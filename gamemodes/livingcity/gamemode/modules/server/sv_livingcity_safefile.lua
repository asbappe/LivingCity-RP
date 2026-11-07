--[[
    Living City: save files written safely

    Garry's Mod's file.Write isn't atomic: a crash, a host restart or a full
    disk in the middle of a write leaves a cut-off file, and the next start
    reads it as nothing at all. Every save file of the city (garrysmod/data/
    livingcity/...) goes through here instead:

      LC.SafeWrite(path, text)   writes <path>.tmp.txt first, reads it back
                                 and checks it (the same length, and JSON
                                 that decodes for a .json file); only then
                                 the good file that was there becomes
                                 <path>.bak.txt and the new one takes its
                                 place. Nothing is lost if it stops halfway.
      LC.SafeReadJSON(path)      reads and decodes; a file that can't be read
                                 falls back to <path>.tmp.txt (a write that
                                 finished but wasn't swapped in yet), then to
                                 <path>.bak.txt, with a warning in the log.
                                 (A file that's gone, deleted by hand to
                                 start it over, isn't brought back from its
                                 backup.)
                                 When nothing can be read, the file is left
                                 as it is and nothing is saved over it (the
                                 city would otherwise save its empty default
                                 over the real data) until it reads again or
                                 a superadmin lets the city save over it
                                 (the admin tools, "Save files").
      LC.SafeDelete(path)        removes the file and its .tmp/.bak.

    The names stay the same; the extra files sit next to each one and end in
    .txt (the data folder only takes certain extensions). See
    docs/dev/save-files.md.
]]

if CLIENT then return end

LC = LC or {}
LC.SafeFiles = LC.SafeFiles or { blocked = {}, warned = {}, noted = {} } -- blocked[path] = when (unreadable: not saved over)

local SF = LC.SafeFiles
SF.noted = SF.noted or {} -- (each warning once: some files are read often)

local function Log(level, msg)
    if LC.Log then LC.Log(level, msg) else print("[Living City] " .. level .. ": " .. msg) end
end

function LC.SafeTmpPath(path) return path .. ".tmp.txt" end
function LC.SafeBakPath(path) return path .. ".bak.txt" end
function LC.SafeUnreadablePath(path) return path .. ".unreadable.txt" end

local function IsJSON(path, opts)
    if opts and opts.json ~= nil then return opts.json end
    return string.lower(string.sub(path, -5)) == ".json"
end

-- Good text for this file: not empty, and JSON that decodes when it's JSON.
local function Good(text, json)
    if not isstring(text) or text == "" then return false end
    if json then return util.JSONToTable(text) ~= nil end
    return true
end

local function MakeDirs(path)
    if not file.CreateDir then return end
    local dir = string.match(path, "^(.*)/[^/]*$")
    if not dir then return end
    local sofar
    for part in string.gmatch(dir, "[^/]+") do
        sofar = sofar and (sofar .. "/" .. part) or part
        file.CreateDir(sofar)
    end
end

-- Move (or copy) a file over another; true when the target holds it now.
local function Move(from, to, text)
    if file.Exists(to, "DATA") then file.Delete(to) end
    if file.Rename and file.Rename(from, to) and file.Exists(to, "DATA") then return true end
    file.Write(to, text)
    local back = file.Read(to, "DATA")
    if back ~= text then return false end
    if file.Exists(from, "DATA") then file.Delete(from) end
    return true
end

-- opts: { json = true/false (default: by the name), force = true (an admin's own save: past the guard) }
-- Returns true when the new text is in place, or false and why.
function LC.SafeWrite(path, text, opts)
    if not (file and file.Write and file.Read) then return false, "no file access" end
    if not isstring(path) or path == "" or not isstring(text) then return false, "nothing to write" end
    local force = opts and opts.force
    if SF.blocked[path] and not force then
        if not SF.warned[path] then
            SF.warned[path] = true
            Log("warn", "Save file " .. path .. " couldn't be read at start, so it isn't saved over (a superadmin can allow it: admin tools, Save files).")
        end
        return false, "unreadable file kept"
    end
    local json = IsJSON(path, opts)
    MakeDirs(path)
    -- 1. the new text, on its own, read back and checked
    local tmp = LC.SafeTmpPath(path)
    file.Write(tmp, text)
    local back = file.Read(tmp, "DATA")
    if back == nil or #back ~= #text or (json and util.JSONToTable(back) == nil) then
        Log("error", "Save file " .. path .. " wasn't saved: the new copy didn't read back whole (is the disk full?). The old one is kept.")
        if file.Exists(tmp, "DATA") then file.Delete(tmp) end
        return false, "write didn't verify"
    end
    -- 2. what was there: a good file becomes the backup, an unreadable one is kept aside once
    local old = file.Read(path, "DATA")
    if old ~= nil and old ~= text then
        if Good(old, json) then
            Move(path, LC.SafeBakPath(path), old)
        elseif old ~= "" and not file.Exists(LC.SafeUnreadablePath(path), "DATA") then
            file.Write(LC.SafeUnreadablePath(path), old)
        end
    end
    -- 3. the new one in its place
    if not Move(tmp, path, text) then
        Log("error", "Save file " .. path .. " couldn't be replaced; the new copy is kept as " .. tmp .. ".")
        return false, "replace failed"
    end
    SF.blocked[path], SF.warned[path], SF.noted[path] = nil, nil, nil
    return true
end

-- Returns the table (or nil) and how it went: "ok", "missing" (no file: start fresh),
-- "backup" (the file was unreadable or gone, a backup was used) or "failed" (nothing readable:
-- the file is kept and not saved over until it reads, or a superadmin allows it).
function LC.SafeReadJSON(path)
    if not (file and file.Read) or not isstring(path) then return nil, "missing" end
    local raw = file.Read(path, "DATA")
    local t = isstring(raw) and raw ~= "" and util.JSONToTable(raw) or nil
    if t ~= nil then
        SF.blocked[path], SF.warned[path] = nil, nil
        return t, "ok"
    end
    -- (gone altogether: only the checked copy of a swap cut short counts. A file deleted by hand, to
    -- start it over, stays deleted: its old backup isn't brought back.)
    local alts = raw == nil and { LC.SafeTmpPath(path) } or { LC.SafeTmpPath(path), LC.SafeBakPath(path) }
    for _, alt in ipairs(alts) do
        local r = file.Read(alt, "DATA")
        local a = isstring(r) and r ~= "" and util.JSONToTable(r) or nil
        if a ~= nil then
            if not SF.noted[path] then SF.noted[path] = true Log("warn", "Save file " .. path .. (raw == nil and " was missing" or " couldn't be read") .. "; loaded " .. alt .. " instead.") end
            SF.blocked[path], SF.warned[path] = nil, nil
            return a, "backup"
        end
    end
    if raw == nil then return nil, "missing" end
    if SF.blocked[path] then return nil, "failed" end
    SF.blocked[path] = os.date("%Y-%m-%d %H:%M:%S")
    Log("error", "Save file " .. path .. " couldn't be read (and no backup could). It's left as it is and the city won't save over it until a superadmin allows it (admin tools, Save files).")
    return nil, "failed"
end

function LC.SafeDelete(path)
    if not (file and file.Delete and file.Exists) then return end
    for _, p in ipairs({ path, LC.SafeTmpPath(path), LC.SafeBakPath(path) }) do
        if file.Exists(p, "DATA") then file.Delete(p) end
    end
    SF.blocked[path], SF.warned[path] = nil, nil
end

-- The files that couldn't be read and are kept as they are: { path = when }.
function LC.SafeFileBlocked(path)
    if path then return SF.blocked[path] ~= nil end
    return SF.blocked
end

-- A superadmin's say-so: the city may save over them (the unreadable file is kept as
-- <path>.unreadable.txt the first time). path nil: all of them. Returns how many.
function LC.SafeFileAllow(path)
    local n = 0
    for p in pairs(SF.blocked) do
        if path == nil or p == path then
            SF.blocked[p], SF.warned[p] = nil, nil
            n = n + 1
            Log("info", "Save file " .. p .. " may be saved over again.")
        end
    end
    return n
end

-- Superadmins hear about it when they join.
hook.Add("PlayerInitialSpawn", "LivingCitySafeFiles", function(ply)
    timer.Simple(8, function()
        if not IsValid(ply) or not ply:IsSuperAdmin() or next(SF.blocked) == nil or not LC.Notice then return end
        local names = {}
        for p in pairs(SF.blocked) do names[#names + 1] = "data/" .. p end
        table.sort(names)
        LC.Notice(ply, "warn", "Save files", "Couldn't be read, kept as they are and not saved over: " .. table.concat(names, ", ")
            .. ". Admin tools (The city, Save files) lets the city save over them.", 12)
    end)
end)
