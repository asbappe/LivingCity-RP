--[[ Combine power bank (Living City): the heart of a checkpoint. Placed with
     the editor ("Fixture: Combine power bank"), or put up by a Civil Protection
     officer. Turrets and forcefields near it hang off it by a cable
     (sv_livingcity_checkpoints.lua). It draws from its district's transformer
     (sv_livingcity_power.lua): when the district goes dark, or a multitool
     shorts it out, its glow dies and so does everything on its cables. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine power bank"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_combine/suit_charger001.mdl", "models/props_combine/health_charger001.mdl", "models/props_lab/powerbox01a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or MODELS[#MODELS])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

-- Live: its district has power, and nobody's shorted it.
function ENT:Live()
    return not self:GetNW2Bool("lc_nopower", false) and self:GetNW2Float("lc_short_until", 0) < CurTime()
end

if SERVER then
    function ENT:Use(ply)
        if IsValid(ply) and ply:IsPlayer() and LC and LC.UsePowerBank then
            local ok, why = LC.UsePowerBank(ply, self)
            if why then ply:ChatPrint(why) end
        end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local LIVE, CORE, SPARK = Color(90, 190, 255), Color(220, 245, 255), Color(255, 150, 60)

    -- the face of it: a little out from its front
    local function Front(self, up)
        local maxs, mins = self:OBBMaxs(), self:OBBMins()
        return self:LocalToWorld(Vector(maxs.x + 1, 0, mins.z + (maxs.z - mins.z) * (up or 0.55)))
    end

    function ENT:Draw() self:DrawModel() end

    -- Up close, it says what it is: to a unit, that E recharges the vest; to anyone else, that
    -- touching it is a crime (the owner, 7 November).
    local LABEL_RANGE = 110
    local function Unit(me) return me:GetNW2Bool("lc_unit", false) or me:GetNW2String("lcf_faction", "") == "cp" or me:GetNW2String("lcf_faction", "") == "admin" end
    -- (made once here, not every frame)
    local C_0_0_0_200 = Color(0, 0, 0, 200)
    local C_150_215_255 = Color(150, 215, 255)
    local C_200_200_200 = Color(200, 200, 200)
    local C_235_235_235 = Color(235, 235, 235)
    local C_255_170_120 = Color(255, 170, 120)
    function ENT:DrawLabel()
        local me = LocalPlayer()
        if not IsValid(me) or not me:Alive() then return end
        local center = self:WorldSpaceCenter()
        if center:DistToSqr(me:EyePos()) > LABEL_RANGE * LABEL_RANGE then return end
        local live = self:Live()
        local top = center + Vector(0, 0, (self:OBBMaxs().z - self:OBBMins().z) / 2 + 8)
        local ang = me:EyeAngles()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        local title = "COMBINE POWER BANK: " .. (live and "LIVE" or "DEAD")
        local line
        if Unit(me) then line = live and "E: read it, and recharge your vest" or "No power: nothing charges here"
        else line = live and "Tampering with it is a crime" or "Dead. Leave it be" end
        cam.Start3D2D(top, Angle(0, ang.y, 90), 0.07)
            draw.SimpleTextOutlined(title, "DermaLarge", 0, -22, live and C_150_215_255 or C_200_200_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_200)
            draw.SimpleTextOutlined(line, "DermaLarge", 0, 10, Unit(me) and C_235_235_235 or C_255_170_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_200)
        cam.End3D2D()
    end

    function ENT:DrawTranslucent()
        self:DrawLabel()
        if self:GetNW2Float("lc_short_until", 0) > CurTime() then
            -- shorted: a spit of sparks now and then
            if math.random() < 0.15 then
                render.SetMaterial(GLOW)
                render.DrawSprite(Front(self, math.Rand(0.3, 0.8)), 14, 14, SPARK)
            end
            return
        end
        if not self:Live() then return end
        -- a slow breathing glow: the city's power, humming through it
        local a = 0.65 + 0.35 * math.sin(CurTime() * 2.2 + self:EntIndex())
        render.SetMaterial(GLOW)
        render.DrawSprite(Front(self, 0.7), 34 * a, 34 * a, Color(LIVE.r, LIVE.g, LIVE.b, 220 * a))
        render.DrawSprite(Front(self, 0.7), 10, 10, CORE)
        render.DrawSprite(Front(self, 0.35), 18 * a, 18 * a, Color(LIVE.r, LIVE.g, LIVE.b, 160 * a))
    end

    function ENT:Think()
        if not self:Live() then return end
        local me = LocalPlayer()
        if not IsValid(me) or me:GetPos():DistToSqr(self:GetPos()) > 1500 * 1500 then return end
        local dl = DynamicLight(self:EntIndex() + 12288)
        if dl then
            dl.pos = Front(self, 0.6) + self:GetForward() * 12
            dl.r, dl.g, dl.b = 80, 170, 255
            dl.brightness = 1.2
            dl.decay = 0
            dl.size = 200
            dl.dietime = CurTime() + 0.3
        end
        self:SetNextClientThink(CurTime() + 0.2)
        return true
    end
end
