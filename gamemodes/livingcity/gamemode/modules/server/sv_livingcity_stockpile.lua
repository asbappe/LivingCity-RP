--[[
    Living City: the city's stores

    The rations the dispensers hand out come from somewhere: the city's
    stores, shown under the clock as a share of what they hold
    (lc_stock_max, 400 rations).

      In    a kitchen shift (+12) or a factory shift (+8), worked by a player;
            the city's own kitchen and factory workers (a few a time); a
            train's freight (+15); a supply convoy, for every load that wasn't
            stolen (+15 a load)
      Out   every ration handed out (one), and the city eating (a little every
            minute for every lc_stock_eat (20) citizens out)

    Running low (under a quarter): allocations come slower, the dispensers
    are sometimes empty, the PA says so, and hungry people listen to the
    Resistance (rebel ground spreads faster). Empty: no rations at all until
    something comes in. Well stocked (over four fifths): the city is calmer.
    Saved per map. lc_stockpile 0 turns it off (rations are endless again).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn  = CreateConVar("lc_stockpile", "1", FLAGS, "Rations come from the city's stores, which work fills and people empty")
local cvMax = CreateConVar("lc_stock_max", "400", FLAGS, "Rations the city's stores hold")
local cvEat = CreateConVar("lc_stock_eat", "20", FLAGS, "The city eats a ration a minute for every this many citizens out (lower empties the stores faster)")

local stock = nil
local dirty = false

local function Path() return "livingcity/" .. game.GetMap() .. "_stock.json" end

local function Max() return math.max(10, cvMax:GetInt()) end

local function Publish()
    SetGlobal2Int("lc_stock", math.floor(stock or 0))
    SetGlobal2Int("lc_stock_max", Max())
    SetGlobal2Bool("lc_stock_on", cvOn:GetBool())
end

local function Load()
    stock = math.floor(Max() / 2)
    local t = LC.SafeReadJSON(Path())
    if istable(t) and tonumber(t.stock) then stock = math.Clamp(tonumber(t.stock), 0, Max()) end
    Publish()
end

function LC.StockSave()
    dirty = false
    if not file or not file.Write or stock == nil then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    LC.SafeWrite(Path(), util.TableToJSON({ stock = stock }))
end

function LC.Stock()
    if stock == nil then Load() end
    return stock
end
function LC.StockOn() return cvOn:GetBool() end
function LC.StockFraction() return LC.Stock() / Max() end

-- "empty", "short", "normal" or "full"
function LC.StockLevel()
    if not cvOn:GetBool() then return "normal" end
    local s, m = LC.Stock(), Max()
    if s <= 0 then return "empty" end
    if s < m * 0.25 then return "short" end
    if s > m * 0.8 then return "full" end
    return "normal"
end

local SAY = {
    empty = "The city's ration stores are empty. Distribution is suspended until supplies arrive.",
    short = "Ration stores are running low. Allocations will be slower until supplies arrive.",
    full = "Ration stores are full. Productive citizens are rewarded.",
}

local lastLevel
local function CheckLevel()
    local lvl = LC.StockLevel()
    if lastLevel and lvl ~= lastLevel and SAY[lvl] and LC.Announce then
        local ok = pcall(LC.Announce, "ambient", nil, SAY[lvl])
        if not ok then for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] " .. SAY[lvl]) end end
    end
    if lvl ~= lastLevel then hook.Run("LivingCityStockLevel", lvl, lastLevel) end
    lastLevel = lvl
end

function LC.StockAdd(n, why)
    if not cvOn:GetBool() or not n or n == 0 then return LC.Stock() end
    stock = math.Clamp(LC.Stock() + n, 0, Max())
    dirty = true
    Publish()
    CheckLevel()
    return stock
end

-- One ration out of the stores, if there is one.
function LC.StockTake(n)
    if not cvOn:GetBool() then return true end
    n = n or 1
    if LC.Stock() < n then return false end
    LC.StockAdd(-n)
    return true
end

-- Allocations come slower while the stores are low.
function LC.StockIntervalMul()
    local lvl = LC.StockLevel()
    if lvl == "short" then return 1.5 end
    return 1
end

------------------------------------------------------------------------
-- What comes in
------------------------------------------------------------------------

local SHIFT_YIELD = { kitchen = 12, factory = 8 }
hook.Add("LivingCityCounter", "LivingCityStock", function(ply, counter, n)
    if counter ~= "shifts" or (n or 1) <= 0 then return end
    local job = LC.Job and LC.Job(ply)
    local y = job and SHIFT_YIELD[job.id]
    if y then LC.StockAdd(y, "shift") end
end)

local NPC_YIELD = { supply = 4, cook = 3, parts = 2, line = 2, station = 1 }
hook.Add("LivingCityNPCWorkFinished", "LivingCityStock", function(npc, st, id)
    local y = NPC_YIELD[id]
    if y and st and st.profile and (st.profile.job == "kitchen" or st.profile.job == "factory") then LC.StockAdd(y, "npc work") end
end)

hook.Add("LivingCityTrainArrived", "LivingCityStock", function() LC.StockAdd(15, "train freight") end)
hook.Add("LivingCitySupplyEnded", "LivingCityStock", function(s, left) if (left or 0) > 0 then LC.StockAdd(left * 15, "convoy") end end)

------------------------------------------------------------------------
-- What goes out
------------------------------------------------------------------------

hook.Add("LivingCityServed", "LivingCityStock", function() LC.StockAdd(-1, "ration line") end)

timer.Create("LivingCityStock", 60, 0, function()
    if not cvOn:GetBool() then return end
    if LC.Running then
        -- the city eats: a ration a minute for every lc_stock_eat (20) people out
        -- (it was every fifteen: a full city of 80 ate 6 a minute, more than its
        -- kitchen, factory and trains could ever bring in)
        local out = LC.RoleCounts and LC.RoleCounts.citizen or 0
        LC.StockAdd(-math.ceil(out / math.max(5, cvEat:GetFloat())))
        local lvl = LC.StockLevel()
        -- hungry people listen to the Resistance; fed ones keep their heads down
        if lvl == "short" or lvl == "empty" then
            LC.RebelSurgeUntil = math.max(LC.RebelSurgeUntil or 0, CurTime() + 90)
        elseif lvl == "full" then
            LC.RebelCalmUntil = math.max(LC.RebelCalmUntil or 0, CurTime() + 90)
        end
    end
    if dirty then LC.StockSave() end
end)

hook.Add("InitPostEntity", "LivingCityStock", function() timer.Simple(2, function() Load() lastLevel = LC.StockLevel() end) end)
hook.Add("ShutDown", "LivingCityStock", function() if dirty then LC.StockSave() end end)

concommand.Add("lc_stock", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local n = tonumber(args[1])
    if n then LC.StockAdd(n - LC.Stock(), "admin") end
    local msg = string.format("[Living City] City stores: %d of %d rations (%s).", LC.Stock(), Max(), LC.StockLevel())
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
