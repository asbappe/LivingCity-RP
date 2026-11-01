--[[
    Living City: economy and social credit

    Credits         money. Earned from Union shifts, directives and operations
                    (a ration comes with none). Spent at the Union Commissary
                    and vending machines.
    Civil Standing  the city's opinion of you, from -1000 to 1000. Rises with
                    work, compliance and reports; falls with crimes, arrests,
                    escapes and conduct strikes. Your standing tier decides what
                    the Commissary will sell you, and whether the ration
                    dispensers will serve you at all.

    The Commissary opens from a commissary terminal (placed with the editor), or
    anywhere with !shop if the map has no terminals.
]]

if CLIENT then return end

util.AddNetworkString("lce_shop")
util.AddNetworkString("lce_buy")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn        = CreateConVar("lc_economy", "1", FLAGS, "Credits, Civil Standing and the Commissary")
local cvStart     = CreateConVar("lc_start_credits", "20", FLAGS, "Credits a new player starts with")
local cvShiftPay  = CreateConVar("lc_shift_pay", "15", FLAGS, "Credits per Union shift")
local cvJobPay    = CreateConVar("lc_directive_pay", "10", FLAGS, "Credits per directive, assignment or operation")

------------------------------------------------------------------------
-- Credits
------------------------------------------------------------------------

function LC.Credits(ply)
    return tonumber(ply:GetPData("lce_credits", cvStart:GetInt())) or 0
end

function LC.AddCredits(ply, n, why)
    if not IsValid(ply) or not ply:IsPlayer() or not n or n == 0 then return end
    local v = math.max(0, LC.Credits(ply) + n)
    ply:SetPData("lce_credits", v)
    ply:SetNW2Int("lce_credits", v)
    if why then ply:ChatPrint(string.format("[Credits] %+d (%s)", n, why)) end
end

------------------------------------------------------------------------
-- Civil Standing
------------------------------------------------------------------------

function LC.Standing(ply) return tonumber(ply:GetPData("lce_standing", 0)) or 0 end

-- What changed someone's standing in the last moment, said in one line: a
-- fight's worth of offences is "-150: Assaulting Civil Protection (x5),
-- Murder of a Civil Protection officer", not a screenful.
local pendingStanding = {} -- [ply] = { total, actual, order = { why... }, count = { [why] = n }, before }

