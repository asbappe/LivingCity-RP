--[[
    Living City: what custody costs the worst anticitizens

    A longer sentence isn't much of a deterrent, so the city doesn't just add
    time. How it treats you depends on how much of an anticitizen you are: your
    Civil Standing, whether you're a hunted Resistance fighter, how often you've
    been brought in, and whether it was for violence (LC.Severity, 0 and up).

      2+  Interrogation  a unit comes to the cell and asks questions, with a
                         stun baton. Answer (!talk) and the beating stops: you
                         name a Resistance hideout (marked for every unit) and
                         gain a little standing, but the Resistance hear that
                         you talked. Stay silent and take it (it won't kill you).
      4+  Broken feet    on top of that, they break your feet: no running for
                         lc_cripple_minutes (15), even after release, even
                         after death.
      6+  Stalker        the worst are not released at all: they're made into
                         stalkers (lc_stalkers 1). Combine property: slow,
                         unarmed, unable to speak, put to work. There is no
                         way out but death (then, with permanent death off,
                         you're back in the city as a broken citizen). Only
                         for the Resistance's own (or anyone hunted as one)
                         who have killed (a unit, a soldier or a citizen) or
                         are brought in for murder: a citizen locked up again
                         and again for small things is never made one.

      lc_custody_punish 0/1, lc_cripple_minutes (15), lc_stalkers 0/1,
      lc_stalker_model
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_custody_punish", "1", FLAGS, "Interrogation, broken feet and stalkers for the worst anticitizens in custody")
local cvCripple = CreateConVar("lc_cripple_minutes", "15", FLAGS, "Minutes without running after the city breaks your feet")
local cvStalker = CreateConVar("lc_stalkers", "1", FLAGS, "The worst anticitizens are made into stalkers instead of released")
local cvStalkMdl = CreateConVar("lc_stalker_model", "", FLAGS, "Playermodel for stalkers. Blank: a stalker playermodel if one is installed (Workshop 268895264), else a corpse")

local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- How bad you are
------------------------------------------------------------------------

function LC.JailCount(ply) return tonumber(ply:GetPData("lc_jailcount", 0)) or 0 end

function LC.Severity(ply, reason)
    if not IsValid(ply) then return 0 end
    local s = 0
    local standing = LC.Standing and LC.Standing(ply) or 0
    if standing < -50 then s = s + 2 end   -- an anticitizen
    if standing < -250 then s = s + 1 end
    if standing < -500 then s = s + 1 end
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then s = s + 2 end
    local n = LC.JailCount(ply)
    if n >= 3 then s = s + 1 end
    if n >= 5 then s = s + 1 end
    local r = string.lower(reason or "")
    if string.find(r, "kill", 1, true) or string.find(r, "murder", 1, true) or string.find(r, "assault", 1, true) then s = s + 1 end
    return s
end

------------------------------------------------------------------------
-- Interrogation
------------------------------------------------------------------------

local QUESTIONS = {
    "Who are your contacts?", "Where do they meet?", "Who gave you the weapon?",
    "Where is the hideout?", "Names. Give me names.", "Who else knows?",
}
LC.Interrogations = LC.Interrogations or {} -- [ply] = { cop, hits, untilT, talked }
local COOP_REWARD = 50 -- civil standing for answering (offered up front)

local function EndInterrogation(ply, text)
    local it = LC.Interrogations[ply]
    if not it then return end
    LC.Interrogations[ply] = nil
    if IsValid(it.cop) then
        if LC.NPCs then LC.NPCs[it.cop] = nil end
        it.cop:Remove()
    end
    if IsValid(ply) then
        ply:SetNW2Bool("lc_interrogated", false)
        if text then ply:ChatPrint(text) end
    end
end

function LC.CanInterrogate(ply)
    if not IsValid(ply) then return false end
    return ply:GetNW2String("lcf_faction", "") == "resistance"
        or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply)) == true
        or (LC.DisguisedAsRebel and LC.DisguisedAsRebel(ply)) == true
end

function LC.StartInterrogation(ply)
    if LC.Interrogations[ply] or not (LC.Prisoners and LC.Prisoners[ply]) then return false end
    local pr = LC.Prisoners[ply]
    local cellPos = pr.cell and pr.cell.pos or ply:GetPos()
    local cop
    local spawner = LC.Spawners and LC.Spawners.cop
    if spawner then
        local spot = (LC.ReleaseSpot and LC.ReleaseSpot(cellPos + ply:GetForward() * 50, ply)) or (cellPos + Vector(50, 0, 4))
        local ok, npc, st = pcall(spawner, spot)
        if ok and IsValid(npc) and st then
            st.unmanaged = true
            st.interrogator = true
            if LC.SetState then LC.SetState(npc, st, "event") end
            st.eventUntil = CurTime() + 120
            if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
            if LC.Face then LC.Face(npc, ply:GetPos()) end
            cop = npc
        end
    end
    LC.Interrogations[ply] = { cop = cop, hits = 0, untilT = CurTime() + 45, next = CurTime() + 4 }
    ply:SetNW2Bool("lc_interrogated", true)
    ply:ChatPrint("[Interrogation] A Civil Protection unit steps into your cell and switches on his baton. \"You will answer my questions.\" (Talk, and it stops: the choice is on your screen. Or don't.)")
    ply:ChatPrint("[Interrogation] \"If you comply, I will grant you " .. COOP_REWARD .. " social credits.\"")
    if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/apply.wav", 75) end
    hook.Run("LivingCityInterrogation", ply)
    return true
end

-- Give them what they want: a hideout, marked for every unit.
function LC.InterrogationTalk(ply)
    local it = LC.Interrogations[ply]
    if not it then return false, "Nobody's asking." end
    it.talked = true
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
    local where
    if #zones > 0 then
        local z = Pick(zones)
        where = LC.DescribePlace and LC.DescribePlace(z.pos) or ""
        local units = {}
        for _, p in ipairs(player.GetAll()) do
            if LC.PlayerIsCP(p) then
                units[#units + 1] = p
                p:ChatPrint("[CP net] A prisoner has talked: a Resistance hideout " .. where .. ".")
            end
        end
        if LC.SendCompressed and #units > 0 then
            LC.SendCompressed("lc_cpmark", { name = "HIDEOUT (INFORMANT)", x = z.pos.x, y = z.pos.y, z = z.pos.z, secs = 300 }, units)
        end
    end
    if LC.AddStanding then LC.AddStanding(ply, COOP_REWARD, "cooperated under interrogation") end
    if ply:GetNW2String("lcf_faction", "") == "resistance" or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply)) then
        -- the cell hears about it
        ply:SetNW2Float("lc_traitor_until", CurTime() + 1800)
        if LC.RadioNotice then LC.RadioNotice("resistance", ply:Nick() .. " talked in custody. Don't trust them.") end
    end
    EndInterrogation(ply, "[Interrogation] You tell them" .. (where and where ~= "" and (" about the place " .. where) or " what you know") .. ". The Civil Protection unit nods, and leaves.")
    return true
end

local function InterrogationTick(now)
    for ply, it in pairs(LC.Interrogations) do
        if not IsValid(ply) or not (LC.Prisoners and LC.Prisoners[ply]) or not ply:Alive() then
            EndInterrogation(ply, nil)
        elseif now > it.untilT then
            EndInterrogation(ply, "[Interrogation] \"We'll talk again.\" The Civil Protection unit leaves. You said nothing.")
            if ply:GetNW2String("lcf_faction", "") == "resistance" and LC.AddXP then LC.AddXP(ply, 15, "said nothing under interrogation") end
        elseif now > it.next then
            it.next = now + math.Rand(6, 9)
            ply:ChatPrint("[Interrogation] \"" .. Pick(QUESTIONS) .. "\"")
            if IsValid(it.cop) then it.cop:EmitSound("npc/metropolice/vo/" .. Pick({ "isaidmovealong", "movealong", "apply", "keepmoving" }) .. ".wav", 70) end
            -- the baton, between questions; it hurts, it doesn't kill
            if it.hits < 5 then
                it.hits = it.hits + 1
                ply:SetHealth(math.max(10, ply:Health() - 6))
                ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 120), 0.4, 0)
                ply:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 4) .. ".wav", 70)
                if ply.ViewPunch then ply:ViewPunch(Angle(math.random(-8, 8), math.random(-8, 8), 0)) end
            end
        end
    end
