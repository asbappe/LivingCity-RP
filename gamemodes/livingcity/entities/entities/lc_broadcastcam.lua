--[[ Broadcast camera (Living City): a city scanner that films whoever is on
     air (sv_livingcity_propaganda.lua). It comes down when a broadcast starts,
     hangs in front of whoever holds the microphone and keeps their head and
     shoulders in frame, drifting after them when they move. It doesn't care
     who that is: the Director of Propaganda, or the rebel who took his microphone.
     Every city screen and TV shows its picture (cl_livingcity_livecam.lua).
     Shoot it down and the picture dies; the voice carries on. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Broadcast camera"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local FRONT = 92   -- how far in front of the speaker it hangs
local DEADBAND = 34 -- it doesn't chase every small step
local SPEED = 1.6  -- how quickly it drifts to a new spot (per second)
local TURN = 2.6   -- how quickly it turns to keep them centred

-- Where it films: head and shoulders.
function ENT:Subject() return self:GetNW2Entity("lc_subject") end
-- Their head: the head bone if the model has one (some NPCs report their eyes
-- at their feet), else their eyes, else about head height.
local function Head(p)
    local b = p.LookupBone and p:LookupBone("ValveBiped.Bip01_Head1")
    local pos = b and p:GetBonePosition(b)
    if pos then return pos end
    local eye = p:EyePos()
    if eye.z - p:GetPos().z < 30 then return p:GetPos() + Vector(0, 0, 64) end
    return eye
end
local function Chest(p) return Head(p) - Vector(0, 0, 12) end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/combine_scanner.mdl")
        self:SetMoveType(MOVETYPE_NOCLIP)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBounds(Vector(-14, -14, -12), Vector(14, 14, 12))
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER) -- shootable, but nobody bumps into it
        self:SetHealth(40)
        self.born = CurTime()
        self:EmitSound("npc/scanner/scanner_blip1.wav", 70)
    end

    -- Every screen in the city shows its picture, so every client needs to know
    -- where it is, wherever they're standing.
    function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

    function ENT:SetSubject(ply) self:SetNW2Entity("lc_subject", ply) end

    -- Where it wants to be: in front of their face, unless a wall is in the way.
    function ENT:WantPos(p)
        local eye = Head(p)
        local fwd = Angle(0, (p:IsPlayer() and p:EyeAngles() or p:GetAngles()).y, 0):Forward()
        local want = eye + fwd * FRONT + Vector(0, 0, 6)
        local tr = util.TraceLine({ start = eye, endpos = want, filter = { p, self }, mask = MASK_SOLID_BRUSHONLY })
        if tr.Hit then want = tr.HitPos + (tr.HitNormal or Vector(0, 0, 0)) * 16 end
        return want
    end

    function ENT:Think()
        local dt = 0.05
        local p = self:Subject()
        if self.leaving or not IsValid(p) or (p:IsPlayer() and not p:Alive()) or p:Health() <= 0 then
            -- off air: back up into the sky, and gone
            self.leaving = self.leaving or CurTime()
            self:SetPos(self:GetPos() + Vector(0, 0, 220 * dt))
            if CurTime() - self.leaving > 3 then self:Remove() end
            self:NextThink(CurTime() + dt)
            return true
        end
        local want = self:WantPos(p)
        if not self.goal or self.goal:DistToSqr(want) > DEADBAND * DEADBAND then self.goal = want end
        local pos = self:GetPos()
        local rate = (CurTime() - self.born < 4) and 2.4 or SPEED -- coming in, it's quicker about it
        local newPos = LerpVector(math.min(1, dt * rate), pos, self.goal)
        self:SetPos(newPos)
        local face = (Chest(p) - newPos):Angle()
        self:SetAngles(LerpAngle(math.min(1, dt * TURN), self:GetAngles(), face))
        self:NextThink(CurTime() + dt)
        return true
    end

    function ENT:Leave() self.leaving = self.leaving or CurTime() end

    function ENT:OnTakeDamage(dmg)
        self:SetHealth(self:Health() - dmg:GetDamage())
        if self:Health() > 0 or self.dead then return end
        self.dead = true
        local fx = EffectData and EffectData()
        if fx then
            fx:SetOrigin(self:GetPos())
            util.Effect("cball_explode", fx)
        end
        self:EmitSound("npc/scanner/scanner_explode_crash2.wav", 80)
        hook.Run("LivingCityBroadcastCamDown", self, dmg:GetAttacker())
        self:Remove()
    end

    -- Everyone who might be watching a screen also needs to see what it sees:
    -- the studio (or wherever the speaker is) joins every player's view of the world.
    hook.Add("SetupPlayerVisibility", "LivingCityBroadcastCam", function(ply)
        for _, cam in ipairs(LC and LC.EntsOf and LC.EntsOf("lc_broadcastcam") or {}) do
            if IsValid(cam) and not cam.leaving then AddOriginToPVS(cam:GetPos()) end
        end
    end)
end

if CLIENT then
    -- Recording: its eye blinks red, slowly, like the record light on a phone
    -- (the same red as a scanner a person is flying, but a slow on, off).
    local GLOW = Material("sprites/light_glow02_add")
    local function Eye(self) return self:GetPos() + self:GetForward() * 12 + self:GetUp() * -2 end
    -- 0 to 1: on for about a second, a soft fade either side, then dark for a second
    local function Rec() return math.Clamp(math.sin(CurTime() * math.pi) * 1.6, 0, 1) end

    function ENT:Draw() self:DrawModel() end

    -- Its hum, played where it is (started here so everyone hears it, wherever they joined from).
    function ENT:Initialize()
        self.hum = CreateSound and CreateSound(self, "npc/scanner/cbot_fly_loop.wav") or nil
        if self.hum then self.hum:PlayEx(0.45, 100) end
    end
    function ENT:OnRemove()
        if self.hum then self.hum:Stop() self.hum = nil end
    end

    function ENT:DrawTranslucent()
        if LC_CL and LC_CL.LiveCamRendering then return end -- not in its own picture
        local a = Rec()
        if a <= 0 then return end
        render.SetMaterial(GLOW)
        render.DrawSprite(Eye(self), 26, 26, Color(255, 40, 30, 255 * a))
        render.DrawSprite(Eye(self), 10, 10, Color(255, 200, 190, 255 * a))
    end

    function ENT:Think()
        local a = Rec()
        if a <= 0.05 then return end
        local dl = DynamicLight(self:EntIndex() + 4096)
        if dl then
            dl.pos = Eye(self)
            dl.r, dl.g, dl.b = 255, 30, 20
            dl.brightness = a
            dl.decay = 900
            dl.size = 140
            dl.dietime = CurTime() + 0.1
        end
    end
end
