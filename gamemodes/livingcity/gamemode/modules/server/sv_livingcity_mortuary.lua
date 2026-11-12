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

-- Where bodies are brought to an incinerator: standing on end, the floor at its foot; lying
-- down (an old model), its middle (the canister is long).
function LC.IncineratorBase(e)
    if e.lcBasePos then return e.lcBasePos + Vector(0, 0, 24) end
    return e:WorldSpaceCenter()
end

-- Incinerators, then morgue workplaces. Each: { pos, ent, name }.
function LC.BodyProcessors()
    local out = {}
    for _, e in ipairs(LC.EntsOf("lc_incinerator")) do
        if IsValid(e) then out[#out + 1] = { pos = LC.IncineratorBase(e), ent = e, name = "the incinerator" } end
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
        if IsBody(e) and not e.lcBody.claimed and not e.lcOnCart and not LC.HauledBy(e)
            and not (LC.InInfest and LC.InInfest(e:GetPos())) then -- (the infestation's dead are the Cremators')
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
    -- let go beside your body cart: it goes on the cart
    if IsValid(ply) and LC.LoadBodyCart and LC.LoadBodyCart(ply, body) then return true end
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
    local mid = LC.IncineratorBase(inc)
    local proc = { pos = mid, ent = inc, name = "the incinerator" }
    local body = hauling[ply]
    -- a body cart brought up to it: everything on it goes in
    if not IsValid(body) and LC.UnloadBodyCart and LC.UnloadBodyCart(ply, proc) then return true end
    if not IsValid(body) then
        for _, b in ipairs(LC.Bodies or {}) do
            if IsBody(b.ent) and not b.ent.lcOnCart and not LC.HauledBy(b.ent) and b.ent:GetPos():DistToSqr(mid) < 160 * 160 then body = b.ent break end
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

------------------------------------------------------------------------
-- The body cart (Morticians, if they want one): take one at the incinerator
-- or the morgue (F2 > Take a body cart, or !bodycart), let go of a body
-- beside it and it goes on, push it (E on it; E again lets go), and E on the
-- incinerator burns everything on it, paid for each. Four at a time.
------------------------------------------------------------------------

local CART_MODELS = { "models/props_wasteland/laundry_cart002.mdl", "models/props_junk/PushCart01a.mdl", "models/props_wasteland/laundry_cart001.mdl" }
local CART_HOLDS = 4
LC.BodyCarts = LC.BodyCarts or {} -- [ply] = cart

local function CartOf(ply) local c = LC.BodyCarts[ply] return IsValid(c) and c or nil end

function LC.TakeBodyCart(ply)
    if not IsValid(ply) or not Attendant(ply) then return false, "Body carts are for Morticians." end
    if CartOf(ply) then return false, "You've a cart out already (E on it to push it)." end
    if not LC.NearestBodyProcessor(ply:GetPos(), 600) then return false, "Body carts are kept by the incinerator, or at the morgue. Go there for one." end
    local model
    for _, m in ipairs(CART_MODELS) do if not util.IsValidModel or util.IsValidModel(m) then model = m break end end
    local fwd = ply:GetAimVector() fwd.z = 0 fwd:Normalize()
    local cart = ents.Create("prop_physics")
    if not IsValid(cart) then return false end
    cart:SetModel(model or CART_MODELS[1])
    cart:SetPos(ply:GetPos() + fwd * 70 + Vector(0, 0, 4))
    cart:SetAngles(Angle(0, fwd:Angle().y + 90, 0))
    cart:Spawn()
    if cart.SetCollisionGroup and COLLISION_GROUP_DEBRIS then cart:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end -- (it doesn't knock people about)
    cart.lcBodyCart = { owner = ply, bodies = {}, pushing = false }
    cart:SetNW2Bool("lc_bodycart", true)
    cart:SetNW2Int("lc_cart_bodies", 0)
    LC.BodyCarts[ply] = cart
    ply:ChatPrint("[Mortuary] A body cart. E on it to push it (E again lets go). Let go of a body beside it and it goes on. Push it to the incinerator and press E on the incinerator.")
    return true
end

-- Let go of a body beside your cart: on it goes (hidden under the sheet).
function LC.LoadBodyCart(ply, body)
    local cart = CartOf(ply)
    if not cart or not IsBody(body) then return false end
    local c = cart.lcBodyCart
    if #c.bodies >= CART_HOLDS or body:GetPos():DistToSqr(cart:GetPos()) > 120 * 120 then return false end
    body.lcOnCart = cart
    body:SetNoDraw(true)
    if body.SetNotSolid then body:SetNotSolid(true) end
    c.bodies[#c.bodies + 1] = body
    cart:SetNW2Int("lc_cart_bodies", #c.bodies)
    cart:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 65)
    ply:ChatPrint(string.format("[Mortuary] On the cart (%d of %d).", #c.bodies, CART_HOLDS))
    return true
end

-- E on the incinerator with your cart beside it: everything on it goes in.
function LC.UnloadBodyCart(ply, proc)
    local cart = CartOf(ply)
    if not cart or not proc then return false end
    local c = cart.lcBodyCart
    if #c.bodies == 0 or cart:GetPos():DistToSqr(proc.pos) > 260 * 260 then return false end
    local n = 0
    for _, b in ipairs(c.bodies) do
        if IsValid(b) then
            b:SetNoDraw(false)
            b:SetPos(proc.pos)
            ply.lcFedAt = 0
            if Cremate(ply, b, proc) then n = n + 1 end
        end
    end
    c.bodies = {}
    cart:SetNW2Int("lc_cart_bodies", 0)
    return n > 0
end

-- Put it away: the bodies on it are left lying where it stood.
function LC.DropBodyCart(ply)
    local cart = LC.BodyCarts[ply]
    LC.BodyCarts[ply] = nil
    if not IsValid(cart) then return end
    for _, b in ipairs(cart.lcBodyCart and cart.lcBodyCart.bodies or {}) do
        if IsValid(b) then
            b.lcOnCart = nil
            b:SetNoDraw(false)
            if b.SetNotSolid then b:SetNotSolid(false) end
            b:SetPos(cart:GetPos() + Vector(0, 0, 10))
        end
    end
    cart:Remove()
end

-- Pushing it: in front of you, turned the way you're going, up and down steps with you.
hook.Add("Think", "LivingCityBodyCarts", function()
    if next(LC.BodyCarts) == nil then return end
    for ply, cart in pairs(LC.BodyCarts) do
        if not IsValid(cart) or not IsValid(ply) then
            LC.BodyCarts[ply] = nil
        else
            local c = cart.lcBodyCart
            for _, b in ipairs(c.bodies) do if IsValid(b) then b:SetPos(cart:GetPos() + Vector(0, 0, 20)) end end -- (they go where it goes)
            if c.pushing and ply:Alive() and ply:GetPos():DistToSqr(cart:GetPos()) < 220 * 220 then
                local fwd = ply:GetAimVector() fwd.z = 0 fwd:Normalize()
                local want = ply:GetPos() + fwd * 58
                local z = cart:GetPos().z
                local tr = util.TraceLine({ start = want + Vector(0, 0, 40), endpos = want - Vector(0, 0, 80), mask = MASK_SOLID_BRUSHONLY, filter = { cart, ply } })
                if tr and tr.Hit and math.abs(tr.HitPos.z + 4 - z) < 60 then z = tr.HitPos.z + 4 end
                local ph = cart:GetPhysicsObject()
                if IsValid(ph) and ph.ComputeShadowControl then
                    ph:Wake()
                    ph:ComputeShadowControl({ secondstoarrive = 0.15, pos = Vector(want.x, want.y, z), angle = Angle(0, fwd:Angle().y + 90, 0),
                        maxangular = 400, maxangulardamp = 800, maxspeed = 400, maxspeeddamp = 600, dampfactor = 0.8, teleportdistance = 0, deltatime = FrameTime() })
                else
                    cart:SetPos(Vector(want.x, want.y, z))
                end
            elseif c.pushing then
                c.pushing = false
            end
        end
    end
end)

hook.Add("KeyPress", "LivingCityBodyCarts", function(ply, key)
    if key ~= IN_USE or hauling[ply] then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e.lcBodyCart and e.lcBodyCart.owner == ply and tr.HitPos:DistToSqr(ply:EyePos()) < 140 * 140 then
        e.lcBodyCart.pushing = not e.lcBodyCart.pushing
    end
end)
hook.Add("AllowPlayerPickup", "LivingCityBodyCarts", function(_, ent) if ent.lcBodyCart then return false end end)
hook.Add("PlayerDisconnected", "LivingCityBodyCarts", function(ply) LC.DropBodyCart(ply) end)
hook.Add("LivingCityJobChanged", "LivingCityBodyCarts", function(ply) LC.DropBodyCart(ply) end)
hook.Add("PlayerSay", "LivingCityBodyCarts", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!bodycart" then return end
    if CartOf(ply) then
        LC.DropBodyCart(ply)
        ply:ChatPrint("[Mortuary] You leave the cart.")
    else
        local ok, why = LC.TakeBodyCart(ply)
        if not ok and why then ply:ChatPrint(why) end
    end
    return ""
end)