end

------------------------------------------------------------------------
-- Broken feet: no running
------------------------------------------------------------------------

function LC.Cripple(ply, minutes)
    minutes = minutes or cvCripple:GetFloat()
    local untilWall = os.time() + minutes * 60
    ply:SetPData("lc_crippled_until", untilWall)
    ply:SetNW2Float("lc_crippled_until", CurTime() + minutes * 60)
    ply:ChatPrint(string.format("[Custody] They hold you down and break your feet. You won't be running for %d minutes. Not after release, not after anything.", minutes))
    ply:EmitSound("physics/body/body_medium_break" .. math.random(2, 4) .. ".wav", 70)
    hook.Run("LivingCityCrippled", ply, minutes)
end

function LC.IsCrippled(ply) return IsValid(ply) and ply:GetNW2Float("lc_crippled_until", 0) > CurTime() end

-- Blood on their hands: a unit, a soldier or a citizen killed by this person (this life;
-- sv_livingcity_response.lua counts them), or brought in for murder.
function LC.KillCount(ply) return tonumber(ply:GetPData("lc_killed", 0)) or 0 end
function LC.Heinous(ply, reason)
    if not IsValid(ply) then return false end
    local rebel = ply:GetNW2String("lcf_faction", "") == "resistance" or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply))
    if not rebel then return false end
    local r = string.lower(reason or "")
    return LC.KillCount(ply) > 0 or string.find(r, "murder", 1, true) ~= nil or string.find(r, "kill", 1, true) ~= nil
