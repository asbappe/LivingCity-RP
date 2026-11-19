--[[
    Living City: snitches among the citizens, and burning an informant
    (the owner, 10 November).

    Snitches. Some of the city's ordinary citizens (lc_snitch_chance, 12%)
    are informants. Nothing about them is different: the same people, the
    same routines, a flag nobody can see. When one sees a player (not a
    unit) do something illegal in plain view, they slip away and walk to the
    nearest Civil Protection unit (or a terminal, or they make the call from
    a doorway after a while) and tell. The player is booked for it and
    outlined for the units for a minute; the units hear who and where. A
    snitch killed or stopped before they get there tells nobody.
    What a snitch sees: a gun out in the open (outside rebel territory), and
    contraband being used (moonshine, a rolled cigarette...).

    Burning. A Resistance member (Member rank or higher) who suspects a
    citizen of informing can burn them: F2, looking at them, close.
      - Burned for lc_burn_hours (2): every Resistance player sees RAT over
        their head, the quartermaster won't deal with them, the Resistance
        won't take them in, and in rebel territory the rebels rough them up.
      - Right (they informed in the last two hours, or work as a Block
        Warden, or are on The Informant's story): the burner earns 15
        experience and the cell is told.
      - Wrong: word spreads that the Resistance burned an innocent; every
        citizen in the city loses a point of sympathy for them, and the
        burner loses 20 experience. The mark stays: the cell believes it.
      - A burned person who is cuffed, down, or has their hands up can be
        scarred (F2, five seconds): a crude rat carved into one cheek, drawn
        on their face (cl_livingcity_ratscar.lua) and added to the description
        strangers see, for good; and the Resistance will never take them in.

      lc_snitches 0/1, lc_snitch_chance (0.12), lc_burn 0/1, lc_burn_hours (2)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSnitch = CreateConVar("lc_snitches", "1", FLAGS, "Some ordinary citizens are secret informants: seeing a player do something illegal, they walk to a unit and tell")
local cvChance = CreateConVar("lc_snitch_chance", "0.12", FLAGS, "The share of the city's citizens who are secret informants")
local cvBurn   = CreateConVar("lc_burn", "1", FLAGS, "The Resistance can burn a citizen they suspect of informing (marked RAT for them, shunned)")
local cvHours  = CreateConVar("lc_burn_hours", "2", FLAGS, "Hours a burned citizen stays burned")

local SEE = 900          -- how far a snitch notices things
local REPORT_NEAR = 140  -- this close to a unit, they tell him
local CALL_AFTER = 25    -- no unit or terminal to walk to: they make the call from a doorway after this long
local GIVE_UP = 90       -- a report not made by then is made anyway (they found a call box)
local ACT_GAP = 60       -- the same person, the same thing: not seen again for this long
local BURN_GAP = 1200    -- a burner can burn again after this long
local BEAT_GAP = 30
local SCAR_TEXT = " A crude rat carved into one cheek."
-- Where the rat sits on the cheek, from the head: forward, right, up (units) and how far it turns
-- toward the side of the face (degrees). Tuned in game; the client reads it (cl_livingcity_ratscar.lua).
CreateConVar("lc_ratscar_pos", "3.4 2.6 -1.6 55", FLAGS, "Where the carved rat sits on a scarred face, from the head bone: forward right up turn")

local function Up(npc) return IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc] ~= nil end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function CitizenLike(p) local f = Faction(p) return f == "" or f == "citizen" or f == "resistance" or f == "vort" end
local function Where(pos) return (LC.DescribePlace and LC.DescribePlace(pos)) or "" end

------------------------------------------------------------------------
-- Snitches
------------------------------------------------------------------------

-- Rolled once for each of the city's citizens, the first time they're looked at.
function LC.IsSnitch(npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" then return false end
    -- a named citizen: from who they are (sv_livingcity_mindsact.lua); anyone else, the roll
    if st.snitch == nil and LC.MindsIsInformer then st.snitch = LC.MindsIsInformer(npc, st) end
    if st.snitch == nil then st.snitch = math.random() < math.Clamp(cvChance:GetFloat() * (LC.LedgerSnitchMul or 1), 0, 1) end -- (the Administrator's authority: sv_livingcity_ledger.lua)
    return st.snitch == true
end

local function Sees(npc, ply)
    if npc:GetPos():DistToSqr(ply:GetPos()) > SEE * SEE then return false end
    if not LC.LineOfSight then return true end
    return LC.LineOfSight(npc:EyePos(), ply:EyePos(), { npc, ply }, ply)
end

local function NearestUnit(pos)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and (st.role == "cop" or st.role == "soldier") and st.state ~= "hostile" then
            local d = npc:GetPos():DistToSqr(pos)
            if d < 5000 * 5000 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

local function Release(npc, st)
    st.snitchReport, st.questLock = nil, nil
    if st.state == "event" or st.state == "moving" then
        st.eventUntil = 0
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 2
    end
end

-- They tell.
local function Report(npc, st)
    local r = st.snitchReport
    Release(npc, st)
    local ply = r and r.ply
    if not IsValid(ply) or not ply:Alive() then return end
    local where = Where(r.pos or ply:GetPos())
    LC.ReportCrime(ply, "Reported by a citizen: " .. r.what, 240)
    ply:SetNW2Float("lc_spotted_until", CurTime() + 60)
    ply:SetNW2String("lc_spotted_why", "a citizen's report")
    local who = ply:GetNW2String("lc_desc", "") ~= "" and ply:GetNW2String("lc_desc", "") or Name(ply)
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsCP(p) then p:ChatPrint("[CP net] A citizen reports someone " .. r.what .. (where ~= "" and (", " .. where) or "") .. ": " .. who .. ". Outlined for 60 seconds.") end
    end
    ply:ChatPrint("[Miscount] Somebody told Civil Protection about you.")
    hook.Run("LivingCitySnitched", npc, ply, r.what)
end
LC.SnitchReport = Report

-- Someone did something illegal: does a snitch see it? True if one goes to tell.
function LC.IllegalAct(ply, what)
    if not cvSnitch:GetBool() or not IsValid(ply) or not ply:IsPlayer() or LC.PlayerIsCP(ply) then return false end
    ply.lcActSeen = ply.lcActSeen or {}
    if (ply.lcActSeen[what] or 0) > CurTime() then return false end
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and LC.IsSnitch(npc) and not st.snitchReport and not st.test and st.state ~= "hostile" and st.state ~= "abed"
            and not st.questLock and Sees(npc, ply) then
            ply.lcActSeen[what] = CurTime() + ACT_GAP
            local now = CurTime()
            st.snitchReport = { ply = ply, what = what, at = now, pos = ply:GetPos(), tries = 0 }
            LC.SetState(npc, st, "event")
            st.eventUntil, st.questLock = now + GIVE_UP + 30, true
            local unit = NearestUnit(npc:GetPos())
            st.snitchReport.unit = unit
            if IsValid(unit) and LC.GoTo then LC.GoTo(npc, st, unit:GetPos(), false) end
            return true
        end
    end
    return false
end

local function SnitchTick(now)
    for npc, st in pairs(LC.NPCs or {}) do
        local r = st.snitchReport
        if r then
            if not Up(npc) or st.state == "hostile" then
                st.snitchReport = nil -- (killed, or caught up in a fight: nobody hears it)
            elseif IsValid(r.unit) then
                if npc:GetPos():DistToSqr(r.unit:GetPos()) < REPORT_NEAR * REPORT_NEAR then
                    if LC.Face then LC.Face(npc, r.unit:GetPos()) LC.Face(r.unit, npc:GetPos()) end
                    Report(npc, st)
                elseif now - r.at > GIVE_UP then
                    Report(npc, st)
                elseif st.state ~= "moving" and now >= (r.next or 0) then
                    r.next, r.tries = now + 3, r.tries + 1
                    if not (LC.GoTo and LC.GoTo(npc, st, r.unit:GetPos(), false)) and r.tries > 4 then Report(npc, st) end
                end
            elseif now - r.at > CALL_AFTER then
                Report(npc, st) -- (no unit about: a call from a doorway)
            end
        end
    end
end

-- What a snitch can see: a gun out in the open.
local function WatchTick(now)
    if not cvSnitch:GetBool() then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not LC.PlayerIsCP(ply) then
            local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
            local cls = IsValid(w) and w.GetClass and w:GetClass()
            if cls and LC.ViolentGuns and LC.ViolentGuns[cls] and not (LC.InRebelZone and LC.InRebelZone(ply:GetPos())) then
                LC.IllegalAct(ply, "carrying a gun")
            end
        end
    end
end

-- ...and contraband being used (sv_livingcity_scavenge.lua, LC.ItemUse).
local wrapped = false
local function Wrap()
    if LC.MenuActions then LC.MenuActions.burn, LC.MenuActions.scar = true, true end
    if wrapped or not LC.ItemUse then return end
    wrapped = true
    local orig = LC.ItemUse
    LC.ItemUse = function(ply, id, ...)
        local ok, why = orig(ply, id, ...)
        local it = LCS and LCS.Items and LCS.Items[id]
        if ok ~= false and it and it.contraband and IsValid(ply) then LC.IllegalAct(ply, "using " .. string.lower(it.name or "contraband")) end
        return ok, why
    end
end
Wrap()
hook.Add("Initialize", "LivingCitySnitches", Wrap)

------------------------------------------------------------------------
-- Burning an informant
------------------------------------------------------------------------

function LC.IsBurned(ply) return IsValid(ply) and ply:GetNW2Float("lc_burned_until", 0) > CurTime() end

-- Really an informant? Informed lately, a Block Warden, or on The Informant's story.
function LC.ReallyInformant(ply)
    if ply.lcInformedAt and ply.lcInformedAt > CurTime() - 7200 then return true end
    local job = LC.Job and LC.Job(ply)
    if job and job.id == "warden" then return true end
    if ply.GetPData and ply:GetPData("lcq_story", "") == "informant" then return true end
    return false
end

hook.Add("LivingCityInformed", "LivingCitySnitches", function(ply) if IsValid(ply) then ply.lcInformedAt = CurTime() end end)

function LC.Burn(burner, target)
    if not cvBurn:GetBool() then return false, "Nobody burns anyone here." end
    if not IsValid(burner) or Faction(burner) ~= "resistance" then return false, "Only the Resistance burns informants." end
    if burner:GetNW2Int("lcf_rank", 1) < 2 then return false, "The cell doesn't take that from a Sympathizer. Rise to Member first." end
    if not IsValid(target) or not target:IsPlayer() or target == burner then return false, "Look at the one you suspect, close up." end
    local f = Faction(target)
    if f ~= "" and f ~= "citizen" then return false, "Only a citizen can be burned as an informant." end
    if burner:GetPos():DistToSqr(target:GetPos()) > 200 * 200 then return false, "Get closer to them." end
    if LC.IsBurned(target) then return false, "They're burned already." end
    if (burner.lcBurnNext or 0) > CurTime() then return false, string.format("You burned someone not long ago. (%s)", string.NiceTime(burner.lcBurnNext - CurTime())) end
    burner.lcBurnNext = CurTime() + BURN_GAP
    local secs = cvHours:GetFloat() * 3600
    target:SetNW2Float("lc_burned_until", CurTime() + secs)
    if target.SetPData then target:SetPData("lc_burned_at", os.time()) end
    local right = LC.ReallyInformant(target)
    local name = Name(target)
    if LC.RadioNotice then LC.RadioNotice("resistance", name .. " is burned: an informant. Don't deal with them.") end
    target:ChatPrint("[Miscount] The Resistance has burned you as an informant. Their people will know you.")
    if right then
        if LC.AddXP then LC.AddXP(burner, 15, "burned an informant") end
        burner:ChatPrint("[Resistance] You were right about them.")
    else
        if LC.AddXP then LC.AddXP(burner, -20, "burned an innocent citizen") end
        for _, p in ipairs(player.GetAll()) do
            local pf = Faction(p)
            if p ~= target and (pf == "" or pf == "citizen") then
                if LC.AddTrait then LC.AddTrait(p, "sympathy", -1) end
                p:ChatPrint("[Miscount] Word spreads: the Resistance burned an innocent citizen as an informant.")
            end
        end
        burner:ChatPrint("[Resistance] Word comes back: they were never an informant. The city won't forget it.")
    end
    hook.Run("LivingCityBurned", burner, target, right)
    return true, right
end

function LC.Scar(burner, target)
    if not IsValid(burner) or Faction(burner) ~= "resistance" then return false, "Only the Resistance marks their rats." end
    if not IsValid(target) or not target:IsPlayer() or not LC.IsBurned(target) then return false, "Only someone burned as an informant." end
    if burner:GetPos():DistToSqr(target:GetPos()) > 120 * 120 then return false, "Get right up to them." end
    local held = (LC.IsTied and LC.IsTied(target)) or (LC.IsDowned and LC.IsDowned(target)) or target:GetNW2Bool("lc_handsup", false)
    if not held then return false, "They'd fight you off. Only when they're cuffed, down, or have their hands up." end
    if target.GetPData and target:GetPData("lc_scar", "0") == "1" then return false, "They carry the mark already." end
    if not LC.StartTask then return false end
    target:ChatPrint("[Miscount] Someone grabs your face. A blade.")
    return LC.StartTask(burner, 5, "Marking them...", { maxMove = 60, cancelText = "You let them go.",
        done = function(p)
            if not IsValid(target) then return end
            target:SetHealth(math.max(10, target:Health() - 20))
            target:EmitSound("physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav", 70)
            if target.ViewPunch then target:ViewPunch(Angle(-10, math.random(-10, 10), 0)) end
            if target.SetPData then
                target:SetPData("lc_scar", "1")
                local desc = target:GetPData("lc_desc", "") or ""
                if not string.find(desc, SCAR_TEXT, 1, true) then
                    desc = desc .. SCAR_TEXT
                    target:SetPData("lc_desc", desc)
                    target:SetNW2String("lc_desc", desc)
                end
            end
            target:SetNW2Bool("lc_scar_mark", true) -- (the rat itself, drawn on the cheek: cl_livingcity_ratscar.lua)
            target:ChatPrint("[Miscount] They've carved a crude rat into your cheek. Everyone who sees you will see it, and the Resistance will never take you in.")
            p:ChatPrint("[Resistance] Marked. Anyone who looks at them will know.")
            hook.Run("LivingCityScarred", p, target)
        end })
end

-- In rebel territory, the rebels rough up a burned one.
local function BeatTick(now)
    for _, ply in ipairs(player.GetAll()) do
        if LC.IsBurned(ply) and ply:Alive() and now >= (ply.lcBeatNext or 0) and LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then
            for npc, st in pairs(LC.NPCs or {}) do
                if Up(npc) and st.role == "rebel" and npc:GetPos():DistToSqr(ply:GetPos()) < 160 * 160 then
                    ply.lcBeatNext = now + BEAT_GAP
                    if LC.Face then LC.Face(npc, ply:GetPos()) end
                    ply:SetHealth(math.max(15, ply:Health() - 10))
                    ply:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 70)
                    if ply.ViewPunch then ply:ViewPunch(Angle(math.random(-12, 12), math.random(-12, 12), 0)) end
                    ply:ChatPrint("[Miscount] A rebel slams you against the wall. \"Rat. Get out of here.\"")
                    break
                end
            end
        end
    end
end

hook.Add("PlayerInitialSpawn", "LivingCityBurned", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) or not ply.GetPData then return end
        ply:SetNW2Bool("lc_scar_mark", ply:GetPData("lc_scar", "0") == "1")
        local at = tonumber(ply:GetPData("lc_burned_at", 0)) or 0
        local left = at + cvHours:GetFloat() * 3600 - os.time()
        if at > 0 and left > 0 then ply:SetNW2Float("lc_burned_until", CurTime() + left) end
    end)
end)
hook.Add("LivingCityNewCharacter", "LivingCityBurned", function(ply)
    if not IsValid(ply) then return end
    ply:SetNW2Float("lc_burned_until", 0)
    ply:RemovePData("lc_burned_at")
    ply:RemovePData("lc_scar")
    ply:SetNW2Bool("lc_scar_mark", false)
end)

------------------------------------------------------------------------

local nextWatch = 0
timer.Create("LivingCitySnitches", 0.5, 0, function()
    local now = CurTime()
    local ok, err = LC.Try(function()
        SnitchTick(now)
        if now >= nextWatch then
            nextWatch = now + 2
            WatchTick(now)
            BeatTick(now)
        end
    end)
    if not ok and LC.Error then LC.Error("snitches", err) end
end)

-- F2's actions on someone in front of you (sv_livingcity_actions.lua hands over the target).
LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.burn = function(ply, target) return LC.Burn(ply, target) end
LC.TargetActions.scar = function(ply, target) return LC.Scar(ply, target) end
