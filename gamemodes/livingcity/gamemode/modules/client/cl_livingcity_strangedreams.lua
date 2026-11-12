--[[
    Living City: the strange dreams, your side (sv_livingcity_strangedreams.lua, sv_livingcity_strangedreams2.lua)

      The voices in the dark (The Cheese Dream, Hooves and All): the screen goes black, and each line
      comes as if from far away, then echoes, further and further off, drifting from one side to the
      other, fading and sinking in pitch, in a cavern's reverb (the owner: "a dreamy distant echo
      effect"); then both voices at once, and the dream swims up out of the dark.
      The Cheese Dream: psychedelic (the colours roll round the rainbow, the picture ripples and smears,
      rainbow sparks drift round you, the music wobbles; golden cheese turns the colours inside out).
      Wings: golden rings, clouds, a pale blue sky. It's Raining Melons: summer light.
      Hooves and All: a cold night, the horse's red eyes, a flash at every shot. The Main Event: the
      ring's ropes and a spotlight; a red glow under it as it winds up. Running in Molasses: sepia and
      smeared. Hot Potato: the grenade glows red, faster as it burns down. Dance Marathon: the lights
      flash on the beat and a ring closes in on every big beat. Counting Headcrabs: a sleepy night.
      The ten after those: clocks melting under a warping picture; a pastel tea party; a white flash when the
      scanner takes its picture; bubbles in every colour; a rainbow trail behind the conga; the screen
      reddening as the baby stirs; the Watchers' red eyes in the dark.
      In every strange dream, nonsense (the owner, 9 November): bathtubs, melons, clocks, toilets and dolls
      drifting and turning in the sky in every colour, rainbow swirls overhead, some things retextured by
      the server, and some people's faces pulled into random expressions (their faces change every few
      seconds: a stand-in copy of the figure that can move its face is drawn in its place).
      (The glows, boards, meters, music and lines are the dreams' own screen: cl_livingcity_dreamgames.lua.)
]]

LC_CL = LC_CL or {}

local function St() return LC_CL.DreamGame and LC_CL.DreamGame() or nil end
local glow = Material("sprites/light_glow02_add")
local beam = Material("cable/rope")
local beamMat = Material("sprites/physbeama")

-- A colour round the rainbow (h from 0 to 1).
local function Rainbow(h, a)
    h = (h or 0) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local rgb = ({ { 1, f, 0 }, { q, 1, 0 }, { 0, 1, f }, { 0, q, 1 }, { f, 0, 1 }, { 1, 0, q } })[i + 1]
    return Color(math.floor(rgb[1] * 255), math.floor(rgb[2] * 255), math.floor(rgb[3] * 255), a or 255)
end
LC_CL.StrangeRainbow = Rainbow

------------------------------------------------------------------------
-- The voices in the dark: a dreamy, distant echo
------------------------------------------------------------------------

