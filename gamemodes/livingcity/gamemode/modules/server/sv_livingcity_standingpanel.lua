--[[
    Living City: "Where I stand", every number in one place, each explained
    (the owner, 10 November: "too many numbers, yes please to your
    suggestion").

    F2 > Me > My standing (or Where I stand) (and C > You > Where I stand) opens one window:
    Civil Standing and its tier, credits, ration cards, rank and experience,
    the three traits (loyalty, sympathy, corruption), wanted or not and how
    to give yourself up, the record since your last sentence and what it
    would come to, probation, conduct strikes, survival mode, close calls
    and lives, and the dreams you can sit out. Each with a line on what it
    is and what it does. Nothing here changes anything: it only shows.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_standing_panel") -- (client asks; server answers with the rows)

local function Cv(name, def) local c = GetConVar(name) return c and c:GetFloat() or def end

-- The rows: { group, label, value, explain, warn }.
function LC.StandingRows(ply)
    local rows = {}
    local function Row(group, label, value, explain, warn)
        rows[#rows + 1] = { g = group, l = label, v = tostring(value or ""), e = explain or "", w = warn or nil }
    end
    local f = ply:GetNW2String("lcf_faction", "")
    local citizenish = f == "" or f == "citizen" or f == "resistance"

    -- the city's view of you
    local s = LC.Standing and LC.Standing(ply) or 0
    local tier = s >= 400 and "Exemplary" or (s >= 150 and "Trusted" or (s < 0 and "Anticitizen" or "Ordinary"))
    Row("The city's view of you", "Civil Standing", string.format("%d (%s)", s, tier),
        "What the Combine thinks of you, from -1000 to 1000. Work, rations and obedience raise it; crimes, contraband and missed curfews lower it. "
        .. "Trusted (150): fewer stops, 10% more pay, a discount, full rations. Exemplary (400): searches waved through, 25% more pay, a slip forgiven, and you may sit out nightmares and propaganda dreams. "
        .. "Below 0 you can do community service to win it back.", s < 0)
    Row("The city's view of you", "Credits", LC.Credits and LC.Credits(ply) or 0,
        "Money. Shifts and jobs pay it; the Commissary, rent and the black market take it. Hoarding above 2000 is taxed now and then.")
    if citizenish and LC.RationCards then
        Row("The city's view of you", "Ration cards", LC.RationCards(ply),
            "One for each Union shift you finish; a ration at a dispenser takes one. No card, no ration.")
    end

    -- your side
    local fac = LCF and LCF.Get and LCF.Get(f)
    if fac and fac.ranks then
        local ri = ply:GetNW2Int("lcf_rank", 1)
        local r = fac.ranks[ri] or fac.ranks[1]
        local xp = tonumber(ply:GetPData("lcf_xp_" .. fac.id, 0)) or 0
        local nxt = fac.ranks[ri + 1]
        Row("Your side", "Rank", string.format("%s, %s", fac.name or f, r and r.name or "?"),
            nxt and string.format("Next: %s at %d experience.", nxt.name, nxt.xp or 0) or "The top of your side's ranks.")
        Row("Your side", "Experience", xp,
            "Earned on your side's work and jobs (F4). It's what promotes you." .. (LC.SurvivalXPMul and LC.SurvivalXPMul(ply) > 1 and " Realistic survival: 20% more." or ""))
    end
    if LC.Trait then
        local sym = LC.Trait(ply, "sympathy")
        local need = Cv("lc_resistance_join_sympathy", 5)
        Row("Your side", "Loyalty", LC.Trait(ply, "loyalty"),
            "Built by choices that side with the Combine in jobs and stories. It helps your dice on the Combine's side of things.")
        Row("Your side", "Sympathy", sym,
            "Help given to the Resistance (their jobs, food for their crate, arms to their quartermaster, siding with the vortigaunts in a dream). "
            .. (f == "resistance" and "You're one of them." or (sym >= need and "The Resistance trusts you enough to let you join." or string.format("The Resistance lets you join at %d.", need))))
        Row("Your side", "Corruption", LC.Trait(ply, "corruption"),
            "Bribes, theft and shady deals. Some jobs open up with it; Internal Affairs takes an interest.")
    end

    -- trouble
    local wanted = ply:GetNW2Float("lc_wanted_until", 0) > CurTime() and LC.PlayerIsWanted and LC.PlayerIsWanted(ply)
    Row("Trouble", "Wanted", wanted and ("Yes: " .. ply:GetNW2String("lc_wanted_reason", "")) or "No",
        "Wanted, units chase you. To give yourself up (half the sentence): walk up to a Civil Protection unit and press E on them, or F1 > Give myself up near one. "
        .. "Out of every unit's sight long enough, they lose track of you.", wanted)
    if LC.RapSheet then
        local r = LC.RapSheet(ply)
        local total, names = 0, {}
        for _, c in ipairs(r) do total = total + (c.min or 0) names[#names + 1] = string.format("%s (%d)", c.reason, c.min or 0) end
        total = math.min(total, Cv("lc_sentence_max", 30))
        Row("Trouble", "Record since your last sentence", #r == 0 and "Clean" or (table.concat(names, ", ") .. string.format(": %d minutes", total)),
            "If you're arrested, your sentence adds these up (petty 3 minutes, up to 20 for murdering a unit; 30 at most). It's cleared when you serve it.", #r > 0)
    end
    if LC.OnProbation and LC.OnProbation(ply) then
        Row("Trouble", "Probation", string.format("%s left%s", string.NiceTime(math.max(0, (ply.lcProbationUntil or 0) - CurTime())), ply.lcProbationChecked and ", checked in" or ", NOT checked in"),
            "Check in with a Civil Protection unit (F1, standing close to one). Anything new counts double. Stay out of rebel territory and away from the Resistance.", not ply.lcProbationChecked)
    end
    if LC.StrikeCount then
        local n = LC.StrikeCount(ply)
        Row("Trouble", "Conduct strikes", n, "Staff warnings for breaking the server's rules (not the city's laws). Enough of them and staff step in.", n > 0)
    end

    -- you
    if LC.SurvivalMode and GetConVar("lc_survival_modes") and GetConVar("lc_survival_modes"):GetBool() then
        local relaxed = LC.Relaxed(ply)
        Row("You", "Survival", relaxed and "Relaxed" or "Realistic",
            relaxed and "Slow hunger and thirst; no parasites, toilet, washing or food going off. (Realistic pays 20% more.) Switch: F2 > Me, every 3 hours."
            or "Every need, as the city really is. 20% more shift pay and experience, and the title Hardened. Switch: F2 > Me, every 3 hours.")
    end
    if LC.CloseCallsLeft then
        local left = LC.CloseCallsLeft(ply)
        Row("You", "Close calls", left, "Times you can go down and live. Out of them, the next death is the end of this person (they come back every few hours).", left == 0)
    end
    if LC.Legacy then
        local lg = LC.Legacy(ply) or {}
        local title = LC.LegacyTitle and LC.LegacyTitle(ply) or ""
        Row("You", "Lives lived", string.format("%d%s", lg.lives or 0, title ~= "" and (" (" .. title .. ")") or ""),
            "Every person you've been before this one. Titles come with many lives behind you; never power or money.")
    end
    if LC.HouseholdOf then
        local _, h = LC.HouseholdOf(ply)
        Row("You", "Household", h and h.name or "None",
            "Who you live with: the same block, each other's crates and lockers, the head's apartment keys. F2 > Me (More) > My household.")
    end
    if LC.DreamSkipEarned then
        local kinds = {}
        for _, k in ipairs({ { "happy", "Happy" }, { "neutral", "Neutral" }, { "nightmare", "Nightmares" }, { "propaganda", "propaganda" } }) do
            if LC.DreamSkipEarned(ply, k[1]) == true then kinds[#kinds + 1] = k[2] end
        end
        Row("You", "Dreams you may sit out", #kinds > 0 and table.concat(kinds, ", ") or "None yet",
            "Happy or Neutral dreams after living through 2 of that kind; nightmares and propaganda with Exemplary standing (citizens). Choose in F2 > Me (More) > My dreams.")
    end
    return rows
end

function LC.SendStandingPanel(ply)
    if not IsValid(ply) then return false end
    local ok, rows = LC.Try(LC.StandingRows, ply)
    if not ok then
        if LC.Error then LC.Error("standing panel", rows) end
        return false
    end
    net.Start("lc_standing_panel")
    net.WriteString(util.TableToJSON(rows) or "[]")
    net.Send(ply)
    return true
end

net.Receive("lc_standing_panel", function(_, ply)
    if (ply.lcStandingPanelNext or 0) > CurTime() then return end
    ply.lcStandingPanelNext = CurTime() + 1
    LC.SendStandingPanel(ply)
end)
