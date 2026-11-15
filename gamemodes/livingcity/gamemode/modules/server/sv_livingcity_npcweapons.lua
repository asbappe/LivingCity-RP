--[[
    Living City: citizens and the weapons lying about, and no weapon in custody
    (the owner, 14 November: "citizens are walking over weapons they find on the street and then auto
    equipping them and walking around with them displayed ... I would expect unless a citizen is a
    sympathizer, they would leave a weapon alone, or at the very least pick it up, hide it, and either
    give it to someone they trust or sell it on the black market"; and "a prisoner held in the cells
    ... is holding a pulse rifle").

      Ordinary citizens   never pick a weapon up. Half-Life 2's citizens do it by themselves (they are
                          the player's companions there), so every citizen who is not one of the
                          Resistance's fighters is told not to (the engine's DisableWeaponPickup), and
                          one found with a weapon in hand all the same puts it back down.
      Sympathizers        one who passes a weapon lying loose, with no unit near, takes it and hides it:
                          nothing shows in their hands. It stays with that person (a named citizen who
                          goes home and comes back still has it). When they are free they carry it to
                          the nearest Resistance supply crate (two supplies for the stores), or with no
                          rebel ground on the map to a black market dealer. A unit who searches them
                          first finds it.
      Custody             nobody cuffed, walked to the cells or held in one has a weapon: it is taken
                          when they are arrested, checked again when they reach the cell, and every
                          couple of seconds after.

    No setting, no command, nothing new on anyone's screen.
]]

if CLIENT then return end

LC = LC or {}

local NEAR_GUN   = 90   -- how close a sympathizer passes to take one
local UNIT_NEAR  = 500  -- a unit this close: they leave it where it is
local CARRY_WAIT = 45   -- seconds between tries to pass it on
local STORES_FOR_A_GUN = 2

LC.HiddenGuns = LC.HiddenGuns or { taken = 0, passed = 0, sold = 0, found = 0, dropped = 0, custody = 0 }
local N = LC.HiddenGuns

local function Custody(npc, st)
    return st.state == "jailed" or (LC.NPCCustody and LC.NPCCustody[npc] ~= nil)
end

