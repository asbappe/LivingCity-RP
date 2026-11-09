--[[
    Living City: the city's market (the owner, 7 November: "a dynamic economic system of
    supply/demand/availability where all the shops/sellers are all playing off each other")

    The Administrator's say over the Union Commissary (her tablet > The Commissary and the market),
    for each thing it sells (never Civil Protection's own issue):
      Restricted     still on the shelf, greyed: "Restricted by the Administrator"
      Price          0.5x to 5x the usual
      Standing       the Civil Standing it needs (a number, or a tier: Trusted 150, Exemplary 400)
      Supply         plentiful, normal, or scarce: lc_market_scarce_stock (5) at a time, one more
                     every lc_market_restock_minutes (20)
    Saved per map (data/livingcity/<map>_market.json) and announced to the city as she makes them.

    One model every seller reads:
      Demand         every purchase, anywhere, adds to the city's demand for that thing; selling
                     it to the dealer or the quartermaster takes from it; it halves every
                     lc_market_demand_halflife minutes (30). Past the first couple of purchases,
                     each one puts the black market's price up lc_market_demand_step (5%), to at
                     most lc_market_demand_cap (50%) more.
      Shortage       restricted, scarce, overpriced or put out of reach at the Commissary (and,
                     for food, the city's ration stores running low: sv_livingcity_stockpile.lua)
                     is a shortage: the black market dealer picks it up if he didn't have it (at
                     lc_market_bm_markup, 1.5x the Commissary's usual price), and his price goes
                     up with the shortage (up to lc_market_bm_premium, double, at a full one) and
                     with demand. Cheap and plentiful at the Commissary: his price falls (up to
                     30%) and what he only stocked because of the shortage goes again.
      The Resistance The quartermaster sells his own what the dealer has at the scientist's rate
                     (sv_livingcity_underground.lua), so the shortage reaches him too; the
                     scientist's prices follow the dealer's, and for a few short things (water
                     tablets, work clothes, a satchel, a curfew permit, weedkiller) he can make
                     one from materials. The quartermaster pays more for what's in demand, never
                     as much as anyone could buy it for.
      Consequences   every restriction is a straw on a citizen's back (the owner, 7 November):
                     while restrictions stand, one more Resistance fighter per restriction is
                     kept in rebel territory (lc_market_rebels_per, 1, at most
                     lc_market_rebels_max, 6, and never more than the zones have room for),
                     and the Resistance's operations come sooner (lc_market_ops_speedup, 10%
                     sooner per restriction, at most half the wait). A citizen turned away by a
                     restriction warms to the Resistance (sympathy, once in half an hour).
                     Sociostability itself isn't touched. The Administrator hears about it in
                     plain words on the market page (LC.MarketMood), not numbers.
    Bounded: the Commissary's multiplier is 0.5x to 5x; the black market's 0.5x to 4x, never
    below what the dealer pays back. With nothing touched and nothing bought, every price is
    as it always was. lc_market 0 turns all of it off.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_market", "1", FLAGS, "The city's market: the Administrator's Commissary controls, demand, and the black market following shortages (0: off, prices as fixed)")
local cvDemand   = CreateConVar("lc_market_demand", "1", FLAGS, "Buying moves black market prices (demand); 0: demand is never counted")
local cvStep     = CreateConVar("lc_market_demand_step", "0.05", FLAGS, "How much each purchase past the first two puts the black market's price up (0.05: 5%)")
local cvCap      = CreateConVar("lc_market_demand_cap", "0.5", FLAGS, "The most demand can put a price up (0.5: 50%)")
local cvHalf     = CreateConVar("lc_market_demand_halflife", "30", FLAGS, "Minutes for the city's demand for something to halve")
local cvMarkup   = CreateConVar("lc_market_bm_markup", "1.5", FLAGS, "What the black market charges for a Commissary good it picks up in a shortage, times the Commissary's usual price")
local cvPremium  = CreateConVar("lc_market_bm_premium", "1", FLAGS, "How far a shortage at the Commissary puts black market prices up (1: up to double at a full shortage)")
local cvScarce   = CreateConVar("lc_market_scarce_stock", "5", FLAGS, "How many of a scarce Commissary good there are at a time")
local cvRestock  = CreateConVar("lc_market_restock_minutes", "20", FLAGS, "Minutes for one more of a scarce Commissary good")
local cvRebelsPer = CreateConVar("lc_market_rebels_per", "1", FLAGS, "Resistance fighters added in rebel territory for each Commissary good the Administrator restricts (0: none)")
local cvRebelsMax = CreateConVar("lc_market_rebels_max", "6", FLAGS, "Most Resistance fighters the Administrator's restrictions can add")
local cvOpsSpeed  = CreateConVar("lc_market_ops_speedup", "10", FLAGS, "Percent sooner the Resistance's operations come for each restricted Commissary good (at most half the wait)")

util.AddNetworkString("lc_market_open")  -- the Administrator asks for her market panel
util.AddNetworkString("lc_market_admin") -- the panel's contents
util.AddNetworkString("lc_market_set")   -- one change from it

local DEMAND_FREE = 2      -- purchases in a while that don't move a price
local APPEAR = 0.25        -- shortage at which the dealer picks a Commissary good up
local PRICE_MIN, PRICE_MAX = 0.5, 5
local BM_MIN, BM_MAX = 0.5, 4
local PA_GAP = 600         -- the PA says a restriction at most once in ten minutes

-- never on the black market, however short (nothing a dealer could sell)
local NO_BLACK = { request_device = true, business_license = true, vendor_stall = true }
-- food: short when the city's ration stores are (sv_livingcity_stockpile.lua)
local FOOD = { ration = true, bread = true, milk = true, water = true, canned_food = true, ration_forged = true }
-- what the Resistance's scientist can make himself while the Commissary won't sell it
local LAB_MAKES = {
    tablets = { needs = { chemicals = 1 }, desc = "Water tablets, pressed from chemicals, while the Commissary won't sell them" },
    civvies = { needs = { cloth = 3 }, desc = "Plain work clothes, stitched from rags, while the Commissary won't sell them" },
    satchel = { needs = { cloth = 4 }, desc = "A satchel, stitched from rags, while the Commissary won't sell them" },
    permit = { needs = { paper = 1, chemicals = 1 }, desc = "A forged curfew permit, while the Commissary won't sell real ones" },
    weedkiller = { needs = { chemicals = 2 }, desc = "Weedkiller, mixed from chemicals, while the Commissary won't sell it" },
}
local SUPPLY = { plentiful = true, normal = true, scarce = true }

LC.MarketState = LC.MarketState or { rules = {}, stock = {}, restockAt = {}, demand = {} }
local M = LC.MarketState
local loaded, dirty = false, false

local function Path() return "livingcity/" .. game.GetMap() .. "_market.json" end
LC.MarketFile = Path
local function On() return cvOn:GetBool() end
function LC.MarketOn() return On() end

local function Load()
    loaded = true
    local t = LC.SafeReadJSON(Path())
    if not istable(t) then return end
    M.rules, M.stock, M.restockAt, M.demand = {}, {}, {}, {}
    for id, r in pairs(istable(t.rules) and t.rules or {}) do
        if LCS.GoodsById[id] and istable(r) then M.rules[id] = r end
    end
    for id, n in pairs(istable(t.stock) and t.stock or {}) do if tonumber(n) then M.stock[id] = tonumber(n) end end
    for id, n in pairs(istable(t.demand) and t.demand or {}) do if tonumber(n) then M.demand[id] = tonumber(n) end end
    -- a restock due: from now (CurTime starts again with the server), not lost
    for id in pairs(M.stock) do M.restockAt[id] = CurTime() + math.max(1, cvRestock:GetFloat()) * 60 end
end
local function Ensure() if not loaded then Load() end end

function LC.MarketSave()
    Ensure()
    dirty = false
    if not (file and file.Write) then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    LC.SafeWrite(Path(), util.TableToJSON({ rules = M.rules, stock = M.stock, demand = M.demand }))
end
-- forget what's in memory and read the file again (the tests' restart)
function LC.MarketReload()
    M.rules, M.stock, M.restockAt, M.demand = {}, {}, {}, {}
    Load()
end

------------------------------------------------------------------------
-- The Administrator's rules
------------------------------------------------------------------------

-- Goods she has a say over: the Union Commissary's, not Civil Protection's issue.
local function Controllable(g) return g ~= nil and not g.cpOnly end
local function Rule(g)
    Ensure()
    return g and M.rules[g.id] or nil
end
function LC.MarketRule(id)
    local g = LCS.GoodsById[id]
    local r = Rule(g) or {}
    return { restricted = r.restricted == true, mul = tonumber(r.mul) or 1, minStanding = tonumber(r.minStanding),
        supply = SUPPLY[r.supply] and r.supply or "normal" }
end

local function BaseStanding(g) return g.minStanding or -50 end
function LC.MarketMinStanding(g)
    local r = On() and Controllable(g) and Rule(g)
    if r and tonumber(r.minStanding) then return tonumber(r.minStanding) end
    return BaseStanding(g)
end
function LC.MarketCommissaryMul(g)
    local r = On() and Controllable(g) and Rule(g)
    return r and tonumber(r.mul) or 1
end
local function Scarce(g)
    local r = On() and Controllable(g) and Rule(g)
    return r and r.supply == "scarce" or false
end
function LC.MarketStock(id)
    local g = LCS.GoodsById[id]
    if not Scarce(g) then return nil end
    return math.max(0, math.floor(M.stock[id] or cvScarce:GetInt()))
end
local function RestockMinutes(id)
    local at = M.restockAt[id]
    if not at then return math.ceil(math.max(1, cvRestock:GetFloat())) end
    return math.max(1, math.ceil((at - CurTime()) / 60))
end
function LC.MarketRestricted(g)
    local r = On() and Controllable(g) and Rule(g)
    return r and r.restricted == true or false
end

-- Why the Commissary won't sell it right now (nil: it will, as far as the market goes).
function LC.MarketCommissaryBlock(ply, g)
    if not On() or not Controllable(g) then return nil end
    if LC.MarketRestricted(g) then return "Restricted by the Administrator." end
    local n = LC.MarketStock(g.id)
    if n and n <= 0 then return string.format("Sold out: more in %d min.", RestockMinutes(g.id)) end
    return nil
end

-- "Requires Exemplary standing." for a tier, "Requires 250 Civil Standing." for a number of hers.
function LC.MarketStandingText(need)
    for _, t in ipairs(LCS.Tiers or {}) do if t.min == need then return t.name .. " standing" end end
    return string.format("%d Civil Standing", need)
end

------------------------------------------------------------------------
-- Demand
------------------------------------------------------------------------

local function Key(g) return g and (g.item or g.id) or nil end
LC.MarketKey = Key

function LC.MarketDemand(key) Ensure() return M.demand[key] or 0 end
function LC.MarketDemandMul(key)
    if not On() or not cvDemand:GetBool() then return 1 end
    local d = LC.MarketDemand(key)
    return 1 + math.Clamp((d - DEMAND_FREE) * math.max(0, cvStep:GetFloat()), 0, math.max(0, cvCap:GetFloat()))
end
local function AddDemand(key, n)
    if not key or not On() or not cvDemand:GetBool() then return end
    Ensure()
    M.demand[key] = math.Clamp((M.demand[key] or 0) + n, 0, 100)
    if M.demand[key] < 0.05 then M.demand[key] = nil end
    dirty = true
end

-- Bought (where: "commissary", "black" or "lab"): demand up, and a scarce good's stock down.
function LC.MarketBought(g, where)
    if not g or not On() then return end
    AddDemand(Key(g), 1)
    if where == "commissary" and Scarce(g) then
        local n = LC.MarketStock(g.id) or 0
        M.stock[g.id] = math.max(0, n - 1)
        M.restockAt[g.id] = M.restockAt[g.id] or (CurTime() + math.max(1, cvRestock:GetFloat()) * 60)
        dirty = true
    end
end
-- Sold to the dealer or the quartermaster: more of it about, less wanted.
function LC.MarketSold(id, n) AddDemand(id, -0.5 * (n or 1)) end

------------------------------------------------------------------------
-- Shortage: how far the Commissary falls short of what the city wants (-1 to 1)
------------------------------------------------------------------------

local function StockPressure()
    local lvl = LC.StockLevel and LC.StockLevel() or "normal"
    return (lvl == "empty" and 0.6) or (lvl == "short" and 0.3) or 0
end

local function GoodPressure(g)
    if LC.MarketRestricted(g) then return 1 end
    local r = Rule(g) or {}
    local p = 0
    if r.supply == "scarce" then p = p + ((LC.MarketStock(g.id) or 1) <= 0 and 0.8 or 0.5)
    elseif r.supply == "plentiful" then p = p - 0.5 end
    local mul = tonumber(r.mul) or 1
    if mul > 1 then p = p + math.min(1, (mul - 1) / 2) elseif mul < 1 then p = p - (1 - mul) end
    local need, base = tonumber(r.minStanding), BaseStanding(g)
    if need and need > base then p = p + ((need >= 400 and base < 400) and 0.5 or 0.25) end
    if FOOD[Key(g)] then p = p + StockPressure() end
    return math.Clamp(p, -1, 1)
end

-- The shortage of a thing (by item id), from every Commissary good that sells it.
function LC.MarketShortage(key)
    if not On() or not key then return 0 end
    local best
    for _, g in ipairs(LCS.Goods) do
        if Controllable(g) and Key(g) == key then
            local p = GoodPressure(g)
            if best == nil or p > best then best = p end
        end
    end
    if best == nil then best = FOOD[key] and StockPressure() or 0 end
    return best
end

------------------------------------------------------------------------
-- The black market, following the Commissary
------------------------------------------------------------------------

local inBlack -- [item id] = true for what the dealer always stocks
local function BlackItems()
    if inBlack then return inBlack end
    inBlack = {}
    for _, b in ipairs(LCS.Black) do inBlack[Key(b)] = true end
    return inBlack
end

local extras = {} -- [mkt_<good id>] = the dealer's entry (made once, kept the same table)
local function Extra(g)
    local id = "mkt_" .. g.id
    local e = extras[id]
    if not e then
        e = { id = id, good = g.id, item = g.item, entity = g.entity, count = g.count, name = g.name, extra = true }
        extras[id] = e
    end
    e.price = math.max(1, math.ceil(g.price * math.max(1, cvMarkup:GetFloat())))
    e.desc = "Off the back of a Union lorry. The Commissary won't sell it to you; he will."
    return e
end
local function ExtraAvailable(g)
    return On() and Controllable(g) and not NO_BLACK[g.id] and not BlackItems()[Key(g)] and GoodPressure(g) >= APPEAR
end

-- What the dealer has right now: his usual stock, and whatever the Commissary is short of.
function LC.MarketBlackList()
    if not On() then return LCS.Black end
    local out = {}
    for _, b in ipairs(LCS.Black) do out[#out + 1] = b end
    for _, g in ipairs(LCS.Goods) do if ExtraAvailable(g) then out[#out + 1] = Extra(g) end end
    return out
end
function LC.MarketBlackById(id)
    if LCS.BlackById[id] then return LCS.BlackById[id] end
    local gid = string.match(tostring(id or ""), "^mkt_(.+)$")
    local g = gid and LCS.GoodsById[gid]
    if g and ExtraAvailable(g) then return Extra(g) end
    return nil
end

-- The market's factor on a dealer's price: shortage and demand (city state is LC.BlackPriceMul's).
function LC.MarketBlackMul(g)
    if not On() or not g then return 1 end
    local key = Key(g)
    local p = LC.MarketShortage(key)
    local m = p > 0 and (1 + math.max(0, cvPremium:GetFloat()) * p) or (1 + 0.3 * p)
    m = m * LC.MarketDemandMul(key)
    return math.Clamp(m, BM_MIN, BM_MAX)
end

local function Pct(m) return math.floor((m - 1) * 100 + 0.5) end

-- A line for the black market's window (nil: nothing to say).
function LC.MarketBlackNote(g)
    if not On() or not g then return nil end
    local key = Key(g)
    local p, dm = LC.MarketShortage(key), LC.MarketDemandMul(key)
    local pct = Pct(LC.MarketBlackMul(g))
    if g.extra then return dm > 1 and "Hard to get in the city: in demand" or "Hard to get in the city" end
    if p > 0 and pct > 0 then return string.format("Short in the city: price up %d%%", pct) end
    if dm > 1 and pct > 0 then return string.format("In demand: price up %d%%", pct) end
    if pct < 0 then return string.format("Cheap at the Commissary: price down %d%%", -pct) end
    return nil
end

-- A line for the Commissary's window.
function LC.MarketCommissaryNote(g)
    if not On() or not Controllable(g) then return nil end
    if LC.MarketRestricted(g) then return "Restricted by the Administrator" end
    local r = Rule(g) or {}
    local bits = {}
    local n = LC.MarketStock(g.id)
    if n then
        bits[#bits + 1] = n > 0 and string.format("Scarce: %d left, more in %d min", n, RestockMinutes(g.id))
            or string.format("Sold out: more in %d min", RestockMinutes(g.id))
    elseif r.supply == "plentiful" then bits[#bits + 1] = "Plentiful" end
    local mul = tonumber(r.mul) or 1
    if mul > 1 then bits[#bits + 1] = string.format("Price raised by the Administrator (+%d%%)", Pct(mul))
    elseif mul < 1 then bits[#bits + 1] = string.format("Price lowered by the Administrator (-%d%%)", -Pct(mul)) end
    if tonumber(r.minStanding) and tonumber(r.minStanding) ~= BaseStanding(g) then
        bits[#bits + 1] = "Needs " .. LC.MarketStandingText(tonumber(r.minStanding)) .. " (the Administrator's order)"
    end
    return #bits > 0 and table.concat(bits, "; ") or nil
end

------------------------------------------------------------------------
-- The quartermaster's buy-back follows demand, never up to what anyone could buy it for
------------------------------------------------------------------------

local function CheapestBuy(id)
    local best = math.huge
    for _, b in ipairs(LC.MarketBlackList()) do
        if Key(b) == id then
            best = math.min(best, LC.BlackPrice and LC.BlackPrice(b) or b.price)
            if LC.QuartermasterPrice then best = math.min(best, LC.QuartermasterPrice(b)) end
        end
    end
    for _, g in ipairs(LCS.Goods) do
        if g.item == id and not LC.MarketRestricted(g) then
            best = math.min(best, math.floor(g.price * LC.MarketCommissaryMul(g) * 0.6)) -- (the most a discount takes off)
        end
    end
    return best
end

function LC.MarketBuybackMul(id)
    if not On() then return 1 end
    return LC.MarketDemandMul(id) * (1 + 0.5 * math.max(0, cvPremium:GetFloat()) * math.max(0, LC.MarketShortage(id)))
end
function LC.MarketBuyback(id, price)
    if not On() or not price then return price end
    local m = LC.MarketBuybackMul(id)
    if m <= 1 then return price end
    local want = math.floor(price * m + 0.5)
    return math.max(price, math.min(want, CheapestBuy(id) - 1))
end

------------------------------------------------------------------------
-- The scientist: what he makes while the Commissary won't sell it
------------------------------------------------------------------------

local labExtras = {}
local function LabExtra(g)
    local id = "mkt_" .. g.id
    local r = labExtras[id]
    if not r then
        local spec = LAB_MAKES[g.id]
        r = { id = id, out = g.item, count = g.count, needs = spec.needs, secs = 8, desc = spec.desc, market = true }
        labExtras[id] = r
    end
    r.black = BlackItems()[g.item] and g.item or ("mkt_" .. g.id) -- (what the dealer would charge: his price sets the scientist's)
    return r
end
local function LabAvailable(g)
    return On() and Controllable(g) and LAB_MAKES[g.id] and g.item and LCS.Items[g.item] and GoodPressure(g) >= APPEAR
end
function LC.MarketLabList()
    if not On() then return LCS.Lab end
    local out = {}
    for _, r in ipairs(LCS.Lab) do out[#out + 1] = r end
    for _, g in ipairs(LCS.Goods) do if LabAvailable(g) then out[#out + 1] = LabExtra(g) end end
    return out
end
function LC.MarketLabById(id)
    if LCS.LabById[id] then return LCS.LabById[id] end
    local gid = string.match(tostring(id or ""), "^mkt_(.+)$")
    local g = gid and LCS.GoodsById[gid]
    if g and LabAvailable(g) then return LabExtra(g) end
    return nil
end
hook.Add("LivingCityLabMade", "LivingCityMarket", function(_, out, how)
    if how == "pay" then AddDemand(out, 1) end -- (made from materials: nothing taken from the market)
end)

------------------------------------------------------------------------
-- Consequences: each restriction drives another citizen to the Resistance
------------------------------------------------------------------------

function LC.MarketRestrictedCount()
    if not On() then return 0 end
    local n = 0
    for _, g in ipairs(LCS.Goods) do if LC.MarketRestricted(g) then n = n + 1 end end
    return n
end
-- One more fighter for each restriction (rebel territory's own target: sv_livingcity_rebels.lua).
function LC.MarketRebelBonus()
    local n = LC.MarketRestrictedCount()
    if n <= 0 then return 0 end
    return math.min(math.max(0, cvRebelsMax:GetInt()), n * math.max(0, cvRebelsPer:GetInt()))
end
-- The Resistance's operations come sooner (sv_livingcity_resistanceops.lua): a multiplier on the wait.
function LC.MarketOpsMul()
    local n = LC.MarketRestrictedCount()
    if n <= 0 then return 1 end
    return math.max(0.5, 1 - n * math.max(0, cvOpsSpeed:GetFloat()) / 100)
end
-- A citizen turned away by a restriction warms to the Resistance (sympathy, at most once in half an hour).
-- (The owner, 7 November: players' sympathy may move; sociostability itself isn't touched.)
local SYMPATHY_GAP = 1800
function LC.MarketRefused(ply, g)
    if not IsValid(ply) or not LC.MarketRestricted(g) then return end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return end
    if (ply.lcMarketSympathy or 0) > CurTime() then return end
    ply.lcMarketSympathy = CurTime() + SYMPATHY_GAP
    -- (it no longer counts as sympathy: the owner, 9 November, sympathy is the way into the Resistance and has to be earned)
end

-- What the Administrator hears about it: plain talk, not numbers (the owner, 7 November).
function LC.MarketMood()
    local n = LC.MarketRestrictedCount()
    if n <= 0 then return nil end
    if n == 1 then return "There's some grumbling in the ration lines about the restriction." end
    if n <= 3 then return "These restrictions are stirring some citizens to think about joining the Resistance." end
    if n <= 5 then return "Word is that citizens are calling the restrictions unfair, and some have gone to join the Resistance. Expect them to be busier." end
    return "Citizens are calling the restrictions draconian. More of them are leaving to fight with the Resistance, and the rebels are getting bolder."
end

------------------------------------------------------------------------
-- The Administrator changes something
------------------------------------------------------------------------

local pending, lastPA, paRestrict = {}, -1e9, nil

local function FlushAnnounce()
    timer.Remove("LivingCityMarketAnnounce")
    if #pending == 0 then return end
    local lines = pending
    pending = {}
    local text = "By order of the City Administrator: " .. table.concat(lines, " ", 1, math.min(#lines, 6))
        .. (#lines > 6 and string.format(" (and %d more changes)", #lines - 6) or "")
    for _, p in ipairs(player.GetAll()) do
        if LC.Notice then LC.Notice(p, "event", "The Union Commissary", text, 12) end
        p:ChatPrint("[Commissary] " .. text)
    end
    if paRestrict and CurTime() - lastPA >= PA_GAP and LC.Announce then
        lastPA = CurTime()
        pcall(LC.Announce, "ambient", nil, paRestrict)
    end
    paRestrict = nil
end
LC.MarketFlushAnnounce = FlushAnnounce

local function Queue(line)
    pending[#pending + 1] = line
    timer.Create("LivingCityMarketAnnounce", 3, 1, FlushAnnounce) -- (a few changes at once: one notice)
end

local function Credits(n) return n == 1 and "1 credit" or (n .. " credits") end

-- field: "restrict" ("1"/"0"), "price" (a factor), "standing" (a number, or "default"),
-- "supply" (plentiful, normal, scarce) or "reset". True, or false and why not.
function LC.MarketSet(ply, id, field, value)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false, "Only the City Administrator." end
    if not On() then return false, "The market is switched off on this server (lc_market 0)." end
    local g = LCS.GoodsById[id]
    if not Controllable(g) then return false, "Not something the Commissary sells to citizens." end
    Ensure()
    local r = M.rules[id] or {}
    local line
    value = tostring(value or "")
    if field == "restrict" then
        local on = value == "1" or value == "true"
        if (r.restricted == true) == on then return true end
        r.restricted = on or nil
        line = on and (g.name .. " is restricted: no longer sold.") or (g.name .. " is on sale again.")
        if on then paRestrict = "By order of the City Administrator, " .. string.lower(g.name) .. " is no longer sold at the Commissary." end
    elseif field == "price" then
        local f = tonumber(value)
        if not f then return false end
        f = math.Clamp(math.floor(f * 20 + 0.5) / 20, PRICE_MIN, PRICE_MAX)
        r.mul = f ~= 1 and f or nil
        local now = math.max(1, math.floor(g.price * f + 0.5))
        line = f == 1 and (g.name .. " is back to its usual price, " .. Credits(g.price) .. ".")
            or string.format("%s now costs %s (usually %d).", g.name, Credits(now), g.price)
    elseif field == "standing" then
        local n = tonumber(value)
        if value == "default" or n == nil or math.floor(n) == BaseStanding(g) then
            r.minStanding = nil
            line = g.name .. " needs the usual standing again (" .. LC.MarketStandingText(BaseStanding(g)) .. ")."
        else
            n = math.Clamp(math.floor(n), -50, 1000)
            r.minStanding = n
            line = g.name .. " now needs " .. LC.MarketStandingText(n) .. "."
        end
    elseif field == "supply" then
        if not SUPPLY[value] then return false end
        r.supply = value ~= "normal" and value or nil
        if value == "scarce" then
            M.stock[id] = math.max(0, cvScarce:GetInt())
            M.restockAt[id] = nil
            line = string.format("%s is scarce: %d at a time, restocked slowly.", g.name, math.max(0, cvScarce:GetInt()))
        else
            M.stock[id], M.restockAt[id] = nil, nil
            line = value == "plentiful" and (g.name .. " is plentiful.") or (g.name .. " is in normal supply.")
        end
    elseif field == "reset" then
        if not M.rules[id] then return true end
        r = {}
        M.stock[id], M.restockAt[id] = nil, nil
        line = g.name .. " is back to normal: on sale, at the usual price, for the usual standing."
    else
        return false
    end
    M.rules[id] = next(r) and r or nil
    LC.MarketSave()
    if line then Queue(line) end
    return true
end

------------------------------------------------------------------------
-- The Administrator's panel
------------------------------------------------------------------------

function LC.MarketAdminData()
    local goods, black = {}, {}
    for _, g in ipairs(LCS.Goods) do
        if Controllable(g) then
            local r = LC.MarketRule(g.id)
            local b = LC.MarketBlackById(g.id) or LC.MarketBlackById("mkt_" .. g.id)
            for _, x in ipairs(LCS.Black) do if not b and Key(x) == Key(g) then b = x end end
            goods[#goods + 1] = {
                id = g.id, name = g.name, price = g.price, now = math.max(1, math.floor(g.price * LC.MarketCommissaryMul(g) + 0.5)),
                restricted = r.restricted, mul = r.mul, standing = LC.MarketMinStanding(g), baseStanding = BaseStanding(g),
                supply = r.supply, stock = LC.MarketStock(g.id), note = LC.MarketCommissaryNote(g),
                demand = Pct(LC.MarketDemandMul(Key(g))), black = b and (LC.BlackPrice and LC.BlackPrice(b) or b.price) or nil,
            }
        end
    end
    for _, b in ipairs(LC.MarketBlackList()) do
        local now = LC.BlackPrice and LC.BlackPrice(b) or b.price
        local note = LC.MarketBlackNote(b)
        if b.extra or note or now ~= b.price then
            black[#black + 1] = { name = b.name, price = now, usual = b.price, note = note, demand = Pct(LC.MarketDemandMul(Key(b))), extra = b.extra }
        end
    end
    local restricted = {}
    for _, g in ipairs(LCS.Goods) do if LC.MarketRestricted(g) then restricted[#restricted + 1] = g.name end end
    return { on = On(), goods = goods, black = black, restricted = restricted, mood = LC.MarketMood(),
        tiers = LCS.Tiers and (function() local t = {} for _, x in ipairs(LCS.Tiers) do if x.min > -1e8 then t[#t + 1] = { name = x.name, min = x.min } end end return t end)() or {} }
end

function LC.MarketOpenAdmin(ply)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false end
    if LC.SendCompressed then LC.SendCompressed("lc_market_admin", LC.MarketAdminData(), { ply }) end
    return true
end

net.Receive("lc_market_open", function(_, ply) LC.MarketOpenAdmin(ply) end)
net.Receive("lc_market_set", function(_, ply)
    local id, field, value = net.ReadString(), net.ReadString(), net.ReadString()
    local ok, why = LC.MarketSet(ply, id, field, value)
    if not ok and IsValid(ply) then ply:ChatPrint("[Office] " .. (why or "No.")) end
    LC.MarketOpenAdmin(ply)
end)

------------------------------------------------------------------------
-- Every minute: demand cools, scarce goods come back one at a time, and it's saved now and then
------------------------------------------------------------------------

local lastSave = 0
function LC.MarketTick()
    if not On() then return end
    Ensure()
    local k = 0.5 ^ (1 / math.max(1, cvHalf:GetFloat()))
    for key, d in pairs(M.demand) do
        d = d * k
        M.demand[key] = d >= 0.05 and d or nil
        dirty = true
    end
    local now = CurTime()
    for id in pairs(M.stock) do
        local g = LCS.GoodsById[id]
        if not Scarce(g) then
            M.stock[id], M.restockAt[id] = nil, nil
        elseif M.stock[id] < cvScarce:GetInt() then
            M.restockAt[id] = M.restockAt[id] or (now + math.max(1, cvRestock:GetFloat()) * 60)
            if now >= M.restockAt[id] then
                M.stock[id] = M.stock[id] + 1
                M.restockAt[id] = M.stock[id] < cvScarce:GetInt() and (now + math.max(1, cvRestock:GetFloat()) * 60) or nil
                dirty = true
            end
        else
            M.restockAt[id] = nil
        end
    end
    if dirty and now - lastSave > 300 then lastSave = now LC.MarketSave() end
end
timer.Create("LivingCityMarket", 60, 0, function() LC.MarketTick() end)
hook.Add("ShutDown", "LivingCityMarket", function() if dirty then LC.MarketSave() end end)
