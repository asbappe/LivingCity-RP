--[[
    Living City: talking to HQ over the radio, and the resupply scanner

    The owner, 13 November: "anything that is local (saying a voice line, a
    kick, cuffing, checking papers) to the roleplay of the player is done
    through the F2 menu, but anything that would require communication
    realistically with combine HQ (call for backup, request resupply, BOLO,
    10-20, job board, etc) is all done ONLY with the CP radio out and SWEP in
    hand, THEN having it out and right clicking opens the hidden 'Radio'
    quick F1/F2 styled menu".

      The rule     A Civil Protection or Overwatch unit's HQ calls (backup,
                   10-20, a BOLO, a records check, a sweep, the Overwatch
                   Commander's squad, a resupply, their directives) only go
                   out with the radio transmitter in hand (LC.RadioOnly).
                   The radio's right click opens the Radio menu (client:
                   LC_CL.OpenRadioQuick in cl_livingcity_quick.lua). Things
                   done on the spot (voice lines, the kick, cuffs, searches,
                   papers, escorts) stay on F2. lc_radio_only (1).
      Resupply     Request resupply on the Radio menu: a shield scanner
                   comes down out of the open sky above the unit, drops one
                   small crate (a quarter the size of a supply crate) that
                   breaks on the ground, and flies back up and away toward
                   the nearest Combine-only zone. The crate holds the three
                   things the unit is shortest of (LC.ResupplyNeeds), plus
                   cuffs back up to issue and one grenade for their rank
                   (Recruit smoke, Metrocop and Division Leader a flashbang,
                   the Overwatch chlorine gas). Not indoors or underground: the
                   scanner needs open sky. lc_resupply (1),
                   lc_resupply_cooldown (300 seconds).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRadioOnly = CreateConVar("lc_radio_only", "1", FLAGS, "Units' HQ calls (backup, 10-20, BOLO, records, sweeps, squads, resupply, directives) only go out with the radio transmitter in hand")
local cvOn = CreateConVar("lc_resupply", "1", FLAGS, "Units can call a shield scanner with a small resupply crate from the Radio menu")
local cvWait = CreateConVar("lc_resupply_cooldown", "300", FLAGS, "Seconds between one unit's resupply calls")

------------------------------------------------------------------------
-- The rule: HQ only hears you over the radio
------------------------------------------------------------------------