end

local function RestoreCripple(ply)
    local t = tonumber(ply:GetPData("lc_crippled_until", 0)) or 0
    local left = t - os.time()
    ply:SetNW2Float("lc_crippled_until", left > 0 and (CurTime() + left) or 0)
end

------------------------------------------------------------------------
-- Stalkers
------------------------------------------------------------------------

function LC.PlayerIsStalker(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "stalker"
end

-- The stalker's body: lc_stalker_model if set, else an installed playermodel
-- with "stalker" in its name or path (Workshop 268895264 is sent to players
-- who join), else the rank's own (a corpse).
if resource and resource.AddWorkshop then resource.AddWorkshop("268895264") end
local foundStalker
function LC.StalkerModel()
    local m = cvStalkMdl:GetString()
    if m ~= "" then return m end
    if foundStalker == nil then
        foundStalker = false
        local list = {}
        for name, path in pairs(player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}) do
            if string.find(string.lower(name), "stalker", 1, true) or string.find(string.lower(path), "stalker", 1, true) then list[#list + 1] = path end
        end
        table.sort(list)
        foundStalker = list[1] or false
    end
    return foundStalker or nil
end
cvars.AddChangeCallback("lc_stalker_model", function() foundStalker = nil end, "LivingCityStalker")

LC.ModelOverrides = LC.ModelOverrides or {}
LC.ModelOverrides.stalker = function(ply)
    if LC.PlayerIsStalker(ply) then return LC.StalkerModel() end
end

function LC.MakeStalker(ply)
    if not IsValid(ply) or not LC.SetFaction then return false end
    ply:SetPData("lc_stalker", "1")
    ply:SetNW2Bool("lc_stalker", true)
    if LC.Prisoners and LC.Prisoners[ply] then
        local pr = LC.Prisoners[ply]
        LC.Prisoners[ply] = nil
        if LC.Occupied and pr.cell and LC.Occupied[pr.cell] == ply then LC.Occupied[pr.cell] = nil end
        ply:SetNW2Float("lc_jail_until", 0)
        ply:RemovePData("lc_jail_left")
    end
    -- whatever they were doing, and whatever they had, goes with who they were
    if LC.QuestOf and LC.QuestOf[ply] and LC.AbandonQuest then pcall(LC.AbandonQuest, ply) end
    if LC.Inventory and LC.TakeItem then
        for id, n in pairs(table.Copy(LC.Inventory(ply) or {})) do LC.TakeItem(ply, id, n) end
    end
    if LC.SetJob then pcall(LC.SetJob, ply, "", true) end
    if LC.Feed then LC.Feed(ply, 100, 100) end
    LC.SetFaction(ply, "stalker", nil, true)
    ply:StripWeapons()
    ply:Give("weapon_lc_hands")
    ply:Freeze(false)
    ply:ChatPrint("[Custody] You come to, standing. Your body moves when they tell it to, not when you do. You are a stalker now: Combine property. You can't run, fight or speak, and you'll work. There is no way out of it but death.")
    if LC.Notice then LC.Notice(ply, "bad", "Combine property", "You are a stalker now. There is no way out of it but death. Your work is on your board (F3).", 10) end
    ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 3, 1)
    ply:EmitSound("npc/stalker/breathing3.wav", 70)
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply then p:ChatPrint("[City] An anticitizen has been repurposed. Citizens are reminded that cooperation is mandatory.") end
    end
    hook.Run("LivingCityStalker", ply)
    return true
