--[[
    Job board (Living City). Place it with the editor ("Fixture: job board"). Whose board it is follows
    where it stands: on rebel ground the Resistance's Operations, on Combine ground Civil Protection's
    Directives, anywhere else the Union's Assignments. Its glass lists what's up on that board; E on it
    opens your Jobs (F4) if it's your side's, and says whose it is if not. (Jobs are still on F4 wherever
    you are: a board in the world is one more way in, not the only one.) sv_livingcity_jobboards.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Job board"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_phx/rt_screen.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseJobBoard then LC.UseJobBoard(activator, self) end
    end
end

if CLIENT then
    local function Place(self)
        local mins, maxs = self:GetModelBounds()
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        local scale = math.min(wide * 0.86 / 640, tall * 0.84 / 360)
        return self:LocalToWorld(Vector(maxs.x + 0.6, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2)), scale
    end
    local function BlankGlass(self)
        self.lcBlanked = true
        for i, m in ipairs(self:GetMaterials() or {}) do
            local l = string.lower(m)
            if string.find(l, "rt", 1, true) or string.find(l, "screen", 1, true) or string.find(l, "camera", 1, true) then
                self:SetSubMaterial(i - 1, "tools/toolsblack")
            end
        end
    end
    local HEAD = { resistance = Color(230, 120, 90), cp = Color(120, 170, 255), citizen = Color(230, 200, 120) }
    local INK, DIM = Color(230, 230, 225), Color(150, 150, 145)
    function ENT:Draw()
        if not self.lcBlanked then BlankGlass(self) end
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 700 * 700 then return end
        local pos, scale = Place(self)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        local side = self:GetNW2String("lc_board_side", "citizen")
        cam.Start3D2D(pos, ang, scale)
            draw.SimpleText(string.upper(self:GetNW2String("lc_board_name", "Assignments")), "DermaLarge", -300, -160, HEAD[side] or INK)
            local y = -110
            local any = false
            for line in string.gmatch(self:GetNW2String("lc_board_list", ""), "[^\n]+") do
                draw.SimpleText("- " .. line, "DermaDefaultBold", -300, y, INK)
                y = y + 30
                any = true
            end
            if not any then draw.SimpleText("Nothing posted right now.", "DermaDefaultBold", -300, y, DIM) end
            draw.SimpleText("Press E (or F4) for your jobs", "DermaDefault", -300, 150, DIM)
        cam.End3D2D()
    end
end
