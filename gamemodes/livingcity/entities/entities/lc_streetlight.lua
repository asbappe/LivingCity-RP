--[[ Streetlight (Living City): placed with the editor ("Street: streetlight").
     It lights the street around it. Shoot it, or give it time, and it
     breaks: dark until a maintenance worker fixes it (their "Lights out" shift
     goes to the broken ones first). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Streetlight"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_c17/lamppost03a_off.mdl", "models/props_c17/light_cagelight02_on.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[1]
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:OnTakeDamage(dmg)
        if dmg:GetDamage() >= 10 and LC and LC.BreakStreetFixture then LC.BreakStreetFixture(self, dmg:GetAttacker()) end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local WARM = Color(255, 220, 160, 200)
    -- The lamp is at the end of the arm: whichever way the model's arm reaches
    -- furthest from the pole, just under the top.
    local function Lamp(self)
        if self.lcLampLocal then return self:LocalToWorld(self.lcLampLocal) end
        local mins, maxs = self:GetModelBounds()
        if not mins or (maxs - mins):LengthSqr() < 1 then return self:GetPos() end -- (the model isn't in yet)
        local reach = { { maxs.x, Vector(1, 0, 0) }, { -mins.x, Vector(-1, 0, 0) }, { maxs.y, Vector(0, 1, 0) }, { -mins.y, Vector(0, -1, 0) } }
        table.sort(reach, function(a, b) return a[1] > b[1] end)
        self.lcLampLocal = reach[1][2] * (reach[1][1] * 0.88) + Vector(0, 0, maxs.z - 10)
        return self:LocalToWorld(self.lcLampLocal)
    end
    function ENT:DrawTranslucent()
        if self:GetNW2Bool("lc_broken", false) or self:GetNW2Bool("lc_nopower", false) then return end
        render.SetMaterial(GLOW)
        render.DrawSprite(Lamp(self), 64, 64, WARM)
    end
    -- light the street, for the few lamps closest to you. Five times a second is
    -- plenty (each light lasts a little longer than that), and the nearest six
    -- are picked out without sorting the lot.
    local MAXLIT, nextT = 6, 0
    local near, dist = {}, {}
    hook.Add("Think", "LivingCityStreetlights", function()
        local now = CurTime()
        if now < nextT then return end
        nextT = now + 0.2
        local me = LocalPlayer()
        if not IsValid(me) then return end
        local mp, n = me:GetPos(), 0
        for _, e in ipairs(LC.EntsOf("lc_streetlight")) do
            local d = e:GetPos():DistToSqr(mp)
            if d < 2000 * 2000 and not e:GetNW2Bool("lc_broken", false) and not e:GetNW2Bool("lc_nopower", false) then
                if n < MAXLIT then
                    n = n + 1
                    near[n], dist[n] = e, d
                else
                    local far = 1
                    for i = 2, MAXLIT do if dist[i] > dist[far] then far = i end end
                    if d < dist[far] then near[far], dist[far] = e, d end
                end
            end
        end
        for i = 1, n do
            local e = near[i]
            local dl = DynamicLight(e:EntIndex() + 8192)
            if dl then
                dl.pos = Lamp(e)
                dl.r, dl.g, dl.b = 255, 215, 160
                dl.brightness = 2
                dl.decay = 0 -- (refreshed five times a second: a decay would make it pulse)
                dl.size = 520
                dl.dietime = now + 0.35
            end
        end
    end)
end
