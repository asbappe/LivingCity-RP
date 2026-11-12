--[[ Incinerator (Living City): placed with the editor ("Fixture: incinerator").
     The city's dead end up here. Haul a body to it (press E on a body, or
     the actions menu, F1) and press E on the incinerator, or just let go of
     the body next to it. Morticians are paid for every one
     (sv_livingcity_mortuary.lua). Nothing else ever spawns one: no
     incinerator on the map, no cremations.
     It's a spent headcrab canister, a fire burning in its broad, open end.
     It stands on end, the open end to the sky, like a torch (the owner,
     12 November: "can we make it so it stands with the fire/open/big end up
     at the sky? Like a fire torch?"). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Incinerator"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

-- A spent headcrab canister, turned furnace: a burner roaring out of its back end.
local MODELS = { "models/props_combine/headcrabcannister01a.mdl", "models/props_c17/furnitureboiler001a.mdl", "models/props_wasteland/kitchen_stove002a.mdl" }

function ENT:Initialize()
    if CLIENT then return end -- (the client's own Initialize is below, with the fire)
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
    timer.Simple(0.2, function() if IsValid(self) then self:FindMouth() self:StandUp() end end)
end

if SERVER then
    -- Which end is the broad, open one (where the fire goes)? Measure how
    -- thick the canister is near each end, with traces that only hit it, and
    -- tell everyone's game (as a spot in its own frame, and the way out).
    function ENT:FindMouth()
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        local size = maxs - mins
        local axis = (size.x >= size.y and size.x >= size.z) and "x" or ((size.y >= size.z) and "y" or "z")
        local across = axis == "z" and "x" or "z"
        local c = (mins + maxs) * 0.5
        local me = self
        local function Thick(frac)
            local at = Vector(c.x, c.y, c.z)
            at[axis] = mins[axis] + size[axis] * frac
            local from = Vector(at.x, at.y, at.z)
            from[across] = maxs[across] + 40
            local tr = util.TraceLine({ start = self:LocalToWorld(from), endpos = self:LocalToWorld(at),
                filter = function(e) return e == me end, ignoreworld = true })
            if not (tr and tr.Hit) then return 0 end
            return (self:LocalToWorld(at) - tr.HitPos):Length()
        end
        local lo, hi = Thick(0.1), Thick(0.9)
        local back, dir = Vector(c.x, c.y, c.z), Vector(0, 0, 0)
        if hi > lo then back[axis], dir[axis] = maxs[axis] - size[axis] * 0.06, 1
        else back[axis], dir[axis] = mins[axis] + size[axis] * 0.06, -1 end
        self:SetNW2Vector("lc_mouth", back)
        self:SetNW2Vector("lc_mouth_dir", dir)
        self:SetNW2Float("lc_mouth_r", math.max(lo, hi, 8))
    end

    -- Stood on end, the broad open end up and the other on the floor (only a model lying on its
    -- side, as the canister does: a boiler or a stove already stands). `ground`: the floor spot it
    -- stands on (the editor's marker; else the floor under it). Frozen there, steady.
    function ENT:StandUp(ground)
        local dir = self:GetNW2Vector("lc_mouth_dir", Vector(0, 0, 0))
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        if not (dir and mins and maxs) then return false end
        local axis = math.abs(dir.x) > 0.5 and "x" or (math.abs(dir.y) > 0.5 and "y" or nil)
        if not axis or (maxs[axis] - mins[axis]) < 40 then return false end
        local yaw = self:GetAngles().y
        local ang
        if axis == "x" then ang = Angle(dir.x > 0 and -90 or 90, yaw, 0)   -- (pitch -90: its front to the sky)
        else ang = Angle(0, yaw, dir.y > 0 and 90 or -90) end               -- (roll 90: its left to the sky)
        if not ground and self.lcFixturePoint and self.lcFixturePoint.pos then ground = self.lcFixturePoint.pos end
        if not ground then
            local from = self:WorldSpaceCenter()
            local tr = util.TraceLine({ start = from, endpos = from - Vector(0, 0, 400), filter = self, mask = MASK_SOLID_BRUSHONLY })
            ground = (tr and tr.Hit) and tr.HitPos or (from - Vector(0, 0, (maxs[axis] - mins[axis]) * 0.5))
        end
        self:SetAngles(ang)
        -- the closed end (the middle of it) on the floor spot
        local c = (mins + maxs) * 0.5
        local foot = Vector(c.x, c.y, c.z)
        foot[axis] = dir[axis] > 0 and mins[axis] or maxs[axis]
        local at = self:LocalToWorld(foot)
        self:SetPos(self:GetPos() + (ground - at))
        self.lcBasePos = Vector(ground.x, ground.y, ground.z)
        self:SetNW2Bool("lc_upright", true)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) phys:Wake() end
        return true
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if LC and LC.FeedIncinerator then
            local ok, why = LC.FeedIncinerator(ply, self)
            if not ok and why then ply:ChatPrint(why) end
        end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local FLAMES = { "particles/flamelet1", "particles/flamelet2", "particles/flamelet3", "particles/flamelet4", "particles/flamelet5" }

    -- Its two ends, along its length: the back end (the burner) and the front
    -- (where the bodies go in). The canister's back is the end nearer its
    -- origin, along its longest side.
    local function Ends(self)
        -- the broad end, as the server measured it
        local mouth = self:GetNW2Vector("lc_mouth", Vector(0, 0, 0))
        if not self.lcMouthSet and mouth ~= Vector(0, 0, 0) then
            local dir = self:GetNW2Vector("lc_mouth_dir", Vector(1, 0, 0))
            local mins, maxs = self:OBBMins(), self:OBBMaxs()
            local front = (mins + maxs) * 0.5 - (mouth - (mins + maxs) * 0.5)
            self.lcBackLocal, self.lcFrontLocal, self.lcBackDir = mouth, front, dir
            self.lcMouthSet = true
        end
        if not self.lcBackLocal then
            local mins, maxs = self:OBBMins(), self:OBBMaxs()
            local size = maxs - mins
            local axis = (size.x >= size.y and size.x >= size.z) and "x" or ((size.y >= size.z) and "y" or "z")
            local c = (mins + maxs) * 0.5
            local back, front, dir = Vector(c.x, c.y, c.z), Vector(c.x, c.y, c.z), Vector(0, 0, 0)
            local far, near = maxs[axis], mins[axis]
            if math.abs(mins[axis]) > math.abs(maxs[axis]) then far, near = mins[axis], maxs[axis] end
            back[axis], front[axis] = near, far
            dir[axis] = near > far and 1 or -1
            self.lcBackLocal, self.lcFrontLocal, self.lcBackDir = back, front, dir
        end
        local back = self:LocalToWorld(self.lcBackLocal)
        local out = self:LocalToWorld(self.lcBackLocal + self.lcBackDir) - back
        return back, self:LocalToWorld(self.lcFrontLocal), out
    end

    -- The fire didn't show until the incinerator was moved (the owner, 7 November): the flames hung
    -- on the client think alone. Now the draw pass lights it too, each incinerator has its own
    -- emitter (with a box it's always drawn in), and the client think is asked for on creation.
    function ENT:Initialize()
        if SERVER then return end
        self:SetNextClientThink(CurTime())
        self.lcNextFlame = 0
    end

    local function Emitter(self, at)
        if self.lcEmitter and (not self.lcEmitter.IsValid or self.lcEmitter:IsValid()) then return self.lcEmitter end
        if not ParticleEmitter then return nil end
        local em = ParticleEmitter(at)
        if em then
            if em.SetBBox then em:SetBBox(at - Vector(200, 200, 200), at + Vector(200, 200, 200)) end
            if em.SetNoDraw then em:SetNoDraw(false) end
        end
        self.lcEmitter = em
        return em
    end

    -- The flames, the glow of the light and the roar: from Think when it runs, from the draw pass otherwise.
    local function Fire(self, now)
        local burning = self:GetNW2Float("lc_burn_until", 0) > now
        local back, _, out = Ends(self)
        if now > (self.lcNextFlame or 0) then
            self.lcNextFlame = now + (burning and 0.04 or 0.08)
            local emitter = Emitter(self, back)
            if emitter then
                -- a fire burning in the mouth of it, filling it, and licking out
                local r = math.min(self:GetNW2Float("lc_mouth_r", 16), 40) * 0.6
                for _ = 1, burning and 5 or 3 do
                    local spread = VectorRand() spread = (spread - out * spread:Dot(out)) * r
                    local p = emitter:Add(FLAMES[math.random(#FLAMES)], back - out * math.Rand(4, 20) + spread)
                    if p then
                        p:SetVelocity(out * math.Rand(burning and 60 or 25, burning and 130 or 60) + VectorRand() * 10 + Vector(0, 0, math.Rand(25, 55)))
                        p:SetDieTime(math.Rand(0.45, burning and 0.9 or 0.7))
                        p:SetStartAlpha(240)
                        p:SetEndAlpha(0)
                        p:SetStartSize(math.Rand(burning and 22 or 16, burning and 34 or 24))
                        p:SetEndSize(math.Rand(4, 10))
                        p:SetRoll(math.Rand(0, 360))
                        p:SetRollDelta(math.Rand(-2, 2))
                        p:SetColor(255, 255, 255)
                    end
                end
            end
        end
        if (self.lcNextLight or 0) <= now then
            self.lcNextLight = now + 0.03
            local d = DynamicLight(self:EntIndex())
            if d then
                d.pos = back + out * 20
                d.r, d.g, d.b = 255, 120, 40
                d.brightness = burning and 3 or 1.5
                d.size = burning and 300 or 180
                d.decay = 600
                d.dietime = now + 0.2
            end
        end
        -- the burner's roar
        if not self.lcRoar and CreateSound then
            self.lcRoar = CreateSound(self, "ambient/fire/fire_med_loop1.wav")
            if self.lcRoar then self.lcRoar:PlayEx(0.5, 100) end
        end
        if self.lcRoar then self.lcRoar:ChangeVolume(burning and 0.9 or 0.5, 0.5) end
    end

    local function Near(self, d)
        local me = LocalPlayer()
        return IsValid(me) and me:GetPos():DistToSqr(self:GetPos()) <= d * d
    end

    -- (made once here, not every frame)
    local V_60_60_60 = Vector(120, 120, 120) -- (standing on end, the flames lick well over the top)
    function ENT:Draw()
        self:DrawModel()
        -- (the sprites and flames reach past the model: drawn whenever any of it could be seen)
        if not self.lcBoundsSet and self.SetRenderBounds then
            self.lcBoundsSet = true
            local mins, maxs = self:OBBMins(), self:OBBMaxs()
            if mins and maxs then self:SetRenderBounds(mins - V_60_60_60, maxs + V_60_60_60) end
        end
        if Near(self, 1500) then Fire(self, CurTime()) end
    end

    -- (made once here, not every frame)
    local C_255_120_45_210 = Color(255, 120, 45, 210)
    local C_255_160_70 = Color(255, 160, 70)
    function ENT:DrawTranslucent()
        if not Near(self, 2000) then return end
        local burning = self:GetNW2Float("lc_burn_until", 0) > CurTime()
        local back, front, out = Ends(self)
        render.SetMaterial(GLOW)
        -- the burner, roaring out of the back
        local s = (burning and 110 or 70) + math.sin(CurTime() * 9) * 8
        render.DrawSprite(back + out * 6, s, s, burning and C_255_160_70 or C_255_120_45_210)
        -- and the glow of the furnace at the hatch (none standing on end: that end is on the floor)
        if self:GetNW2Bool("lc_upright", false) then return end
        local m = (burning and 44 or 22) + math.sin(CurTime() * 7) * 3
        render.DrawSprite(front, m, m, Color(255, 110, 40, burning and 200 or 110))
    end

    function ENT:Think()
        local now = CurTime()
        if not Near(self, 1500) then
            if self.lcRoar then self.lcRoar:Stop() self.lcRoar = nil end
        else
            Fire(self, now)
        end
        self:SetNextClientThink(now + 0.03)
        return true
    end

    function ENT:OnRemove()
        if self.lcRoar then self.lcRoar:Stop() self.lcRoar = nil end
        if self.lcEmitter and self.lcEmitter.Finish then self.lcEmitter:Finish() end
        self.lcEmitter = nil
    end
end
