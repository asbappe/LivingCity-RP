--[[ A crate nobody admits to leaving (Living City): the G-Man forcing the Administrator's hand
     (sv_livingcity_directives.lua). Press E: an SMG or a shotgun with ammunition, and a powered
     vest with the cells to charge it full. One each, a few loads, then it's empty. ]]
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Unmarked crate"
ENT.Author = "Miscount"
ENT.Spawnable = false

local LOADS = 4

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/items/ammocrate_smg1.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self.lcLoads, self.lcTaken = LOADS, {}
    self:SetNW2Int("lc_loads", LOADS)
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if (self.lcNext or 0) > CurTime() then return end
        self.lcNext = CurTime() + 0.8
        if self.lcTaken[activator:SteamID()] then activator:ChatPrint("[???] You've had yours.") return end
        if (self.lcLoads or 0) <= 0 then activator:ChatPrint("[???] Empty.") return end
        self.lcTaken[activator:SteamID()] = true
        self.lcLoads = self.lcLoads - 1
        self:SetNW2Int("lc_loads", self.lcLoads)
        local gun = math.random() < 0.5 and "weapon_smg1" or "weapon_shotgun"
        activator:Give(gun)
        activator:GiveAmmo(gun == "weapon_smg1" and 135 or 24, gun == "weapon_smg1" and "SMG1" or "Buckshot")
        if LC and LC.GiveItem then
            pcall(LC.GiveItem, activator, "armor_vest", 1)
            pcall(LC.GiveItem, activator, "vest_cell", 2) -- (thirty in the vest, and fifty: full)
        end
        self:EmitSound("items/ammocrate_open.wav", 70)
        activator:ChatPrint("[???] " .. (gun == "weapon_smg1" and "An SMG" or "A shotgun") .. ", ammunition, a powered vest and the cells to charge it. Nobody's watching. Yet.")
        if self.lcLoads <= 0 then timer.Simple(2, function() if IsValid(self) then self:Remove() end end) end
    end
end

if CLIENT then
    function ENT:Draw() self:DrawModel() end
end
