--[[
    Living City: things to do as a vortigaunt (and for the city's own)

    The owner asked (2026-11-01) for more for vortigaunt players and NPCs.

    Shackled vortigaunt players (the Vortigaunt faction):
      Reach out through the vortessence   C > Reach out (or !vortcall): eight
                       seconds still, with no unit watching, and the Resistance
                       hears where you are ("cut it loose"), and so do the free
                       vortigaunts. Once every lc_vort_call_minutes (10). Seen
                       by a unit, the collar bites instead.
      The Collar       a story on the board (F3), in three parts: a street to
                       sweep for the Overseer, a crate to carry to a
                       checkpoint (and whether to slip a warning into its
                       manifest), and a quiet corner to reach out from.

    Free vortigaunt players (the Resistance's Free Vortigaunt role), on the
    Resistance's board:
      Free your kin    a shackled vortigaunt sweeping the streets (marked):
                       cut it loose.
      Read the Combine still yourself in sight of a checkpoint, unseen, and
                       let the vortessence read it: written down, it's intel
                       the quartermaster buys. (The vortessence charges vests;
                       it doesn't heal: healing is food, sleep and medicine.)

    The city's own: freed vortigaunts in rebel ground walk the camp, stand by
    the fire and hum to themselves, instead of standing in one spot.
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}
local Q = LC.QB
if not Q then return end

local Goto, Hold, Count, Choice, Narrate, Place, Pick = Q.Goto, Q.Hold, Q.Count, Q.Choice, Q.Narrate, Q.Place, Q.Pick

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCallGap = CreateConVar("lc_vort_call_minutes", "10", FLAGS, "Minutes between a shackled vortigaunt's calls to the Resistance through the vortessence")

local function Shackled(ply) return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "vort" end
local function FreeVort(ply) return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_special", "") == "vortigaunt" end
local function Where(pos) return (LC.DescribePlace and LC.DescribePlace(pos)) or "" end

------------------------------------------------------------------------
-- Reaching out through the vortessence
------------------------------------------------------------------------

-- The call itself: the Resistance hears where you are, and so do the free vortigaunts.
local function Call(p)
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "Through the vortessence: a shackled vortigaunt calls out from " .. Where(p:GetPos()) .. ". Cut it loose (look at it up close, and unshackle).")
    end
    for _, o in ipairs(player.GetAll()) do
        if FreeVort(o) then o:ChatPrint("[Vortessence] One of your kin calls out, in chains, " .. Where(p:GetPos()) .. ".") end
    end
    p:ChatPrint("[Vortessence] Your call goes out. Somewhere, someone hears it.")
    p:EmitSound("npc/vort/vort_pain3.wav", 60, 80)
    LC.QuestEvent("vort_called", p, p)
end
LC.VortCallOut = Call

function LC.VortCall(ply)
    if not Shackled(ply) then return false, "Only a shackled vortigaunt can reach out like that." end
    local now = CurTime()
    if (ply.lcVortCallNext or 0) > now then
        return false, string.format("The vortessence is quiet. Try again in %d minutes.", math.ceil((ply.lcVortCallNext - now) / 60))
    end
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        -- the collar bites
        ply.lcVortCallNext = now + 60
        ply:TakeDamage(10, ply, ply)
        ply:EmitSound("ambient/energy/zap1.wav", 70)
        return false, "A Civil Protection unit is watching. The collar bites, and the vortessence goes quiet."
    end
    if not LC.StartTask then Call(ply) ply.lcVortCallNext = now + cvCallGap:GetFloat() * 60 return true end
    return LC.StartTask(ply, 8, "Reaching out through the vortessence...", {
        maxMove = 30, cancelText = "The thread slips away.",
        done = function(p)
            if not Shackled(p) then return end
            p.lcVortCallNext = CurTime() + cvCallGap:GetFloat() * 60
            Call(p)
        end,
    })
end
LC.SlashCommands.vortcall = function(ply) local ok, why = LC.VortCall(ply) if not ok and why then ply:ChatPrint(why) end end
if LC.MenuActions then LC.MenuActions.vortcall = true end

------------------------------------------------------------------------
-- The Collar: a story for a shackled vortigaunt
------------------------------------------------------------------------

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30))) or p end