end

-- How it happens: the cell door opens, two units come in with their batons, and it all goes
-- black. In the dark: machinery, a long while of it. Then you wake as one.
local SCENE = {
    { 0, "door", "buttons/combine_button_locked.wav" },
    { 0.6, nil, "npc/metropolice/vo/youwantamalcomplianceverdict.wav" },
    { 2.5, "hit", "weapons/stunstick/stunstick_impact1.wav" },
    { 3.2, "hit", "weapons/stunstick/stunstick_impact2.wav" },
    { 3.6, "black" },
    { 5, nil, "ambient/machines/spinup.wav" },
    { 7.5, nil, "ambient/levels/labs/machine_moving_loop3.wav" },
    { 9, nil, "ambient/machines/thumper_hit.wav" },
    { 10.5, nil, "npc/stalker/stalker_scream1.wav" },
    { 12.5, nil, "ambient/machines/spindown.wav" },
    { 14, "done" },
}
function LC.StalkerScene(ply)
    if not IsValid(ply) or ply.lcStalkerScene then return false end
    ply.lcStalkerScene = true
    ply:ChatPrint("[Custody] The cell door opens. Two Civil Protection units come in, batons out. They aren't here to ask questions.")
    if LC.Notice then LC.Notice(ply, "bad", "They've come for you", "Two units, batons out. You're not being released.", 6) end
    for _, step in ipairs(SCENE) do
        timer.Simple(step[1], function()
            if not IsValid(ply) then return end
            if not (LC.Prisoners and LC.Prisoners[ply]) and step[2] ~= "done" then return end
            if step[3] then ply:EmitSound(step[3], 75) end
            if step[2] == "hit" then
                ply:ViewPunch(Angle(math.random(8, 14), math.random(-8, 8), 0))
                ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 120), 0.3, 0)
            elseif step[2] == "black" then
                ply:Freeze(true)
                ply:ScreenFade(bit.bor(SCREENFADE.OUT or 2, SCREENFADE.STAYOUT or 8), Color(0, 0, 0, 255), 0.6, 0)
                ply:ChatPrint("[Custody] Everything goes black.")
            elseif step[2] == "done" then
                ply.lcStalkerScene = nil
                ply:ScreenFade(SCREENFADE.PURGE or 16, Color(0, 0, 0, 0), 0, 0)
                ply:Freeze(false)
                if LC.Prisoners and LC.Prisoners[ply] then LC.MakeStalker(ply) end
            end
        end)
    end
    return true
end

function LC.FreeStalker(ply, why)
    if not LC.PlayerIsStalker(ply) then return false end
    ply:RemovePData("lc_stalker")
    ply:SetNW2Bool("lc_stalker", false)
    if LC.SetFaction then LC.SetFaction(ply, "citizen", nil, true) end
    local s = LC.Standing and LC.Standing(ply) or 0
    if LC.AddStanding and s < -50 then LC.AddStanding(ply, -50 - s, nil) end -- what's left of you is on probation
    ply:ChatPrint(why or "[City] The city has had its use of you. You're let back onto the streets, on probation.")
    hook.Run("LivingCityStalkerFreed", ply)
    return true
end

-- (superadmin) let someone off being a stalker: lc_unstalker <part of a name>
concommand.Add("lc_unstalker", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local name = string.lower(args[1] or "")
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsStalker(p) and (name == "" or string.find(string.lower(p:Nick()), name, 1, true)) then
            LC.FreeStalker(p, "[City] An administrator has let you off being a stalker.")
            if IsValid(ply) then ply:ChatPrint("[Living City] " .. p:Nick() .. " is no longer a stalker.") end
        end
    end
end)

