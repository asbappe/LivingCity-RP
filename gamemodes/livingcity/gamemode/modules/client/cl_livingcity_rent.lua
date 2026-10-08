--[[
    Living City: apartment doors (client)

    Look at an apartment door and it says who holds it, or that it is free.
    Right click with your hands (weapon_lc_hands) to rent a free one: a yes or
    no pops up. Once it is yours, right click locks and unlocks it.
    The server does the renting (sv_livingcity_business.lua).
]]

if SERVER then return end

LC_CL = LC_CL or {}

local SEE = 170 -- how close you have to be

local function Parse(v)
    if not v or v == "" then return nil end
    local kind, a, b = string.match(v, "^(%a):([^:]*):?(.*)$")
    if kind == "A" then return { free = true, price = tonumber(a) or 0, hours = tonumber(b) or 0 } end
    if kind == "O" then return { free = false, name = string.sub(v, 3) } end
    return nil
end
LC_CL.ParseRent = Parse

-- The lines to show for a door entity (nil: not an apartment door).
function LC_CL.RentLines(door, me)
    if not IsValid(door) then return nil end
    local info = Parse(door:GetNW2String("lc_rent", ""))
    if not info then return nil end
    local holding = IsValid(me) and IsValid(me:GetActiveWeapon()) and me:GetActiveWeapon():GetClass() == "weapon_lc_hands"
    if info.free then
        local h = info.hours == math.floor(info.hours) and tostring(math.floor(info.hours)) or tostring(info.hours)
        return "Apartment: available", string.format("%d credits for %s hours", info.price, h),
            holding and "Right click to rent it" or "Put your hands out (nothing in them) and right click to rent it"
    end
    local key = door:GetNW2String("lc_rentkey", "")
    local mine = IsValid(me) and key ~= "" and (key == me:GetNW2String("lc_cid", "") or key == "sid:" .. me:SteamID())
    if mine then
        local locked = door:GetNW2Bool("lc_rentlocked", false)
        return "Your apartment (" .. (locked and "locked" or "unlocked") .. ")", nil,
            holding and ("Right click to " .. (locked and "unlock" or "lock") .. " it") or "Put your hands out and right click to lock or unlock it"
    end
    return "Apartment: " .. info.name .. "'s", nil, nil
end

local fontsMade = false
local function Fonts()
    if fontsMade or not surface.CreateFont then return end
    fontsMade = true
    surface.CreateFont("LCRentMain", { font = "Tahoma", size = 22, weight = 800, extended = true })
    surface.CreateFont("LCRentSub", { font = "Tahoma", size = 17, weight = 600, extended = true })
end

hook.Add("HUDPaint", "LivingCityRentLabel", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local tr = me:GetEyeTrace()
    local e = tr and tr.Entity
    if not IsValid(e) or e:GetPos():DistToSqr(me:GetPos()) > SEE * SEE then return end
    local a, b, c = LC_CL.RentLines(e, me)
    if not a then return end
    Fonts()
    local x, y = ScrW() / 2, ScrH() / 2 + 46
    local free = Parse(e:GetNW2String("lc_rent", "")).free
    local col = free and Color(130, 230, 150) or Color(235, 235, 240)
    draw.SimpleTextOutlined(a, "LCRentMain", x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220))
    if b then y = y + 26 draw.SimpleTextOutlined(b, "LCRentSub", x, y, Color(235, 235, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220)) end
    if c then y = y + 22 draw.SimpleTextOutlined(c, "LCRentSub", x, y, Color(190, 200, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220)) end
end)

local asking = false
net.Receive("lc_rent_ask", function()
    local door, price, hours = net.ReadEntity(), net.ReadUInt(16), net.ReadFloat()
    if asking or not IsValid(door) then return end
    local function yes()
        asking = false
        net.Start("lc_rent_confirm")
        net.WriteEntity(door)
        net.SendToServer()
    end
    local h = hours == math.floor(hours) and tostring(math.floor(hours)) or tostring(hours)
    local text = string.format("Rent this apartment for %d credits? It is yours for %s hours, locked to everyone but you and whoever you give a key.", price, h)
    LC_CL.RentAskLast = { door = door, price = price, hours = hours, yes = yes }
    if Derma_Query then
        asking = true
        Derma_Query(text, "Rent apartment", "Yes, rent it", yes, "No", function() asking = false end)
    end
end)
