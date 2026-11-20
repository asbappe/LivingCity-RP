--[[
    Living City: the Resistance's flag (sv_livingcity_base.lua)

      The pole is a prop the server puts up; the flag on it is drawn here,
      as high up the pole as the server says (lc_flag_h, 0 to 1): climbing
      while the headquarters is being set up, at the top while it is live,
      at half mast when it is overrun, coming down when it is struck or torn
      down. Nothing is written on the screen: the flag is the message.
]]

if SERVER then return end

LC_CL = LC_CL or {}

local POLE_TOP, FOOT = 330, 70     -- a pole in the open; how far up it the flag hangs at the bottom
local WIDE, HIGH = 78, 50
local CLOTH = Color(176, 44, 36)
local mat

-- The flag's four corners for a pole standing at pos, h of the way up (0 to 1), flying along dir.
-- poleTop: how tall this pole is (the server makes it short under a roof); the flag and where it starts shrink with it.
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
        if IsValid(e) then
            local a, b, c, d = LC_CL.BaseFlagCorners(e:GetPos(), e:GetNW2Float("lc_flag_h", 0), e:GetRight(), e:GetNW2Float("lc_flag_top", POLE_TOP))
            render.DrawQuad(a, b, c, d, CLOTH)
            render.DrawQuad(b, a, d, c, CLOTH)
        end
    end
end)
