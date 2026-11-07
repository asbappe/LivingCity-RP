--[[
    Living City: a life

    What a person's life in the city is worth, and how their death marks the
    people around them. (The settings for how the city looks and feels are in
    sh_livingcity_feel.lua; the death card is drawn by cl_livingcity_life.lua.)

      Eyes      a little lower than GMod's (lc_eye_height, 61): people and
                units stand a touch over you. A pose has its own, and puts
                these back when it ends.
      Time      how long each person has lived in the city, counted while
                they're alive and kept with them (character slots too).
      The card  when someone dies the screen goes dark and says who they were:
                name and number, how long they lived, how many people knew
                their name, and what killed them. lc_respawn_secs (12) before
                anyone can go on. Deaths that don't end the person (build
                mode, custody, the infested, lc_permadeath 0) get a short card
                that says so.
      Word      the people who knew their name hear it a minute or two later,
                in passing: "[Word gets around] Ada Grey is dead. They say it
                was the Combine." Whoever's away, or playing someone else,
                hears when they're back as the person who knew them (for up to
                30 days). lc_word_gets_around 0 keeps it quiet.

    Who knows whom lives in each person's own saved data (sv_livingcity_rp.lua).
    This keeps the other side of it, who knows each citizen number, in
    garrysmod/data/livingcity/known.json, and the word still to be passed on
    in livingcity/word.json.

    Players: !bob keeps the camera still (cl_livingcity_view.lua).
]]

if CLIENT then return end

util.AddNetworkString("lc_obituary")

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRespawn = CreateConVar("lc_respawn_secs", "12", FLAGS, "Seconds after dying before you can go on (the death card is up meanwhile)")
local cvWord    = CreateConVar("lc_word_gets_around", "1", FLAGS, "People who knew someone's name hear, a minute or two later, that they're dead")

local WORD_MIN, WORD_MAX = 45, 150 -- seconds before the word reaches someone who's here
local WORD_DAYS = 30               -- how long news waits for someone who's away
local WORD_KEEP = 12               -- most pieces of news kept waiting for one player
local RECENT = 15                  -- seconds a wound still counts as what killed you

function LC.RespawnWait() return math.max(0, cvRespawn:GetFloat()) end

------------------------------------------------------------------------
-- Eyes
------------------------------------------------------------------------

function LC.StandEye(ply)
    local h = LC.EyeHeights and LC.EyeHeights() or 64
    return Vector(0, 0, h)
end

