--[[
    Living City: crime between citizens (the owner, 10 November: "citizen
    crime: pickpocketing, debts, deals that go bad"; "I love it all").

    Pickpocketing. From behind someone (not a unit), close: F1 > "Pick their
    pocket" (three seconds, keep still). They may feel it: more likely if
    they turn to face you. Done unnoticed, you have some of their credits (up
    to 20) or one thing from their pockets (never their papers). Felt, they're
    told whose hand it was (or a description, if they don't know you), and
    nothing's taken. Either way a unit who sees it, or a snitch, makes it
    Theft. Once every two minutes for a thief; the same mark, once in five.

    Debts. F1 on someone > "Lend (name) money": 10, 25 or 50 credits; they
    accept on F2 > Me (More) > My debts (or turn it down). It's due back in
    lc_debt_hours (2) with a fifth more on top. The borrower repays on the
    same page (the lender needn't be about: it's waiting for them). Overdue,
    the lender can report it to Civil Protection (Debt default: a petty crime
    and 10 standing off the borrower) from their own F2 > Me (More) > My debts.
    Kept on the characters (who owes whom, how much, by when).

    Deals that go bad. Buying from a black market dealer (not the
    quartermaster), lc_bad_deal_chance (6%) of the time it goes wrong: the
    goods are fake (a brick in a bag, the credits gone), or it was a sting
    (the sale goes through, and Civil Protection have you for it).

      lc_pickpocket 0/1, lc_debt_hours (2), lc_bad_deal_chance (0.06)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPick  = CreateConVar("lc_pickpocket", "1", FLAGS, "Citizens can pick each other's pockets (from behind, close)")
local cvDebt  = CreateConVar("lc_debt_hours", "2", FLAGS, "Real hours a loan between players is due back in")
local cvDeal  = CreateConVar("lc_bad_deal_chance", "0.06", FLAGS, "Chance a black market purchase goes bad: fake goods, or a sting")

local THIEF_GAP, MARK_GAP = 120, 300
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function CID(p) local c = IsValid(p) and p:GetNW2String("lc_cid", "") or "" return c ~= "" and c or ("sid:" .. (IsValid(p) and p:SteamID() or "")) end
local function ByCID(cid) for _, p in ipairs(player.GetAll()) do if CID(p) == cid then return p end end end
local function Citizenish(p) local f = p:GetNW2String("lcf_faction", "") return f == "" or f == "citizen" or f == "resistance" or f == "vort" end

------------------------------------------------------------------------
-- Pickpocketing
------------------------------------------------------------------------

local function Behind(thief, mark)
    local to = thief:GetPos() - mark:GetPos()
    to.z = 0
    if to:LengthSqr() < 1 then return false end
    local f = mark:GetForward()
    f.z = 0
    return f:GetNormalized():Dot(to:GetNormalized()) < -0.3
end

local function SeenBy(thief)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.role == "cop" or st.role == "soldier") and npc:GetPos():DistToSqr(thief:GetPos()) < 700 * 700
            and (not LC.LineOfSight or LC.LineOfSight(npc:EyePos(), thief:EyePos(), { npc, thief }, thief)) then return true end
    end
    return false
end

function LC.Pickpocket(thief, mark)
    if not cvPick:GetBool() then return false, "Not here." end
    if not IsValid(mark) or not mark:IsPlayer() or mark == thief then return false, "Get behind someone, close." end
    if LC.PlayerIsCP(thief) then return false, "A unit doesn't pick pockets." end
    if LC.PlayerIsCP(mark) then return false, "A unit's pockets? Not if you want to keep your hands." end
    if thief:GetPos():DistToSqr(mark:GetPos()) > 80 * 80 then return false, "Closer." end
    if not Behind(thief, mark) then return false, "From behind, where they can't see you." end
    if (thief.lcPickNext or 0) > CurTime() then return false, "Not so soon after the last one." end
    if (mark.lcPickedAt or 0) + MARK_GAP > CurTime() then return false, "They're keeping a hand on their pockets now." end
    thief.lcPickNext = CurTime() + THIEF_GAP
    return LC.StartTask(thief, 3, "Lifting it out...", { maxMove = 30, cancelText = "You pull your hand back.",
        done = function(p)
            if not IsValid(mark) then return end
            mark.lcPickedAt = CurTime()
            local felt = math.random() < (Behind(p, mark) and 0.35 or 0.75) or p:GetPos():DistToSqr(mark:GetPos()) > 90 * 90
            local seen = SeenBy(p)
            if LC.IllegalAct then LC.IllegalAct(p, "picking a pocket") end
            if seen then LC.ReportCrime(p, "Theft", 180) end
            if felt then
                local who = (LC.Recognizes and LC.Recognizes(mark, p)) and Name(p) or (p:GetNW2String("lc_desc", "") ~= "" and p:GetNW2String("lc_desc", "") or "someone")
                mark:ChatPrint("[Miscount] A hand in your pocket! " .. who .. ".")
                if LC.Notice then LC.Notice(mark, "warn", "A pickpocket", "Someone tried your pockets: " .. who .. ".", 8) end
                p:ChatPrint("[Miscount] They felt it. You come away with nothing.")
                hook.Run("LivingCityPickpocket", p, mark, false)
                return
            end
            local inv = LC.Inventory and LC.Inventory(mark) or {}
            local ids = {}
            for id, n in pairs(inv) do if n > 0 and id ~= "id_papers" and id ~= "ration_card" then ids[#ids + 1] = id end end
            local cr = LC.Credits and LC.Credits(mark) or 0
            if cr > 0 and (#ids == 0 or math.random() < 0.5) then
                local take = math.min(20, cr, math.random(5, 20))
                LC.AddCredits(mark, -take)
                LC.AddCredits(p, take, "a lifted wallet")
                p:ChatPrint(string.format("[Miscount] %d credits, and they never felt a thing.", take))
            elseif #ids > 0 then
                local id = ids[math.random(#ids)]
                if LC.TakeItem(mark, id, 1) then
                    LC.GiveItem(p, id, 1)
                    p:ChatPrint("[Miscount] You come away with: " .. ((LCS.Items[id] and LCS.Items[id].name) or id) .. ". They never felt a thing.")
                end
            else
                p:ChatPrint("[Miscount] Empty pockets.")
            end
            hook.Run("LivingCityPickpocket", p, mark, true)
        end })
end

------------------------------------------------------------------------
-- Debts
------------------------------------------------------------------------

-- Each character's debts: { { lender = cid, lenderName, borrower = cid, borrowerName, owed, due (os time) } } kept on the borrower,
-- and a copy of what's owed to them on the lender.
local function Owes(p) local t = util.JSONToTable(p:GetPData("lc_debts", "") or "") return istable(t) and t or {} end
local function SaveOwes(p, t) if #t == 0 then p:RemovePData("lc_debts") else p:SetPData("lc_debts", util.TableToJSON(t)) end end
local function Owed(p) local t = util.JSONToTable(p:GetPData("lc_lent", "") or "") return istable(t) and t or {} end
local function SaveOwed(p, t) if #t == 0 then p:RemovePData("lc_lent") else p:SetPData("lc_lent", util.TableToJSON(t)) end end
-- repayments waiting for a lender who wasn't about: { [cid] = credits }
local PENDING_FILE = "livingcity/debts_paid.json"
local function Pending() local t = LC.SafeReadJSON and LC.SafeReadJSON(PENDING_FILE) return istable(t) and t or {} end
local function SavePending(t) if file and file.Write and LC.SafeWrite then if file.CreateDir then file.CreateDir("livingcity") end LC.SafeWrite(PENDING_FILE, util.TableToJSON(t)) end end

local function SyncDebts(p)
    local t = { owes = {}, owed = {}, offer = p.lcLoanOffer and { from = Name(p.lcLoanOffer.from), n = p.lcLoanOffer.n } or nil }
    for _, d in ipairs(Owes(p)) do t.owes[#t.owes + 1] = { to = d.lenderName, n = d.owed, left = d.due - os.time() } end
    for _, d in ipairs(Owed(p)) do t.owed[#t.owed + 1] = { by = d.borrowerName, n = d.owed, left = d.due - os.time(), reported = d.reported or nil } end
    p:SetNW2String("lc_debts", util.TableToJSON(t) or "")
end
LC.SyncDebts = SyncDebts

function LC.OfferLoan(lender, borrower, n)
    n = tonumber(n)
    if n ~= 10 and n ~= 25 and n ~= 50 then n = 25 end
    if not IsValid(borrower) or not borrower:IsPlayer() or borrower == lender then return false, "Look at who you want to lend to." end
    if lender:GetPos():DistToSqr(borrower:GetPos()) > 250 * 250 then return false, "Face to face." end
    if (LC.Credits and LC.Credits(lender) or 0) < n then return false, "You haven't that much." end
    borrower.lcLoanOffer = { from = lender, n = n, at = CurTime() }
    borrower:ChatPrint(string.format("[Miscount] %s offers to lend you %d credits, %d back within %d hours. F2 > Me (More) > My debts.", Name(lender), n, math.ceil(n * 1.2), cvDebt:GetInt()))
    lender:ChatPrint("[Miscount] You've offered " .. Name(borrower) .. " a loan of " .. n .. ".")
    SyncDebts(borrower)
    return true
end

function LC.AcceptLoan(p, yes)
    local o = p.lcLoanOffer
    p.lcLoanOffer = nil
    if not o or CurTime() - o.at > 120 or not IsValid(o.from) then SyncDebts(p) return false, "No loan is on offer." end
    if not yes then o.from:ChatPrint("[Miscount] " .. Name(p) .. " turned the loan down.") SyncDebts(p) return true end
    if (LC.Credits(o.from) or 0) < o.n then SyncDebts(p) return false, "They haven't the money any more." end
    LC.AddCredits(o.from, -o.n, "a loan to " .. Name(p))
    LC.AddCredits(p, o.n, "a loan from " .. Name(o.from))
    local d = { lender = CID(o.from), lenderName = Name(o.from), borrower = CID(p), borrowerName = Name(p), owed = math.ceil(o.n * 1.2), due = os.time() + cvDebt:GetFloat() * 3600 }
    local a = Owes(p) a[#a + 1] = d SaveOwes(p, a)
    local b = Owed(o.from) b[#b + 1] = d SaveOwed(o.from, b)
    o.from:ChatPrint(string.format("[Miscount] %s took your loan: %d owed back.", Name(p), d.owed))
    p:ChatPrint(string.format("[Miscount] You owe %s %d credits, due in %d hours.", Name(o.from), d.owed, cvDebt:GetInt()))
    SyncDebts(p) SyncDebts(o.from)
    return true
end

function LC.RepayDebt(p, index)
    local a = Owes(p)
    local d = a[tonumber(index) or 0]
    if not d then return false, "No such debt." end
    if (LC.Credits(p) or 0) < d.owed then return false, string.format("You need %d credits.", d.owed) end
    LC.AddCredits(p, -d.owed, "repaying " .. d.lenderName)
    table.remove(a, tonumber(index)) SaveOwes(p, a)
    local lender = ByCID(d.lender)
    if IsValid(lender) then
        LC.AddCredits(lender, d.owed, "a debt repaid")
        local b = Owed(lender)
        for i, x in ipairs(b) do if x.borrower == d.borrower and x.due == d.due then table.remove(b, i) break end end
        SaveOwed(lender, b)
        lender:ChatPrint(string.format("[Miscount] %s repaid you %d credits.", Name(p), d.owed))
        SyncDebts(lender)
    else
        local pend = Pending()
        pend[d.lender] = (pend[d.lender] or 0) + d.owed
        pend[d.lender .. ":clear"] = pend[d.lender .. ":clear"] or {}
        table.insert(pend[d.lender .. ":clear"], { borrower = d.borrower, due = d.due })
        SavePending(pend)
    end
    p:ChatPrint(string.format("[Miscount] Debt repaid: %d credits to %s.", d.owed, d.lenderName))
    SyncDebts(p)
    return true
end

function LC.ReportDebt(lender, index)
    local b = Owed(lender)
    local d = b[tonumber(index) or 0]
    if not d then return false, "No such debt." end
    if os.time() < d.due then return false, "It isn't due yet." end
    if d.reported then return false, "You've reported it already." end
    d.reported = true
    SaveOwed(lender, b)
    local borrower = ByCID(d.borrower)
    if IsValid(borrower) then
        LC.ReportCrime(borrower, "Debt default", 180)
        if LC.AddStanding then LC.AddStanding(borrower, -10, "a debt left unpaid") end
        borrower:ChatPrint("[Civil Protection] " .. d.lenderName .. " reports an unpaid debt. Pay it.")
    else
        lender:ChatPrint("[Miscount] They aren't about. It's on record for when they are.")
        local pend = Pending()
        pend[d.borrower .. ":default"] = true
        SavePending(pend)
    end
    lender:ChatPrint("[Miscount] Reported to Civil Protection.")
    SyncDebts(lender)
    return true
end

hook.Add("PlayerInitialSpawn", "LivingCityDebts", function(p)
    timer.Simple(8, function()
        if not IsValid(p) or not p.GetPData then return end
        local pend = Pending()
        local cid = CID(p)
        local changed = false
        if (pend[cid] or 0) > 0 then
            LC.AddCredits(p, pend[cid], "debts repaid while you were away")
            p:ChatPrint(string.format("[Miscount] Debts repaid while you were away: %d credits.", pend[cid]))
            local b = Owed(p)
            for _, c in ipairs(pend[cid .. ":clear"] or {}) do
                for i, x in ipairs(b) do if x.borrower == c.borrower and x.due == c.due then table.remove(b, i) break end end
            end
            SaveOwed(p, b)
            pend[cid], pend[cid .. ":clear"] = nil, nil
            changed = true
        end
        if pend[cid .. ":default"] then
            LC.ReportCrime(p, "Debt default", 180)
            if LC.AddStanding then LC.AddStanding(p, -10, "a debt left unpaid") end
            pend[cid .. ":default"] = nil
            changed = true
        end
        if changed then SavePending(pend) end
        SyncDebts(p)
    end)
end)

------------------------------------------------------------------------
-- Deals that go bad
------------------------------------------------------------------------

local wrapped = false
local function Wrap()
    if LC.MenuActions then
        LC.MenuActions.loanaccept, LC.MenuActions.loandecline, LC.MenuActions.repay, LC.MenuActions.reportdebt = true, true, true, true
    end
    LC.TargetActions = LC.TargetActions or {}
    LC.TargetActions.pickpocket = function(ply, target) return LC.Pickpocket(ply, target) end
    LC.TargetActions.lend10 = function(ply, target) return LC.OfferLoan(ply, target, 10) end
    LC.TargetActions.lend25 = function(ply, target) return LC.OfferLoan(ply, target, 25) end
    LC.TargetActions.lend50 = function(ply, target) return LC.OfferLoan(ply, target, 50) end
    if wrapped or not LC.BlackBuy then return end
    wrapped = true
    local orig = LC.BlackBuy
    LC.BlackBuy = function(ply, id, ...)
        local atQM = LC.AtQuartermaster and LC.AtQuartermaster(ply)
        local inv0 = (LC.Inventory and LC.Inventory(ply) or {})
        local g = LC.MarketBlackById and LC.MarketBlackById(id) or (LCS.BlackById and LCS.BlackById[id])
        local before = g and g.item and (inv0[g.item] or 0) or 0
        local ok, why = orig(ply, id, ...)
        if ok and not atQM and math.random() < math.Clamp(cvDeal:GetFloat(), 0, 1) then
            if g and g.item and math.random() < 0.5 then
                local now = (LC.Inventory(ply) or {})[g.item] or 0
                local got = now - before
                if got > 0 then LC.TakeItem(ply, g.item, got) end
                ply:ChatPrint("[Black market] You open it round the corner: a brick wrapped in newspaper. The dealer's long gone.")
                hook.Run("LivingCityBadDeal", ply, id, "fake")
            else
                LC.ReportCrime(ply, "Buying contraband", 240)
                ply:SetNW2Float("lc_spotted_until", CurTime() + 60)
                ply:SetNW2String("lc_spotted_why", "a black market sting")
                ply:ChatPrint("[Black market] A whistle behind you. It was a sting: Civil Protection have your face.")
                hook.Run("LivingCityBadDeal", ply, id, "sting")
            end
        end
        return ok, why
    end
end
Wrap()
hook.Add("Initialize", "LivingCityStreetCrime", Wrap)

-- a new person owes nothing and is owed nothing (the old life's debts die with it)
hook.Add("LivingCityNewCharacter", "LivingCityDebts", function(p)
    if not IsValid(p) then return end
    p:RemovePData("lc_debts") p:RemovePData("lc_lent") p:RemovePData("lc_employer") p:RemovePData("lc_employer_name")
end)

timer.Create("LivingCityDebtsSync", 30, 0, function() for _, p in ipairs(player.GetAll()) do LC.Try(SyncDebts, p) end end)

hook.Add("PlayerSay", "LivingCityStreetCrime", function(ply, text)
    local cmd, rest = string.match(string.Trim(tostring(text or "")), "^[!/](%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local ok, why
    if cmd == "loanaccept" then ok, why = LC.AcceptLoan(ply, true)
    elseif cmd == "loandecline" then ok, why = LC.AcceptLoan(ply, false)
    elseif cmd == "repay" then ok, why = LC.RepayDebt(ply, rest)
    elseif cmd == "reportdebt" then ok, why = LC.ReportDebt(ply, rest)
    else return end
    if not ok and why then ply:ChatPrint("[Miscount] " .. why) end
    return ""
end)