-- Stalkers can't speak: what they type comes out as a sound
hook.Add("PlayerSay", "LivingCityStalkerVoice", function(ply, text)
    if not LC.PlayerIsStalker(ply) then return end
    if LC.ICChatActive and LC.ICChatActive() then return end -- in-character chat turns it into the noise itself (sv_livingcity_rp.lua)
    local t = string.Trim(text)
    if string.sub(t, 1, 1) == "!" or string.sub(t, 1, 1) == "/" or string.sub(t, 1, 2) == "//" then return end -- commands and OOC still work
    ply:EmitSound("npc/stalker/go_alert2a.wav", 70)
    return "*a strained, wordless noise*"
end)
-- nor talk to anyone (E on a person does nothing: a stalker's work is the only thing it does)
-- (asked first by every E-on-someone handler: sv_livingcity.lua, the rebels', Grigori's, the lab's)
function LC.StalkerCantSpeak(ply, ent)
    if not LC.PlayerIsStalker(ply) or not IsValid(ent) then return false end
    if not (ent:IsNPC() or ent:IsPlayer() or ent:GetClass() == "lc_scientist") then return false end
    if (ply.lcStalkerUseNext or 0) < CurTime() then
        ply.lcStalkerUseNext = CurTime() + 4
        ply:EmitSound("npc/stalker/go_alert2a.wav", 65)
        ply:ChatPrint("[Stalker] You try to speak. Nothing comes out but a noise.")
    end
    return true
end
hook.Add("PlayerUse", "LivingCityStalkerUse", function(ply, ent)
    if LC.StalkerCantSpeak(ply, ent) then return false end
end)
-- and can't pick up guns
hook.Add("PlayerCanPickupWeapon", "LivingCityStalker", function(ply, wep)
    if LC.PlayerIsStalker(ply) and IsValid(wep) and wep:GetClass() ~= "weapon_lc_hands" then return false end
end)
-- a new person (death with permanent death on, a staff decision) was never a stalker
hook.Add("LivingCityNewCharacter", "LivingCityStalker", function(ply)
    ply:RemovePData("lc_stalker")
    ply:SetNW2Bool("lc_stalker", false)
end)
hook.Add("PlayerDeath", "LivingCityStalker", function(ply)
    if LC.PlayerIsStalker(ply) then
        timer.Simple(0.5, function()
            if IsValid(ply) then LC.FreeStalker(ply, "[City] The stalker that was you is gone. You come back as a citizen, on probation.") end
        end)
    end
end)

------------------------------------------------------------------------
-- When someone is brought in
------------------------------------------------------------------------

hook.Add("LivingCityIncarcerated", "LivingCityCustody", function(ply, secs, reason)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    -- severity counts the arrests before this one; then this one is counted
    local sev = LC.Severity(ply, reason)
    ply:SetPData("lc_jailcount", LC.JailCount(ply) + 1)
    if not cvOn:GetBool() then return end
    if sev >= 6 and cvStalker:GetBool() and LC.Heinous(ply, reason) then
        timer.Simple(20, function()
            if IsValid(ply) and LC.Prisoners and LC.Prisoners[ply] then LC.StalkerScene(ply) end
        end)
        return
    end
    -- only someone who could know something is questioned: a rebel (a Resistance
    -- fighter, or anyone hunted as one). A citizen locked up for a fight knows nothing.
    if sev >= 2 and LC.CanInterrogate(ply) then
        timer.Simple(12, function()
            if IsValid(ply) and LC.Prisoners and LC.Prisoners[ply] then
                LC.StartInterrogation(ply)
                if sev >= 4 then timer.Simple(50, function() if IsValid(ply) and LC.Prisoners and LC.Prisoners[ply] then LC.Cripple(ply) end end) end
            end
        end)
    end
end)

hook.Add("PlayerSay", "LivingCityInterrogation", function(ply, text)
    if string.lower(string.Trim(text)) == "!talk" then
        local ok, why = LC.InterrogationTalk(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
end)

hook.Add("PlayerInitialSpawn", "LivingCityCustody", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        RestoreCripple(ply)
        -- leaving the server doesn't end it: nothing does but death
        if ply:GetPData("lc_stalker", "0") == "1" and LC.SetFaction then
            ply:SetNW2Bool("lc_stalker", true)
            LC.SetFaction(ply, "stalker", nil, true)
        end
    end)
end)

timer.Create("LivingCityCustody", 1, 0, function()
    local now = CurTime()
    InterrogationTick(now)
end)