-- Every weapon an NPC has: gone. Returns the class of the first one taken (nil: they had none).
function LC.StripNPCWeapons(npc)
    if not IsValid(npc) then return nil end
    local took
    local seen = {}
    local list = npc.GetWeapons and npc:GetWeapons() or {}
    local active = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if active then list[#list + 1] = active end
    for _, w in ipairs(list) do
        if IsValid(w) and not seen[w] then
            seen[w] = true
            took = took or (w.GetClass and w:GetClass()) or "weapon"
            if w.Remove then w:Remove() end
        end
    end
    return took
end

-- The engine's own picking up, off (or back on for a fighter let out again).
function LC.NPCWeaponPickup(npc, allow)
    if not IsValid(npc) or not npc.Fire or npc:GetClass() ~= "npc_citizen" then return end
    npc:Fire(allow and "EnableWeaponPickup" or "DisableWeaponPickup")
    npc.lcNoPickup = not allow
end

-- What a hidden weapon is kept on: the person (so it is theirs when they come back), and their body now.
local function Hidden(npc, st)
    local p = IsValid(npc) and npc.lcProfile
    if p and p.hidGun and not st.hidGun then st.hidGun = p.hidGun end
    return st.hidGun
end
local function SetHidden(npc, st, cls)
    st.hidGun = cls
    local p = IsValid(npc) and npc.lcProfile
    if p then p.hidGun = cls end
end
LC.NPCHiddenGun = Hidden

-- Taken into custody: no weapon in the hands, none hidden either (it is found on them).
function LC.NoWeaponsInCustody(npc, st)
    if not IsValid(npc) or not st then return false end
    local had = false
    if st.role == "rebel" and LC.DisarmPrisoner then LC.DisarmPrisoner(npc, st) end -- (theirs is remembered for when they're freed)
    if LC.StripNPCWeapons(npc) then had = true end
    if Hidden(npc, st) then SetHidden(npc, st, nil) had = true end
    if not npc.lcNoPickup then LC.NPCWeaponPickup(npc, false) end
    if had then N.custody = N.custody + 1 end
    return had
end

-- A unit's search finds it (sv_livingcity_underground.lua, LC.SearchNPCFound).
function LC.HiddenGunFound(npc, st)
    if not st or not Hidden(npc, st) then return false end
    SetHidden(npc, st, nil)
    N.found = N.found + 1
    return true
end

local function UnitNear(pos)
    local r2 = UNIT_NEAR * UNIT_NEAR
    for npc, st in pairs(LC.NPCs or {}) do
        if (st.role == "cop" or st.role == "soldier") and IsValid(npc) and npc:Health() > 0 and npc:GetPos():DistToSqr(pos) < r2 then return true end
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(ply) and ply:GetPos():DistToSqr(pos) < r2 then return true end
    end
    return false
end

-- Weapons nobody holds, lying where they fell.
function LC.LooseWeapons()
    local out = {}
    for _, w in ipairs(ents.FindByClass("weapon_*")) do
        if IsValid(w) and not IsValid(w.GetOwner and w:GetOwner()) and not IsValid(w.GetParent and w:GetParent())
            and not (w.CreatedByMap and w:CreatedByMap()) then
            out[#out + 1] = w
        end
    end
    return out
end

local FREE = { idle = true, moving = true }
local function Sympathizer(npc, st)
    return st.role == "citizen" and st.rebel and FREE[st.state] and not st.test and not st.leaving and not st.questLock
        and IsValid(npc) and npc:Health() > 0
end

-- A sympathizer passing a loose weapon takes it and hides it.
function LC.HideLooseWeapon(npc, st, w)
    if not IsValid(w) or Hidden(npc, st) then return false end
    local cls = w.GetClass and w:GetClass() or "weapon"
    if w.Remove then w:Remove() end
    SetHidden(npc, st, cls)
    N.taken = N.taken + 1
    if LC.PlayGesture then LC.PlayGesture(npc, { "ACT_PICKUP_GROUND", "pickup", "ACT_GMOD_GESTURE_ITEM_PLACE" }, 1.5) end
    if LC.Log then LC.Log("info", string.format("%s (a sympathizer) took a %s lying loose and hid it", (npc.lcProfile and npc.lcProfile.name) or "A citizen", cls)) end
    hook.Run("LivingCityHiddenGun", npc, cls, "taken")
    return true
end

-- Where it goes: the nearest Resistance supply crate, or with none a black market dealer.
local function PassTarget(pos)
    local best, bd
    for _, rp in pairs(LC.RebelProps or {}) do
        if IsValid(rp.cache) then
            local d = rp.cache:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = rp.cache, d end
        end
    end
    if best then return best, "stores" end
    for _, e in ipairs(ents.FindByClass("lc_dealer")) do
        if IsValid(e) then
            local d = e:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best, best and "dealer" or nil
end

function LC.HiddenGunDelivered(npc, st, target, how)
    local cls = Hidden(npc, st)
    if not cls then return false end
    SetHidden(npc, st, nil)
    if how == "stores" then
        if LC.AddToCache then LC.AddToCache(target, STORES_FOR_A_GUN) end
        N.passed = N.passed + 1
    else
        N.sold = N.sold + 1
    end
    if LC.Log then
        LC.Log("info", string.format("%s passed a hidden %s %s", (npc.lcProfile and npc.lcProfile.name) or "A citizen", cls,
            how == "stores" and "to the Resistance's stores" or "to a black market dealer"))
    end
    hook.Run("LivingCityHiddenGun", npc, cls, how)
    return true
end

local function Carry(npc, st, now)
    if now < (st.gunNext or 0) or st.mindErrand or not LC.MindsErrand or not (LC.MindsFree and LC.MindsFree(st)) then return false end
    st.gunNext = now + CARRY_WAIT
    local target, how = PassTarget(npc:GetPos())
    if not target then return false end
    return LC.MindsErrand(npc, st, target, function(n, s, t) LC.HiddenGunDelivered(n, s, t, how) end) and true or false
end

local looseAt = 0
function LC.NPCWeaponsTick(now)
    now = now or CurTime()
    local loose
    if now >= looseAt then
        looseAt = now + 4
        loose = LC.LooseWeapons()
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and not st.test then
            if Custody(npc, st) then
                LC.NoWeaponsInCustody(npc, st)
                st.wasHeld = true
            elseif st.wasHeld then
                -- out again: a fighter may pick one up as before
                st.wasHeld = nil
                if st.role == "rebel" then LC.NPCWeaponPickup(npc, true) end
            elseif st.role == "citizen" then
                local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
                if IsValid(w) then
                    -- in their hands all the same: a sympathizer hides it, anyone else puts it back down
                    if st.rebel and not Hidden(npc, st) and not UnitNear(npc:GetPos()) then
                        LC.HideLooseWeapon(npc, st, w)
                    else
                        if npc.DropWeapon then npc:DropWeapon(w) elseif w.Remove then w:Remove() end
                        N.dropped = N.dropped + 1
                    end
                    if not npc.lcNoPickup then LC.NPCWeaponPickup(npc, false) end
                elseif Hidden(npc, st) then
                    Carry(npc, st, now)
                elseif loose and #loose > 0 and Sympathizer(npc, st) then
                    local pos = npc:GetPos()
                    for i, lw in ipairs(loose) do
                        if IsValid(lw) and lw:GetPos():DistToSqr(pos) < NEAR_GUN * NEAR_GUN and not UnitNear(lw:GetPos()) then
                            if LC.HideLooseWeapon(npc, st, lw) then table.remove(loose, i) end
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Told not to pick weapons up, a moment after they appear (their role is known by then).
hook.Add("OnEntityCreated", "LivingCityNPCWeapons", function(e)
    if not IsValid(e) or e:GetClass() ~= "npc_citizen" then return end
    timer.Simple(0.2, function()
        if not IsValid(e) then return end
        local st = LC.NPCs and LC.NPCs[e]
        if st and st.role == "rebel" then return end -- (the Resistance's fighters arm themselves as they always did)
        LC.NPCWeaponPickup(e, false)
    end)
end)

timer.Create("LivingCityNPCWeapons", 2, 0, function()
    if not LC.Running then return end
    local ok, err = LC.Try(LC.NPCWeaponsTick, CurTime())
    if not ok and LC.Error then LC.Error("npc weapons", err) end
end)

-- For the debug report.
function LC.NPCWeaponsSummary()
    return string.format("weapons and citizens: %d hidden by sympathizers (%d passed to the Resistance's stores, %d to a dealer, %d found in a search), %d put back down, %d taken in custody",
        N.taken, N.passed, N.sold, N.found, N.dropped, N.custody)
end
