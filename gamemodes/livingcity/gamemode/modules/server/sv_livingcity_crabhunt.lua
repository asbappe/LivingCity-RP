--[[
    Living City: headcrab hunts for the Resistance's supply crate

    The owner, 7 November: Resistance jobs to go into the infestation and bring
    back raw headcrabs for food. Dangerous, and worth it while the crate is
    empty.

      The job        "Headcrab hunt" on the Resistance's Operations board (F4):
                     go into the infested ground (marked), kill headcrabs
                     there (a few more crawl out for it), pick up the raw meat
                     they leave (E), and bring it to the camp's supply crate.
                     Standing by the crate, the meat goes in on its own: each
                     headcrab is one meal in the crate (roasted, it feeds like
                     a tin).
      When           only while there's infested ground and a rebel camp. It
                     turns up now and then on the board; whenever a crate is
                     running low it's always there, and when a crate runs
                     empty it's posted straight away (once every twenty
                     minutes at most) with a notice to the Resistance.
      Pay            XP like any operation (30), and more (+15) if the crate
                     was empty when the meat came in.
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Count, Narrate, Place, Pick, Members = Q.Goto, Q.Count, Q.Narrate, Q.Place, Q.Pick, Q.Members

LC.CrabHunt = LC.CrabHunt or {}
local CH = LC.CrabHunt
CH.NEED = 4            -- headcrabs to kill, and raw meat to bring back
CH.REWARD = 30         -- XP, like the other operations
CH.EMPTY_BONUS = 15    -- XP more when the crate was empty as the meat came in
CH.REPOST = 1200       -- seconds between postings when a crate runs empty
CH.CHANCE = 0.3        -- how often it turns up on the board while the crate is well stocked

-- what counts as headcrab meat at the crate (raw, of any kind; a roasted one too)
CH.MEAT = { "raw_headcrab", "raw_fastcrab", "raw_poisoncrab", "cooked_headcrab" }
local CRABS = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true }
CH.CRABS = CRABS

local function Crates()
    local out = {}
    for _, r in pairs(LC.RebelProps or {}) do if IsValid(r.cache) then out[#out + 1] = r.cache end end
    return out
end

-- A crate that's running low: under a quarter of what a delivery fills it to, or two meals or fewer.
function CH.Low(cache)
    if not IsValid(cache) then return false end
    return (cache.lcStock or 0) <= math.max(2, math.floor((cache.lcFoodCap or 0) / 4))
end

local function Nearest(list, pos, posOf)
    local best, bd
    for _, x in ipairs(list) do
        local d = posOf(x):DistToSqr(pos)
        if not bd or d < bd then best, bd = x, d end
    end
    return best
end

function CH.Available()
    if #(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) == 0 then return false end
    local crates = Crates()
    if #crates == 0 then return false end
    for _, c in ipairs(crates) do if CH.Low(c) then return true end end
    return math.random() < CH.CHANCE
end

-- Meat in this player's pockets that the crate would take.
local function Held(ply)
    local n = 0
    for _, id in ipairs(CH.MEAT) do
        local k = 0
        while LC.HasItem(ply, id, k + 1) do k = k + 1 end
        n = n + k
    end
    return n
end
CH.MeatHeld = Held

-- A headcrab for the hunt, somewhere in the zone, out of sight if it can be.
local function SpawnCrab(z)
    if not LC.SpawnZombie or not LC.SpotInZone then return nil end
    local spot
    for _ = 1, 6 do
        local p = LC.SpotInZone(z)
        if p and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 30))) then spot = p break end
    end
    spot = spot or LC.SpotInZone(z)
    if not spot then return nil end
    local npc, st = LC.SpawnZombie(spot + Vector(0, 0, 4), z, Pick({ "npc_headcrab", "npc_headcrab", "npc_headcrab", "npc_headcrab_fast" }))
    if st then st.unmanaged = true end -- (extra, on top of the usual number: nothing replaces it)
    return npc
