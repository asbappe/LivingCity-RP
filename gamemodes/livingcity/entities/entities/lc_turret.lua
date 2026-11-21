--[[ Combine barricade with a mounted gun (Living City): Valve's own, as it stands by the double gate
     in d1_canals_07 (turret_1): the Combine bunker gun, its foot 33 above the floor, between two
     short Combine barricades, the gunner standing behind it. Placed with the editor ("Fixture:
     Combine barricade with mounted gun"), facing you. Solid; the barricades go with it. E on it from
     behind mans the gun: sh_livingcity_turret.lua. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine mounted gun"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true -- (it unfolds, fires and folds up: Valve's animations)

ENT.GunModel = "models/props_combine/bunker_gun01.mdl"
ENT.Lift = 33 -- the gun's foot above the floor (Valve's)
-- Valve's two barricades, from the gun's foot (x ahead, y to its left, z up). In d1_canals_07 they
-- stand turned 14.5 degrees from the gun to fit that room; here they stand square to it.
ENT.Parts = {
    { model = "models/props_combine/combine_barricade_short02a.mdl", x = -3.24, y = 34.66, z = -9.97 },
    { model = "models/props_combine/combine_barricade_short01a.mdl", x = -3.77, y = -31.31, z = -9.97 },
}

if SERVER then
    local function Turn(yaw, x, y)
        local r = math.rad(yaw)
        local c, s = math.cos(r), math.sin(r)
        return x * c - y * s, x * s + y * c
    end

    -- A barricade, solid by its own shape, frozen where it stands. (prop_dynamic_override: one of
    -- these models has physics data, which a plain prop_dynamic refuses.)
    local function MakePart(gun, part, yaw)
        local e = ents.Create("prop_dynamic_override")
        if not IsValid(e) then return nil end
        local x, y = Turn(yaw, part.x, part.y)
        local p = gun:GetPos()
        e:SetModel(part.model)
        e:SetPos(Vector(p.x + x, p.y + y, p.z + part.z))
        e:SetAngles(Angle(0, yaw, 0))
        e:SetKeyValue("solid", "6")
        e:SetKeyValue("DisableBoneFollowers", "1")
        e:Spawn()
        e:Activate()
        e.lcTurretGun = gun        -- (E on a barricade mans the gun too)
        e.PhysgunDisabled = true   -- (moved with the gun, in build mode, never on its own)
        e.m_tblToolsAllowed = {}
        return e
    end

    function ENT:Initialize()
        self:SetModel(self.GunModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        self:SetPoseParameter("aim_yaw", 0)
        self:SetPoseParameter("aim_pitch", LC and LC.Turret and LC.Turret.PITCH_CENTER or 7.5)
        if LC and LC.TurretAnim then LC.TurretAnim(self, "idle_inactive") end -- (folded up until someone mans it, as Valve's)
        -- (a moment later: the editor seats it on the floor after it spawns)
        timer.Simple(0.1, function() if IsValid(self) then self:StandUp() end end)
    end

    -- On its barricades: the gun Lift above the floor spot (`ground`: the editor's marker, where the
    -- physgun left it), upright, the barricades either side. Made again each time it moves.
    function ENT:StandUp(ground)
        if not ground and self.lcFixturePoint and self.lcFixturePoint.pos then ground = self.lcFixturePoint.pos end
        ground = ground or self.lcGround or self:GetPos()
        self.lcGround = Vector(ground.x, ground.y, ground.z)
        local yaw = self:GetAngles().y
        self:SetAngles(Angle(0, yaw, 0))
        self:SetPos(Vector(ground.x, ground.y, ground.z + self.Lift))
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) phys:Wake() end
        for _, e in ipairs(self.lcParts or {}) do if IsValid(e) then e:Remove() end end
        self.lcParts = {}
        for i, part in ipairs(self.Parts) do
            local e = MakePart(self, part, yaw)
            self.lcParts[i] = e
            self:SetNW2Entity("lc_turret_part" .. i, e or NULL)
        end
        return true
    end

    function ENT:Think()
        local busy = LC and LC.TurretAnimThink and LC.TurretAnimThink(self)
        self:NextThink(CurTime() + (busy and 0 or 0.5))
        return true
    end

    function ENT:OnRemove()
        for _, e in ipairs(self.lcParts or {}) do if IsValid(e) then e:Remove() end end
        if LC and LC.TurretGone then LC.TurretGone(self) end
    end
end

if CLIENT then
    function ENT:Draw()
        if LC and LC.TurretPose then LC.TurretPose(self) end -- (the barrel where its gunner aims)
        self:DrawModel()
    end
end
