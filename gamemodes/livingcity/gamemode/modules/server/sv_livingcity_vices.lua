--[[
    Living City: cigarettes, alcohol and stimulants (and how a night's dream leaves you)

      The owner, 7 November: "I also wanted to add alcohol and cigarettes with varying effects",
      and stimulants: the only way to keep yourself awake through a night with a nightmare in it
      (sv_livingcity_dreams.lua: nobody opts out of a nightmare).

      From your pockets (F3), each one's button: Smoke, Drink or Take.

      Cigarettes (Union cigarettes from the Commissary, hand-rolled from the black market):
        steady your nerves (they clear the shakes a nightmare leaves), take the edge off hunger
        and dry your mouth. Hand-rolled are harsher: more coughing, and they do it all more.
        Smoke three inside ten minutes and you cough your lungs up (a little health, more thirst).
        Anyone nearby sees the smoke.
      Alcohol (homebrew beer and moonshine from the black market, pre-war vodka from the
        Commissary for exemplary citizens): each drink makes you drunker (beer 1, vodka 2,
        moonshine 3; it wears off by one every two minutes). It dulls pain (a little health back
        as you drink it). Tipsy (2 and up): you take a tenth less from every hit. Drunk (4 and up):
        the world sways, and you can't run. Past 7 you throw up (hungry and thirsty again, and
        sobered to 3). Beer quenches a little thirst; spirits make it worse. One moonshine in five
        is a bad batch: it poisons you and blinds you for a few seconds.
      Stimulants (a stimulant shot, black market): fifteen minutes wide awake. You can't fall
        asleep (so tonight's nightmare can't have you), and it clears the shakes too. A second
        while the first is still in you: your heart pounds (health lost). When it wears off you
        crash: three minutes too heavy to run.
      After a dream you play (sv_livingcity_dreamgames.lua; the owner, 8 November: nothing the
        Combine would give): win it and you wake Unbroken (a day when Breen's water can't fog you
        and no nightmare can take you) with a second wind (a day of tiring slower, hunger and thirst
        coming slower); a citizen also wakes with a Vortigaunt's whisper (a black market dealer or
        a rebel cache marked for ten minutes), the Resistance with something a Vortigaunt pressed
        into their hand (hand-rolled cigarettes, moonshine or a stimulant shot). Still in it at the
        end: nothing either way. Lose every life: 30 off your health until your next full night's
        sleep, and three minutes of the shakes.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_vice") -- someone smoking (everyone near sees it), and your own screen's effects

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) else p:ChatPrint(title .. ": " .. text) end
end

local WIRED_SECS, CRASH_SECS, SHAKEN_SECS = 900, 180, 180
local DRUNK_DECAY = 120 -- (seconds to sober up by one)
LC.ViceWiredSecs, LC.ViceCrashSecs, LC.ViceShakenSecs = WIRED_SECS, CRASH_SECS, SHAKEN_SECS

-- How it stands with someone.
function LC.Wired(p) return IsValid(p) and p:GetNW2Float("lc_wired_until", 0) > CurTime() end
function LC.Crashing(p) return IsValid(p) and p:GetNW2Float("lc_crash_until", 0) > CurTime() end
function LC.Shaken(p) return IsValid(p) and p:GetNW2Float("lc_shaken_until", 0) > CurTime() end
function LC.Drunk(p) return IsValid(p) and p:GetNW2Int("lc_drunk", 0) or 0 end

local function SetDrunk(p, n)
    n = math.Clamp(math.floor(n), 0, 8)
    p:SetNW2Int("lc_drunk", n)
    p.lcSoberAt = n > 0 and (CurTime() + DRUNK_DECAY) or nil
end
LC.SetDrunk = SetDrunk

local function Calm(p)
    if LC.Shaken(p) then
        p:SetNW2Float("lc_shaken_until", 0)
        return true
    end
    return false
end

local function Hurt(p, n) p:SetHealth(math.max(1, p:Health() - n)) end

------------------------------------------------------------------------
-- Smoking, drinking, taking
------------------------------------------------------------------------