util.AddNetworkString("lc_radio_menu") -- (the radio's right click: open the Radio menu)

LC.RADIO_NEEDED ="Get your radio out first: HQ only hears you over it. Switch to the radio transmitter (next to Hands) and right click for the Radio menu."

-- A real unit (Civil Protection or the Overwatch, not the Administrator, not a disguise).
local function Unit(ply)
    return IsValid(ply) and ply:IsPlayer() and (ply:GetNW2String("lcf_faction", "") == "cp" or ply:GetNW2String("lcf_faction", "") == "ota")
end
LC.RadioUnit = Unit

local function Held(ply)
    if LC.RadioHeld then return LC.RadioHeld(ply) end
    local w = IsValid(ply) and ply.GetActiveWeapon and ply:GetActiveWeapon()
    return IsValid(w) and w:GetClass() == "weapon_lc_radio"
end

-- ok, why. Only units are held to it (everyone else's calls are as they were); in a dream it doesn't apply.
function LC.RadioOnly(ply)
    if not cvRadioOnly:GetBool() or not Unit(ply) then return true end
    if ply.lcDreaming or (ply.GetNW2Bool and ply:GetNW2Bool("lc_dreaming", false)) then return true end
    if Held(ply) then return true end
    return false, LC.RADIO_NEEDED
end

-- Wrap one of the HQ calls (ok, why = fn(ply, ...)) so a unit needs the radio up for it.
-- quietArg: the call's second argument, when true, is the game's own (not the player's), and passes.
local function Gate(name, quietArg)
    local fn = LC[name]
    if type(fn) ~= "function" or LC["_radioGated_" .. name] then return end
    LC["_radioGated_" .. name] = true
    LC[name] = function(ply, a, ...)
        if not (quietArg and a == true) then
            local ok, why = LC.RadioOnly(ply)
            if not ok then return false, why end
        end
        return fn(ply, a, ...)
    end
end
function LC.RadioGateAll()
    Gate("CallBackup")
    Gate("Mark1020", true) -- (Mark1020(ply, true) is the backup call's own, already over the radio)
    Gate("OfficerCallSweep")
    Gate("CommanderDrop")
end
LC.RadioGateAll()
-- (the modules after this one, and a reload: once more when everything is in)
hook.Add("Initialize", "LivingCityRadioGate", function() LC.RadioGateAll() end)
timer.Simple(0, function() LC.RadioGateAll() end)

-- Chat: !records and !bolo (sv_livingcity_cp.lua's chat hook asks this first). !backup, !10-20 and !dropship go
-- through the gated calls above.
LC.RadioChatCommands = { records = true, bolo = true, backup = true, ["10-20"] = true, ["1020"] = true, mark = true, dropship = true, resupply = true }
function LC.RadioChatBlocked(ply, cmd)
    if not LC.RadioChatCommands[string.lower(tostring(cmd or ""))] then return false end
    local ok, why = LC.RadioOnly(ply)
    if ok then return false end
    if LC.Notice then LC.Notice(ply, "warn", "Radio", why, 6) else ply:ChatPrint(why) end
    return true
end

-- The menus' path (LC.RunAction): a unit's HQ calls need the radio up.
local MENU_HQ = { backup = true, ["10-20"] = true, records = true, dropship = true, bolo = true, resupply = true }
do
    local run = LC.RunAction
    if run and not LC._radioRunGated then
        LC._radioRunGated = true
        LC.RunAction = function(ply, cmd, ...)
            if MENU_HQ[string.lower(tostring(cmd or ""))] then
                local ok, why = LC.RadioOnly(ply)
                if not ok then
                    if LC.Notice then LC.Notice(ply, "warn", "Radio", why, 6) else ply:ChatPrint(why) end
                    return true
                end
            end
            return run(ply, cmd, ...)
        end
    end
end

-- A gun put away for the radio still counts as a gun out for a little while (LC.BackupViolent: backup comes armed).
hook.Add("PlayerSwitchWeapon", "LivingCityRadioGunOut", function(ply, old, new)
    if not (new and new.GetClass and new:GetClass() == "weapon_lc_radio" and old and old.GetClass) then return end
    local cls = old:GetClass()
    if (LCL and LCL.Guns and LCL.Guns[cls]) or (LC.ViolentGuns and LC.ViolentGuns[cls]) then ply.lcGunOutAt = CurTime() end
end)

-- Right click with one band: the radio's own switch (an Insider's right click used to switch bands; now it's on
-- the Radio menu as "Switch frequency").
function LC.RadioTune(ply)
    if not Held(ply) then return false, "Hold your radio up first." end
    if not (LC.TransmitBands and #LC.TransmitBands(ply) > 1 and LC.TuneTransmitter) then return false, "Your radio only sends on one band." end
    local w = ply:GetActiveWeapon()
    local nw = IsValid(w) and w.GetNW2String ~= nil
    local before = nw and w:GetNW2String("lc_band", "") or ""
    local band = LC.TuneTransmitter(ply)
    if nw and w.SetNW2String then
        w:SetNW2String("lc_band", band or "")
        w:SetNW2Int("lc_bands", #LC.TransmitBands(ply))
    end
    if band ~= before then
        ply:EmitSound("buttons/button16.wav", 50)
        ply:ChatPrint("[Radio] Now transmitting on " .. (band == "cp" and "the CP net" or (band == "resistance" and "Freq 7" or "nothing")) .. ".")
    end
    return true
end
LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.radiotune = function(ply) return LC.RadioTune(ply) end
LC.TargetActions.resupply = function(ply) return LC.RequestResupply(ply) end

------------------------------------------------------------------------
-- Resupply: what a unit is shortest of
------------------------------------------------------------------------

-- A full load for each kind of round (the issue and a little over), and what's low: under 30% of it.
LC.RESUPPLY_FULL = { Pistol = 72, SMG1 = 180, Buckshot = 24, AR2 = 90 }
LC.RESUPPLY_LOW = 0.3
local WEAPON_AMMO = { weapon_pistol = "Pistol", weapon_smg1 = "SMG1", weapon_shotgun = "Buckshot", weapon_ar2 = "AR2" }
local GUN_NAME = { Pistol = "pistol", SMG1 = "SMG", Buckshot = "shotgun", AR2 = "pulse rifle" }
-- Half-Life 2's own pickups (anyone walking over them picks them up), and how much each holds.
local AMMO_ENT = { Pistol = { "item_ammo_pistol", 20 }, SMG1 = { "item_ammo_smg1", 45 }, Buckshot = { "item_box_buckshot", 20 }, AR2 = { "item_ammo_ar2", 20 } }
-- Grenade by rank: Recruit smoke, Metrocop and Division Leader a flashbang, the Overwatch chlorine gas.
function LC.ResupplyGrenade(ply)
    local r = ply:GetNW2Int("lcf_rank", 1)
    local f = LCF and LCF.ById and LCF.ById[ply:GetNW2String("lcf_faction", "")]
    local rank = f and f.ranks and f.ranks[r]
    if ply:GetNW2String("lcf_faction", "") == "ota" or (rank and rank.overwatch) then return "gren_gas" end
    if r <= 1 then return "gren_smoke" end
    return "gren_flash"
end
local function MaxArmor(ply)
    local f = LCF and LCF.ById and LCF.ById[ply:GetNW2String("lcf_faction", "")]
    local rank = f and f.ranks and f.ranks[ply:GetNW2Int("lcf_rank", 1)]
    local m = (rank and rank.armor) or (ply.GetMaxArmor and ply:GetMaxArmor()) or 100
    return math.max(1, m)
end

-- How the three are chosen (the owner: "we would need a way to analyze and prioritize the needs"): each
-- need gets a score and the three highest go in the crate.
--   ammo     only under 30% of a full load: 1 to 2, the emptier the higher, a quarter more for the gun in your hands
--   health   under 75%: what's missing times 2 (half health ties with a gun just under 30%; near death outranks it)
--   vest     under half its charge: up to 1.2
-- Returns { { kind, score, label, give = { { cls or item, n } } } }, best first.
function LC.ResupplyNeeds(ply)
    local out = {}
    local held = ply.GetActiveWeapon and ply:GetActiveWeapon()
    local heldCls = held and held.GetClass and held:GetClass() or ""
    local byAmmo = {}
    for _, w in ipairs(ply.GetWeapons and ply:GetWeapons() or {}) do
        local ammo = w and w.GetClass and WEAPON_AMMO[w:GetClass()]
        if ammo then
            local full = LC.RESUPPLY_FULL[ammo]
            local have = (ply:GetAmmoCount(ammo) or 0) + math.max(0, w.Clip1 and w:Clip1() or 0)
            local frac = have / full
            if frac < LC.RESUPPLY_LOW then
                local score = 1 + (LC.RESUPPLY_LOW - frac) / LC.RESUPPLY_LOW + (w:GetClass() == heldCls and 0.25 or 0)
                local cur = byAmmo[ammo]
                if not cur or score > cur.score then
                    local per = AMMO_ENT[ammo][2]
                    local n = math.Clamp(math.ceil((full * 0.6 - have) / per), 1, 3)
                    byAmmo[ammo] = { kind = "ammo", ammo = ammo, score = score, label = "rounds for your " .. GUN_NAME[ammo],
                        give = { { AMMO_ENT[ammo][1], n } } }
                end
            end
        end
    end
    for _, e in pairs(byAmmo) do out[#out + 1] = e end
    local hp, maxHp = ply:Health(), math.max(1, ply:GetMaxHealth())
    if hp / maxHp < 0.75 then
        out[#out + 1] = { kind = "health", score = (1 - hp / maxHp) * 2, label = hp / maxHp < 0.4 and "two health vials" or "a health vial",
            give = { { "item_healthvial", hp / maxHp < 0.4 and 2 or 1 } } }
    end
    local ar, maxAr = ply:Armor(), MaxArmor(ply)
    if ar / maxAr < 0.5 then
        out[#out + 1] = { kind = "vest", score = (1 - ar / maxAr) * 1.2, label = ar / maxAr < 0.25 and "two suit batteries" or "a suit battery",
            give = { { "item_battery", ar / maxAr < 0.25 and 2 or 1 } } }
    end
    table.sort(out, function(a, b) return a.score > b.score end)
    while #out > 3 do table.remove(out) end
    return out
end

-- The whole crate: the three, cuffs back up to issue, and the rank's grenade (unless they carry two already).
function LC.ResupplyContents(ply)
    local needs = LC.ResupplyNeeds(ply)
    local give, words = {}, {}
    for _, n in ipairs(needs) do
        for _, g in ipairs(n.give) do give[#give + 1] = { cls = g[1], n = g[2] } end
        words[#words + 1] = n.label
    end
    local cuffs = 0
    if LC.CuffCount and LC.CP_CUFFS and ply:GetNW2String("lcf_faction", "") == "cp" then cuffs = math.max(0, LC.CP_CUFFS - LC.CuffCount(ply)) end
    if cuffs > 0 then
        give[#give + 1] = { item = "zipties", n = cuffs }
        words[#words + 1] = cuffs == 1 and "a pair of cuffs" or (cuffs .. " pairs of cuffs")
    end
    local nade = LC.ResupplyGrenade(ply)
    local carry = (LC.Inventory and (LC.Inventory(ply) or {})[nade]) or 0
    local essential = #needs > 0 or cuffs > 0
    if essential and carry < 2 then
        give[#give + 1] = { item = nade, n = 1 }
        words[#words + 1] = (nade == "gren_smoke" and "a smoke grenade") or (nade == "gren_flash" and "a flashbang") or "a chlorine gas grenade"
    end
    return give, words, essential
end

------------------------------------------------------------------------
-- Resupply: the call
------------------------------------------------------------------------

LC.ResupplyNext = LC.ResupplyNext or {}
LC.ResupplyOut = LC.ResupplyOut or {}

-- Open sky straight above (a scanner comes down a clear shaft): the sky's height, or nil.
function LC.OpenSkyAbove(pos)
    local tr = util.TraceLine({ start = pos, endpos = pos + Vector(0, 0, 32768), mask = MASK_SOLID_BRUSHONLY })
    if not tr.HitSky then return nil end
    if tr.HitPos.z - pos.z < 220 then return nil end -- (a skylight in a low roof isn't room to fly in)
    return tr.HitPos.z
end

-- Which way it flies off: the nearest Combine-only zone's cardinal direction (north, south, east or west).
function LC.ResupplyHeading(pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        if z.pos then
            local d = (z.pos.x - pos.x) ^ 2 + (z.pos.y - pos.y) ^ 2
            if not bd or d < bd then best, bd = z, d end
        end
    end
    if not best then return Vector(0, 1, 0) end
    local dx, dy = best.pos.x - pos.x, best.pos.y - pos.y
    if math.abs(dx) >= math.abs(dy) then return Vector(dx >= 0 and 1 or -1, 0, 0) end
    return Vector(0, dy >= 0 and 1 or -1, 0)
end

function LC.RequestResupply(ply)
    if not IsValid(ply) then return false end
    if not cvOn:GetBool() then return false, "Resupply is off on this server." end
    if not Unit(ply) then return false, "Only Civil Protection and the Overwatch can call for a resupply." end
    if not ply:Alive() then return false end
    if ply.lcDreaming then return false, "Not in a dream." end
    local ok, why = LC.RadioOnly(ply)
    if not ok then return false, why end
    if not Held(ply) then return false, LC.RADIO_NEEDED end
    local now = CurTime()
    if IsValid(LC.ResupplyOut[ply]) then return false, "A scanner is already on its way to you." end
    local wait = (LC.ResupplyNext[ply] or 0) - now
    if wait > 0 then return false, string.format("HQ sent you a resupply not long ago. Next one in %d:%02d.", math.floor(wait / 60), math.floor(wait % 60)) end
    local give, words, essential = LC.ResupplyContents(ply)
    if not essential then return false, "HQ: you're stocked. Ammo over 30%, health and vest fine, cuffs full: nothing to send." end
    local ground = ply:GetPos()
    local sky = LC.OpenSkyAbove(ply:EyePos())
    if not sky then return false, "No open sky above you: a scanner can't reach you indoors or underground. Get outside, under the sky." end
    local e = ents.Create("lc_resupplyscanner")
    if not IsValid(e) then return false, "HQ has no scanner to send." end
    e.lcFor = ply
    e.lcGive = give
    e.lcWords = words
    e.lcTop = Vector(ground.x, ground.y, sky - 48)
    e.lcDrop = Vector(ground.x, ground.y, math.min(sky - 60, ground.z + 170))
    e.lcHeading = LC.ResupplyHeading(ground)
    e:SetPos(e.lcTop)
    e:Spawn()
    LC.ResupplyOut[ply] = e
    LC.ResupplyNext[ply] = now + cvWait:GetFloat()
    ply:EmitSound("npc/metropolice/vo/on1.wav", 50)
    if LC.Notice then LC.Notice(ply, "info", "Resupply", "HQ copies. A scanner is coming down with " .. table.concat(words, ", ") .. ".", 7) end
    hook.Run("LivingCityResupplyCalled", ply, e)
    return true
end

-- The crate broke: what was in it, on the ground for whoever gets there first.
function LC.ResupplySpill(crate, pos)
    local give = crate.lcGive or {}
    local spawned = {}
    local i = 0
    for _, g in ipairs(give) do
        for _ = 1, g.n or 1 do
            i = i + 1
            local a = math.rad(i * 67)
            local at = pos + Vector(math.cos(a) * 14, math.sin(a) * 14, 8)
            local e
            if g.cls then
                e = ents.Create(g.cls)
                if IsValid(e) then e:SetPos(at) e:Spawn() end
            elseif g.item and LC.SpawnWorldItem then
                e = LC.SpawnWorldItem(g.item, at)
            end
            if IsValid(e) then spawned[#spawned + 1] = e end
        end
    end
    -- left lying: gone after two minutes, like anything else dropped
    timer.Simple(120, function() for _, e in ipairs(spawned) do if IsValid(e) and not IsValid(e:GetOwner()) then e:Remove() end end end)
    local ply = crate.lcFor
    if IsValid(ply) and LC.Notice then
        LC.Notice(ply, "info", "Resupply", "The crate is down: " .. table.concat(crate.lcWords or {}, ", ") .. ". Walk over it to pick it up.", 7)
    end
    hook.Run("LivingCityResupplied", ply, spawned)
    return spawned
end

hook.Add("PlayerDisconnected", "LivingCityResupply", function(ply) LC.ResupplyNext[ply] = nil LC.ResupplyOut[ply] = nil end)
