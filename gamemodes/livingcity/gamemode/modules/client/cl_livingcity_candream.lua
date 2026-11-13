--[[
    Living City: Pick Up That Can, on your screen (sv_livingcity_candream.lua)

      Your own can (the owner: "every player has their own client side can prop"): nobody else sees
      it. The server says where it is (on the bin, knocked to the floor, in your hand, thrown, and
      where it lands); this draws it there. Once the can has swapped places with the officer, what you
      pick up is a tiny officer instead. And when anyone puts theirs in a bin, it rains cans on you.
]]

if SERVER then return end

LC_CL = LC_CL or {}

local CAN, COP = "models/props_junk/popcan01a.mdl", "models/police.mdl"
LC_CL.CanTiny = 0.22  -- (a tiny officer: as on the server)
LC_CL.CanRain = 24    -- (cans in a shower)
LC_CL.CanRainSecs = 3.5

local mine, mineKind
local rain, rainAt = {}, nil

local function St()
    local st = LC_CL.DreamGame and LC_CL.DreamGame() or nil
    return st and st.theme == "can" and st or nil
end
local function V(t) return t and Vector(t[1], t[2], t[3]) or nil end
local function Lerp3(a, b, k, arc)
    return Vector(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k, a.z + (b.z - a.z) * k + math.sin(k * math.pi) * (arc or 0))
end

local function Clear()
    if IsValid(mine) then mine:Remove() end
    mine, mineKind = nil, nil
    for _, r in ipairs(rain) do if IsValid(r.m) then r.m:Remove() end end
    rain, rainAt = {}, nil
end
LC_CL.CanDreamClear = Clear

local function Mine(kind)
    if IsValid(mine) and mineKind == kind then return mine end
    if IsValid(mine) then mine:Remove() end
    mine, mineKind = nil, kind
    if not ClientsideModel then return nil end
    mine = ClientsideModel(kind == "cop" and COP or CAN, RENDERGROUP_OPAQUE)
    if IsValid(mine) and mine.SetModelScale then mine:SetModelScale(kind == "cop" and LC_CL.CanTiny or 1.6, 0) end
    return IsValid(mine) and mine or nil
end

-- Where your can is right now, and how it's turned. Nil: nowhere to be seen.
function LC_CL.CanWhere(c, now, eye, ang)
    if not c or not c.s then return nil end
    local t = now - (c.a or now)
    local bin, floor, to = V(c.b), V(c.p), V(c.t)
    if c.s == "bin" then
        return bin, Angle(0, 0, 0)
    elseif c.s == "floor" then
        if not floor then return nil end
        if bin and t < 0.5 then return Lerp3(bin, floor, t / 0.5, 22), Angle(t * 900, 0, t * 500) end
        return floor, Angle(c.k == "cop" and -90 or 0, 40, c.k == "cop" and 0 or 90)
    elseif c.s == "held" then
        if not eye or not ang then return nil end
        local at = eye + ang:Forward() * 26 + ang:Right() * 9 - ang:Up() * 8
        return at, Angle(0, ang.y + 180, 0)
    elseif c.s == "fly" then
        if not to then return nil end
        local from = eye and (eye + (ang and ang:Forward() * 26 or Vector(0, 0, 0))) or to
        c.from = c.from or from -- (from where it left your hand)
        local secs = c.w == "away" and 0.8 or 0.45
        if t < secs then return Lerp3(c.from, to, t / secs, c.w == "away" and 50 or 12), Angle(t * 1100, t * 300, 0) end
        if c.w == "away" and t < 1.6 then return to, Angle(0, 0, 90) end
        return nil -- (in the bin, bounced off him, or grown into a tree)
    end
    return nil
end

local function Rain(st, now)
    if st.rain and st.rain ~= rainAt then
        rainAt = st.rain
        local me = LocalPlayer()
        if ClientsideModel and IsValid(me) then
            local at = me:GetPos()
            for i = 1, LC_CL.CanRain do
                local r = rain[i]
                if not (r and IsValid(r.m)) then
                    r = { m = ClientsideModel(CAN, RENDERGROUP_OPAQUE) }
                    if IsValid(r.m) and r.m.SetModelScale then r.m:SetModelScale(math.Rand(1.5, 4), 0) end
                    rain[i] = r
                end
                r.x, r.y = at.x + math.Rand(-320, 320), at.y + math.Rand(-320, 320)
                r.z0, r.z1, r.t0, r.spin = at.z + math.Rand(380, 700), at.z + 2, now + math.Rand(0, 1.2), math.Rand(200, 900)
            end
        end
    end
    for _, r in ipairs(rain) do
        if IsValid(r.m) then
            local k = (now - (r.t0 or now)) / 1.6
            local show = rainAt ~= nil and k >= 0 and now - rainAt < LC_CL.CanRainSecs + 1.5
            if r.m.SetNoDraw then r.m:SetNoDraw(not show) end
            if show then
                k = math.min(1, k)
                r.m:SetPos(Vector(r.x, r.y, r.z0 + (r.z1 - r.z0) * k * k))
                r.m:SetAngles(Angle(now * r.spin % 360, now * 70 % 360, k >= 1 and 90 or 0))
            end
        end
    end
end

hook.Add("Think", "LivingCityCanDream", function()
    local st = St()
    if not st then
        if mine or #rain > 0 then Clear() end
        return
    end
    local now = CurTime()
    Rain(st, now)
    local c = st.can
    local me = LocalPlayer()
    if not c or st.out or not IsValid(me) then
        if IsValid(mine) and mine.SetNoDraw then mine:SetNoDraw(true) end
        return
    end
    local eye = me.EyePos and me:EyePos() or EyePos()
    local ang = me.EyeAngles and me:EyeAngles() or EyeAngles()
    local pos, a = LC_CL.CanWhere(c, now, eye, ang)
    local m = Mine(c.k == "cop" and "cop" or "can")
    if not m then return end
    if m.SetNoDraw then m:SetNoDraw(pos == nil) end
    if pos then
        m:SetPos(pos)
        m:SetAngles(a or Angle(0, 0, 0))
    end
end)