local function Smoke(p, it)
    local s = it.strength or 1
    if LC.Feed then LC.Feed(p, 5 * s, -3 * s) end -- (the appetite goes; the mouth dries)
    local calmed = Calm(p)
    -- (three inside ten minutes: a coughing fit)
    local now = CurTime()
    p.lcSmokes = p.lcSmokes or {}
    for i = #p.lcSmokes, 1, -1 do if p.lcSmokes[i] < now - 600 then table.remove(p.lcSmokes, i) end end
    p.lcSmokes[#p.lcSmokes + 1] = now
    net.Start("lc_vice")
    net.WriteString("smoke")
    net.WriteEntity(p)
    net.WriteUInt(s, 4)
    if net.SendPVS then net.SendPVS(p:GetPos()) else net.Broadcast() end
    if #p.lcSmokes >= 3 then
        Hurt(p, 4)
        if LC.Feed then LC.Feed(p, 0, -12) end
        p:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 70)
        Notice(p, "warn", "Coughing fit", "Too many, too close together. Your chest burns.", 5)
    elseif math.random() < 0.25 * s then
        p:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 65)
    end
    p:ChatPrint(calmed and "You draw on it, slow. Your hands stop shaking." or (s > 1 and "Harsh. It catches in your throat, but it does the job." or "Thin, Union-approved smoke. It takes the edge off."))
    return true
end

local function Drink(p, it)
    local s = it.strength or 1
    local was = LC.Drunk(p)
    p:SetHealth(math.min(p:GetMaxHealth(), p:Health() + 3 * s)) -- (it dulls the pain)
    if LC.Feed then LC.Feed(p, 0, it.quench or -6) end
    p:EmitSound("npc/barnacle/barnacle_gulp1.wav", 60)
    if it.badChance and math.random() < it.badChance then
        Hurt(p, 15)
        p:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 2, 4)
        Notice(p, "warn", "A bad batch", "Something in it was very wrong. Your eyes go dark and your stomach turns.", 7)
    end
    local n = was + s
    if n >= 7 then
        if LC.Feed then LC.Feed(p, -25, -30) end
        SetDrunk(p, 3)
        p:EmitSound("npc/barnacle/barnacle_digesting1.wav", 70)
        p:ScreenFade(SCREENFADE.IN, Color(80, 100, 20, 160), 1.5, 0.5)
        Notice(p, "warn", "You throw up", "Too much. It all comes back up, and you're hungry and thirsty all over again.", 6)
        return true
    end
    SetDrunk(p, n)
    if n >= 4 and was < 4 then Notice(p, "info", "Drunk", "The world's swaying. You can't run like this. (It wears off, slowly.)", 6)
    elseif n >= 2 and was < 2 then p:ChatPrint("A warm glow. The knocks don't hurt quite as much.")
    else p:ChatPrint("It goes down warm.") end
    return true
end

local function Stim(p, it)
    local now = CurTime()
    if LC.Wired(p) then
        Hurt(p, 10)
        p:EmitSound("player/heartbeat1.wav", 70)
        Notice(p, "warn", "Your heart pounds", "Another one, on top of the last. Your chest hammers and your vision swims.", 6)
    end
    local untilT = math.max(p:GetNW2Float("lc_wired_until", 0), now) + WIRED_SECS
    p:SetNW2Float("lc_wired_until", math.min(untilT, now + WIRED_SECS * 1.5))
    p:SetNW2Float("lc_crash_until", 0)
    p.lcCrashPending = true
    if LC.Feed then LC.Feed(p, 0, -8) end
    Calm(p)
    p:EmitSound("items/medshot4.wav", 55)
    Notice(p, "info", "Wide awake", "Your eyes snap open and your heart quickens. For the next fifteen minutes you couldn't sleep if you tried: lights out waits, and no dream can take you. No second shot until you've slept and dreamt properly.", 8)
    return true
end

local USES = { smoke = Smoke, drink = Drink, stim = Stim }

