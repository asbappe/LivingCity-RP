--[[
    Living City: the Resistance's flag (sv_livingcity_base.lua)

      The pole is a prop the server puts up; the flag on it is drawn here
      (the Lambda in its ring, orange on black, waving),
      as high up the pole as the server says (lc_flag_h, 0 to 1): climbing
      while the headquarters is being set up, at the top while it is live,
      at half mast when it is overrun, coming down when it is struck or torn
      down. The flag is the message; the only words are at the pole itself,
      for a member of the Resistance standing at it: what E does there for a
      Lieutenant or Commander, and for anyone else that it takes one of them
      (the owner, 20 November).
]]

if SERVER then return end

LC_CL = LC_CL or {}

local POLE_TOP, FOOT = 330, 70     -- a pole in the open; how far up it the flag hangs at the bottom
local WIDE, HIGH = 132, 84
local FIELD, LAMBDA = Color(22, 22, 24), Color(240, 132, 26)      -- the Resistance's colours: the Lambda in orange on black
local mat

-- The flag's four corners for a pole standing at pos, h of the way up (0 to 1), flying along dir.
-- poleTop: how tall this pole is (the server makes it short under a roof); the flag and where it starts shrink with it.
-- A tall pole (a map's _top marker: the silo's, about 1700) keeps the flag full size; at the top it hangs 12 under the
-- marker, so the map puts the marker about 120 over the floor the flag is to be seen from at eye level.
function LC_CL.BaseFlagCorners(pos, h, dir, poleTop)
    h = math.Clamp(h or 0, 0, 1)
    poleTop = poleTop or POLE_TOP
    local k = math.Clamp(poleTop / POLE_TOP, 0.4, 1)
    local foot, wide, high = FOOT * k, WIDE * k, HIGH * k
    local top = pos + Vector(0, 0, foot + high + (poleTop - 12 - foot - high) * h)
    local out = top + dir * wide
    local down = Vector(0, 0, high)
    return top, out, out - down, top - down
end

-- The cloth: a waving surface from the pole (origin: its top corner there) `across` and `down`, rippling along
-- `normal` more towards the free end, drawn on both sides, darker in each fold and in the dark.
-- On it the Lambda in its ring, a hair off the cloth on each side.
local COLS, RING = 12, 20
function LC_CL.BaseFlagDraw(origin, across, down, normal, W, H, t, light)
    local amp = H * 0.11
    local function At(x, y, lift)
        local u = x / W
        return origin + across * x + down * y + normal * (math.sin(u * 7 - t * 4.5) * amp * u + (lift or 0))
    end
    local function Shade(col, x)
        local k = light * (1 + 0.2 * math.cos(x / W * 7 - t * 4.5))
        return Color(math.min(255, col.r * k), math.min(255, col.g * k), math.min(255, col.b * k))
    end
    for i = 0, COLS - 1 do
        local x0, x1 = W * i / COLS, W * (i + 1) / COLS
        local a, b, c, d = At(x0, 0), At(x1, 0), At(x1, H), At(x0, H)
        local col = Shade(FIELD, (x0 + x1) / 2)
        render.DrawQuad(a, b, c, d, col)
        render.DrawQuad(d, c, b, a, col)
    end
    -- a stroke from (x1, y1) to (x2, y2), th wide, in pieces short enough to follow the folds
    local function Stroke(x1, y1, x2, y2, th, pieces)
        local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
        if len < 0.01 then return end
        local nx, ny = -(y2 - y1) / len * th / 2, (x2 - x1) / len * th / 2
        for seg = 0, pieces - 1 do
            local f0, f1 = seg / pieces, (seg + 1) / pieces
            local ax, ay, bx, by = x1 + (x2 - x1) * f0, y1 + (y2 - y1) * f0, x1 + (x2 - x1) * f1, y1 + (y2 - y1) * f1
            local col = Shade(LAMBDA, (ax + bx) / 2)
            for _, side in ipairs({ 0.5, -0.5 }) do
                local p1, p2 = At(ax + nx, ay + ny, side), At(bx + nx, by + ny, side)
                local p3, p4 = At(bx - nx, by - ny, side), At(ax - nx, ay - ny, side)
                if side > 0 then render.DrawQuad(p1, p2, p3, p4, col) else render.DrawQuad(p4, p3, p2, p1, col) end
            end
        end
    end
    local cx, cy, R, th = W / 2, H / 2, H * 0.37, H * 0.075
    for i = 0, RING - 1 do
        local a1, a2 = math.rad(i * 360 / RING), math.rad((i + 1) * 360 / RING + 2)
        Stroke(cx + math.cos(a1) * R, cy + math.sin(a1) * R, cx + math.cos(a2) * R, cy + math.sin(a2) * R, th, 1)
    end
    -- the Lambda: its hook at the top, the long stroke down to the right, the short leg down to the left
    Stroke(cx - H * 0.15, cy - H * 0.215, cx - H * 0.055, cy - H * 0.215, th, 1)
    Stroke(cx - H * 0.085, cy - H * 0.235, cx + H * 0.15, cy + H * 0.235, th * 1.1, 4)
    Stroke(cx + H * 0.005, cy - H * 0.02, cx - H * 0.15, cy + H * 0.235, th * 1.1, 3)
