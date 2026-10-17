--[[
    Living City: the dead

    Citizens, metrocops and soldiers who die leave a body you can search:
    press E on it and stay with it for a few seconds. What you find depends on
    who they were. Citizens carry rations, water, a few credits, and now and
    then their identity papers. Metrocops carry pistol ammunition, credits, and
    sometimes their keycard or stunstick. Soldiers carry rifle ammunition,
    grenades and medical supplies.

    Searching a body in front of a unit is a crime (Civil Protection players
    can do it freely). Bodies are removed after lc_body_time seconds, or when
    there are more than lc_max_bodies of them.

    The game's own death ragdolls are hidden for these NPCs (and for birds and
    headcrabs, which leave a carcass item instead), so nothing appears twice.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_bodies", "1", FLAGS, "The dead leave bodies you can search")
local cvTime = CreateConVar("lc_body_time", "300", FLAGS, "Seconds a body stays")
local cvMax  = CreateConVar("lc_max_bodies", "16", FLAGS, "Most bodies at once (oldest go first)")

LC.Bodies = LC.Bodies or {} -- list of { ent, born }

local function Roll(p) return math.random() < p end

-- What each kind of person has on them. Rolled when they die.
local LOOT = {
    citizen = function()
        local t = { items = {}, credits = 0, ammo = {}, weapons = {} }
        if Roll(0.35) then t.items[#t.items + 1] = "ration" end
        if Roll(0.25) then t.items[#t.items + 1] = "water" end
        if Roll(0.2) then t.items[#t.items + 1] = Roll(0.5) and "bottle_empty" or "can_empty" end
        if Roll(0.12) then t.items[#t.items + 1] = "bread" end
        if Roll(0.06) then t.items[#t.items + 1] = "tablets" end
        if Roll(0.12) then t.items[#t.items + 1] = "papers_dead" end
        if Roll(0.05) then t.items[#t.items + 1] = "keepsake" end
        if Roll(0.2) then t.items[#t.items + 1] = "civvies" end -- the clothes off their back
        if Roll(0.6) then t.credits = math.random(1, 10) end
        return t
    end,
    cop = function()
        local t = { items = {}, credits = 0, ammo = {}, weapons = {} }
        t.ammo[#t.ammo + 1] = { "Pistol", math.random(12, 36) }
        if Roll(0.35) then t.items[#t.items + 1] = "cp_keycard" end
        if Roll(0.25) then t.items[#t.items + 1] = "uniform_cp" end -- mask and all
        if Roll(0.25) then t.weapons[#t.weapons + 1] = "weapon_stunstick" end
        if Roll(0.15) then t.items[#t.items + 1] = "ration" end
        if Roll(0.7) then t.credits = math.random(5, 20) end
        return t
    end,
    rebel = function()
        local t = { items = {}, credits = 0, ammo = {}, weapons = {} }
        if Roll(0.35) then t.items[#t.items + 1] = "rebel_gear" end
        if Roll(0.5) then t.ammo[#t.ammo + 1] = Roll(0.5) and { "SMG1", math.random(15, 45) } or { "Pistol", math.random(9, 24) } end
        if Roll(0.3) then t.items[#t.items + 1] = "canned_food" end
        if Roll(0.2) then t.items[#t.items + 1] = "gun_parts" end
        if Roll(0.15) then t.items[#t.items + 1] = "radio_tuned" end
        if Roll(0.4) then t.credits = math.random(1, 12) end
        return t
    end,
    soldier = function()
        local t = { items = {}, credits = 0, ammo = {}, weapons = {}, ents = {} }
        t.ammo[#t.ammo + 1] = Roll(0.6) and { "SMG1", math.random(30, 90) } or { "AR2", math.random(15, 45) }
        if Roll(0.3) then t.weapons[#t.weapons + 1] = "weapon_frag" end
        if Roll(0.35) then t.ents[#t.ents + 1] = "item_healthvial" end
        if Roll(0.2) then t.items[#t.items + 1] = "cp_keycard" end
        if Roll(0.5) then t.credits = math.random(10, 30) end
        return t
    end,
}

local function Busy(e)
    return e.lcBody and (e.lcBody.claimed or (LC.HauledBy and LC.HauledBy(e)))
end

local function Trim()
    local now = CurTime()
    for i = #LC.Bodies, 1, -1 do
        local b = LC.Bodies[i]
        if not IsValid(b.ent) then
            table.remove(LC.Bodies, i)
        elseif now - b.born > cvTime:GetFloat() and not Busy(b.ent) and not LC.IsSeen(b.ent:GetPos() + Vector(0, 0, 20)) then
            b.ent:Remove()
            table.remove(LC.Bodies, i)
        end
    end
    -- too many: the oldest go first (not one somebody is hauling, or that a shift is about)
    local i = 1
    while #LC.Bodies > cvMax:GetInt() and i <= #LC.Bodies do
        local b = LC.Bodies[i]
        if IsValid(b.ent) and Busy(b.ent) then
            i = i + 1
        else
            table.remove(LC.Bodies, i)
            if IsValid(b.ent) then b.ent:Remove() end
        end
    end
end

-- A body that lies the way the person fell, not in a T-pose.
function LC.MakeBody(npc, role)
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return nil end
    rag:SetModel(npc:GetModel())
    rag:SetPos(npc:GetPos())
    rag:SetAngles(npc:GetAngles())
    if npc.GetSkin then rag:SetSkin(npc:GetSkin()) end
    rag:Spawn()
    rag:Activate()
    local count = rag.GetPhysicsObjectCount and rag:GetPhysicsObjectCount() or 0
    local vel = npc:GetVelocity()
    for i = 0, count - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        local bone = rag:TranslatePhysBoneToBone(i)
        if IsValid(phys) and bone then
            local pos, ang = npc:GetBonePosition(bone)
            if pos then phys:SetPos(pos) end
            if ang then phys:SetAngles(ang) end
            phys:SetVelocity(vel)
        end
    end
    if rag.SetCollisionGroup then rag:SetCollisionGroup(COLLISION_GROUP_WEAPON) end -- you can walk over it
    rag.lcBody = { role = role, loot = LOOT[role] and LOOT[role]() or nil, name = npc:GetNW2String("lc_name", "") }
    if rag.lcBody.loot then hook.Run("LivingCityBodyLoot", role, rag.lcBody.loot) end
    rag:SetNW2Bool("lc_body", true)
    LC.Bodies[#LC.Bodies + 1] = { ent = rag, born = CurTime() }
    Trim()
    return rag
end

hook.Add("OnNPCKilled", "LivingCityBodies", function(npc, attacker)
    if not cvOn:GetBool() then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.test or not LOOT[st.role] or not npc:GetNW2Bool("lc_noragdoll", false) then return end
    local ok, err = pcall(LC.MakeBody, npc, st.role)
    if not ok then LC.Error("bodies", err) end
end)

-- Their guns hit the floor with them: a soldier's SMG or pulse rifle, a unit's
-- or a rebel's pistol, about half a clip left in it (what else they carried is
-- found by searching the body). A gun nobody picks up is cleared away after a
-- few minutes, out of sight, and there are never more than a dozen about.
local DROPS = { weapon_smg1 = true, weapon_ar2 = true, weapon_pistol = true, weapon_shotgun = true, weapon_357 = true, weapon_crossbow = true }
local DROP_ROLES = { soldier = true, cop = true, rebel = true }
LC.DroppedGuns = LC.DroppedGuns or {} -- list of { ent, at }
local cvDrops = CreateConVar("lc_gun_drops", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Soldiers, armed Civil Protection units and rebels drop their guns when they die (about half a clip in them)")

function LC.DropNPCGun(npc)
    local wep = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if not IsValid(wep) then return nil end
    local cls = wep:GetClass()
    if not DROPS[cls] then return nil end
    local g = ents.Create(cls)
    if not IsValid(g) then return nil end
    local pos = wep:GetPos()
    if not pos or pos:DistToSqr(npc:GetPos()) > 200 * 200 then pos = npc:WorldSpaceCenter() end
    g:SetPos(pos + Vector(0, 0, 6))
    g:SetAngles(wep:GetAngles() or npc:GetAngles())
    g:Spawn()
    g:Activate()
    local max = g.GetMaxClip1 and g:GetMaxClip1() or -1
    if max and max > 0 and g.SetClip1 then g:SetClip1(math.max(1, math.floor(max * 0.5 + math.Rand(-0.15, 0.1) * max))) end
    local phys = g.GetPhysicsObject and g:GetPhysicsObject()
    if IsValid(phys) then phys:SetVelocity(npc:GetForward() * math.Rand(30, 80) + Vector(0, 0, 60)) end
    g.lcDropped = true
    table.insert(LC.DroppedGuns, { ent = g, at = CurTime() })
    -- never more than a dozen lying about: the oldest goes
    while #LC.DroppedGuns > 12 do
        local old = table.remove(LC.DroppedGuns, 1)
        if IsValid(old.ent) and not IsValid(old.ent:GetOwner()) then old.ent:Remove() end
    end
    return g
end

hook.Add("OnNPCKilled", "LivingCityGunDrops", function(npc)
    if not cvDrops:GetBool() then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.test or not DROP_ROLES[st.role] then return end
    local ok, err = pcall(LC.DropNPCGun, npc)
    if not ok and LC.Error then LC.Error("gun drops", err) end
end)

timer.Create("LivingCityGunDrops", 15, 0, function()
    local now = CurTime()
    for i = #LC.DroppedGuns, 1, -1 do
        local d = LC.DroppedGuns[i]
        if not IsValid(d.ent) or IsValid(d.ent:GetOwner()) then
            table.remove(LC.DroppedGuns, i) -- (picked up)
        elseif now - d.at > 240 and not (LC.IsSeen and LC.IsSeen(d.ent:GetPos())) then
            d.ent:Remove()
            table.remove(LC.DroppedGuns, i)
        end
    end
end)

-- The engine's own server ragdoll (if ai_serverragdolls is on) for anyone we
-- already made a body or a carcass for.
local CARCASS_CLASSES = {
    npc_pigeon = true, npc_crow = true, npc_seagull = true,
    npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true,
}
hook.Add("CreateEntityRagdoll", "LivingCityBodies", function(owner, rag)
    if not IsValid(owner) or not IsValid(rag) then return end
    if owner:GetNW2Bool("lc_noragdoll", false) or CARCASS_CLASSES[owner:GetClass()] then rag:Remove() end
end)

-- A body for a job (a mortuary collection with no real one about): a citizen nobody has claimed.
function LC.SpawnBody(model, pos, role)
    role = role or "citizen"
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return nil end
    rag:SetModel(model)
    rag:SetPos(pos + Vector(0, 0, 12))
    rag:SetAngles(Angle(0, math.random(0, 359), 0))
    rag:Spawn()
    rag:Activate()
    if rag.SetCollisionGroup then rag:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
    rag.lcBody = { role = role, loot = LOOT[role] and LOOT[role]() or nil, name = "" }
    rag:SetNW2Bool("lc_body", true)
    LC.Bodies[#LC.Bodies + 1] = { ent = rag, born = CurTime() }
    return rag
end

-- The infested rise again: the body gets up as a zombie (sv_livingcity_factions.lua).
function LC.TakeBodyAt(pos)
    for i, b in ipairs(LC.Bodies) do
        if IsValid(b.ent) and not Busy(b.ent) and b.ent:GetPos():DistToSqr(pos) < 96 * 96 then
            b.ent:Remove()
            table.remove(LC.Bodies, i)
            return true
        end
    end
    return false
end

------------------------------------------------------------------------
-- Searching
------------------------------------------------------------------------

local searching = {} -- [ply] = { body, untilT }

local function TakeLoot(ply, body)
    local loot = body.lcBody.loot
    body.lcBody.searched = true
    if not loot then return ply:ChatPrint("Nothing on them.") end
    local found, left = {}, false
    for i = #loot.items, 1, -1 do
        local id = loot.items[i]
        if LC.GiveItem(ply, id, 1) then
            found[#found + 1] = LCS.Items[id] and LCS.Items[id].name or id
            table.remove(loot.items, i)
        else
            left = true
        end
    end
    for _, a in ipairs(loot.ammo) do
        ply:GiveAmmo(a[2], a[1])
        found[#found + 1] = string.format("%d %s rounds", a[2], string.lower(a[1]))
    end
    loot.ammo = {}
    for _, w in ipairs(loot.weapons) do
        ply:Give(w)
        found[#found + 1] = (w == "weapon_stunstick" and "a stunstick") or (w == "weapon_frag" and "a grenade") or w
    end
    loot.weapons = {}
    for _, cls in ipairs(loot.ents or {}) do
        local e = ents.Create(cls)
        if IsValid(e) then
            e:SetPos(body:GetPos() + Vector(0, 0, 20))
            e:Spawn()
            found[#found + 1] = cls == "item_healthvial" and "a health vial" or cls
        end
    end
    loot.ents = {}
    if loot.credits > 0 then
        if LC.AddCredits then LC.AddCredits(ply, loot.credits) end
        found[#found + 1] = loot.credits .. " credits"
        loot.credits = 0
    end
    if #found == 0 then
        ply:ChatPrint(left and "Your pockets are full." or "Nothing left on them.")
    else
        ply:ChatPrint("You search the body: " .. table.concat(found, ", ") .. "." .. (left and " Your pockets are full; there's more." or ""))
    end
    if left then body.lcBody.searched = false end
    hook.Run("LivingCityBodySearched", ply, body, found)
end

function LC.StartBodySearch(ply, body)
    if not IsValid(body) or not body.lcBody or searching[ply] then return false end
    if body.lcBody.searched then return false, "You've already been through their pockets." end
    if not ply:Alive() or (LC.InCustody and LC.InCustody(ply)) then return false end
    searching[ply] = { body = body, untilT = CurTime() + 3 }
    ply:SetNW2String("lcu_progress", "Searching the body...")
    ply:SetNW2Float("lcu_pick_start", CurTime())
    ply:SetNW2Float("lcu_pick_until", CurTime() + 3)
    ply:ChatPrint("You go through their pockets...")
    -- doing this in front of a unit is a crime (unless you are one)
    if not LC.PlayerIsCP(ply) and LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        LC.ReportCrime(ply, body.lcBody.role == "citizen" and "Robbing the dead" or "Looting a dead officer",
            body.lcBody.role == "citizen" and 120 or 300)
    end
    return true
end

timer.Create("LivingCityBodySearch", 0.25, 0, function()
    local now = CurTime()
    for ply, s in pairs(searching) do
        if not IsValid(ply) or not ply:Alive() or not IsValid(s.body) or ply:GetPos():DistToSqr(s.body:GetPos()) > 140 * 140 then
            searching[ply] = nil
            if IsValid(ply) then ply:SetNW2Float("lcu_pick_until", 0) end
        elseif now >= s.untilT then
            searching[ply] = nil
            ply:SetNW2Float("lcu_pick_until", 0)
            TakeLoot(ply, s.body)
        end
    end
end)

hook.Add("PlayerUse", "LivingCityBodies", function(ply, ent)
    if not IsValid(ent) or not ent.lcBody then return end
    if (ply.lcNextBodyUse or 0) > CurTime() then return false end
    ply.lcNextBodyUse = CurTime() + 1
    if hook.Run("LivingCityBodyUse", ply, ent) then return false end -- a Mortician hauls it instead
    local ok, why = LC.StartBodySearch(ply, ent)
    if not ok and why then ply:ChatPrint(why) end
    return false
end)

timer.Create("LivingCityBodyTrim", 10, 0, function() Trim() end)
