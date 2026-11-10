--[[
    Living City: citizens who drink and smoke

    The owner, 10 November: "NPCs should smoke and drink too". A named citizen
    fond of a drink and a smoke (the vice trait of the city's minds,
    sv_livingcity_psyche.lua: worked out from who they are, so always the same
    people) now and then lights a cigarette or takes out a bottle while they
    stand about, queue or sit, without stopping what they're doing:

      a cigarette   a puff of smoke from them every few seconds (the same
                    smoke a player's cigarette makes), for half a minute or so
      a bottle      a bottle in their right hand and a swig every so often

    Only where a player could see it (within 2500 units), only while they're
    calm (standing, queueing, sitting, keeping watch), and at most 6 at once.
    The stronger the vice, the more often; with the city's minds on, a craving
    makes it sooner, and a drink or a smoke eases it (and is written down).
    Never a unit (the mask) and never someone the trait says is sober.

    lc_npc_vices 1/0 (editor panel, NPC budget section).
]]

LC = LC or {}

local cv = CreateConVar("lc_npc_vices", "1", FCVAR_ARCHIVE, "Citizens fond of a drink and a smoke light a cigarette or take out a bottle now and then, where players can see")

local CALM = { idle = true, inline = true, busy = true, lookout = true }
local SEE = 2500
local MAX_AT_ONCE = 6
local BOTTLES = { "models/props_junk/garbage_glassbottle001a.mdl", "models/props_junk/glassjug01.mdl" }
local GULPS = { "npc/barnacle/barnacle_gulp1.wav", "npc/barnacle/barnacle_gulp2.wav" }

LC.NPCVices = LC.NPCVices or {}
local Active = LC.NPCVices

-- How fond of a drink and a smoke a named person is, from 0 (sober) to 1.
function LC.NPCViceOf(npc)
    local p = IsValid(npc) and npc.lcProfile
    if not p or p.role ~= "citizen" or not LC.Psy or not LC.MindOf then return 0 end
    return math.max(0, LC.Psy.Traits(LC.MindOf(p)).vice)
end

local function Bottle(npc)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(BOTTLES[math.random(#BOTTLES)])
    e:SetPos(npc:GetPos() + Vector(0, 0, 40))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_NONE) end
    local att = npc.LookupAttachment and npc:LookupAttachment("anim_attachment_RH") or 0
    if att and att > 0 then
        e:SetParent(npc, att)
        if e.SetLocalPos then e:SetLocalPos(Vector(3, -2, 0)) end
        if e.SetLocalAngles then e:SetLocalAngles(Angle(0, 0, 90)) end
    else
        e:SetParent(npc)
        if e.SetLocalPos then e:SetLocalPos(Vector(12, -8, 40)) end
    end
    e.lcViceProp = true
    return e
end

local function Puff(npc)
    net.Start("lc_vice")
    net.WriteString("smoke")
    net.WriteEntity(npc)
    net.WriteUInt(1, 4)
    if net.SendPVS then net.SendPVS(npc:GetPos()) else net.Broadcast() end
end

function LC.NPCViceStop(npc)
    local a = Active[npc]
    if not a then return end
    if IsValid(a.prop) then a.prop:Remove() end
    Active[npc] = nil
end

-- Light up (kind "smoke") or take out a bottle ("drink"). The tests call it directly.
function LC.NPCViceStart(npc, kind, now)
    if not IsValid(npc) or Active[npc] then return false end
    now = now or CurTime()
    local a = { kind = kind, untilT = now + (kind == "smoke" and math.Rand(30, 50) or math.Rand(25, 40)), nextT = now + math.Rand(1, 3) }
    if kind == "drink" then a.prop = Bottle(npc) end
    Active[npc] = a
    -- the city's minds: the craving goes (sv_livingcity_minds.lua)
    if LC.MindsIndulged and LC.MindsOn and LC.MindsOn() and npc.lcProfile then LC.MindsIndulged(LC.MindOf(npc.lcProfile), "street") end
    return true
end

function LC.NPCViceTick(now)
    now = now or CurTime()
    local on = cv:GetBool()
    local n = 0
    for npc, a in pairs(Active) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if not on or not st or not CALM[st.state] or now > a.untilT or (LC.NPCAsleep and LC.NPCAsleep(npc)) then
            LC.NPCViceStop(npc)
        else
            n = n + 1
            if now >= a.nextT then
                if a.kind == "smoke" then
                    Puff(npc)
                    a.nextT = now + math.Rand(5, 8)
                else
                    npc:EmitSound(GULPS[math.random(#GULPS)], 55)
                    a.nextT = now + math.Rand(8, 12)
                end
            end
        end
    end
    if not on or n >= MAX_AT_ONCE then return end
    local eyes = LC.ViewerPositions and LC.ViewerPositions() or {}
    if #eyes == 0 then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if n >= MAX_AT_ONCE then break end
        if st.role == "citizen" and CALM[st.state] and not Active[npc] and not st.test and IsValid(npc) and npc.lcProfile
            and not IsValid(st.carry) and not (LC.NPCAsleep and LC.NPCAsleep(npc)) then
            local vice = LC.NPCViceOf(npc)
            if vice > 0 then
                local chance = 0.012 * vice
                local m = LC.Minds and LC.Minds.byId[npc.lcProfile.id]
                if m and m.psy and (m.psy.crave or 0) > 0.6 then chance = chance * 2.5 end
                if math.random() < chance then
                    local pos, seen = npc:GetPos(), false
                    for _, at in ipairs(eyes) do if at:DistToSqr(pos) < SEE * SEE then seen = true break end end
                    if seen and LC.NPCViceStart(npc, math.random() < 0.6 and "smoke" or "drink", now) then n = n + 1 end
                end
            end
        end
    end
end

timer.Create("LivingCityNPCVices", 3, 0, function()
    if LC.TimeStopped then return end
    local ok, err = pcall(LC.NPCViceTick, CurTime())
    if not ok and LC.Error then LC.Error("npc vices", err) end
end)

hook.Add("EntityRemoved", "LivingCityNPCVices", function(ent)
    if Active[ent] then LC.NPCViceStop(ent) end
end)
