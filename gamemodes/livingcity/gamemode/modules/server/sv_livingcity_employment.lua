--[[
    Living City: a business of your own (the owner, 10 November: "real
    businesses: hiring other players, crafting worth selling"; "I love it all").

    Hand-made goods. Anyone can make them from rags and scrap (crafting, F3):
    a rag doll (3 rags), a tin toy (3 scrap), a patched coat (4 rags, 1 scrap).
    They sell from a market stall, to players, and to the city's own people:
    every lc_stall_customers_minutes (3) one of the citizens walking by buys
    one hand-made thing from an open stall near them, if it's priced at no more
    than half again what it's worth (a rag doll about 18, a tin toy 20, a
    patched coat 32). The takings go in the till, as any sale's do.

    Hiring. A stall owner (with a business license) can offer another citizen
    a job: F1, looking at them, "Offer (name) a job at my stall"; they accept
    on F2 > Me (More) > My stall business. A worker can open their employer's stalls
    and stock them; the till stays the owner's. Every lc_wage_minutes (10) a
    worker who's been at one of the stalls is paid lc_wage (10) credits, out of
    the till, else out of the owner's own pocket (if they're about), else not
    at all (and told so). Either can end it on F2 > Me (More) > My stall business.

      lc_stall_customers_minutes (3), lc_wage (10), lc_wage_minutes (10)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCust  = CreateConVar("lc_stall_customers_minutes", "3", FLAGS, "Minutes between the city's own people buying a hand-made thing from a player's stall (0: never)")
local cvWage  = CreateConVar("lc_wage", "10", FLAGS, "Credits a stall worker is paid each wage period")
local cvWageM = CreateConVar("lc_wage_minutes", "10", FLAGS, "Minutes in a stall worker's wage period")

local NEAR_STALL = 400
local OFFER_SECS = 120

local function CID(p) local c = IsValid(p) and p:GetNW2String("lc_cid", "") or "" return c ~= "" and c or ("sid:" .. (IsValid(p) and p:SteamID() or "")) end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function ByCID(cid) for _, p in ipairs(player.GetAll()) do if CID(p) == cid then return p end end end
local function Citizenish(p) local f = p:GetNW2String("lcf_faction", "") return f == "" or f == "citizen" or f == "resistance" end

local function Stalls(ownerKey)
    local out = {}
    for _, c in pairs(LC.Containers and LC.Containers() or {}) do
        if c.kind == "stall" and c.owner == ownerKey then out[#out + 1] = c end
    end
    return out
end
LC.StallsOf = Stalls

------------------------------------------------------------------------
-- Employment
------------------------------------------------------------------------

-- Whose stalls this person works (the owner's key), or nil.
function LC.EmployerOf(ply)
    if not IsValid(ply) or not ply.GetPData then return nil end
    local k = ply:GetPData("lc_employer", "")
    return k ~= "" and k or nil
end

local function Sync(ply)
    if not IsValid(ply) then return end
    local workers = {}
    for _, p in ipairs(player.GetAll()) do if p ~= ply and LC.EmployerOf(p) == CID(ply) then workers[#workers + 1] = Name(p) end end
    local emp = LC.EmployerOf(ply)
    ply:SetNW2String("lc_business", util.TableToJSON({
        employer = emp and (ply:GetPData("lc_employer_name", "") or "") or nil,
        offer = ply.lcJobOffer and IsValid(ply.lcJobOffer.from) and Name(ply.lcJobOffer.from) or nil,
        workers = #workers > 0 and workers or nil,
        owner = (LC.HasItem and LC.HasItem(ply, "business_license") or #Stalls(CID(ply)) > 0) or nil,
    }) or "")
end
LC.BusinessSync = Sync

function LC.OfferJob(owner, target)
    if not IsValid(target) or not target:IsPlayer() or target == owner then return false, "Look at who you want to hire." end
    if not Citizenish(owner) or not Citizenish(target) then return false, "Only citizens hire and work stalls." end
    if #Stalls(CID(owner)) == 0 then return false, "You need a stall of your own first (a business license and a vendor stall, from the Commissary)." end
    if owner:GetPos():DistToSqr(target:GetPos()) > 250 * 250 then return false, "Ask them face to face." end
    if LC.EmployerOf(target) then return false, Name(target) .. " works for someone already." end
    target.lcJobOffer = { from = owner, at = CurTime() }
    target:ChatPrint(string.format("[Living City] %s offers you a job at their stall: %d credits every %d minutes you're there. F2 > Me (More) > My stall business to accept.", Name(owner), cvWage:GetInt(), cvWageM:GetInt()))
    owner:ChatPrint("[Living City] You've offered " .. Name(target) .. " a job.")
    Sync(target)
    return true
end

function LC.AcceptJob(ply, yes)
    local o = ply.lcJobOffer
    ply.lcJobOffer = nil
    if not o or CurTime() - o.at > OFFER_SECS or not IsValid(o.from) then Sync(ply) return false, "There's no offer waiting." end
    if not yes then
        o.from:ChatPrint("[Living City] " .. Name(ply) .. " turned your job down.")
        Sync(ply)
        return true
    end
    ply:SetPData("lc_employer", CID(o.from))
    ply:SetPData("lc_employer_name", Name(o.from))
    ply.lcWorkedAt = nil
    o.from:ChatPrint("[Living City] " .. Name(ply) .. " works your stall now.")
    ply:ChatPrint("[Living City] You work " .. Name(o.from) .. "'s stall now. Stock it, sell from it; your wages come from the till.")
    Sync(ply) Sync(o.from)
    hook.Run("LivingCityHired", o.from, ply)
    return true
end

function LC.QuitJob(ply)
    local emp = LC.EmployerOf(ply)
    if not emp then return false, "You don't work anyone's stall." end
    ply:RemovePData("lc_employer")
    ply:RemovePData("lc_employer_name")
    local owner = ByCID(emp)
    if IsValid(owner) then owner:ChatPrint("[Living City] " .. Name(ply) .. " has quit working your stall.") Sync(owner) end
    ply:ChatPrint("[Living City] You've left the job.")
    Sync(ply)
    return true
end

function LC.LetGo(owner, name)
    for _, p in ipairs(player.GetAll()) do
        if LC.EmployerOf(p) == CID(owner) and string.lower(Name(p)) == string.lower(tostring(name or "")) then
            p:RemovePData("lc_employer")
            p:RemovePData("lc_employer_name")
            p:ChatPrint("[Living City] " .. Name(owner) .. " has let you go from their stall.")
            owner:ChatPrint("[Living City] You've let " .. Name(p) .. " go.")
            Sync(p) Sync(owner)
            return true
        end
    end
    return false, "Nobody by that name works for you."
end

-- Wages: for each period a worker has spent at one of the stalls.
local function WageTick()
    for _, p in ipairs(player.GetAll()) do
        local emp = LC.EmployerOf(p)
        if emp then
            local stalls = Stalls(emp)
            local at = false
            for _, c in ipairs(stalls) do if c.pos and p:GetPos():DistToSqr(c.pos) < NEAR_STALL * NEAR_STALL then at = true break end end
            if at then p.lcWorkedAt = (p.lcWorkedAt or 0) + 1 end
        end
    end
end

local function PayDay()
    local wage = math.max(0, cvWage:GetInt())
    for _, p in ipairs(player.GetAll()) do
        local emp = LC.EmployerOf(p)
        if emp and (p.lcWorkedAt or 0) > 0 then
            p.lcWorkedAt = 0
            local paid = false
            for _, c in ipairs(Stalls(emp)) do
                if (c.till or 0) >= wage then c.till = c.till - wage paid = true break end
            end
            local owner = ByCID(emp)
            if not paid and IsValid(owner) and LC.Credits and LC.Credits(owner) >= wage then
                LC.AddCredits(owner, -wage, "a worker's wage")
                paid = true
            end
            if paid then
                LC.AddCredits(p, wage, "wages from the stall")
                if IsValid(owner) then owner:ChatPrint(string.format("[Stall] Paid %s %d credits in wages.", Name(p), wage)) end
            else
                p:ChatPrint("[Living City] Your employer couldn't pay you this time: the till's empty.")
            end
        end
    end
end
LC.PayStallWages = PayDay

------------------------------------------------------------------------
-- The city's own people buy hand-made things
------------------------------------------------------------------------

function LC.StallCustomer()
    local sold = false
    for _, c in pairs(LC.Containers and LC.Containers() or {}) do
        if not sold and c.kind == "stall" and not c.closed and c.pos then
            local best
            for id, n in pairs(c.items or {}) do
                local it = LCS.Items[id]
                local price = c.prices and c.prices[id]
                if n > 0 and it and it.handmade and price and price <= math.floor((it.worth or 10) * 1.5) then best = id break end
            end
            if best then
                local buyer
                for npc, st in pairs(LC.NPCs or {}) do
                    if IsValid(npc) and st.role == "citizen" and npc:GetPos():DistToSqr(c.pos) < 1500 * 1500 then buyer = npc break end
                end
                if IsValid(buyer) then
                    local price = c.prices[best]
                    c.items[best] = c.items[best] - 1
                    if c.items[best] <= 0 then c.items[best] = nil c.prices[best] = nil end
                    c.till = (c.till or 0) + price
                    sold = true
                    local owner = ByCID(c.owner)
                    if IsValid(owner) then owner:ChatPrint(string.format("[Stall] A passer-by bought a %s for %d credits. (%d in the till)", string.lower(LCS.Items[best].name), price, c.till)) end
                    hook.Run("LivingCityStallCustomer", buyer, c, best, price)
                end
            end
        end
    end
    return sold
end

------------------------------------------------------------------------

local nextCust, nextPay = 0, 0
timer.Create("LivingCityEmployment", 30, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        WageTick()
        if now >= nextPay then
            if nextPay > 0 then PayDay() end
            nextPay = now + math.max(1, cvWageM:GetFloat()) * 60
        end
        local m = cvCust:GetFloat()
        if m > 0 and now >= nextCust then
            nextCust = now + m * 60
            LC.StallCustomer()
        end
        for _, p in ipairs(player.GetAll()) do Sync(p) end
    end)
    if not ok and LC.Error then LC.Error("employment", err) end
end)

local function Wrap()
    if LC.MenuActions then LC.MenuActions.jobaccept, LC.MenuActions.jobdecline, LC.MenuActions.jobquit, LC.MenuActions.joblet = true, true, true, true end
    LC.TargetActions = LC.TargetActions or {}
    LC.TargetActions.joboffer = function(ply, target) return LC.OfferJob(ply, target) end
end
Wrap()
hook.Add("Initialize", "LivingCityEmployment", Wrap)
hook.Add("PlayerSay", "LivingCityEmployment", function(ply, text)
    local cmd, rest = string.match(string.Trim(tostring(text or "")), "^[!/](%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local ok, why
    if cmd == "jobaccept" then ok, why = LC.AcceptJob(ply, true)
    elseif cmd == "jobdecline" then ok, why = LC.AcceptJob(ply, false)
    elseif cmd == "jobquit" then ok, why = LC.QuitJob(ply)
    elseif cmd == "joblet" then ok, why = LC.LetGo(ply, rest)
    else return end
    if not ok and why then ply:ChatPrint("[Living City] " .. why) end
    return ""
end)
