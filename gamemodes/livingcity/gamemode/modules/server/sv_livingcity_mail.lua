--[[
    Living City: letters

    A note in your pockets (paper, written on: sv_livingcity_writing.lua) can
    be sent as a letter to anyone the city knows: read it (F3) and Send as a
    letter. You hand it in at the post office (the Courier's workplace; on a
    map without one, anywhere). Signed or not, the post office knows who
    posted it.

    After lc_mail_minutes (4) of sorting, it's out for delivery: a courier
    carries it to the recipient's housing block (a player Courier's "The
    real mail" shift, or the city's own couriers: sv_livingcity_npcwork.lua),
    and it turns up in their pockets. Nobody takes it, and the Union's van
    does, eventually. If they aren't in the city, it waits for them.

    While it's at the post office, Civil Protection can read it (the actions
    menu, at the post office): who wrote it, who to, what it says. They can
    let it through or confiscate it, and the sender never knows.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_mail_list")
util.AddNetworkString("lc_mail_do")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMinutes = CreateConVar("lc_mail_minutes", "4", FLAGS, "Minutes a letter spends being sorted at the post office before it goes out")

local FILE = "livingcity/mail.json"
LC.Mail = LC.Mail or nil -- { letters = { ... }, dir = { [cid] = { name, block } }, serial }

local function Data()
    if LC.Mail then return LC.Mail end
    local t = LC.SafeReadJSON(FILE)
    LC.Mail = istable(t) and t or {}
    LC.Mail.letters = LC.Mail.letters or {}
    LC.Mail.dir = LC.Mail.dir or {}
    LC.Mail.serial = LC.Mail.serial or 0
    for _, l in ipairs(LC.Mail.letters) do l.claimed = nil end -- (whoever was carrying it before a restart isn't now)
    return LC.Mail
end

local dirty = false
local function Save()
    dirty = false
    LC.SafeWrite(FILE, util.TableToJSON(Data()))
end
local function Changed() dirty = true end

local function CidOf(ply) return ply:GetNW2String("lc_cid", "") end
local function PlayerOf(cid)
    for _, p in ipairs(player.GetAll()) do if CidOf(p) == cid then return p end end
    return nil
end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end

-- Everyone the city knows: who's here, and whoever's been here.
local function Register(ply)
    local cid = CidOf(ply)
    if cid == "" then return end
    local d = Data().dir
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    local block = LC.PlayerBlock and LC.PlayerBlock(ply) or nil
    local cur = d[cid]
    if not cur or cur.name ~= name or cur.block ~= block then
        d[cid] = { name = name, block = block, seen = os.time() }
        Changed()
    end
end
LC.MailRegister = Register

-- Who's in the city first, then whoever was here most recently (sixty at most).
function LC.MailRecipients(ply)
    local me, online, offline, seen = CidOf(ply), {}, {}, {}
    for _, p in ipairs(player.GetAll()) do
        Register(p)
        local cid = CidOf(p)
        if cid ~= "" and cid ~= me and not seen[cid] then
            seen[cid] = true
            online[#online + 1] = { cid, Data().dir[cid] and Data().dir[cid].name or p:Nick() }
        end
    end
    for cid, d in pairs(Data().dir) do
        if cid ~= me and not seen[cid] then offline[#offline + 1] = { cid, d.name, d.seen or 0 } end
    end
    table.sort(online, function(a, b) return a[2] < b[2] end)
    table.sort(offline, function(a, b) return a[3] > b[3] end)
    local out = online
    for _, r in ipairs(offline) do
        if #out >= 60 then break end
        out[#out + 1] = { r[1], r[2] }
    end
    return out
end

-- The post office: the Courier's workplace.
function LC.PostOffices()
    local job = LCJ and LCJ.ById and LCJ.ById.courier
    return job and LC.PointsOfKind("work", job.num) or {}
end
local function AtPostOffice(ply)
    local offices = LC.PostOffices()
    if #offices == 0 then return true end
    for _, p in ipairs(offices) do if p.pos:DistToSqr(ply:GetPos()) < 300 * 300 then return true end end
    return false
end
LC.AtPostOffice = AtPostOffice

function LC.SendLetter(ply, idx, cid)
    local list = LC.Notes(ply)
    local n = list[idx]
    if not n then return false, "You don't have that note." end
    local d = cid and Data().dir[cid]
    if not d then return false, "The post office doesn't know anyone by that name." end
    if cid == CidOf(ply) then return false, "You could just keep it." end
    if not AtPostOffice(ply) then return false, "Take it to the post office." end
    table.remove(list, idx)
    if LC.SaveCarriedNotes then LC.SaveCarriedNotes(ply) end
    local m = Data()
    m.serial = m.serial + 1
    local letter = {
        id = "L" .. os.time() .. "-" .. m.serial, text = n.text, sig = n.sig,
        fromCid = CidOf(ply), fromName = LC.CharacterName and LC.CharacterName(ply) or ply:Nick(), -- the post office knows
        toCid = cid, toName = d.name, posted = os.time(), state = "sorting",
    }
    table.insert(m.letters, letter)
    Changed()
    if LC.SendInv then LC.SendInv(ply) end
    hook.Run("LivingCityLetterPosted", ply, letter)
    return true, "You hand it over the counter, addressed to " .. d.name .. ". It'll go out with the next round."
end

-- Into their pockets (or kept for them, if they aren't here).
function LC.DeliverLetter(letter, by)
    if not letter or letter.state == "gone" then return false end
    local p = PlayerOf(letter.toCid)
    if IsValid(p) then
        local list = LC.Notes(p)
        list[#list + 1] = { text = letter.text, sig = letter.sig, letter = true }
        if LC.SaveCarriedNotes then LC.SaveCarriedNotes(p) end
        if LC.SendInv then LC.SendInv(p) end
        p:ChatPrint("[Mail] A letter has come for you" .. (letter.sig and (", from " .. letter.sig) or "") .. ". It's in your pockets (F3).")
        letter.state = "gone"
    else
        letter.state = "delivered" -- waiting for them
    end
    if IsValid(by) and by:IsPlayer() and LC.AddCredits then LC.AddCredits(by, 4, "letter delivered") end
    hook.Run("LivingCityLetterDelivered", letter, by)
    Changed()
    return true
end

-- Where a letter's going: the recipient's block, if the city knows it.
function LC.LetterDestination(letter, from)
    local d = Data().dir[letter.toCid]
    local n = d and tonumber(d.block)
    if n then
        for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("block") or {}) do
            if (z.group or 0) == n then return LC.SpotInZone and LC.SpotInZone(z) or z.pos end
        end
    end
    local p = PlayerOf(letter.toCid)
    if IsValid(p) and LC.PlayerBlock then
        local b = LC.PlayerBlock(p)
        for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("block") or {}) do
            if b and (z.group or 0) == b then return LC.SpotInZone and LC.SpotInZone(z) or z.pos end
        end
    end
    return nil
end

-- Letters out for delivery that nobody has taken.
function LC.LettersOut(n)
    local out = {}
    for _, l in ipairs(Data().letters) do
        if l.state == "out" and not l.claimed then out[#out + 1] = l if n and #out >= n then break end end
    end
    return out
end

function LC.MailTick()
    local now, m = os.time(), Data()
    local wait = cvMinutes:GetFloat() * 60
    for i = #m.letters, 1, -1 do
        local l = m.letters[i]
        if l.state == "sorting" and now - (l.posted or now) >= wait then
            l.state, l.outAt = "out", now
            Changed()
        elseif l.state == "out" and now - (l.outAt or now) > wait * 2 and not l.claimed then
            LC.DeliverLetter(l, nil) -- the Union's van
        elseif l.state == "delivered" and IsValid(PlayerOf(l.toCid)) then
            LC.DeliverLetter(l, nil)
        end
        if l.state == "gone" or (now - (l.posted or now)) > 7 * 86400 then table.remove(m.letters, i) Changed() end
    end
    if dirty then Save() end
end

timer.Create("LivingCityMail", 15, 0, function()
    local ok, err = LC.Try(LC.MailTick)
    if not ok and LC.Error then LC.Error("mail", err) end
end)
hook.Add("PlayerSpawn", "LivingCityMail", function(ply)
    timer.Simple(3, function() if IsValid(ply) then Register(ply) end end)
end)
hook.Add("ShutDown", "LivingCityMail", function() if dirty then Save() end end)

------------------------------------------------------------------------
-- Civil Protection reads the mail
------------------------------------------------------------------------

function LC.MailForInspection(ply)
    if not LC.PlayerIsCP(ply) then return nil, "Civil Protection units only." end
    if not AtPostOffice(ply) then return nil, "The mail's at the post office." end
    local out = {}
    for _, l in ipairs(Data().letters) do
        if l.state == "sorting" or l.state == "out" then
            out[#out + 1] = { id = l.id, from = l.fromName, sig = l.sig, to = l.toName, text = l.text }
        end
    end
    return out
end

function LC.ConfiscateLetter(ply, id)
    if not LC.PlayerIsCP(ply) or not AtPostOffice(ply) then return false end
    for i, l in ipairs(Data().letters) do
        if l.id == id and (l.state == "sorting" or l.state == "out") then
            table.remove(Data().letters, i)
            Changed()
            if LC.AddXP then LC.AddXP(ply, 2, "mail inspected") end
            hook.Run("LivingCityLetterConfiscated", ply, l)
            return true, "Confiscated. It won't arrive. (Posted by " .. (l.fromName or "?") .. ".)"
        end
    end
    return false
end

function LC.SendMailList(ply)
    local list, why = LC.MailForInspection(ply)
    if not list then if why then ply:ChatPrint(why) end return false end
    LC.SendCompressed("lc_mail_list", { letters = list }, { ply })
    return true
end

net.Receive("lc_mail_do", function(_, ply)
    local what, id = net.ReadString(), net.ReadString()
    if what == "confiscate" then
        local ok, msg = LC.ConfiscateLetter(ply, id)
        if msg then ply:ChatPrint(msg) end
        if ok then LC.SendMailList(ply) end
    end
end)

------------------------------------------------------------------------
-- The city's couriers carry real mail when there is some
------------------------------------------------------------------------

if LC.AddNPCTask then
    LC.AddNPCTask("courier", { id = "letters", label = "delivering letters", urgent = true, find = function(npc, st, now)
        local grace = (LC.NPCWorkGrace and LC.NPCWorkGrace("courier") or 60)
        local pick
        for _, l in ipairs(LC.LettersOut()) do
            if os.time() - (l.outAt or 0) >= grace then pick = l break end
        end
        if not pick then return nil end
        local dest = LC.LetterDestination(pick, npc:GetPos())
        local office = LC.PostOffices()[1]
        local steps = {}
        if office then
            steps[#steps + 1] = { pos = office.pos, secs = 3, anim = { "ACT_PICKUP_RACK" }, doing = "collecting the mail",
                done = function(n, s) if LC.NPCCarry then LC.NPCCarry(n, s, "models/props_lab/clipboard.mdl") end end }
        end
        steps[#steps + 1] = { pos = dest or (office and office.pos) or npc:GetPos(), secs = 3, anim = { "ACT_PICKUP_RACK" },
            doing = "delivering a letter to " .. (pick.toName or "someone"),
            done = function(n, s) if LC.NPCDropCarry then LC.NPCDropCarry(n, s) end LC.DeliverLetter(pick, n) end }
        return { key = "letter" .. pick.id, steps = steps,
            onStart = function() pick.claimed = true end,
            onEnd = function(_, _, _, finished) if not finished then pick.claimed = nil end end }
    end })
end
