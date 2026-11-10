--[[
    Living City (gamemode)

    A Combine-occupied city to live in. Built on Sandbox only so admins keep
    the building tools for editing the city; everything Sandbox gives regular
    players (spawn menu, context menu, props, noclip, physgun, toolgun) is off.
    Admins switch between playing and building with !build (lc_buildmode).

    All of the city itself (NPCs, factions, jobs, quests, survival, prisons,
    contraband...) is in gamemode/modules (shared, server, client), loaded
    below in a fixed order; its entities and weapons are in entities/. It is
    its own gamemode: none of it loads anywhere else.
]]

DeriveGamemode("sandbox")

GM.Name = "Living City"
GM.Author = "Living City"
GM.Email = ""
GM.Website = ""
GM.TeamBased = false

------------------------------------------------------------------------
-- The city's code: every module, in the order it loads (shared first, then
-- the server's or the client's). init.lua and cl_init.lua load them; nothing
-- here runs outside this gamemode.
------------------------------------------------------------------------

LC_MODULES = {
    shared = {
        "sh_livingcity_cache", -- (first: quick lookups the rest use)
        "sh_livingcity_net", -- (big and frequent sends to players, made safe: before anything sends)
        "sh_livingcity_perfdebug", -- (staff: the performance debugger, off until turned on)
        "sh_livingcity_npcstr", -- (the people's names, jobs and doings: sent only to players near them)
        "sh_livingcity_acts",
        "sh_livingcity_lowered", -- (guns carried lowered until raised: hold R)
        "sh_livingcity_stamina", -- (running and jumping tire you)
        "sh_livingcity_cp",
        "sh_livingcity_custody",
        "sh_livingcity_feel",
        "sh_livingcity_factions",
        "sh_livingcity_jobs",
        "sh_livingcity_power",
        "sh_livingcity_scanner",
        "sh_livingcity_shop",
        "sh_livingcity_zones",
    },
    server = {
        "sv_livingcity_perf", -- (first of the server modules: every timer after it is timed and staggered)
        "sv_livingcity_safefile", -- (early: every save file is written and read through it)
        "sv_livingcity_guard", -- (before anything that listens to players: the flood guard wraps every handler)
        "sv_livingcity",
        "sv_livingcity_notices", -- (early: warnings and notices on screen, waypoints)
        "sv_livingcity_actions",
        "sv_livingcity_acts",
        "sv_livingcity_admintools",
        "sv_livingcity_atmos",
        "sv_livingcity_bodies",
        "sv_livingcity_business",
        "sv_livingcity_character",
        "sv_livingcity_law", -- (who is CP, who is wanted: early, others lean on it)
        "sv_livingcity_lookouts",
        "sv_livingcity_conduct",
        "sv_livingcity_convoy",
        "sv_livingcity_cp",
        "sv_livingcity_cpsupply", -- (the Civil Protection Commissary: units are issued supplies)
        "sv_livingcity_crafting",
        "sv_livingcity_custody",
        "sv_livingcity_data",
        "sv_livingcity_debug",
        "sv_livingcity_lagwatch", -- (staff: the lag monitor)
        "sv_livingcity_perfdebug", -- (staff: the performance debugger)
        "sv_livingcity_nextstep", -- (what now? everyone always has a next step)
        "sv_livingcity_jobgames", -- (work you actually do: the street sweep, the factory line, papers check)
        "sv_livingcity_vest", -- (powered vests: what suit power is in the city)
        "sv_livingcity_grigori", -- (Father Grigori, the man himself, when no player is him)
        "sv_livingcity_hygiene", -- (toilets, baths, soiling yourself, the stink, the mess on the ground)
        "sv_livingcity_rest", -- (beds, sleep, being tired)
        "sv_livingcity_moregames", -- (more of them: parcels, the records terminal, dead drops, the dead, laundry, filing, radios, pat-downs, breaches)
        "sv_livingcity_doors",
        "sv_livingcity_dropship",
        "sv_livingcity_escort",
        "sv_livingcity_economy",
        "sv_livingcity_endings",
        "sv_livingcity_endingtune", -- (the Endings menu: every ending's settings, and the dances tuned live)
        "sv_livingcity_dreams", -- (the secret endings as shared dreams for everyone asleep, with a dream point placed)
        "sv_livingcity_dreamgames", -- (nightmare dreams you play: the maze, the barrel tower, the crumbling floor, freeze)
        "sv_livingcity_propagandadreams", -- (propaganda dreams you play: kneel, roses, mirror, the saviour, the quiz; after dreamgames)
        "sv_livingcity_propagandamore", -- (ten more propaganda dreams, drawn from real propaganda; after propagandadreams)
        "sv_livingcity_battleline", -- (The Battle Line, a propaganda dream: shoot the red rebels, never her soldiers; after propagandamore)
        "sv_livingcity_vortwar", -- (freed vortigaunts break into propaganda dreams: stand in their light; after battleline)
        "sv_livingcity_vices", -- (cigarettes, alcohol and stimulants; and how a dream you played leaves you)
        "sv_livingcity_dreamstandins", -- (stand-ins: every dream has at least lc_dream_min dreamers)
        "sv_livingcity_dreamenforcers", -- (Civil Protection and the Administration as Enforcers in nightmares and propaganda dreams)
        "sv_livingcity_dreamrules", -- (which dream tonight: Nightmares after bad days, Happy after clean ones; the city's own pick)
        "sv_livingcity_strangedreams", -- (strange dreams you play: the cheese dream, musical chairs, wings, raining melons; after propagandamore)
        "sv_livingcity_strangedreams2", -- (ten more: the horse, boxing, the exam, the last train, Lamarr, molasses, hot potato, Overwatch says, dance, counting headcrabs)
        "sv_livingcity_strangedreams3", -- (ten more, nonsense on purpose: clocks, tea party, headcrab derby, say cheese, doors, splat, conga, shh, bubbles, the watchers)
        "sv_livingcity_dreamtest", -- (testing any dream from the Living City Editor, alone and awake)
        "sv_livingcity_dreamplan", -- (who chooses tonight's dream: her kind now and then, the city by sociostability, in turn; the black screen's line)
        "sv_livingcity_desperation", -- (the outnumbered Combine fight dirtier: SMGs, grenades, energy balls, a little more damage)
        "sv_livingcity_imbalance", -- (one side's players far outnumbering the other's: more NPCs for the outnumbered, and the Combine's reaction force)
        "sv_livingcity_events",
        "sv_livingcity_exercise", -- (after events: the morning jog, drill and parade are events)
        "sv_livingcity_freq7",
        "sv_livingcity_factions",
        "sv_livingcity_garrison",
        "sv_livingcity_heist",
        "sv_livingcity_hints",
        "sv_livingcity_housing",
        "sv_livingcity_life", -- (a life: eye height, time lived, the death card, word getting around)
        "sv_livingcity_intake", -- (Civil Intake: new arrivals register, then ask for a room)
        "sv_livingcity_kick",
        "sv_livingcity_combinemodels",
        "sv_livingcity_lab", -- (the Resistance lab: the scientist makes what the cell needs)
        "sv_livingcity_ways",
        "sv_livingcity_outfits",
        "sv_livingcity_squadai",
        "sv_livingcity_mortuary",
        "sv_livingcity_navgraph",
        "sv_livingcity_npcwork",
        "sv_livingcity_sleep", -- (NPCs far from everyone stop running the engine's AI)
        "sv_livingcity_mail", -- (after npcwork: it gives the city's couriers the real mail)
        "sv_livingcity_paths",
        "sv_livingcity_pathmap",
        "sv_livingcity_people",
        "sv_livingcity_power",
        "sv_livingcity_props",
        "sv_livingcity_checkpoints", -- (after power: turrets and forcefields run off its power banks)
        "sv_livingcity_prison",
        "sv_livingcity_progress",
        "sv_livingcity_march", -- (after prison: arrested by a unit NPC, you're walked to the cells)
        "sv_livingcity_arrest", -- (after march: the baton's arrests, struggles, and walking prisoners in)
        "sv_livingcity_propaganda",
        "sv_livingcity_announcer", -- (after propaganda: it borrows the Administrator's speakers)
        "sv_livingcity_quests",
        "sv_livingcity_bedtime", -- (after quests: the chip's bedtime, the night shift, missed dreams, the foil hat and pulling the chip)
        "sv_livingcity_raids",
        "sv_livingcity_rations",
        "sv_livingcity_rebels",
        "sv_livingcity_rebellife",
        "sv_livingcity_resistanceops",
        "sv_livingcity_rebelevents", -- (raids and operations with real fighters: their own room above the NPC cap, findable, honest)
        "sv_livingcity_manpower", -- (after rebelevents: each side's reserve of fighters and units, refilled slowly)
        "sv_livingcity_response",
        "sv_livingcity_rp",
        "sv_livingcity_rhythm",
        "sv_livingcity_running",
        "sv_livingcity_salvage",
        "sv_livingcity_scanner",
        "sv_livingcity_scavenge",
        "sv_livingcity_security",
        "sv_livingcity_sidejobs",
        "sv_livingcity_crabhunt", -- (headcrab hunts: raw headcrabs from the infestation for the Resistance's supply crate)
        "sv_livingcity_slots",
        "sv_livingcity_staff",
        "sv_livingcity_staticprops",
        "sv_livingcity_stockpile",
        "sv_livingcity_market", -- (the Administrator's say over the Commissary; demand, and the black market following shortages)
        "sv_livingcity_storage",
        "sv_livingcity_stories",
        "sv_livingcity_insider", -- (the Resistance's man inside Civil Protection)
        "sv_livingcity_quickmore", -- (more on F2: Inside, Freq 7, Me, the Administrator's orders, a senior unit's sweep)
        "sv_livingcity_loyalty", -- (what high Civil Standing earns a citizen)
        "sv_livingcity_survival",
        "sv_livingcity_talk",
        "sv_livingcity_advice",
        "sv_livingcity_territory",
        "sv_livingcity_territorypaths", -- (territory grows along the path nodes)
        "sv_livingcity_trains",
        "sv_livingcity_underground",
        "sv_livingcity_patsearch", -- (a unit's search as a short pat-down: sv_livingcity_underground.lua starts it)
        "sv_livingcity_intaketutor", -- (the arrival search at the desks, its lesson, and the walk back to Civil Intake)
        "sv_livingcity_sentence", -- (sentences that add up the record, the work detail, probation)
        "sv_livingcity_interrogation", -- (the interrogation question by question: truth, lies, silence, a bargain; a unit asking in person)
        "sv_livingcity_survivalmode", -- (Realistic or Relaxed survival, per character)
        "sv_livingcity_dreamskip", -- (sitting out a kind of dream, once earned)
        "sv_livingcity_standingpanel", -- (where I stand: every number in one window, explained)
        "sv_livingcity_vort",
        "sv_livingcity_vortwork", -- (things to do as a vortigaunt, and the freed ones' camp life)
        "sv_livingcity_weeds", -- (weeds on open ground, the Groundskeeper, weedkiller as poison)
        "sv_livingcity_cleanup", -- (the infestation's growths, Infestation Cleanup, the firebomb, barnacles, fouled filters)
        "sv_livingcity_cityadmin", -- (the City Administrator: the election, the office, the bodyguard; idle players)
        "sv_livingcity_streetlife", -- (brandishing a gun, obituaries, longer street detentions, players found by citizen number)
        "sv_livingcity_directives", -- (the sealed directives: how the secret endings start; the G-Man's hand)
        "sv_livingcity_collapse", -- (sociostability BLACK: the G-Man's offer, the Administrator's last stand, the heroes; after directives)
        "sv_livingcity_war",
        "sv_livingcity_squads", -- (squad sizes by players on a side, E on a unit to lead it, backup out of rebel territory)
        "sv_livingcity_pacing", -- (who is in a fight; the Combine's action music)
        "sv_livingcity_campmove",
        "sv_livingcity_funding",
        "sv_livingcity_work",
        "sv_livingcity_labor", -- (after work: Labor Assignment, where Union work is given out and changed)
        "sv_livingcity_reconcile", -- (a new faction or rank: the old job, its clothes and kit go)
        "sv_livingcity_stalkerwork",
        "sv_livingcity_combineground", -- (soldiers stay in Combine zones, citizens stay out)
        "sv_livingcity_zonestalkers", -- (each Combine zone's stalkers: its terminals, its cleaning and repairs)
        "sv_livingcity_writing",
        "sv_livingcity_guidance", -- (the quest trail's way, and where you are for the panel of what you can do)
        "sv_livingcity_fieldops", -- (after the quests and the war: backup's guns, squads for violent jobs, flashbangs, rebel ground)
        "sv_livingcity_labdamage", -- (a lab shot up and wrecked, and the job to fix it)
        "sv_livingcity_career", -- (C > My career: rank, XP, the way to the Overwatch)
        "sv_livingcity_evidence", -- (what units confiscate is kept, and burned in public now and then)
    },
    client = {
        "cl_livingcity",
        "cl_livingcity_view", -- (early: the camera the other modules add their touches to)
        "cl_livingcity_screens", -- (terminals' menus on their own screens)
        "cl_livingcity_notices",
        "cl_livingcity_actions",
        "cl_livingcity_quick", -- (F1: the quick menu, nine things on the number keys; F2: the same for your side and job)
        "cl_livingcity_hub", -- (F4: jobs, career and factions, one window with tabs)
        "cl_livingcity_acts",
        "cl_livingcity_admintools",
        "cl_livingcity_lagwatch", -- (staff: the lag monitor)
        "cl_livingcity_perfdebug", -- (staff: the performance debugger)
        "cl_livingcity_nextstep", -- (what now? the next step on screen, F1 slot 1)
        "cl_livingcity_jobgames", -- (the job games' panel, the papers window)
        "cl_livingcity_grigori", -- (his window; the vest's charge on screen)
        "cl_livingcity_rest", -- (drooping eyelids, the stink's flies, sleeping, what you still have to do)
        "cl_livingcity_moregames", -- (their panels, and the outline on what the game wants you to look at)
        "cl_livingcity_patsearch", -- (the pat-down window a unit's search opens, and the panel for the person searched)
        "cl_livingcity_intaketutor", -- (the arrival search: the choice, the lesson, the practice search)
        "cl_livingcity_interrogation", -- (the interrogation's questions on the prisoner's screen, and the unit's window asking them)
        "cl_livingcity_standingpanel", -- (where I stand: every number explained)
        "cl_livingcity_atmos",
        "cl_livingcity_character",
        "cl_livingcity_checkpoints",
        "cl_livingcity_endings",
        "cl_livingcity_endingtune", -- (the Endings menu)
        "cl_livingcity_dreams", -- (shared dreams: opting out, waking up, the admins' window)
        "cl_livingcity_dreamgames", -- (the dreams you play: tokens, lives, time, on screen)
        "cl_livingcity_vortwar", -- (the vortigaunts' purple light, the tug-of-war meter)
        "cl_livingcity_strangedreams", -- (the strange dreams: the cheese dream's voices and colours, wings' rings; after dreamgames)
        "cl_livingcity_dreamenforce", -- (Enforcers: the bad dreamers glow red; a dreamer marked is told)
        "cl_livingcity_vices", -- (smoke, drunk, wired, crashing and the shakes, on screen)
        "cl_livingcity_exercise",
        "cl_livingcity_cp",
        "cl_livingcity_factions",
        "cl_livingcity_hints",
        "cl_livingcity_stealth", -- (sneaking: how seen you are, and the units' sight on the ground)
        "cl_livingcity_infest", "cl_livingcity_suit", "cl_livingcity_cityadmin", "cl_livingcity_directives",
        "cl_livingcity_collapse", -- (the G-Man's offer, her shield, the last stand on screen)
        "cl_livingcity_intake",
        "cl_livingcity_labor", -- (Labor Assignment's screen)
        "cl_livingcity_kick",
        "cl_livingcity_arrest", -- (the struggle bar when someone resists arrest)
        "cl_livingcity_ways",
        "cl_livingcity_outfits",
        "cl_livingcity_lab",
        "cl_livingcity_market", -- (the Administrator's Commissary and market panel)
        "cl_livingcity_labdamage", -- (a shot-up lab's smoke and sparks)
        "cl_livingcity_career", -- (F4 > Career, and C > My career)
        "cl_livingcity_layoutbrowser",
        "cl_livingcity_life",
        "cl_livingcity_livecam",
        "cl_livingcity_needs",
        "cl_livingcity_quests",
        "cl_livingcity_rent",
        "cl_livingcity_resistance",
        "cl_livingcity_rp",
        "cl_livingcity_scanner",
        "cl_livingcity_slots",
        "cl_livingcity_unittools",
        "cl_livingcity_staff",
        "cl_livingcity_talk",
        "cl_livingcity_war",
        "cl_livingcity_writing",
        "cl_livingcity_context", -- (what you can do here: the panel on the right)
        "cl_livingcity_trail", -- (the quest trail on the ground)
    },
}

-- Every Living City setting is saved with the map's layout as it changes (a
-- dedicated server doesn't keep them over a restart by itself), so each one
-- reports its changes as it's made (sv_livingcity_data.lua keeps them).
if SERVER and not LC_ConVarWrapped then
    LC_ConVarWrapped = true
    local create = CreateConVar
    LC_SettingInfo = LC_SettingInfo or {} -- [name] = { d = default, help, min, max } (the Endings menu lists them)
    CreateConVar = function(name, ...)
        local cv = create(name, ...)
        if isstring(name) then
            local d, _, help, mn, mx = ...
            LC_SettingInfo[name] = { d = tostring(d or ""), help = isstring(help) and help or "", min = tonumber(mn), max = tonumber(mx) }
        end
        if isstring(name) and cvars and cvars.AddChangeCallback
            and (string.match(name, "^lc_[%w_]+$") or string.match(name, "^lc[fq]_[%w_]+$")) then
            cvars.AddChangeCallback(name, function(n, _, new)
                if LC and LC.RememberSetting then LC.RememberSetting(n, new) end
            end, "LivingCityRemember")
        end
        return cv
    end
end

function LC_LoadModules(side)
    for _, name in ipairs(LC_MODULES[side]) do include("modules/" .. side .. "/" .. name .. ".lua") end
end

if SERVER then
    for _, name in ipairs(LC_MODULES.shared) do AddCSLuaFile("modules/shared/" .. name .. ".lua") end
    for _, name in ipairs(LC_MODULES.client) do AddCSLuaFile("modules/client/" .. name .. ".lua") end
end
LC_LoadModules("shared")

-- Admins in build mode get Sandbox's tools back.
function GM:LCBuilder(ply)
    return IsValid(ply) and ply:IsAdmin() and ply:GetNW2Bool("lc_build", false)
end

------------------------------------------------------------------------
-- How it moves: a person walking around a city, not a deathmatch
--
-- Half-Life 2's movement is built for strafing and hopping. Here there's a
-- slow walk and a slower sprint, a short low jump with a beat to recover from
-- it, no jumping from a crouch, no ducking in the air, and no gaining speed
-- in the air. lc_slow_movement 0 gives the old feel back.
------------------------------------------------------------------------

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
GM.cvSlow  = CreateConVar("lc_slow_movement", "1", FLAGS, "Slow, grounded movement: lower speeds and jump, no bunny hopping or crouch jumping")
GM.cvWalk  = CreateConVar("lc_walk_speed", "110", FLAGS, "Walking speed")
GM.cvRun   = CreateConVar("lc_run_speed", "190", FLAGS, "Sprinting speed (hold shift)")
GM.cvJump  = CreateConVar("lc_jump_power", "200", FLAGS, "Jump strength (200 is Half-Life 2's, enough for a curb or a crate)")
GM.cvHop   = CreateConVar("lc_jump_delay", "0.9", FLAGS, "Seconds between jumps")

function GM:LCSlowMovement() return self.cvSlow:GetBool() end

-- Pulling yourself up onto a ledge: look at something up to about chest height
-- (a crate, the lip of a platform, out of a track bed) and jump.
local MANTLE_MIN = 28
local cvMantle = CreateConVar("lc_mantle_height", "108", FLAGS, "The highest ledge you can pull yourself up onto (Civil Protection units; you're 72 tall)")

local function Mantle(ply, mv)
    if not mv.GetOrigin or not mv.GetAngles then return false end
    local MANTLE_MAX = math.Clamp(cvMantle:GetFloat(), MANTLE_MIN + 1, 160)
    local pos = mv:GetOrigin()
    local fwd = Angle(0, mv:GetAngles().y, 0):Forward()
    -- a wall right ahead
    local wall = util.TraceHull({
        start = pos + Vector(0, 0, 20), endpos = pos + Vector(0, 0, 20) + fwd * 30,
        mins = Vector(-10, -10, -4), maxs = Vector(10, 10, 4), filter = ply, mask = MASK_PLAYERSOLID,
    })
    if not wall.Hit or (wall.HitNormal and wall.HitNormal.z > 0.5) then return false end
    -- the top of it
    local from = Vector(wall.HitPos.x, wall.HitPos.y, pos.z + MANTLE_MAX + 10) + fwd * 14
    local down = util.TraceLine({ start = from, endpos = from - Vector(0, 0, MANTLE_MAX + 10), filter = ply, mask = MASK_PLAYERSOLID })
    if not down.Hit or down.StartSolid or (down.HitNormal and down.HitNormal.z < 0.7) then return false end
    local h = down.HitPos.z - pos.z
    if h < MANTLE_MIN or h > MANTLE_MAX then return false end
    -- room to stand up there
    local room = util.TraceHull({
        start = down.HitPos + Vector(0, 0, 2), endpos = down.HitPos + Vector(0, 0, 70),
        mins = Vector(-14, -14, 0), maxs = Vector(14, 14, 2), filter = ply, mask = MASK_PLAYERSOLID,
    })
    if room.Hit then return false end
    local g = 600
    local cv = GetConVar("sv_gravity")
    if cv then g = cv:GetFloat() end
    -- just enough to clear the edge. Whatever upward speed you already have
    -- (from the jump that started this) counts toward it, not on top of it.
    local need = math.sqrt(2 * g * (h + 8))
    local vz = math.max(mv:GetVelocity().z, 0)
    mv:SetVelocity(Vector(fwd.x * 90, fwd.y * 90, math.max(need, vz)))
    return true
end

hook.Add("SetupMove", "LivingCityMovement", function(ply, mv)
    local gm = GAMEMODE
    if not gm or not gm:LCSlowMovement() then return end
    if ply:GetMoveType() ~= MOVETYPE_WALK then return end
    local buttons = mv:GetButtons()
    if bit.band(buttons, IN_JUMP) ~= 0 and (ply.lcNextMantle or 0) <= CurTime() and Mantle(ply, mv) then
        ply.lcNextMantle = CurTime() + 1
        ply.lcNextJump = CurTime() + gm.cvHop:GetFloat()
        -- the climb replaces the jump: left in, the engine adds a full jump on
        -- top of the climb and throws you twenty feet up
        mv:SetButtons(bit.band(buttons, bit.bnot(IN_JUMP)))
        return
    end
    if ply:IsOnGround() then
        if bit.band(buttons, IN_JUMP) ~= 0 then
            if (ply.lcNextJump or 0) > CurTime() or ply:Crouching() then
                buttons = bit.band(buttons, bit.bnot(IN_JUMP)) -- no hopping, no crouch jumping
            else
                ply.lcNextJump = CurTime() + gm.cvHop:GetFloat()
            end
        end
    else
        buttons = bit.band(buttons, bit.bnot(IN_DUCK)) -- no tucking up in the air
        local v = mv:GetVelocity()
        local cap = math.max(ply:GetRunSpeed(), mv:GetMaxSpeed())
        local flat = Vector(v.x, v.y, 0)
        if flat:Length() > cap then
            flat = flat:GetNormalized() * cap
            mv:SetVelocity(Vector(flat.x, flat.y, v.z))
        end
    end
    mv:SetButtons(buttons)
end)
