--[[
    Poster roll (Living City): the Director of Propaganda's. Left click hangs
    the chosen poster on the wall in front of you; right click takes any
    poster down (the editor's own come back when the map next starts); reload opens the roll to choose another. The
    city's walls only get these posters when someone holding a roll puts them
    up (LC.HangPoster, sv_livingcity_learning.lua; the posters themselves:
    entities/lc_civposter.lua). Anyone holding it can use it.
]]

AddCSLuaFile()

SWEP.PrintName    = "Poster roll"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "The city's walls."
SWEP.Instructions = "Left click: hang the poster on the wall in front of you. Right click: take a poster down. Reload: choose another poster."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 4
SWEP.SlotPos      = 4
SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_c17/paper01.mdl"
SWEP.UseHands     = false
SWEP.HoldType     = "slam"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local MODEL = "models/props_c17/paper01.mdl"
local REACH = 110

local function Notices()
    local stored = scripted_ents and scripted_ents.GetStored and scripted_ents.GetStored("lc_civposter")
    local t = stored and stored.t or {}
    return t.Notices or {}, t.NoticeOrder or {}
end

function SWEP:Initialize() self:SetHoldType(self.HoldType) end

function SWEP:Chosen()
    local notices, order = Notices()
    local k = self:GetNW2String("lc_poster", "")
    if notices[k] then return k end
    return order[1] or "curfew"
end

local function Tell(ply, title, text)
    if LC and LC.Notice then LC.Notice(ply, "info", title, text) elseif ply.ChatPrint then ply:ChatPrint(text) end
end

local function Look(owner)
    return util.TraceLine({ start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * REACH, filter = owner })
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.HangPoster then return end
    local tr = Look(owner)
    if not tr.Hit or tr.HitSky or (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then Tell(owner, "Poster roll", "Stand at a wall and look at it.") return end
    local kind = self:Chosen()
    local e, why = LC.HangPoster(owner, kind, tr.HitPos, tr.HitNormal)
    if not e then Tell(owner, "Poster roll", why or "It won't stick.") return end
    owner:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 60, 110)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.TakeDownPoster then return end
    local ok, why = LC.TakeDownPoster(owner, Look(owner).Entity)
    if not ok then Tell(owner, "Poster roll", why) return end
    owner:EmitSound("physics/cardboard/cardboard_box_impact_soft4.wav", 60, 120)
end

if SERVER then
    util.AddNetworkString("lc_poster_pick")
    net.Receive("lc_poster_pick", function(_, ply)
        local kind = net.ReadString()
        local w = IsValid(ply) and ply:GetActiveWeapon()
        if not IsValid(w) or w:GetClass() ~= "weapon_lc_posters" then return end
        local notices = Notices()
        if notices[kind] then w:SetNW2String("lc_poster", kind) end
    end)
    function SWEP:Reload() end
end

if CLIENT then
    local cvView = CreateClientConVar("lc_posters_view", "20 0 -9", true, false, "Where your poster sits in your view: forward right up")
    local C_PAPER = Color(225, 218, 200)
    local C_BLACK = Color(0, 0, 0)

    -- the roll: every poster, to choose from
    function SWEP:Reload()
        if (self.lcMenuAt or 0) > CurTime() then return end
        self.lcMenuAt = CurTime() + 1
        if not DermaMenu then return end
        local notices, order = Notices()
        local menu = DermaMenu()
        for _, kind in ipairs(order) do
            local n = notices[kind]
            if n then
                menu:AddOption(n[1], function()
                    net.Start("lc_poster_pick") net.WriteString(kind) net.SendToServer()
                end)
            end
        end
        menu:Open()
        menu:Center()
    end

    local function Prop(self)
        if not IsValid(self.lcProp) and ClientsideModel then
            self.lcProp = ClientsideModel(MODEL, RENDERGROUP_OPAQUE)
            if IsValid(self.lcProp) then self.lcProp:SetNoDraw(true) end
        end
        return self.lcProp
    end

    -- your hands, holding the sheet up in front of you
    function SWEP:PostDrawViewModel()
        local p = Prop(self)
        if not IsValid(p) then return end
        local parts = {}
        for n in string.gmatch(cvView:GetString(), "%-?[%d%.]+") do parts[#parts + 1] = tonumber(n) end
        local f, r, u = parts[1] or 20, parts[2] or 0, parts[3] or -9
        local ang = EyeAngles()
        p:SetPos(EyePos() + ang:Forward() * f + ang:Right() * r + ang:Up() * u)
        local a = Angle(ang.p, ang.y, ang.r)
        a:RotateAroundAxis(a:Right(), -55) -- (tilted up toward you, as you'd hold a sheet to read it)
        p:SetAngles(a)
        p:DrawModel()
    end

    function SWEP:DrawWorldModel()
        local p = Prop(self)
        if not IsValid(p) then return end
        local owner = self:GetOwner()
        local bone = IsValid(owner) and owner.LookupBone and owner:LookupBone("ValveBiped.Bip01_R_Hand")
        local m = bone and owner:GetBoneMatrix(bone)
        if m then
            local pos, ang = m:GetTranslation(), m:GetAngles()
            p:SetPos(pos + ang:Forward() * 4 + ang:Right() * 2)
            p:SetAngles(ang)
        else
            p:SetPos(self:GetPos()) p:SetAngles(self:GetAngles())
        end
        p:DrawModel()
    end

    function SWEP:OnRemove() if IsValid(self.lcProp) then self.lcProp:Remove() end end

    function SWEP:DrawHUD()
        local notices = Notices()
        local n = notices[self:Chosen()]
        local x, y = ScrW() / 2, ScrH() * 0.8
        draw.SimpleTextOutlined("Poster: " .. (n and n[1] or "?"), "DermaDefaultBold", x, y, C_PAPER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_BLACK)
        draw.SimpleTextOutlined("Left click: hang it on the wall.  Right click: take one down.  Reload: choose another.", "DermaDefault", x, y + 18, C_PAPER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_BLACK)
    end
end
