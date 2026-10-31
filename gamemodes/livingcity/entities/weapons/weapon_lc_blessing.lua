--[[
    The Blessing (Living City, Father Grigori)

    Primary:   lay hands on the person in front of you (heals 20)
    Secondary: a prayer for everyone near you (heals 10 to each, 30 second rest)
    Reload:    preach. Citizens nearby stop and listen. Civil Protection
               within earshot does not take kindly to it.

    The infected are beyond his help.
]]

AddCSLuaFile()

SWEP.PrintName    = "The Blessing"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Instructions = "Primary: heal one. Secondary: prayer for all nearby. Reload: preach."
SWEP.Spawnable    = true
SWEP.AdminOnly    = false

SWEP.Slot         = 0
SWEP.SlotPos      = 6
SWEP.ViewModel    = ""
SWEP.WorldModel   = ""
SWEP.HoldType     = "normal"
SWEP.DrawAmmo     = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local HEAL_SOUND = "items/medshot4.wav"
local PRAYER_SOUND = "items/smallmedkit1.wav"

local PREACH = {}
for i = 1, 22 do PREACH[#PREACH + 1] = string.format("vo/ravenholm/monk_rant%02d.wav", i) end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:DrawWorldModel() end

local function Healable(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then
        return ent:Alive() and not (LC and LC.PlayerIsZombie and LC.PlayerIsZombie(ent))
    end
    if ent:IsNPC() then
        local cls = ent:GetClass()
        return cls == "npc_citizen" or cls == "npc_alyx" or cls == "npc_barney" or cls == "npc_monk"
            or cls == "npc_vortigaunt" or cls == "npc_metropolice" or cls == "npc_combine_s"
    end
    return false
end

local function Heal(healer, ent, amount)
    local before = ent:Health()
    local max = ent:GetMaxHealth() > 0 and ent:GetMaxHealth() or 100
    ent:SetHealth(math.min(max, before + amount))
    local gained = ent:Health() - before
    if gained > 0 and ent ~= healer then hook.Run("LivingCityHealed", healer, ent, gained) end
    if gained > 0 and LC and LC.AddXP and ent ~= healer then
        healer.lcHealPool = (healer.lcHealPool or 0) + gained
        while healer.lcHealPool >= 25 do
            healer.lcHealPool = healer.lcHealPool - 25
            LC.AddXP(healer, LCF and LCF.XP.heal_per_25hp or 1, "tending the wounded")
        end
    end
    return gained
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 4)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
        filter = owner,
    })
    local ent = tr.Entity
    if not Healable(ent) then
        if IsValid(ent) and ent:IsPlayer() then owner:ChatPrint("[Blessing] The infected are beyond your help.") end
        self:SetNextPrimaryFire(CurTime() + 0.5)
        return
    end
    if Heal(owner, ent, 20) > 0 then
        ent:EmitSound(HEAL_SOUND, 70)
        if ent:IsPlayer() then ent:ChatPrint("[Blessing] Father Grigori lays a hand on your head and blesses you; You feel stronger.") end
    else
        self:SetNextPrimaryFire(CurTime() + 0.5)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 30)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    owner:EmitSound(PRAYER_SOUND, 75)
    local healed = 0
    for _, ent in ipairs(ents.FindInSphere(owner:GetPos(), 300)) do
        if Healable(ent) and Heal(owner, ent, 10) > 0 then healed = healed + 1 end
    end
    owner:ChatPrint(healed > 0 and ("[Blessing] Your prayer comforts " .. healed .. " soul(s).") or "[Blessing] You pray alone.")
end

function SWEP:Reload()
    if CLIENT then return end
    if (self.nextPreach or 0) > CurTime() then return end
    self.nextPreach = CurTime() + 15
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    owner:EmitSound(PREACH[math.random(#PREACH)], 85)
    hook.Run("LivingCityPreached", owner)

    if not LC or not LC.NPCs then return end
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) then
            local d2 = npc:GetPos():DistToSqr(owner:GetPos())
            if st.role == "citizen" and d2 < 400 * 400 and (st.state == "idle" or st.state == "moving") then
                -- they stop and listen for a moment
                npc:SetSchedule(SCHED_IDLE_STAND)
                LC.Face(npc, owner:GetPos())
                LC.SetState(npc, st, "event")
                st.eventUntil = CurTime() + math.Rand(5, 9)
            elseif LC.IsSecurity(st) and d2 < 900 * 900 and st.state ~= "hostile" then
                LC.ReportCrime(owner, "Unlawful preaching", 300)
                LC.MakeCopsHostile(owner, owner:GetPos(), 900)
                break
            end
        end
    end
end
