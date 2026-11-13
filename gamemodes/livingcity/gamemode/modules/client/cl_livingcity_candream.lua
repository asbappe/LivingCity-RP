--[[
    Living City: Pick Up That Can, on your screen (sv_livingcity_candream.lua)

      Your own can (the owner: "every player has their own client side can prop"): nobody else sees
      it. The server says where it is (on the bin, knocked to the floor, in your hand, thrown, and
      where it lands); this draws it there. Once the can has swapped places with the officer, what you
      pick up is a tiny officer instead, squeaking threats and orders the whole time (LC_CL.CanTinyLines).
      And when anyone puts theirs in a bin, it rains cans on you. Once there is more than one scene,
      yours is lit up (a pulsing beam, circling lights, "YOURS").
]]

if SERVER then return end

LC_CL = LC_CL or {}

local CAN, COP = "models/props_junk/popcan01a.mdl", "models/police.mdl"
LC_CL.CanTiny = 0.22  -- (a tiny officer: as on the server)
LC_CL.CanRain = 24    -- (cans in a shower)
LC_CL.CanRainSecs = 3.5

-- What your tiny officer squeaks (the owner, 13 November: "super high pitch shifted voice lines coming from the tiny
-- officer: threats, commands, etc to make it more comical"): Half-Life 2's own officer, as high as it goes, from
-- wherever he is. By the moment: knocked off the bin, picked up, held (every few seconds), thrown, and where he ends up.
LC_CL.CanTinyPitch = 240
LC_CL.CanTinyEvery = { 2.5, 4.5 } -- (seconds between his lines while he's in your hand, or lying on the floor)
local VO = "npc/metropolice/vo/"
LC_CL.CanTinyLines = {
    floor = { "youknockeditover", "holdit", "holditrightthere", "dontmove", "stopthere", "firstwarningmove", "lookingfortrouble", "isaidmovealong", "pickupthecan2", "citizen" },
    held = { "secondwarning", "finalwarning", "thisisyoursecondwarning", "prepareforjudgement", "youwantamalcomplianceverdict", "getdown", "dontmove", "putitinthetrash1",
        "officerneedsassistance", "officerneedshelp", "backup", "help", "allunitsrespondcode3", "finalverdictadministered", "amputate", "pacifying" },
    pickup = { "watchit", "holdit", "help", "shit", "officerneedsassistance", "stopthere" },
    thrown = { "shit", "help", "lookout", "watchit", "officerneedshelp" },
    cop = { "finalverdictadministered", "chuckle", "pacifying" },         -- (he hit the one in charge)
    bin = { "allrightyoucango", "nowgetoutofhere", "movealong", "keepmoving" }, -- (from inside the bin)
    away = { "getdown", "isaidmovealong", "moveit", "backup" },
}
local known = {}
local function Have(path)
    if known[path] == nil then known[path] = not (file and file.Exists) or file.Exists("sound/" .. path, "GAME") == true end
    return known[path]
end
-- One of his lines for this moment, from where he is. The path played, or nil (none of them on this computer).
function LC_CL.CanSqueak(kind, pos)
    local list = LC_CL.CanTinyLines[kind]
    if not list or not pos then return nil end
    local at = math.random(#list)
    for i = 0, #list - 1 do
        local path = VO .. list[(at + i - 1) % #list + 1] .. ".wav"
        if Have(path) then
            if sound and sound.Play then sound.Play(path, pos, 75, math.Clamp(LC_CL.CanTinyPitch + math.random(-12, 12), 30, 255), 1) end
            return path
        end
    end
    return nil
end

local mine, mineKind
local was, nextLine, landed
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
    was, nextLine, landed = nil, nil, nil
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
    -- the tiny officer has plenty to say about all of this
    if c.k == "cop" then
        local key = c.s .. (c.a or 0)
        local at = pos or V(c.t) or eye
        if key ~= was then
            was, landed = key, nil
            local kind = ({ floor = "floor", held = "pickup", fly = "thrown" })[c.s]
            if kind then LC_CL.CanSqueak(kind, at) end
            nextLine = now + math.Rand(LC_CL.CanTinyEvery[1], LC_CL.CanTinyEvery[2])
        elseif c.s == "fly" and not landed and now - (c.a or now) > 0.9 then
            landed = true
            LC_CL.CanSqueak(c.w or "away", at)
        elseif (c.s == "held" or c.s == "floor") and now >= (nextLine or 0) then
            nextLine = now + math.Rand(LC_CL.CanTinyEvery[1], LC_CL.CanTinyEvery[2])
            LC_CL.CanSqueak(c.s, at)
        end
    else
        was = nil
    end
    if pos then
        m:SetPos(pos)
        m:SetAngles(a or Angle(0, 0, 0))
    end
end)

-- Which scene is yours (the owner: "how do they know which little scene is theirs? Maybe it should pulse or glow or do a
-- few things"): a beam of light into the sky, a glow that pulses, lights circling its feet, and "YOURS" over it.
LC_CL.CanMineColour = Color(255, 225, 90)
local glowMat = Material and Material("sprites/light_glow02_add") or nil
local beamMat = Material and Material("sprites/physbeama") or nil
function LC_CL.CanMine()
    local st = St()
    local m = st and not st.out and st.mine
    if not m then return nil end
    return Vector(m[1], m[2], m[3]), m[4] == 1
end
hook.Add("PostDrawTranslucentRenderables", "LivingCityCanDream", function(_, sky)
    if sky then return end
    local at = LC_CL.CanMine()
    if not at or not render then return end
    local now = CurTime()
    local pulse = 0.5 + 0.5 * math.sin(now * 4)
    local col = LC_CL.CanMineColour
    if beamMat and render.SetMaterial and render.DrawBeam then
        render.SetMaterial(beamMat)
        render.DrawBeam(at + Vector(0, 0, 4), at + Vector(0, 0, 1400), 14 + pulse * 18, now * 0.5, now * 0.5 + 6, Color(col.r, col.g, col.b, 160))
    end
    if glowMat and render.SetMaterial and render.DrawSprite then
        render.SetMaterial(glowMat)
        local s = 150 + pulse * 110
        render.DrawSprite(at + Vector(0, 0, 40), s, s, Color(col.r, col.g, col.b, 150))
        for i = 1, 8 do -- (lights going round its feet)
            local a = now * 1.6 + i / 8 * math.pi * 2
            render.DrawSprite(at + Vector(math.cos(a) * 80, math.sin(a) * 80, 6 + math.sin(now * 3 + i) * 4), 26, 26, col)
        end
    end
end)
hook.Add("HUDPaint", "LivingCityCanDream", function()
    local at, own = LC_CL.CanMine()
    if not at then return end
    local top = at + Vector(0, 0, 125 + math.sin(CurTime() * 3) * 6)
    local sc = top.ToScreen and top:ToScreen()
    if not sc or sc.visible == false then return end
    local col = LC_CL.CanMineColour
    local a = math.floor(170 + 85 * math.sin(CurTime() * 4))
    draw.SimpleTextOutlined(own and "YOURS" or "YOUR BIN", "DermaLarge", sc.x, sc.y, Color(col.r, col.g, col.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, a))
end)
