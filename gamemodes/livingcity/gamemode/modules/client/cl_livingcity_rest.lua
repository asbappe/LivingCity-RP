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
-- seven seconds or so, shut all the way a moment, then opened with a start.
function LC_CL.EyelidClose(t)
    local cycle = 7
    local p = (t % cycle) / cycle
    if p < 0.62 then return 0 end
    if p < 0.86 then return ((p - 0.62) / 0.24) ^ 1.6 end
    if p < 0.92 then return 1 end -- (shut, all the way)
    return 1 - (p - 0.92) / 0.08
end

local sleepFade = 0

hook.Add("HUDPaint", "LivingCityRest", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then sleepFade = 0 return end
    local w, h = ScrW(), ScrH()
    -- asleep: dark, and a little reassurance
    -- (slowly: a few seconds looking up from the pillow before your eyes close)
    sleepFade = math.Approach(sleepFade, me:GetNW2Bool("lc_sleeping", false) and 1 or 0, FrameTime() * (me:GetNW2Bool("lc_sleeping", false) and 0.25 or 0.7))
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
    -- (tired: the eyelids are drawn under the rest of the screen: LivingCityRestLids, below)
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

-- Tired: the eyelids. Drawn before the rest of the screen (HUDPaintBackground), so the job's
-- objective, its marker and the notices stay on top of them (the owner, 7 November: "The quest
-- objective disappears when the sleepiness effect eye shutting thing kicks in").
function LC_CL.DrawEyelids(me, t)
    if not IsValid(me) or not me:Alive() or not me:GetNW2Bool("lc_tired", false) or me:GetNW2Bool("lc_sleeping", false) then return false end
    local f = LC_CL.EyelidClose(t or CurTime())
    if f <= 0.01 then return false end
    local w, h = ScrW(), ScrH()
    local lid = (h / 2 + FEATHER * 0.5) * f -- (at 1 the two meet: no gap left between them)
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
    return true
end
hook.Add("HUDPaintBackground", "LivingCityRestLids", function() LC_CL.DrawEyelids(LocalPlayer()) end)

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
    for _, p in LC.Players() do
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

-- Asleep (a fighter on his mattress, sv_livingcity_rebellife.lua): eyes shut. The face's
-- blink and eyelid controls, held closed every frame (its own blinking would open them).
do
    local sleepers, at = {}, 0
    local flexOf = {} -- [model] = { ids }
    local function Lids(e)
        local m = e:GetModel() or ""
        local ids = flexOf[m]
        if not ids then
            ids = {}
            for i = 0, (e.GetFlexNum and e:GetFlexNum() or 0) - 1 do
                local n = string.lower(e:GetFlexName(i) or "")
                if n == "blink" or string.find(n, "lid_closer", 1, true) or string.find(n, "eyes_closed", 1, true) then ids[#ids + 1] = i end
            end
            flexOf[m] = ids
        end
        return ids
    end
    hook.Add("Think", "LivingCityEyesShut", function()
        local now = CurTime()
        if now >= at then
            at = now + 1
            sleepers = {}
            for _, e in ipairs(ents.FindByClass and ents.FindByClass("npc_*") or {}) do
                if IsValid(e) and e.GetNW2Bool and e:GetNW2Bool("lc_eyes_shut", false) then sleepers[#sleepers + 1] = e end
            end
            for _, e in ipairs(ents.FindByClass and ents.FindByClass("prop_ragdoll") or {}) do -- (an NPC asleep, laid on its bed)
                if IsValid(e) and e.GetNW2Bool and e:GetNW2Bool("lc_eyes_shut", false) then sleepers[#sleepers + 1] = e end
            end
            for _, p in ipairs(player.GetAll()) do -- (players asleep in a bed too)
                if p:GetNW2Bool("lc_sleeping", false) then sleepers[#sleepers + 1] = p end
            end
        end
        for _, e in ipairs(sleepers) do
            if IsValid(e) and e.SetFlexWeight then
                for _, id in ipairs(Lids(e)) do e:SetFlexWeight(id, 1) end
            end
        end
    end)
end

------------------------------------------------------------------------
-- Asleep in a bed: lying on it, seen by everyone, and your view from the pillow
------------------------------------------------------------------------

local BED_LIFT = 6 -- (how far above the mattress the hips lie)

-- Lay a sleeping player's model along their bed: turned the bed's way, the hips
-- over its middle. Returns where their head is, or nil if they're not in a bed.
function LC_CL.BedPlace(ply)
    if not IsValid(ply) or not ply:GetNW2Bool("lc_sleeping", false) then return nil end
    local top = ply:GetNW2Vector("lc_bed_top", Vector(0, 0, 0))
    if not top or (top.x == 0 and top.y == 0 and top.z == 0) then return nil end
    if not ply.SetRenderOrigin or not ply.SetRenderAngles then return nil end
    local yaw = ply:GetNW2Float("lc_bed_yaw", 0)
    ply:SetRenderAngles(Angle(0, yaw, 0))
    local off = ply.lcBedOff or Vector(0, 0, 0)
    local origin = top + Vector(0, 0, BED_LIFT) - off
    ply:SetRenderOrigin(origin)
    if ply.InvalidateBoneCache then ply:InvalidateBoneCache() end
    if ply.SetupBones then ply:SetupBones() end
    local pelvis = ply.LookupBone and ply:LookupBone("ValveBiped.Bip01_Pelvis")
    local pp = pelvis and ply:GetBonePosition(pelvis)
    if pp then
        -- (the lying animation carries the body away from its feet: measured, and the hips put back on the bed next frame)
        local measured = pp - origin
        if measured:LengthSqr() < 120 * 120 then ply.lcBedOff = measured end
    end
    local head = ply.LookupBone and ply:LookupBone("ValveBiped.Bip01_Head1")
    local hp = head and ply:GetBonePosition(head)
    return hp or (top + Vector(0, 0, BED_LIFT + 8))
end

hook.Add("PrePlayerDraw", "LivingCityBed", function(ply)
    if LC_CL.BedPlace(ply) then ply.lcBedDrawn = true end
end)
hook.Add("PostPlayerDraw", "LivingCityBed", function(ply)
    if ply.lcBedDrawn then
        ply.lcBedDrawn = nil
        ply:SetRenderOrigin(nil)
    end
end)
hook.Add("Think", "LivingCityBedForget", function()
    for _, ply in LC.Players() do
        if ply.lcBedOff and not ply:GetNW2Bool("lc_sleeping", false) then ply.lcBedOff = nil end
    end
end)

-- (one of the camera's steps: cl_livingcity_view.lua) your eyes on the pillow, looking about as you like
LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.bed = { order = 15, fn = function(ply, view, ctx)
    if ctx.remote or ctx.vehicle then return end
    local head = LC_CL.BedPlace(ply)
    if not head then return end
    if ply.SetRenderOrigin then ply:SetRenderOrigin(nil) end
    view.origin = head + Vector(0, 0, 4)
    view.drawviewer = false
    ctx.remote = true -- (not from your standing eyes: no step sway)
end }