-- Each line, then its echoes: { delay, distance, volume, pitch }. The first is already far off;
-- every echo is further, quieter and lower, and drifts to the other side.
LC_CL.DreamEchoes = { { 0, 350, 0.9, 100 }, { 0.6, 750, 0.55, 97 }, { 1.2, 1150, 0.35, 94 }, { 1.8, 1550, 0.22, 91 }, { 2.4, 1950, 0.12, 88 }, { 3.0, 2350, 0.06, 85 } }
LC_CL.DreamEchoDSP = 25 -- (Source's "cavern, large": the server sets it too)
local function Far(dist, side)
    local me = LocalPlayer()
    local eye = (EyePos and EyePos()) or (IsValid(me) and me:GetPos() + Vector(0, 0, 64)) or Vector(0, 0, 0)
    local ang = (EyeAngles and EyeAngles()) or Angle(0, 0, 0)
    local yaw = math.rad(ang.y + 90 * side + 20 * side)
    return eye + Vector(math.cos(yaw) * dist, math.sin(yaw) * dist, 60)
end
local function Echo(path, at, pitch)
    if not path or path == "" then return end
    for i, e in ipairs(LC_CL.DreamEchoes) do
        timer.Simple(at + e[1], function()
            local me = LocalPlayer()
            if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
            local p = math.floor(e[4] * (pitch or 100) / 100)
            if sound and sound.Play then
                sound.Play(path, Far(e[2], i % 2 == 0 and 1 or -1), 100, p, e[3])
            else
                me:EmitSound(path, 75, p, e[3], CHAN_STATIC or 6)
            end
        end)
    end
end
LC_CL.DreamEcho = Echo
-- The first voice, then the second, then both together, one lower and one higher.
function LC_CL.DreamIntro(lines)
    lines = lines or {}
    local me = LocalPlayer()
    if IsValid(me) and me.SetDSP then pcall(me.SetDSP, me, LC_CL.DreamEchoDSP, false) end
    Echo(lines[1], 0.4)
    Echo(lines[2] or lines[1], 3.0)
    Echo(lines[1], 5.6, 82)
    Echo(lines[2] or lines[1], 5.75, 122)
end
LC_CL.CheeseIntro = LC_CL.DreamIntro -- (its first name)

local seen
hook.Add("Think", "LivingCityStrangeDreams", function()
    local st = St()
    if st == seen then return end
    seen = st
    if st and (st.intro or 0) > CurTime() and st.lines then LC_CL.DreamIntro(st.lines) end
end)

------------------------------------------------------------------------
-- Nonsense: things floating in the sky, and faces
------------------------------------------------------------------------

LC_CL.StrangeThemes = {}
for _, id in ipairs({ "cheese", "chairs", "flying", "melons", "horse", "boxing", "exam", "train", "lamarr", "molasses", "potato", "simon", "dance", "sheep",
    "clocks", "tea", "derby", "photo", "doors", "paint", "conga", "shh", "bubbles", "watchers" }) do LC_CL.StrangeThemes[id] = true end
LC_CL.NonsenseModels = { "models/props_junk/watermelon01.mdl", "models/props_interiors/bathtub01a.mdl", "models/props_c17/clock01.mdl", "models/props_c17/furnituretoilet001a.mdl",
    "models/props_c17/doll01.mdl", "models/props_junk/shoe001a.mdl", "models/props_c17/chair02a.mdl", "models/props_junk/popcan01a.mdl", "models/headcrabclassic.mdl",
    "models/props_c17/oildrum001.mdl", "models/props_lab/huladoll.mdl", "models/props_junk/garbage_coffeemug001a.mdl" }
local floaters, anchor = {}, nil
local function ClearFloaters()
    for _, f in ipairs(floaters) do if IsValid(f.m) then f.m:Remove() end end
    floaters, anchor = {}, nil
end
local function MakeFloaters()
    ClearFloaters()
    local me = LocalPlayer()
    if not (ClientsideModel and IsValid(me)) then return end
    anchor = me:GetPos()
    for i = 1, 12 do
        local m = ClientsideModel(LC_CL.NonsenseModels[(i - 1) % #LC_CL.NonsenseModels + 1], RENDERGROUP_OPAQUE)
        if IsValid(m) then
            local sc = math.Rand(1.5, 6)
            if m.SetModelScale then m:SetModelScale(sc, 0) end
            floaters[#floaters + 1] = { m = m, r = math.Rand(500, 1400), h = math.Rand(250, 900), a = math.Rand(0, math.pi * 2), speed = math.Rand(0.05, 0.2) * (i % 2 == 0 and 1 or -1),
                spin = Angle(math.Rand(-40, 40), math.Rand(-60, 60), math.Rand(-40, 40)), hue = i / 12 }
        end
    end
end
LC_CL.StrangeFloaters = function() return floaters end
local function MoveFloaters(now)
    if not anchor then return end
    for _, f in ipairs(floaters) do
        if IsValid(f.m) then
            local a = f.a + now * f.speed
            f.m:SetPos(anchor + Vector(math.cos(a) * f.r, math.sin(a) * f.r, f.h + math.sin(now * 0.5 + f.hue * 9) * 60))
            f.m:SetAngles(Angle(now * f.spin.p % 360, now * f.spin.y % 360, now * f.spin.r % 360))
            f.m:SetColor(Rainbow(now * 0.1 + f.hue))
        end
    end
end

-- Faces: a figure the server marked (lc_dream_face) is drawn by a copy that can pull faces.
local faces = {}
local function ClearFaces()
    for e, f in pairs(faces) do
        if IsValid(f.m) then f.m:Remove() end
        if IsValid(e) then e.RenderOverride = nil end
    end
    faces = {}
end
local function Face(e)
    if not ClientsideModel then return end
    local m = ClientsideModel(e:GetModel(), RENDERGROUP_OPAQUE)
    if not IsValid(m) then return end
    m:SetNoDraw(true)
    local f = { m = m, next = 0 }
    faces[e] = f
    e.RenderOverride = function(self)
        if not IsValid(m) then self:DrawModel() return end
        local now = CurTime()
        if now >= f.next and m.GetFlexNum then -- (a new face every few seconds)
            for i = 0, m:GetFlexNum() - 1 do m:SetFlexWeight(i, math.Rand(0, 0.9)) end
            f.next = now + math.Rand(1.5, 4)
        end
        m:SetPos(self:GetPos())
        m:SetAngles(self:GetAngles())
        if m.SetModelScale then m:SetModelScale(self:GetModelScale() or 1, 0) end
        if self.GetSequence then m:SetSequence(self:GetSequence()) m:SetCycle(self:GetCycle()) end
        m:SetMaterial(self:GetMaterial() or "")
        local c = self:GetColor()
        render.SetColorModulation(c.r / 255, c.g / 255, c.b / 255)
        m:DrawModel()
        render.SetColorModulation(1, 1, 1)
    end
end
LC_CL.DreamFaces = function() return faces end
local faceAt = 0
local function FaceTick(now)
    if now < faceAt then return end
    faceAt = now + 0.5
    local me = LocalPlayer()
    if not (IsValid(me) and me:GetNW2Bool("lc_dreaming", false)) then if next(faces) then ClearFaces() end return end
    for e, f in pairs(faces) do if not IsValid(e) then if IsValid(f.m) then f.m:Remove() end faces[e] = nil end end
    if not (ents and ents.FindByClass) then return end
    local fx = {}
    for _, e in ipairs(ents.FindByClass("prop_dynamic")) do
        if IsValid(e) and not faces[e] and e:GetNW2Bool("lc_dream_face", false) then Face(e) end
        local m = IsValid(e) and e:GetNW2Int("lc_dream_fx", 0) or 0
        if m > 0 then fx[#fx + 1] = { e = e, m = m, seed = e:EntIndex() } end
    end
    LC_CL.DreamFxList = fx
end

-- The ten effects things may carry (sv_livingcity_strangedreams.lua rolls them): bit k for LC_CL.DreamFxNames[k].
LC_CL.DreamFxNames = { "sparkles", "halo", "smoke", "bubbles", "hearts", "fire", "confetti", "moons", "beam", "disco" }
LC_CL.DreamFxList = {}
function LC_CL.DreamFxHas(mask, k) return math.floor((mask or 0) / 2 ^ (k - 1)) % 2 == 1 end
local Has = LC_CL.DreamFxHas
local emitter, emitAt = nil, 0
local function Emit(now)
    if now < emitAt or #LC_CL.DreamFxList == 0 or not ParticleEmitter then return end
    emitAt = now + 0.12
    local me = LocalPlayer()
    if not IsValid(me) then return end
    if not emitter then emitter = ParticleEmitter(me:GetPos()) end
    if not emitter then return end
    local gst = LC_CL.DreamGame and LC_CL.DreamGame()
    local bubbleDream = gst ~= nil and gst.theme == "bubbles"
    for _, f in ipairs(LC_CL.DreamFxList) do
        local e = f.e
        if IsValid(e) then
            local top = e:GetPos() + Vector(0, 0, (e.OBBMaxs and e:OBBMaxs().z or 40) * (e.GetModelScale and e:GetModelScale() or 1))
            if Has(f.m, 3) and math.random() < 0.6 then -- smoke
                local pt = emitter:Add("particle/particle_smokegrenade", top)
                if pt then pt:SetVelocity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(30, 60))) pt:SetDieTime(2.5) pt:SetStartAlpha(120) pt:SetEndAlpha(0)
                    pt:SetStartSize(10) pt:SetEndSize(50) local c = Rainbow(now * 0.1 + f.seed * 0.1) pt:SetColor(c.r, c.g, c.b) end
            end
            if Has(f.m, 4) and not bubbleDream then -- bubbles (not in the Bubbles dream: only the real ones there)
                local pt = emitter:Add("effects/bubble", top + Vector(math.Rand(-20, 20), math.Rand(-20, 20), 0))
                if pt then pt:SetVelocity(Vector(0, 0, math.Rand(40, 90))) pt:SetDieTime(2) pt:SetStartAlpha(255) pt:SetEndAlpha(0) pt:SetStartSize(4) pt:SetEndSize(8) end
            end
            if Has(f.m, 7) then -- confetti
                for _ = 1, 2 do
                    local pt = emitter:Add("effects/spark", top)
                    if pt then
                        pt:SetVelocity(VectorRand() * 120 + Vector(0, 0, 120)) pt:SetGravity(Vector(0, 0, -200)) pt:SetDieTime(1.6)
                        pt:SetStartAlpha(255) pt:SetEndAlpha(0) pt:SetStartSize(3) pt:SetEndSize(3)
                        local c = Rainbow(math.random()) pt:SetColor(c.r, c.g, c.b)
                    end
                end
            end
        end
    end
end
-- The rest are drawn each frame (sparkles, halo, hearts, fire, moons, beam, disco).
local function DrawFx(now)
    if #LC_CL.DreamFxList == 0 then return end
    render.SetMaterial(glow)
    for _, f in ipairs(LC_CL.DreamFxList) do
        local e = f.e
        if IsValid(e) then
            local sc = e.GetModelScale and e:GetModelScale() or 1
            local h = (e.OBBMaxs and e:OBBMaxs().z or 40) * sc
            local base, mid = e:GetPos(), e:GetPos() + Vector(0, 0, h * 0.5)
            if Has(f.m, 1) then for i = 1, 6 do local a = now * 2 + i + f.seed render.DrawSprite(mid + Vector(math.cos(a) * h * 0.6, math.sin(a) * h * 0.6, math.sin(a * 2) * h * 0.3), 14, 14, Rainbow(i / 6 + now * 0.2)) end end
            if Has(f.m, 2) then local s2 = h * 1.4 * (0.85 + 0.15 * math.sin(now * 3 + f.seed)) render.DrawSprite(mid, s2, s2, Color(255, 255, 220, 70)) end
            if Has(f.m, 5) then for i = 1, 4 do local fr = (now * 0.4 + i / 4 + f.seed * 0.1) % 1 render.DrawSprite(base + Vector(math.sin(i + now) * 15, 0, h + fr * 80), 16 * (1 - fr) + 4, 16 * (1 - fr) + 4, Color(255, 80, 160, math.floor(255 * (1 - fr)))) end end
            if Has(f.m, 6) then
                local fl = 0.7 + 0.3 * math.sin(now * 23 + f.seed)
                render.DrawSprite(base + Vector(0, 0, h * 0.3), h * 0.9 * fl, h * 1.3 * fl, Color(255, 120, 30, 160))
                render.DrawSprite(base + Vector(0, 0, h * 0.2), h * 0.5 * fl, h * 0.7 * fl, Color(255, 230, 120, 200))
            end
            if Has(f.m, 8) then for i = 1, 3 do local a = now * (1 + i * 0.4) + i * 2 local r = h * 0.8 + i * 15 render.DrawSprite(mid + Vector(math.cos(a) * r, math.sin(a) * r, 0), 24 - i * 4, 24 - i * 4, Rainbow(i / 3 + 0.5)) end end
            if Has(f.m, 9) and render.DrawBeam then
                render.SetMaterial(beamMat)
                render.DrawBeam(base, base + Vector(0, 0, 2000), 20 + 10 * math.sin(now * 4 + f.seed), 0, 1, Rainbow(now * 0.3 + f.seed * 0.05, 140))
                render.SetMaterial(glow)
            end
            if Has(f.m, 10) and DynamicLight then
                local d = DynamicLight(9000 + f.seed % 500)
                if d then local c = Rainbow(now * 0.8 + f.seed * 0.1) d.pos, d.r, d.g, d.b, d.brightness, d.decay, d.size, d.dietime = mid, c.r, c.g, c.b, 3, 1000, 300, now + 0.2 end
            end
        end
    end
end

-- Lines said in a strange dream: some slowed, some sped up (cl_livingcity_dreamgames.lua asks this as it plays one).
function LC_CL.DreamVoiceRate(st)
    if not st or not LC_CL.StrangeThemes[st.theme or ""] or math.random() >= 0.4 then return nil end
    return math.Rand(0.72, 1.35)
end
-- The music, now and then, slows right down or races (the owner: "slow down/speed ups"); the cheese dream wobbles all the time.
local lurch = { at = 0, til = 0, rate = 1 }
local function MusicWarp(st, now)
    if not LC_CL.DreamGameSongChannel then return end
    local ch = LC_CL.DreamGameSongChannel()
    if not (IsValid(ch) and ch.SetPlaybackRate) then return end
    if st.theme == "cheese" then ch:SetPlaybackRate(1 + 0.12 * math.sin(now * 0.9)) return end
    if st.theme == "dance" then return end -- (the beat has to stay the beat)
    if now >= lurch.at then lurch.rate, lurch.til, lurch.at = (math.random() < 0.5 and math.Rand(0.65, 0.85) or math.Rand(1.2, 1.4)), now + math.Rand(3, 6), now + math.Rand(13, 23) end -- (each lurch twice as long: the owner, 11 November)
    ch:SetPlaybackRate(now < lurch.til and lurch.rate or 1)
end

local nonsenseFor
hook.Add("Think", "LivingCityStrangeNonsense", function()
    local now = CurTime()
    local st = St()
    local want = st and LC_CL.StrangeThemes[st.theme or ""] and st or nil
    if want ~= nonsenseFor then
        nonsenseFor = want
        if want then MakeFloaters() else ClearFloaters() end
    end
    if nonsenseFor then MoveFloaters(now) MusicWarp(nonsenseFor, now) end
    FaceTick(now)
    Emit(now)
end)

------------------------------------------------------------------------
-- How it looks
------------------------------------------------------------------------

local function Cm(addr, addg, addb, bright, contrast, colour, mulr, mulg, mulb)
    if not DrawColorModify then return end
    DrawColorModify({ ["$pp_colour_addr"] = addr or 0, ["$pp_colour_addg"] = addg or 0, ["$pp_colour_addb"] = addb or 0, ["$pp_colour_brightness"] = bright or 0,
        ["$pp_colour_contrast"] = contrast or 1, ["$pp_colour_colour"] = colour or 1, ["$pp_colour_mulr"] = mulr or 0, ["$pp_colour_mulg"] = mulg or 0, ["$pp_colour_mulb"] = mulb or 0 })
end
-- Where the next big beat is (Dance Marathon): seconds to it, and whether it's on now.
function LC_CL.DanceBeat(st, now)
    if not st or not st.bpm or not st.beat0 then return nil end
    local beat = 60 / st.bpm
    local t = now - st.beat0
    if t < -beat * 4 then return nil end
    local bar = beat * 4
    local into = t % bar
    return bar - into, into < 0.15 or into > bar - 0.05, math.floor(t / beat)
end

hook.Add("RenderScreenspaceEffects", "LivingCityStrangeDreams", function()
    local st = St()
    if not st then return end
    local now = CurTime()
    local intro = st.intro or 0
    if now < intro then -- (dark while the voices echo; it swims up over the last two seconds)
        Cm(0, 0, 0, -math.Clamp((intro - now) / 2, 0, 1), 1, 1)
        return
    end
    local th = st.theme
    if th == "cheese" then
        local flip = (st.flip or 0) > now
        Cm(0.07 * math.sin(now * 1.3), 0.07 * math.sin(now * 1.7 + 2), 0.07 * math.sin(now * 2.1 + 4), 0.02, flip and 1.4 or 1.1,
            flip and -1.6 or (1.9 + 0.7 * math.sin(now * 0.5)), 0.8 * math.sin(now * 0.9), 0.8 * math.sin(now * 1.1 + 1), 0.8 * math.sin(now * 1.3 + 2))
        if DrawMotionBlur then DrawMotionBlur(0.12, 0.7, 0.01) end
        if DrawMaterialOverlay then DrawMaterialOverlay("effects/water_warp01", 0.04 + 0.03 * math.sin(now * 0.7)) end
    elseif th == "flying" then Cm(0, 0.01, 0.04, 0.03, 1.05, 1.2)
    elseif th == "melons" then Cm(0.03, 0.02, 0, 0.02, 1.05, 1.3)
    elseif th == "horse" then
        Cm(0.02, 0, 0.03, -0.08, 1.25, 0.45)
        if st.stunned and DrawBloom then DrawBloom(0.6, 1.2, 9, 9, 1, 1, 1, 1, 1) end
    elseif th == "molasses" then
        Cm(0.06, 0.03, 0, -0.02, 1.1, 0.35)
        if DrawMotionBlur then DrawMotionBlur(0.05, 0.9, 0.02) end
    elseif th == "boxing" then Cm(0.02, 0.015, 0, 0, 1.15, 1.1)
    elseif th == "dance" then
        local _, on = LC_CL.DanceBeat(st, now)
        Cm(on and 0.08 or 0, 0, on and 0.06 or 0.02, on and 0.06 or 0, 1.1, 1.5)
    elseif th == "sheep" then Cm(0, 0, 0.05, -0.05, 1, 0.7)
    elseif th == "exam" then Cm(0.02, 0.02, 0, 0, 1.05, 0.8)
    elseif th == "train" then Cm(0, 0.01, 0.02, -0.02, 1.1, 0.6)
    elseif th == "clocks" then
        Cm(0.05 * math.sin(now * 0.7), 0.03, 0.05 * math.cos(now * 0.5), 0, 1.1, 1.4 + 0.4 * math.sin(now * 0.3))
        if DrawMaterialOverlay then DrawMaterialOverlay("effects/water_warp01", 0.03 + 0.02 * math.sin(now * 0.4)) end
    elseif th == "tea" then Cm(0.05, 0.02, 0.05, 0.04, 1, 1.3, 0.2 * math.sin(now), 0, 0.2 * math.cos(now))
    elseif th == "derby" then Cm(0.03, 0.02, 0, 0, 1.1, 1.3)
    elseif th == "photo" then Cm(0, 0, 0, 0, 1.2, 0.6 + 0.4 * math.abs(math.sin(now * 0.5)))
    elseif th == "doors" then Cm(0.04, 0, 0.06, -0.04, 1.1, 1.2)
    elseif th == "paint" then Cm(0, 0, 0, 0.02, 1.15, 2.0)
    elseif th == "conga" then Cm(0.04, 0.02, 0.02, 0.02, 1.05, 1.6, 0.3 * math.sin(now * 2), 0.3 * math.sin(now * 2 + 2), 0.3 * math.sin(now * 2 + 4))
    elseif th == "shh" then Cm(0.02, 0, 0.03, 0, 1, 1.1 - math.min(0.8, (st.noise or 0) / 120))
    elseif th == "bubbles" then Cm(0.03, 0.02, 0.05, 0.04, 1, 1.4)
    elseif th == "watchers" then Cm(0, 0, 0, -0.12, 1.3, 0.15)
    end
    if LC_CL.StrangeThemes[th or ""] and th ~= "cheese" and th ~= "watchers" and th ~= "molasses" and DrawSharpen then DrawSharpen(0.6 + 0.4 * math.sin(now * 0.8), 1) end
end)

local function EntOf(i) local e = i and Entity and Entity(i) return IsValid(e) and e or nil end
local RED, GOLD = Color(255, 30, 20), Color(255, 210, 80)

hook.Add("PostDrawTranslucentRenderables", "LivingCityStrangeDreams", function(_, sky)
    local st = St()
    if sky or not st then return end
    local now = CurTime()
    local th = st.theme
    DrawFx(now)
    render.SetMaterial(glow)
    if anchor and LC_CL.StrangeThemes[th or ""] and th ~= "watchers" then -- (rainbow swirls in the sky, in every strange dream)
        for i = 1, 30 do
            local a = i * 0.45 + now * 0.15
            local r = 200 + i * 45
            render.DrawSprite(anchor + Vector(math.cos(a) * r, math.sin(a) * r, 1400 + math.sin(now + i) * 80), 300, 300, Rainbow(now * 0.05 + i / 30, 70))
        end
    end
    if th == "bubbles" then -- (each bubble, rising and swaying)
        for _, b in ipairs(st.bubbles or {}) do
            local t = now - (b[4] or now)
            local p = Vector(b[1] + math.sin(t * 1.3 + b[1]) * 30, b[2] + math.cos(t * 1.1 + b[2]) * 30, b[3] + t * (st.rise or 45))
            local big = b[5] == 3
            local c = b[5] == 2 and GOLD or (big and Color(230, 245, 255, 120) or Rainbow(b[1] * 0.001 + now * 0.1, 170))
            local sz = big and 150 or 100 -- (the owner, 12 November: bigger, so it's clear which ones count)
            render.DrawSprite(p, sz, sz, c)
            render.DrawSprite(p + Vector(0, 0, sz * 0.2), sz * 0.25, sz * 0.25, Color(255, 255, 255, 200))
        end
    elseif th == "watchers" then -- (their red eyes)
        for _, i in ipairs(st.watchers or {}) do
            local e = EntOf(i)
            if e then
                local sc = e.GetModelScale and e:GetModelScale() or 1
                local fwd, side = e:GetAngles():Forward(), e:GetAngles():Right()
                local head = e:GetPos() + Vector(0, 0, 66 * sc) + fwd * 5 * sc
                render.DrawSprite(head + side * 2.5 * sc, 10 * sc, 10 * sc, RED)
                render.DrawSprite(head - side * 2.5 * sc, 10 * sc, 10 * sc, RED)
            end
        end
    elseif th == "conga" then -- (a rainbow trail behind every dancer)
        for k, i in ipairs(st.conga or {}) do
            local e = EntOf(i)
            if e then render.DrawSprite(e:GetPos() + Vector(0, 0, 20), 90, 90, Rainbow(now * 0.4 + k / 7, 150)) end
        end
    elseif th == "shh" then -- (Zzz over the crib, unless it's crying)
        local me = LocalPlayer()
        if not st.crying and IsValid(me) and anchor then
            for i = 1, 3 do
                local f = (now * 0.3 + i / 3) % 1
                render.DrawSprite(anchor + Vector(math.sin(i + now) * 40, 0, 200 + f * 200), 30 * (1 - f) + 10, 30 * (1 - f) + 10, Color(200, 220, 255, math.floor(200 * (1 - f))))
            end
        end
    end
    if th == "cheese" and now >= (st.intro or 0) then -- (rainbow sparks drifting round you)
        local me = LocalPlayer()
        if not IsValid(me) then return end
        local at = me:GetPos()
        for i = 1, 24 do
            local a = i * 0.9 + now * (0.2 + (i % 5) * 0.05)
            local r = 120 + (i * 37) % 260
            local p = at + Vector(math.cos(a) * r, math.sin(a) * r, 30 + ((i * 53) % 220) + math.sin(now * 2 + i) * 30)
            local sz = 18 + 10 * math.sin(now * 3 + i)
            render.DrawSprite(p, sz, sz, Rainbow(now * 0.2 + i / 24, 200))
        end
    elseif th == "flying" then
        local ea = EyeAngles and EyeAngles() or Angle(0, 0, 0)
        local right, up = ea:Right(), ea:Up()
        local pulse = 0.85 + 0.15 * math.sin(now * 4)
        for _, r in ipairs(st.rings or {}) do -- (each ring faces you)
            local c = Vector(r[1], r[2], r[3])
            for i = 1, 20 do
                local a = i / 20 * math.pi * 2 + now
                render.DrawSprite(c + right * math.cos(a) * 70 + up * math.sin(a) * 70, 26 * pulse, 26 * pulse, GOLD)
            end
            render.DrawSprite(c, 60, 60, Color(255, 240, 180, 80))
        end
        local ctr = st.center
        if ctr then -- (clouds)
            for i = 1, 14 do
                local a = i * 2.4 + now * 0.02
                local d = 300 + (i * 97) % 900
                local h = (st.ceiling or (ctr[3] + 800)) - ctr[3]
                render.DrawSprite(Vector(ctr[1] + math.cos(a) * d, ctr[2] + math.sin(a) * d, ctr[3] + h * (0.35 + ((i * 31) % 60) / 100)), 420, 260, Color(255, 255, 255, 50))
            end
        end
    elseif th == "horse" then -- (its red eyes; a flash as the shot hits)
        local e = EntOf(st.horse)
        if e then
            local sc = e.GetModelScale and e:GetModelScale() or 1
            local mx = e.OBBMaxs and e:OBBMaxs() or Vector(60, 10, 150)
            local fwd, side = e:GetAngles():Forward(), e:GetAngles():Right()
            local head = e:GetPos() + Vector(0, 0, mx.z * sc * 0.85) + fwd * mx.x * sc * 0.75
            local f = 0.8 + 0.2 * math.sin(now * 9)
            render.DrawSprite(head + side * 8, 22 * f, 22 * f, RED)
            render.DrawSprite(head - side * 8, 22 * f, 22 * f, RED)
            if st.stunned then render.DrawSprite(head, 160, 160, Color(255, 230, 190, 120)) end
        end
    elseif th == "boxing" and st.ring then -- (the ropes, a spotlight, and a red glow as it winds up)
        local x, y, z, r = st.ring[1], st.ring[2], st.ring[3], st.ring[4]
        local corners = { Vector(x - r, y - r, z), Vector(x + r, y - r, z), Vector(x + r, y + r, z), Vector(x - r, y + r, z) }
        local cols = { Color(220, 30, 30), Color(240, 240, 240), Color(40, 70, 220) }
        render.SetMaterial(beam)
        for k, h in ipairs({ 32, 52, 72 }) do
            for i = 1, 4 do
                local a, b = corners[i], corners[i % 4 + 1]
                render.DrawBeam(a + Vector(0, 0, h), b + Vector(0, 0, h), 3, 0, 1, cols[k])
            end
        end
        render.SetMaterial(glow)
        render.DrawSprite(Vector(x, y, z + 300), 300, 300, Color(255, 250, 220, 60))
        local foe = EntOf(st.foe)
        if foe and st.windup then render.DrawSprite(foe:GetPos() + Vector(0, 0, 10), 320, 320, Color(255, 30, 30, 160)) end
    elseif th == "potato" then
        local e = EntOf(st.nade)
        if e then
            local f = 0.6 + 0.4 * math.abs(math.sin(now * 8))
            render.DrawSprite(e:GetPos(), 70 * f, 70 * f, RED)
        end
    elseif th == "train" then
        local e = EntOf(st.door)
        if e then render.DrawSprite(e:GetPos() + Vector(0, 0, 60), 180, 220, Color(255, 230, 150, st.watched and 60 or 140)) end
    elseif th == "dance" then -- (the lights, on the beat)
        local _, on, beat = LC_CL.DanceBeat(st, now)
        local me = LocalPlayer()
        if beat and IsValid(me) then
            local at = me:GetPos()
            for i = 1, 12 do
                local a = i / 12 * math.pi * 2 + (beat or 0) * 0.5
                local c = Rainbow(i / 12 + (beat or 0) * 0.1, on and 255 or 120)
                render.DrawSprite(at + Vector(math.cos(a) * 300, math.sin(a) * 300, 220), on and 120 or 60, on and 120 or 60, c)
            end
        end
    elseif th == "sheep" then -- (stars)
        local me = LocalPlayer()
        if IsValid(me) then
            local at = me:GetPos()
            for i = 1, 30 do
                local p = at + Vector(((i * 137) % 1600) - 800, ((i * 251) % 1600) - 800, 700 + (i * 53) % 300)
                local tw = 0.6 + 0.4 * math.sin(now * 2 + i)
                render.DrawSprite(p, 14 * tw, 14 * tw, Color(255, 255, 230, 200))
            end
        end
    end
end)

-- The words in the dark, and the big beat.
hook.Add("HUDPaint", "LivingCityStrangeDreams", function()
    local st = St()
    if not st then return end
    local now = CurTime()
    local intro = st.intro or 0
    if now < intro then
        local secs = st.introSecs or 9
        local t = now - (intro - secs)
        local a = math.floor(255 * math.Clamp(math.min(t / 1.5, (intro - now) / 1.5), 0, 1))
        local texts = st.introText or { "..." }
        local text = texts[math.Clamp(math.floor(t / (secs / #texts)) + 1, 1, #texts)]
        local x = ScrW() / 2 + math.sin(now * 2) * 12
        local y = ScrH() * 0.45 + math.cos(now * 1.6) * 8
        local col = st.theme == "horse" and Color(200, 30, 30, a) or Rainbow(now * 0.15, a)
        draw.SimpleTextOutlined(text, "DermaLarge", x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, a))
        return
    end
    if st.theme == "photo" and st.flash and now - st.flash < 0.8 then -- (the flash)
        surface.SetDrawColor(255, 255, 255, math.floor(255 * (1 - (now - st.flash) / 0.8)))
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    if st.theme == "shh" and (st.noise or 0) > 30 then -- (the baby stirring: the edges go red)
        local a = math.floor(math.min(120, (st.noise - 30) * 1.7) * (0.7 + 0.3 * math.sin(now * 6)))
        surface.SetDrawColor(200, 0, 0, a)
        surface.DrawRect(0, 0, ScrW(), 40) surface.DrawRect(0, ScrH() - 40, ScrW(), 40)
        surface.DrawRect(0, 0, 40, ScrH()) surface.DrawRect(ScrW() - 40, 0, 40, ScrH())
    end
    if st.theme == "dance" then -- (a ring closing in on the big beat)
        local left, on = LC_CL.DanceBeat(st, now)
        if left then
            local r = math.floor(30 + left * 90)
            local cx, cy = ScrW() / 2, ScrH() * 0.62
            surface.SetDrawColor(255, 255, 255, on and 255 or 140)
            for i = 0, 35 do
                local a1, a2 = i / 36 * math.pi * 2, (i + 1) / 36 * math.pi * 2
                surface.DrawLine(cx + math.cos(a1) * r, cy + math.sin(a1) * r, cx + math.cos(a2) * r, cy + math.sin(a2) * r)
            end
            if on then draw.SimpleTextOutlined("JUMP!", "DermaLarge", cx, cy, Color(255, 120, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220)) end
        end
    end
end)
