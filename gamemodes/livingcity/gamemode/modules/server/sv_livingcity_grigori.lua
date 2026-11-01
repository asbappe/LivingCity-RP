--[[
    Living City: Father Grigori, in the flesh

    While no player is Father Grigori, the man himself keeps to the
    Resistance's ground (the largest rebel territory at first; every
    lc_grigori_move_minutes, 12, he moves on to another camp, when nobody's
    about to see him go), Annabelle in hand, talking to himself and to God.
    E on him:

      Blessing  he lays a hand on you: 25 health back, and blessed for five
                minutes (you take 15% less harm). Once every five minutes each.
      Sermon    he preaches, and every one of ours within earshot is
                emboldened for ten minutes (their shots hit the Combine 10%
                harder; a little XP for listening). Once every ten minutes.
      Talk      a word from him.

    Only for the Resistance and those who keep their heads down near them:
    he blesses no unit, and a unit who walks up to him gets a shotgun's
    worth of scripture. Killed, he's back after lc_grigori_respawn minutes
    (10). lc_grigori 0: no Grigori.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_grigori")      -- server -> client: his window
util.AddNetworkString("lc_grigori_ask")  -- client -> server: "bless", "sermon", "talk"

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_grigori", "1", FLAGS, "Father Grigori keeps to rebel territory when no player is him: blessings and sermons for the Resistance")
local cvRespawn = CreateConVar("lc_grigori_respawn", "10", FLAGS, "Minutes before Father Grigori is back after he's killed")
local cvTalk    = CreateConVar("lc_grigori_talk_gap", "60", FLAGS, "Seconds at the least between two things Father Grigori says out loud")
local cvMove    = CreateConVar("lc_grigori_move_minutes", "12", FLAGS, "About how many minutes Father Grigori stays in one rebel territory before he moves on to another (only when nobody's about to see him go; 0: he stays put)")

local BLESS_SECS, BLESS_EVERY = 300, 300
local SERMON_SECS, SERMON_EVERY = 600, 600
local RANTS = {}
for i = 1, 22 do RANTS[#RANTS + 1] = string.format("vo/ravenholm/monk_rant%02d.wav", i) end
local SAYINGS = {
    "\"Come, my child. There is nothing here that the Lord has not seen.\"",
    "\"They took the town, they took the bells. They did not take this.\" He taps his chest.",
    "\"Mind the traps on the way out. I would hate to bury you.\"",
    "\"Every soul that walks out of their city is a prayer answered.\"",
    "\"Annabelle and I keep watch. Sleep, if you can.\"",
    "\"Pray for them too. Under the masks they were men once.\"",
}

local function Pick(t) return t[math.random(#t)] end

-- He says something: at most once every lc_grigori_talk_gap seconds, whatever it's for.
local function Speak(g, level)
    local now = CurTime()
    if not IsValid(g) or (g.lcSpokeAt or -1e9) + cvTalk:GetFloat() > now then return false end
    g.lcSpokeAt = now
    g:EmitSound(Pick(RANTS), level or 70)
    return true
end
LC.GrigoriSpeak = Speak
local function Rebel(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end
local function Notice(ply, kind, title, text, secs) if LC.Notice then LC.Notice(ply, kind, title, text, secs) else ply:ChatPrint(title .. ": " .. text) end end

LC.Grigori = LC.Grigori or nil
local deadAt = -1e9

local function PlayerIsGrigori()
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_special", "") == "chaplain" then return true end
    end
    return false
end

-- His ground: the largest rebel territory.
local function Home()
    local best
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if not best or (z.r or 0) > (best.r or 0) then best = z end
    end
    return best
end

function LC.SpawnGrigori()
    if IsValid(LC.Grigori) then return LC.Grigori end
    local z = Home()
    if not z then return nil end
    local pos = (LC.SpotInZone and LC.SpotInZone(z)) or z.pos
    if LC.GroundAt then pos = LC.GroundAt(pos) or pos end
    local npc = ents.Create("npc_monk")
    if not IsValid(npc) then return nil end
    npc:SetPos(pos + Vector(0, 0, 4))
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:SetKeyValue("additionalequipment", "weapon_annabelle")
    npc:SetKeyValue("spawnflags", "2") -- (gagged: none of the engine's own idle chatter; he talks when we say)
    npc:Spawn()
    npc:Activate()
    npc:SetNW2String("lc_pname", "Father Grigori")
    npc:SetNW2String("lc_doing", "keeping watch over the flock")
    npc.lcGrigori = true
    npc.lcHome = z
    -- an ordinary man's health (the owner, 1 November: he couldn't be killed)
    if npc.SetMaxHealth then npc:SetMaxHealth(100) end
    npc:SetHealth(100)
    LC.Grigori = npc
    return npc
end

function LC.GrigoriTick(now)
    local want = cvOn:GetBool() and LC.Running and not PlayerIsGrigori() and Home() ~= nil
    local g = LC.Grigori
    if IsValid(g) and g:Health() <= 0 then g = nil end
    if not want then
        if IsValid(LC.Grigori) then LC.Grigori:Remove() end
        LC.Grigori = nil
        return
    end
    if not IsValid(g) then
        if LC.Grigori ~= nil then deadAt = now LC.Grigori = nil end -- (killed: he's away a while)
        if now - deadAt >= cvRespawn:GetFloat() * 60 then LC.SpawnGrigori() end
        return
    end
    -- now and then he moves on to another of the Resistance's camps (when nobody's about to see him go)
    if LC.GrigoriMove(g, now) then return end
    -- he keeps to his ground (and wanders it a little)
    local z = g.lcHome
    local inside = false
    for _, part in ipairs(z and (LC.RebelPartsOf and LC.RebelPartsOf(z)) or { z }) do
        if LCZ and LCZ.Contains(part, g:GetPos(), 0) then inside = true end
    end
    if z and LCZ and not inside and g.SetLastPosition then
        g:SetLastPosition(z.pos)
        g:SetSchedule(SCHED_FORCED_GO)
    elseif math.random() < 0.02 then
        Speak(g, 70) -- (talking to himself, and to God)
    end
end

-- Off to another camp: true when he went. Only with nobody near him, and nobody watching where he
-- turns up; otherwise he tries again in a minute.
function LC.GrigoriMove(g, now, force)
    local mins = cvMove:GetFloat()
    if not IsValid(g) or (mins <= 0 and not force) then return false end
    g.lcMoveAt = g.lcMoveAt or (now + mins * 60 * math.Rand(0.7, 1.3))
    if now < g.lcMoveAt and not force then return false end
    local terr = LC.RebelTerritories and LC.RebelTerritories() or {}
    local here = g.lcHome and LC.RebelLeader and LC.RebelLeader(g.lcHome) or g.lcHome
    local others = {}
    for _, t in ipairs(terr) do if t.leader ~= here and not t.leader.grown then others[#others + 1] = t.leader end end
    if #others == 0 then g.lcMoveAt = now + mins * 60 return false end
    local busy = LC.IsSeen and LC.IsSeen(g:GetPos() + Vector(0, 0, 40))
    for _, p in ipairs(player.GetAll()) do if p:GetPos():DistToSqr(g:GetPos()) < 1500 * 1500 then busy = true end end
    local to = Pick(others)
    local pos = (LC.SpotInZone and LC.SpotInZone(to)) or to.pos
    if LC.GroundAt then pos = LC.GroundAt(pos) or pos end
    if busy or (LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 40))) then g.lcMoveAt = now + 60 return false end
    g:SetPos(pos + Vector(0, 0, 4))
    g.lcHome = to
    g.lcMoveAt = now + mins * 60 * math.Rand(0.7, 1.3)
    if LC.Log then LC.Log("info", "Father Grigori moved on to the rebel territory at " .. tostring(to.pos)) end
    return true
end

timer.Create("LivingCityGrigori", 5, 0, function()
    local ok, err = pcall(LC.GrigoriTick, CurTime())
    if not ok and LC.Error then LC.Error("grigori", err) end
end)
hook.Add("LivingCityStopped", "LivingCityGrigori", function()
    if IsValid(LC.Grigori) then LC.Grigori:Remove() end
    LC.Grigori = nil
end)

------------------------------------------------------------------------
-- Talking to him
------------------------------------------------------------------------

function LC.UseGrigori(ply, g)
    if not IsValid(g) or not g.lcGrigori or not ply:Alive() then return end
    if (ply.lcGrigoriUse or 0) > CurTime() then return end
    ply.lcGrigoriUse = CurTime() + 0.8
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then
        Speak(g, 80)
        ply:ChatPrint("[Father Grigori] \"Ah, a shepherd of the Combine! Come closer, so Annabelle can give you my blessing.\"")
        return
    end
    local now = CurTime()
    net.Start("lc_grigori")
    net.WriteBool(Rebel(ply))
    net.WriteFloat(math.max(0, (ply.lcBlessNext or 0) - now))
    net.WriteFloat(math.max(0, (g.lcSermonNext or 0) - now))
    net.Send(ply)
end

hook.Add("PlayerUse", "LivingCityGrigori", function(ply, ent)
    if LC.StalkerCantSpeak and LC.StalkerCantSpeak(ply, ent) then return false end
    if IsValid(ent) and ent.lcGrigori then LC.UseGrigori(ply, ent) return false end
end)

local function Near(ply, g) return IsValid(g) and ply:GetPos():DistToSqr(g:GetPos()) < 200 * 200 end

-- A blessing, a sermon, or a word. True, or false and why not.
function LC.GrigoriAsk(ply, what)
    local g = LC.Grigori
    if not Near(ply, g) or not ply:Alive() then return false, "Father Grigori isn't here." end
    local now = CurTime()
    if what == "talk" then
        ply:ChatPrint("[Father Grigori] " .. Pick(SAYINGS))
        return true
    end
    if not Rebel(ply) then return false, "\"Go with God, child. But go.\"" end
    if what == "bless" then
        if (ply.lcBlessNext or 0) > now then return false, string.format("\"Patience. God does not repeat Himself so soon.\" (%d s)", math.ceil(ply.lcBlessNext - now)) end
        ply.lcBlessNext = now + BLESS_EVERY
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 25))
        ply:SetNW2Float("lc_blessed_until", now + BLESS_SECS)
        ply:EmitSound("items/medshot4.wav", 65)
        Speak(g, 70)
        Notice(ply, "info", "Blessed", "He lays a heavy hand on your head and mutters in Russian. For five minutes, the world hurts you a little less.", 6)
        return true
    elseif what == "sermon" then
        if (g.lcSermonNext or 0) > now then return false, string.format("\"I have said my piece. Come back later and I will say it again, louder.\" (%d s)", math.ceil(g.lcSermonNext - now)) end
        g.lcSermonNext = now + SERMON_EVERY
        local n = 0
        g.lcSpokeAt = nil -- (a sermon is asked for: he says his piece now)
        Speak(g, 85)
        for _, p in ipairs(player.GetAll()) do
            if Rebel(p) and p:Alive() and p:GetPos():DistToSqr(g:GetPos()) < 500 * 500 then
                n = n + 1
                p:SetNW2Float("lc_emboldened_until", now + SERMON_SECS)
                if LC.AddXP then LC.AddXP(p, 3, "Father Grigori's sermon") end
                Notice(p, "info", "Emboldened", "Father Grigori preaches fire and brimstone at the Combine. For ten minutes your shots hit them harder.", 7)
            end
        end
        hook.Run("LivingCityPreached", g)
        return true
    end
    return false
end

net.Receive("lc_grigori_ask", function(_, ply)
    if (ply.lcGrigoriAsk or 0) > CurTime() then return end
    ply.lcGrigoriAsk = CurTime() + 0.5
    local ok, why = LC.GrigoriAsk(ply, net.ReadString())
    if not ok and why then ply:ChatPrint("[Father Grigori] " .. why) end
end)

------------------------------------------------------------------------
-- What the blessing and the sermon do
------------------------------------------------------------------------

hook.Add("EntityTakeDamage", "LivingCityGrigoriGifts", function(victim, dmg)
    local now = CurTime()
    if victim:IsPlayer() and victim:GetNW2Float("lc_blessed_until", 0) > now then dmg:ScaleDamage(0.85) end
    local att = dmg:GetAttacker()
    if IsValid(att) and att:IsPlayer() and att:GetNW2Float("lc_emboldened_until", 0) > now then
        local combine = (victim:IsPlayer() and LC.PlayerIsCP and LC.PlayerIsCP(victim))
            or (victim:IsNPC() and LC.NPCs and LC.NPCs[victim] and LC.IsSecurity and LC.IsSecurity(LC.NPCs[victim]))
        if combine then dmg:ScaleDamage(1.1) end
    end
end)

-- Half-Life 2 makes him one of the player's vital allies, and the engine throws away any damage a player
-- (or a friendly) does to those: he couldn't be killed. So it's taken off his health here, and when it's gone,
-- he dies (of the world's damage, which the engine lets through).
hook.Add("EntityTakeDamage", "LivingCityGrigoriMortal", function(victim, dmg)
    if not IsValid(victim) or not victim.lcGrigori or victim.lcDying then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or att == game.GetWorld() or att == victim then return end
    local hp = victim:Health() - dmg:GetDamage()
    dmg:SetDamage(0)
    if hp > 0 then victim:SetHealth(hp) return end
    victim.lcDying = true
    victim.lcKilledBy = att
    timer.Simple(0, function()
        if not IsValid(victim) or victim:Health() <= 0 then return end
        victim:SetHealth(1)
        if not DamageInfo then victim:TakeDamage(1000, game.GetWorld(), game.GetWorld()) return end
        local d = DamageInfo()
        d:SetDamage(1000)
        d:SetDamageType(DMG_BULLET)
        d:SetAttacker(game.GetWorld())
        d:SetInflictor(game.GetWorld())
        victim:TakeDamageInfo(d)
    end)
end)

hook.Add("PlayerSpawn", "LivingCityGrigoriGifts", function(ply)
    ply:SetNW2Float("lc_blessed_until", 0)
    ply:SetNW2Float("lc_emboldened_until", 0)
end)

------------------------------------------------------------------------
-- Annabelle holds two: a player who is Father Grigori loads his shotgun
-- two shells at a time (the rest stay in his pockets), like the old
-- double-barrel it is.
------------------------------------------------------------------------

local ANNABELLE = 2
hook.Add("Tick", "LivingCityAnnabelle", function()
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_special", "") == "chaplain" then
            local w = p:GetActiveWeapon()
            if IsValid(w) and w:GetClass() == "weapon_shotgun" and w:Clip1() > ANNABELLE then
                local extra = w:Clip1() - ANNABELLE
                w:SetClip1(ANNABELLE)
                p:GiveAmmo(extra, "Buckshot", true)
            end
        end
    end
end)