local function ApplyEyes(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNW2String("lc_act", "") ~= "" then return end -- (a pose has its own; it puts these back when it ends)
    local h, d = 64, 28
    if LC.EyeHeights then h, d = LC.EyeHeights() end
    ply:SetViewOffset(Vector(0, 0, h))
    if ply.SetViewOffsetDucked then ply:SetViewOffsetDucked(Vector(0, 0, d)) end
end
LC.ApplyEyes = ApplyEyes

if cvars and cvars.AddChangeCallback then
    cvars.AddChangeCallback("lc_eye_height", function()
        for _, p in ipairs(player.GetAll()) do ApplyEyes(p) end
    end, "LivingCityEyes")
end

------------------------------------------------------------------------
-- Time lived
------------------------------------------------------------------------

local function Lived(ply) return tonumber(ply:GetPData("lc_lived", 0)) or 0 end

-- Adds the time since the last count to this person's total, and returns it.
function LC.FlushLived(ply)
    if not IsValid(ply) then return 0 end
    local total = Lived(ply)
    if ply.lcLivedMark then
        local now = CurTime()
        total = total + math.max(0, now - ply.lcLivedMark)
        ply.lcLivedMark = now
        ply:SetPData("lc_lived", string.format("%.1f", total))
    end
    return total
end

function LC.LivedSeconds(ply)
    if not IsValid(ply) then return 0 end
    return Lived(ply) + (ply.lcLivedMark and math.max(0, CurTime() - ply.lcLivedMark) or 0)
end

-- A brand-new person (sv_livingcity_character.lua): counted from their first moment.
function LC.StartLife(ply)
    ply:SetPData("lc_lived", 0)
    ply:SetPData("lc_lived_full", "1")
    if ply.lcLivedMark then ply.lcLivedMark = CurTime() end
end

hook.Add("PlayerSpawn", "LivingCityLife", function(ply)
    LC.FlushLived(ply)
    ply.lcLivedMark = CurTime()
    ply.lcDownCause, ply.lcLastHurt = nil, nil
    ApplyEyes(ply)
    timer.Simple(0, function() ApplyEyes(ply) end) -- (after anything else that sets up a fresh body)
end)

hook.Add("PlayerDisconnected", "LivingCityLife", function(ply) LC.FlushLived(ply) end)

-- the clock stops at death (LC.RecordDeath does this too; whichever comes first)
hook.Add("PlayerDeath", "LivingCityLife", function(ply)
    if IsValid(ply) and ply.lcLivedMark then
        LC.FlushLived(ply)
        ply.lcLivedMark = nil
    end
end)

timer.Create("LivingCityLived", 60, 0, function()
    for _, p in ipairs(player.GetAll()) do LC.FlushLived(p) end
end)

------------------------------------------------------------------------
-- What killed them
------------------------------------------------------------------------

local D = {
    CRUSH = DMG_CRUSH or 1, BULLET = DMG_BULLET or 2, SLASH = DMG_SLASH or 4, BURN = DMG_BURN or 8,
    VEHICLE = DMG_VEHICLE or 16, FALL = DMG_FALL or 32, BLAST = DMG_BLAST or 64, CLUB = DMG_CLUB or 128,
    SHOCK = DMG_SHOCK or 256, DROWN = DMG_DROWN or 16384, NERVEGAS = DMG_NERVEGAS or 65536, POISON = DMG_POISON or 131072,
    RADIATION = DMG_RADIATION or 262144, ACID = DMG_ACID or 1048576, SLOWBURN = DMG_SLOWBURN or 2097152,
    DISSOLVE = DMG_DISSOLVE or 67108864, BUCKSHOT = DMG_BUCKSHOT or 536870912,
}
local function Has(bits, flag) return bit.band(bits or 0, flag) ~= 0 end

hook.Add("EntityTakeDamage", "LivingCityLifeCause", function(ent, dmg)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    ent.lcLastHurt = {
        at = CurTime(),
        bits = dmg.GetDamageType and dmg:GetDamageType() or 0,
        attacker = dmg:GetAttacker(),
        inflictor = dmg.GetInflictor and dmg:GetInflictor() or nil,
    }
end)

-- Another player, as the dead knew them: a name, a callsign, or what they looked like.
local function PersonTo(ply, other)
    local n = LC.NameFor and LC.NameFor(ply, other) or other:Nick()
    if string.sub(n, 1, 1) == "[" then
        n = LC.Description and LC.Description(other) or string.sub(n, 2, -2)
        n = string.lower(string.sub(n, 1, 1)) .. string.sub(n, 2)
    end
    return n
end

local NPC_ROLES = {
    cop = { "a Civil Protection unit", "combine" }, soldier = { "an Overwatch soldier", "combine" },
    rebel = { "a Resistance fighter", "resistance" }, citizen = { "a citizen", "someone" },
    zombie = { "one of the infested", "infestation" }, scanner = { "a city scanner", "combine" },
}
local CLASSES = {
    npc_metropolice = NPC_ROLES.cop, npc_combine_s = NPC_ROLES.soldier, npc_citizen = NPC_ROLES.citizen,
    npc_zombie = NPC_ROLES.zombie, npc_fastzombie = NPC_ROLES.zombie, npc_poisonzombie = NPC_ROLES.zombie,
    npc_zombine = NPC_ROLES.zombie, npc_zombie_torso = NPC_ROLES.zombie, npc_fastzombie_torso = NPC_ROLES.zombie,
    npc_headcrab = { "a headcrab", "infestation" }, npc_headcrab_fast = { "a headcrab", "infestation" },
    npc_headcrab_black = { "a poison headcrab", "infestation" }, npc_headcrab_poison = { "a poison headcrab", "infestation" },
    npc_manhack = { "a manhack", "combine" }, npc_turret_floor = { "a turret", "combine" }, npc_turret_ceiling = { "a turret", "combine" },
    npc_cscanner = NPC_ROLES.scanner, npc_clawscanner = NPC_ROLES.scanner, npc_strider = { "a strider", "combine" },
    npc_hunter = { "a hunter", "combine" }, npc_combinegunship = { "a gunship", "combine" }, npc_helicopter = { "a gunship", "combine" },
    npc_rollermine = { "a rollermine", "combine" }, npc_vortigaunt = { "a vortigaunt", "resistance" },
    npc_antlion = { "an antlion", "wild" }, npc_antlionguard = { "an antlion guard", "wild" },
    lc_forcefield = { "a forcefield", "combine" }, prop_combine_ball = { "an energy ball", "combine" },
    lc_rscanner = NPC_ROLES.scanner,
}

-- Who (or what) another entity was, to the dead: a phrase, and what people will say it was.
local function Killer(ply, ent, depth)
    if not IsValid(ent) or ent == ply or (game.GetWorld and ent == game.GetWorld()) then return nil end
    if ent:IsPlayer() then
        -- what people will say is what it looked like: a rebel passing as a citizen is just somebody
        local f = ent:GetNW2String("lcf_faction", "")
        local who = PersonTo(ply, ent)
        local openly = (LC.PlayerIsHunted and LC.PlayerIsHunted(ent)) or string.find(who, "Resistance", 1, true)
        local said = ((f == "cp" or (LC.DisguisedAsCP and LC.DisguisedAsCP(ent))) and "combine")
            or (f == "resistance" and openly and "resistance") or (f == "zombie" and "infestation") or "someone"
        return who, said
    end
    local st = LC.NPCs and LC.NPCs[ent]
    local known = (st and NPC_ROLES[st.role]) or CLASSES[ent:GetClass()]
    if known then return known[1], known[2] end
    -- a grenade, a thrown thing: whoever it belongs to
    if (depth or 0) < 2 and ent.GetOwner and IsValid(ent:GetOwner()) then return Killer(ply, ent:GetOwner(), (depth or 0) + 1) end
    if ent.IsNPC and ent:IsNPC() then return "something", nil end
    return nil
end

-- How they died, in a line for the card, and what people will say it was.
function LC.DeathCause(ply, attacker)
    if ply.lcDownCause then return ply.lcDownCause[1], ply.lcDownCause[2] end -- (put down first: that's what did it)
    local hurt = ply.lcLastHurt
    if hurt and CurTime() - (hurt.at or 0) > RECENT then hurt = nil end
    local bits = hurt and hurt.bits or 0
    local who, said = Killer(ply, attacker)
    if not who and hurt then who, said = Killer(ply, hurt.attacker) end
    if not who and hurt then who, said = Killer(ply, hurt.inflictor) end
    if who then
        if said == "infestation" or said == "wild" then return "Killed by " .. who .. ".", said end
        if Has(bits, D.BULLET) or Has(bits, D.BUCKSHOT) then return "Shot by " .. who .. ".", said end
        if Has(bits, D.CLUB) or Has(bits, D.SLASH) then return "Beaten to death by " .. who .. ".", said end
        if Has(bits, D.BLAST) then return "Blown up by " .. who .. ".", said end
        if Has(bits, D.BURN) or Has(bits, D.SLOWBURN) then return "Burned to death by " .. who .. ".", said end
        if Has(bits, D.DISSOLVE) then return "Disintegrated by " .. who .. ".", said end
        if Has(bits, D.NERVEGAS) or Has(bits, D.POISON) then return "Gassed by " .. who .. ".", said end
        return "Killed by " .. who .. ".", said
    end
    if Has(bits, D.FALL) then return "A fall.", "fall" end
    if Has(bits, D.DROWN) then return "Drowned.", "drowned" end
    if Has(bits, D.BURN) or Has(bits, D.SLOWBURN) then return "Burned to death.", "accident" end
    if Has(bits, D.BLAST) then return "An explosion.", "accident" end
    if Has(bits, D.VEHICLE) then return "Hit by a vehicle.", "accident" end
    if Has(bits, D.CRUSH) then return "Crushed.", "accident" end
    if Has(bits, D.SHOCK) then return "Electrocuted.", "accident" end
    if Has(bits, D.DISSOLVE) then return "Disintegrated.", "combine" end
    if Has(bits, D.NERVEGAS) or Has(bits, D.POISON) or Has(bits, D.ACID) then return "Poisoned.", "sick" end
    if Has(bits, D.RADIATION) then return "Radiation sickness.", "sick" end
    if LC.Hunger and LC.Hunger(ply) <= 0 then return "Starved.", "hunger" end
    if LC.Thirst and LC.Thirst(ply) <= 0 then return "Died of thirst.", "thirst" end
    if LC.HasParasites and LC.HasParasites(ply) and hurt then return "Sickness: parasites.", "sick" end
    return "Nobody saw how.", nil
end

-- Put down first: whoever did that is what the card says, however it ends.
hook.Add("LivingCityDowned", "LivingCityLifeCause", function(ply, attacker)
    if not IsValid(ply) then return end
    ply.lcDownCause = nil
    local line, said = LC.DeathCause(ply, attacker)
    ply.lcDownCause = { line, said }
end)
hook.Add("LivingCityRevived", "LivingCityLifeCause", function(ply) if IsValid(ply) then ply.lcDownCause = nil end end)

------------------------------------------------------------------------
-- Who knows each citizen number
------------------------------------------------------------------------

local KNOWN_FILE, WORD_FILE = "livingcity/known.json", "livingcity/word.json"
local known, word
local dirtyK, dirtyW = false, false

local function Load(path)
    local t = LC.SafeReadJSON(path)
    return istable(t) and t or {}
end
local function Known() if not known then known = Load(KNOWN_FILE) end return known end
local function Word() if not word then word = Load(WORD_FILE) end return word end

local function Save()
    if not dirtyK and not dirtyW then return end
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    if dirtyK then LC.SafeWrite(KNOWN_FILE, util.TableToJSON(Known())) dirtyK = false end
    if dirtyW then LC.SafeWrite(WORD_FILE, util.TableToJSON(Word())) dirtyW = false end
end
LC.SaveLifeData = Save
timer.Create("LivingCityLifeSave", 10, 0, Save)
hook.Add("ShutDown", "LivingCityLife", Save)

local function Me(ply) return ply:SteamID() .. "|" .. ply:GetNW2String("lc_cid", "") end

-- knower now knows the person with this citizen number.
function LC.NoteKnows(knower, cid)
    if not IsValid(knower) or not isstring(cid) or cid == "" then return end
    local mine = knower:GetNW2String("lc_cid", "")
    if mine == "" or mine == cid then return end
    local k = Known()
    k[cid] = k[cid] or {}
    local key = Me(knower)
    if not k[cid][key] then
        k[cid][key] = true
        dirtyK = true
    end
end

-- Everyone this person already knew, from before anyone kept count.
local function Backfill(ply)
    if not IsValid(ply) then return end
    local recog = util.JSONToTable(ply:GetPData("lc_recog", "") or "") or {}
    for cid, yes in pairs(recog) do
        if yes then LC.NoteKnows(ply, tostring(cid)) end
    end
end
LC.BackfillKnown = Backfill

function LC.KnownByCount(cid, exceptSid)
    local n = 0
    for key in pairs(Known()[cid] or {}) do
        if string.match(key, "^(.*)|") ~= exceptSid then n = n + 1 end
    end
    return n
end

-- A person who's gone takes what they knew with them.
local function Forget(sid, cid)
    if not sid or not cid or cid == "" then return end
    local key = sid .. "|" .. cid
    for c, t in pairs(Known()) do
        if t[key] then
            t[key] = nil
            dirtyK = true
            if next(t) == nil then Known()[c] = nil end
        end
    end
    local w = Word()[sid]
    if w then
        local keep = {}
        for _, e in ipairs(w) do if e.knower ~= cid then keep[#keep + 1] = e end end
        if #keep ~= #w then
            Word()[sid] = #keep > 0 and keep or nil
            dirtyW = true
        end
    end
end
LC.ForgetKnower = Forget

hook.Add("LivingCityIntroduced", "LivingCityLife", function(from, to)
    if IsValid(from) and IsValid(to) then LC.NoteKnows(to, from:GetNW2String("lc_cid", "")) end
end)

------------------------------------------------------------------------
-- Word gets around
------------------------------------------------------------------------

local OPENERS = { "%s is dead.", "You hear that %s died.", "Someone tells you %s is dead." }
local TAILS = {
    combine = " They say it was the Combine.", resistance = " They say it was the Resistance.",
    infestation = " The infestation, they say.", someone = " Somebody killed them, people say.",
    fall = " A fall, they say.", drowned = " Drowned, they say.", hunger = " Starved, they say.",
    thirst = " Thirst, they say.", sick = " Sick, they say.", accident = " An accident, they say.",
    wild = " Something out past the walls, they say.",
}

function LC.WordText(name, said)
    return string.format(OPENERS[math.random(#OPENERS)], name) .. (said and TAILS[said] or "")
end

local function Tell(ply, text)
    if IsValid(ply) then ply:ChatPrint("[Word gets around] " .. text) end
end

-- One knower's queue, told now (staggered) if they're the person who knew.
local function Deliver(ply)
    if not IsValid(ply) then return 0 end
    local sid = ply:SteamID()
    local w = Word()[sid]
    if not w then return 0 end
    local mine, now = ply:GetNW2String("lc_cid", ""), os.time()
    local keep, told = {}, 0
    for _, e in ipairs(w) do
        if now - (tonumber(e.at) or 0) > WORD_DAYS * 86400 then
            -- (too long ago to matter now)
        elseif e.knower == mine then
            told = told + 1
            local text = e.text
            timer.Simple(told * 6, function() if IsValid(ply) and ply:GetNW2String("lc_cid", "") == mine then Tell(ply, text) end end)
        else
            keep[#keep + 1] = e
        end
    end
    Word()[sid] = #keep > 0 and keep or nil
    dirtyW = true
    return told
end
LC.DeliverWord = Deliver

local function Queue(sid, entry)
    local w = Word()
    w[sid] = w[sid] or {}
    table.insert(w[sid], entry)
    while #w[sid] > WORD_KEEP do table.remove(w[sid], 1) end
    dirtyW = true
end

local function SpreadWord(dead, cid, text, killer)
    local online = {}
    for _, p in ipairs(player.GetAll()) do online[p:SteamID()] = p end
    local deadSid = dead:SteamID()
    for key in pairs(Known()[cid] or {}) do
        local sid, kcid = string.match(key, "^(.*)|(.*)$")
        local p = sid and online[sid]
        if sid and sid ~= deadSid and not (IsValid(p) and p == killer) then
            if IsValid(p) and p:GetNW2String("lc_cid", "") == kcid then
                local delay = WORD_MIN + math.random() * (WORD_MAX - WORD_MIN)
                timer.Simple(delay, function()
                    if IsValid(p) and p:GetNW2String("lc_cid", "") == kcid then Tell(p, text)
                    elseif IsValid(p) then Queue(sid, { knower = kcid, text = text, at = os.time() }) end
                end)
            else
                -- away, or playing someone else: when they're back as the person who knew them
                Queue(sid, { knower = kcid, text = text, at = os.time() })
            end
        end
    end
end

hook.Add("PlayerInitialSpawn", "LivingCityLife", function(ply)
    timer.Simple(6, function() Backfill(ply) end)
    timer.Simple(40, function() Deliver(ply) end) -- (once they've found their feet)
end)

hook.Add("LivingCityCharacterSwitched", "LivingCityLife", function(ply)
    Backfill(ply)
    timer.Simple(20, function() Deliver(ply) end)
end)

-- a new life (death, a staff decision): what the old person knew goes with them
hook.Add("LivingCityNewCharacter", "LivingCityLife", function(ply, oldName, why, oldCid)
    if IsValid(ply) and oldCid then Forget(ply:SteamID(), oldCid) end
end)

-- a character slot deleted (sv_livingcity_slots.lua)
hook.Add("LivingCityCharacterDeleted", "LivingCityLife", function(ply, cid)
    if IsValid(ply) and cid then Forget(ply:SteamID(), cid) end
end)

------------------------------------------------------------------------
-- The card
------------------------------------------------------------------------

-- Called as someone dies (sv_livingcity_character.lua), before anything of
-- theirs is cleared away. gone: this person is over (permanent death). note:
-- for a death that isn't, why not.
function LC.RecordDeath(ply, gone, attacker, note)
    if not IsValid(ply) then return nil end
    local lived = LC.FlushLived(ply)
    ply.lcLivedMark = nil
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    local cid = ply:GetNW2String("lc_cid", "")
    local card = { gone = gone and true or false, name = name, cid = cid, wait = LC.RespawnWait(), note = note }
    if gone then
        local line, said = LC.DeathCause(ply, attacker)
        card.lived = math.floor(lived)
        card.full = ply:GetPData("lc_lived_full", "0") == "1"
        card.known = LC.KnownByCount(cid, ply:SteamID())
        card.cause = line
        local m = string.lower(ply:GetModel() or "")
        card.she = (string.find(m, "female", 1, true) or string.find(m, "police_fem", 1, true)
            or string.find(m, "alyx", 1, true) or string.find(m, "mossman", 1, true)) and true or false
        if cvWord:GetBool() and cid ~= "" then
            local killer = IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply and attacker or nil
            SpreadWord(ply, cid, LC.WordText(name, said), killer)
        end
        if cid ~= "" and Known()[cid] then
            Known()[cid] = nil
            dirtyK = true
        end
    end
    ply.lcDownCause = nil
    if LC.SendCompressed then LC.SendCompressed("lc_obituary", card, { ply }) end
    hook.Run("LivingCityLifeEnded", ply, card)
    return card
end

------------------------------------------------------------------------
-- !bob
------------------------------------------------------------------------

local function Bob(ply)
    local sv = GetConVar("lc_view_bob")
    if sv and not sv:GetBool() then
        ply:ChatPrint("[Living City] The camera sway is off for everyone on this server.")
        return
    end
    ply:ConCommand("lc_bob_toggle")
end
LC.SlashCommands.bob = Bob

hook.Add("PlayerSay", "LivingCityLifeChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!bob" then Bob(ply) return "" end
end)
