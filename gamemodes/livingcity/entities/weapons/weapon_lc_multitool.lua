--[[
    Multitool (Living City): the Resistance's do-everything device, after Alyx's.
    Point it at something and left click:
      a locked Combine door     hack it open (twelve seconds; open for thirty)
      a city screen             wire in and hijack it (ten seconds)
      a Combine data terminal   download its data onto a chip (thirty seconds)
      a shackled vortigaunt     cut the shackles
    The HUD says what it will do before you click. The Resistance's Hackers
    (a Resistance special, Member and up) carry one; anyone can buy one from
    the black market dealer, at a price. It's contraband: searches take it.
]]

AddCSLuaFile()

SWEP.PrintName    = "Multitool"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "Combine locks, screens and terminals, opened the Resistance's way."
SWEP.Instructions = "Point at a Combine door, a city screen, a data terminal or a shackled vortigaunt, and left click."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 4
SWEP.SlotPos      = 2
SWEP.ViewModel    = ""
SWEP.WorldModel   = "models/props_lab/reciever01b.mdl"
SWEP.HoldType     = "slam"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local TERMINAL_HINTS = { "combine_interface", "breenconsole", "combine_intmonitor", "combine_smallmonitor", "masterinterface", "combine_intwallunit" }

-- What the tool would do with whatever you're pointing at (shared, for the HUD and the click).
local function Job(ply)
    local tr = ply:GetEyeTrace()
    if not tr or not tr.HitPos or tr.HitPos:DistToSqr(ply:EyePos()) > 120 * 120 then return nil end
    local e = tr.Entity
    if not IsValid(e) then return nil end
    local cls = e:GetClass()
    if cls == "lc_screen" then return "screen", "Hijack the city screen" end
    if cls == "lc_dataterminal" then return "data", "Download the Combine's data" end
    if cls == "lc_masterterminal" then return "data", "Download the master terminal (the motherlode)" end
    if cls == "lc_vending" and not e:GetNW2Bool("lc_nopower", false) then return "machine", "Hack the vending machine (free water)" end
    if cls == "lc_dispenser" and not e:GetNW2Bool("lc_nopower", false) then return "machine", "Hack the ration dispenser (rations, no coupon)" end
    if cls == "lc_transformer" and not e:GetNW2Bool("lc_down", false) then return "power", "Sabotage the transformer (the district goes dark)" end
    if cls == "lc_powerbank" and not e:GetNW2Bool("lc_nopower", false) and e:GetNW2Float("lc_short_until", 0) < CurTime() then
        return "bank", "Short out the power bank (its turrets and forcefields die with it)"
    end
    if cls == "lc_forcefield" and not e:GetNW2Bool("lc_nopower", false) and e:GetNW2Float("lc_short_until", 0) < CurTime() then
        return "field", "Short out the forcefield"
    end
    if cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating" or cls == "func_movelinear" then return "door", "Hack the Combine lock" end
    if e:IsPlayer() and e:GetNW2String("lcf_faction", "") == "vort" then return "vort", "Cut the vortigaunt's shackles" end
    if cls ~= "lc_console" and cls ~= "lc_terminal" and not string.StartWith(cls, "lc_") then
        local m = string.lower(e:GetModel() or "")
        for _, t in ipairs(TERMINAL_HINTS) do
            if string.find(m, t, 1, true) then
                return "data", t == "masterinterface" and "Download the master terminal (the motherlode)" or "Download the Combine's data"
            end
        end
    end
    return nil
end

function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:PreDrawViewModel() return true end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC then return end
    local job = Job(owner)
    local ok, why
    if job == "door" and LC.HackDoor then ok, why = LC.HackDoor(owner)
    elseif job == "screen" and LC.HijackScreen then ok, why = LC.HijackScreen(owner, owner:GetEyeTrace().Entity)
    elseif job == "data" and LC.StealData then ok, why = LC.StealData(owner)
    elseif job == "vort" and LC.StartUnshackle then ok, why = LC.StartUnshackle(owner)
    elseif job == "power" and LC.SabotageTransformer then ok, why = LC.SabotageTransformer(owner, owner:GetEyeTrace().Entity)
    elseif job == "field" and LC.ShortForcefield then ok, why = LC.ShortForcefield(owner, owner:GetEyeTrace().Entity)
    elseif job == "bank" and LC.ShortPowerBank then ok, why = LC.ShortPowerBank(owner, owner:GetEyeTrace().Entity)
    elseif job == "machine" and LC.HackMachine then ok, why = LC.HackMachine(owner, owner:GetEyeTrace().Entity)
    elseif not job and LC.DataTerminalAt and LC.DataTerminalAt(owner) and LC.StealData then ok, why = LC.StealData(owner) -- (a terminal built into the map)
    else why = "Nothing here the multitool can work on. (A Combine door, a city screen, a data terminal, a shackled vortigaunt, a transformer, a forcefield, a power bank, a vending machine, a ration dispenser.)" end
    if not ok and why then owner:ChatPrint(why) end
    if ok then owner:EmitSound("buttons/combine_button7.wav", 60) end
end

if CLIENT then
    function SWEP:DrawHUD()
        local _, label = Job(LocalPlayer())
        local x, y = ScrW() / 2, ScrH() / 2 + 40
        if label then
            draw.SimpleTextOutlined("LEFT CLICK: " .. string.upper(label), "DermaDefaultBold", x, y, Color(230, 150, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        else
            draw.SimpleTextOutlined("MULTITOOL: point at a Combine door, a city screen, a data terminal or a vending machine", "DermaDefault", x, y, Color(200, 190, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        end
    end
end
