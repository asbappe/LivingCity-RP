--[[
    Living City: field operations (the owner's 7 November playtest)

      Backup that comes armed    Call for backup with a gun in your hand, shot at in the last
                                 30 seconds, or on a violent job, and the units come with
                                 pistols and SMGs, and keep them out while they're with you
                                 (LC.BackupViolent, LC.ArmBackupUnit; the call is LC.CallBackup).
      A squad for violent jobs   Take a violent job (a raid, a sweep, an ambush) and
                                 lc_quest_allies (2) of your own side go with you: units with
                                 guns for Civil Protection, soldiers for the Overwatch, fighters
                                 for the Resistance. They follow you and fight what you fight
                                 until the job ends. Free ones nearby first; else they're
                                 brought in out of sight.
      Flashbangs blind           Everyone in sight of the bang (or right beside it) is blinded
                                 for 4 to 9 seconds each: hands to their eyes, stumbling about,
                                 not shooting (LC.FlashStun).
      Rebel ground               Ground a team is clearing gets no new rebels while they're at
                                 it (LC.QuietRebels); who's still standing on it
                                 (LC.RebelsOnGround); and the counterattack while they hold
                                 it (LC.RebelWave). The job is "Retake the block"
                                 (sv_livingcity_quests.lua).
      6-12, what's left of him   The zombine in the Missing Unit story (sv_livingcity_stories.lua).
      Who hid the contraband     The contraband sweep's trail: the last stash points to a
                                 suspect; ask around, find them, bring them in.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSquad = CreateConVar("lc_quest_allies", "2", FLAGS, "Friendly NPCs of your own side who go with you on a violent job and fight beside you (0: none)")

local UP = Vector(0, 0, 50)
local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Backup that comes armed
------------------------------------------------------------------------

-- Shot at (by anyone, person or NPC) in the last 30 seconds.
hook.Add("EntityTakeDamage", "LivingCityShotAt", function(victim, dmg)
    if not IsValid(victim) or not victim:IsPlayer() or dmg:GetDamage() <= 0 then return end
    local a = dmg:GetAttacker()
    if IsValid(a) and a ~= victim and (a:IsPlayer() or a:IsNPC()) then victim.lcShotAt = CurTime() end
end)

-- A call for backup is a call to a gunfight: a gun in your hand, shot at in the last 30 seconds,
-- or a violent job under way.
function LC.BackupViolent(ply)
    if not IsValid(ply) then return false end
    if LC.GunInHand and LC.GunInHand(ply) then return true end
    -- (a gun put away for the radio in the last 20 seconds: the call goes out on the radio now, so the hand holds that;
    -- sv_livingcity_radiohq.lua)
    if (ply.lcGunOutAt or -1e9) > CurTime() - 20 then return true end
    if (ply.lcShotAt or -1e9) > CurTime() - 30 then return true end
    local q = LC.QuestOf and LC.QuestOf[ply]
    return q ~= nil and not q.done and q.violent == true
end

-- Arm one unit answering a call. violent: pistols and SMGs, half and half (the first an SMG);
-- else a pistol, now and then an SMG, as before. Soldiers carry their own rifles.
function LC.ArmBackupUnit(npc, st, violent, i)
    if not IsValid(npc) or st.role ~= "cop" then return end
    local gun
    if violent then
        gun = ((i or 1) % 2 == 1) and "weapon_smg1" or "weapon_pistol"
    else
        gun = math.random() < 0.7 and "weapon_pistol" or "weapon_smg1"
    end
    st.armed = true
    st.backupGun = gun
    if gun == "weapon_pistol" and LC.DrawPistol then
        LC.DrawPistol(npc, st)
    else
        st.gunsGiven = st.gunsGiven or {}
        if not st.gunsGiven[gun] then
            st.gunsGiven[gun] = true
            npc:Give(gun)
        end
        if npc.SelectWeapon then npc:SelectWeapon(gun) end
    end
end

-- While they're with you, the gun stays in their hand (calming down after a fight, or
-- Half-Life 2's own weapon choice, put the stick back in it: that's how they turned up with stunsticks).
local function KeepGunsOut()
    for npc, st in pairs(LC.NPCs or {}) do
        if st.backupGun and IsValid(npc) then
            if st.backupFor == nil then
                st.backupGun = nil
            elseif not st.arrestOnly and npc:Health() > 0 then
                local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
                if not IsValid(w) or w:GetClass() ~= st.backupGun then
                    st.armed = true
                    if npc.SelectWeapon then npc:SelectWeapon(st.backupGun) end
                end
            end
        end
    end
end
LC.KeepBackupGunsOut = KeepGunsOut

------------------------------------------------------------------------
-- Flashbangs blind
------------------------------------------------------------------------

-- Hands to the eyes (a citizen's reaction to a scanner's flash), else a flinch.
local BLIND_ANIMS = { "photo_react_blind", "photo_react_startle", "Fear_Reaction" }
local NO_FIRE = bit.bor(CAP_WEAPON_RANGE_ATTACK1 or 0, CAP_WEAPON_RANGE_ATTACK2 or 0, CAP_INNATE_RANGE_ATTACK1 or 0,
    CAP_INNATE_RANGE_ATTACK2 or 0, CAP_WEAPON_MELEE_ATTACK1 or 0, CAP_INNATE_MELEE_ATTACK1 or 0, CAP_MOVE_SHOOT or 0)

-- Blind, they haven't a gun to fire (the owner, 11 November, the second time: two flashbangs "right into
-- them, and they never moved nor stopped shooting me"). Taking away what they may do and whom they see
-- wasn't enough in the real game: they still hate whoever they were shooting at, see them again a tenth of
-- a second later and fire. So the weapons themselves are taken out of their hands for as long as they are
-- blind (fumbled, as far as anyone can tell) and put back after.
local function Disarm(npc, st)
    if st.flashWeapons or not npc.GetWeapons then return end
    local active = npc.GetActiveWeapon and npc:GetActiveWeapon()
    local list = {}
    for _, w in ipairs(npc:GetWeapons() or {}) do
        if IsValid(w) then
            list[#list + 1] = { cls = w:GetClass(), active = w == active }
            w:Remove()
        end
    end
    st.flashWeapons = list
end
local function Rearm(npc, st)
    local list = st.flashWeapons
    st.flashWeapons = nil
    if not list or not IsValid(npc) or npc:Health() <= 0 or not npc.Give then return end
    local back
    for _, w in ipairs(list) do
        npc:Give(w.cls)
        if w.active then back = w.cls end
    end
    if back and npc.SelectWeapon then npc:SelectWeapon(back) end
end
LC.FlashDisarm, LC.FlashRearm = Disarm, Rearm
local PAIN = {
    cop = { "npc/metropolice/pain1.wav", "npc/metropolice/pain2.wav", "npc/metropolice/pain3.wav" },
    soldier = { "npc/combine_soldier/pain1.wav", "npc/combine_soldier/pain2.wav", "npc/combine_soldier/pain3.wav" },
}

local function CancelAnim(npc)
    if IsValid(npc.lcGesture) then
        npc.lcGesture:Fire("CancelSequence")
        npc.lcGesture:Remove()
        npc.lcGesture = nil
    end
end

-- One beat of being blind: standing pressing their eyes, or a few stumbling steps. Either way the left hand is over
-- their eyes the whole time (the owner, 13 November: "cover their eyes with their hand (preferably left hand, since
-- their right is holding their weapon) and stumble about"; drawn by cl_livingcity_gasmask.lua). It used to be
-- Half-Life 2's two-handed flinch (BLIND_ANIMS), which hid the hand on the face; only when that pose is off
-- (lc_flash_hand 0) is it still played.
local cvFlashHand = CreateConVar("lc_flash_hand", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "A flashbanged NPC covers their eyes with their left hand (0: Half-Life 2's two-handed flinch instead)")
local function FlashStep(npc, st, now)
    st.flashPhase = st.flashPhase == "rub" and "stumble" or "rub"
    if st.flashPhase == "rub" then
        if cvFlashHand:GetBool() then
            CancelAnim(npc)
            npc:SetSchedule(SCHED_IDLE_STAND)
            st.flashNext = now + math.Rand(1.2, 2.0)
            return
        elseif LC.PlayGesture and LC.PlayGesture(npc, BLIND_ANIMS, 2.5) then
            st.flashNext = now + math.Rand(1.6, 2.6)
            return
        end
    end
    st.flashPhase = "stumble"
    CancelAnim(npc)
    local a = math.rad(math.random(0, 359))
    npc:SetLastPosition(npc:GetPos() + Vector(math.cos(a), math.sin(a), 0) * math.random(40, 90))
    npc:SetSchedule(SCHED_FORCED_GO)
    if npc.AddGesture and ACT_GESTURE_FLINCH_HEAD then npc:AddGesture(ACT_GESTURE_FLINCH_HEAD) end
    st.flashNext = now + math.Rand(1.0, 1.8)
end

function LC.FlashStun(npc, st, secs)
    if not IsValid(npc) or not st then return end
    local now = CurTime()
    st.stunnedUntil = math.max(st.stunnedUntil or 0, now + (secs or 4))
    if not st.flashBlind then
        st.flashBlind = true
        if npc.CapabilitiesGet and npc.CapabilitiesRemove and not st.flashCaps then
            st.flashCaps = npc:CapabilitiesGet()
            npc:CapabilitiesRemove(NO_FIRE)
        end
        local snd = PAIN[st.role] and Pick(PAIN[st.role])
            or ("vo/npc/" .. (st.gender or "male") .. "01/" .. Pick({ "ow01", "ow02", "pain01", "pain02" }) .. ".wav")
        npc:EmitSound(snd, 75)
        Disarm(npc, st)
    end
    npc:SetEnemy(NULL)
    if npc.ClearEnemyMemory then npc:ClearEnemyMemory() end
    if cvFlashHand:GetBool() and LC.HandToFace then LC.HandToFace(npc, "eyes", st.stunnedUntil - now) end
    st.flashPhase = nil
    FlashStep(npc, st, now)
end

local function FlashEnd(npc, st)
    st.flashBlind, st.flashPhase, st.flashNext = nil, nil, nil
    if st.flashCaps and npc.CapabilitiesClear and npc.CapabilitiesAdd then
        npc:CapabilitiesClear()
        npc:CapabilitiesAdd(st.flashCaps)
    end
    st.flashCaps = nil
    Rearm(npc, st)
    CancelAnim(npc)
    if LC.HandFromFace then LC.HandFromFace(npc) end
    if npc:Health() > 0 then npc:SetSchedule(SCHED_IDLE_STAND) end
end

function LC.FlashTick(now)
    for npc, st in pairs(LC.NPCs or {}) do
        if st.flashBlind and IsValid(npc) then
            if now >= (st.stunnedUntil or 0) or npc:Health() <= 0 then
                FlashEnd(npc, st)
            else
                -- blind: nobody to aim at, whatever the engine thinks it saw
                npc:SetEnemy(NULL)
                if npc.ClearEnemyMemory then npc:ClearEnemyMemory() end
                if now >= (st.flashNext or 0) then FlashStep(npc, st, now) end
            end
        end
    end
end
timer.Create("LivingCityFlashStun", 0.25, 0, function()
    local ok, err = LC.Try(LC.FlashTick, CurTime())
    if not ok and LC.Error then LC.Error("flash stun", err) end
end)

------------------------------------------------------------------------
-- Rebel ground: no new arrivals while it's being cleared, who's left, the counterattack
------------------------------------------------------------------------

LC.RebelQuiet = LC.RebelQuiet or {}
function LC.QuietRebels(pos, r, secs)
    local q = { pos = pos, r = r, untilT = CurTime() + (secs or 600) }
    table.insert(LC.RebelQuiet, q)
    return q
end
-- Inside ground being cleared (margin: how big the thing asking is, say a zone's radius)?
function LC.RebelQuietAt(pos, margin)
    local now = CurTime()
    for i = #LC.RebelQuiet, 1, -1 do
        local q = LC.RebelQuiet[i]
        if now > q.untilT then
            table.remove(LC.RebelQuiet, i)
        elseif pos:DistToSqr(q.pos) < (q.r + (margin or 0)) ^ 2 then
            return true
        end
    end
    return false
end

-- Does rebel zone z reach into ground being cleared? A zone you placed: the circle round it, as
-- always; grown ground: any of its cells.
function LC.RebelQuietZone(z)
    if not z.cells then return LC.RebelQuietAt(z.pos, z.r) end
    local now = CurTime()
    for _, q in ipairs(LC.RebelQuiet) do
        if now <= q.untilT and LCZ.Contains(z, q.pos, q.r) then return true end
    end
    return false
end

-- Every rebel fighter still standing within r of center.
function LC.RebelsOnGround(center, r)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if st.role == "rebel" and not st.test and IsValid(npc) and npc:Health() > 0 then
            local p = npc:GetPos()
            local dx, dy = p.x - center.x, p.y - center.y
            if dx * dx + dy * dy < r * r and math.abs(p.z - center.z) < 300 then out[#out + 1] = npc end
        end
    end
    return out
end

-- A wave of n fighters, out of sight (rebel ground nearby first, else the streets around),
-- coming at center and whoever of targets is nearest. Returns how many came.
function LC.RebelWave(center, targets, n)
    if not LC.SpawnRebel or not LC.Running or (n or 0) <= 0 then return 0 end
    local now = CurTime()
    local spots = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        local d = z.pos:Distance(center)
        -- (grown ground: any of its cells within reach; each spot is still kept 500 away below)
        if z.cells and LCZ.Near(z, center, 3500) or not z.cells and d > 500 and d < 3500 then
            for _ = 1, 3 do
                local p = LC.SpotInZone(z)
                if p and p:Distance(center) > 500 and not LC.IsSeen(p + UP) then spots[#spots + 1] = { p, z } end
            end
        end
    end
    for _ = 1, 3 do
        if #spots >= n then break end
        local p = LC.AlarmSquadSpot and LC.AlarmSquadSpot(center)
        if p then spots[#spots + 1] = { p, nil } end
    end
    if #spots == 0 then return 0 end
    local made = 0
    for i = 1, n do
        local s = spots[(i - 1) % #spots + 1]
        local npc, st = LC.SpawnRebel(s[1] + Vector(math.random(-40, 40), math.random(-40, 40), 4), s[2])
        if IsValid(npc) and st then
            st.unmanaged = true
            st.expires = now + 300
            st.wave = true
            st.raid = { target = center + Vector(math.random(-120, 120), math.random(-120, 120), 0), ends = now + 180, sk = {} }
            local best, bd
            for _, p in ipairs(targets or {}) do
                if IsValid(p) and p:Alive() then
                    local d = p:GetPos():DistToSqr(npc:GetPos())
                    if not bd or d < bd then best, bd = p, d end
                end
            end
            if best and LC.RebelSetFoe then LC.RebelSetFoe(npc, st, best, now) end
            made = made + 1
        end
    end
    LC.Log("info", string.format("Rebel counterattack: %d fighters toward %s", made, tostring(center)))
    return made
end

------------------------------------------------------------------------
-- A squad for violent jobs
------------------------------------------------------------------------

-- Jobs that bring their own fighters already (the sweep team meets you; the raid is ours).
local NO_SQUAD = { cp_joinsweep = true, res_backupraid = true }
local SQUAD_ROLE = { cp = "cop", ota = "soldier", resistance = "rebel" }
LC.QuestSquads = LC.QuestSquads or setmetatable({}, { __mode = "k" }) -- [q] = { role, want, nextTop }

local BUSY_STATES = { hostile = true, escort = true, event = true, escorted = true, jailed = true, fighting = true }

local function Free(npc, st, role)
    if not IsValid(npc) or npc:Health() <= 0 or st.role ~= role or st.test or st.questLock or st.questSquad then return false end
    if BUSY_STATES[st.state] then return false end
    if role == "rebel" then
        return not (st.follow or st.raid or st.quartermaster or st.post or st.foe or st.skirmish or st.wave)
    end
    return not (st.raid or st.skirmish or st.backupFor or st.workEscort or st.marching or st.escortee or st.subject or st.guardZone or st.holdPos)
end

local function SquadOf(q)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if st.questSquad == q and IsValid(npc) and npc:Health() > 0 then out[#out + 1] = npc end
    end
    return out
end
LC.QuestSquadOf = SquadOf

local function JoinSecurity(npc, st, ply, q, i, now)
    if LC.AbandonTask then LC.AbandonTask(npc, st, now) end
    LC.ArmBackupUnit(npc, st, true, i)
    st.questSquad = q
    -- (the backup squad's own following and fighting: sv_livingcity_war.lua, BackupTick)
    st.backupFor, st.backupUntil, st.backupJoined = ply, now + 60, true
    if npc.SetSquad then npc:SetSquad("lcbk" .. ply:EntIndex()) end
    LC.GoTo(npc, st, ply:GetPos() + Vector(math.random(-90, 90), math.random(-90, 90), 0), true, nil)
end

local function JoinRebel(npc, st, ply, q, now)
    if st.life and LC.RebelLifeEnd then LC.RebelLifeEnd(npc, st) end
    if st.errand and LC.RebelErrandEnd then LC.RebelErrandEnd(npc, st) end
    local taken = {}
    for _, f in ipairs(LC.FollowersOf and LC.FollowersOf(ply) or {}) do
        local fst = LC.NPCs[f]
        if fst and fst.followSlot then taken[fst.followSlot] = true end
    end
    local slot = 0
    while taken[slot] do slot = slot + 1 end
    st.follow, st.followSlot, st.followSID, st.followAt = ply, slot, ply:SteamID(), now
    st.unmanaged = true
    st.returning, st.expires, st.raid, st.errand = nil, nil, nil, nil
    st.questSquad = q
end

-- Bring the squad up to strength: free ones within reach first, else brought in out of sight.
local function TopUp(q, now)
    local s = LC.QuestSquads[q]
    local ply = q.owner
    if not s or not IsValid(ply) or not ply:Alive() then return 0 end
    local have = #SquadOf(q)
    local need = s.want - have
    if need <= 0 then return 0 end
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if Free(npc, st, s.role) then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < 3000 * 3000 then cands[#cands + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    local added = 0
    local function Take(npc, st)
        added = added + 1
        if s.role == "rebel" then JoinRebel(npc, st, ply, q, now) else JoinSecurity(npc, st, ply, q, have + added, now) end
    end
    for _, c in ipairs(cands) do
        if added >= need then break end
        Take(c.npc, c.st)
    end
    if added < need then
        local spot = LC.AlarmSquadSpot and LC.AlarmSquadSpot(ply:GetPos())
        if spot then
            for i = added + 1, need do
                local p = spot + Vector(math.cos(i) * 40, math.sin(i) * 40, 4)
                local npc, st
                if s.role == "cop" and LC.SpawnCop then npc, st = LC.SpawnCop(p)
                elseif s.role == "soldier" and LC.SpawnSoldier then npc, st = LC.SpawnSoldier(p)
                elseif s.role == "rebel" and LC.SpawnRebel then npc, st = LC.SpawnRebel(p, nil) end
                if IsValid(npc) and st then
                    st.unmanaged = true -- (on top of the city's own numbers)
                    st.qsSpawned = true
                    Take(npc, st)
                end
            end
        end
    end
    return added
end

-- Who they are, to the one they're with.
local SQUAD_WORDS = {
    cop = { "units", "[Dispatch] %d units are assigned to you for this job: armed, with you, and on whatever you fight until it's done." },
    soldier = { "soldiers", "[Overwatch] %d soldiers are assigned to you for this protocol: with you, and on whatever you fight until it's done." },
    rebel = { "fighters", "[Resistance] %d fighters are coming with you on this one: they keep with you and fight beside you until it's done." },
}

function LC.AssignQuestSquad(ply, q)
    if not IsValid(ply) or not q or q.done or not q.violent or not LC.Running then return 0 end
    if q.tmpl and NO_SQUAD[q.tmpl.id] then return 0 end
    local want = cvSquad:GetInt()
    local role = SQUAD_ROLE[LC.QuestFaction and LC.QuestFaction(ply) or ""]
    if want <= 0 or not role then return 0 end
    LC.QuestSquads[q] = { role = role, want = want, nextTop = CurTime() + 45 }
    TopUp(q, CurTime())
    local n = #SquadOf(q)
    if n > 0 then
        local w = SQUAD_WORDS[role]
        ply:ChatPrint(string.format(w[2], n))
        if LC.Notice then
            LC.Notice(ply, "info", "Your squad", string.format("%d %s are with you for this job. They follow you and fight what you fight until it's over.", n, w[1]), 7)
        end
    end
    return n
end

hook.Add("LivingCityQuestAccepted", "LivingCityQuestSquad", function(ply, q)
    local ok, err = LC.Try(LC.AssignQuestSquad, ply, q)
    if not ok and LC.Error then LC.Error("quest squad", err) end
end)

local function Release(q)
    for npc, st in pairs(LC.NPCs or {}) do
        if st.questSquad == q and IsValid(npc) then
            st.questSquad = nil
            if st.role == "rebel" then
                if LC.DismissFollower and st.follow then LC.DismissFollower(npc, st, true) end
            else
                st.backupFor, st.backupUntil, st.backupJoined = nil, nil, nil
                if st.qsSpawned then st.qsLeaveAt = CurTime() end
            end
        end
    end
    LC.QuestSquads[q] = nil
end
LC.ReleaseQuestSquad = Release

function LC.QuestSquadTick(now)
    for q, s in pairs(LC.QuestSquads) do
        if q.done or not (LC.ActiveQuests and LC.ActiveQuests[q]) then
            Release(q)
        else
            local ply = q.owner
            if IsValid(ply) then
                for npc, st in pairs(LC.NPCs or {}) do
                    if st.questSquad == q and IsValid(npc) and npc:Health() > 0 then
                        if st.role == "rebel" then
                            if st.follow ~= ply then st.follow, st.followSID, st.followAt = ply, ply:SteamID(), now end
                        else
                            st.backupFor, st.backupUntil, st.backupJoined = ply, now + 60, true
                            -- the infested too: they're not on the city's list of who to shoot
                            if st.state ~= "hostile" and LC.MakeOneHostile then
                                for other, ost in pairs(LC.NPCs) do
                                    if ost.role == "zombie" and IsValid(other) and other:Health() > 0
                                        and other:GetPos():DistToSqr(npc:GetPos()) < 900 * 900
                                        and LC.LineOfSight(npc:EyePos(), other:EyePos(), npc, other) then
                                        LC.MakeOneHostile(npc, st, other)
                                        st.provokedBy, st.provokedUntil = other, now + 60
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                -- one down: another comes, now and then
                if now >= (s.nextTop or 0) then
                    s.nextTop = now + 45
                    TopUp(q, now)
                end
            end
        end
    end
    -- the ones brought in for a job go again, once nobody's looking (or after a few minutes)
    for npc, st in pairs(LC.NPCs or {}) do
        if st.qsLeaveAt and IsValid(npc) and not st.questSquad and st.state ~= "hostile" then
            if not LC.IsSeen(npc:GetPos() + UP) or now - st.qsLeaveAt > 240 then
                LC.NPCs[npc] = nil
                npc:Remove()
            end
        end
    end
end

timer.Create("LivingCityFieldOps", 1, 0, function()
    if not LC.Running then return end
    local now = CurTime()
    local ok, err = LC.Try(KeepGunsOut)
    if not ok and LC.Error then LC.Error("backup guns", err) end
    ok, err = LC.Try(LC.QuestSquadTick, now)
    if not ok and LC.Error then LC.Error("quest squads", err) end
end)

------------------------------------------------------------------------
-- 6-12, what's left of him (the Missing Unit, part 2: sv_livingcity_stories.lua)
------------------------------------------------------------------------

function LC.SpawnMissingZombine(q, z)
    if not LC.SpawnZombie or not z then return nil end
    local class = "npc_zombine"
    if util.IsValidModel and not util.IsValidModel("models/zombie/zombie_soldier.mdl") then class = "npc_zombie" end
    local owner = q.owner
    local spot, any
    for _ = 1, 12 do
        local p = LC.SpotInZone(z)
        if p then
            any = any or p
            local d = IsValid(owner) and p:Distance(owner:GetPos()) or 500
            if d > 250 and d < 1000 and not LC.IsSeen(p + UP) then spot = p break end
        end
    end
    spot = spot or any or (IsValid(owner) and owner:GetPos() + owner:GetForward() * 400) or z.pos
    local npc, st = LC.SpawnZombie(spot + Vector(0, 0, 4), z, class)
    if not IsValid(npc) or not st then return nil end
    st.unmanaged = true
    if LC.QB and LC.QB.Lock then LC.QB.Lock(q, npc) end
    LC.SetNPCStr(npc, "lc_pname", "6-12")
    q.data.zombine = npc
    q.ents[#q.ents + 1] = npc -- (left to the infestation: the cleanup crew deals with him when the job's over)
    if IsValid(owner) then
        npc:SetEnemy(owner)
        if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(owner, owner:GetPos()) end
    end
    npc:EmitSound(class == "npc_zombine" and "npc/zombine/zombine_alert" .. math.random(1, 7) .. ".wav" or "npc/zombie/zombie_alert1.wav", 80)
    return npc
end

------------------------------------------------------------------------
-- Who hid the contraband (the contraband sweep, sv_livingcity_quests.lua)
------------------------------------------------------------------------

local CLUES = {
    "a ration coupon stamped with citizen ID %s",
    "a torn work card with citizen ID %s on it",
    "a delivery slip signed by citizen %s",
    "a housing chit for citizen %s, folded small",
}

-- After the three stashes: whoever hid them. Nothing to go on (nobody about, or no prison to
-- take them to), and the sweep simply ends, as it always did.
function LC.ContrabandTrail(q, center, kind)
    local Q = LC.QB
    if not Q or not (LC.PrisonAvailable and LC.PrisonAvailable()) then return false end
    local suspect = Q.RandomCitizen(center, 2500) or Q.RandomCitizen()
    if not IsValid(suspect) then return false end
    local id = Q.CitizenID()
    Q.Lock(q, suspect)
    q.data.suspect = suspect
    q.reward = q.reward + 30
    q.expires = math.max(q.expires, CurTime() + 480)
    local place = LC.DescribePlace and LC.DescribePlace(suspect:GetPos()) or "down the street"
    Q.Narrate(q, "Tucked under the last stash: " .. string.format(Pick(CLUES), id) .. ". Whoever hid all this lives around here.")
    local ask = { kind = "count", event = "used_npc", need = 1, pos = center, r = 900,
        text = "Ask around: walk up to a citizen near the stashes and press E to ask who citizen " .. id .. " is",
        filter = function(qq, _, npc)
            local st = LC.NPCs[npc]
            return st ~= nil and st.role == "citizen" and npc ~= qq.data.suspect
        end,
        onDone = function(qq)
            qq.data.target = qq.data.suspect
            Q.Narrate(qq, Pick({
                "'" .. id .. "? Keeps odd hours. Saw them " .. place .. " not long ago.' They won't meet your eyes.",
                "'I don't want trouble. " .. id .. " went " .. place .. ". That's all I know.'",
                "A shrug, then a whisper: '" .. place .. ". Don't tell them it was me.'",
            }))
        end,
    }
    Q.InsertStages(q, {
        ask,
        Q.FindCitizenStage("Track down citizen " .. id .. " (marked on your screen)", 140, function(qq) Q.Freeze(qq.data.target, 40) end),
        Q.Choice("Citizen " .. id .. " sees " .. kind[1] .. " in your hands and goes pale.", {
            { text = "Detain them." },
            { text = "Make them say who it was for.", check = { "authority", 12 },
              success = function(qq, p)
                  LC.AddTrait(p, "loyalty", 1)
                  qq.bonus = (qq.bonus or 0) + 15
                  Q.Narrate(qq, "They crack: a name, a block, a time. Dispatch has it now.")
              end,
              fail = function(qq)
                  Q.Narrate(qq, "They shove the stash at you and run! Catch them.")
                  Q.Flee(qq)
              end },
            { text = "Take their ration units and let them go (ends the job, less XP).",
              pick = function(qq, p)
                  LC.AddTrait(p, "corruption", 1)
                  LC.Bump(p, "bribes")
                  qq.reward = 15
                  Q.Narrate(qq, "Their ration units go in your pocket. The stash goes in the incinerator. Nobody asks.")
                  return "complete"
              end },
            { text = "Let them go with a warning (ends the job).",
              pick = function(qq, p)
                  LC.AddTrait(p, "sympathy", 1)
                  LC.Bump(p, "mercies")
                  qq.reward = 30
                  Q.Narrate(qq, "'Not again.' They nod too fast, and they're gone.")
                  return "complete"
              end },
        }),
        Q.ArrestStage("Detain citizen " .. id .. " with the Arrest Baton (right click)"),
    })
    return true
end
