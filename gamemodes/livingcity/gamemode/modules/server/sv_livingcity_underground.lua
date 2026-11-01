--[[
    Living City: the underground

    Contraband, and the people who look for it.

      Stops        Civil Protection NPCs stop and frisk people: often at
                   checkpoints, much more during inspection sweeps, and now
                   and then on the street. Stand still while they do it.
                   Walking off makes you wanted for evading inspection.
      Searches     units (players) search people with the Arrest Baton
                   (reload) or !search. Hidden things can slip past (Guile
                   helps). What's found is confiscated and you're wanted.
                   Arrest confiscates everything illegal you were carrying.
      Papers       stops check your papers. Forged papers and a dead man's
                   papers give you a new identity: your wanted status clears
                   if no unit is watching, but a close look can catch it.
                   A travel permit gets you past one curfew stop.
      Disguises    a Civil Protection uniform fools security NPCs and opens
                   CP doors, until a unit asks for your designation, a Combine
                   door reads your biosignal, or you commit a crime. Citizen
                   clothes let hunted Resistance members pass as citizens,
                   until someone checks their face against the wanted notices.
      Radios       Union radios hear city notices before the loudspeakers and
                   talk on the Union band (Civil Protection monitors it).
                   Retuned radios use Freq 7 and pick up CP dispatch, garbled.
                   Chat: !r <message>, and !ru <message> for the Union band.
      Lockpicks    open locked doors. Bypass charges open Combine doors too.
      Stash        8 extra slots in your own housing block (!stash, or F2
                   while you're home, or E on a stove or a fridge there).
                   A street search doesn't reach it; a raid on your block can.
      Black market a dealer placed with the editor or, on maps without one,
                   rebel territory (!market). Units who find a dealer bust it.
]]

if CLIENT then return end

util.AddNetworkString("lcu_market")
util.AddNetworkString("lcu_decode")
util.AddNetworkString("lcu_buy")
util.AddNetworkString("lcu_sell")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvStops     = CreateConVar("lc_stops", "1", FLAGS, "Civil Protection NPCs stop and search players")
local cvStopCD    = CreateConVar("lc_stop_cooldown", "480", FLAGS, "Seconds before NPCs can stop the same person again")
local cvStopPct   = CreateConVar("lc_stop_chance", "15", FLAGS, "Percent chance per check that a cop at a checkpoint stops you (doubled during sweeps)")
local cvStreetPct = CreateConVar("lc_street_stop_chance", "1", FLAGS, "Percent chance per check that a cop on the street stops you")
local cvSearchCD  = CreateConVar("lc_search_cooldown", "120", FLAGS, "Seconds before Civil Protection units can search the same person again")
local cvRisk      = CreateConVar("lc_disguise_risk", "5", FLAGS, "Percent chance per minute near security that a CP disguise is questioned")
local cvIdentity  = CreateConVar("lc_identity_minutes", "30", FLAGS, "How long a forged identity holds")
local cvStash     = CreateConVar("lc_stash_size", "8", FLAGS, "Slots in your hidden stash at home")
local cvRaid      = CreateConVar("lc_raid_chance", "25", FLAGS, "Percent chance an inspection sweep raids a stash with contraband in it")
local cvGuns      = CreateConVar("lc_search_weapons", "1", FLAGS, "Searches confiscate guns from citizens (Living City factions only)")

local function Pick(t) return t[math.random(#t)] end
local function Skill(ply, s) return LC.SkillMod and LC.SkillMod(ply, s) or 0 end

-- A d20 check: a natural 20 always works, a natural 1 never does.
local function Check(ply, skill, dc)
    local roll = math.random(20)
    return roll == 20 or (roll ~= 1 and roll + Skill(ply, skill) >= dc)
end

local function Watched(ply, dist) return LC.SeenBySecurity and LC.SeenBySecurity(ply, dist or 800) or false end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "somewhere in the city" end

local function Faction(ply) return ply:GetNW2String("lcf_faction", "") end

local function Free(ply)
    return IsValid(ply) and ply:Alive() and not (LC.InCustody and LC.InCustody(ply))
end

------------------------------------------------------------------------
-- Radios
------------------------------------------------------------------------

local BAND_NAMES = { union = "Union band", resistance = "Freq 7", cp = "CP net" }

function LC.RadioBand(ply)
    if LC.PlayerIsCP(ply) then return "cp" end
    if LC.HasItem(ply, "radio_tuned") then return "resistance" end
    if LC.HasItem(ply, "radio") then return "resistance" end -- (an old one: Freq 7, like every civilian radio now)
    return nil
end

-- Everyone who hears a band. CP traffic also leaks, garbled, to retuned radios.
local function Hears(ply, band)
    if not IsValid(ply) or (LC.Prisoners and LC.Prisoners[ply]) then return false end
    local mine = LC.RadioBand(ply)
    if not mine then return false end
    if band == "union" then return true end -- every radio picks up the Union band, and CP monitors it
    if band == "resistance" and LC.HasItem(ply, "radio_tuned") then return true end -- (a unit carrying a Freq 7 radio: an Insider, or a confiscated one)
    return mine == band
end
LC.HearsBand = Hears

local function Garble(text)
    local out = {}
    for w in string.gmatch(text, "%S+") do
        out[#out + 1] = math.random() < 0.3 and string.rep("-", math.min(#w, 6)) or w
    end
    return table.concat(out, " ")
end

function LC.RadioNotice(band, text)
    local name = BAND_NAMES[band] or band
    for _, p in ipairs(player.GetAll()) do
        if Hears(p, band) and band == "cp" and LC.Jammed and LC.Jammed(p:GetPos()) then
            p:ChatPrint("[" .. name .. "] *static* " .. Garble(Garble(text)))
        elseif Hears(p, band) then
            p:ChatPrint("[" .. name .. "] " .. text)
        elseif band == "cp" and LC.RadioBand(p) == "resistance" and not (LC.Prisoners and LC.Prisoners[p]) then
            p:ChatPrint("[Intercept] " .. Garble(text))
        end
    end
end

-- What someone can transmit on: the CP net (every unit, issued), and Freq 7 (a Freq 7 radio and a
-- radio transmitter, contraband). Nobody transmits on the Union band: it's the city's, for listening.
-- A Resistance Insider (a unit with both) has the two, and switches between them (right click).
function LC.TransmitBands(ply)
    local out = {}
    if not IsValid(ply) then return out end
    if LC.PlayerIsCP(ply) then out[#out + 1] = "cp" end
    if LC.HasItem(ply, "radio_tuned") and LC.HasItem(ply, "radio_transmitter") then out[#out + 1] = "resistance" end
    return out
end
function LC.CanTransmit(ply) return #LC.TransmitBands(ply) > 0 end
-- The frequency they're tuned to send on (kept while they still have it, else the first they have).
function LC.TransmitBand(ply)
    local bands = LC.TransmitBands(ply)
    for _, b in ipairs(bands) do if b == ply.lcTxBand then return b end end
    ply.lcTxBand = bands[1]
    return bands[1]
end
function LC.TuneTransmitter(ply)
    local bands = LC.TransmitBands(ply)
    if #bands < 2 then return LC.TransmitBand(ply) end
    local cur = LC.TransmitBand(ply)
    for i, b in ipairs(bands) do if b == cur then ply.lcTxBand = bands[i % #bands + 1] break end end
    return ply.lcTxBand
end

function LC.RadioSay(ply, text, band)
    local mine = LC.RadioBand(ply)
    if not mine then return false, "You don't have a radio." end
    if band == "union" then return false, "Nobody talks on the Union band: it's the city's, for listening." end
    if not LC.CanTransmit(ply) then
        return false, "Your radio only listens. To talk on Freq 7 you need a radio transmitter (black market, or the Resistance lab) and a Freq 7 radio."
    end
    band = band or LC.TransmitBand(ply)
    if LC.Prisoners and LC.Prisoners[ply] then return false, "Your radio was taken when you were processed." end
    if not table.HasValue(LC.TransmitBands(ply), band) then return false, "Your transmitter isn't on that band." end
    if band == "cp" and LC.Jammed and LC.Jammed(ply:GetPos()) then return false, "Static. Something nearby is jamming the band." end
    text = string.sub(string.Trim(text or ""), 1, 200)
    if text == "" then return false, "Say what?" end
    local who = (band == "cp" and ply:GetNW2String("lcf_title", "") ~= "" and ply:GetNW2String("lcf_title", "")) or ply:Nick()
    LC.RadioNotice(band, who .. ": " .. text)
    if band == "cp" then ply:EmitSound("npc/metropolice/vo/on1.wav", 50) end
    return true
end

-- The radio transmitter held up (weapon_lc_radio, next to Hands): everything typed and said goes out on the
-- band instead, and only someone right beside you (lc_radio_overhear, 110 units, about two metres)
-- hears you directly. You have the radio while you carry one (units always do).
local cvOverhear = CreateConVar("lc_radio_overhear", "110", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "How close someone must stand to hear what you say into your radio (units)")
local RADIO_SWEP = "weapon_lc_radio"

function LC.RadioRaised(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
    return IsValid(w) and w:GetClass() == RADIO_SWEP and LC.CanTransmit(ply)
end

local function Overheard(ply, listener)
    local r = math.max(0, cvOverhear:GetFloat())
    return listener ~= ply and listener:GetPos():DistToSqr(ply:GetPos()) < r * r
end

-- A line typed with the radio up. True if it went over the radio (so nothing else says it).
function LC.RadioRaisedSay(ply, text)
    if not LC.RadioRaised(ply) then return false end
    local t = string.Trim(text or "")
    if t == "" or string.find(t, "^[!/@%.]") then return false end -- (commands, /me, out of character: as usual)
    if ply.lcRadioSaidAt == CurTime() and ply.lcRadioSaidText == t then return true end -- (both chat hooks see it)
    ply.lcRadioSaidAt, ply.lcRadioSaidText = CurTime(), t
    local band = LC.TransmitBand(ply)
    local ok, why = LC.RadioSay(ply, t)
    if not ok then ply:ChatPrint("[Radio] " .. why) return true end
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    for _, p in ipairs(player.GetAll()) do
        if Overheard(ply, p) and not Hears(p, band) then p:ChatPrint(name .. " (into a radio): " .. t) end
    end
    return true
end

-- Voice with the radio up: everyone on the band hears it (wherever they are), anyone right beside
-- you hears it from where you stand, and nobody else. Returns nil when the radio isn't up.
function LC.RadioVoice(listener, talker)
    if not LC.RadioRaised(talker) then return nil end
    if Overheard(talker, listener) then return true, true end
    local band = LC.TransmitBand(talker)
    if band == "cp" and LC.Jammed and LC.Jammed(talker:GetPos()) then return false, false end
    if Hears(listener, band) then return true, false end
    return false, false
end

-- Who has the transmitter to hold up: anyone with a radio and a radio transmitter in their pockets, and every unit.
function LC.SyncRadioSwep(ply)
    if not IsValid(ply) or not ply:Alive() or not ply.Give then return end
    local has = ply:HasWeapon(RADIO_SWEP)
    local should = LC.CanTransmit(ply) and not (LC.Prisoners and LC.Prisoners[ply])
        and not (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) and not (LC.PlayerIsStalker and LC.PlayerIsStalker(ply))
    if should and not has then
        ply:Give(RADIO_SWEP)
    elseif has and not should then
        if LC.RadioRaised(ply) or (ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == RADIO_SWEP) then
            if ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end
        end
        ply:StripWeapon(RADIO_SWEP)
    end
end
hook.Add("LivingCityInventoryChanged", "LivingCityRadioSwep", function(ply) timer.Simple(0, function() LC.SyncRadioSwep(ply) end) end)
hook.Add("PlayerSpawn", "LivingCityRadioSwep", function(ply) timer.Simple(2, function() LC.SyncRadioSwep(ply) end) end)
timer.Create("LivingCityRadioSwep", 5, 0, function() for _, p in ipairs(player.GetAll()) do LC.SyncRadioSwep(p) end end)

local RADIO_CMDS = { ["!r"] = true, ["/r"] = true, ["!radio"] = true, ["/radio"] = true } -- (!ru is gone: nobody talks on the Union band)

hook.Add("PlayerSay", "LivingCityRadio", function(ply, text)
    if LC.RadioRaisedSay(ply, text) then return "" end
    local cmd, rest = string.match(text, "^(%S+)%s*(.*)$")
    local mode = cmd and RADIO_CMDS[string.lower(cmd)]
    if not mode then return end
    local ok, why = LC.RadioSay(ply, rest, mode ~= true and mode or nil)
    if not ok then ply:ChatPrint("[Radio] " .. why) end
    return ""
end)

-- City notices reach radios before the loudspeakers.
local EVENT_TITLES = { rations = "ration distribution", sweep = "civil status inspections", curfew = "curfew", lockdown = "lockdown", raid = "a housing block inspection" }
local WHISPERS = {
    sweep = "Civil Protection units are gearing up for a sweep. Move anything you don't want found.",
    curfew = "Curfew's coming. Get where you need to be.",
    lockdown = "Lockdown incoming. Get off the street.",
    raid = "Civil Protection units are about to go through a housing block. Anything they find is traced to whoever it belongs to.",
    supply = "A Combine convoy is coming through. Lots of crates, not many guards.",
}

hook.Add("LivingCityEventSoon", "LivingCityRadio", function(name, secs)
    local title = EVENT_TITLES[name] or name
    -- the Union band only announces the routine ones; the rest are surprises
    if LC.PublicEvents and LC.PublicEvents[name] then
        LC.RadioNotice("union", string.format("Notice: %s begins in %d seconds.", title, math.floor(secs)))
    end
    if WHISPERS[name] then LC.RadioNotice("resistance", WHISPERS[name]) end
end)

local lastDispatch = setmetatable({}, { __mode = "k" })
hook.Add("LivingCityWanted", "LivingCityRadio", function(ply, reason)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (lastDispatch[ply] or 0) > CurTime() then return end
    lastDispatch[ply] = CurTime() + 20
    local alias = ply:GetNW2String("lcd_alias", "")
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        LC.RadioNotice("cp", string.format("Dispatch: all units, suspect %s, %s. Last seen %s.",
            alias ~= "" and ("citizen " .. alias) or ply:Nick(), string.lower(reason or "malcompliance"), Where(ply:GetPos())))
    end)
end)

hook.Add("LivingCityIncarcerated", "LivingCityRadio", function(target)
    if IsValid(target) and target:IsPlayer() then
        LC.RadioNotice("cp", "Dispatch: suspect " .. target:Nick() .. " in custody.")
    end
end)

------------------------------------------------------------------------
-- Disguises
------------------------------------------------------------------------

-- Player models (not the NPC ones, which have no player animations).
-- Your own face is kept where the clothes allow it: the same citizen in
-- Union blue or the Resistance's colours.
local DISGUISE_MODELS = {
    cp = { "models/player/police.mdl", "models/player/police_fem.mdl" },
    citizen = { "models/player/group01/male_02.mdl", "models/player/group01/male_04.mdl", "models/player/group01/male_07.mdl",
        "models/player/group01/female_01.mdl", "models/player/group01/female_04.mdl" },
    rebel = { "models/player/group03/male_02.mdl", "models/player/group03/male_04.mdl", "models/player/group03/male_07.mdl",
        "models/player/group03/female_01.mdl", "models/player/group03/female_04.mdl" },
}
local DISGUISE_GROUP = { citizen = "group01", rebel = "group03" }

local function DisguiseModel(ply, wear)
    local group = DISGUISE_GROUP[wear]
    local base = string.match(ply:GetNW2String("lc_model", ""), "([^/]+)%.mdl$")
    if group and base and string.find(base, "male", 1, true) then
        return "models/player/" .. group .. "/" .. base .. ".mdl"
    end
    if wear == "cp" then
        local female = base and string.find(base, "female", 1, true)
        return female and DISGUISE_MODELS.cp[2] or DISGUISE_MODELS.cp[1]
    end
    return Pick(DISGUISE_MODELS[wear] or DISGUISE_MODELS.citizen)
end
LC.DisguiseModel = DisguiseModel

function LC.Disguise(ply)
    local d = IsValid(ply) and ply:GetNW2String("lcd_disguise", "") or ""
    return d ~= "" and d or nil
end
function LC.DisguisedAsCP(ply) return LC.Disguise(ply) == "cp" end
function LC.PassesAsCitizen(ply) return LC.Disguise(ply) == "citizen" end
function LC.DisguisedAsRebel(ply) return LC.Disguise(ply) == "rebel" end
LC.FoolsSecurity = LC.DisguisedAsCP -- security NPCs take you for a unit

function LC.TakeOff(ply, quiet, lose)
    local kind = LC.Disguise(ply)
    if not kind then return false end
    ply:SetNW2String("lcd_disguise", "")
    timer.Simple(0.2, function() if IsValid(ply) and LC.DressPlayer then LC.DressPlayer(ply) end end) -- (battle gear on or off with it)
    ply:SetNW2String("lcd_title", "")
    if ply.lcdOldModel and ply:Alive() then ply:SetModel(ply.lcdOldModel) end
    local id = ply.lcdItem
    ply.lcdOldModel, ply.lcdItem, ply.lcdDoors = nil, nil, nil
    if id and not lose and ply:Alive() then LC.GiveOrDrop(ply, id) end
    if not quiet then ply:ChatPrint("You change back into your own clothes.") end
    return true
end

function LC.BlowDisguise(ply, why)
    local kind = LC.Disguise(ply)
    if not kind then return false end
    LC.TakeOff(ply, true, true)
    ply:ChatPrint("[Disguise] " .. why .. " Your disguise is blown.")
    ply:EmitSound("npc/metropolice/vo/holdit.wav", 70)
    if kind == "cp" then
        LC.ReportCrime(ply, "Impersonating a Civil Protection officer", 300)
        if LC.MakeCopsHostile then LC.MakeCopsHostile(ply, ply:GetPos(), 2000) end
    elseif kind == "rebel" and LC.RebelAlarms then
        -- the fighters around you know now: no warning shout this time
        LC.RebelAlarms[ply] = { at = CurTime() - 60 }
    end
    -- hunted Resistance in plain clothes are simply recognized again
    hook.Run("LivingCityDisguiseBlown", ply, kind)
    return true
end

-- Resistance members have clothes of their own to change into: no item needed.
local OWN_CLOTHES = { plain = "citizen", gear = "rebel" }

function LC.Wear(ply, id)
    local it = LCS.Items[id]
    if OWN_CLOTHES[id] then it = { wear = OWN_CLOTHES[id], own = true } end
    if not it or not it.wear or not (it.own or LC.HasItem(ply, id)) then return false end
    -- filthy clothes: spare citizen clothes are just clean clothes (sv_livingcity_hygiene.lua)
    if LC.CleanClothes and LC.CleanClothes[id] and LC.SoilNeeds and LC.SoilNeeds(ply).clothes then return LC.ChangeClothes(ply, id) end
    if LC.Disguise(ply) then return false, "You're already in disguise. Take it off first." end
    if not Free(ply) or LC.PlayerIsZombie(ply) then return false, "Not now." end
    if LC.InCombat and LC.InCombat(ply) then return false, "Not in the middle of a fight." end
    if it.wear == "cp" and LC.PlayerIsCP(ply) then return false, "You don't need a disguise to be a Civil Protection unit." end
    if it.wear == "rebel" and ply:GetNW2String("lcf_faction", "") == "resistance" then return false, "You're one of them already. (!gearup puts your own gear on.)" end
    if not it.own then LC.TakeItem(ply, id) end
    ply.lcdOldModel = ply:GetModel()
    ply.lcdItem = (not it.own) and id or nil
    ply.lcdDoors = {}
    ply:SetModel(DisguiseModel(ply, it.wear))
    if ply.SetupHands then ply:SetupHands() end
    ply:SetNW2String("lcd_disguise", it.wear)
    timer.Simple(0.2, function() if IsValid(ply) and LC.DressPlayer then LC.DressPlayer(ply) end end) -- (battle gear on or off with it)
    ply:SetNW2String("lcd_title", (it.wear == "cp" and string.format("CP %s-%d", Pick({ "05", "04", "03" }), math.random(1000, 9999)))
        or (it.wear == "rebel" and "Resistance") or "Citizen")
    ply:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 55)
    if Watched(ply, 800) then
        LC.BlowDisguise(ply, "A Civil Protection unit watched you change.")
        return true
    end
    if it.wear == "cp" then
        if LC.CalmCops then LC.CalmCops(ply) end
        ply:ChatPrint("[Disguise] You're a Civil Protection unit now, as far as anyone on the street can tell. Don't fight, don't linger near real units, and stay away from Combine doors unless you're feeling lucky.")
    elseif it.wear == "rebel" then
        ply:ChatPrint("[Disguise] Resistance colours. The fighters in rebel territory will take you for one of them, for a while. Out on the streets, Civil Protection units will take you for one of them too.")
    elseif it.own then
        ply:ChatPrint("[Disguise] Plain clothes. You're just another citizen. Keep your gun out of sight: a Civil Protection unit who sees it will know. (F1 > Gear up to change back.)")
    else
        ply:ChatPrint("[Disguise] Union blue, like everyone else. Nobody looks twice at a citizen. Until they check your face.")
    end
    hook.Run("LivingCityDisguised", ply, it.wear)
    return true
end

-- Combine doors read biosignals. A uniform doesn't have one.
function LC.DisguiseDoorCheck(ply, door)
    if not LC.DisguisedAsCP(ply) then return false end
    ply.lcdDoors = ply.lcdDoors or {}
    local known = ply.lcdDoors[door]
    if known ~= nil then return known end
    local fooled = math.random() >= math.max(0.04, 0.15 - Skill(ply, "guile") * 0.01)
    if fooled then
        ply.lcdDoors[door] = true
        return true
    end
    LC.BlowDisguise(ply, "The door reads your biosignal and sounds an alarm.")
    return false
end

-- Any new crime blows a CP disguise; hunted Resistance get recognized.
hook.Add("LivingCityWanted", "LivingCityDisguise", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if LC.DisguisedAsCP(ply) then
        LC.BlowDisguise(ply, "Civil Protection units don't do that.")
    elseif LC.PassesAsCitizen(ply) and LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then
        LC.BlowDisguise(ply, "Someone recognized you.")
    end
end)

-- Hanging around real units is the risky part.
local DESIGNATION_FAILS = {
    "A Civil Protection unit asks for your designation. You give one that doesn't exist.",
    "A Civil Protection unit tries to sync with your mask radio. There's nothing to sync with.",
    "A Civil Protection unit looks at your boots for a long second. They're civilian issue.",
}
-- A gun in your hand gives plain clothes away.
local FIREARMS = { weapon_pistol = true, weapon_357 = true, weapon_smg1 = true, weapon_ar2 = true, weapon_shotgun = true,
    weapon_crossbow = true, weapon_rpg = true, weapon_frag = true }
timer.Create("LivingCityDisguiseGuns", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and LC.PassesAsCitizen(ply) then
            local w = ply:GetActiveWeapon()
            if IsValid(w) and FIREARMS[w:GetClass()] and Watched(ply, 700) then
                LC.BlowDisguise(ply, "A Civil Protection unit saw the gun in your hand.")
            end
        end
    end
end)

-- A Combine plant in Resistance colours gets asked questions.
local REBEL_QUESTIONS = {
    "A fighter asks who vouched for you. You give a name. Nobody knows it.",
    "Someone asks which cell you're from. You hesitate a moment too long.",
    "A fighter looks at your boots. Civil Protection issue.",
}
timer.Create("LivingCityDisguiseRebelRisk", 15, 0, function()
    if not LC.Running then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and LC.DisguisedAsRebel(ply) then
            local close = false
            for npc, st in pairs(LC.NPCs or {}) do
                if IsValid(npc) and st.role == "rebel" and npc:GetPos():DistToSqr(ply:GetPos()) < 350 * 350 then close = true break end
            end
            if close and math.random() < math.max(0.04, 0.12 - Skill(ply, "guile") * 0.008) then
                LC.BlowDisguise(ply, Pick(REBEL_QUESTIONS))
            end
        end
    end
end)

timer.Create("LivingCityDisguiseRisk", 15, 0, function()
    if not LC.Running then return end
    local p = cvRisk:GetFloat() / 100 / 4
    if p <= 0 then return end
    for _, ply in ipairs(player.GetAll()) do
        if LC.DisguisedAsCP(ply) and ply:Alive() and Watched(ply, 400) then
            if math.random() < math.max(0.004, p - Skill(ply, "guile") * 0.002) then
                LC.BlowDisguise(ply, Pick(DESIGNATION_FAILS))
            end
        end
    end
end)

------------------------------------------------------------------------
-- Papers and identities
------------------------------------------------------------------------

local DETECT = { forged = 0.30, dead = 0.15 }

function LC.Identity(ply)
    local id = ply.lcIdentity
    if id and CurTime() < id.untilT then return id end
    return nil
end

local function ClearIdentity(ply)
    ply.lcIdentity = nil
    ply:SetNW2String("lcd_alias", "")
end

function LC.AssumeIdentity(ply, itemId)
    local it = LCS.Items[itemId]
    if not it or not it.papers or not LC.HasItem(ply, itemId) then return false end
    if not Free(ply) then return false, "Not now." end
    if Watched(ply, 1000) then return false, "Not with a Civil Protection unit watching." end
    LC.TakeItem(ply, itemId)
    local alias = (LC.QB and LC.QB.CitizenID and LC.QB.CitizenID())
        or string.format("#%02d-%03d", math.random(10, 99), math.random(100, 999))
    ply.lcIdentity = { kind = it.papers, alias = alias, untilT = CurTime() + cvIdentity:GetFloat() * 60 }
    ply:SetNW2String("lcd_alias", alias)
    local wasWanted = LC.PlayerIsWanted(ply)
    LC.ClearWanted(ply)
    if wasWanted and LC.CalmCops then LC.CalmCops(ply) end
    ply:ChatPrint(string.format("[Papers] As far as the city knows, you're citizen %s now. Nobody is looking for %s.", alias, alias))
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) and not LC.PassesAsCitizen(ply) then
        ply:ChatPrint("[Papers] Your face is still on the notices, though. Citizen clothes would help.")
    end
    hook.Run("LivingCityNewIdentity", ply, alias)
    return true
end

-- Returns true if the papers hold up, or false and why not.
function LC.CheckPapers(ply)
    local id = LC.Identity(ply)
    -- (a face the lab changed isn't on any notice: sv_livingcity_lab.lua)
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) and LC.PassesAsCitizen(ply) and not id and ply:GetPData("lc_new_face", "0") ~= "1" then
        return false, "Your face matches a wanted notice."
    end
    if id then
        local p = math.max(0.03, (DETECT[id.kind] or 0.3) - Skill(ply, "guile") * 0.02)
        if math.random() < p then return false, "Your papers don't hold up to a close look." end
    end
    return true
end

function LC.PapersFailed(ply, why)
    why = why or "Your papers don't check out."
    local hadId = LC.Identity(ply) ~= nil
    ClearIdentity(ply)
    if LC.PassesAsCitizen(ply) and LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then
        LC.BlowDisguise(ply, why)
    else
        ply:ChatPrint("[Civil Protection] " .. why)
    end
    LC.ReportCrime(ply, hadId and "Forged identity papers" or "Wanted anticitizen", 300)
end

-- Curfew: a permit (or papers that say night shift) gets you past the stop.
function LC.CurfewExcuse(ply, cop)
    if LC.DisguisedAsCP(ply) then return true end
    if ply.lcPermitSerial and ply.lcPermitSerial == LC.EventSerial then return true end
    if LC.HasItem(ply, "permit") then
        LC.TakeItem(ply, "permit")
        ply.lcPermitSerial = LC.EventSerial
        if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/allrightyoucango.wav", 75) end
        ply:ChatPrint("[Civil Protection] The Civil Protection unit checks your permit and stamps it. You're cleared until this is over.")
        return true
    end
    if LC.Identity(ply) then
        local ok, why = LC.CheckPapers(ply)
        if ok then
            ply.lcPermitSerial = LC.EventSerial
            if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/allrightyoucango.wav", 75) end
            ply:ChatPrint("[Civil Protection] Your papers say night shift. The Civil Protection unit waves you on.")
        else
            LC.PapersFailed(ply, why)
        end
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Searches
------------------------------------------------------------------------

-- Guns citizens shouldn't have, and how easy each is to hide.
local ILLEGAL_WEAPONS = {
    weapon_crowbar = 0, weapon_pistol = 0.3, weapon_357 = 0.15, weapon_smg1 = 0, weapon_ar2 = 0, weapon_lc_multitool = 0.4, weapon_lc_microphone = 0.2,
    weapon_shotgun = 0, weapon_crossbow = 0, weapon_frag = 0.25, weapon_rpg = 0, weapon_slam = 0.2,
}

local function SearchWeapons(ply, extra)
    local out = {}
    if not cvGuns:GetBool() then return out end
    local guile = Skill(ply, "guile") * 0.03
    for _, w in ipairs(ply:GetWeapons()) do
        local cls = w:GetClass()
        local conceal = ILLEGAL_WEAPONS[cls]
        if conceal and math.random() >= math.Clamp(conceal + guile - (extra or 0), 0, 0.85) then out[#out + 1] = cls end
    end
    for _, cls in ipairs(out) do ply:StripWeapon(cls) end
    return out
end

-- Go through someone's pockets. Returns { { id, n } } of what was found and taken.
function LC.SearchPockets(ply, thoroughness)
    local inv = LC.Inventory(ply)
    local guile = Skill(ply, "guile") * 0.03
    local found = {}
    local ids = table.GetKeys(inv)
    table.sort(ids)
    for _, id in ipairs(ids) do
        local it = LCS.Items[id]
        if it and it.contraband then
            local slip = math.Clamp((it.conceal or 0) + guile - (thoroughness or 0), 0, 0.85)
            local caught = 0
            for _ = 1, inv[id] do if math.random() >= slip then caught = caught + 1 end end
            if caught > 0 then found[#found + 1] = { id = id, n = caught } end
        end
    end
    for _, f in ipairs(found) do LC.TakeItem(ply, f.id, f.n) end
    return found
end

local function Describe(found, guns)
    local names = {}
    for _, f in ipairs(found) do
        local it = LCS.Items[f.id]
        local gun = isstring(f.id) and string.sub(f.id, 1, 2) == "w:" and string.gsub(string.gsub(string.sub(f.id, 3), "^weapon_", ""), "_", " ")
        names[#names + 1] = (it and it.name or gun or f.id) .. (f.n > 1 and (" x" .. f.n) or "")
    end
    for _, cls in ipairs(guns or {}) do names[#names + 1] = string.gsub(string.gsub(cls, "^weapon_", ""), "_", " ") end
    return table.concat(names, ", ")
end

-- searcher: a unit (player) or a security NPC.
function LC.Search(searcher, target)
    local byPlayer = IsValid(searcher) and searcher:IsPlayer()
    local thorough = byPlayer and 0.1 or 0
    target.lcSearchedAt = CurTime()

    if LC.DisguisedAsCP(target) and byPlayer then
        LC.BlowDisguise(target, "Hands on, the uniform is obviously a costume.")
    end

    local found = LC.SearchPockets(target, thorough)
    local guns = SearchWeapons(target, thorough)
    local total = #guns
    for _, f in ipairs(found) do total = total + f.n end

    local tag = byPlayer and ("[" .. searcher:Nick() .. "]") or "[Civil Protection]"
    if total == 0 then
        target:ChatPrint(tag .. " Search complete. Nothing found.")
        if byPlayer then searcher:ChatPrint("[Search] " .. target:Nick() .. " is clean.") end
        hook.Run("LivingCitySearched", searcher, target, found, guns)
        return 0, found, guns
    end

    local list = Describe(found, guns)
    target:ChatPrint(tag .. " Confiscated: " .. list .. ".")
    if LC.AddStanding then LC.AddStanding(target, -10 * total, "Contraband confiscated") end
    LC.ReportCrime(target, "Possession of contraband", math.min(600, 120 + 60 * total))
    if byPlayer then
        searcher:ChatPrint("[Search] " .. target:Nick() .. " was carrying: " .. list .. ". Confiscated.")
        if LC.AddXP then LC.AddXP(searcher, 5 * total, "Contraband seized") end
        if LC.AddCredits then LC.AddCredits(searcher, 5 * total, "seizure bonus") end
        if LC.QuestEvent then LC.QuestEvent("seized", searcher, target) end
    end
    hook.Run("LivingCitySearched", searcher, target, found, guns)
    return total, found, guns
end

-- A unit searches the person in front of them: three seconds of standing still.
-- What a citizen on the street might be carrying. Sympathizers are far likelier to have something.
local NPC_CONTRABAND = {
    "a Resistance pamphlet", "an unregistered radio", "black market rations", "a crowbar wrapped in newspaper",
    "a lambda armband", "forged ration coupons", "a handful of pistol rounds",
}

-- A unit patting down an NPC citizen: they stop, hands out, and after a few
-- seconds you hear what was on them.
function LC.SearchNPC(cop, npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" then return false, "You can only search citizens." end
    if st.state == "jailed" or st.state == "escorted" or st.questLock or st.state == "exiting" then return false, "Not now." end
    if npc:GetPos():DistToSqr(cop:GetPos()) > 120 * 120 then return false, "Get closer." end
    local now = CurTime()
    if (st.searchedAt or -1e9) + 120 > now and not cop:IsAdmin() then return false, "You searched them a moment ago." end
    if st.beingSearched then return false, "They're already being searched." end
    st.searchedAt, st.beingSearched = now, true
    if LC.LeaveLine then LC.LeaveLine(npc, st) end
    if IsValid(st.ss) then st.ss:Fire("CancelSequence") st.ss:Remove() st.ss = nil end
    LC.Release(npc, st)
    npc:SetSchedule(SCHED_IDLE_STAND)
    LC.SetState(npc, st, "detained")
    st.untilT = now + 8
    LC.Face(npc, cop:GetPos())
    if LC.PlayGesture and LC.FRISKED_ANIMS then LC.PlayGesture(npc, LC.FRISKED_ANIMS, 4) end
    cop:EmitSound("npc/metropolice/vo/apply.wav", 65)
    cop:ChatPrint("[Search] Patting them down...")
    timer.Simple(3, function()
        if not IsValid(npc) or not LC.NPCs[npc] then return end
        st.beingSearched = nil
        if not IsValid(cop) or not cop:Alive() then return end
        if math.random() < (st.rebel and 0.5 or 0.1) then
            st.contraband = Pick(NPC_CONTRABAND)
            npc:EmitSound(LC.Sounds and LC.Sounds.Vo(st.gender or "male", "no02") or "", 70)
            cop:ChatPrint("[Search] Found " .. st.contraband .. ". Confiscated. Right click with the baton to detain them.")
            if LC.AddXP then LC.AddXP(cop, 3, "search") end
            st.untilT = CurTime() + 15 -- they stay put a while, waiting to see what you'll do
        else
            cop:ChatPrint("[Search] Nothing on them. Papers in order.")
            st.untilT = CurTime() + 1.5
        end
    end)
    return true
end

function LC.StartSearch(cop, target)
    if IsValid(target) and LC.NPCs and LC.NPCs[target] then
        if not (LC.PlayerIsCP(cop) or cop:IsAdmin()) then return false, "Only Civil Protection units can search people." end
        return LC.SearchNPC(cop, target)
    end
    if not IsValid(cop) or not IsValid(target) or not target:IsPlayer() then return false, "Search who?" end
    if not (LC.PlayerIsCP(cop) or cop:IsAdmin()) then return false, "Only Civil Protection units can search people." end
    if not target:Alive() or (LC.Prisoners and LC.Prisoners[target]) then return false, "Not now." end
    if LC.PlayerIsCP(target) and not cop:IsAdmin() then return false, "You don't search other Civil Protection units." end
    if target:GetPos():DistToSqr(cop:GetPos()) > 120 * 120 then return false, "Get closer." end
    if target.lcBeingSearched then return false, "They're already being searched." end
    if (target.lcSearchedAt or -1e9) + cvSearchCD:GetFloat() > CurTime() and not cop:IsAdmin() then
        return false, "They were searched a moment ago."
    end
    target.lcBeingSearched = cop
    target:SetNW2Float("lcu_stop_until", CurTime() + 3)
    target:ChatPrint("[Civil Protection] " .. cop:Nick() .. " is searching you. Stay still.")
    cop:ChatPrint("[Search] Searching " .. target:Nick() .. "...")
    cop:EmitSound("npc/metropolice/vo/apply.wav", 65)
    timer.Simple(3, function()
        if not IsValid(target) then return end
        target.lcBeingSearched = nil
        target:SetNW2Float("lcu_stop_until", 0)
        if not IsValid(cop) or not cop:Alive() or not target:Alive() then return end
        if target:GetPos():DistToSqr(cop:GetPos()) > 200 * 200 then
            cop:ChatPrint("[Search] " .. target:Nick() .. " walked away.")
            LC.ReportCrime(target, "Evading a search", 180)
            return
        end
        LC.Search(cop, target)
    end)
    return true
end

hook.Add("PlayerSay", "LivingCitySearchChat", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!search" then return end
    local tr = ply:GetEyeTrace()
    local ok, why = LC.StartSearch(ply, tr.Entity)
    if not ok then ply:ChatPrint("[Search] " .. why) end
    return ""
end)

-- Processing: anything illegal on you when you're arrested is gone.
hook.Add("LivingCityIncarcerated", "LivingCityConfiscate", function(target)
    if not IsValid(target) or not target:IsPlayer() then return end
    LC.TakeOff(target, true, true)
    ClearIdentity(target)
    local found = LC.SearchPockets(target, 1)
    if #found > 0 then target:ChatPrint("[Processing] Confiscated: " .. Describe(found) .. ".") end
end)

------------------------------------------------------------------------
-- Stop and search: Civil Protection NPCs frisk people on the street
------------------------------------------------------------------------

LC.Stops = LC.Stops or {} -- [ply] = { cop, cst, stage, untilT, origin }
local Stops = LC.Stops

local STOP_LINES = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/citizen.wav" }
local CLEAR_LINES = { "npc/metropolice/vo/allrightyoucango.wav", "npc/metropolice/vo/movealong.wav" }

-- Don't wreck someone in the middle of a delicate job (tailing, escorting).
local DELICATE = { tail = true, escort = true }
local function Busy(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and not q.done and q.stages and q.stages[q.stage]
    return st ~= nil and DELICATE[st.kind] == true
end
local function Exempt(ply) return Faction(ply) == "admin" or LCF.IsOverwatch(ply) end

local function Stoppable(ply, now)
    return ply:Alive() and not ply:InVehicle() and now > (ply.lcStopNext or 0)
        and not Exempt(ply) and not Busy(ply)
        and not Stops[ply] and not ply.lcBeingSearched
        and not LC.PlayerIsCP(ply) and not LC.PlayerIsZombie(ply)
        and not (LC.InCustody and LC.InCustody(ply)) and not LC.DisguisedAsCP(ply)
        and not LC.PlayerIsWanted(ply) -- the wanted get chased, not frisked
        and not (LC.InRebelZone and LC.InRebelZone(ply:GetPos()))
        and not (LC.InCombat and LC.InCombat(ply))
        and not (LC.EditorHeld and LC.EditorHeld(ply)) -- (an admin at work with the editor tool)
end

local function CopFree(st)
    return st.role == "cop" and not st.test and not st.questLock and (st.state == "idle" or st.state == "moving")
end

local function Sees(npc, ply) return LC.LineOfSight(npc:EyePos(), ply:EyePos(), npc) end

function LC.StartStop(cop, cst, ply)
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end -- (Combine property: nobody stops it)
    local now = CurTime()
    LC.SetState(cop, cst, "event")
    cst.eventUntil = now + 30
    LC.Face(cop, ply:GetPos())
    cop:EmitSound(Pick(STOP_LINES), 78)
    cop:SetLastPosition(LC.SpotInFrontOf and LC.SpotInFrontOf(ply, cop, 40) or ply:GetPos())
    cop:SetSchedule(SCHED_FORCED_GO)
    Stops[ply] = { cop = cop, cst = cst, stage = "approach", untilT = now + 12, origin = ply:GetPos() }
    ply.lcStopNext = now + cvStopCD:GetFloat()
    ply:SetNW2Float("lcu_stop_until", now + 16)
    ply:ChatPrint("[Civil Protection] Hold it right there. Stand still for inspection.")
    hook.Run("LivingCityPlayerStopped", ply, cop)
end

local function EndStop(ply, s)
    Stops[ply] = nil
    if IsValid(ply) then ply:SetNW2Float("lcu_stop_until", 0) end
    if IsValid(s.cop) and s.cst and s.cst.state == "event" then s.cst.eventUntil = 0 end
end

local function Evaded(ply, s)
    EndStop(ply, s)
    if IsValid(s.cop) then s.cop:EmitSound("npc/metropolice/vo/holdit.wav", 80) end
    if LC.CopShout then LC.CopShout(ply, s.cop, "Hold it! Get back here!", 3) end
    ply:ChatPrint("[Civil Protection] You walked away from an inspection.")
    LC.ReportCrime(ply, "Evading inspection", 180)
end

local function Resolve(ply, s)
    local cop = s.cop
    EndStop(ply, s)
    if LC.IntakeStopped and LC.IntakeStopped(ply, cop) then return end -- (no papers at all: sv_livingcity_intake.lua)
    local ok, why = LC.CheckPapers(ply)
    if not ok then
        cop:EmitSound("npc/metropolice/vo/prepareforjudgement.wav", 78)
        LC.PapersFailed(ply, why)
        return
    end
    local total = LC.Search(cop, ply)
    if total > 0 then
        cop:EmitSound("npc/metropolice/vo/prepareforjudgement.wav", 78)
    else
        cop:EmitSound(Pick(CLEAR_LINES), 75)
    end
end

local function RunStops(now)
    for ply, s in pairs(Stops) do
        local cop = s.cop
        if not IsValid(ply) or not Free(ply) or not IsValid(cop) or cop:Health() <= 0 or s.cst.state ~= "event" then
            EndStop(ply, s)
        else
            s.cst.eventUntil = now + 10
            local d2 = ply:GetPos():DistToSqr(cop:GetPos())
            if ply:GetPos():DistToSqr(s.origin) > 300 * 300 then
                Evaded(ply, s)
            elseif s.stage == "approach" then
                if d2 < 60 * 60 then
                    cop:SetSchedule(SCHED_IDLE_STAND)
                    LC.Face(cop, ply:GetPos())
                    cop:EmitSound("npc/metropolice/vo/apply.wav", 75)
                    if LC.PlayGesture then LC.PlayGesture(cop, LC.FRISK_ANIMS, 6) end
                    ply:ChatPrint("[Civil Protection] Papers. Arms out.")
                    s.stage, s.untilT = "frisk", now + 4
                    ply:SetNW2Float("lcu_stop_until", now + 4)
                elseif now > s.untilT then
                    EndStop(ply, s) -- couldn't get to them; let it go
                elseif not cop:IsCurrentSchedule(SCHED_FORCED_GO) then
                    cop:SetLastPosition(LC.SpotInFrontOf and LC.SpotInFrontOf(ply, cop, 40) or ply:GetPos())
                    cop:SetSchedule(SCHED_FORCED_GO)
                end
            elseif s.stage == "frisk" then
                LC.Face(cop, ply:GetPos())
                if d2 > 180 * 180 then
                    Evaded(ply, s)
                elseif now > s.untilT then
                    Resolve(ply, s)
                end
            end
        end
    end
end

local nextScan = 0
local function ScanForStops(now)
    if now < nextScan then return end
    nextScan = now + 3
    local players = player.GetAll()
    local cap = math.max(2, math.floor(#players / 16))
    if table.Count(Stops) >= cap then return end
    local sweep = LC.Event == "sweep"
    for _, ply in ipairs(players) do
        if Stoppable(ply, now) then
            for cop, cst in pairs(LC.NPCs or {}) do
                if IsValid(cop) and CopFree(cst) then
                    local atPost = cst.state == "idle" and cst.claim and cst.claim.kind == "checkpoint"
                    local range = (sweep or atPost) and 450 or 300
                    if cop:GetPos():DistToSqr(ply:GetPos()) < range * range then
                        local pct = sweep and cvStopPct:GetFloat() * 2 or (atPost and cvStopPct:GetFloat() or cvStreetPct:GetFloat())
                        pct = pct * (LC.SocioStopMul and LC.SocioStopMul() or 1) -- sociostability (sv_livingcity_cp.lua)
                        -- a loyalty test waiting for a real prisoner: the units go looking (sv_livingcity_stories.lua)
                        if LC.LoyaltyHunt and LC.LoyaltyHunt(ply) then pct = math.max(pct, 90) end
                        if math.random() * 100 < pct and Sees(cop, ply) then
                            LC.StartStop(cop, cst, ply)
                            if table.Count(Stops) >= cap then return end
                        end
                        break -- one roll per person per scan
                    end
                end
            end
        end
    end
end

timer.Create("LivingCityStops", 0.5, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        if not LC.Running or not cvStops:GetBool() or (LC.EndingSession and LC.EndingSession()) then -- (no inspections through an ending)
            for ply, s in pairs(Stops) do EndStop(ply, s) end
            return
        end
        RunStops(now)
        ScanForStops(now)
    end)
    if not ok then LC.Error("stops", err) end
end)

------------------------------------------------------------------------
-- Lockpicks and bypass charges
------------------------------------------------------------------------

LC.Picking = LC.Picking or {}
local Picking = LC.Picking

function LC.DoorPicked(door) return IsValid(door) and (door.lcPickedUntil or 0) > CurTime() end

local DoorLockKind
function LC.DoorLockKind(door) return DoorLockKind(door) end
DoorLockKind = function(door)
    local tag = LC.EffectiveDoorTag(door)
    local cp = tag == "cp" or tag == "prison"
    local locked = tag == "locked" or door:GetInternalVariable("m_bLocked") == true
    return cp, locked
end

function LC.StartPick(ply, id)
    local it = LCS.Items[id]
    if not it or not it.tool or not LC.HasItem(ply, id) then return false end
    local prisoner = LC.Prisoners and LC.Prisoners[ply]
    if not Free(ply) and not prisoner then return false, "Not now." end
    if Picking[ply] then return false, "You're already working on a lock." end
    local tr = ply:GetEyeTrace()
    local door = tr.Entity
    if not LC.IsDoorEntity(door) or tr.HitPos:DistToSqr(ply:EyePos()) > 110 * 110 then
        return false, "Look at a locked door, up close."
    end
    local cp, locked = DoorLockKind(door)
    if it.tool == "keycard" then
        if not cp then return false, "There's no card reader on that door." end
    elseif cp and it.tool ~= "bypass" and not (prisoner and it.tool == "lockpick") then
        -- (the old cell locks are mechanical underneath: from the inside, with time, a pick will do)
        return false, "That's a Combine lock. A pick won't touch it."
    end
    if not cp and not locked then return false, "It isn't locked." end
    if LC.DoorPicked(door) then return false, "It's already open." end
    local secs = (it.tool == "keycard" and 1.5) or (it.tool == "bypass" and 4) or (prisoner and 14) or 7
    Picking[ply] = { door = door, id = id, untilT = CurTime() + secs, cp = cp, locked = locked, prisoner = prisoner ~= nil }
    ply:SetNW2String("lcu_progress", id == "door_code" and "Punching in the code..." or (it.tool == "keycard" and "Swiping the card..." or "Working the lock... keep looking at it"))
    ply:SetNW2Float("lcu_pick_start", CurTime())
    ply:SetNW2Float("lcu_pick_until", CurTime() + secs)
    ply:EmitSound((it.tool == "bypass" or it.tool == "keycard") and "buttons/combine_button2.wav" or "doors/door_locked2.wav", 55)
    return true
end

local function StopPicking(ply, msg)
    Picking[ply] = nil
    if IsValid(ply) then
        ply:SetNW2Float("lcu_pick_until", 0)
        if msg then ply:ChatPrint(msg) end
    end
end

-- Open for 30 seconds, then shut (and locked again, if it was locked before).
local OpenPicked
function LC.OpenPickedDoor(door, relock) return OpenPicked(door, relock) end
OpenPicked = function(door, relock)
    door.lcPickedUntil = CurTime() + 30
    door:Fire("Unlock")
    door:Fire("Open", "", 0.1)
    if LC.OpenedDoors then LC.OpenedDoors[door] = nil end
    timer.Simple(30, function()
        if not IsValid(door) then return end
        door.lcPickedUntil = nil
        door:Fire("Close")
        if relock then door:Fire("Lock", "", 1) end
    end)
end

local function FinishPick(ply, p)
    StopPicking(ply)
    local it = LCS.Items[p.id]
    if not LC.HasItem(ply, p.id) then return end
    if p.prisoner and Watched(ply, 900) then
        -- a guard was watching the whole time
        LC.TakeItem(ply, p.id)
        local pr = LC.Prisoners and LC.Prisoners[ply]
        if pr then
            pr.untilT = pr.untilT + 120
            ply:SetNW2Float("lc_jail_until", pr.untilT)
        end
        return ply:ChatPrint("[Civil Protection] A guard takes the pick off you. Two more minutes for the trouble.")
    end
    if it.tool == "lockpick" then
        if not Check(ply, "guile", 8) then
            if math.random() < 0.4 then
                LC.TakeItem(ply, p.id)
                ply:EmitSound("physics/metal/metal_solid_impact_soft1.wav", 60)
                return ply:ChatPrint("Your pick snaps in the lock.")
            end
            return ply:ChatPrint("The lock won't give. Try again.")
        end
    elseif it.tool == "keycard" then
        LC.TakeItem(ply, p.id) -- flagged as stolen the moment it's used
        p.door:EmitSound("buttons/combine_button1.wav", 65)
    else
        LC.TakeItem(ply, p.id)
        if math.random() < math.max(0.05, 0.25 - Skill(ply, "nerve") * 0.02) then
            p.door:EmitSound("ambient/alarms/klaxon1.wav", 80)
            LC.ReportCrime(ply, "Tampering with Combine technology", 240)
        end
    end
    p.door:EmitSound("doors/door_latch3.wav", 65)
    OpenPicked(p.door, p.locked)
    ply:ChatPrint(p.id == "door_code" and "You punch in the code. The reader blinks green: they'll have changed it by tomorrow." or (it.tool == "keycard" and "The reader blinks green. The card won't work twice." or "The lock gives."))
    if Watched(ply, 900) then
        LC.ReportCrime(ply, it.tool == "keycard" and "Unauthorized use of a Civil Protection keycard" or "Breaking and entering", 180)
    end
    if LC.QuestEvent then LC.QuestEvent("picked", ply, p.door) end
    hook.Run("LivingCityLockPicked", ply, p.door, it.tool)
end

timer.Create("LivingCityPicking", 0.25, 0, function()
    local now = CurTime()
    for ply, p in pairs(Picking) do
        if not IsValid(ply) or not (Free(ply) or (LC.Prisoners and LC.Prisoners[ply])) or not IsValid(p.door) then
            StopPicking(ply)
        else
            local tr = ply:GetEyeTrace()
            if tr.Entity ~= p.door or ply:GetPos():DistToSqr(p.door:GetPos()) > 160 * 160 then
                StopPicking(ply, "You stop working on the lock.")
            elseif now >= p.untilT then
                FinishPick(ply, p)
            end
        end
    end
end)

------------------------------------------------------------------------
-- Forging papers
------------------------------------------------------------------------

local function Private(ply) return not LC.IsPrivate or LC.IsPrivate(ply) end

function LC.Forge(ply, id)
    local it = LCS.Items[id]
    if not it or not it.forge or not LC.HasItem(ply, id) then return false end
    if not Private(ply) then return false, "Not with someone watching. Get out of sight first." end
    if Watched(ply, 800) then return false, "Not with a Civil Protection unit watching." end
    LC.TakeItem(ply, id)
    if Check(ply, "guile", 11) then
        LC.GiveOrDrop(ply, "papers_forged")
        ply:ChatPrint("[Papers] Name, number, stamp. It looks right. It has to.")
        return true
    end
    ply:ChatPrint("[Papers] The ink bleeds across the number. The form is ruined.")
    return true
end

------------------------------------------------------------------------
-- The stash at home
------------------------------------------------------------------------

local function StashKey() return "lci_stash_" .. game.GetMap() end

function LC.Stash(ply)
    if ply.lcStash and ply.lcStashMap == game.GetMap() then return ply.lcStash end
    local raw = ply:GetPData(StashKey(), "")
    local t = raw ~= "" and util.JSONToTable(raw) or nil
    ply.lcStash = istable(t) and t or {}
    ply.lcStashMap = game.GetMap()
    return ply.lcStash
end

local function SaveStash(ply) ply:SetPData(StashKey(), util.TableToJSON(LC.Stash(ply))) end

local function StashCount(ply)
    local n = 0
    for k, c in pairs(LC.Stash(ply)) do if isnumber(c) then n = n + c end end -- (lcClips: what's in the guns' magazines)
    return n
end

-- Your stash is kept in the furniture at home: press E on a stove, fridge, dresser, wardrobe or
-- cupboard in your own block and it opens (F2 shows it while you stand by it). Not anywhere else.
local STASH_FURNITURE = { "fridge", "refrigerator", "stove", "oven", "dresser", "wardrobe", "drawer", "cupboard", "cabinet", "closet", "shelf", "bookcase" }
function LC.IsStashFurniture(ent)
    if not IsValid(ent) or not ent.GetModel then return false end
    local m = string.lower(ent:GetModel() or "")
    for _, w in ipairs(STASH_FURNITURE) do if string.find(m, w, 1, true) then return true end end
    return false
end
function LC.OpenStashAt(ply, pos)
    ply.lcStashAt = pos
    LC.SendInv(ply, true)
end
function LC.CanReachStash(ply)
    if not (Free(ply) and LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) == true) then return false end
    return ply.lcStashAt ~= nil and ply:GetPos():DistToSqr(ply.lcStashAt) < 160 * 160
end
hook.Add("PlayerUse", "LivingCityStashFurniture", function(ply, ent)
    if LC.IsStashFurniture(ent) and LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) and not LC.PlayerIsCP(ply)
        and (ply.lcStashUse or 0) < CurTime() then
        ply.lcStashUse = CurTime() + 1
        LC.OpenStashAt(ply, ent:GetPos())
    end
end)

function LC.StashStore(ply, id)
    if not LC.CanReachStash(ply) then return false, "Your stash is at home, in your own block." end
    if not LC.HasItem(ply, id) then return false end
    if LC.IssuedLocked and LC.IssuedLocked(ply, id) then return false, "That's Combine issue: it stays with you (or another unit)." end
    if StashCount(ply) >= cvStash:GetInt() then return false, "Your stash is full." end
    LC.TakeItem(ply, id)
    local st = LC.Stash(ply)
    st[id] = (st[id] or 0) + 1
    SaveStash(ply)
    return true
end

function LC.StashTake(ply, id)
    if not LC.CanReachStash(ply) then return false, "Your stash is at home, in your own block." end
    local st = LC.Stash(ply)
    if (st[id] or 0) < 1 then return false end
    local okC, whyC = LC.CanCarry(ply, id, 1)
    if not okC then return false, whyC end
    st[id] = st[id] - 1
    if st[id] <= 0 then st[id] = nil end
    SaveStash(ply)
    LC.GiveItem(ply, id)
    return true
end

-- Weapons in hand (a crowbar, a gun) go in too: "w:<class>", one stash place each,
-- with what's in the magazine. The ones your faction issues you stay with you.
local function WeaponName(cls) return (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " ")) end
LC.StashWeaponName = WeaponName
function LC.StashableWeapons(ply)
    local out = {}
    for _, w in ipairs(ply:GetWeapons()) do
        local cls = w and w.GetClass and w:GetClass()
        if cls and LCS.SellWeapons[cls] and not (LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls)) then
            out[#out + 1] = { cls = cls, name = WeaponName(cls) }
        end
    end
    table.sort(out, function(a, b) return a.cls < b.cls end)
    return out
end

function LC.StashStoreWeapon(ply, cls)
    if not LC.CanReachStash(ply) then return false, "Your stash is at home, in your own block." end
    if not isstring(cls) or not LCS.SellWeapons[cls] or not ply:HasWeapon(cls) then return false end
    local w = ply.GetWeapon and ply:GetWeapon(cls)
    if LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls) then return false, "That was issued to you. It stays with you." end
    if StashCount(ply) >= cvStash:GetInt() then return false, "Your stash is full." end
    local st = LC.Stash(ply)
    local key = "w:" .. cls
    st[key] = (st[key] or 0) + 1
    local clip = IsValid(w) and w.Clip1 and w:Clip1() or -1
    if clip and clip > 0 then
        st.lcClips = istable(st.lcClips) and st.lcClips or {}
        st.lcClips[key] = (st.lcClips[key] or 0) + clip
    end
    ply:StripWeapon(cls)
    SaveStash(ply)
    ply:EmitSound("physics/metal/weapon_impact_soft" .. math.random(1, 3) .. ".wav", 55)
    return true, "You hide the " .. WeaponName(cls) .. " away."
end

function LC.StashTakeWeapon(ply, key)
    if not LC.CanReachStash(ply) then return false, "Your stash is at home, in your own block." end
    local st = LC.Stash(ply)
    if not isstring(key) or (st[key] or 0) < 1 then return false end
    local cls = string.sub(key, 3)
    if ply:HasWeapon(cls) then return false, "You've one of those on you already." end
    st[key] = st[key] - 1
    if st[key] <= 0 then st[key] = nil end
    local w = ply:Give(cls, true)
    local clips = istable(st.lcClips) and st.lcClips or nil
    if clips and clips[key] then
        if IsValid(w) and w.SetClip1 then w:SetClip1(clips[key]) end
        clips[key] = nil
        if next(clips) == nil then st.lcClips = nil end
    end
    SaveStash(ply)
    return true
end

-- Sweeps sometimes reach people's homes.
hook.Add("LivingCityEventStarted", "LivingCityStashRaids", function(name)
    if name ~= "sweep" then return end
    for _, ply in ipairs(player.GetAll()) do
        local st = LC.Stash(ply)
        local found = {}
        for id, n in pairs(st) do
            if LCS.Items[id] and LCS.Items[id].contraband then found[#found + 1] = { id = id, n = n } end
            if isstring(id) and string.sub(id, 1, 2) == "w:" and isnumber(n) then found[#found + 1] = { id = id, n = n, weapon = true } end
        end
        if #found > 0 and math.random() * 100 < cvRaid:GetFloat() then
            for _, f in ipairs(found) do st[f.id] = nil if istable(st.lcClips) then st.lcClips[f.id] = nil end end
            SaveStash(ply)
            local home = LC.PlayerBlock and LC.PlayerBlock(ply)
            ply:ChatPrint(string.format("[Civil Protection] Your residence%s was searched. Confiscated: %s.",
                home and (" in " .. LC.BlockName(home)) or "", Describe(found)))
            if LC.AddStanding then LC.AddStanding(ply, -40, "Contraband found in your residence") end
            hook.Run("LivingCityStashRaided", ply, found)
        end
    end
end)

concommand.Add("lci_stash", function(ply) if IsValid(ply) then LC.SendInv(ply, true) end end)
hook.Add("PlayerSay", "LivingCityStashChat", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!stash" then return end
    if not LC.CanReachStash(ply) then
        ply:ChatPrint("[Stash] Your stash is at home, in " .. (LC.PlayerBlock and LC.PlayerBlock(ply) and LC.BlockName(LC.PlayerBlock(ply)) or "your housing block") .. ": press E on a stove, fridge, dresser or wardrobe there.")
    else
        LC.SendInv(ply, true)
    end
    return ""
end)

------------------------------------------------------------------------
-- The black market
------------------------------------------------------------------------

local function Dealers()
    local out = {}
    for _, f in ipairs(LC.EntsOf("lc_dealer")) do out[#out + 1] = f end
    return out
end

local function NearDealer(ply)
    for _, f in ipairs(Dealers()) do
        if not f:GetNW2Bool("lc_busted", false) and f:GetPos():DistToSqr(ply:GetPos()) < 180 * 180 then return f end
    end
    return nil
end

local BARRED = { ota = "Overwatch doesn't shop.", admin = "The Administrator has people for this.", zombie = "..." }
-- What the quartermaster won't buy: the lab decodes it (sv_livingcity_heist.lua, sv_livingcity_lab.lua)
local DECODED = { data_chip = true, master_chip = true }

function LC.MarketAccess(ply)
    if LC.PlayerIsCP(ply) then return false, "Nobody here sells anything to a Civil Protection unit." end
    if LC.PlayerIsZombie(ply) then return false, "..." end
    local f = Faction(ply)
    if BARRED[f] then return false, BARRED[f] end
    if NearDealer(ply) then return true end
    if f == "resistance" and LC.NearQuartermaster and LC.NearQuartermaster(ply) then return true end -- he only sells to his own
    local dealers = Dealers()
    if #dealers == 0 and LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then return true end
    if #dealers > 0 then return false, "Find the dealer." end
    return false, "There's no black market here. Try rebel territory, or ask an admin to place a dealer."
end

function LC.OpenMarket(ply)
    local ok, why = LC.MarketAccess(ply)
    if not ok then
        ply:ChatPrint("[Black market] " .. why)
        return false
    end
    local credits = LC.Credits and LC.Credits(ply) or 0
    local goods, sell = {}, {}
    -- the quartermaster (and no dealer here): he won't buy the Combine's data; the lab decodes it
    local qm = LC.AtQuartermaster(ply) or nil
    for _, g in ipairs(LCS.Black) do
        local can, reason = true, nil
        local price = LC.MarketPrice(ply, g)
        if credits < price then can, reason = false, "Not enough credits" end
        if can and g.item and not LC.CanCarry(ply, g.item, g.count or 1) then can, reason = false, "Too much to carry" end
        goods[#goods + 1] = { id = g.id, name = g.name, price = price, desc = g.desc, ok = can, why = reason }
    end
    local inv = LC.Inventory(ply)
    local ids = table.GetKeys(inv)
    table.sort(ids)
    for _, id in ipairs(ids) do
        local it = LCS.Items[id]
        local price = LC.SellPrice and LC.SellPrice(ply, id) or (it and it.sell)
        if it and price and not (qm and DECODED[id]) then sell[#sell + 1] = { id = id, name = it.name, n = inv[id], price = price } end
    end
    -- weapons you're carrying, unless your faction issued them
    for _, w in ipairs(ply:GetWeapons()) do
        local cls = w:GetClass()
        local price = LCS.SellWeapons[cls]
        if price and not (LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls)) then
            sell[#sell + 1] = { id = "w:" .. cls, name = (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " ")), n = 1, price = price, weapon = true }
        end
    end
    LC.SendCompressed("lcu_market", { credits = credits, goods = goods, sell = sell, quartermaster = qm }, { ply })
    return true
end

-- At the quartermaster: a chip decoded, from his menu.
net.Receive("lcu_decode", function(_, ply)
    local id = net.ReadString()
    if not DECODED[id] or not LC.DecodeChip then return end
    local ok, why = LC.DecodeChip(ply, id)
    if not ok and why then ply:ChatPrint("[Quartermaster] " .. why) end
    if ok then ply:ChatPrint("[Quartermaster] He plugs it into a battered laptop and reads. 'This is good. Get the word out.'") end
    LC.OpenMarket(ply)
end)

-- what the city's state does to prices (sv_livingcity_war.lua)
function LC.BlackPrice(g)
    return math.max(1, math.floor(g.price * (LC.BlackPriceMul and LC.BlackPriceMul() or 1) + 0.5))
end

-- Buying from the quartermaster (a Resistance member at his post, no dealer about): he charges
-- his own what the lab does (lc_lab_price of the dealer's price), not the dealer's markup.
function LC.AtQuartermaster(ply)
    return Faction(ply) == "resistance" and not NearDealer(ply) and LC.NearQuartermaster and LC.NearQuartermaster(ply) and true or false
end
function LC.QuartermasterPrice(g)
    if LC.LabPrice then return LC.LabPrice({ out = g.id, item = g.item }) end
    return LC.BlackPrice(g)
end
function LC.MarketPrice(ply, g)
    if IsValid(ply) and LC.AtQuartermaster(ply) then return LC.QuartermasterPrice(g) end
    return LC.BlackPrice(g)
end

function LC.BlackBuy(ply, id)
    local g = LCS.BlackById[id]
    if not g then return false end
    local ok, why = LC.MarketAccess(ply)
    if not ok then return false, why end
    local price = LC.MarketPrice(ply, g)
    if LC.Credits(ply) < price then return false, "Not enough credits." end
    if g.item then local okC, whyC = LC.CanCarry(ply, g.item, g.count or 1) if not okC then return false, whyC end end
    LC.AddCredits(ply, -price)
    if g.item then LC.GiveItem(ply, g.item, g.count or 1) elseif g.weapon then ply:Give(g.weapon) end
    ply:ChatPrint(string.format("[Black market] %s, for %d credits. You didn't get it here.", g.name, price))
    return true
end

-- Sell one of something (or all of it): pocket items, or a weapon as "w:<class>".
function LC.DealerSell(ply, id, all)
    local ok, why = LC.MarketAccess(ply)
    if not ok then return false, why end
    local cls = string.match(id or "", "^w:(.+)$")
    if cls then
        local price = LCS.SellWeapons[cls]
        if not price or not ply:HasWeapon(cls) then return false end
        if LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls) then return false, "That was issued to you. The dealer doesn't want it." end
        ply:StripWeapon(cls)
        LC.AddCredits(ply, price)
        ply:ChatPrint(string.format("[Black market] Sold: %s, for %d credits.", (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " ")), price))
        return true
    end
    local it = LCS.Items[id]
    local price = LC.SellPrice and LC.SellPrice(ply, id) or (it and it.sell)
    if not it or not price or not LC.HasItem(ply, id) then return false end
    if DECODED[id] and not NearDealer(ply) and LC.NearQuartermaster and LC.NearQuartermaster(ply) then
        return false, "The quartermaster doesn't buy those. Take it to the lab: the scientist decodes them."
    end
    local n = all and (LC.Inventory(ply)[id] or 1) or 1
    LC.TakeItem(ply, id, n)
    LC.AddCredits(ply, price * n)
    if id == "ration_forged" then hook.Run("LivingCityForgedCard", ply, n) end -- (the search for the forger: sv_livingcity_funding.lua)
    if it.intel and LC.AddXP then LC.AddXP(ply, 5 * n, "intel") end
    ply:ChatPrint(string.format("[Black market] Sold: %s%s, for %d credits.", it.name, n > 1 and (" x" .. n) or "", price * n))
    if it.arms and LC.NearQuartermaster and LC.NearQuartermaster(ply) and LC.AddTrait then LC.AddTrait(ply, "sympathy", 1) end
    return true
end

net.Receive("lcu_buy", function(_, ply)
    local ok, why = LC.BlackBuy(ply, net.ReadString())
    if not ok and why then ply:ChatPrint("[Black market] " .. why) end
    LC.OpenMarket(ply)
end)

net.Receive("lcu_sell", function(_, ply)
    local id = net.ReadString()
    local ok, why = LC.DealerSell(ply, id, net.ReadBool())
    if not ok and why then ply:ChatPrint("[Black market] " .. why) end
    LC.OpenMarket(ply)
end)

function LC.BustDealer(cop, dealer)
    if not IsValid(dealer) or dealer:GetNW2Bool("lc_busted", false) then return false end
    dealer:SetNW2Bool("lc_busted", true)
    dealer:SetNotSolid(true)
    dealer:EmitSound("npc/metropolice/vo/holdit.wav", 80)
    if IsValid(cop) then
        cop:ChatPrint("[Civil Protection] The dealer bolts. You confiscate what's left of the stock.")
        if LC.AddCredits then LC.AddCredits(cop, 20, "black market busted") end
        if LC.AddXP then LC.AddXP(cop, 10, "Busted a dealer") end
        if LC.AddStanding then LC.AddStanding(cop, 10) end
    end
    LC.RadioNotice("resistance", "The dealer " .. Where(dealer:GetPos()) .. " got raided. Stay away for a while.")
    timer.Simple(900, function()
        if not IsValid(dealer) then return end
        dealer:SetNW2Bool("lc_busted", false)
        dealer:SetNotSolid(false)
    end)
    hook.Run("LivingCityDealerBusted", cop, dealer)
    return true
end

hook.Add("PlayerSay", "LivingCityMarketChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t ~= "!market" and t ~= "!blackmarket" and t ~= "!dealer" then return end
    LC.OpenMarket(ply)
    return ""
end)

------------------------------------------------------------------------
-- Inventory actions and what the inventory window needs to know
------------------------------------------------------------------------

-- !pick (or bind a key to lc_pick): use the right tool you're carrying on the door you're looking at.
function LC.QuickPick(ply)
    local tr = ply:GetEyeTrace()
    local door = tr.Entity
    if not LC.IsDoorEntity(door) or tr.HitPos:DistToSqr(ply:EyePos()) > 110 * 110 then
        return false, "Look at a locked door, up close."
    end
    local cp = DoorLockKind(door)
    local order = cp and { "cp_keycard", "bypass" } or { "lockpick" }
    for _, id in ipairs(order) do
        if LC.HasItem(ply, id) then return LC.StartPick(ply, id) end
    end
    return false, cp and "That's a Combine lock. You need a keycard or a bypass charge." or "You don't have a lockpick. Make one from four pieces of scrap (F2), or find the dealer."
end

concommand.Add("lc_pick", function(ply)
    if not IsValid(ply) then return end
    local ok, why = LC.QuickPick(ply)
    if not ok and why then ply:ChatPrint(why) end
end)

hook.Add("PlayerSay", "LivingCityQuickPick", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!pick" then return end
    local ok, why = LC.QuickPick(ply)
    if not ok and why then ply:ChatPrint(why) end
    return ""
end)

function LC.UndergroundAction(ply, action, id)
    local it = id and LCS.Items[id]
    local ok, why
    if action == "eatchip" then -- (Father Grigori, the motherlode: sv_livingcity_endings.lua)
        if LC.EatChip then ok, why = LC.EatChip(ply) end
    elseif action == "takeoff" then
        ok = LC.TakeOff(ply)
    elseif action == "wear" then
        if id == "plain" or id == "gear" then
            if id == "gear" then ok = LC.TakeOff(ply) else ok, why = LC.Wear(ply, "plain") end
        else
            if not it or not it.wear then return true end
            ok, why = LC.Wear(ply, id)
        end
    elseif action == "craft" and id == "scrap" then
        -- bend four bits of scrap into something that opens a lock
        if not LC.HasItem(ply, "scrap", 4) then
            why = "You need four pieces of scrap."
        else
            LC.TakeItem(ply, "scrap", 4)
            LC.GiveItem(ply, "lockpick")
            ply:EmitSound("physics/metal/metal_solid_impact_soft2.wav", 60)
            why = "You bend and file the scrap into a lockpick set."
        end
        ok = false
    elseif action == "store" then
        ok, why = LC.StashStore(ply, id)
    elseif action == "wstore" then
        ok, why = LC.StashStoreWeapon(ply, id)
        if ok and why then ply:ChatPrint("[Stash] " .. why) why = nil end
    elseif action == "take" then
        if isstring(id) and string.sub(id, 1, 2) == "w:" then ok, why = LC.StashTakeWeapon(ply, id) else ok, why = LC.StashTake(ply, id) end
    elseif action == "use" and it then
        if it.tool then
            ok, why = LC.StartPick(ply, id)
        elseif it.papers then
            ok, why = LC.AssumeIdentity(ply, id)
        elseif it.forge then
            ok, why = LC.Forge(ply, id)
        elseif it.wear then
            ok, why = LC.Wear(ply, id)
        elseif it.permit then
            why = "Keep it on you. It's shown when a Civil Protection unit stops you during curfew."
        elseif it.radio then
            why = it.radio == "resistance" and "It only listens. With a radio transmitter too, you can talk on Freq 7: switch to the Radio transmitter (next to Hands), or !r <message>."
                or "It only listens: nobody talks on the Union band, it's the city's. Press Listen to hear it."
        elseif it.rationCard then
            why = "Use any ration dispenser."
        else
            return false
        end
    else
        return false
    end
    if not ok and why then ply:ChatPrint(why) end
    return true
end

function LC.InvExtras(ply, t)
    t.container = LC.ContainerView and LC.ContainerView(ply) or nil
    t.notes = LC.NotesForInv and LC.NotesForInv(ply) or nil
    t.disguise = LC.Disguise(ply)
    t.alias = LC.Identity(ply) and LC.Identity(ply).alias or nil
    if LC.CanReachStash(ply) then
        t.stash = {}
        for k, v in pairs(LC.Stash(ply)) do if isnumber(v) then t.stash[k] = v end end
        t.stashSize = cvStash:GetInt()
        t.stashWeapons = LC.StashableWeapons(ply)
    end
end

------------------------------------------------------------------------
-- Upkeep
------------------------------------------------------------------------

timer.Create("LivingCityUnderground", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local band = LC.RadioBand(ply) or ""
        if ply:GetNW2String("lcu_band", "") ~= band then ply:SetNW2String("lcu_band", band) end
        if ply.lcIdentity and not LC.Identity(ply) then
            ClearIdentity(ply)
            ply:ChatPrint("[Papers] Your borrowed name has worn thin. You're yourself again.")
        end
    end
end)

hook.Add("PlayerDeath", "LivingCityUnderground", function(ply)
    LC.TakeOff(ply, true, true) -- the disguise is ruined
    ClearIdentity(ply)
    StopPicking(ply)
    if Stops[ply] then EndStop(ply, Stops[ply]) end
end)

hook.Add("PlayerDisconnected", "LivingCityUnderground", function(ply)
    if ply.lcdItem then LC.GiveItem(ply, ply.lcdItem) end -- you keep your uniform overnight
    Stops[ply], Picking[ply] = nil, nil
end)

concommand.Add("lc_search", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    if not target then return end
    local n, found, guns = LC.Search(ply, target)
    local msg = string.format("%s searched: %d item(s) confiscated%s", target:Nick(), n, n > 0 and (": " .. Describe(found, guns)) or "")
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)

concommand.Add("lc_giveitem", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    local id = args[2]
    if not target or not id or not LCS.Items[id] then
        local msg = "Usage: lc_giveitem <name> <item> [count]"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    LC.GiveOrDrop(target, id, math.Clamp(tonumber(args[3]) or 1, 1, 20))
end)

------------------------------------------------------------------------
-- The Resistance's own plain clothes
------------------------------------------------------------------------

local cvPlain = CreateConVar("lc_resistance_plainclothes", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Resistance members come back to life in plain clothes, and change with !plainclothes and !gearup")

hook.Add("PlayerSay", "LivingCityPlainClothes", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!plainclothes" or t == "!plain" or t == "!civvies" then
        if ply:GetNW2String("lcf_faction", "") ~= "resistance" then ply:ChatPrint("You don't have anything else to wear. (Find some clothes.)") return "" end
        local ok, why = LC.Wear(ply, "plain")
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
    if t == "!gearup" or t == "!gear" then
        if LC.Disguise(ply) then LC.TakeOff(ply) else ply:ChatPrint("You're already in your own clothes.") end
        return ""
    end
end)

hook.Add("PlayerSpawn", "LivingCityPlainClothes", function(ply)
    if not cvPlain:GetBool() then return end
    timer.Simple(2.5, function()
        if not IsValid(ply) or not ply:Alive() or ply:GetNW2String("lcf_faction", "") ~= "resistance" then return end
        if ply:GetNW2String("lcf_special", "") ~= "" or LC.Disguise(ply) then return end
        if LC.Wear(ply, "plain") then
            ply:ChatPrint("[Resistance] You're in plain clothes. F1 > Gear up when it's time to fight.")
        end
    end)
end)

-- The Union radio is gone (the owner, 2026-11-01): one still in someone's pockets becomes the Freq 7 radio
-- every civilian radio now is.
hook.Add("PlayerSpawn", "LivingCityNoUnionRadio", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) or not LC.HasItem or not LC.HasItem(ply, "radio") then return end
        local n = (LC.Inventory(ply) or {}).radio or 1
        LC.TakeItem(ply, "radio", n)
        LC.GiveItem(ply, "radio_tuned", n)
    end)
end)
