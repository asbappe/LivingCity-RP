--[[
    Living City: The Battle Line, a propaganda dream (sv_livingcity_battleline.lua)

    The owner, 8 November: "glowing red and evil looking rebels are swarming a combine battle line
    with an APC and barricades, and the dreamers are expected to help shoot and kill the rebels;
    shooting at the combine unleashes a huge swarm of man hacks that target only the player that
    shot the combine." Built 9 November, with the owner's additions that day: the hopeless last
    charge and the rescue from the air, traitors turned into tiny rebels, and five minutes at most.

    On her tablet under Happy as "Propaganda: The Battle Line", like the others (built at the dream
    point out of plain props, not skippable, an offence costs loyalty as you wake). Each dreamer is
    handed a pulse rifle (the dream's only: what they carried comes back as they wake) and stands
    behind the barricades beside her soldiers and an APC. Glowing red rebels pour across the field
    (LC.BattleLineTimes); now and then a giant one that takes a lot of shooting.
      - A rebel you shoot falls (LC.BattleLineShot: the bullet's line, the dream's figures aren't
        solid). Her soldiers and the APC fire too, but not enough on their own.
      - A rebel who reaches the line hurts the nearest dreamer; low on health, a life is gone.
      - Fire on her soldiers or the APC and it's an offence (a life and loyalty points), she calls
        you a traitor, and a swarm of manhacks comes for you alone. If they cut you down you're
        one of them (LC.BattleLineTurn): a tiny glowing red rebel, half size, no gun, your voice
        lines squeaking, put back among the rebels at the far end and driven at the line, shot
        down there (or by the dreamers) and put back again, over and over, till the dream ends.
      - Dreamers can't hurt each other.
    When the battle should be over, every rebel comes back as a massive swarm of giants
    (LC.BattleLineDoomWave: 20 twice the size up to one seven times), in metal or raw flesh,
    glowing red, and charges: all hope looks lost. Three times the size and bigger, bullets bounce
    off them; only the gunships and the bombs bring them down (health 10 x size squared). Then her gunships and an attack
    helicopter sweep in; the gunships cut them down and the helicopter carpet-bombs the field
    (LC.BattleLineBombs). The line held: won, and the board says who shot the most.
    The whole dream is at most five minutes (def.secs; about two and a half as timed).

    Music: battleline (or propaganda) in sound/livingcity/dreams/; voices in dreams/voice/, named
    for the line (battleline_hello and the rest, LC.PropagandaCues).
]]

if CLIENT then return end

LC = LC or {}

local K, P, G = LC.DreamGameKit, LC.PropagandaKit, LC.DreamGames
if not K or not P or not G or not LC.PropagandaVillain then return end
local Block, Actor, Snd, Done = K.Block, K.Actor, K.Snd, K.Done
local Line, Starts, Spawn, Offend, Notice, HerEnt = P.Line, P.Starts, P.Spawn, P.Offend, P.Notice, P.HerEnt
local Villain = LC.PropagandaVillain

local ID = "battleline"
-- (the owner, 12 November: "paced out to last a tad longer": the doom's giants come in over a few seconds, not all
-- at once (LC.BattleLineDoomEvery); her air comes once they're about half way across (LC.BattleLineAirAt), or after
-- doom seconds at the latest; the bombs fall slower, and the rescue may take up to rescue seconds)
LC.BattleLineTimes = { calm = 6, battle = 110, doom = 30, rescue = 45, victory = 4 }
LC.BattleLineDoomEvery, LC.BattleLineAirAt, LC.BattleLineBombEvery = 0.2, 0.5, 0.3
-- Their pace: a usual run, whatever the size of the field (it's the whole dream zone now: LC.BattleLineField).
LC.BattleLineRun = { rebel = 230, giant = 200, doom = 180 }
LC.BattleLineWidest = 3000 -- (the field across: the whole zone's length, but no wider than this, so a line can hold it)
local T = LC.BattleLineTimes
local def = { id = ID, name = "The Battle Line", mood = "happy", secs = 240, lives = 3, music = { ID, "propaganda" },
    goal = "The terrorists are coming! Shoot the red rebels before they reach the line. Never fire on her soldiers.",
    timeUp = { "The guns fall silent", "The field goes quiet, and you wake." } }
G[ID] = def
LC.PropagandaDreams[ID] = true
if LC.PropagandaMore then LC.PropagandaMore[#LC.PropagandaMore + 1] = ID end
LC.DreamGameOrder[#LC.DreamGameOrder + 1] = ID
LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = ID

local LINES = {
    battleline_hello = { "The Administrator", "My brave citizens! The terrorists are coming. Take up arms beside my soldiers and hold the line!" },
    battleline_giant = { "The Administrator", "Look at the size of that one! Everyone, fire!" },
    battleline_traitor = { "The Administrator", "You fired on MY soldiers? Manhacks! Deal with this traitor." },
    battleline_turned = { "The Administrator", "A traitor wants to be a rebel? Then be one. Forever." },
    battleline_doom = { "Overwatch", "Sector overrun. Hostiles beyond containment. Requesting immediate air support." },
    battleline_air = { "The Administrator", "Did you think I would abandon you? Behold my wings!" },
    battleline_held = { "The Administrator", "The line held! Every one of you is a hero of my city." },
}
LC.PropagandaCueWho = LC.PropagandaCueWho or {}
for k, v in pairs(LINES) do LC.PropagandaCues[k], LC.PropagandaCueWho[k] = v[2], v[1] end
LC.BattleLineTaunts = { "Free City Seventeen!", "Down with the Combine!", "Charge! Charge!", "For the Resistance!", "Lambda! Lambda!" }

LC.BattleLineMost = 16           -- (rebels on the field at once)
LC.BattleLineHurt = 15           -- (a rebel at the line: health off the nearest dreamer)
LC.BattleLineLow = 30            -- (at or under this, a life is gone)
LC.BattleLineHacks = 10          -- (manhacks in a traitor's swarm)
LC.BattleLineHackHurt = 6
-- (the last charge, a massive swarm, the owner: 20 twice the size, 12 three times, 6 four, 3 five, 2 six and 1 seven times)
LC.BattleLineDoomWave = { { 2, 20 }, { 3, 12 }, { 4, 6 }, { 5, 3 }, { 6, 2 }, { 7, 1 } }
LC.BattleLineImmuneFrom = 3     -- (this size and up: the dreamers' bullets do nothing)
LC.BattleLineDoom = 0
for _, w in ipairs(LC.BattleLineDoomWave) do LC.BattleLineDoom = LC.BattleLineDoom + w[2] end
LC.BattleLineBombs = 36          -- (the helicopter's carpet of bombs)
LC.BattleLineTraitorPitch = 170  -- (a turned traitor's voice lines)
LC.BattleLineGun, LC.BattleLineAmmo = "weapon_ar2", "AR2"
local SOLDIER = "models/combine_soldier.mdl"
local APC = { "models/combine_apc.mdl", "models/props_vehicles/apc001.mdl" }
local BARRICADES = { "models/props_combine/combine_barricade_short01a.mdl", "models/props_c17/concrete_barrier001a.mdl" }
local HACK, GUNSHIP, CHOPPER, BOMB = "models/manhack.mdl", "models/gunship.mdl", "models/combine_helicopter.mdl", "models/combine_helicopter/helicopter_bomb01.mdl"
local SKINS = { "models/flesh", "debug/env_cubemap_model" } -- (raw flesh, or metal)
local RED = Color(255, 40, 40)

local function SayAs(g, cue)
    local snd, text = LC.PropagandaVoice(cue)
    g.said = g.said or {}
    g.said[#g.said + 1] = cue
    Line(g, text, snd, LC.PropagandaCueWho[cue])
end
local function FirstModel(list) for _, m in ipairs(list) do if K.ValidModel(m) then return m end end return list[#list] end
local function Scale(e) return e.GetModelScale and e:GetModelScale() or 1 end
local function Center(e, h) return e:GetPos() + Vector(0, 0, (h or 40) * Scale(e)) end
local function Turned(g, p) local s = g.pl[p] return s ~= nil and s.turned == true end
-- The dreamers still fighting (not turned).
local function Fighters(g, players)
    local out = {}
    for _, p in ipairs(players) do if not Turned(g, p) then out[#out + 1] = p end end
    return out
end

-- (the dream's own rifle: let through by LC.DreamGive, sv_livingcity_dreams.lua; taken back as they wake with their own things)
local function Arm(p)
    if not IsValid(p) or not p.Give or (p.HasWeapon and p:HasWeapon(LC.BattleLineGun)) then return end
    if LC.DreamGive then LC.DreamGive(p, LC.BattleLineGun) else p:Give(LC.BattleLineGun) end
    if p.GiveAmmo then p:GiveAmmo(900, LC.BattleLineAmmo, true) end
    if p.SelectWeapon then p:SelectWeapon(LC.BattleLineGun) end
end

function def.spawn(g, p, i)
    local at, yaw = Spawn(g, p, i)
    Arm(p)
    return at, yaw
end

-- The field: the whole dream zone, on the map's own floor under the dream point (the owner, 12 November: "have
-- the zone expand to the entire area"). x0, x1, y0, y1, the floor's height; nil: no zone or no floor there (then
-- the dream builds its own small floor, as it did before).
function LC.BattleLineField(dream)
    local z, c = dream.zone, dream.pos
    if not (z and z.box and z.box.mins and z.box.maxs) then return nil end
    local tr = util.TraceLine({ start = c + Vector(0, 0, 40), endpos = c - Vector(0, 0, 300), mask = MASK_SOLID_BRUSHONLY })
    if not (tr and tr.Hit and not tr.StartSolid and tr.HitPos) then return nil end
    local b = z.box
    local x0, x1 = b.mins.x + 80, b.maxs.x - 80
    local half = math.min(LC.BattleLineWidest / 2, (b.maxs.y - b.mins.y) / 2 - 80)
    if x1 - x0 < 1200 or half < 300 then return nil end -- (smaller than the dream's own floor: that instead)
    local cy = math.Clamp(c.y, b.mins.y + 80 + half, b.maxs.y - 80 - half)
    return x0, x1, cy - half, cy + half, tr.HitPos.z + 2
end

function def.build(g, dream)
    local c = dream.pos
    local x0, x1, top
    local fx0, fx1, fy0, fy1, ftop = LC.BattleLineField(dream)
    if fx0 then
        x0, x1, top = fx0, fx1, ftop
        g.top = top
        g.x0, g.x1, g.y0, g.y1 = x0, x1, fy0, fy1
        g.bounds = { mins = Vector(x0 - 60, fy0 - 60, top - 160), maxs = Vector(x1 + 60, fy1 + 60, top + 1200) }
        g.wide = true
    else
        x0, x1, top = P.Hall(g, dream, 3, Color(70, 62, 52))
        g.x0, g.x1, g.y0, g.y1 = x0, x1, c.y - K.PLATE8_S + 40, c.y + K.PLATE8_S - 40
    end
    local cy = (g.y0 + g.y1) / 2
    g.lineX = x0 + 300 -- (the barricades: the rebels must not get past here)
    local bm = FirstModel(BARRICADES)
    local n = math.max(3, math.floor((g.y1 - g.y0) / 140))
    for i = 0, n - 1 do
        local y = g.y0 + (i + 0.5) * (g.y1 - g.y0) / n
        if K.ValidModel(bm) then Block(g, bm, Vector(g.lineX, y, top), Angle(0, 0, 0), Color(150, 150, 160)) end
    end
    g.soldiers = {}
    for i = 0, 5 do
        local at = Vector(g.lineX - 50, g.y0 + 60 + i * (g.y1 - g.y0 - 120) / 5, top)
        local e = Actor(g, SOLDIER, at, 0, 1, ACT_IDLE_ANGRY or ACT_IDLE or 1)
        if e then
            g.soldiers[#g.soldiers + 1] = { e = e, next = CurTime() + T.calm + math.Rand(1, 3) }
            LC.BattleLineHolding(g, e) -- (a rifle in their hands: the owner saw them firing with none)
        end
    end
    g.apc = Actor(g, FirstModel(APC), Vector(g.lineX - 180, cy, top), 0, 1)
    local z = dream.zone
    local ceiling = (z and z.box and z.box.maxs.z) or (top + (LC.DreamGameHeadroom and LC.DreamGameHeadroom(dream) or 2000))
    g.airZ = math.max(top + 300, math.min(ceiling - 150, top + 550)) -- (the gunships' height, under the room's ceiling)
    g.rebels, g.hacks, g.air, g.bombs, g.phase, g.kills = {}, {}, {}, {}, "calm", 0
    Starts(g, x0 + 110, cy, top)
    return true
end
-- A pulse rifle in a figure's hands (its world model, merged onto the hand).
function LC.BattleLineHolding(g, e)
    if not IsValid(e) or not ents or not ents.Create then return nil end
    local w = ents.Create("prop_dynamic")
    if not IsValid(w) then return nil end
    w:SetModel("models/weapons/w_irifle.mdl")
    w:SetPos(e:GetPos())
    w:Spawn()
    if w.SetNotSolid then w:SetNotSolid(true) end
    if w.SetParent then w:SetParent(e) end
    if w.AddEffects then w:AddEffects(EF_BONEMERGE or 1) end
    g.ents[#g.ents + 1] = w
    return w
end

function def.hello(g)
    g.song = LC.PropagandaSong(def.music)
    timer.Simple(2, function() if g and not g.stopped then SayAs(g, "battleline_hello") end end)
    return { theme = "propaganda", song = g.song, herEnt = HerEnt and HerEnt(g) or nil }
end

-- A rebel at the far end. kind: nil, "giant" (now and then) or "doom" (the last charge, size times as big).
local function NewRebel(g, kind, y, size)
    y = y or math.Rand(g.y0 + 30, g.y1 - 30)
    local at = Vector(g.x1 - 40 - (kind == "doom" and math.Rand(0, 220) or 0), y, g.top)
    local scale = (kind == "doom" and (size or 3)) or (kind == "giant" and 2.6) or 1
    local e = Villain(g, LC.PropagandaRebels, at, 180, scale)
    if not e then return nil end
    if kind == "doom" and e.SetMaterial then e:SetMaterial(SKINS[math.random(#SKINS)]) e:SetColor(RED) end
    if K.Animate then K.Animate(e, ACT_RUN or 1) end
    -- (the field's as long as the dream point's room allows: a charge takes 11 to 16 seconds across it, a giant 25, the last charge 30)
    local run = math.max(200, g.x1 - 40 - g.lineX)
    -- (a usual run: the owner, 12 November, "have the rebels run at usual/normal speed"; on the small floor, as before)
    local pace = (kind == "doom" and (LC.BattleLineRun.doom + 10 * scale)) or (kind == "giant" and LC.BattleLineRun.giant) or LC.BattleLineRun.rebel * math.Rand(0.9, 1.1)
    local secs = g.wide and (run / pace) or ((kind == "doom" and (28 + scale)) or (kind == "giant" and 25) or math.Rand(11, 16))
    -- (the owner: health to match their size, 10 x size squared: 40 at twice the size up to 490 at seven times;
    -- three times and bigger, only her gunships and the helicopter's bombs can bring them down)
    local m = { e = e, alive = true, hp = (kind == "doom" and 10 * scale * scale) or (kind == "giant" and 10) or 1,
        immune = (kind == "doom" and scale >= LC.BattleLineImmuneFrom) or nil, giant = kind == "giant" or nil, doom = kind == "doom" or nil,
        speed = run / secs, y = y, x0 = at.x }
    g.rebels[#g.rebels + 1] = m
    return m
end
LC.BattleLineNewRebel = NewRebel

local function Alive(g) local n = 0 for _, m in ipairs(g.rebels) do if m.alive and IsValid(m.e) then n = n + 1 end end return n end
LC.BattleLineAlive = Alive
-- How far the last charge has come: the furthest giant's share of the way from where it began to the line (0 to 1;
-- 1 when none are left standing).
function LC.BattleLineAdvance(g)
    local best, any = 0, false
    for _, m in ipairs(g.rebels) do
        if m.doom and m.alive and IsValid(m.e) then
            any = true
            local run = math.max(1, (m.x0 or g.x1) - g.lineX)
            best = math.max(best, math.Clamp(((m.x0 or g.x1) - m.e:GetPos().x) / run, 0, 1))
        end
    end
    return any and best or 1
end

-- A shot's streak, drawn on the dreamers' screens for a moment (cl_livingcity_dreamgames.lua): never a game effect
-- that might outlive the dream (the owner, 12 November: the trails "never went away").
local function Tracer(from, to, kind)
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped or not K.Send then return end
    K.Send(g, { k = "tracer", a = { math.floor(from.x), math.floor(from.y), math.floor(from.z) }, b = { math.floor(to.x), math.floor(to.y), math.floor(to.z) },
        heavy = kind == "AirboatGunHeavyTracer" or nil })
end
LC.BattleLineTracer = Tracer

-- A rebel goes down (by: who or what fired, for the tracer).
local function Fall(g, m, by)
    m.alive = false
    g.dirty = true
    if IsValid(m.e) then
        local pos = Center(m.e)
        if IsValid(by) then Tracer(Center(by, 50), pos) end
        if EffectData then local ed = EffectData() ed:SetOrigin(pos) util.Effect("BloodImpact", ed, true, true) end
        Snd(m.e, "npc/combine_soldier/die" .. math.random(1, 3) .. ".wav", 70, m.doom and 50 or 70)
        m.e:Remove()
    end
end

-- Health off a dreamer; at LC.BattleLineLow or under, a life (and their health back for the next).
local function Hurt(g, p, n, title, text)
    local s = g.pl[p]
    if not s or s.done or s.turned or CurTime() < (s.safe or 0) then return false end
    p:SetHealth(math.max(1, p:Health() - n)) -- (in the dream; it's all put back on waking)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(160, 0, 0, 150), 0.4, 0.05) end
    g.dirty = true
    if p:Health() <= LC.BattleLineLow then
        LC.DreamGameHit(g, p, title, text)
        if not g.pl[p].done then p:SetHealth(p.GetMaxHealth and p:GetMaxHealth() or 100) end
        return true
    end
    return false
end

-- A traitor's swarm: manhacks round the APC, after p alone.
local function Swarm(g, p)
    local from = IsValid(g.apc) and g.apc:GetPos() or Vector(g.lineX - 150, (g.y0 + g.y1) / 2, g.top)
    for i = 1, LC.BattleLineHacks do
        local a = i / LC.BattleLineHacks * math.pi * 2
        local e = Actor(g, HACK, from + Vector(math.cos(a) * 80, math.sin(a) * 80, 90), 0, 1)
        if e then g.hacks[#g.hacks + 1] = { e = e, target = p, speed = math.Rand(240, 320), next = 0 } end
    end
    -- (on a manhack, not on the dreamer: it's a loop, and on a player it never stopped; it goes with the manhack)
    local h = g.hacks[#g.hacks]
    if h and IsValid(h.e) then Snd(h.e, "npc/manhack/mh_engine_loop1.wav", 80) end
end

-- Back among the rebels at the far end.
local function Respawn(g, p)
    local s = g.pl[p]
    p:SetPos(Vector(g.x1 - 60, math.Rand(g.y0 + 40, g.y1 - 40), g.top + 4))
    if p.SetEyeAngles then p:SetEyeAngles(Angle(0, 180, 0)) end
    p:SetHealth(p.GetMaxHealth and p:GetMaxHealth() or 100)
    if s then s.safe = CurTime() + 1 end
end
-- A turned traitor goes down (shot at the line, or by a dreamer), and is put back to charge again.
local function Down(g, p, by)
    if IsValid(by) then Tracer(Center(by, 50), p:GetPos() + Vector(0, 0, 20)) end
    Snd(p, "npc/combine_soldier/die" .. math.random(1, 3) .. ".wav", 75, LC.BattleLineTraitorPitch)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(200, 0, 0, 220), 0.8, 0.2) end
    Respawn(g, p)
    g.pl[p].downs = (g.pl[p].downs or 0) + 1
    g.dirty = true
end

-- Cut down by the manhacks: one of them now, till the dream's over.
function LC.BattleLineTurn(g, p)
    local s = g.pl[p]
    if not s or s.done or s.turned then return false end
    s.turned = true
    for _, h in ipairs(g.hacks) do if h.target == p then h.target = nil end end
    p.lcBattleLook = p.lcBattleLook or { model = p.GetModel and p:GetModel() or nil, scale = Scale(p),
        color = p.GetColor and p:GetColor() or nil, mat = p.GetMaterial and p:GetMaterial() or nil }
    if p.StripWeapons then p:StripWeapons() end
    local m = LC.PropagandaRebels[1]
    for _, c in ipairs(LC.PropagandaRebels) do if K.ValidModel(c) then m = c break end end
    if p.SetModel then p:SetModel(m) end
    if p.SetModelScale then p:SetModelScale(0.5, 0) end
    if p.SetColor then p:SetColor(RED) end
    if p.SetMaterial then p:SetMaterial("models/debug/debugwhite") end
    p.lcVoicePitch = LC.BattleLineTraitorPitch
    Respawn(g, p)
    SayAs(g, "battleline_turned")
    Notice(p, "warn", "One of them", "The manhacks cut you down, and you wake up small, red and unarmed among the rebels. Charge the line with them, again and again, till the dream is over.", 10)
    g.dirty = true
    return true
end

-- Their own look back (as they leave the dream; the dream's own restore follows).
function def.leave(g, p)
    local look = p.lcBattleLook
    p.lcVoicePitch = nil
    if not look then return end
    p.lcBattleLook = nil
    if look.model and p.SetModel then p:SetModel(look.model) end
    if p.SetModelScale then p:SetModelScale(look.scale or 1, 0) end
    if look.color and p.SetColor then p:SetColor(look.color) end
    if p.SetMaterial then p:SetMaterial(look.mat or "") end
end

-- Something a dreamer fired, from src along dir: the first figure on the line takes it. What was hit, or nil.
function LC.BattleLineShot(p, src, dir)
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped or g.id ~= ID then return nil end
    local s = g.pl[p]
    local enf = not s and g.enf and g.enf[p] or nil -- (an Enforcer shoots with the rest: the owner, 12 November, "I have no guns as a CP unit")
    if enf then s = enf end
    if not s or s.done or s.turned or g.phase == "calm" then return nil end
    dir = dir:GetNormalized()
    local best, bestT, kind
    local function Try(e, r, h, k, m)
        if not IsValid(e) then return end
        local c = Center(e, h)
        local t = (c - src):Dot(dir)
        if t <= 0 or t > 30000 then return end
        if (src + dir * t - c):Length() <= r * Scale(e) and (not bestT or t < bestT) then best, bestT, kind = m or e, t, k end
    end
    for _, m in ipairs(g.rebels) do if m.alive then Try(m.e, 24, 40, "rebel", m) end end
    for q, qs in pairs(g.pl) do if q ~= p and qs.turned and IsValid(q) then Try(q, 30, 36, "traitor", q) end end
    for _, sd in ipairs(g.soldiers) do Try(sd.e, 20, 40, "combine") end
    Try(g.apc, 110, 50, "combine")
    if kind == "rebel" and best.immune then
        Snd(best.e, "weapons/fx/rics/ric" .. math.random(1, 5) .. ".wav", 80) -- (it bounces off)
        return "immune"
    elseif kind == "rebel" then
        best.hp = best.hp - 1
        if best.hp <= 0 then
            Fall(g, best, p)
            s.kills = (s.kills or 0) + 1
            g.kills = g.kills + 1
        else
            Snd(best.e, "physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav", 75)
        end
        return "rebel"
    elseif kind == "traitor" then
        if not enf and CurTime() >= (g.pl[best].safe or 0) then
            Down(g, best, p)
            s.kills = (s.kills or 0) + 1
            g.kills = g.kills + 1
        end
        return "traitor"
    elseif kind == "combine" then
        if enf then return "combine" end -- (nothing in it touches an Enforcer)
        if (s.traitorAt or 0) > CurTime() then return "combine" end -- (one burst is one offence)
        s.traitorAt = CurTime() + 3
        SayAs(g, "battleline_traitor")
        Swarm(g, p)
        Offend(g, p, "Traitor", "You fired on her soldiers.")
        return "combine"
    end
    return nil
end

hook.Add("EntityFireBullets", "LivingCityBattleLine", function(ent, data)
    if not IsValid(ent) or not ent:IsPlayer() or ent.lcDreamGame ~= ID or not data then return end
    if data.Src and data.Dir then LC.Try(LC.BattleLineShot, ent, data.Src, data.Dir) end
end)
-- (dreamers can't hurt each other in it)
hook.Add("EntityTakeDamage", "LivingCityBattleLine", function(victim, dmg)
    if not IsValid(victim) then return end
    local a = dmg:GetAttacker()
    -- (the dream's rifle hurts nothing in the waking world: a city NPC wandering by, a door, a prop)
    if IsValid(a) and a.IsPlayer and a:IsPlayer() and a.lcDreamGame == ID and not (victim.IsPlayer and victim:IsPlayer()) then dmg:SetDamage(0) return true end
    if not victim:IsPlayer() or victim.lcDreamGame ~= ID then return end
    if IsValid(a) and a:IsPlayer() then dmg:SetDamage(0) return true end
end)
-- City NPCs wandering onto the field are sent off it (the owner, 12 November: "the citizen NPCs were just running in front
-- of me"); the dreamers' screens don't show them there either (cl_livingcity_dreamgames.lua).
function LC.BattleLineClearField(g)
    local b = g.bounds
    if not b or not ents.FindInBox then return 0 end
    local n = 0
    local dream = g.dream
    for _, e in ipairs(ents.FindInBox(b.mins, b.maxs)) do
        if IsValid(e) and e.IsNPC and e:IsNPC() and not (dream.made and dream.made[e]) then
            local pos = e:GetPos()
            local outY = (pos.y - g.y0 < g.y1 - pos.y) and (g.y0 - 400) or (g.y1 + 400)
            if e.SetLastPosition and e.SetSchedule then
                e:SetLastPosition(Vector(pos.x, outY, pos.z))
                e:SetSchedule(SCHED_FORCED_GO_RUN or 71)
            end
            n = n + 1
        end
    end
    return n
end

local function Toward(e, to, speed, dt, z)
    local pos = e:GetPos()
    local d = Vector(to.x - pos.x, to.y - pos.y, (z and (z - pos.z)) or 0)
    local len = d:Length()
    if len > 1 then
        local step, n = math.min(len, speed * dt), d:GetNormalized()
        e:SetPos(pos + n * step)
        e:SetAngles(Angle(0, math.deg(math.atan2(n.y, n.x)), 0))
    end
    return len
end

-- The rescue: gunships and an attack helicopter in over the line.
local function AirIn(g, now)
    local mid = (g.y0 + g.y1) / 2
    local spots = { { GUNSHIP, -260 }, { GUNSHIP, 0 }, { GUNSHIP, 260 }, { CHOPPER, 0, true } }
    for i, sp in ipairs(spots) do
        local from = Vector(g.x0 - 300, mid + sp[2], g.airZ + 200)
        local hover = Vector(sp[3] and (g.lineX + (g.x1 - g.lineX) * 0.25) or (g.lineX + 120), mid + sp[2], g.airZ + (sp[3] and 60 or 0))
        local e = Actor(g, sp[1], from, 0, sp[3] and 1 or 0.8)
        if e then g.air[#g.air + 1] = { e = e, hover = hover, chopper = sp[3] or nil, next = now + 1.5 + i * 0.2 } end
    end
    for _, a in ipairs(g.air) do Snd(a.e, a.chopper and "npc/attack_helicopter/aheli_rotor_loop1.wav" or "npc/combine_gunship/engine_whine_loop1.wav", 120) end
end

local function Bomb(g, at)
    local e = Actor(g, BOMB, at, math.random(0, 359), 1)
    if e then g.bombs[#g.bombs + 1] = { e = e, vz = 0 } end
end
local function Blast(g, pos)
    if EffectData then local ed = EffectData() ed:SetOrigin(pos) util.Effect("Explosion", ed, true, true) end
    if K.Puff then K.Puff(pos) end
    if sound and sound.Play then sound.Play("ambient/explosions/explode_" .. math.random(1, 4) .. ".wav", pos, 110) end
    for _, m in ipairs(g.rebels) do
        if m.alive and IsValid(m.e) and m.e:GetPos():Distance(pos) < 260 + 30 * Scale(m.e) then Fall(g, m, nil) end
    end
end

function def.tick(g, dt, players)
    local now = CurTime()
    local t = now - g.t0
    local fighters = Fighters(g, players)
    for _, p in ipairs(fighters) do Arm(p) end
    for p in pairs(g.enf or {}) do if IsValid(p) and p.lcDreaming == g.dream.id then Arm(p) end end -- (Enforcers too)
    if now >= (g.clearAt or 0) then
        g.clearAt = now + 1
        local okC, errC = LC.Try(LC.BattleLineClearField, g)
        if not okC and LC.Error then LC.Error("battle line field", errC) end
    end
    if g.phase == "calm" and t >= T.calm then g.phase, g.dirty, g.spawnAt, g.giantAt, g.tauntAt = "battle", true, now, now + 30, now + 3 end
    if g.phase == "battle" then
        local f = math.Clamp((t - T.calm) / T.battle, 0, 1)
        if now >= g.spawnAt and Alive(g) < LC.BattleLineMost then
            NewRebel(g, nil)
            g.spawnAt = now + (2.2 - 1.4 * f) / math.sqrt(math.max(1, #fighters))
        end
        if now >= g.giantAt then NewRebel(g, "giant") SayAs(g, "battleline_giant") g.giantAt = now + 30 end
        if now >= g.tauntAt then
            g.tauntAt = now + math.Rand(8, 12)
            Line(g, LC.BattleLineTaunts[math.random(#LC.BattleLineTaunts)], nil, "The rebels")
        end
        -- when it should be over: they all come back, giants in metal and flesh, and it looks hopeless
        if t >= T.calm + T.battle then
            g.phase, g.dirty, g.doomAt = "doom", true, now
            for _, m in ipairs(g.rebels) do if m.alive then Fall(g, m, nil) end end
            -- (not all in one instant: the owner, 12 November, it "froze my game"; a few every second, the biggest last)
            g.doomQueue, g.doomNext = {}, now
            for _, w in ipairs(LC.BattleLineDoomWave) do
                for _ = 1, w[2] do g.doomQueue[#g.doomQueue + 1] = w[1] end
            end
            SayAs(g, "battleline_doom")
            for _, p in ipairs(players) do if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(120, 0, 0, 180), 2, 0.5) end end
        end
    end
    if g.phase == "doom" and g.doomQueue then
        while #g.doomQueue > 0 and now >= g.doomNext do
            NewRebel(g, "doom", math.Rand(g.y0 + 40, g.y1 - 40), table.remove(g.doomQueue, 1))
            g.doomNext = g.doomNext + LC.BattleLineDoomEvery
        end
    end
    -- her air: once the giants are about half way across (or at the latest after T.doom)
    if g.phase == "doom" and ((#(g.doomQueue or {}) == 0 and LC.BattleLineAdvance(g) >= LC.BattleLineAirAt) or now >= g.doomAt + T.doom) then
        g.phase, g.dirty, g.airAt = "rescue", true, now
        AirIn(g, now)
        SayAs(g, "battleline_air")
    end
    -- the rebels charge; one at the line strikes the nearest dreamer and is gone
    if g.phase == "battle" or g.phase == "doom" or g.phase == "rescue" then
        for _, m in ipairs(g.rebels) do
            if m.alive and IsValid(m.e) then
                Toward(m.e, Vector(g.lineX + 20, m.y, g.top), m.speed, dt)
                if m.e:GetPos().x <= g.lineX + 30 * Scale(m.e) then
                    local best, bd
                    for _, p in ipairs(fighters) do local d = p:GetPos():Distance(m.e:GetPos()) if not bd or d < bd then best, bd = p, d end end
                    if best then Hurt(g, best, LC.BattleLineHurt * ((m.giant or m.doom) and 2 or 1), "The line breaks", "A rebel got through the barricades.") end
                    if K.Puff then K.Puff(m.e:GetPos()) end
                    Fall(g, m, nil)
                end
            end
        end
    end
    -- her soldiers and the APC fire too, not enough on their own
    if g.phase == "battle" then
        for _, sd in ipairs(g.soldiers) do
            if IsValid(sd.e) and now >= sd.next then
                sd.next = now + math.Rand(2.5, 4)
                local reach = g.lineX + (g.x1 - g.lineX) * 0.4 -- (only the near part of the field: the dreamers do most of it)
                local target
                for _, m in ipairs(g.rebels) do if m.alive and IsValid(m.e) and m.e:GetPos().x < reach then target = m break end end
                if target then
                    Snd(sd.e, "weapons/ar2/fire1.wav", 85)
                    target.hp = target.hp - 1
                    if target.hp <= 0 then Fall(g, target, sd.e) end
                end
            end
        end
        if IsValid(g.apc) and now >= (g.apcAt or 0) then
            g.apcAt = now + 3
            for _, m in ipairs(g.rebels) do
                if m.alive and m.giant and IsValid(m.e) then
                    Snd(g.apc, "weapons/ar2/fire1.wav", 95, 70)
                    m.hp = m.hp - 1
                    if m.hp <= 0 then Fall(g, m, g.apc) end
                    break
                end
            end
        end
    end
    -- the turned traitors: driven at the line, shot down there, put back with the rebels
    for _, p in ipairs(players) do
        if Turned(g, p) then
            local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0)
            if p.SetVelocity and v.x > -220 then p:SetVelocity(Vector(-220 - v.x, 0, 0)) end
            if p:GetPos().x > g.x1 - 40 then p:SetPos(Vector(g.x1 - 60, p:GetPos().y, p:GetPos().z)) end -- (no hanging back)
            if p:GetPos().x <= g.lineX + 40 and now >= (g.pl[p].safe or 0) then
                local sd = g.soldiers[math.random(math.max(1, #g.soldiers))]
                Down(g, p, sd and sd.e)
            end
        end
    end
    -- the rescue: gunships cut them down, the helicopter carpet-bombs the field
    if g.phase == "rescue" then
        for _, a in ipairs(g.air) do
            if IsValid(a.e) then
                local left = Toward(a.e, a.hover, 700, dt, a.hover.z)
                a.e:SetAngles(Angle(0, 0, 0))
                if left < 40 and not a.chopper and now >= a.next then
                    a.next = now + 0.5
                    local target
                    for _, m in ipairs(g.rebels) do if m.alive and IsValid(m.e) then target = m break end end
                    if target then
                        Snd(a.e, "weapons/ar2/fire1.wav", 110, 55)
                        Tracer(a.e:GetPos(), Center(target.e), "AirboatGunHeavyTracer")
                        target.hp = target.hp - 10
                        if target.hp <= 0 then Fall(g, target, nil) end
                    end
                elseif left < 40 and a.chopper and not g.bombAt then
                    g.bombAt, g.bombsLeft, g.dirty = now, LC.BattleLineBombs, true
                    Snd(a.e, "npc/attack_helicopter/aheli_megabomb_siren1.wav", 130)
                end
            end
        end
        -- the bomb drop: a carpet of them along the field, from the helicopter as it sweeps across
        local chopper
        for _, a in ipairs(g.air) do if a.chopper and IsValid(a.e) then chopper = a end end
        if g.bombAt and (g.bombsLeft or 0) > 0 and chopper and now >= (g.nextBomb or 0) then
            g.nextBomb = now + LC.BattleLineBombEvery
            g.bombsLeft = g.bombsLeft - 1
            local f = 1 - g.bombsLeft / LC.BattleLineBombs
            chopper.hover = Vector(g.lineX + (g.x1 - g.lineX) * (0.25 + 0.7 * f), chopper.hover.y, chopper.hover.z)
            Bomb(g, chopper.e:GetPos() + Vector(math.Rand(-60, 60), math.Rand(-300, 300), -60))
        end
        for i = #g.bombs, 1, -1 do
            local b = g.bombs[i]
            if not IsValid(b.e) then table.remove(g.bombs, i) else
                b.vz = b.vz - 900 * dt
                local pos = b.e:GetPos()
                local nz = pos.z + b.vz * dt
                if nz <= g.top + 10 then
                    Blast(g, Vector(pos.x, pos.y, g.top))
                    b.e:Remove()
                    table.remove(g.bombs, i)
                else
                    b.e:SetPos(Vector(pos.x, pos.y, nz))
                end
            end
        end
        if (Alive(g) == 0 and #g.bombs == 0 and now >= g.airAt + 3) or now >= g.airAt + T.rescue then
            for _, m in ipairs(g.rebels) do if m.alive then Fall(g, m, nil) end end
            g.phase, g.dirty, g.wonAt = "victory", true, now + T.victory
            SayAs(g, "battleline_held")
        end
    end
    -- the manhacks: after their traitor, until they've cut them down (and then the traitor's one of them)
    for i = #g.hacks, 1, -1 do
        local h = g.hacks[i]
        local p = h.target
        local s = IsValid(p) and g.pl[p]
        if not IsValid(h.e) or not s or s.done or s.turned then
            if IsValid(h.e) then h.e:Remove() end
            table.remove(g.hacks, i)
        else
            h.e:SetAngles(Angle(0, now * 900 % 360, 0))
            local left = Toward(h.e, p:GetPos() + Vector(0, 0, 50), h.speed, dt, p:GetPos().z + 50)
            if left < 50 and now >= h.next and now >= (s.safe or 0) then
                h.next = now + 0.5
                Snd(p, "npc/manhack/grind_flesh" .. math.random(1, 3) .. ".wav", 75)
                if p:Health() - LC.BattleLineHackHurt <= LC.BattleLineLow then
                    LC.BattleLineTurn(g, p)
                else
                    p:SetHealth(p:Health() - LC.BattleLineHackHurt)
                    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(160, 0, 0, 150), 0.4, 0.05) end
                    g.dirty = true
                end
            end
        end
    end
    if g.phase == "victory" and now >= g.wonAt then
        g.wonAt = math.huge
        local top, tn = nil, 0
        for p, s in pairs(g.pl) do if IsValid(p) and not s.turned and (s.kills or 0) > tn then top, tn = p, s.kills end end
        for _, p in ipairs(players) do
            local s = g.pl[p]
            if s.turned then
                Done(g, p, "out", "One of them", "The last rebels burn, and you with them. A traitor, to the very end.")
            else
                local mine = string.format(" You shot %d.", s.kills or 0)
                local best = (top == p and tn > 0) and " The most of anyone: she pins a medal on you herself." or ""
                Done(g, p, "won", "The line held", "Her gunships turn the last of the rebels to ash. Her soldiers cheer, and so do you." .. mine .. best)
            end
        end
    end
end

function def.woke(p, how)
    if how == "won" then Notice(p, "info", "The line held", "You wake with your finger still curled round a trigger, and a warm pride you can't explain. The Combine and you, side by side.", 9)
    elseif how == "out" then Notice(p, "warn", "Cut down", "You wake gasping, with the whine of manhacks or the roar of the charge still in your ears.", 9)
    else Notice(p, "info", "The guns fall silent", "You wake to quiet, and the smell of smoke that isn't there.", 9) end
end

local BIG = { calm = "Her soldiers hold the line. Take up your rifle.", battle = "The rebels are charging! Hold the line!",
    doom = "They're back, and they're GIANTS. All hope is lost...", rescue = "Gunships! She sent her gunships!", victory = "The line held!" }
function def.state(g, p)
    local s = g.pl[p]
    local hacked = false
    for _, h in ipairs(g.hacks) do if h.target == p then hacked = true break end end
    local big = (s and s.turned and "You're one of them now. Charge!") or (hacked and "MANHACKS! You fired on her soldiers!") or BIG[g.phase]
    local red = {}
    for _, m in ipairs(g.rebels) do if m.alive and IsValid(m.e) then red[#red + 1] = m.e:EntIndex() end end
    for q, qs in pairs(g.pl) do if qs.turned and IsValid(q) then red[#red + 1] = q:EntIndex() end end
    return { big = big, tone = (hacked or (s and s.turned) or g.phase == "battle" or g.phase == "doom") and "warn" or "love", villains = #red > 0 and red or nil,
        meterName = g.phase ~= "calm" and string.format("Rebels down: %d (you: %d)", g.kills, s and s.kills or 0) or nil }
end
