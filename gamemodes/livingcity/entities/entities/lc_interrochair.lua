--[[
    Interrogation chair (Living City). Place it with the Living City Editor
    ("Fixture: Resistance interrogation chair"). A wooden chair with a harsh
    lamp hung over it, pointing straight down: dark until someone is sat in
    it, then lit, so whoever is in the chair is all but blinded.
    What happens in it: sv_livingcity_chair.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Interrogation chair"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_c17/FurnitureChair001a.mdl", "models/nova/chair_wood01.mdl" }
local LAMP_MODEL = "models/props_wasteland/light_spotlight01_lamp.mdl"
local LAMP_UP = 112 -- how far above the chair's feet the lamp hangs

if SERVER then
    local function MakeLamp(self)
        local top = self:GetPos() + Vector(0, 0, LAMP_UP)
        -- the beam you can see in the air
        local sp = ents.Create("point_spotlight")
        if IsValid(sp) then
            sp:SetPos(top)
            sp:SetAngles(Angle(90, 0, 0))
            sp:SetKeyValue("spotlightlength", "120")
            sp:SetKeyValue("spotlightwidth", "48")
            sp:SetKeyValue("rendercolor", "255 250 235")
            sp:SetKeyValue("spawnflags", "2") -- (off to start with; its own weak light isn't used)
            sp:Spawn()
            sp:Activate()
            sp:SetParent(self)
            self.lcSpot = sp
        end
        -- the light itself: a tight, very bright cone straight down
        local dl = ents.Create("light_dynamic")
        if IsValid(dl) then
            dl:SetPos(top)
            dl:SetAngles(Angle(90, 0, 0))
            dl:SetKeyValue("_light", "255 250 235 255")
            dl:SetKeyValue("brightness", "7")
            dl:SetKeyValue("distance", "190")
            dl:SetKeyValue("_inner_cone", "24")
            dl:SetKeyValue("_cone", "42")
            dl:SetKeyValue("pitch", "-90")
            dl:SetKeyValue("style", "0")
            dl:Spawn()
            dl:Activate()
            dl:SetParent(self)
            dl:Fire("TurnOff")
            self.lcLight = dl
        end
        -- the lamp's housing, if this install has the model
        if not util.IsValidModel or util.IsValidModel(LAMP_MODEL) then
            local lamp = ents.Create("prop_dynamic")
            if IsValid(lamp) then
                lamp:SetModel(LAMP_MODEL)
                lamp:SetPos(top + Vector(0, 0, 6))
                lamp:SetAngles(Angle(90, 0, 0))
                lamp:Spawn()
                lamp:SetParent(self)
                self.lcLamp = lamp
            end
        end
    end

    function ENT:Initialize()
        local m
        for _, c in ipairs(MODELS) do
            if not util.IsValidModel or util.IsValidModel(c) then m = c break end
        end
        self:SetModel(m or MODELS[1])
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        -- (a moment later: the editor seats the chair on the floor after it spawns)
        timer.Simple(0.5, function() if IsValid(self) then pcall(MakeLamp, self) end end)
    end

    function ENT:SetLamp(on)
        if IsValid(self.lcSpot) then self.lcSpot:Fire(on and "LightOn" or "LightOff") end
        if IsValid(self.lcLight) then self.lcLight:Fire(on and "TurnOn" or "TurnOff") end
        self:SetNW2Bool("lc_chair_lit", on and true or false)
    end

    function ENT:OnRemove()
        for _, e in ipairs({ self.lcSpot, self.lcLight, self.lcLamp }) do if IsValid(e) then e:Remove() end end
        if LC and LC.ChairGone then LC.ChairGone(self) end
    end

    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.ChairUse then LC.ChairUse(activator, self) end
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    function ENT:Draw()
        self:DrawModel()
        if not self:GetNW2Bool("lc_chair_lit", false) then return end
        -- the bulb's glare, whatever the map's lighting does with the rest
        render.SetMaterial(glow)
        render.DrawSprite(self:GetPos() + Vector(0, 0, LAMP_UP - 4), 90, 90, Color(255, 250, 235, 255))
    end
end