local function FlushStanding(ply)
    local p = pendingStanding[ply]
    pendingStanding[ply] = nil
    if not p or not IsValid(ply) then return end
    if #p.order > 0 then
        local parts = {}
        local several = #p.order > 1
        for _, why in ipairs(p.order) do
            local c, sum = p.count[why], p.sum[why]
            if several then
                parts[#parts + 1] = c > 1 and string.format("%s (x%d, %+d)", why, c, sum) or string.format("%s (%+d)", why, sum)
            else
                parts[#parts + 1] = c > 1 and string.format("%s (x%d)", why, c) or why
            end
        end
        local note = ""
        if p.actual == 0 and p.total < 0 then note = " (it can't go any lower)"
        elseif p.actual == 0 and p.total > 0 then note = " (it can't go any higher)" end
        ply:ChatPrint(string.format("[Civil Standing] %+d%s: %s", p.total, note, table.concat(parts, ", ")))
    end
    local after = LCS.TierFor(LC.Standing(ply))
    if after ~= p.before then ply:ChatPrint("[Civil Standing] You are now classified: " .. after.name .. ".") end
end
LC.FlushStanding = FlushStanding

function LC.AddStanding(ply, n, why)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:IsPlayer() or not n or n == 0 then return end
    if LC.PlayerIsZombie(ply) then return end
    if n < 0 and LC.EndingSession and LC.EndingSession() then return end -- (an ending never costs anyone standing)
    local old = LC.Standing(ply)
    local v = math.Clamp(old + n, -1000, 1000)
    ply:SetPData("lce_standing", v)
    ply:SetNW2Int("lce_standing", v)
    local p = pendingStanding[ply]
    if not p then
        p = { total = 0, actual = 0, order = {}, count = {}, sum = {}, before = LCS.TierFor(old), first = CurTime() }
        pendingStanding[ply] = p
    end
    p.actual = p.actual + (v - old)
    if why and math.abs(n) >= 5 then
        p.total = p.total + n
        if not p.count[why] then p.count[why], p.sum[why] = 0, 0 p.order[#p.order + 1] = why end
        p.count[why] = p.count[why] + 1
        p.sum[why] = p.sum[why] + n
    end
    -- said once things go quiet for a moment (and at least every few seconds in a long fight)
    timer.Create("LivingCityStanding" .. ply:EntIndex(), CurTime() - p.first > 5 and 0 or 1.5, 1, function() FlushStanding(ply) end)
end

hook.Add("PlayerInitialSpawn", "LivingCityEconomy", function(ply)
    if ply:GetPData("lce_credits", nil) == nil then ply:SetPData("lce_credits", cvStart:GetInt()) end
    ply:SetNW2Int("lce_credits", LC.Credits(ply))
    ply:SetNW2Int("lce_standing", LC.Standing(ply))
end)

------------------------------------------------------------------------
-- What earns and costs you
------------------------------------------------------------------------

local SECRET_BOARDS = { Operations = true, Urges = true }

hook.Add("LivingCityQuestComplete", "LivingCityEconomy", function(p, q)
    if not cvOn:GetBool() or not IsValid(p) then return end
    if q.chain == "rehab" then
        LC.AddStanding(p, 40, "Community service")
    elseif q.chain == "shift" then
        LC.AddCredits(p, math.floor(cvShiftPay:GetInt() * (LC.LoyalPayMul and LC.LoyalPayMul(p) or 1) + 0.5), "shift complete") -- (more for the loyal: sv_livingcity_loyalty.lua)
        LC.AddStanding(p, 5, "Union shift completed")
    elseif q.chain == "insidework" or SECRET_BOARDS[q.board] then
        if q.board ~= "Urges" then LC.AddCredits(p, cvJobPay:GetInt(), "paid quietly") end
    elseif q.chain then
        LC.AddCredits(p, cvJobPay:GetInt())
    else
        LC.AddCredits(p, cvJobPay:GetInt(), q.board .. " complete")
        LC.AddStanding(p, 3)
    end
end)

hook.Add("LivingCityIncarcerated", "LivingCityEconomy", function(target)
    if IsValid(target) and target:IsPlayer() then LC.AddStanding(target, -40, "Incarcerated") end
end)
hook.Add("LivingCityEscaped", "LivingCityEconomy", function(ply)
    ply.lcSurrendered = nil
    LC.AddStanding(ply, -60, "Escaped custody")
end)

-- Serving your time pays back part of what you owe: a quarter of the deficit
-- plus 100, and more if you gave yourself up. Never past zero.
hook.Add("LivingCityReleased", "LivingCityEconomy", function(ply)
    if not cvOn:GetBool() or not IsValid(ply) then return end
    local s = LC.Standing(ply)
    local surrendered = ply.lcSurrendered
    ply.lcSurrendered = nil
    if s >= 0 then return end
    local back = math.min(-s, math.floor(100 + 0.25 * -s) + (surrendered and 75 or 0))
    LC.AddStanding(ply, back, surrendered and "Turned yourself in and served your time" or "Served your time")
end)
hook.Add("LivingCityStrike", "LivingCityEconomy", function(ply) LC.AddStanding(ply, -50, "Conduct violation") end)
-- (what an offence costs in standing; most are 25. A shot at a scanner is a little, wrecking one is 50)
local STANDING_COST = { ["Destroying city property"] = -50, ["Damaging city property"] = -10 }
hook.Add("LivingCityWanted", "LivingCityEconomy", function(ply, reason) LC.AddStanding(ply, STANDING_COST[reason] or -25, reason or "Wanted") end)
hook.Add("LivingCityCurfewWarning", "LivingCityEconomy", function(ply) LC.AddStanding(ply, -5, "Out after curfew") end)
hook.Add("LivingCityCounter", "LivingCityEconomy", function(ply, counter, n)
    if counter == "reports" and n > 0 then LC.AddStanding(ply, 10 * n, "Reported anticitizen activity") end
end)

-- Quiet compliance slowly earns trust, a little faster from below zero.
timer.Create("LivingCityCompliance", 600, 0, function()
    if not cvOn:GetBool() or not LC.Running then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not LC.PlayerIsWanted(ply) and not (LC.Prisoners and LC.Prisoners[ply]) and not LC.PlayerIsZombie(ply) then
            LC.AddStanding(ply, LC.Standing(ply) < 0 and 10 or 2, "Compliance")
        end
    end
end)

------------------------------------------------------------------------
-- The Union Commissary
------------------------------------------------------------------------

local function NearTerminal(ply)
    if LC.NearCPSupply and LC.PlayerIsCP(ply) and LC.NearCPSupply(ply) then return true end -- (the unit counter: sv_livingcity_cpsupply.lua)
    local terms = LC.EntsOf("lc_terminal")
    if #terms == 0 then return true end
    for _, t in ipairs(terms) do
        if t:GetPos():DistToSqr(ply:GetPos()) < 200 * 200 and not t:GetNW2Bool("lc_nopower", false) then return true end -- (a dead one sells nothing)
    end
    return false
end

-- Where a unit's things are sold: the Civil Protection Commissary's counter
-- (sv_livingcity_cpsupply.lua), never the Union's terminals; only a city with
-- no Civil Protection Commissary sells them at the Union terminal.
local function AtUnitCounter(ply)
    if not (LC.HasCPSupply and LC.HasCPSupply()) then return true end
    return LC.NearCPSupply ~= nil and LC.NearCPSupply(ply)
end
LC.AtUnitCounter = AtUnitCounter

function LC.CanBuy(ply, g)
    if not cvOn:GetBool() then return false, "The commissary is closed." end
    if LC.PlayerIsZombie(ply) then return false, "The terminal doesn't recognize you. It doesn't recognize anything like you." end
    if g.cpOnly and not LC.PlayerIsCP(ply) then return false, "Civil Protection units only." end
    if g.cpOnly and not AtUnitCounter(ply) then return false, "Issued at the Civil Protection Commissary, not here." end
    if g.minRank and ply:GetNW2Int("lcf_rank", 1) < g.minRank and not (LCF.IsOverwatch and LCF.IsOverwatch(ply)) then
        return false, "Not at your rank."
    end
    local need = g.minStanding or -50
    if LC.Standing(ply) < need then return false, "Requires " .. LCS.TierFor(need).name .. " standing." end
    if LC.Credits(ply) < LC.GoodsPrice(ply, g) then return false, "Not enough credits." end
    if g.item and LC.CanCarry then local okC, whyC = LC.CanCarry(ply, g.item, g.count or 1) if not okC then return false, whyC end end
    return true
end

-- What it costs this person: the loyal get a discount at the Union Commissary (sv_livingcity_loyalty.lua).
function LC.GoodsPrice(ply, g)
    if not g then return 0 end
    if g.cpOnly then return g.price end
    return math.max(1, math.floor(g.price * (LC.LoyalPriceMul and LC.LoyalPriceMul(ply) or 1) + 0.5))
end

function LC.Buy(ply, id)
    local g = LCS.GoodsById[id]
    if not g then return false end
    local ok, why = LC.CanBuy(ply, g)
    if not ok then
        ply:ChatPrint("[Commissary] " .. why)
        return false
    end
    LC.AddCredits(ply, -LC.GoodsPrice(ply, g))
    if g.item then
        LC.GiveItem(ply, g.item, g.count or 1)
    elseif g.entity then
        local e = ents.Create(g.entity)
        if IsValid(e) then
            e:SetPos(ply:GetPos() + ply:GetForward() * 40 + Vector(0, 0, 20))
            e:Spawn()
        end
    elseif g.ammo then
        ply:GiveAmmo(g.ammo[2], g.ammo[1])
    end
    ply:ChatPrint(string.format("[Commissary] Purchased: %s (%d credits)", g.name, LC.GoodsPrice(ply, g)))
    ply:EmitSound("buttons/button14.wav", 60)
    return true
end

function LC.OpenShop(ply, viaTerminal)
    if not cvOn:GetBool() then return ply:ChatPrint("[Commissary] The commissary is closed.") end
    if LC.IntakePending and LC.IntakePending(ply) then
        return ply:ChatPrint("[Commissary] The terminal asks for a citizen number you don't have yet. Register at Civil Intake.")
    end
    if not viaTerminal and not NearTerminal(ply) then
        return ply:ChatPrint("[Commissary] Find a Union Commissary terminal.")
    end
    local goods = {}
    local counter = LC.PlayerIsCP(ply) and AtUnitCounter(ply)
    for _, g in ipairs(LCS.Goods) do
        if not g.cpOnly or counter then
            local ok, why = LC.CanBuy(ply, g)
            goods[#goods + 1] = {
                id = g.id, name = g.name, price = LC.GoodsPrice(ply, g), desc = g.desc, ok = ok, why = why,
                tier = LCS.TierFor(g.minStanding or -50).name,
            }
        end
    end
    local cp = LC.PlayerIsCP(ply) and LC.NearCPSupply ~= nil and LC.NearCPSupply(ply)
    LC.SendCompressed("lce_shop", { credits = LC.Credits(ply), standing = LC.Standing(ply), goods = goods, cp = cp or nil }, { ply })
end

net.Receive("lce_buy", function(_, ply)
    if not NearTerminal(ply) then return end
    LC.Buy(ply, net.ReadString())
    LC.OpenShop(ply, true)
end)

concommand.Add("lce_shop", function(ply) if IsValid(ply) then LC.OpenShop(ply) end end)
hook.Add("PlayerSay", "LivingCityEconomyChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!shop" or t == "!commissary" then LC.OpenShop(ply) return "" end
    if t == "!credits" or t == "!standing" then
        ply:ChatPrint(string.format("[Union] %d credits. Civil Standing %d (%s).", LC.Credits(ply), LC.Standing(ply),
            LCS.TierFor(LC.Standing(ply)).name))
        return ""
    end
end)

concommand.Add("lc_givecredits", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    if target then LC.AddCredits(target, tonumber(args[2]) or 0, "from staff") end
end)

concommand.Add("lc_setstanding", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    local v = tonumber(args[2])
    if target and v then LC.AddStanding(target, v - LC.Standing(target), "adjusted by staff") end
end)

-- Settings players' games need to know about. These live on the server only,
-- so each game hears them this way (the credits line on the HUD, the clock's
-- day part, the housing blocks' names).
timer.Create("LivingCityPublicSettings", 2, 0, function()
    local function cv(n) return GetConVar(n) end
    local e, r, b = cv("lc_economy"), cv("lc_daily_rhythm"), cv("lc_block_name")
    SetGlobal2Bool("lc_economy_on", e == nil or e:GetBool())
    SetGlobal2Bool("lc_rhythm_on", r == nil or r:GetBool())
    if b then SetGlobal2String("lc_block_name", b:GetString()) end
end)

