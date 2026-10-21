--[[
    Living City: the Resistance's money (besides raiding supply drops)

      Intel         a Resistance member watches the Combine and writes it down
                    (F1 > Resistance > Write down what you see, or !scout; a
                    sheet of paper from your pockets): fifteen seconds where no
                    unit sees you doing it, near a checkpoint, the Combine's own
                    ground, or a unit on his beat. The notes are a report in
                    your pockets (contraband) that only the quartermaster buys
                    (lc_intel_pay: a patrol's beat 20, a checkpoint 25, the
                    Combine's ground 35, and a little XP). The same place again
                    is old news for lc_intel_minutes (30). A unit who sees you
                    at it takes the paper off you, and notes your face (a
                    little standing).

      Skimming      on the factory line (sv_livingcity_jobgames.lua), R while
                    holding a good part pockets it: Union machine parts, which
                    the dealer buys (8) and the quartermaster for more (12). A
                    unit who sees it makes you wanted; and the foreman counts:
                    the more you take, the likelier he finds the count short
                    at the end of the shift (it comes out of your pay, and
                    your standing).

      Forgery       the lab's scientist turns out forged ration cards five at
                    a time (paper and chemicals). The dealer buys them (4 each)
                    and the dispensers take them. But every forged card that
                    turns up (sold, or used at a dispenser) heats up the
                    Combine's search for the forger (lc_forgery_heat: at 15, it
                    cools a card every lc_forgery_cool minutes, 3): when it's
                    hot enough, a sweep is planned on the rebel territory
                    nearest the lab that made the last batch, and the city hears
                    that counterfeit cards are about.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvIntelMin = CreateConVar("lc_intel_minutes", "30", FLAGS, "Minutes before the same place is worth writing down again (intel for the quartermaster)")
local cvHeat     = CreateConVar("lc_forgery_heat", "15", FLAGS, "Forged ration cards turning up (sold or used) before the Combine come looking for the forger: a sweep on the rebel territory nearest the lab (0: never)")
local cvCool     = CreateConVar("lc_forgery_cool", "3", FLAGS, "Minutes for the search for the forger to cool by one card")

local function Rebel(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end
local function Say(ply, text) ply:ChatPrint("[Intel] " .. text) end

------------------------------------------------------------------------
-- Intel
------------------------------------------------------------------------

-- What's worth writing down from here: the best thing in sight, and a key for "the same place".
local function WhatsHere(ply)
    local pos = ply:GetPos()
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        if LCZ.Contains(z, pos, 900) then
            return "intel_nexus", string.format("z%d_%d", math.floor(z.pos.x / 100), math.floor(z.pos.y / 100)), "the approaches to the Combine's ground"
        end
    end
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}) do
        if p.pos:DistToSqr(pos) < 700 * 700 then
            return "intel_checkpoint", string.format("c%d_%d", math.floor(p.pos.x / 100), math.floor(p.pos.y / 100)), "the checkpoint: its shifts, its gate, its men"
        end
    end
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and npc:GetPos():DistToSqr(pos) < 900 * 900 and LC.LineOfSight and LC.LineOfSight(eye, npc:EyePos(), ply) then
            local p = npc:GetPos()
            return "intel_patrol", string.format("p%d_%d", math.floor(p.x / 400), math.floor(p.y / 400)), "a unit's beat: where he walks, and when"
        end
    end
    return nil
end
LC.IntelHere = WhatsHere

function LC.Scout(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not Rebel(ply) then return false, "Intel is the Resistance's trade: the quartermaster buys it." end
    if not LC.HasItem(ply, "paper") then return false, "You need a sheet of paper to write on (the Commissary sells them)." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local id, key, what = WhatsHere(ply)
    if not id then return false, "Nothing worth writing down here. Get within sight of a checkpoint, a unit on his beat, or the Combine's own ground." end
    ply.lcIntelSeen = ply.lcIntelSeen or {}
    if (ply.lcIntelSeen[key] or 0) > CurTime() then return false, "You've written this one down already. It's old news for a while." end
    ply.lcScouting = true
    return LC.StartTask(ply, 15, "Writing down what you see... keep out of sight", {
        maxMove = 60, cancelText = "You put the paper away.",
        cancel = function(p) p.lcScouting = nil end,
        done = function(p)
            p.lcScouting = nil
            if not LC.TakeItem(p, "paper", 1) then return end
            LC.GiveOrDrop(p, id, 1)
            p.lcIntelSeen[key] = CurTime() + cvIntelMin:GetFloat() * 60
            Say(p, "Written down: " .. what .. ". The quartermaster pays for it.")
        end,
    })
end

-- A unit who sees you at it: the paper's taken, and he remembers your face.
timer.Create("LivingCityScouting", 1, 0, function()
    for _, p in ipairs(player.GetAll()) do
        if p.lcScouting and LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
            p.lcScouting = nil
            if LC.CancelTask then LC.CancelTask(p) end
            LC.TakeItem(p, "paper", 1)
            Say(p, "A Civil Protection unit sees you writing. He takes the paper off you, and looks hard at your face.")
            if LC.AddStanding then LC.AddStanding(p, -10, "Seen taking notes on Civil Protection") end
        end
    end
end)

LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.scout = function(ply)
    local ok, why = LC.Scout(ply)
    if not ok and why then Say(ply, why) end
end

------------------------------------------------------------------------
-- Forged ration cards: the search for the forger
------------------------------------------------------------------------

LC.ForgeryHeat = LC.ForgeryHeat or 0
-- Where the last batch was made (the lab): the sweep goes to the rebel territory nearest it.
function LC.ForgeryMade(pos) LC.ForgeryLab = pos end

function LC.ForgeryTurnedUp(n)
    local limit = cvHeat:GetFloat()
    if limit <= 0 then return false end
    LC.ForgeryHeat = LC.ForgeryHeat + (n or 1)
    LC.ForgeryCoolAt = CurTime() + cvCool:GetFloat() * 60
    if LC.ForgeryHeat < limit then return false end
    LC.ForgeryHeat = 0
    -- the forger: the rebel territory nearest the lab that made the last batch
    local best, bd
    local from = LC.ForgeryLab
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if not z.grown then
            local d = from and z.pos:DistToSqr(from) or math.random()
            if not bd or d < bd then best, bd = z, d end
        end
    end
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[City] Counterfeit ration cards are in circulation. Civil Protection is tracing them to their source. Report anything you know.")
    end
    if LC.RadioNotice then LC.RadioNotice("resistance", "They're onto the cards. They've traced them to one of our camps: a sweep is coming. Lie low.") end
    if best and LC.PlanCombineSweep then LC.PlanCombineSweep(best) end
    if LC.Log then LC.Log("info", "Forged ration cards traced: a sweep on the rebel territory at " .. tostring(best and best.pos)) end
    return true
end

timer.Create("LivingCityForgeryCool", 10, 0, function()
    if LC.ForgeryHeat > 0 and CurTime() >= (LC.ForgeryCoolAt or 0) then
        LC.ForgeryHeat = LC.ForgeryHeat - 1
        LC.ForgeryCoolAt = CurTime() + cvCool:GetFloat() * 60
    end
end)

-- turning up: sold to the dealer, or used at a dispenser
hook.Add("LivingCityForgedCard", "LivingCityForgery", function(ply, n) LC.ForgeryTurnedUp(n) end)
hook.Add("LivingCityLabMade", "LivingCityForgery", function(ply, out)
    if out == "ration_forged" and IsValid(ply) then LC.ForgeryMade(ply:GetPos()) end
end)
