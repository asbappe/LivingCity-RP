--[[
    Living City: writing, broadcasts, and the law

      Notes and posters   Paper (Commissary, or bins): Write, from your pockets.
                          Leave it on the ground as a note, stick it to the
                          wall you're looking at as a poster, or keep it. Sign
                          it or don't. Anyone can press E on a note or poster
                          to read it and take it (up to lc_notes_kept, 8, in
                          your pockets). Units, and whoever put it up, can tear
                          a poster down. They're kept across restarts for
                          lc_poster_hours (12). One person can have
                          lc_posters_per_person (3) up at once.

      Broadcasts          The City Administrator (or an admin, or Civil
                          Protection from Divisional Leader up) speaks to the
                          whole city: !broadcast <text>. It's across everyone's
                          screen and on every city screen (editor: "Fixture:
                          city screen") until the next one.

      The law             !laws shows the city's laws; so does any law board
                          (editor: "Fixture: law board"). The Administrator and
                          admins write them: !addlaw <text>, !setlaw <n> <text>,
                          !dellaw <n>. Kept in garrysmod/data/livingcity/laws.json.
]]

if CLIENT then return end

util.AddNetworkString("lc_write_open")
util.AddNetworkString("lc_write")
util.AddNetworkString("lc_read")
util.AddNetworkString("lc_read_do")
util.AddNetworkString("lc_broadcast")
util.AddNetworkString("lc_laws")
util.AddNetworkString("lc_laws_do")

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvKept      = CreateConVar("lc_notes_kept", "8", FLAGS, "Written notes a person can carry")
local cvHours     = CreateConVar("lc_poster_hours", "12", FLAGS, "Hours a note or poster stays where it was left")
local cvPerPerson = CreateConVar("lc_posters_per_person", "3", FLAGS, "Notes and posters one person can have up at once")
local MAX_TEXT = 600

local DIR = "livingcity"
local function NotesFile() return DIR .. "/" .. game.GetMap() .. "_notes.json" end
local LAWS_FILE = DIR .. "/laws.json"

local function CharName(ply) return LC.CharacterName and LC.CharacterName(ply) or ply:Nick() end
local function OwnerKey(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and cid or ("sid:" .. ply:SteamID())
end

local function Clean(text)
    text = tostring(text or "")
    text = string.gsub(text, "[%c]", function(c) return c == "\n" and "\n" or "" end)
    text = string.Trim(text)
    return string.sub(text, 1, MAX_TEXT)
end

------------------------------------------------------------------------
-- Notes you carry
------------------------------------------------------------------------

function LC.Notes(ply)
    if not ply.lcNotes then
        local t = util.JSONToTable(ply:GetPData("lc_notes", "") or "")
        ply.lcNotes = istable(t) and t or {}
    end
    return ply.lcNotes
end
local function SaveNotes(ply) ply:SetPData("lc_notes", util.TableToJSON(LC.Notes(ply))) end
LC.SaveCarriedNotes = SaveNotes
LC.CharName = CharName

function LC.OpenWriter(ply)
    if not LC.HasItem(ply, "paper") then return false, "You need paper." end
    net.Start("lc_write_open")
    net.Send(ply)
    return true
end

------------------------------------------------------------------------
-- Notes and posters in the world
------------------------------------------------------------------------

LC.WorldNotes = LC.WorldNotes or nil -- [id] = { text, by, sig, poster, pos, ang, untilT (os.time), owner }

local function LoadNotes()
    if LC.WorldNotes then return LC.WorldNotes end
    local raw = file.Read(NotesFile(), "DATA")
    local t = raw and util.JSONToTable(raw) or {}
    LC.WorldNotes = istable(t) and t or {}
    return LC.WorldNotes
end
local function SaveWorldNotes()
    local out = {}
    for id, n in pairs(LoadNotes()) do
        out[id] = { text = n.text, sig = n.sig, poster = n.poster, pos = n.pos, ang = n.ang, untilT = n.untilT, owner = n.owner }
    end
    file.CreateDir(DIR)
    file.Write(NotesFile(), util.TableToJSON(out))
end

local function SpawnNote(id, n)
    local e = ents.Create("lc_note")
    if not IsValid(e) then return nil end
    e:SetPos(Vector(n.pos.x, n.pos.y, n.pos.z))
    e:SetAngles(Angle(n.ang.p or 0, n.ang.y or 0, n.ang.r or 0))
    e:SetNW2Bool("lc_poster", n.poster == true)
    e:SetNW2String("lc_note_text", string.sub(n.text or "", 1, 160)) -- for the poster face; reading gets it all
    e:Spawn()
    e.lcNoteId = id
    n.ent = e
    return e
end

local function Mine(ply)
    local n = 0
    for _, x in pairs(LoadNotes()) do if x.owner == OwnerKey(ply) then n = n + 1 end end
    return n
end

-- mode: "note" (on the ground), "poster" (on the wall you're looking at), "keep" (in your pockets)
function LC.WriteNote(ply, text, mode, signed, sigAs)
    text = Clean(text)
    if #text < 2 then return false, "Write something." end
    if not LC.HasItem(ply, "paper") then return false, "You need paper." end
    if LC.IsTied and LC.IsTied(ply) then return false, "Your hands are tied." end
    local sig = sigAs or (signed and CharName(ply)) or nil
    if mode == "keep" then
        local list = LC.Notes(ply)
        if #list >= cvKept:GetInt() then return false, "You can't carry any more notes. Drop one first." end
        LC.TakeItem(ply, "paper", 1)
        list[#list + 1] = { text = text, sig = sig }
        SaveNotes(ply)
        return true, "You fold the note into your pocket."
    end
    if Mine(ply) >= cvPerPerson:GetInt() then return false, "You've got enough of your writing out there already." end
    local n = { text = text, sig = sig, owner = OwnerKey(ply), untilT = os.time() + cvHours:GetFloat() * 3600 }
    if mode == "poster" then
        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 110, filter = ply })
        if not tr.Hit or IsValid(tr.Entity) and not tr.Entity:IsWorld() or math.abs((tr.HitNormal or Vector(0, 0, 1)).z) > 0.5 then
            return false, "Look at a wall to put it up on."
        end
        local a = tr.HitNormal:Angle()
        n.poster = true
        n.pos = { x = tr.HitPos.x + tr.HitNormal.x, y = tr.HitPos.y + tr.HitNormal.y, z = tr.HitPos.z }
        n.ang = { p = a.p, y = a.y, r = a.r }
    else
        local fwd = ply:GetForward()
        local spot = ply:GetPos() + Vector(fwd.x, fwd.y, 0) * 35
        local ground = LC.GroundAt and LC.GroundAt(spot + Vector(0, 0, 30)) or spot
        n.pos = { x = ground.x, y = ground.y, z = ground.z + 1 }
        n.ang = { p = 0, y = math.floor(ply:EyeAngles().y), r = 0 }
    end
    LC.TakeItem(ply, "paper", 1)
    LC.NoteSerial = (LC.NoteSerial or 0) + 1
    local id = string.format("n%d-%d", os.time(), LC.NoteSerial)
    LoadNotes()[id] = n
    SpawnNote(id, n)
    SaveWorldNotes()
    hook.Run("LivingCityWrote", ply, n)
    return true, n.poster and "You put it up." or "You leave the note."
end

net.Receive("lc_write", function(_, ply)
    local text, mode, signed = net.ReadString(), net.ReadString(), net.ReadBool()
    if (ply.lcWriteNext or 0) > CurTime() then return end
    ply.lcWriteNext = CurTime() + 1
    local ok, msg = LC.WriteNote(ply, text, mode, signed)
    if msg then ply:ChatPrint(msg) end
end)

-- Reading: what's written, who signed it, and what this reader may do with it.
local function SendRead(ply, t)
    LC.SendCompressed("lc_read", t, ply)
end

function LC.ReadNoteEntity(ply, e)
    local id = e.lcNoteId
    local n = id and LoadNotes()[id]
    if not n then return end
    local canTear = n.poster and (LC.PlayerIsCP(ply) or n.owner == OwnerKey(ply))
    SendRead(ply, { text = n.text, sig = n.sig, poster = n.poster or nil, world = id, take = true, tear = canTear or nil })
end

function LC.TakeNote(ply, id)
    local n = LoadNotes()[id]
    if not n or not IsValid(n.ent) or n.ent:GetPos():DistToSqr(ply:GetPos()) > 160 * 160 then return false end
    local list = LC.Notes(ply)
    if #list >= cvKept:GetInt() then return false, "You can't carry any more notes." end
    list[#list + 1] = { text = n.text, sig = n.sig }
    SaveNotes(ply)
    n.ent:Remove()
    LoadNotes()[id] = nil
    SaveWorldNotes()
    return true, "You take it."
end

function LC.TearDown(ply, id)
    local n = LoadNotes()[id]
    if not n or not n.poster then return false end
    if not (LC.PlayerIsCP(ply) or n.owner == OwnerKey(ply)) then return false end
    if IsValid(n.ent) then n.ent:EmitSound("physics/cardboard/cardboard_box_break1.wav", 60) n.ent:Remove() end
    LoadNotes()[id] = nil
    SaveWorldNotes()
    if LC.PlayerIsCP(ply) and n.owner ~= OwnerKey(ply) and LC.AddXP then LC.AddXP(ply, 2, "unauthorised notice removed") end
    return true, "You tear it down."
end

-- The notes in your pockets: read one, drop it, or put it up.
function LC.CarriedNote(ply, idx, what)
    local list = LC.Notes(ply)
    local n = list[idx]
    if not n then return false end
    if what == "read" then
        -- who it could be posted to, as a letter (sv_livingcity_mail.lua)
        local to = LC.MailRecipients and LC.MailRecipients(ply) or nil
        SendRead(ply, { text = n.text, sig = n.sig, carried = idx, letter = n.letter or nil, to = to })
        return true
    end
    if what == "drop" or what == "post" then
        if Mine(ply) >= cvPerPerson:GetInt() then return false, "You've got enough of your writing out there already." end
        table.remove(list, idx)
        SaveNotes(ply)
        LC.GiveItem(ply, "paper", 1) -- the same sheet, put down again (WriteNote takes it back)
        local ok, msg = LC.WriteNote(ply, n.text, what == "post" and "poster" or "note", false, n.sig)
        if not ok then
            LC.TakeItem(ply, "paper", 1)
            table.insert(list, idx, n)
            SaveNotes(ply)
        end
        return ok, msg
    end
    if what == "destroy" then
        table.remove(list, idx)
        SaveNotes(ply)
        return true, "You tear it up."
    end
    return false
end

net.Receive("lc_read_do", function(_, ply)
    local what, ref = net.ReadString(), net.ReadString()
    local ok, msg
    if what == "take" then ok, msg = LC.TakeNote(ply, ref)
    elseif what == "tear" then ok, msg = LC.TearDown(ply, ref)
    elseif what == "letter" and LC.SendLetter then
        local idx, cid = string.match(ref, "^(%d+)|(.+)$")
        ok, msg = LC.SendLetter(ply, tonumber(idx) or 0, cid)
    else ok, msg = LC.CarriedNote(ply, tonumber(ref) or 0, what) end
    if msg then ply:ChatPrint(msg) end
    if what ~= "read" and LC.SendInv then LC.SendInv(ply) end
end)

-- On start: what was left up comes back; what's old is gone.
function LC.RestoreNotes()
    local now = os.time()
    local all = LoadNotes()
    for id, n in pairs(all) do
        if (n.untilT or 0) < now then all[id] = nil
        elseif not IsValid(n.ent) and n.pos and n.ang then SpawnNote(id, n) end
    end
    SaveWorldNotes()
end
hook.Add("InitPostEntity", "LivingCityNotes", function() timer.Simple(2, function() pcall(LC.RestoreNotes) end) end)
hook.Add("PostCleanupMap", "LivingCityNotes", function() timer.Simple(1, function() pcall(LC.RestoreNotes) end) end)
timer.Create("LivingCityNotesExpire", 120, 0, function()
    local now, changed = os.time(), false
    for id, n in pairs(LoadNotes()) do
        if (n.untilT or 0) < now then
            if IsValid(n.ent) then n.ent:Remove() end
            LoadNotes()[id] = nil
            changed = true
        end
    end
    if changed then SaveWorldNotes() end
end)

------------------------------------------------------------------------
-- Broadcasts
------------------------------------------------------------------------

function LC.MayBroadcast(ply)
    if not IsValid(ply) then return true end
    if ply:IsAdmin() then return true end
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "admin" or (f == "cp" and ply:GetNW2Int("lcf_rank", 1) >= 3) -- (Division Leader and up)
end

function LC.Broadcast(ply, text)
    if not LC.MayBroadcast(ply) then return false, "Only the City Administrator speaks to the whole city." end
    text = Clean(text)
    if #text < 3 then return false, "Say something." end
    if IsValid(ply) and (ply.lcBroadcastNext or 0) > CurTime() and not ply:IsAdmin() then return false, "Give the city a moment." end
    if IsValid(ply) then ply.lcBroadcastNext = CurTime() + 60 end
    local who = IsValid(ply) and ((ply:GetNW2String("lcf_faction", "") == "admin" or ply:IsAdmin()) and "The City Administrator"
        or ply:GetNW2String("lcf_title", "Civil Protection")) or "The City Administrator"
    SetGlobal2String("lc_broadcast", text)
    SetGlobal2String("lc_broadcast_by", who)
    SetGlobal2Float("lc_broadcast_at", CurTime())
    net.Start("lc_broadcast")
    net.WriteString(text)
    net.WriteString(who)
    net.Broadcast()
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[" .. who .. "] " .. text) end
    LC.Log("info", "broadcast by " .. (IsValid(ply) and ply:Nick() or "console") .. ": " .. text)
    return true
end

------------------------------------------------------------------------
-- The law
------------------------------------------------------------------------

local DEFAULT_LAWS = {
    "Obey the instructions of Civil Protection at all times.",
    "Carry your identification. Present it when asked.",
    "Curfew is absolute. Be in your residence when it is called.",
    "Gatherings of more than three citizens require a permit.",
    "Do not run. Do not loiter. Do not obstruct a unit.",
    "Possession of weapons, unregistered radios or Resistance materials is forbidden.",
    "Report anticitizen activity. Inaction is conspiracy.",
    "Rations are allocated by standing. Do not take what is not yours.",
}

LC.Laws = LC.Laws or nil
local function Laws()
    if not LC.Laws then
        local raw = file.Read(LAWS_FILE, "DATA")
        local t = raw and util.JSONToTable(raw) or nil
        LC.Laws = istable(t) and t or table.Copy(DEFAULT_LAWS)
        SetGlobal2String("lc_laws", util.TableToJSON(LC.Laws))
    end
    return LC.Laws
end
local function SaveLaws()
    file.CreateDir(DIR)
    file.Write(LAWS_FILE, util.TableToJSON(Laws()))
    SetGlobal2String("lc_laws", util.TableToJSON(Laws()))
end
hook.Add("InitPostEntity", "LivingCityLaws", function() Laws() end)

local function MayLegislate(ply) return not IsValid(ply) or ply:IsAdmin() or ply:GetNW2String("lcf_faction", "") == "admin" end

function LC.SetLaw(ply, n, text)
    if not MayLegislate(ply) then return false, "Only the City Administrator writes the law." end
    local list = Laws()
    text = Clean(text)
    if n == nil then
        if #text < 3 then return false, "Write the law." end
        list[#list + 1] = string.sub(text, 1, 200)
    elseif text == "" then
        if not list[n] then return false, "No such law." end
        table.remove(list, n)
    else
        if n < 1 or n > #list + 1 then return false, "Laws go from 1 to " .. #list .. "." end
        list[n] = string.sub(text, 1, 200)
    end
    SaveLaws()
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] The law has changed. C > The city > The city's laws.") end
    return true
end

function LC.ShowLaws(ply)
    LC.SendCompressed("lc_laws", { laws = Laws(), edit = MayLegislate(ply) or nil }, ply)
end

net.Receive("lc_laws_do", function(_, ply)
    local action, n, text = net.ReadString(), tonumber(net.ReadString()), net.ReadString()
    local ok, why
    if action == "add" then ok, why = LC.SetLaw(ply, nil, text)
    elseif action == "set" and n then ok, why = LC.SetLaw(ply, n, text)
    elseif action == "del" and n then ok, why = LC.SetLaw(ply, n, "") end
    if why then ply:ChatPrint(why) end
    LC.ShowLaws(ply)
end)

------------------------------------------------------------------------
-- Pockets screen: your notes
------------------------------------------------------------------------

-- What the pockets screen lists (sv_livingcity_underground.lua's LC.InvExtras adds it).
function LC.NotesForInv(ply)
    local out = {}
    for i, n in ipairs(LC.Notes(ply)) do out[i] = { first = string.sub(string.gsub(n.text, "\n", " "), 1, 48), sig = n.sig } end
    return out
end

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

local CMDS = {
    write = function(ply) local ok, why = LC.OpenWriter(ply) if not ok and why then ply:ChatPrint(why) end end,
    broadcast = function(ply, rest) local ok, why = LC.Broadcast(ply, rest) if not ok and why then ply:ChatPrint(why) end end,
    laws = function(ply) LC.ShowLaws(ply) end,
    addlaw = function(ply, rest) local ok, why = LC.SetLaw(ply, nil, rest) if why then ply:ChatPrint(why) end end,
    setlaw = function(ply, rest)
        local n, text = string.match(rest or "", "^(%d+)%s+(.+)$")
        if not n then return ply:ChatPrint("Usage: !setlaw <number> <text>") end
        local ok, why = LC.SetLaw(ply, tonumber(n), text)
        if why then ply:ChatPrint(why) end
    end,
    dellaw = function(ply, rest)
        local n = tonumber(string.match(rest or "", "^(%d+)"))
        if not n then return ply:ChatPrint("Usage: !dellaw <number>") end
        local ok, why = LC.SetLaw(ply, n, "")
        if why then ply:ChatPrint(why) end
    end,
}
for k, fn in pairs(CMDS) do LC.SlashCommands[k] = fn end

hook.Add("PlayerSay", "LivingCityWritingChat", function(ply, text)
    local raw = string.Trim(text or "")
    local lead = string.sub(raw, 1, 1)
    if lead ~= "!" and lead ~= "/" then return end
    if lead == "/" and LC.ICChatActive and LC.ICChatActive() then return end
    local cmd, rest = string.match(raw, "^[!/](%S+)%s*(.*)$")
    local fn = cmd and CMDS[string.lower(cmd)]
    if not fn then return end
    fn(ply, rest or "")
    return ""
end)

concommand.Add("lc_broadcast", function(ply, _, args)
    local ok, why = LC.Broadcast(ply, table.concat(args or {}, " "))
    if not ok and why then if IsValid(ply) then ply:ChatPrint(why) else print(why) end end
end)
