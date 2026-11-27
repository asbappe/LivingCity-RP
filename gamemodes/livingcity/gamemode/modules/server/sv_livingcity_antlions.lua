--[[
    Living City: antlions at a stopped thumper (the owner's long-term list, 18 November, 5: "thumpers keep
    them off (the Combine's, which a saboteur can switch off), they come up through sand or soft ground").
    The first small piece of it, and only where a map has the thumper module (docs/dev/canal-modules.md):

      lc_thumper_head    the thumper (prop_thumper). The map's button stops and starts it (Disable, Enable).
      lc_thumper_burrow  the burrow's mouth near it: where they come up.

    A map may have several copies of the module (27 November: four on the canal ring). The first keeps these names;
    the others have a number after "thumper" (lc_thumper2_head, lc_thumper2_burrow, ...). Every name is read as
    ^lc_thumper(%d*)_(%w+)$, and a copy's parts go together by that number ("" for the first).

    While a thumper stands still, antlions dig up at its burrow as Valve's own makers send them
    (ep2_outland_05): two out at most, from a pool of four that gets one back every 25 seconds, so killing
    them buys a breather and lingering brings more. They go for everyone: units, rebels, citizens.
    Started again, the thumper drives off what is left (the game does that itself) and after a minute those
    still alive dig themselves away. Nothing is written on anyone's screen.
    On a map without these names nothing here happens.
]]

LC = LC or {}
LC.Antlions = LC.Antlions or { stopped = {}, out = {} }
local A = LC.Antlions

local GRACE, EVERY, OUT_MAX, POOL_MAX, REGEN, REACH, HEARD = 15, 8, 2, 4, 25, 2000, 3500

local function NameOf(e) return string.lower(tostring(e.GetName and e:GetName() or "")) end

-- A thumper module's name read: its copy's number ("" for the first) and the part ("head", "burrow", "button",
-- "start", "stop" ...). nil for any other name.
function A.Parse(name)
    local n, part = string.match(string.lower(tostring(name or "")), "^lc_thumper(%d*)_(%w+)$")
    return n, part
end

-- Every thumper on the map (each copy's head).
function A.Heads()
    local out = {}
    for _, e in ipairs(ents.FindByName and ents.FindByName("lc_thumper*") or {}) do
        local _, part = A.Parse(NameOf(e))
        if IsValid(e) and part == "head" then out[#out + 1] = e end
    end
    return out
end

-- A part of the same copy as ent (a thumper, or any part of it): the one of that number nearest to it, within reach.
function A.PartOf(ent, part)
    if not IsValid(ent) then return nil end
    local n = A.Parse(NameOf(ent))
    if not n then return nil end
    local best, bd
    for _, t in ipairs(ents.FindByName and ents.FindByName("lc_thumper" .. n .. "_" .. part) or {}) do
        if IsValid(t) then
            local d = t:GetPos():DistToSqr(ent:GetPos())
            if d <= REACH * REACH and (not bd or d < bd) then best, bd = t, d end
        end
    end
    return best
end

function A.BurrowOf(thumper) return A.PartOf(thumper, "burrow") end

-- The map tells its thumper to stop or start: remembered here.
function A.Set(thumper, running)
    if not IsValid(thumper) then return end
    local s = A.stopped[thumper]
    if running then
        if s then A.stopped[thumper] = nil A.startedAt = CurTime() end
    elseif not s then
        A.stopped[thumper] = { since = CurTime(), pool = POOL_MAX, regenAt = CurTime() + REGEN, nextAt = CurTime() + GRACE }
    end
end

hook.Add("AcceptInput", "LivingCityAntlions", function(ent, input)
    if not IsValid(ent) then return end
    local what = string.lower(input or "")
    if what ~= "enable" and what ~= "disable" then return end
    local _, part = A.Parse(NameOf(ent))
    if part ~= "head" then return end
    LC.Try(A.Set, ent, what == "enable")
end)

local function Living()
    local n = 0
    for e in pairs(A.out) do
        if IsValid(e) and e:Health() > 0 then n = n + 1 else A.out[e] = nil end
    end
    return n
end

local function SomeoneNear(pos)
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetPos():DistToSqr(pos) <= HEARD * HEARD then return true end
    end
    return false
end

function A.Spawn(pos)
    local e = ents.Create("npc_antlion")
    if not IsValid(e) then return nil end
    local a, d = math.Rand(0, math.pi * 2), math.Rand(0, 48)
    e:SetPos(pos + Vector(math.cos(a) * d, math.sin(a) * d, 4))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:SetKeyValue("startburrowed", "1")
    e:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE or 512))
    e:Spawn()
    if e.Activate then e:Activate() end
    if e.Fire then e:Fire("Unburrow", "", 0.1) end
    e.lcThumperAntlion = true
    A.out[e] = true
    return e
end

function A.Tick()
    local now = CurTime()
    local anyStopped = false
    for th, s in pairs(A.stopped) do
        if not IsValid(th) then
            A.stopped[th] = nil
        else
            anyStopped = true
            if now >= s.regenAt then
                s.regenAt = now + REGEN
                if s.pool < POOL_MAX then s.pool = s.pool + 1 end
            end
            if now >= s.nextAt and s.pool > 0 and Living() < OUT_MAX then
                local burrow = A.BurrowOf(th)
                if burrow and SomeoneNear(burrow:GetPos()) and A.Spawn(burrow:GetPos()) then
                    s.pool = s.pool - 1
                    s.nextAt = now + EVERY
                end
            end
        end
    end
    -- every thumper running again for a minute: what is left digs itself away
    if not anyStopped and A.startedAt and now - A.startedAt >= 60 then
        A.startedAt = nil
        for e in pairs(A.out) do
            if IsValid(e) and e:Health() > 0 then
                if e.Fire then e:Fire("BurrowAway", "", 0) else e:Remove() end
            end
            A.out[e] = nil
        end
    end
end

timer.Create("LivingCityAntlions", 2, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(A.Tick)
    if not ok and LC.Error then LC.Error("antlions", err) end
end)
local function Forget()
    for e in pairs(A.out) do if IsValid(e) then e:Remove() end end
    A.stopped, A.out, A.startedAt = {}, {}, nil
end
hook.Add("LivingCityStopped", "LivingCityAntlions", Forget)
hook.Add("PostCleanupMap", "LivingCityAntlions", function() A.stopped, A.out, A.startedAt = {}, {}, nil end)
