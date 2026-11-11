--[[
    Living City (client): the quest trail on the ground

    While you have a quest, amber chevrons on the ground lead the way to where
    it wants you, flowing toward it. The server works out the way over the
    city's own paths (sv_livingcity_guidance.lua) and sends it again when the
    objective moves or you wander off it. Here, the points you've walked past
    are dropped at once, so the trail always starts at your feet and never
    doubles back, and only the next stretch is drawn (AHEAD units).

    The ground under the way is found once, when the way changes, not every
    frame: drawing it is a couple of dozen chevrons.

    C > Settings: "Quest trail on the ground" (lc_trail_show, 1; the server
    stops sending it too). lc_trail 0 on the server turns it off for everyone.
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_trail_show", "1", true, true, "The quest trail on the ground, leading to your quest's objective: 1 on, 0 off")

local SPACING = 56      -- between chevrons
local SPEED = 70        -- how fast they flow toward the objective, units a second
local NEAR = 48         -- none right under your feet
local AHEAD = 1400      -- drawn this far along the way, no further
local FADE_IN, FADE_FAR = 80, 350
local PASS = 90         -- this close to a point, it's behind you
local ARRIVED = 100     -- this close to the end, the trail's done
local SAMPLE = 32       -- the ground under the way, found every this many units
local SAMPLE_MAX = 2200 -- (as far as could ever be drawn, and some)
local LIFT = 3          -- just above the ground
local COLOR = Color(235, 185, 80)

local MAT = Material("trails/laser")
local trail -- { pts = { Vector... }, goal = Vector, samples = { { pos, dir, d }... } }

function LC_CL.Trail() return trail end
function LC_CL.TrailActive() return trail ~= nil and cvShow:GetBool() end

local function Flat2(a, b) local dx, dy = a.x - b.x, a.y - b.y return dx * dx + dy * dy end
local function SegDist2(p, a, b)
    local ab = b - a
    local len2 = ab:LengthSqr()
    local t = len2 > 0 and math.Clamp((p - a):Dot(ab) / len2, 0, 1) or 0
    return p:DistToSqr(a + ab * t)
end

-- Drops the points already behind you (reached, or passed on the way to the
-- next); the last one, the objective, stays. Returns how many went.
function LC_CL.TrailPrune(t, pos)
    if not t or not t.pts or not pos then return 0 end
    local pts, cut = t.pts, 0
    for i = 1, math.min(#pts - 1, 4) do
        local p, nxt = pts[i], pts[i + 1]
        if Flat2(pos, p) < PASS * PASS and math.abs(pos.z - p.z) < 96 then
            cut = i
        else
            local ab = nxt - p
            local len2 = ab:LengthSqr()
            if len2 > 1 then
                local along = (pos - p):Dot(ab) / len2
                if along > 0 and along < 1 and SegDist2(pos, p, nxt) < (PASS * 1.5) ^ 2 then cut = i end
            end
        end
    end
    -- (how far along the way has been dropped: the chevrons keep their places on the ground, below)
    for i = 1, cut do t.d0 = (t.d0 or 0) + (pts[i + 1] - pts[i]):Length() end
    for _ = 1, cut do table.remove(pts, 1) end
    if cut > 0 then t.samples = nil end
    return cut
end

function LC_CL.SetTrail(t)
    if not t or type(t.p) ~= "table" or #t.p < 3 then trail = nil return end
    local pts = {}
    for i = 1, #t.p - 2, 3 do pts[#pts + 1] = Vector(t.p[i], t.p[i + 1], t.p[i + 2]) end
    trail = { pts = pts, goal = (type(t.g) == "table" and #t.g == 3) and Vector(t.g[1], t.g[2], t.g[3]) or pts[#pts] }
    local me = LocalPlayer()
    if IsValid(me) then LC_CL.TrailPrune(trail, me:GetPos()) end
end

net.Receive("lc_trail", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    LC_CL.SetTrail(json and util.JSONToTable(json) or nil)
end)

-- The ground along the way, every SAMPLE units: worked out once per change.
local function Ground(p)
    local tr = util.TraceLine({ start = p + Vector(0, 0, 40), endpos = p - Vector(0, 0, 120), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit and not tr.StartSolid then return Vector(p.x, p.y, tr.HitPos.z) end
    return p
end
local function Sample(t)
    local out, d = {}, 0
    local pts = t.pts
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i + 1]
        local seg = b - a
        local len = seg:Length()
        local dir = Vector(seg.x, seg.y, 0)
        if dir:LengthSqr() > 0.01 then dir:Normalize() else dir = Vector(1, 0, 0) end
        local s = 0
        while s < len do
            out[#out + 1] = { pos = Ground(a + seg * (s / len)), dir = dir, d = d + s }
            s = s + SAMPLE
            if d + s > SAMPLE_MAX then break end
        end
        d = d + len
        if d > SAMPLE_MAX then break end
    end
    local last = pts[#pts]
    local prevDir = out[#out] and out[#out].dir or Vector(1, 0, 0)
    out[#out + 1] = { pos = Ground(last), dir = prevDir, d = d }
    return out
end

-- Every chevron to draw now: { pos, dir, alpha }.
function LC_CL.TrailChevrons(t, from, now)
    if not t or not t.pts or #t.pts == 0 then return {} end
    t.samples = t.samples or Sample(t)
    local smp = t.samples
    local first = smp[1].pos
    local head = first - from
    local headLen = head:Length()
    local headDir = Vector(head.x, head.y, 0)
    if headDir:LengthSqr() > 0.01 then headDir:Normalize() else headDir = smp[1].dir end
    local out, j = {}, 1
    -- Each chevron keeps its place on the ground and flows on at SPEED, however fast you go (the owner,
    -- 11 November: "when I run they speed up and it looks really disorienting"; they were spaced out
    -- from your own feet, so they ran along with you).
    local u = (now * SPEED + headLen - (t.d0 or 0)) % SPACING
    while u <= AHEAD do
        local pos, dir
        if u < headLen then
            pos, dir = from + head * (u / math.max(headLen, 1)), headDir
        else
            local d = u - headLen
            while smp[j + 1] and smp[j + 1].d <= d do j = j + 1 end
            local a, b = smp[j], smp[j + 1]
            if not b then break end
            local f = (d - a.d) / math.max(b.d - a.d, 1)
            pos, dir = a.pos + (b.pos - a.pos) * f, a.dir
        end
        if u >= NEAR then
            local alpha = math.Clamp((u - NEAR) / FADE_IN, 0, 1) * math.Clamp((AHEAD - u) / FADE_FAR, 0, 1)
            if alpha > 0.02 then out[#out + 1] = { pos = pos, dir = dir, alpha = alpha } end
        end
        u = u + SPACING
    end
    return out
end

local nextThink = 0
hook.Add("Think", "LivingCityTrail", function()
    if not trail then return end
    local now = CurTime()
    if now < nextThink then return end
    nextThink = now + 0.1
    local me = LocalPlayer()
    if not IsValid(me) then return end
    -- the quest is over (or its last message went astray): no trail
    local q = LC_CL.QuestState and LC_CL.QuestState()
    if q and not q.active then trail = nil return end
    local pos = me:GetPos()
    LC_CL.TrailPrune(trail, pos)
    if #trail.pts <= 1 and pos:DistToSqr(trail.goal) < ARRIVED * ARRIVED then trail = nil end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCityTrail", function(depth, sky)
    if depth or sky or not trail or not cvShow:GetBool() then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local chev = LC_CL.TrailChevrons(trail, me:GetPos(), CurTime())
    if #chev == 0 then return end
    render.SetMaterial(MAT)
    local up = Vector(0, 0, LIFT)
    for _, c in ipairs(chev) do
        local d = c.dir
        local side = Vector(-d.y, d.x, 0)
        local p = c.pos + up
        local tip = p + d * 10
        local col = Color(COLOR.r, COLOR.g, COLOR.b, 255 * c.alpha)
        render.DrawBeam(p - d * 6 + side * 12, tip, 4, 0, 1, col)
        render.DrawBeam(p - d * 6 - side * 12, tip, 4, 0, 1, col)
    end
end)
