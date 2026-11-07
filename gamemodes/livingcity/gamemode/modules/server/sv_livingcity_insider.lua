--[[
    Living City: the Resistance Insider (a Civil Protection unit secretly with the Resistance)

    Designed with the owner (2026-10-31; TODO.md). Becoming one is the story
    "The Man Inside" (sv_livingcity_stories.lua): a unit who keeps showing
    mercy is approached by a Resistance contact, proves themselves, and
    chooses to stay inside as the Resistance's spy. "Inside Work" then posts
    secret jobs on their board, and "Mole Hunt" comes when suspicion catches
    up with them.

    What an Insider can do besides, from the full menu (C > Civil Protection >
    Inside, and F2 > Inside: sv_livingcity_quickmore.lua), each only where nobody can see or hear them (no other player in
    sight within lc_insider_privacy, 700, or within earshot, 300; no unit
    watching): they have to slip away to do it.
      Tip off Freq 7         a message on the Resistance's band, unsigned,
                             with the next planned sweep or raid if there is
                             one (once every 2 minutes).
      Lose a record          a wanted citizen's record goes missing: they're
                             no longer wanted. Costs 25 Civil Standing (they
                             look a little incompetent, never disloyal).
      Supplies for a drop    at the Civil Protection Commissary: two bandages
                             and a box of pistol ammunition that aren't
                             issued, so they can be passed on (once every 10
                             minutes). Costs 10 Civil Standing.
      Copy the records       the city's own records, written out: the best
                             intel there is (the quartermaster pays 60). Once
                             every 15 minutes.
      Foul the filters       at the Commissary, with weedkiller: for lc_fouled_minutes (20)
                             every unit's mask lets gas through (once every 20 minutes).
      Spike the food         at the Commissary, with weedkiller: the units who eat at the
                             station fall sick over the next few minutes (once every 20).
      Let them slip          (also F2, and a line in "what you can do here" on
                             the right while one is within reach: bright when
                             nobody's watching, faint when someone is)
                             beside a prisoner being marched to the cells: you
                             take them off the escort's hands, and once it's
                             gone, the cuffs come off. A head start of 20
                             seconds; whoever still sees them then has them
                             wanted for escaping custody. Costs 20 Civil
                             Standing (it got away from you); once every 20
                             minutes. (The escort and the prisoner don't count
                             as watching: other people and units do.)
      Reveal myself          to the one person you're looking at: they learn
                             you're the Resistance's friend inside (the
                             codeword).
    Ordinary Resistance players don't know who the Insider is; the Resistance's
    leaders (its top two ranks) are told when one is recruited, and when they
    come on.

    Caught (Mole Hunt's exposure): that character is out of the system for
    good. Wanted and hunted (no surrendering), never Civil Protection or any
    Combine role again, never the city administration, never a Union job: a
    permanent Resistance member (PData lc_burned, by citizen number).

      lc_insider 0/1 (1), lc_insider_privacy (700)
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}
util.AddNetworkString("lc_insider")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_insider", "1", FLAGS, "A Civil Protection unit recruited by the Resistance can tip off Freq 7, lose records, take supplies and copy records, where nobody sees them")
local cvPrivacy = CreateConVar("lc_insider_privacy", "700", FLAGS, "How far away anyone who can see an Insider has to be before they can act")

local TIP_GAP, SKIM_GAP, COPY_GAP = 120, 600, 900
local LOSE_COST, SKIM_COST = 25, 10

local function Say(ply, text) if IsValid(ply) then ply:ChatPrint(text) end end

function LC.IsInsider(ply)
    return IsValid(ply) and ply:IsPlayer() and cvOn:GetBool() and LC.PlayerIsCP and LC.PlayerIsCP(ply)
        and LC.StoryFlag and LC.StoryFlag(ply, "insider") == true and not LC.StoryFlag(ply, "exposed")
        and not LC.StoryFlag(ply, "disgraced") -- (killed one of theirs in the loyalty test: not until the debt's paid)
end

-- Burned: this character was caught as the mole.
function LC.InsiderBurned(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and ply:GetPData("lc_burned", "") == cid
end

-- A unit (NPC) who can see them, leaving out the ones in ignore.
local function SecuritySees(ply, far, ignore)
    if not ignore then return LC.SeenBySecurity and LC.SeenBySecurity(ply, far) end
    if not (LC.IsSecurity and LC.UnitSees) then return false end
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and not ignore[npc] and LC.IsSecurity(st) and LC.UnitSees(npc, ply, far) then
            local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
            if tr.Fraction > 0.97 and not (LC.SmokeBlocks and LC.SmokeBlocks(npc:EyePos(), eye)) then return true end
        end
    end
    return false
end

-- Who could see or hear them right now (nobody: they can act). ignore: people and units
-- who don't count (a marched prisoner and their escort, for Let them slip).
function LC.InsiderWatched(ply, ignore)
    local far = cvPrivacy:GetFloat()
    local eye = ply:EyePos()
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and not (ignore and ignore[p]) then
            local d = p:GetPos():DistToSqr(ply:GetPos())
            if d < 300 * 300 then return true, "Someone's close enough to hear you." end
            if d < far * far and (not LC.LineOfSight or LC.LineOfSight(p:EyePos(), eye, p, ply)) then return true, "Someone can see you." end
        end
    end
    if SecuritySees(ply, far, ignore) then return true, "A Civil Protection unit can see you." end
    return false
end

local function Ready(ply, key, gap)
    local now = CurTime()
    ply.lcInsiderNext = ply.lcInsiderNext or {}
    local at = ply.lcInsiderNext[key] or 0
    if now < at then return false, string.format("Not yet: in %d seconds.", math.ceil(at - now)) end
    return true
end
local function Used(ply, key, gap) ply.lcInsiderNext[key] = CurTime() + gap end
-- Seconds before one of their actions (tip, skim, copy, foul, spike, slip) is open again: 0, now (F2 > Inside).
function LC.InsiderWait(ply, key)
    local at = IsValid(ply) and ply.lcInsiderNext and ply.lcInsiderNext[key] or 0
    return math.max(0, math.ceil(at - CurTime()))
end

-- The checks every Insider action makes first: true, or false and why.
local function CanAct(ply, ignore)
    if not LC.IsInsider(ply) then return false, "Nothing like that is open to you." end
    if not ply:Alive() or (LC.InCustody and LC.InCustody(ply)) then return false, "Not now." end
    local watched, why = LC.InsiderWatched(ply, ignore)
    if watched then return false, why .. " Slip away somewhere nobody's watching first." end
    return true
end

------------------------------------------------------------------------
-- What they can do
------------------------------------------------------------------------

local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end

function LC.InsiderTip(ply, text)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    ok, why = Ready(ply, "tip", TIP_GAP)
    if not ok then return false, why end
    text = string.Trim(string.sub(tostring(text or ""), 1, 180))
    local extra = {}
    local now = CurTime()
    if LC.PlannedSweep and LC.PlannedSweep.zone then
        extra[#extra + 1] = string.format("a sweep into our ground %s in about %d seconds", Where(LC.PlannedSweep.zone.pos), math.max(0, math.ceil(LC.PlannedSweep.at - now)))
    end
    if LC.Event == "raid" or LC.RaidPlanned then extra[#extra + 1] = "a housing block raid is on" end
    local bolos = GetGlobal2Float("lc_bolos", 0)
    if bolos > 0 then extra[#extra + 1] = string.format("%d BOLO%s out", bolos, bolos == 1 and "" or "s") end
    if text == "" and #extra == 0 then return false, "Say what to tell them." end
    local msg = "A friend inside: " .. (text ~= "" and text or "") .. (#extra > 0 and ((text ~= "" and " " or "") .. "(" .. table.concat(extra, "; ") .. ")") or "")
    if LC.RadioNotice then LC.RadioNotice("resistance", msg) end
    Used(ply, "tip", TIP_GAP)
    Say(ply, "[Inside] Sent on Freq 7, unsigned.")
    hook.Run("LivingCityInsiderAct", ply, "tip")
    return true
end

function LC.InsiderLoseRecord(ply, target)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    if not IsValid(target) or not target:IsPlayer() then return false, "No such person." end
    if not (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) then return false, "They aren't wanted." end
    LC.ClearWanted(target)
    if LC.AddStanding then LC.AddStanding(ply, -LOSE_COST, "A record lost through carelessness") end
    Say(ply, string.format("[Inside] Their record goes missing. Somebody will call it carelessness (-%d Civil Standing).", LOSE_COST))
    Say(target, "[City] Your record seems to have gone missing. Nobody is looking for you, for now.")
    hook.Run("LivingCityInsiderAct", ply, "lose")
    return true
end

function LC.InsiderSkim(ply)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    if LC.NearCPSupply and not LC.NearCPSupply(ply) then return false, "Only at the Civil Protection Commissary." end
    ok, why = Ready(ply, "skim", SKIM_GAP)
    if not ok then return false, why end
    local got = {}
    if LC.GiveItem(ply, "bandage", 2) then got[#got + 1] = "2 bandages" end
    if LCS.Items.ammo_pistol and LC.GiveItem(ply, "ammo_pistol", 1) then got[#got + 1] = "a box of pistol ammunition" end
    if #got == 0 then return false, "Your pockets are full." end
    Used(ply, "skim", SKIM_GAP)
    if LC.AddStanding then LC.AddStanding(ply, -SKIM_COST, "Supplies unaccounted for") end
    Say(ply, string.format("[Inside] Off the shelf and into your pockets, not on the books: %s. Leave them in a bin for the Resistance (-%d Civil Standing).", table.concat(got, " and "), SKIM_COST))
    hook.Run("LivingCityInsiderAct", ply, "skim")
    return true
end

function LC.InsiderCopy(ply)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    ok, why = Ready(ply, "copy", COPY_GAP)
    if not ok then return false, why end
    if not LC.GiveItem(ply, "intel_records", 1) then return false, "Your pockets are full." end
    Used(ply, "copy", COPY_GAP)
    Say(ply, "[Inside] You copy out the city's own records: names, routes, who's being watched. The quartermaster pays the most for this.")
    hook.Run("LivingCityInsiderAct", ply, "copy")
    return true
end

-- At the Civil Protection Commissary, with weedkiller: foul the filter stock (every unit's mask lets
-- gas through for lc_fouled_minutes), or spike the station's food (units fall sick).
local FOUL_GAP, SPIKE_GAP = 1200, 1200
function LC.InsiderFoul(ply)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    if LC.NearCPSupply and not LC.NearCPSupply(ply) then return false, "Only at the Civil Protection Commissary, where the spare filters are kept." end
    if not LC.HasItem(ply, "weedkiller") then return false, "You'd need weedkiller to soak them in." end
    ok, why = Ready(ply, "foul", FOUL_GAP)
    if not ok then return false, why end
    LC.TakeItem(ply, "weedkiller", 1)
    if LC.FoulFilters then LC.FoulFilters() end
    Used(ply, "foul", FOUL_GAP)
    Say(ply, "[Inside] You soak the spare filter canisters and put them back. For a while, every unit's mask will let gas straight through: theirs as much as anyone's.")
    if LC.RadioNotice then LC.RadioNotice("resistance", "A friend inside: their mask filters are fouled. For a while, gas will get to them too.") end
    hook.Run("LivingCityInsiderAct", ply, "foul")
    return true
end

function LC.InsiderSpike(ply)
    local ok, why = CanAct(ply)
    if not ok then return false, why end
    if LC.NearCPSupply and not LC.NearCPSupply(ply) then return false, "Only at the Civil Protection Commissary, where the station's food is kept." end
    if not LC.HasItem(ply, "weedkiller") then return false, "You'd need weedkiller." end
    ok, why = Ready(ply, "spike", SPIKE_GAP)
    if not ok then return false, why end
    LC.TakeItem(ply, "weedkiller", 1)
    Used(ply, "spike", SPIKE_GAP)
    local at = ply:GetPos()
    Say(ply, "[Inside] A few drops into the station's coffee and rations. Over the next few minutes, the units who eat here will be sick. Don't eat here yourself.")
    -- each unit eats sometime in the next few minutes
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and LC.PlayerIsCP(p) then
            timer.Simple(math.Rand(30, 240), function()
                if not IsValid(p) or not p:Alive() or not LC.PlayerIsCP(p) then return end
                p:SetHealth(math.max(1, p:Health() - 30))
                p:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 70)
                if LC.Notice then LC.Notice(p, "warn", "Something you ate", "The station's coffee tasted wrong. Your stomach turns over: you've been poisoned.", 8) end
            end)
        end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and npc:GetPos():DistToSqr(at) < 3000 * 3000 then
            timer.Simple(math.Rand(30, 240), function() if IsValid(npc) and npc:Health() > 0 then npc:TakeDamage(30, game.GetWorld(), game.GetWorld()) end end)
        end
    end
    hook.Run("LivingCityInsiderAct", ply, "spike")
    return true
end

-- Let them slip: a prisoner being marched to the cells (sv_livingcity_march.lua), let go on the
-- way. The Insider takes them off the escort's hands; once it's gone, the cuffs come off and they
-- have a head start. Whoever still sees them at the end of it has them wanted for escaping custody;
-- out of sight by then, they got clean away. It got away from the Insider: they look careless.
local SLIP_GAP, SLIP_COST, SLIP_NEAR, SLIP_HEAD = 1200, 20, 300, 20
LC.InsiderSlipHeadStart = SLIP_HEAD

-- The prisoner being marched nearest them, within reach (or nil).
function LC.InsiderMarchNear(ply)
    local best, bd
    for p in pairs(LC.Marching or {}) do
        if IsValid(p) and p ~= ply then
            local d = p:GetPos():DistToSqr(ply:GetPos())
            if d < SLIP_NEAR * SLIP_NEAR and (not bd or d < bd) then best, bd = p, d end
        end
    end
    return best
end

-- Out of sight, or not: at the end of the head start.
function LC.InsiderSlipSeen(target)
    if LC.SeenBySecurity and LC.SeenBySecurity(target, 1500) then return true end
    local eye = target:EyePos()
    for _, p in ipairs(player.GetAll()) do
        if p ~= target and p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p) and not LC.IsInsider(p)
            and p:GetPos():DistToSqr(target:GetPos()) < 1500 * 1500
            and (not LC.LineOfSight or LC.LineOfSight(p:EyePos(), eye, p, target)) then return true end
    end
    return false
end

local function SlipOver(target, where)
    if not IsValid(target) or not target:IsPlayer() or not target.lcSlipped then return end
    target.lcSlipped = nil
    if not target:Alive() or (LC.InCustody and LC.InCustody(target)) or (LC.Marching and LC.Marching[target]) then return end
    if LC.InsiderSlipSeen(target) then
        local esc = GetConVar("lc_escape_wanted")
        if LC.ReportCrime then LC.ReportCrime(target, "Escaping custody", esc and esc:GetFloat() or 300) end
        if LC.Notice then LC.Notice(target, "warn", "Spotted", "They've seen you: you're wanted for escaping custody. Run.", 8) end
        if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: prisoner in transit has escaped custody" .. (where ~= "" and (", " .. where) or "") .. ". Locate and detain.") end
    else
        if LC.Notice then LC.Notice(target, "info", "Clean away", "Nobody saw which way you went. As far as the city knows, you got away from your escort. Lie low for a while.", 8) end
        if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: a prisoner in transit is missing" .. (where ~= "" and (", " .. where) or "") .. ". No sighting.") end
    end
    if LC.RadioNotice then LC.RadioNotice("resistance", "One of ours got away on the march to the cells.") end
end

-- The prisoner and their escort: they don't count as watching.
local function SlipIgnore(target)
    local m = LC.Marching[target] or {}
    local ignore = { [target] = true }
    if IsValid(m.lead) then ignore[m.lead] = true end
    if IsValid(m.rear) then ignore[m.rear] = true end
    return ignore
end

-- What the Insider's own screen shows (the hint on the right, and F2): the marched prisoner
-- within reach (or nil), and "" (they can do it now), "watched" or "soon" (not again yet).
function LC.InsiderSlipState(ply)
    if not LC.IsInsider(ply) or not ply:Alive() or (LC.InCustody and LC.InCustody(ply)) then return nil end
    local target = LC.InsiderMarchNear(ply)
    if not IsValid(target) then return nil end
    if LC.InsiderWatched(ply, SlipIgnore(target)) then return target, "watched" end
    if not Ready(ply, "slip", SLIP_GAP) then return target, "soon" end
    return target, ""
end

function LC.InsiderLetSlip(ply, target)
    if not LC.IsInsider(ply) then return false, "Nothing like that is open to you." end
    if not (IsValid(target) and LC.Marching and LC.Marching[target]) then target = LC.InsiderMarchNear(ply) end
    if not IsValid(target) then return false, "Nobody's being marched to the cells near you." end
    if target:GetPos():DistToSqr(ply:GetPos()) > SLIP_NEAR * SLIP_NEAR then return false, "Get closer to the prisoner first." end
    local ok, why = CanAct(ply, SlipIgnore(target))
    if not ok then return false, why end
    ok, why = Ready(ply, "slip", SLIP_GAP)
    if not ok then return false, why end
    if not (LC.MarchRelease and LC.MarchRelease(target)) then return false, "Not now." end
    if LC.Untie and LC.IsTied and LC.IsTied(target) then LC.Untie(target, ply, true) end
    if LC.ClearWanted then LC.ClearWanted(target) end
    Used(ply, "slip", SLIP_GAP)
    if LC.AddStanding then LC.AddStanding(ply, -SLIP_COST, "A prisoner lost on the march") end
    Say(ply, string.format("[Inside] You tell the escort you'll take this one in yourself. Once they've gone, the cuffs come off and you look the other way. It will look like they got away from you (-%d Civil Standing).", SLIP_COST))
    if LC.Notice then
        LC.Notice(target, "info", "Let go", string.format("Your cuffs come off and someone says, low: \"Go. Now.\" Nobody's after you yet: get out of sight within %d seconds, or they'll want you for escaping.", SLIP_HEAD), 10)
    end
    target.lcSlipped = true
    local where = Where(target:GetPos())
    timer.Simple(SLIP_HEAD, function() SlipOver(target, where) end)
    hook.Run("LivingCityInsiderAct", ply, "slip")
    return true
end

function LC.InsiderReveal(ply, target)
    if not LC.IsInsider(ply) then return false, "Nothing like that is open to you." end
    if not IsValid(target) or not target:IsPlayer() or target == ply then return false, "Look at the one person you want to tell." end
    if target:GetPos():DistToSqr(ply:GetPos()) > 160 * 160 then return false, "Get closer: this is said quietly." end
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    Say(target, "[Freq 7] " .. name .. " leans in and says the codeword. This unit is the Resistance's friend inside. Keep it to yourself.")
    Say(ply, "[Inside] You say the codeword. They know now.")
    if LC.LearnName then pcall(LC.LearnName, target, ply) end
    return true
end

------------------------------------------------------------------------
-- Caught: out of the system for good
------------------------------------------------------------------------

function LC.BurnInsider(ply)
    if not IsValid(ply) then return end
    local cid = ply:GetNW2String("lc_cid", "")
    if cid ~= "" then ply:SetPData("lc_burned", cid) end
    LC.StoryFlag(ply, "insider", false)
    LC.StoryFlag(ply, "exposed", true)
    if LC.SetFaction then LC.SetFaction(ply, "resistance", nil, true, true) end
    if LC.ReportCrime then LC.ReportCrime(ply, "Treason: a mole in Civil Protection", 900) end
    if LC.Notice then
        LC.Notice(ply, "warn", "Exposed", "They know you were the Resistance's man inside. You're wanted, and there's no surrendering. "
            .. "You'll never wear the mask again, nor work for the city or the Union: you're Resistance now, for good.", 14)
    end
    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: all units, a traitor in our ranks. Shoot on sight. No surrender accepted.") end
end

-- Unmasked (the reckoning, sv_livingcity_stories.lua): no longer undercover, an ordinary Resistance
-- fighter; never Civil Protection (or anyone's man inside) again. Not wanted for it.
function LC.Unmask(ply)
    if not IsValid(ply) then return end
    local cid = ply:GetNW2String("lc_cid", "")
    if cid ~= "" then ply:SetPData("lc_unmasked", cid) end
    LC.StoryFlag(ply, "insider", false)
    if LC.SetFaction then LC.SetFaction(ply, "resistance", nil, true, true) end
    if LC.Notice then LC.Notice(ply, "info", "Out of the mask", "You're Resistance now, in the open. Civil Protection will never have you back.", 10) end
end
function LC.InsiderUnmasked(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and ply:GetPData("lc_unmasked", "") == cid
end

-- No deals for a traitor: no surrendering (sv_livingcity_prison.lua asks), no Combine role, no Union job.
local COMBINE_SIDE = { cp = true, ota = true, admin = true }
function LC.InsiderBarred(ply, what, fid)
    if not LC.InsiderBurned(ply) then
        -- unmasked: just never a unit (or any Combine role) again
        if what == "faction" and COMBINE_SIDE[fid or "cp"] and LC.InsiderUnmasked(ply) then return "You took off the mask for good. Civil Protection will never have you back: only the Resistance." end
        return nil
    end
    if what == "surrender" then return "They know what you did. There's no surrendering for you." end
    if what == "job" then return "The Union won't have a traitor on its books." end
    return "You're known as a traitor. Only the Resistance will have you now."
end

------------------------------------------------------------------------
-- Telling the right people
------------------------------------------------------------------------

local function IsLeader(p)
    if not IsValid(p) or p:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    local f = LCF and LCF.Get and LCF.Get("resistance")
    local top = f and f.ranks and #f.ranks or 5
    return p:GetNW2Int("lcf_rank", 1) >= top - 1
end
LC.InsiderLeader = IsLeader

local function Name(p) return LC.CharacterName and LC.CharacterName(p) or p:Nick() end

-- Each Insider's own menu shows (sent to them alone: nobody else's game knows).
local function SendFlag(p, on)
    net.Start("lc_insider")
    net.WriteBool(on)
    net.Send(p)
end

timer.Create("LivingCityInsider", 5, 0, function()
    for _, p in ipairs(player.GetAll()) do
        local on = LC.IsInsider(p)
        if p.lcInsiderSent ~= on then
            local was = p.lcInsiderSent
            p.lcInsiderSent = on
            SendFlag(p, on)
            if on and was == false then
                -- newly recruited: the leaders hear of it
                for _, l in ipairs(player.GetAll()) do
                    if IsLeader(l) then Say(l, "[Freq 7] For the leaders only: we have a friend inside Civil Protection now. " .. Name(p) .. ". Keep it close.") end
                end
            end
        end
    end
end)

-- Let them slip, on the Insider's own screen: while a marched prisoner is within reach, twice a
-- second, whether they can do it now (sent to them alone, and only when it changes).
util.AddNetworkString("lc_insider_slip")
function LC.InsiderSlipTick()
    local any = next(LC.Marching or {}) ~= nil
    for _, p in ipairs(player.GetAll()) do
        local target, why
        if any then target, why = LC.InsiderSlipState(p) end
        local key = IsValid(target) and (target:EntIndex() .. ":" .. why) or ""
        if (p.lcSlipSent or "") ~= key then
            p.lcSlipSent = key
            net.Start("lc_insider_slip")
            net.WriteBool(IsValid(target))
            if IsValid(target) then
                net.WriteEntity(target)
                net.WriteString(why or "")
            end
            net.Send(p)
        end
    end
end
timer.Create("LivingCityInsiderSlip", 0.5, 0, function() LC.InsiderSlipTick() end)

-- A leader coming on hears who's inside, once.
hook.Add("PlayerSpawn", "LivingCityInsiderLeaders", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) or ply.lcInsiderToldLeader or not IsLeader(ply) then return end
        local names = {}
        for _, p in ipairs(player.GetAll()) do if LC.IsInsider(p) then names[#names + 1] = Name(p) end end
        if #names > 0 then
            ply.lcInsiderToldLeader = true
            Say(ply, "[Freq 7] For the leaders only: our friends inside Civil Protection: " .. table.concat(names, ", ") .. ".")
        end
    end)
end)

------------------------------------------------------------------------
-- From the menus (and chat, as a backup)
------------------------------------------------------------------------

local function Reply(ply, ok, why) if not ok and why then Say(ply, "[Inside] " .. why) end end
local function Looked(ply)
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    return IsValid(e) and e:IsPlayer() and e or nil
end
local function FindPlayer(text)
    text = string.lower(string.Trim(text or ""))
    if text == "" then return nil end
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(Name(p)), text, 1, true) or string.find(string.lower(p:Nick()), text, 1, true) then return p end
    end
    return nil
end

LC.SlashCommands.tipoff = function(ply, rest) Reply(ply, LC.InsiderTip(ply, rest)) end
LC.SlashCommands.loserecord = function(ply, rest) Reply(ply, LC.InsiderLoseRecord(ply, FindPlayer(rest) or Looked(ply))) end
LC.SlashCommands.skim = function(ply) Reply(ply, LC.InsiderSkim(ply)) end
LC.SlashCommands.copyrecords = function(ply) Reply(ply, LC.InsiderCopy(ply)) end
LC.SlashCommands.reveal = function(ply) Reply(ply, LC.InsiderReveal(ply, Looked(ply))) end
LC.SlashCommands.letslip = function(ply, rest) Reply(ply, LC.InsiderLetSlip(ply, FindPlayer(rest) or Looked(ply))) end
LC.SlashCommands.foulfilters = function(ply) Reply(ply, LC.InsiderFoul(ply)) end
LC.SlashCommands.spikefood = function(ply) Reply(ply, LC.InsiderSpike(ply)) end
if LC.MenuActions then
    for _, c in ipairs({ "tipoff", "loserecord", "skim", "copyrecords", "reveal", "foulfilters", "spikefood", "letslip" }) do LC.MenuActions[c] = true end
end