end

local function LiveCrabsNear(pos, r)
    local n = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and CRABS[npc:GetClass()] and npc:GetPos():DistToSqr(pos) < r * r then n = n + 1 end
    end
    return n
end

-- Put the meat of everyone on the job standing by the crate into it. Returns how many went in.
function CH.Deposit(q, st, cache)
    if not IsValid(cache) then return 0 end
    local put = 0
    for _, p in ipairs(Members(q)) do
        if IsValid(p) and p:Alive() and p:GetPos():DistToSqr(cache:GetPos()) < (st.r or 200) ^ 2 then
            for _, id in ipairs(CH.MEAT) do
                while (st.got or 0) < st.need and LC.HasItem(p, id) do
                    if (cache.lcStock or 0) <= 0 then q.data.wasEmpty = true end
                    LC.TakeItem(p, id)
                    if LC.AddToCache then LC.AddToCache(cache, 1) end
                    st.got = (st.got or 0) + 1
                    put = put + 1
                end
            end
        end
    end
    return put
end

LC.QuestTemplates[#LC.QuestTemplates + 1] = {
    -- (not a "violent" job: no squad of fighters, it isn't a fight with the Combine)
    id = "res_crabhunt", factions = { resistance = true }, squad = 4,
    available = function() return CH.Available() end,
    build = function(ply, focus)
        local zones = LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}
        local crates = Crates()
        if #zones == 0 or #crates == 0 then return nil end
        -- the crate: the one that ran empty (when posted for it), else the nearest that's low, else the nearest
        local cache
        if IsValid(focus) then for _, c in ipairs(crates) do if c == focus then cache = c end end end
        if not cache then
            local low = {}
            for _, c in ipairs(crates) do if CH.Low(c) then low[#low + 1] = c end end
            cache = Nearest(#low > 0 and low or crates, ply:GetPos(), function(c) return c:GetPos() end)
        end
        -- the hunting ground: infested ground nearest the camp
        local z = Nearest(zones, cache:GetPos(), function(x) return x.pos end)
        local need = CH.NEED
        local area = math.max(700, z.r * 1.6)
        local enter = Goto(z.pos, "Go into the infested ground (marked)", math.max(200, z.r))
        local hunt = Count("killed", need, "Kill headcrabs in the infested ground, and pick up the raw meat they leave (E)",
            function(_, _, npc) return IsValid(npc) and CRABS[npc:GetClass()] ~= nil and npc:GetPos():DistToSqr(z.pos) < area * area end)
        hunt.pos = z.pos
        hunt.onEnter = function(q)
            -- they're expected: a few more crawl out, and more if the team runs out of them
            q.data.crabs, q.data.spawned = {}, 0
            for _ = 1, need + 1 do
                local c = SpawnCrab(z)
                if c then q.data.crabs[#q.data.crabs + 1] = c q.data.spawned = q.data.spawned + 1 end
            end
            Narrate(q, "Headcrabs everywhere here. Mind the zombies. Every one you kill leaves its meat: pick it up (E), don't eat it raw.")
        end
        hunt.poll = function(q, st)
            if (st.got or 0) >= st.need then return end
            if q.data.spawned < need * 2 + 2 and LiveCrabsNear(z.pos, area) == 0 and CurTime() >= (q.data.nextCrab or 0) then
                q.data.nextCrab = CurTime() + 15
                local c = SpawnCrab(z)
                if c then q.data.crabs[#q.data.crabs + 1] = c q.data.spawned = q.data.spawned + 1 end
            end
        end
        local bring = Count("crab_meat", need, "Bring the raw headcrabs to the Resistance supply crate (marked): stand by it")
        bring.pos, bring.r = cache:GetPos(), 200
        bring.poll = function(q, st)
            if not IsValid(cache) then
                local other = Crates()[1]
                if not other then return Q.Finish(q, false, "the supply crate is gone") end
                cache = other
                st.pos = cache:GetPos()
            end
            -- any of the Resistance's supply crates will do: standing by another one with the meat, that
            -- one is the crate now (the owner, 13 November: "if I am at a different supply crate than
            -- marked, how about it just let me put the headcrabs in there?")
            for _, c in ipairs(Crates()) do
                if IsValid(c) and c ~= cache then
                    for _, p in ipairs(Members(q)) do
                        if IsValid(p) and Held(p) > 0 and p:GetPos():DistToSqr(c:GetPos()) < (st.r or 200) ^ 2 then
                            cache = c
                            st.pos = c:GetPos()
                            Q.SendStateAll(q)
                            break
                        end
                    end
                end
            end
            -- what they're carrying, on the tracker
            local have = 0
            for _, p in ipairs(Members(q)) do if IsValid(p) then have = have + Held(p) end end
            local text = string.format("Bring the raw headcrabs to the Resistance supply crate (marked): stand by it (carrying %d)", have)
            if st.text ~= text then st.text = text Q.SendStateAll(q) end
            if CH.Deposit(q, st, cache) > 0 then
                if st.got >= st.need then return Q.Advance(q) end
                Q.SendStateAll(q)
            end
        end
        bring.onDone = function(q)
            local stock = IsValid(cache) and (cache.lcStock or 0) or 0
            if q.data.wasEmpty then
                q.bonus = CH.EMPTY_BONUS
                Narrate(q, string.format("The crate was empty: the camp needed this. %d meals of headcrab in the stores now (+%d XP for it).", stock, CH.EMPTY_BONUS))
            else
                Narrate(q, string.format("Headcrab meat in the stores: the camp roasts it. The crate holds %d meals now.", stock))
            end
        end
        local empty = (cache.lcStock or 0) <= 0
        return {
            title = "Headcrab hunt " .. Place(z.pos, ply:GetPos()), reward = CH.REWARD, limit = 900,
            desc = (empty and "The supply crate is empty. " or (CH.Low(cache) and "The supply crate is running low. " or "The camp could use more food. "))
                .. "There's meat in the infested ground " .. Place(z.pos, ply:GetPos()) .. ": go in, kill " .. need
                .. " headcrabs, pick up what they leave and bring it back to the crate. Dangerous: zombies, and poison headcrabs."
                .. (empty and " Worth more while the crate's empty." or ""),
            stages = { enter, hunt, bring },
            onFinish = function(q)
                -- leftover headcrabs wander off once nobody's looking
                for _, npc in ipairs(q.data.crabs or {}) do
                    local st = IsValid(npc) and LC.NPCs[npc]
                    if st then st.surgeExpires = CurTime() + 120 end
                end
            end,
        }
    end,
}

-- A crate runs empty: put the job up for the Resistance straight away, and tell them.
function CH.Check(now)
    now = now or CurTime()
    if not LC.Running or now < (CH.nextPost or 0) then return nil end
    if #(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) == 0 then return nil end
    local empty
    for _, c in ipairs(Crates()) do if (c.lcStock or 0) <= 0 then empty = c break end end
    if not empty or not LC.PostDirective then return nil end
    local made = LC.PostDirective("res_crabhunt", empty)
    if #made == 0 then return nil end
    CH.nextPost = now + CH.REPOST
    if LC.Notice then
        for _, p in ipairs(player.GetAll()) do
            if LC.QuestFaction and LC.QuestFaction(p) == "resistance" then
                LC.Notice(p, "info", "Resistance supplies", "The supply crate is empty. A headcrab hunt is up on your Operations board (F4): bring raw headcrabs back from the infested ground.")
            end
        end
    end
    return made[1]
end

timer.Create("LivingCityCrabHunt", 30, 0, function()
    local ok, err = LC.Try(CH.Check)
    if not ok and LC.Error then LC.Error("headcrab hunt", err) end
end)