end

local flags, nextLook = {}, 0
hook.Add("PostDrawOpaqueRenderables", "LivingCityBaseFlag", function()
    local now = CurTime()
    if now >= nextLook then
        nextLook = now + 1
        flags = {}
        for _, e in ipairs(ents.FindByClass("prop_physics")) do
            if e:GetNW2Bool("lc_baseflag", false) then flags[#flags + 1] = e end
        end
    end
    if #flags == 0 then return end
    mat = mat or Material("models/debug/debugwhite")
    render.SetMaterial(mat)
    for _, e in ipairs(flags) do
        if IsValid(e) and e:GetNW2Bool("lc_flag_up", false) then
            local dir = e:GetRight()
            local a, b, _, d = LC_CL.BaseFlagCorners(e:GetPos(), e:GetNW2Float("lc_flag_h", 0), dir, e:GetNW2Float("lc_flag_top", POLE_TOP))
            local lit = render.GetLightColor and render.GetLightColor(a) or Vector(1, 1, 1)
            local light = math.Clamp(0.3 + (lit.x + lit.y + lit.z) * 0.9, 0.3, 1.25)
            LC_CL.BaseFlagDraw(a, dir, Vector(0, 0, -1), Vector(-dir.y, dir.x, 0), a:Distance(b), a:Distance(d), now + e:EntIndex(), light)
        end
    end
end)

-- What the pole says to a member of the Resistance standing at it (nil: nothing).
function LC_CL.BasePolePrompt(me, state, up)
    if not (IsValid(me) and me:GetNW2String("lcf_faction", "") == "resistance") then return nil end
    if not me:GetNW2Bool("lc_base_may", false) then return "Resistance Commander or Lieutenant is required to establish a Resistance HQ" end
    if state == "" then return LC_CL.HintKeys("{+use} Raise the flag") end
    if not up then return nil end
    return LC_CL.HintKeys(({ raising = "{+use} Leave the flag", live = "{+use} Strike the flag", striking = "{+use} Hoist it again" })[state] or "")
end

surface.CreateFont("LCBasePole", { font = "Trebuchet MS", size = 18, weight = 600 })
hook.Add("HUDPaint", "LivingCityBasePole", function()
    if #flags == 0 or not GetGlobal2Bool("lc_base_on", false) then return end
    local me = LocalPlayer()
    if not (IsValid(me) and me:Alive()) then return end
    local at = me:GetPos()
    for _, e in ipairs(flags) do
        if IsValid(e) and e:GetPos():DistToSqr(at) <= 110 * 110 then
            local text = LC_CL.BasePolePrompt(me, GetGlobal2String("lc_base", ""), e:GetNW2Bool("lc_flag_up", false))
            if text and text ~= "" then
                draw.SimpleTextOutlined(text, "LCBasePole", ScrW() / 2, ScrH() * 0.62, Color(238, 236, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
            end
            return
        end
    end
end)