LC.Chain{
    id = "collar", name = "The Collar", factions = { citizen = true }, -- (shackled vortigaunts work the citizens' board)
    unlock = Shackled, gate = Shackled, pace = 30,
    start = "grime",
    endings = {
        called = "Your call went out through the vortessence. The Resistance knows where you are now: the rest is up to them.",
    },
    parts = {
        grime = { num = 1, next = "errand", build = function(ply)
            local pos = Q.Spot(ply, 300, 1500)
            if not pos then return nil end
            local go = Goto(pos, "Go to the street the Overseer has marked", 180)
            go.onDone = function(q) if IsValid(q.owner) and LC.JobGameStart then LC.JobGameStart(q.owner, "sweep", q, { depot = pos }) end end
            return {
                title = "Grime", reward = 10, limit = 600,
                desc = "The Overseer wants a street swept, and you're the broom. The collar hums at your neck the whole time.",
                stages = { go, Count("game_done", 1, "Sweep the street clean (the cart, the litter, the bin)") },
            }
        end },

        errand = { num = 2, next = "whisper", build = function(ply)
            local cps = LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 600, 2500)
            if not pos then return nil end
            return {
                title = "The Overseer's crate", reward = 15, limit = 600,
                desc = "A crate of Union stores to carry to a checkpoint " .. Place(pos, ply:GetPos()) .. ". Its manifest is clipped to the lid.",
                stages = {
                    Goto(pos, "Carry the crate to the checkpoint (marked)", 220),
                    Choice("The manifest lists what's going where: the checkpoint's new orders, a sweep two days from now. The unit at the gate isn't looking.", {
                        { text = "Fold a warning into it for the Resistance: a mark in the margin they'll know.", check = { "guile", 11 },
                          success = function(q, p)
                              LC.AddTrait(p, "sympathy", 1)
                              Narrate(q, "Nobody sees. Somewhere down the line, someone will read the margin.")
                              if LC.RadioNotice then LC.RadioNotice("resistance", "A mark in a Union manifest, from a vortigaunt in chains: a sweep in two days. Be ready.") end
                          end,
                          fail = function(q, p)
                              Narrate(q, "The unit looks up as you fold it. The collar bites before you can straighten.")
                              p:TakeDamage(15, p, p)
                          end },
                        { text = "Hand it over as it is.", pick = function(q, p)
                            LC.AddTrait(p, "loyalty", 1)
                            Narrate(q, "The unit signs for it without a glance at you.")
                        end },
                    }),
                },
            }
        end },

        whisper = { num = 3, build = function(ply)
            local pos = Q.Spot(ply, 300, 1500)
            if not pos then return nil end
            local hold = Hold(pos, 20, "Reach out through the vortessence: stay still here, unseen, for 20 seconds", 140)
            hold.onDone = function(q) if IsValid(q.owner) then Call(q.owner) end end
            return {
                title = "A whisper in the vortessence", reward = 20, limit = 600,
                desc = "Some nights the collar flickers, and the vortessence stirs behind it. Find somewhere quiet " .. Place(pos, ply:GetPos()) .. ", and reach out.",
                stages = { Goto(pos, "Find a quiet corner (marked)", 140), hold },
                onFinish = function(q, success) if success then q.chainEnd = "called" end end,
            }
        end },
    },
}