-- From your pockets (sv_livingcity_scavenge.lua's LC.ItemUse sends it here). True, or false and why not.
function LC.ViceUse(p, id)
    local it = LCS.Items[id]
    local fn = it and USES[it.vice]
    if not fn then return false end
    if p.lcSleep then return false, "Not while you're asleep." end
    -- one stimulant, then not again until you've slept and dreamt properly (sv_livingcity_bedtime.lua)
    if it.vice == "stim" and LC.StimLocked and LC.StimLocked(p) then return false, LC.StimLockedText end
    if not LC.HasItem(p, id) then return false end
    LC.TakeItem(p, id, 1)
    fn(p, it)
    if it.leaves and not LC.GiveItem(p, it.leaves, 1) and LC.SpawnWorldItem then LC.SpawnWorldItem(it.leaves, p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 40)) end -- (the empty bottle)
    hook.Run("LivingCityConsumed", p, id)
    return true
end

------------------------------------------------------------------------
-- Waking from a dream you played: well rested, or shaken
------------------------------------------------------------------------

-- The owner, 8 November: nightmares are the Administrator's punishment, so beating one earns
-- nothing the Combine would hand out (no credits, no standing, no experience); losing one costs
-- 30 health until your next full night's sleep.
local SCAR_HP = 30
LC.DreamScarHP = SCAR_HP
local function DayLen() return math.max(60, GetGlobal2Float("lc_day_len", 1440)) end
function LC.Unbroken(p) return IsValid(p) and p:GetNW2Float("lc_unbroken_until", 0) > CurTime() end
function LC.SecondWind(p) return IsValid(p) and p:GetNW2Float("lc_secondwind_until", 0) > CurTime() end
function LC.DreamScarred(p) return IsValid(p) and p:GetNW2Bool("lc_dream_scar", false) end

-- Lost a nightmare: 30 off the health limit, until a night's sleep begun after it.
local function ScarHealth(p, on)
    if on and not p.lcScarHP then
        p.lcScarHP = true
        p:SetMaxHealth(math.max(1, p:GetMaxHealth() - SCAR_HP))
        if p:Health() > p:GetMaxHealth() then p:SetHealth(p:GetMaxHealth()) end
    elseif not on and p.lcScarHP then
        p.lcScarHP = nil
        p:SetMaxHealth(p:GetMaxHealth() + SCAR_HP)
    end
end
function LC.SetDreamScar(p, on)
    if not IsValid(p) then return end
    p:SetNW2Bool("lc_dream_scar", on and true or false)
    p.lcScarAt = on and CurTime() or nil
    if p.SetPData then p:SetPData("lc_dream_scar", on and "1" or "0") end
    ScarHealth(p, on)
