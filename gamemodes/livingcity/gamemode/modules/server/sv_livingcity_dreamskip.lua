--[[
    Living City: sitting out a kind of dream, earned (the owner, 10 November).

      - Happy dreams: anyone who has lived through 2 Happy dreams may sit
        them out.
      - Neutral dreams: the same, after 2 Neutral dreams.
      - Nightmares and propaganda dreams: only a citizen with Exemplary
        standing (lc_dream_skip_standing, 400), the city's favoured.
    Chosen per kind in F2 > Me (More) > My dreams (also C > Settings > Shared dreams, or /dream skip happy,
    /dream skip neutral, /dream skip nightmare, /dream skip propaganda;
    the same again to dream them again). Whoever has earned it but hasn't
    chosen it sees a small note as the screen goes black for a dream.
    Sitting a dream out, they sleep through it. Dreams lived through are
    counted per kind for each character (not as an Enforcer, not a test).

      lc_dream_skip 0/1, lc_dream_skip_after (2), lc_dream_skip_standing (400)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_dream_skip", "1", FLAGS, "Dreams can be sat out once earned: Happy or Neutral after living through 2 of that kind, Nightmares and propaganda with Exemplary standing")
local cvAfter    = CreateConVar("lc_dream_skip_after", "2", FLAGS, "Happy (or Neutral) dreams someone must live through before they may sit that kind out")
local cvStanding = CreateConVar("lc_dream_skip_standing", "400", FLAGS, "Civil Standing a citizen needs to sit out Nightmares and propaganda dreams")

local KINDS = { happy = "Happy", neutral = "Neutral", nightmare = "Nightmares", propaganda = "propaganda" }
LC.DreamSkipKinds = KINDS

local function Kind(id, mood)
    if id and LC.PropagandaDreams and LC.PropagandaDreams[id] then return "propaganda" end
    return mood or (id and LC.DreamMood and LC.DreamMood(id)) or "neutral"
end

function LC.DreamsLivedOfKind(p, kind)
    return IsValid(p) and p.GetPData and (tonumber(p:GetPData("lc_dreams_" .. kind, "0")) or 0) or 0
end

-- May they sit this kind out? True, or false and why not.
function LC.DreamSkipEarned(p, kind)
    if not cvOn:GetBool() or not IsValid(p) then return false, "Nobody can sit out the city's dreams here." end
    if kind == "happy" or kind == "neutral" then
        local have, need = LC.DreamsLivedOfKind(p, kind), cvAfter:GetInt()
        if have >= need then return true end
        return false, string.format("Live through %d more %s dream%s first.", need - have, KINDS[kind], need - have == 1 and "" or "s")
    end
    local f = p:GetNW2String("lcf_faction", "")
    local standing = LC.Standing and LC.Standing(p) or 0
    if (f == "" or f == "citizen") and standing >= cvStanding:GetFloat() then return true end
    return false, string.format("Only a citizen with Civil Standing %d (Exemplary) may sit out %s.", cvStanding:GetInt(), KINDS[kind] or kind)
end

local function Prefs(p)
    if not p.lcDreamSkip then
        local t = util.JSONToTable(p:GetPData("lc_dream_sitout", "") or "")
        p.lcDreamSkip = istable(t) and t or {}
    end
    return p.lcDreamSkip
end

-- Sitting this dream out (they've earned it and chosen it).
function LC.DreamSkips(p, id, mood)
    if not cvOn:GetBool() or not IsValid(p) or not p.GetPData then return false end
    local kind = Kind(id, mood)
    return Prefs(p)[kind] == true and LC.DreamSkipEarned(p, kind) == true
end

-- The small note as the screen goes black: earned, not chosen.
function LC.DreamSkipHint(p, id, mood)
    if not cvOn:GetBool() or not IsValid(p) or not p.GetPData then return nil end
    local kind = Kind(id, mood)
    if Prefs(p)[kind] or not LC.DreamSkipEarned(p, kind) then return nil end
    return string.format("You've earned the right to sit out %s dreams: F2 > Me (More) > My dreams.", KINDS[kind] == "Nightmares" and "nightmare" or string.lower(KINDS[kind]))
end

local function Sync(p)
    local pr = Prefs(p)
    local earned = {}
    for k in pairs(KINDS) do earned[k] = LC.DreamSkipEarned(p, k) == true end
    p:SetNW2String("lc_dream_sitout", util.TableToJSON({ on = pr, earned = earned }) or "")
end
LC.DreamSkipSync = Sync

function LC.SetDreamSkip(p, kind, skip)
    if not KINDS[kind] then return false, "Which dreams? Happy, Neutral, Nightmares or propaganda." end
    local ok, why = LC.DreamSkipEarned(p, kind)
    if skip and not ok then return false, why end
    local pr = Prefs(p)
    pr[kind] = skip and true or nil
    p:SetPData("lc_dream_sitout", util.TableToJSON(pr))
    Sync(p)
    p:ChatPrint("[Dreams] " .. (skip and ("You'll sleep through " .. KINDS[kind] .. " dreams.") or ("You'll dream " .. KINDS[kind] .. " dreams again.")))
    return true
end

-- One more lived through, of its kind (not as an Enforcer, not a test).
hook.Add("LivingCityDreamWoke", "LivingCityDreamSkip", function(p, _, why)
    if not IsValid(p) or not p.SetPData or p.lcDreamWokeEnforcer or why == "test" then return end
    local dream = LC.DreamActive
    if not dream or not dream.id or dream.test then return end
    local kind = Kind(dream.id, dream.mood)
    if not KINDS[kind] then return end
    p:SetPData("lc_dreams_" .. kind, tostring(LC.DreamsLivedOfKind(p, kind) + 1))
    Sync(p)
end)

hook.Add("LivingCityCharacterSwitched", "LivingCityDreamSkip", function(p)
    if IsValid(p) then p.lcDreamSkip = nil timer.Simple(0.5, function() if IsValid(p) then Sync(p) end end) end
end)
hook.Add("PlayerInitialSpawn", "LivingCityDreamSkip", function(p)
    timer.Simple(5, function() if IsValid(p) then Sync(p) end end)
end)
-- (standing moves all the time: what's earned is looked at again now and then)
timer.Create("LivingCityDreamSkip", 30, 0, function()
    for _, p in ipairs(player.GetAll()) do pcall(Sync, p) end
end)
hook.Add("LivingCityNewCharacter", "LivingCityDreamSkip", function(p)
    if not IsValid(p) then return end
    for k in pairs(KINDS) do p:RemovePData("lc_dreams_" .. k) end
    p:RemovePData("lc_dream_sitout")
    p.lcDreamSkip = nil
    Sync(p)
end)
