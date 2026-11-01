--[[
    Living City: what loyalty earns (the owner, 2026-11-01: "other rewards for high standing civilians? All of them")

    For citizens (and anyone who passes as one) by Civil Standing tier, Trusted (150) and Exemplary (400):
      Fewer stops        units stop a Trusted citizen half as often, an Exemplary one rarely; and stopping
                         an Exemplary citizen is a glance at the papers, not a search
      Better pay         Union shifts pay 10% more (Trusted) or 25% more (Exemplary)
      A discount         10% (Trusted) or 20% (Exemplary) off at the Union Commissary
      Food               an Exemplary citizen earns two ration cards for each finished shift
      Curfew leniency    Trusted: a minute longer to get home; Exemplary: waved through once a curfew
      A slip forgiven    Exemplary: a minor offence (a curfew slip, loitering, defacing, trespass) is a
                         warning instead of wanted, once a day
      Public praise      now and then the Administrator commends an Exemplary citizen by name, and their
                         papers carry a MODEL CITIZEN stamp
      Lockers            only citizens in good standing (lc_locker_standing, 150) can use a locker
                         (sv_livingcity_storage.lua)
      Block Warden       a Union job for Exemplary citizens: walk your block, have a word with the
                         neighbours, and report what isn't right (paid when it holds up)
    (Free rent from 200 is in sv_livingcity_business.lua.)

      lc_loyalty_rewards 0/1 (1), lc_loyalty_praise_minutes (20)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_loyalty_rewards", "1", FLAGS, "Trusted and Exemplary citizens get fewer stops, better pay, a discount, more food, curfew leniency, a slip forgiven and praise")
local cvPraise = CreateConVar("lc_loyalty_praise_minutes", "20", FLAGS, "Minutes between the Administrator commending an Exemplary citizen by name (0: never)")

local TRUSTED, EXEMPLARY = 150, 400

-- "exemplary", "trusted" or nil. Only for citizens (and those passing as one): units have their own rewards.
function LC.LoyalTier(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:IsPlayer() then return nil end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return nil end
    local f = ply:GetNW2String("lcf_faction", "")
    if f ~= "" and f ~= "citizen" and f ~= "resistance" then return nil end
    local s = LC.Standing and LC.Standing(ply) or 0
    if s >= EXEMPLARY then return "exemplary" end
    if s >= TRUSTED then return "trusted" end
    return nil
end

local function By(ply, trusted, exemplary, otherwise)
    local t = LC.LoyalTier(ply)
    if t == "exemplary" then return exemplary end
    if t == "trusted" then return trusted end
    return otherwise
end

function LC.LoyalStopMul(ply) return By(ply, 0.5, 0.15, 1) end
function LC.LoyalPayMul(ply) return By(ply, 1.10, 1.25, 1) end
function LC.LoyalPriceMul(ply) return By(ply, 0.90, 0.80, 1) end
function LC.LoyalExtraCards(ply) return By(ply, 0, 1, 0) end
function LC.LoyalCurfewGrace(ply) return By(ply, 60, 60, 0) end
function LC.LoyalStashExtra(ply) return 0 end -- (no bigger stash: lockers are the reward now, sv_livingcity_storage.lua)
function LC.LoyalNoSearch(ply) return LC.LoyalTier(ply) == "exemplary" end
function LC.ModelCitizen(ply) return LC.LoyalTier(ply) == "exemplary" end

-- Once a curfew, an Exemplary citizen is waved through (sv_livingcity_underground.lua asks, at a curfew stop).
function LC.LoyalCurfewPass(ply, cop)
    if not LC.ModelCitizen(ply) or ply.lcLoyalPassSerial == LC.EventSerial then return false end
    ply.lcLoyalPassSerial = LC.EventSerial
    ply.lcPermitSerial = LC.EventSerial
    if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/allrightyoucango.wav", 75) end
    ply:ChatPrint("[Civil Protection] The unit looks at your papers, and then at you. \"A model citizen. Get home, citizen.\" You're cleared until this is over.")
    return true
end

-- A slip forgiven: once an in-game day, a minor offence by an Exemplary citizen is a warning.
local MINOR = { "curfew", "loitering", "defacing", "trespass" }
hook.Add("LivingCityCrime", "LivingCityLoyalty", function(ply, reason)
    if not LC.ModelCitizen(ply) then return end
    local r = string.lower(tostring(reason or ""))
    local minor = false
    for _, w in ipairs(MINOR) do if string.find(r, w, 1, true) then minor = true break end end
    if not minor then return end
    local day = math.max(60, GetGlobal2Float("lc_day_len", 1440))
    if (ply.lcLoyalForgivenAt or -1e9) + day > CurTime() then return end
    ply.lcLoyalForgivenAt = CurTime()
    if LC.Notice then
        LC.Notice(ply, "warn", "A warning", "\"" .. tostring(reason) .. ".\" The unit lets it go this once: a model citizen gets a warning. Next time, it counts.", 9)
    end
    return false -- (not booked: ReportCrime gives up)
end)

-- Now and then, the Administrator commends one of them by name, to everyone.
local nextPraise = 0
local function Praise(now)
    local mins = cvPraise:GetFloat()
    if mins <= 0 or now < nextPraise then return end
    nextPraise = now + mins * 60
    local cands = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.ModelCitizen(p) and (p.lcPraisedAt or -1e9) + 3600 < now then cands[#cands + 1] = p end
    end
    if #cands == 0 then return end
    local p = cands[math.random(#cands)]
    p.lcPraisedAt = now
    local name = LC.CharacterName and LC.CharacterName(p) or p:Nick()
    local cv = GetConVar("lc_administrator_name")
    local admin = cv and cv:GetString() ~= "" and cv:GetString() or "The Administrator"
    for _, o in ipairs(player.GetAll()) do
        if LC.Notice then
            LC.Notice(o, "event", admin, string.format("Citizen %s is commended for exemplary conduct. Let %s be an example to us all.", name, o == p and "you" or "them"), 10)
        end
    end
    if LC.AddStanding then LC.AddStanding(p, 5, "Commended by the Administrator") end
end
LC.LoyalPraise = function(now) nextPraise = 0 Praise(now or CurTime()) end -- (for tests)
timer.Create("LivingCityLoyalty", 10, 0, function()
    local ok, err = pcall(Praise, CurTime())
    if not ok and LC.Error then LC.Error("loyalty", err) end
end)
