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

local POLE_TOP, FOOT = 318, 70     -- the pole's height as the server scales it; how far up the pole the flag hangs at the bottom
local WIDE, HIGH = 78, 50
local CLOTH = Color(176, 44, 36)
local mat

-- The flag's four corners for a pole standing at pos, h of the way up (0 to 1), flying along dir.
function LC_CL.BaseFlagCorners(pos, h, dir)
    h = math.Clamp(h or 0, 0, 1)
    local top = pos + Vector(0, 0, FOOT + HIGH + (POLE_TOP - FOOT - HIGH) * h)
    local out = top + dir * WIDE
    local down = Vector(0, 0, HIGH)
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
            local a, b, c, d = LC_CL.BaseFlagCorners(e:GetPos(), e:GetNW2Float("lc_flag_h", 0), e:GetRight())
            render.DrawQuad(a, b, c, d, CLOTH)
            render.DrawQuad(b, a, d, c, CLOTH)
        end
    end
end)