end
hook.Add("LivingCitySlept", "LivingCityDreamScar", function(p)
    if not LC.DreamScarred(p) then return end
    local s = p.lcSleep
    if s and s.t0 and s.t0 > (p.lcScarAt or 0) then -- (the night it happened doesn't count)
        LC.SetDreamScar(p, false)
        Notice(p, "info", "The nightmare's gone", "A real night's sleep, and the nightmare finally lets go. Your strength is back.", 7)
    end
end)
hook.Add("PlayerSpawn", "LivingCityDreamScar", function(p) p.lcScarHP = nil end) -- (spawning sets the limit afresh; the tick takes it down again)
hook.Add("PlayerInitialSpawn", "LivingCityDreamScar", function(p)
    if p.GetPData and p:GetPData("lc_dream_scar", "0") == "1" then
        p:SetNW2Bool("lc_dream_scar", true)
        p.lcScarAt = CurTime()
    end
end)

-- A Vortigaunt's whisper (citizens): where a black market dealer or a rebel cache is.
local function Whisper(p)
    local spots = {}
    for _, e in ipairs(ents.FindByClass("lc_dealer")) do if IsValid(e) then spots[#spots + 1] = { pos = e:GetPos(), what = "A black market dealer" } end end
    for _, r in pairs(LC.RebelProps or {}) do if IsValid(r.cache) then spots[#spots + 1] = { pos = r.cache:GetPos(), what = "A Resistance cache" } end end
    if #spots == 0 then return nil end
    local s = spots[math.random(#spots)]
    net.Start("lc_vice")
    net.WriteString("whisper")
    net.WriteEntity(p)
    net.WriteUInt(0, 4)
    net.WriteVector(s.pos)
    net.WriteString(s.what)
    net.Send(p)
    return s
end
LC.DreamWhisper = Whisper

-- Something brought back (the Resistance): a Vortigaunt pressed it into your hand as you woke.
local GIFTS = { { "cig_rolled", 3 }, { "moonshine", 1 }, { "stimulant", 1 } }
local function Gift(p)
    local g = GIFTS[math.random(#GIFTS)]
    if not LC.GiveItem(p, g[1], g[2]) and LC.SpawnWorldItem then LC.SpawnWorldItem(g[1], p:GetPos() + Vector(0, 0, 40)) end
    return g[1], g[2]
end

-- how: "won" (beat it), "time" (still in it when it ended), "out" (lost every life).
function LC.DreamOutcome(p, how, name)
    if not IsValid(p) then return end
    name = name or "the nightmare"
    local now = CurTime()
    if how == "won" then
        -- for everyone: Unbroken and Second wind, for a day
        p:SetNW2Float("lc_unbroken_until", now + DayLen())
        p:SetNW2Float("lc_secondwind_until", now + DayLen())
        p:SetHealth(math.max(p:Health(), p:GetMaxHealth()))
        Calm(p)
        local extra = ""
        local fac = p:GetNW2String("lcf_faction", "")
        if fac == "citizen" then
            local s = Whisper(p)
            extra = s and (" A Vortigaunt's voice found you in the dark, and whispered where to look: " .. string.lower(s.what) .. " (marked for you, for ten minutes).") or ""
        elseif fac == "resistance" then
            local id, n = Gift(p)
            local it = LCS.Items[id]
            extra = " As you woke, a Vortigaunt's hand pressed something into yours: " .. (n > 1 and (n .. " x ") or "") .. (it and it.name or id) .. "."
        end
        Notice(p, "info", "Unbroken", "You beat " .. name .. ". For a day the Combine can't get into your head (Breen's water won't fog you, and no nightmare can take you), "
            .. "and you've a second wind (you tire slower, hunger and thirst come slower)." .. extra, 12)
    elseif how == "time" then
        Notice(p, "info", "You held on", "You held on until " .. name .. " let go. You wake tired, but whole.", 7)
    elseif how == "out" then
        LC.SetDreamScar(p, true)
        p:SetNW2Float("lc_shaken_until", now + SHAKEN_SECS)
        Notice(p, "warn", "The nightmare stays with you", "You wake soaked in sweat, your hands shaking, weaker than you were: 30 off your health until your next full night's sleep.", 10)
    end
end

------------------------------------------------------------------------
-- How it all feels, as it goes on
------------------------------------------------------------------------

-- Tipsy: a tenth less from every hit.
hook.Add("EntityTakeDamage", "LivingCityVices", function(ent, dmg)
    if IsValid(ent) and ent:IsPlayer() and LC.Drunk(ent) >= 2 and dmg and dmg.ScaleDamage then dmg:ScaleDamage(0.9) end
end)
-- Drunk, or crashing: no running.
hook.Add("SetupMove", "LivingCityVices", function(p, mv)
    if not (p:GetNW2Int("lc_drunk", 0) >= 4 or p:GetNW2Float("lc_crash_until", 0) > CurTime()) then return end
    local cap = p:GetWalkSpeed() or 110
    if mv:GetMaxClientSpeed() > cap then mv:SetMaxClientSpeed(cap) end
end)

timer.Create("LivingCityVices", 1, 0, function()
    local now = CurTime()
    for _, p in ipairs(player.GetAll()) do
        if p.lcSoberAt and now >= p.lcSoberAt then SetDrunk(p, LC.Drunk(p) - 1) end
        if LC.DreamScarred(p) and not p.lcScarHP and p:Alive() then ScarHealth(p, true) end -- (after a respawn)
        if p.lcCrashPending and p:GetNW2Float("lc_wired_until", 0) <= now then
            p.lcCrashPending = nil
            p:SetNW2Float("lc_crash_until", now + CRASH_SECS)
            Notice(p, "info", "The crash", "The stimulant wears off all at once. Your legs feel like lead: no running for a few minutes.", 7)
        end
    end
end)
