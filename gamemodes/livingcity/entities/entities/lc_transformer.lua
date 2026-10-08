--[[ Transformer (Living City): placed with the editor ("Fixture: transformer").
     It powers the district around it (sv_livingcity_power.lua): streetlights,
     loudspeakers, city screens, forcefields and Combine door locks. Sabotage it
     (a multitool, or enough damage) and the district goes dark until a
     maintenance worker brings it back. Press E on it to repair it, if that's
     your trade.
     It's the Combine's own generator: bolted down (it's top heavy, and would
     fall over), humming, with its lamp lit while it has power. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Transformer"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_combine/combine_generator01.mdl", "models/props_c17/substation_transformer01a.mdl",
    "models/props_c17/substation_transformer01d.mdl", "models/props_lab/powerbox01a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    m = m or MODELS[#MODELS]
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    -- bolted down: never free physics (it's top heavy and goes over)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    self.lcHealth = 150
end

if SERVER then
    -- (a gravity gun doesn't knock it loose; a physgun in build mode moves it, and it's bolted down again where it's dropped)
    function ENT:GravGunPunt() return false end
    function ENT:GravGunPickupAllowed() return false end

    function ENT:Use(ply)
        if IsValid(ply) and ply:IsPlayer() and LC and LC.UseTransformer then
            local ok, why = LC.UseTransformer(ply, self)
            if not ok and why then ply:ChatPrint(why) end
        end
    end
    function ENT:OnTakeDamage(dmg)
        if self:GetNW2Bool("lc_down", false) then return end
        self.lcHealth = (self.lcHealth or 150) - dmg:GetDamage()
        if self.lcHealth <= 0 and LC and LC.TransformerDown then
            self.lcHealth = 150
            LC.TransformerDown(self, dmg:GetAttacker(), "damage")
        end
    end
end

if CLIENT then
    -- It hums while it has power, and its lamp is lit; down, it's dark and quiet.
    local HUMS = { "ambient/machines/power_transformer_loop_1.wav", "ambient/machines/power_transformer_loop_2.wav", "ambient/energy/force_field_loop1.wav" }
    local hum
    local function Hum()
        if hum ~= nil then return hum or nil end
        hum = false
        for _, h in ipairs(HUMS) do
            if file.Exists("sound/" .. h, "GAME") then hum = h break end
        end
        return hum or nil
    end

    -- The lamp: the model's own light attachment if it has one, else high on its front.
    local GLOW = Material("sprites/light_glow02_add")
    local LAMP = Color(150, 205, 255, 230)
    local function Lamp(self)
        if self.lcLampAtt == nil then
            self.lcLampAtt = false
            local list = self.GetAttachments and self:GetAttachments() or {}
            for _, a in ipairs(list) do
                local n = string.lower(a.name or "")
                if string.find(n, "light", 1, true) or string.find(n, "lamp", 1, true) or string.find(n, "glow", 1, true) then self.lcLampAtt = a.id break end
            end
            if not self.lcLampAtt and list[1] then self.lcLampAtt = list[1].id end
        end
        if self.lcLampAtt then
            local at = self:GetAttachment(self.lcLampAtt)
            if at and at.Pos then return at.Pos end
        end
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        return self:LocalToWorld(Vector(maxs.x + 1, 0, mins.z + (maxs.z - mins.z) * 0.8))
    end

    function ENT:Draw() self:DrawModel() end

    function ENT:DrawTranslucent()
        if self:GetNW2Bool("lc_down", false) then return end
        local pulse = 0.85 + 0.15 * math.sin(CurTime() * 2.5)
        render.SetMaterial(GLOW)
        local s = 26 * pulse
        render.DrawSprite(Lamp(self), s, s, LAMP)
    end

    function ENT:Think()
        local me = LocalPlayer()
        local near = IsValid(me) and me:GetPos():DistToSqr(self:GetPos()) < 1500 * 1500
        local on = near and not self:GetNW2Bool("lc_down", false)
        if on and not self.lcHum then
            local path = Hum()
            if path then
                self.lcHum = CreateSound and CreateSound(self, path) or nil
                if self.lcHum then self.lcHum:PlayEx(0.5, 100) end
            end
        elseif not on and self.lcHum then
            self.lcHum:Stop()
            self.lcHum = nil
        end
        if on then
            local dl = DynamicLight(self:EntIndex() + 12288)
            if dl then
                dl.pos = Lamp(self)
                dl.r, dl.g, dl.b = 120, 180, 255
                dl.brightness = 1
                dl.decay = 0
                dl.size = 160
                dl.dietime = CurTime() + 0.7
            end
        end
        self:SetNextClientThink(CurTime() + 0.5)
        return true
    end

    function ENT:OnRemove()
        if self.lcHum then self.lcHum:Stop() self.lcHum = nil end
    end
end
