--[[
    Living City: the Resistance's flag (sv_livingcity_base.lua)

      The pole is a prop the server puts up; the flag on it is drawn here,
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
        if IsValid(e) and e:GetNW2Bool("lc_flag_up", false) then
            local a, b, c, d = LC_CL.BaseFlagCorners(e:GetPos(), e:GetNW2Float("lc_flag_h", 0), e:GetRight(), e:GetNW2Float("lc_flag_top", POLE_TOP))
            render.DrawQuad(a, b, c, d, CLOTH)
            render.DrawQuad(b, a, d, c, CLOTH)
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
