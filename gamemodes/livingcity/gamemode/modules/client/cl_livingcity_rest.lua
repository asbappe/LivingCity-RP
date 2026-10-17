--[[
    Living City (client): sleep, and what happens without it or a toilet

      Tired (sv_livingcity_rest.lua): your eyelids droop shut every few
      seconds and open again, and the world swims a little.
      Sleeping: the screen goes dark while you lie there.
      Filthy (sv_livingcity_hygiene.lua): flies round whoever it is, you
      included; and a cramping stomach shows as a line under your needs.
]]

LC_CL = LC_CL or {}

local BLACK = Color(0, 0, 0)
local FEATHER = 90 -- (the eyelids' soft edge, in pixels)
local gradDown, gradUp, blurMat
-- lying still: the same as the server's, so your own game doesn't try to walk you about
hook.Add("StartCommand", "LivingCitySleeping", function(ply, cmd)
    if not ply:GetNW2Bool("lc_sleeping", false) then return end
    cmd:ClearMovement()
    cmd:SetButtons(bit.band(cmd:GetButtons(), IN_JUMP))
end)
-- An eyelid: dark, fading softly into the open eye (not a hard black line)
local function Lid(w, h, lid, top)
    gradDown = gradDown or (Material and Material("vgui/gradient-d"))
    gradUp = gradUp or (Material and Material("vgui/gradient-u"))
    local solid = math.max(0, lid - FEATHER * 0.5)
    surface.SetDrawColor(0, 0, 0, 255)
    if top then surface.DrawRect(0, 0, w, solid) else surface.DrawRect(0, h - solid, w, solid) end
    local g = top and gradUp or gradDown
    if g and surface.SetMaterial then
        surface.SetMaterial(g)
        surface.SetDrawColor(0, 0, 0, 255)
        if top then surface.DrawTexturedRect(0, solid, w, FEATHER) else surface.DrawTexturedRect(0, h - solid - FEATHER, w, FEATHER) end
        if draw.NoTexture then draw.NoTexture() end
    end
end

-- How closed the eyes are right now (0 open, 1 shut): a slow droop every
-- seven seconds or so, held a moment, then opened with a start.
function LC_CL.EyelidClose(t)
    local cycle = 7
    local p = (t % cycle) / cycle
    if p < 0.62 then return 0 end
    if p < 0.86 then return 0.85 * ((p - 0.62) / 0.24) ^ 1.6 end
    if p < 0.92 then return 0.85 end
    return 0.85 * (1 - (p - 0.92) / 0.08)
end

local sleepFade = 0

hook.Add("HUDPaint", "LivingCityRest", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then sleepFade = 0 return end
    local w, h = ScrW(), ScrH()
    -- asleep: dark, and a little reassurance
    sleepFade = math.Approach(sleepFade, me:GetNW2Bool("lc_sleeping", false) and 1 or 0, FrameTime() * 0.7)
    if sleepFade > 0.01 then
        surface.SetDrawColor(0, 0, 0, 245 * sleepFade)
        surface.DrawRect(0, 0, w, h)
        if sleepFade > 0.6 then
            draw.SimpleText("Z z z", "DermaLarge", w / 2, h / 2 - 20, Color(200, 200, 210, 200 * sleepFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local done = me:GetNW2Float("lc_sleep_done", 0)
            local msg = (done > 0 and CurTime() < done) and string.format("Asleep (%ds). Jump to get up (too soon, and it won't count).", math.ceil(done - CurTime()))
                or "Rested. Jump to get up."
            draw.SimpleText(msg, "DermaDefault", w / 2, h / 2 + 16, Color(170, 170, 180, 200 * sleepFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end
    -- tired: the eyelids
    if me:GetNW2Bool("lc_tired", false) then
        local f = LC_CL.EyelidClose(CurTime())
        if f > 0.01 then
            local lid = h / 2 * f
            -- the world blurs as they close
            blurMat = blurMat or (Material and Material("pp/blurscreen"))
            if blurMat and render and render.UpdateScreenEffectTexture and surface.SetMaterial then
                surface.SetMaterial(blurMat)
                surface.SetDrawColor(255, 255, 255, 255)
                for i = 1, 3 do
                    blurMat:SetFloat("$blur", f * 2 * i)
                    if blurMat.Recompute then blurMat:Recompute() end
                    render.UpdateScreenEffectTexture()
                    surface.DrawTexturedRect(0, 0, w, h)
                end
                if draw.NoTexture then draw.NoTexture() end
            end
            Lid(w, h, lid, true)
            Lid(w, h, lid, false)
        end
    end
    -- after a close call: still recovering (sv_livingcity_progress.lua)
    local rec = me:GetNW2Float("lc_recovering_until", 0) - CurTime()
    local ly = (LC_CL.LeftColumnBottom and LC_CL.LeftColumnBottom() or 160) + 6 -- (in the left column, under the rest)
    if rec > 0 then
        draw.SimpleText(string.format("Recovering from a close call (%d:%02d): a little less to give", math.floor(rec / 60), math.floor(rec % 60)),
            "DermaDefault", 20, ly, Color(200, 170, 150))
        ly = ly + 16
    end
    -- the urge (parasites): a line under the needs while it's building
    local urge = me:GetNW2Float("lc_urge", 0)
    if urge >= 25 then
        local y = ly
        draw.SimpleText(urge >= 80 and "You need a toilet. NOW." or (urge >= 50 and "Your stomach cramps: find a toilet." or "Your stomach's unsettled."),
            "DermaDefaultBold", 20, y, urge >= 80 and Color(255, 120, 90) or Color(230, 190, 120))
    end
end)

-- tired: the world swims a little
hook.Add("RenderScreenspaceEffects", "LivingCityRest", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_tired", false) then return end
    if DrawMotionBlur then DrawMotionBlur(0.25, 0.35 + 0.15 * math.sin(CurTime() * 0.8), 0.01) end
end)

-- flies round anyone filthy
local FLY = Color(15, 15, 10, 230)
hook.Add("PostDrawTranslucentRenderables", "LivingCityStink", function(depth, sky)
    if depth or sky then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local drew = false
    local t = CurTime()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetNW2Bool("lc_stink", false) and p:GetPos():DistToSqr(me:GetPos()) < 900 * 900 and (p ~= me or me:ShouldDrawLocalPlayer()) then
            if not drew then render.SetColorMaterial() drew = true end
            local c = p:GetPos() + Vector(0, 0, 36)
            for i = 1, 9 do
                local a = t * (2.2 + i * 0.31) + i * 2.1
                local r = 14 + (i % 3) * 5
                render.DrawSphere(c + Vector(math.cos(a) * r, math.sin(a * 1.2) * r, math.sin(t * 2.5 + i) * 14), 0.6, 4, 4, FLY)
            end
        end
    end
end)
