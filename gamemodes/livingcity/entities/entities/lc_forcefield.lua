--[[ Combine forcefield (Living City): placed with the editor ("Fixture: Combine
     forcefield"), facing you, across a doorway or a street (about eight feet
     wide). Units pass through it; nobody else does, unless they swipe a
     Combine keycard (E on it). It goes down when its district loses power
     (sv_livingcity_power.lua), and a multitool shorts it out for a minute.
     Who may pass is decided the same way on both sides (sh_livingcity_power.lua),
     so walking into it is smooth. It runs off a Combine power bank, takes a
     beating and recharges, and can be overwhelmed or broken
     (sv_livingcity_checkpoints.lua). Drawn with HL2's own Combine shield
     material (effects/com_shield003a). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine forcefield"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.HalfWidth, ENT.Height, ENT.Thick = 64, 112, 4

ENT.lcForcefield = true -- (the collision hook looks for this: sh_livingcity_power.lua)

-- The same box on both sides: the client predicts walking into it.
function ENT:Initialize()
    local w, h, t = self.HalfWidth, self.Height, self.Thick
    self:SetModel("models/props_combine/combine_fence01b.mdl")
    self:PhysicsInitBox(Vector(-t, -w, 0), Vector(t, w, h))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetCollisionBounds(Vector(-t, -w, 0), Vector(t, w, h))
    self:EnableCustomCollisions(true)
    self:SetCustomCollisionCheck(true)
    if SERVER then self:SetUseType(SIMPLE_USE) end
    -- the field is much bigger than the post it hangs from: draw it whenever any of it is in view
    if CLIENT then self:SetRenderBounds(Vector(-24, -w - 24, 0), Vector(24, w + 24, h + 24)) end -- (the posts at both ends too)
end

-- Is it up right now? (power, and not shorted out)
function ENT:FieldUp()
    return not self:GetNW2Bool("lc_nopower", false) and self:GetNW2Float("lc_short_until", 0) < CurTime()
end

if SERVER then
    function ENT:Use(ply)
        if IsValid(ply) and ply:IsPlayer() and LC and LC.SwipeForcefield then
            local ok, why = LC.SwipeForcefield(ply, self)
            if not ok and why then ply:ChatPrint(why) end
        end
    end
end

if CLIENT then
    -- Half-Life 2's own Combine shield (what the map's forcefield brushes use);
    -- the old flat blue if it isn't there.
    local SHIELD = Material("effects/com_shield003a")
    local HAS_SHIELD = SHIELD and not SHIELD:IsError()
    local FIELD = Color(80, 160, 255, 40)
    local LINE = Color(140, 200, 255, 110)
    local function Face(origin, ang, w, h)
        cam.Start3D2D(origin, ang, 1)
            surface.SetDrawColor(FIELD)
            surface.DrawRect(0, 0, w * 2, h)
            -- slow bands rolling down it
            surface.SetDrawColor(LINE)
            local off = (CurTime() * 30) % 16
            for y = off, h, 16 do surface.DrawRect(0, y, w * 2, 1) end
        cam.End3D2D()
    end
    -- the shield material, both sides; weaker, it thins and flickers
    local function Shield(self, w, h)
        local hp, max = self:GetNW2Int("lc_ff_hp", 1), math.max(1, self:GetNW2Int("lc_ff_hpmax", 1))
        local f = math.Clamp(hp / max, 0, 1)
        local a = 255 * (0.35 + 0.65 * f)
        if f < 0.35 and math.random() < 0.25 then a = a * 0.3 end
        local col = Color(255, 255, 255, a)
        local mid = self:LocalToWorld(Vector(0, 0, h / 2))
        render.SetMaterial(SHIELD)
        render.DrawQuadEasy(mid, self:GetForward(), w * 2, h, col, 180)
        render.DrawQuadEasy(mid, -self:GetForward(), w * 2, h, col, 180)
    end
    -- A post at each end of the field: the same post, the far one turned round
    -- to face it (so the emitters point at each other), the field strung between.
    ENT.PostYaw = { 0, 180 } -- (left end, right end)
    local function DrawPost(self, side, yaw)
        self:SetRenderOrigin(self:LocalToWorld(Vector(0, side * self.HalfWidth, 0)))
        self:SetRenderAngles(self:LocalToWorldAngles(Angle(0, yaw, 0)))
        self:SetupBones()
        self:DrawModel()
    end
    function ENT:DrawTranslucent()
        DrawPost(self, -1, self.PostYaw[1])
        DrawPost(self, 1, self.PostYaw[2])
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
        self:SetupBones()
        if not self:FieldUp() then return end
        local w, h = self.HalfWidth, self.Height
        if HAS_SHIELD then return Shield(self, w, h) end
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        Face(self:LocalToWorld(Vector(0, -w, h)), ang, w, h)
        -- and the back, seen from the other side (3D2D only draws one face)
        local back = Angle(ang.p, ang.y, ang.r)
        back:RotateAroundAxis(self:GetUp(), 180)
        Face(self:LocalToWorld(Vector(0, w, h)), back, w, h)
    end
end
