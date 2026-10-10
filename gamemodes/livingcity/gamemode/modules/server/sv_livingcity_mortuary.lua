--[[
    Living City: hauling the dead

    Any body in the city (sv_livingcity_bodies.lua) can be hauled: press E on
    it if you're a Mortician, or, looking at it, F1 > Haul the body, as anyone.
    You drag it behind you at a walk. Let go next to an incinerator (placed
    with the editor, "Fixture: incinerator"), or press E on the incinerator,
    and in it goes. Attendants are paid for each one.

    Nothing spawns an incinerator by itself. With none placed, attendants
    bag bodies at the morgue instead (a workplace point for the Mortuary
    Attendant job), and with neither there are no collection shifts.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPay = CreateConVar("lc_cremation_pay", "6", FLAGS, "Credits a Mortician is paid per body")

local hauling = {} -- [ply] = body
LC.Haulers = hauling

local function IsBody(e) return IsValid(e) and e.lcBody ~= nil end
local function Attendant(ply) return ply:GetNW2String("lcj_job", "") == "mortuary" end
LC.IsMortuaryAttendant = Attendant

function LC.HauledBy(body)
    for p, b in pairs(hauling) do if b == body then return p end end
    return nil
end

------------------------------------------------------------------------
-- Where bodies go
------------------------------------------------------------------------

-- Incinerators, then morgue workplaces. Each: { pos, ent, name }.
function LC.BodyProcessors()
    local out = {}
    for _, e in ipairs(LC.EntsOf("lc_incinerator")) do
        if IsValid(e) then out[#out + 1] = { pos = e:WorldSpaceCenter(), ent = e, name = "the incinerator" } end -- (its middle: the canister is long)
    end
    local job = LCJ and LCJ.ById and LCJ.ById.mortuary
    if job and LC.PointsOfKind then
        for _, p in ipairs(LC.PointsOfKind("work", job.num)) do out[#out + 1] = { pos = p.pos, name = "the morgue" } end
    end
    return out
end

function LC.NearestBodyProcessor(pos, maxD)
    local best, bd = nil, (maxD or 1e9) ^ 2
    for _, p in ipairs(LC.BodyProcessors()) do
        local d = p.pos:DistToSqr(pos)
        -- an incinerator beats a morgue point that's about as close
        if p.ent then d = d * 0.8 end
        if d < bd then best, bd = p, d end
    end
    return best
end

-- A body nobody is dealing with, near a spot.
function LC.UnclaimedBody(pos, maxD)
    local best, bd = nil, (maxD or 3000) ^ 2
    for _, b in ipairs(LC.Bodies or {}) do
        local e = b.ent
        if IsBody(e) and not e.lcBody.claimed and not LC.HauledBy(e) then
            local d = e:GetPos():DistToSqr(pos)
            if d < bd then best, bd = e, d end
        end
    end
    return best
end

------------------------------------------------------------------------
-- Hauling
------------------------------------------------------------------------

local function CanHaul(ply)
    if not IsValid(ply) then return false end
    if not ply:IsPlayer() then -- one of the city's attendants (sv_livingcity_npcwork.lua)
        local st = LC.NPCs and LC.NPCs[ply]
        return ply:Health() > 0 and st ~= nil and st.npcWork ~= nil and (st.state == "moving" or st.state == "working")
    end
    if not ply:Alive() then return false end
    if LC.InCustody and LC.InCustody(ply) then return false end
    if ply:GetNW2Bool("lc_tied", false) or ply:GetNW2Bool("lc_handsup", false) then return false end
    if IsValid(ply:GetNW2Entity("lc_scanner")) then return false end
    return true
end

local function Cremate(ply, body, proc)
    if not IsValid(body) then return false end
    local pos = body:GetPos()
    for p, b in pairs(hauling) do if b == body then LC.StopHaul(p, true, true) end end
    body:Remove()
    if proc and IsValid(proc.ent) then
        proc.ent:SetNW2Float("lc_burn_until", CurTime() + 8)
        proc.ent:EmitSound("ambient/fire/gascan_ignite1.wav", 75, 90)
        timer.Simple(0.4, function() if IsValid(proc.ent) then proc.ent:EmitSound("ambient/fire/ignite.wav", 70, 80) end end)
    elseif sound and sound.Play then
        sound.Play("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", pos, 65)
    end
    if IsValid(ply) and ply:IsPlayer() then
        ply.lcFedAt = CurTime()
        local burnt = proc and proc.ent and "The incinerator door clangs shut. The roar takes a while to die down." or "You zip the bag and leave it with the others."
        if Attendant(ply) then
            local pay = cvPay:GetInt()
            if pay > 0 and LC.AddCredits then LC.AddCredits(ply, pay, "cremation") end
            ply:ChatPrint("[Mortuary] " .. burnt .. (pay > 0 and (" (+" .. pay .. " credits)") or ""))
        else
            ply:ChatPrint(burnt)
        end
        LC.QuestEvent("cremated", ply, body)
    end
    hook.Run("LivingCityCremated", ply, body, proc)
    return true
end
LC.CremateBody = Cremate

function LC.StartHaul(ply, body)
    if hauling[ply] then return LC.StopHaul(ply) end
    if not IsBody(body) then return false, "That isn't a body." end
    if not CanHaul(ply) then return false end
    if LC.HauledBy(body) then return false, "Someone else already has hold of them." end
    if ply:GetPos():DistToSqr(body:GetPos()) > 170 * 170 then return false, "Get closer." end
    hauling[ply] = body
    ply:SetNW2Bool("lc_hauling", true)
    ply:SetNW2Entity("lc_haul_body", body)
    ply.lcNextBodyUse = CurTime() + 0.8
    local proc = LC.NearestBodyProcessor(body:GetPos())
    ply:ChatPrint("You take hold of the body by the collar." ..
        (proc and (" Drag it to " .. proc.name .. ". E lets go.") or " E lets go."))
    return true
end

function LC.StopHaul(ply, quiet, noDrop)
    local body = hauling[ply]
    hauling[ply] = nil
    if IsValid(ply) and ply:IsPlayer() then
        ply:SetNW2Bool("lc_hauling", false)
        ply:SetNW2Entity("lc_haul_body", NULL)
        ply.lcNextBodyUse = CurTime() + 0.8
    end
    if not IsValid(body) or noDrop then return true end
    -- let go next to an incinerator, or at the morgue: that's where it stays
    local proc = LC.NearestBodyProcessor(body:GetPos(), 170)
    if proc and IsValid(ply) then return Cremate(ply, body, proc) end
    if IsValid(ply) and ply:IsPlayer() and not quiet then ply:ChatPrint("You let go of the body.") end
    return true
end

-- One of the city's own attendants takes hold (sv_livingcity_npcwork.lua).
function LC.StartHaulNPC(npc, body)
    if not IsValid(npc) or not IsBody(body) or LC.HauledBy(body) then return false end
    for _, b in pairs(hauling) do if b == body then return false end end
    hauling[npc] = body
    return true
end

-- E on the incinerator: in goes whoever you're hauling, or a body lying right beside it.
function LC.FeedIncinerator(ply, inc)
    if CurTime() - (ply.lcFedAt or 0) < 1 then return true end
    local mid = inc:WorldSpaceCenter()
    local proc = { pos = mid, ent = inc, name = "the incinerator" }
    local body = hauling[ply]
    if not IsValid(body) then
        for _, b in ipairs(LC.Bodies or {}) do
            if IsBody(b.ent) and not LC.HauledBy(b.ent) and b.ent:GetPos():DistToSqr(mid) < 160 * 160 then body = b.ent break end
        end
    end
    if not IsValid(body) then return false, "The incinerator is roaring. You've nothing to put in it. (Haul a body here: E on a body, or the actions menu.)" end
    if body:GetPos():DistToSqr(mid) > 240 * 240 then return false, "Bring the body closer." end
    return Cremate(ply, body, proc)
end

-- Drag: the body follows at your heels, by the shoulders.
hook.Add("Think", "LivingCityHauling", function()
    if next(hauling) == nil then return end
    for ply, body in pairs(hauling) do
        if not IsValid(body) or not CanHaul(ply) then
            LC.StopHaul(ply, true)
        elseif ply:GetPos():DistToSqr(body:GetPos()) > 320 * 320 then
            LC.StopHaul(ply, true)
            if ply:IsPlayer() then ply:ChatPrint("The body snags on something and slips out of your grip.") end
        else
            local phys = body.GetPhysicsObjectNum and body:GetPhysicsObjectNum(0)
            if IsValid(phys) then
                -- behind them, level (looking up or down doesn't lift it or bury it)
                local yaw = ply:IsPlayer() and ply:EyeAngles().y or ply:GetAngles().y
                local target = ply:GetPos() - Angle(0, yaw, 0):Forward() * 42 + Vector(0, 0, 14)
                local v = (target - phys:GetPos()) * 7
                if v:Length() > 420 then v = v:GetNormalized() * 420 end
                phys:Wake()
                phys:SetVelocity(v)
            end
        end
    end
end)

-- E while hauling: feed the incinerator you're looking at, or let go.
hook.Add("KeyPress", "LivingCityHauling", function(ply, key)
    if key ~= IN_USE or not hauling[ply] then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:GetClass() == "lc_incinerator" and tr.HitPos:DistToSqr(ply:EyePos()) < 160 * 160 then
        local ok, why = LC.FeedIncinerator(ply, e)
        if not ok and why then ply:ChatPrint(why) end
        return
    end
    LC.StopHaul(ply)
end)

hook.Add("PlayerDeath", "LivingCityHauling", function(ply) if hauling[ply] then LC.StopHaul(ply, true) end end)
hook.Add("PlayerDisconnected", "LivingCityHauling", function(ply) hauling[ply] = nil end)

-- Morticians haul with E; everyone else searches (the actions menu does either).
hook.Add("LivingCityBodyUse", "LivingCityHauling", function(ply, body)
    if Attendant(ply) and not hauling[ply] then
        local ok, why = LC.StartHaul(ply, body)
        if not ok and why then ply:ChatPrint(why) end
        return true
    end
end)