------------------------------------------------------------------------
-- Jobs for a free vortigaunt (the Resistance's board)
------------------------------------------------------------------------

local function T(def)
    def.factions = def.factions or {}
    LC.QuestTemplates[#LC.QuestTemplates + 1] = def
end

local function NearestSlave(pos)
    local best, bd
    for v in pairs(LC.VortSlaves or {}) do
        if IsValid(v) then
            local d = v:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = v, d end
        end
    end
    return best
end

T{
    id = "res_vort_kin", factions = { resistance = true },
    available = function(ply) return FreeVort(ply) and NearestSlave(ply:GetPos()) ~= nil end,
    build = function(ply)
        local v = NearestSlave(ply:GetPos())
        if not v then return nil end
        return {
            title = "Free your kin", reward = 45, limit = 600,
            desc = "One of your kin sweeps the streets in a collar " .. Place(v:GetPos(), ply:GetPos()) .. ". Cut it loose, and it will find its way to us.",
            data = { target = v },
            stages = {
                Goto(v:GetPos(), "Find your kin, collared, sweeping the street (marked)", 220),
                Count("vort_freed", 1, "Cut it loose: look at it up close and unshackle it (C > Resistance), with no unit watching"),
            },
        }
    end,
}

T{
    id = "res_vort_sense", factions = { resistance = true },
    available = function(ply) return FreeVort(ply) end,
    build = function(ply)
        local cps = LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}
        local target = #cps > 0 and Pick(cps).pos or nil
        if not target then
            local zs = LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}
            target = #zs > 0 and Pick(zs).pos or nil
        end
        if not target then return nil end
        -- not on top of it: a little way off, where you can watch
        local away = Q.Spot(ply, 300, 900) or target
        local dir = (away - target)
        dir.z = 0
        if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
        local spot = Ground(target + dir:GetNormalized() * 450)
        return {
            title = "Read the Combine", reward = 35, limit = 600,
            desc = "The vortessence sees what eyes don't: who stands where, and when they change. Watch the checkpoint " .. Place(target, ply:GetPos()) .. " from a little way off, unseen, and bring what it shows you to the quartermaster.",
            stages = {
                Goto(spot, "Find somewhere to watch from (marked), out of the units' sight", 200),
                Hold(spot, 20, "Still yourself and let the vortessence read the checkpoint (20 seconds, unseen)", 160),
            },
            onFinish = function(q, success)
                if not success or not IsValid(q.owner) then return end
                if LC.GiveItem and LC.GiveItem(q.owner, "intel_checkpoint", 1) then
                    q.owner:ChatPrint("[Vortessence] Shifts, the gate, the men: it all settles into your mind, and you write it down. The quartermaster pays for this.")
                end
            end,
        }
    end,
}

------------------------------------------------------------------------
-- The city's own: freed vortigaunts living in rebel ground
------------------------------------------------------------------------

local HUMS = { "npc/vort/vort_foot1.wav", "npc/vort/vort_foot2.wav", "npc/vort/vort_foot3.wav", "npc/vort/vort_foot4.wav" }
local nextLife = 0
local function VortLife(now)
    if now < nextLife or not LC.RebelVorts then return end
    nextLife = now + 5
    for v in pairs(LC.RebelVorts) do
        if IsValid(v) and v:Health() > 0 and now > (v.lcVortNext or 0) then
            v.lcVortNext = now + math.Rand(25, 55)
            -- somewhere in its own camp: by the fire if there is one, else anywhere in the zone
            local zone
            for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
                if LCZ and LCZ.Contains and LCZ.Contains(z, v:GetPos(), 200) then zone = z break end
            end
            local spot
            if zone and math.random() < 0.4 then
                for _, f in ipairs(LC.EntsOf and LC.EntsOf("lc_fire") or {}) do
                    if IsValid(f) and LCZ.Contains(zone, f:GetPos(), 0) then spot = f:GetPos() + VectorRand():GetNormalized() * 70 spot.z = f:GetPos().z break end
                end
            end
            spot = spot or (zone and LC.SpotInZone and LC.SpotInZone(zone))
            if spot and v.SetLastPosition then
                v:SetLastPosition(spot)
                v:SetSchedule(SCHED_FORCED_GO)
                v:SetNW2String("lc_doing", math.random() < 0.5 and "tending the camp" or "humming to itself")
            end
            if math.random() < 0.3 then v:EmitSound(HUMS[math.random(#HUMS)], 55, math.random(80, 95)) end
        end
    end
end
LC.VortLifeTick = function(now) nextLife = 0 VortLife(now or CurTime()) end -- (for tests)
timer.Create("LivingCityVortLife", 1, 0, function()
    local ok, err = pcall(VortLife, CurTime())
    if not ok and LC.Error then LC.Error("vortigaunt life", err) end
end)
