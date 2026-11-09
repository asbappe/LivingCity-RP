--[[
    Living City: the desperate Combine (sv_livingcity_desperation.lua)

    The owner, 9 November: rather than flooding the city with NPCs, tougher
    units (lc_cp_health, lc_soldier_health, lc_elite_health: sv_livingcity.lua)
    and, when the Resistance's players outnumber the Combine's, units that fight
    dirtier the more outnumbered they are:
      - metrocops are issued SMGs instead of pistols (a share of them equal to
        the desperation: half of them at 0.5, all of them at 1);
      - soldiers throw grenades: frags, the Combine's poison gas and flashbangs
        (their own flashbangs and gas spare Combine units and players);
      - Elites are supplied with up to twice the energy balls (AR2 alt fire),
        kept topped up, and fire more of them;
      - every Combine unit does up to LC.DesperationDamage (10%) more damage
        to players.

    LC.Desperation (0 to 1) follows LC.DesperationTarget() slowly, at most
    LC.DesperationStep every 5 seconds (nothing ever jumps):
      0 under LC.ImbalanceFloor Resistance players, or at less than 1.5 to 1;
      2 to 1: 0.2; 3 to 1: 0.6; 4 to 1 and more: 1 (all in LC.DesperationFrom,
      LC.DesperationFull).
    lc_desperation 0 turns it all off (a setting in the editor's Population).
]]

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_desperation", "1", FLAGS, "Combine NPCs fight dirtier the more the Resistance's players outnumber the Combine's (SMGs, grenades, energy balls)")

LC.DesperationFrom, LC.DesperationFull = 1.5, 4 -- (Resistance to Combine players: where it starts, where it's full)
LC.DesperationStep = 0.05         -- (most it moves every 5 seconds: about 100 seconds from none to full)
LC.DesperationDamage = 0.10       -- (the owner: 10% more damage at full)
LC.DesperationEliteBalls = 2      -- (an Elite's energy balls normally; up to twice that)
LC.DesperationFrags = 3           -- (a soldier's own frags at full: Half-Life 2 throws these itself)
LC.DesperationThrowGap = { 45, 12 }  -- (seconds between one soldier's thrown grenades: barely desperate, fully)
LC.DesperationTargetGap = { 12, 3 }  -- (seconds between grenades at the same person)
LC.DesperationBallGap = { 30, 8 }    -- (seconds between one Elite's extra energy balls)
LC.DesperationMix = { { "frag", 50 }, { "poison", 25 }, { "flash", 25 } }
LC.Desperation = LC.Desperation or 0

local function Lerp2(t, ab) return ab[1] + (ab[2] - ab[1]) * t end

local function Counts()
    if LC.ImbalanceCounts then return LC.ImbalanceCounts() end
    return { rebels = 0, combine = 0 }
end

-- Where the desperation is heading, from the players on each side.
function LC.DesperationTarget(n)
    if not cvOn:GetBool() then return 0 end
    n = n or Counts()
    if n.rebels < (LC.ImbalanceFloor or 4) then return 0 end
    local ratio = n.rebels / math.max(1, n.combine)
    return math.Clamp((ratio - LC.DesperationFrom) / (LC.DesperationFull - LC.DesperationFrom), 0, 1)
end

function LC.DesperationLevel() return cvOn:GetBool() and (LC.Desperation or 0) or 0 end

-- A metrocop's sidearm when it's first issued: an SMG for a share of them as big as the desperation.
-- (each cop's roll is kept, so the same ones carry SMGs as it rises)
function LC.DesperateSidearm(st)
    st.smgRoll = st.smgRoll or math.random()
    return st.smgRoll < LC.DesperationLevel() and "weapon_smg1" or "weapon_pistol"
end

local function IsResistance(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return ent:GetNW2String("lcf_faction", "") == "resistance" end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and st.role == "rebel"
end

local function CombinePlayer(p)
    local f = p:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "ota"
end

-- Nobody of the Combine's own, or a citizen, near where a grenade would land.
function LC.DesperateClear(pos, r, kind)
    local r2 = r * r
    if kind == "poison" and not (LC.FiltersFouled and LC.FiltersFouled()) then return true end -- (their masks keep it out)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and st.role ~= "rebel" and st.role ~= "zombie" and npc:GetPos():DistToSqr(pos) < r2 then
            if kind ~= "flash" or not LC.IsSecurity(st) then return false end -- (their own flashbangs spare them)
        end
    end
    if kind ~= "flash" then
        for _, p in ipairs(player.GetAll()) do
            if p:Alive() and CombinePlayer(p) and p:GetPos():DistToSqr(pos) < r2 then return false end
        end
    end
    return true
end

local function PickKind()
    local total = 0
    for _, m in ipairs(LC.DesperationMix) do total = total + m[2] end
    local roll = math.random() * total
    for _, m in ipairs(LC.DesperationMix) do
        roll = roll - m[2]
        if roll <= 0 then return m[1] end
    end
    return "frag"
end

-- The velocity that lobs something from a to b in t seconds.
function LC.LobVelocity(a, b, t)
    local g = 600
    local cv = GetConVar and GetConVar("sv_gravity")
    if cv then g = cv:GetFloat() end
    local v = (b - a) / t
    v.z = v.z + 0.5 * g * t
    return v
end

-- A soldier throws a grenade at someone. kind: "frag", "poison" or "flash".
function LC.DesperateThrow(npc, target, kind)
    if not IsValid(npc) or not IsValid(target) then return false end
    local from = (npc.EyePos and npc:EyePos() or npc:GetPos() + Vector(0, 0, 60)) + npc:GetForward() * 16
    local to = target:GetPos()
    local t = math.Clamp(from:Distance(to) / 700, 0.6, 1.5)
    local vel = LC.LobVelocity(from, to, t)
    local e
    if kind == "frag" then
        e = ents.Create("npc_grenade_frag")
        if IsValid(e) then
            e:SetPos(from)
            e:SetOwner(npc)
            e:Spawn()
            e:Activate()
            if e.SetSaveValue then e:SetSaveValue("m_hThrower", npc) end
            e:Fire("SetTimer", tostring(t + 0.8))
        end
    else
        e = ents.Create("lc_grenade")
        if IsValid(e) then
            e.lcKind, e.lcOwner = kind, npc
            e:SetPos(from)
            e:Spawn()
            e.lcBlowAt = CurTime() + t + 0.5 -- (it lands first)
        end
    end
    if not IsValid(e) then
        if kind ~= "frag" and LC.Detonate then LC.Detonate(kind, to, npc) return true end
        return false
    end
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetVelocity(vel)
        if phys.AddAngleVelocity then phys:AddAngleVelocity(Vector(math.random(-400, 400), math.random(200, 600), 0)) end
    end
    npc:EmitSound("weapons/slam/throw.wav", 70)
    hook.Run("LivingCityDesperateThrow", npc, target, kind)
    return true
end

-- An Elite fires one more energy ball.
function LC.DesperateBall(npc, target)
    if not IsValid(npc) or not IsValid(target) then return false end
    local from = (npc.EyePos and npc:EyePos() or npc:GetPos() + Vector(0, 0, 60)) + npc:GetForward() * 24
    local aim = (target.EyePos and target:EyePos() or target:GetPos()) - Vector(0, 0, 12)
    local dir = (aim - from):GetNormalized()
    -- nobody of their own in the way
    local tr = util.TraceLine({ start = from, endpos = aim, filter = npc, mask = MASK_SHOT })
    local hit = tr and tr.Entity
    if IsValid(hit) and hit ~= target then
        local hst = LC.NPCs and LC.NPCs[hit]
        if (hst and hst.role ~= "rebel" and hst.role ~= "zombie") or (hit:IsPlayer() and not IsResistance(hit)) then return false end
    end
    local ball = ents.Create("prop_combine_ball")
    if not IsValid(ball) then return false end
    ball:SetPos(from)
    ball:SetOwner(npc)
    if ball.SetSaveValue then
        ball:SetSaveValue("m_flRadius", 10)
        ball:SetSaveValue("m_nState", 3)
        ball:SetSaveValue("m_nMaxBounces", 2)
    end
    ball:Spawn()
    ball:EmitSound("NPC_CombineBall.Launch")
    local phys = ball.GetPhysicsObject and ball:GetPhysicsObject()
    if IsValid(phys) then
        if phys.AddGameFlag and FVPHYSICS_WAS_THROWN then phys:AddGameFlag(FVPHYSICS_WAS_THROWN) end
        phys:SetVelocity(dir * 1200)
    end
    ball:Fire("Explode", "", 3)
    return true
end

local function Supply(npc, st, d)
    if st.elite then
        npc:SetKeyValue("NumGrenades", tostring(math.floor(LC.DesperationEliteBalls * (1 + d) + 0.5)))
    elseif st.role == "soldier" then
        npc:SetKeyValue("NumGrenades", tostring(math.floor(LC.DesperationFrags * d + 0.5)))
    elseif st.role == "cop" and st.hasPistol and st.sidearm ~= "weapon_smg1" and LC.DesperateSidearm(st) == "weapon_smg1" then
        -- the pistol's swapped for an SMG
        st.sidearm = "weapon_smg1"
        npc:Give("weapon_smg1")
        if st.armed and npc.SelectWeapon then npc:SelectWeapon("weapon_smg1") end
    end
end

local function Announce(text)
    for _, p in ipairs(player.GetAll()) do LC.Notice(p, "warn", "Overwatch", text, 10) end
end

-- Every 5 seconds: the desperation moves a step toward its target, and the units are supplied for it.
function LC.DesperationTick()
    local was = LC.Desperation or 0
    local want = LC.DesperationTarget()
    local d = was
    if want > d then d = math.min(want, d + LC.DesperationStep) elseif want < d then d = math.max(want, d - LC.DesperationStep) end
    LC.Desperation = d
    if was <= 0 and d > 0 then
        Announce("The Resistance far outnumbers the Combine. Units are breaking out SMGs, grenades and energy balls, and hit a little harder. The more outnumbered they are, the dirtier they fight.")
    elseif was > 0 and d <= 0 then
        Announce("The Combine hold their own again: units fight by the book.")
    end
    if d <= 0 and was <= 0 then return end
    local now = CurTime()
    if now < (LC.DesperationNextSupply or 0) and d > 0 then return end
    LC.DesperationNextSupply = now + 30
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and LC.IsSecurity(st) and not st.test then Supply(npc, st, d) end
    end
end

local function Enemy(npc, st)
    local e = npc.GetEnemy and npc:GetEnemy()
    if not IsValid(e) and IsValid(st.enemy) then e = st.enemy end
    if not IsValid(e) or not IsResistance(e) then return nil end
    if e:IsPlayer() and not e:Alive() then return nil end
    return e
end

-- Every 2 seconds: the soldiers who can throw, throw; the Elites who can fire, fire.
function LC.DesperationFight()
    local d = LC.DesperationLevel()
    if d <= 0 then return 0 end
    local now, done = CurTime(), 0
    LC.DesperationAt = LC.DesperationAt or setmetatable({}, { __mode = "k" })
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and st.role == "soldier" and not st.test and now >= (st.nextDesperate or 0)
            and not (st.stunnedUntil and st.stunnedUntil > now) then
            local target = Enemy(npc, st)
            if target then
                local dist = npc:GetPos():Distance(target:GetPos())
                local seen = not npc.Visible or npc:Visible(target)
                if st.elite then
                    if dist > 300 and dist < 1600 and seen and LC.DesperateBall(npc, target) then
                        st.nextDesperate = now + Lerp2(d, LC.DesperationBallGap) * math.Rand(0.8, 1.2)
                        done = done + 1
                    end
                elseif dist > 250 and dist < 1100 and seen and now >= (LC.DesperationAt[target] or 0) then
                    local kind = PickKind()
                    if LC.DesperateClear(target:GetPos(), kind == "flash" and 200 or 320, kind) and LC.DesperateThrow(npc, target, kind) then
                        st.nextDesperate = now + Lerp2(d, LC.DesperationThrowGap) * math.Rand(0.8, 1.2)
                        LC.DesperationAt[target] = now + Lerp2(d, LC.DesperationTargetGap)
                        done = done + 1
                    end
                end
            end
        end
    end
    return done
end

timer.Create("LivingCityDesperation", 5, 0, function() pcall(LC.DesperationTick) end)
timer.Create("LivingCityDesperationFight", 2, 0, function() if LC.Running then pcall(LC.DesperationFight) end end)

-- Up to 10% more damage to players from Combine units.
hook.Add("EntityTakeDamage", "LivingCityDesperation", function(victim, dmg)
    local d = LC.DesperationLevel()
    if d <= 0 or not IsValid(victim) or not victim:IsPlayer() then return end
    local att = dmg:GetAttacker()
    local st = IsValid(att) and LC.NPCs and LC.NPCs[att]
    if st and LC.IsSecurity(st) then dmg:ScaleDamage(1 + LC.DesperationDamage * d) end
end)

-- A line for the readouts.
function LC.DesperationLine()
    local d = LC.DesperationLevel()
    if d <= 0 then return nil end
    return string.format("The Combine are desperate (%d%%): about %d%% of metrocops' sidearms are SMGs, soldiers throw grenades, Elites carry %d energy balls, %d%% more damage.",
        math.floor(d * 100 + 0.5), math.floor(d * 100 + 0.5), math.floor(LC.DesperationEliteBalls * (1 + d) + 0.5), math.floor(LC.DesperationDamage * d * 100 + 0.5))
end
