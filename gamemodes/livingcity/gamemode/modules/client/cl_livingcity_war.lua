--[[
    Living City (client): the state of the city

      - a line on screen as you cross into (or out of) rebel territory or the
        infestation
      - unit 10-20 markers: where a unit called from, and how far you are
      - the control bar (Combine / Resistance / infested) for the F4 screen
]]

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

LC_CL = LC_CL or {}
LC_CL.territory = LC_CL.territory or {}
LC_CL.marks = LC_CL.marks or {}

local REBEL_COL, INFEST_COL, COMBINE_COL = Color(225, 150, 60), Color(125, 175, 60), Color(80, 140, 255)
local ENTER = {
    rebel = { "REBEL TERRITORY", "The Combine doesn't patrol here. Civil Protection units get shot at.", REBEL_COL },
    infest = { "QUARANTINE ZONE", "Infested ground. Nobody comes back the same.", INFEST_COL },
}

-- (inside a Combine-only zone, rebel ground stacked over or under it doesn't count: the owner, 7 November)
local function KindAt(pos)
    local found, combine
    for _, z in ipairs(LC_CL.territory or {}) do
        if LCZ.Contains(z, pos, 0) then
            if z.kind == "infest" then return "infest" end
            if z.kind == "combine" then combine = true elseif z.kind == "rebel" then found = "rebel" end
        end
    end
    if combine then return nil end
    return found
end
LC_CL.TerritoryAt = KindAt
function LC_CL.InCombineZone(pos)
    for _, z in ipairs(LC_CL.territory or {}) do
        if z.kind == "combine" and LCZ.Contains(z, pos, 0) then return true end
    end
    return false
end

local current, nextCheck = nil, 0
local shown -- { title, sub, col, untilT, startT }

net.Receive("lc_cpmark", function()
    local t = ReadCompressed()
    if not t then return end
    LC_CL.marks[t.name or "?"] = { pos = Vector(t.x, t.y, t.z), untilT = CurTime() + (t.secs or 90) }
    surface.PlaySound("npc/overwatch/radiovoice/on1.wav")
end)

hook.Add("HUDPaint", "LivingCityWarHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local now = CurTime()

    if now > nextCheck then
        nextCheck = now + 0.5
        local k = ply:Alive() and KindAt(ply:GetPos()) or nil
        if k ~= current then
            if k then
                local e = ENTER[k]
                shown = { title = e[1], sub = e[2], col = e[3], untilT = now + 5, startT = now }
            elseif current then
                shown = { title = current == "rebel" and "LEAVING REBEL TERRITORY" or "LEAVING THE QUARANTINE ZONE",
                    sub = "", col = Color(200, 200, 200), untilT = now + 3, startT = now }
            end
            current = k
        end
    end

    if shown and now < shown.untilT then
        local a = math.Clamp(math.min(now - shown.startT, shown.untilT - now) * 2, 0, 1)
        local x, y = ScrW() / 2, ScrH() * 0.24
        local c = shown.col
        draw.SimpleTextOutlined(shown.title, "DermaLarge", x, y, Color(c.r, c.g, c.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200 * a))
        if shown.sub ~= "" then
            draw.SimpleTextOutlined(shown.sub, "DermaDefault", x, y + 24, Color(225, 225, 225, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200 * a))
        end
    end

    -- 10-20s from other units
    for name, m in pairs(LC_CL.marks) do
        if now > m.untilT then
            LC_CL.marks[name] = nil
        else
            local sp = (m.pos + Vector(0, 0, 60)):ToScreen()
            local dist = math.floor(ply:GetPos():Distance(m.pos) * 0.019)
            if sp.visible then
                draw.SimpleTextOutlined("10-20: " .. name, "DermaDefaultBold", sp.x, sp.y, COMBINE_COL, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
                draw.SimpleTextOutlined(dist .. " m  (" .. math.ceil(m.untilT - now) .. "s)", "DermaDefault", sp.x, sp.y + 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            end
        end
    end
end)

local STATE = {
    unrest = { "CIVIL UNREST", "More inspections and raids, ration cuts. Black market cheaper.", REBEL_COL },
    order = { "FULL COMPLIANCE", "The rebels are quiet. Black market prices are up.", COMBINE_COL },
    normal = { "CONTESTED", "Nobody holds the upper hand.", Color(200, 200, 200) },
}

-- Who holds the city, as a bar: for the F4 screen (and anywhere else).
function LC_CL.DrawControlBar(x, y, w, h)
    local rebel = GetGlobal2Float("lc_ctl_rebel", 0)
    local infest = GetGlobal2Float("lc_ctl_infest", 0)
    local combine = math.max(0, 1 - rebel - infest)
    local st = STATE[GetGlobal2String("lc_city_state", "normal")] or STATE.normal
    draw.RoundedBox(6, x, y, w, h, Color(24, 26, 32, 235))
    draw.SimpleText("WHO HOLDS THE CITY", "DermaDefaultBold", x + 10, y + 10, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(st[1], "DermaDefaultBold", x + w - 10, y + 10, st[3], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    local bx, by, bw, bh = x + 10, y + 20, w - 20, 14
    local cw, rw = math.floor(bw * combine), math.floor(bw * rebel)
    draw.RoundedBox(2, bx, by, bw, bh, INFEST_COL)
    draw.RoundedBox(2, bx, by, cw, bh, COMBINE_COL)
    draw.RoundedBox(0, bx + cw, by, rw, bh, REBEL_COL)
    draw.SimpleText(string.format("Combine %d%%   Resistance %d%%   Infested %d%%   |   %s", math.floor(combine * 100 + 0.5),
        math.floor(rebel * 100 + 0.5), math.floor(infest * 100 + 0.5), st[2]), "DefaultSmall", x + 10, y + h - 10, Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

------------------------------------------------------------------------
-- Graffiti on the walls, and labels on rebel pots and supply crates
--
-- The lambda is Half-Life 2's own: its maps have the Resistance's lambda in
-- a circle as spray decals, so those are what gets painted. A decal sits on
-- the wall, takes its light, and looks like it belongs there. If an install
-- somehow lacks them, a drawn lambda stands in.
--   lc_tag_scale   how big they come out (1 is the game's own size)
------------------------------------------------------------------------

LC_CL.tags = LC_CL.tags or {}
local cvTagScale = CreateClientConVar("lc_tag_scale", "1", true, false, "Size of the Resistance's lambda sprays on walls (1 is the game's own size)")
local WHITE = Color(255, 255, 255, 255)

-- The spray decals this install has (looked for once). The game's are
-- lambdaspray_1a, 1b, 2a... : try each name, keep the ones that exist.
local lambdaMats
local function LambdaMats()
    if lambdaMats then return lambdaMats end
    lambdaMats = {}
    local names = { "decals/lambda", "decals/lambdaspray" }
    for n = 1, 9 do
        names[#names + 1] = "decals/lambdaspray_" .. n
        for _, suffix in ipairs({ "a", "b", "c", "d", "e", "f" }) do names[#names + 1] = "decals/lambdaspray_" .. n .. suffix end
    end
    for _, name in ipairs(names) do
        local m = Material(name)
        if m and not m:IsError() then lambdaMats[#lambdaMats + 1] = m end
    end
    if #lambdaMats == 0 then print("[Living City] This install has no lambda spray decals; graffiti is drawn instead.") end
    return lambdaMats
end
LC_CL.LambdaMats = LambdaMats

local painted = {} -- [key] = { at = when it was painted, scale = how big }
local function TagKey(t)
    return string.format("%d_%d_%d", math.floor(t.pos.x + 0.5), math.floor(t.pos.y + 0.5), math.floor(t.pos.z + 0.5))
end

local function ClearTagDecal(t)
    if util.RemoveDecalsAt then util.RemoveDecalsAt(t.pos, 24) end
end

-- One tag, on its wall. Which of the game's sprays it is comes from where it is,
-- so everyone sees the same one.
local function PaintTag(t, mats, scale)
    local pick = (math.abs(math.floor(t.pos.x * 3 + t.pos.y * 5 + t.pos.z * 7)) % #mats) + 1
    local wall = t.pos - t.normal * 0.5 -- (the server puts it half a unit off the wall)
    util.DecalEx(mats[pick], game.GetWorld(), wall, t.normal, WHITE, scale, scale)
    painted[TagKey(t)] = { at = CurTime(), scale = scale }
end

-- The list the server sent: the whole of it, each time. What's gone (scrubbed
-- off, faded) comes off the wall; what's new is painted by the timer below.
function LC_CL.SetTags(list)
    local fresh, keep = {}, {}
    for _, g in ipairs(list or {}) do
        local t = { pos = Vector(g.x, g.y, g.z), normal = Vector(g.nx, g.ny, g.nz) }
        fresh[#fresh + 1] = t
        keep[TagKey(t)] = true
    end
    for _, old in ipairs(LC_CL.tags or {}) do
        local key = TagKey(old)
        if not keep[key] then
            ClearTagDecal(old)
            painted[key] = nil
        end
    end
    LC_CL.tags = fresh
end

net.Receive("lc_tags", function()
    local t = ReadCompressed() or {}
    LC_CL.SetTags(t.tags)
end)

-- Paint what isn't up yet; and put back, from time to time, what's near and may
-- have gone (the game drops its oldest decals once there are too many, and a
-- player can clear them all). Painting again takes the old one off first.
timer.Create("LivingCityTagDecals", 1, 0, function()
    local mats = LambdaMats()
    if #mats == 0 or not util.DecalEx then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local eye, now, scale = me:GetPos(), CurTime(), math.Clamp(cvTagScale:GetFloat(), 0.25, 4)
    for _, t in ipairs(LC_CL.tags or {}) do
        local rec = painted[TagKey(t)]
        if not rec then
            PaintTag(t, mats, scale)
        elseif rec.scale ~= scale or (now - rec.at > 90 and t.pos:DistToSqr(eye) < 1200 * 1200) then
            ClearTagDecal(t)
            PaintTag(t, mats, scale)
        end
    end
end)

hook.Add("PostCleanupMap", "LivingCityTagDecals", function() painted = {} end) -- (a map cleanup wipes every decal)

-- Rain washes the marks off open ground near you (blood, scorch marks, bullet holes on the
-- street): a few spots under the open sky every couple of seconds while it rains. Never near a
-- graffiti tag (rain doesn't take paint off a wall). Under a roof, nothing changes.
timer.Create("LivingCityRainWash", 2, 0, function()
    local w = GetGlobal2String("lc_weather", "clear")
    if (w ~= "rain" and w ~= "storm") or not util.RemoveDecalsAt or GetConVar("lc_rain_wash") and GetConVar("lc_rain_wash"):GetFloat() <= 0 then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local base = me:GetPos()
    for _ = 1, 6 do
        local p = base + Vector(math.Rand(-900, 900), math.Rand(-900, 900), 64)
        local down = util.TraceLine({ start = p, endpos = p - Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY })
        if down.Hit and not down.HitSky then
            local up = util.TraceLine({ start = down.HitPos + Vector(0, 0, 8), endpos = down.HitPos + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
            local nearTag = false
            for _, t in ipairs(LC_CL.tags or {}) do if t.pos:DistToSqr(down.HitPos) < 200 * 200 then nearTag = true break end end
            if (not up.Hit or up.HitSky) and not nearTag then util.RemoveDecalsAt(down.HitPos, 48) end
        end
    end
end)

if surface and surface.CreateFont then
    surface.CreateFont("LCLambda", { font = "Arial", size = 120, weight = 900, antialias = true })
end

-- The stand-in: a drawn lambda, only where the game's own sprays aren't there to use.
hook.Add("PostDrawTranslucentRenderables", "LivingCityTags", function(depth, sky)
    if sky or #LambdaMats() > 0 then return end
    local eye = EyePos()
    for _, t in ipairs(LC_CL.tags or {}) do
        if t.pos:DistToSqr(eye) < 1500 * 1500 then
            local ang = t.normal:Angle()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)
            cam.Start3D2D(t.pos + t.normal * 0.6, ang, 0.35)
                draw.SimpleText("λ", "LCLambda", 0, 0, Color(225, 120, 30, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)

local function PotLabel(e)
    local s = e:GetNW2String("lc_pot_state", "empty")
    if s == "empty" then return "Empty pot", "Plant a seed packet (E)" end
    if s == "ripe" then return "Ripe vegetables", "Harvest (E)" end
    local left = math.max(0, e:GetNW2Float("lc_pot_ready", 0) - CurTime())
    return "Growing", string.format("Ripe in %d:%02d", math.floor(left / 60), math.floor(left % 60))
end

hook.Add("HUDPaint", "LivingCityRebelPropLabels", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if not IsValid(e) or tr.HitPos:DistToSqr(ply:EyePos()) > 200 * 200 then return end
    local kind = e:GetNW2String("lc_label_kind", "")
    local title, sub
    if kind == "pot" then
        title, sub = PotLabel(e)
    elseif kind == "cache" then
        title = "Resistance supplies"
        sub = string.format("%d meal%s stored", e:GetNW2Int("lc_cache_stock", 0), e:GetNW2Int("lc_cache_stock", 0) == 1 and "" or "s")
    else
        return
    end
    local x, y = ScrW() / 2, ScrH() / 2 + 40
    draw.SimpleTextOutlined(title, "DermaDefaultBold", x, y, Color(225, 150, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined(sub, "DermaDefault", x, y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)

------------------------------------------------------------------------
-- Smoke and gas clouds (grenades and smoke bombs): real particles, grey for
-- smoke and a sickly green for chlorine, thick enough to hide in, and not lit
-- up like the engine's own smokestack.
------------------------------------------------------------------------

local SMOKE_MATS = { "particle/particle_smokegrenade", "particle/particle_noisesphere" }
LC_CL.clouds = LC_CL.clouds or {}

local function Puff(em, c, n, burst)
    for _ = 1, n do
        local off = VectorRand() * c.r * (burst and 0.35 or 0.6)
        off.z = math.abs(off.z) * 0.5 + 20
        local p = em:Add(SMOKE_MATS[math.random(#SMOKE_MATS)], c.pos + off)
        if p then
            if c.kind == "gas" then
                local g = math.random(95, 140)
                p:SetColor(g - 25, g + 25, g - 55)
            else
                local g = math.random(95, 150)
                p:SetColor(g, g, g)
            end
            p:SetStartAlpha(burst and 245 or 225)
            p:SetEndAlpha(0)
            p:SetVelocity(VectorRand() * (burst and math.Rand(350, 550) or math.Rand(20, 60)))
            p:SetLifeTime(0)
            p:SetDieTime(math.min(c.untilT - CurTime() + 3, math.Rand(7, 11)))
            p:SetStartSize(math.random(90, 120))
            p:SetEndSize(math.random(150, 200))
            p:SetRoll(math.random(-180, 180))
            p:SetRollDelta(math.Rand(-0.15, 0.15))
            p:SetAirResistance(burst and 260 or 80)
            p:SetGravity(Vector(0, 0, burst and 0 or 6))
            p:SetCollide(true)
            p:SetBounce(0.3)
            p:SetLighting(false)
        end
    end
end

net.Receive("lc_cloud", function()
    local pos, kind, secs, r = net.ReadVector(), net.ReadString(), net.ReadFloat(), net.ReadFloat()
    local me = LocalPlayer()
    if IsValid(me) and me:GetPos():DistToSqr(pos) > 6000 * 6000 then return end
    local c = { pos = pos, kind = kind, untilT = CurTime() + secs, r = r or 240, nextPuff = 0 }
    if ParticleEmitter then
        c.em = ParticleEmitter(pos, false)
        if c.em then Puff(c.em, c, 26, true) end
    end
    table.insert(LC_CL.clouds, c)
end)

-- keep it thick while it lasts, then let it thin out
hook.Add("Think", "LivingCityClouds", function()
    local now = CurTime()
    for i = #LC_CL.clouds, 1, -1 do
        local c = LC_CL.clouds[i]
        if now > c.untilT then
            if c.em then c.em:Finish() end
            table.remove(LC_CL.clouds, i)
        elseif c.em and now >= c.nextPuff then
            c.nextPuff = now + 0.35
            Puff(c.em, c, 3, false)
        end
    end
end)

-- Rebel territory: a warning a step before you walk into it, and while you're in it.
hook.Add("HUDPaint", "LivingCityRebelEdge", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local v = ply:GetNW2Int("lc_rebelzone", 0)
    if v == 0 then return end
    if LC_CL.InCombineZone(ply:GetPos()) then return end -- (inside a Combine zone: the server says so too)
    local unit = ply:GetNW2Bool("lc_unit", false)
    local x, y = ScrW() / 2, ScrH() * 0.16
    if v == 1 then
        draw.SimpleTextOutlined("REBEL TERRITORY AHEAD", "DermaDefaultBold", x, y, Color(255, 190, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        if unit then draw.SimpleTextOutlined("Step in and they'll open fire.", "DermaDefault", x, y + 16, Color(255, 220, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black) end
    else
        local a = unit and (170 + 85 * math.abs(math.sin(CurTime() * 4))) or 230
        draw.SimpleTextOutlined("REBEL TERRITORY", "DermaDefaultBold", x, y, Color(255, 90, 70, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        if unit then draw.SimpleTextOutlined("You're inside. They will shoot.", "DermaDefault", x, y + 16, Color(255, 200, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black) end
    end
end)
