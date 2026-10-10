--[[
    Living City: stealing the Combine's data

    The Resistance can raid a Combine data terminal (the editor's "Fixture:
    Combine data terminal", or any Combine console prop the map already has,
    best placed in the nexus or a Combine-only zone) and download its data onto
    a chip, the way Alyx did in the Citadel.

      The download   a Hacker (anyone with a multitool) aims at the terminal,
                     primary fire, and stays close for lc_heist_seconds (30).
                     Halfway through the terminal trips its alarm: every unit
                     hears "data breach" with where, it's marked on their
                     screens, the units nearby come running and a response
                     squad comes through the door. A unit who sees you at it
                     makes you wanted. Each terminal then needs
                     lc_heist_cooldown minutes (20) before there's anything new
                     on it.
      Two halves     one terminal only holds half the picture: a data fragment.
                     Download a second terminal's and the two fragments make a
                     whole chip.
      The master     the Combine's master terminal (the editor's "Fixture:
      terminal       Combine master terminal", or the map's own
                     masterinterface) is the motherlode: one download
                     (lc_heist_master_seconds, 60; the alarm a third of the way
                     in, and a bigger squad) gives a master data core, worth far
                     more than a chip, and it's dry for
                     lc_heist_master_cooldown minutes (60) after.
      The chip       a Combine data chip, in your pockets (contraband; units
                     who search you will want it back). What to do with it:
                       - sell it to the black market dealer, for a lot
                       - take it to the Resistance lab: the scientist decodes it: XP
                         and credits for whoever brought it, and for
                         lc_heist_intel_seconds (300, five minutes) every Resistance member
                         sees every unit in the city outlined through walls
                         (patrol routes, posts, who's where), the scanner
                         report turned around
                       - plug it into a terminal yourself (Use, at a terminal)
                         to wipe your own record: wanted status, BOLO and
                         violations, gone. It's spent either way.
      Directives     the Resistance get "Steal the Combine's data" on their
                     Operations board when a terminal is ready; units get
                     "Data breach" when one is being hit.

      The core       the same, bigger: the dealer pays three times a chip's
                     price, the quartermaster's decoding marks every unit for
                     lc_heist_master_intel_seconds (600), and plugged into a
                     terminal it wipes the records of every Resistance member
                     in the city.

      lc_heist 0/1, lc_heist_seconds (30), lc_heist_cooldown (20),
      lc_heist_intel_seconds (300), lc_heist_master_seconds (60),
      lc_heist_master_cooldown (60), lc_heist_master_intel_seconds (600)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_heist", "1", FLAGS, "The Resistance can steal data from Combine terminals")
local cvSecs     = CreateConVar("lc_heist_seconds", "30", FLAGS, "Seconds a data download takes")
local cvCooldown = CreateConVar("lc_heist_cooldown", "20", FLAGS, "Minutes before a terminal has new data to steal")
local cvIntel    = CreateConVar("lc_heist_intel_seconds", "300", FLAGS, "Seconds the Resistance can see every unit after a chip is decoded")
local cvMSecs    = CreateConVar("lc_heist_master_seconds", "60", FLAGS, "Seconds a download from the master terminal takes")
local cvMCool    = CreateConVar("lc_heist_master_cooldown", "60", FLAGS, "Minutes before the master terminal has new data to steal")
local cvMIntel   = CreateConVar("lc_heist_master_intel_seconds", "600", FLAGS, "Seconds the Resistance can see every unit after a master data core is decoded")

local function IsResistance(p) return IsValid(p) and p:GetNW2String("lcf_faction", "") == "resistance" end
local function Unit(p) return LC.PlayerIsCP and LC.PlayerIsCP(p) end

LC.TerminalReadyAt = LC.TerminalReadyAt or {} -- [key] = CurTime() it has new data

-- Combine console props a map may already have (the master interface is the master terminal)
local TERMINAL_MODELS = { "combine_interface", "breenconsole", "combine_intmonitor", "combine_smallmonitor", "masterinterface", "combine_intwallunit" }
function LC.IsTerminalModel(model)
    model = string.lower(model or "")
    for _, m in ipairs(TERMINAL_MODELS) do if string.find(model, m, 1, true) then return true end end
    return false
end
function LC.IsMasterTerminalModel(model) return string.find(string.lower(model or ""), "masterinterface", 1, true) ~= nil end

local function StaticKey(pos) return string.format("s%d:%d:%d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)) end

-- The terminal someone is looking at: key, position, entity (if it is one), and
-- whether it's the master terminal. nil if none.
function LC.DataTerminalAt(ply)
    local tr = ply:GetEyeTrace()
    if not tr or not tr.HitPos or tr.HitPos:DistToSqr(ply:EyePos()) > 120 * 120 then return nil end
    local e = tr.Entity
    if IsValid(e) then
        if e:GetClass() == "lc_dataterminal" then return "e" .. (e.lcFixtureKey or e:EntIndex()), e:GetPos(), e, false end
        if e:GetClass() == "lc_masterterminal" then return "m" .. (e.lcFixtureKey or e:EntIndex()), e:GetPos(), e, true end
        -- the scanner console and the commissary have other jobs
        if e:GetClass() ~= "lc_console" and e:GetClass() ~= "lc_terminal" and not string.StartWith(e:GetClass(), "lc_")
            and LC.IsTerminalModel(e:GetModel()) then
            return "e" .. e:EntIndex(), e:GetPos(), e, LC.IsMasterTerminalModel(e:GetModel())
        end
    end
    for _, fx in ipairs(LC.StaticFixtures or {}) do
        if (fx.kind == "dataterm" or fx.kind == "masterterm") and fx.pos:DistToSqr(tr.HitPos) < 90 * 90 then
            return StaticKey(fx.pos), fx.pos, nil, fx.kind == "masterterm"
        end
    end
    return nil
end

-- Every terminal in the city (for the Operations board): { key, pos, master }
function LC.DataTerminals()
    local out = {}
    for _, e in ipairs(LC.EntsOf("lc_dataterminal")) do
        out[#out + 1] = { key = "e" .. (e.lcFixtureKey or e:EntIndex()), pos = e:GetPos(), master = false }
    end
    for _, e in ipairs(LC.EntsOf("lc_masterterminal")) do
        out[#out + 1] = { key = "m" .. (e.lcFixtureKey or e:EntIndex()), pos = e:GetPos(), master = true }
    end
    for _, fx in ipairs(LC.StaticFixtures or {}) do
        if fx.kind == "dataterm" or fx.kind == "masterterm" then
            out[#out + 1] = { key = StaticKey(fx.pos), pos = fx.pos, master = fx.kind == "masterterm" }
        end
    end
    return out
end

-- The ones with something on them right now (master: the master terminal; else the ordinary ones).
function LC.ReadyTerminals(master)
    local now, out = CurTime(), {}
    for _, t in ipairs(LC.DataTerminals()) do
        if (t.master == true) == (master == true) and (LC.TerminalReadyAt[t.key] or 0) <= now then out[#out + 1] = t end
    end
    return out
end

local function Alarm(pos, ply, master)
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    local units = {}
    for _, p in ipairs(player.GetAll()) do
        if Unit(p) then
            units[#units + 1] = p
            p:ChatPrint("[CP net] " .. (master and "MASTER TERMINAL BREACH " or "DATA BREACH ") .. where .. ". Anticitizens are inside Combine systems. All units respond.")
        end
    end
    if LC.SendCompressed and #units > 0 then
        LC.SendCompressed("lc_cpmark", { name = master and "MASTER TERMINAL BREACH" or "DATA BREACH", x = pos.x, y = pos.y, z = pos.z, secs = 120 }, units)
    end
    if sound and sound.Play then sound.Play("ambient/alarms/klaxon1.wav", pos, 90) end
    if LC.MakeCopsHostile and IsValid(ply) then LC.MakeCopsHostile(ply, pos, 1800) end
    if LC.AnnounceLine then LC.AnnounceLine("f_anticitizenreport_spkr.wav", "Anticitizens are breaking into Combine systems " .. where .. ".") end
    if LC.PostDirective then LC.PostDirective("cp_databreach") end
    LC.LastBreach = { pos = pos, at = CurTime() }
    hook.Run("LivingCityDataBreach", pos, ply, master)
end

-- What a finished download leaves in your pockets: from an ordinary terminal a
-- fragment (two from different terminals make a chip), from the master
-- terminal a master data core.
local function Downloaded(p, key, master)
    if master then
        if LC.GiveOrDrop then LC.GiveOrDrop(p, "master_chip", 1) else LC.GiveItem(p, "master_chip") end
        p:ChatPrint("[Resistance] The master terminal's data, all of it, on one core. This is the motherlode: the quartermaster can decode it (every unit marked for ten minutes), the dealer will pay a fortune, or plug it in and wipe every comrade's record.")
        return
    end
    if LC.HasItem(p, "data_shard") and p.lcShardKey ~= key then
        LC.TakeItem(p, "data_shard")
        if LC.GiveOrDrop then LC.GiveOrDrop(p, "data_chip", 1) else LC.GiveItem(p, "data_chip") end
        p.lcShardKey = nil
        p:ChatPrint("[Resistance] The other half. The two fragments make a whole chip of Combine data: the dealer pays well for it, or take it to the quartermaster to decode.")
    else
        if LC.GiveOrDrop then LC.GiveOrDrop(p, "data_shard", 1) else LC.GiveItem(p, "data_shard") end
        p.lcShardKey = key
        p:ChatPrint("[Resistance] Half the picture: a data fragment. Another terminal has the rest. Download it and the two make a whole chip.")
    end
end

function LC.StealData(ply)
    if not cvOn:GetBool() then return false end
    if not (LC.CanHack and LC.CanHack(ply)) then
        return false, "You need a multitool to get into it. (The Resistance's Hackers carry one; the black market sells them.)"
    end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local key, pos, _, master = LC.DataTerminalAt(ply)
    if not key then return false, "Look at a Combine terminal." end
    local now = CurTime()
    if (LC.TerminalReadyAt[key] or 0) > now then
        return false, string.format("Nothing new on this one. (Ready again in about %d minutes.)", math.ceil((LC.TerminalReadyAt[key] - now) / 60))
    end
    if not master and ply.lcShardKey == key and LC.HasItem(ply, "data_shard") then
        return false, "You've already got this terminal's half. The rest is on another terminal."
    end
    local secs = master and cvMSecs:GetFloat() or cvSecs:GetFloat()
    local alarmed = false
    ply:EmitSound("buttons/combine_button7.wav", 65)
    local ok = LC.StartTask(ply, secs, master and "Downloading the master terminal... stay close" or "Downloading Combine data... stay close", {
        maxMove = 70, cancelText = "The download breaks off. Nothing to show for it.",
        done = function(p)
            LC.TerminalReadyAt[key] = CurTime() + (master and cvMCool:GetFloat() or cvCooldown:GetFloat()) * 60
            Downloaded(p, key, master)
            p:EmitSound("buttons/combine_button3.wav", 70)
            if LC.QuestEvent then
                LC.QuestEvent("data_stolen", p, key, master)
                if master then LC.QuestEvent("master_stolen", p, key, true) end
            end
            hook.Run("LivingCityDataStolen", p, key, master)
        end,
    })
    if not ok then return false end
    -- partway through, the terminal notices (the master terminal sooner)
    timer.Simple(secs * (master and 0.33 or 0.5), function()
        if not IsValid(ply) or not (LC.Busy and LC.Busy(ply)) or alarmed then return end
        alarmed = true
        ply:ChatPrint(master and "[Resistance] Every alarm in the nexus at once. They're coming in force. Keep going, or run."
            or "[Resistance] An alarm. They know. Keep going, or run.")
        Alarm(pos, ply, master)
    end)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        LC.ReportCrime(ply, master and "Breaking into the master terminal" or "Breaking into Combine systems", master and 600 or 300)
    end
    return true
end

-- The lab's scientist decodes it: XP and credits, and the Resistance see every unit for a while.
-- Which chip to use: the one asked for, else an ordinary chip before the master core.
local function ChipFor(ply, id)
    if id and LC.HasItem(ply, id) then return id end
    if LC.HasItem(ply, "data_chip") then return "data_chip" end
    if LC.HasItem(ply, "master_chip") then return "master_chip" end
    return nil
end

function LC.DecodeChip(ply, id)
    local chip = ChipFor(ply, id)
    if not chip then return false, "You don't have a data chip." end
    if not IsResistance(ply) then return false, "Only the Resistance can make sense of it. The dealer would buy it." end
    if not (LC.ScientistNear and LC.ScientistNear(ply:GetPos())) then return false, "Take it to the lab: the scientist decodes them." end
    LC.TakeItem(ply, chip)
    local master = chip == "master_chip"
    if LC.AddXP then LC.AddXP(ply, master and 150 or 50, master and "The master terminal's data decoded" or "Combine data decoded") end
    LC.AddCredits(ply, master and 150 or 50, master and "The master terminal's data decoded" or "Combine data decoded")
    local secs = master and cvMIntel:GetFloat() or cvIntel:GetFloat()
    SetGlobal2Float("lc_rebel_intel", CurTime() + secs)
    if LC.RadioNotice then
        LC.RadioNotice("resistance", string.format("The data's decoded: unit positions, patrol routes, posts. Every unit is marked for you for %d seconds. Move.", secs))
    end
    hook.Run("LivingCityDataDecoded", ply)
    return true
end

-- Plugged into a terminal yourself: your own record, wiped.
local function WipeOne(p)
    if LC.ClearWanted then LC.ClearWanted(p) end
    p:SetNW2Bool("lc_bolo", false)
    p:SetNW2String("lc_bolo_text", "")
    if LC.RecordOf then
        local r = LC.RecordOf(p)
        if r then r.v = {} end
    end
    if LC.DropBolosFor and LC.RecordKey then LC.DropBolosFor(LC.RecordKey(p)) end
    hook.Run("LivingCityRecordWiped", p)
end

function LC.WipeRecordWithChip(ply, id)
    local chip = ChipFor(ply, id)
    if not chip then return false, "You don't have a data chip." end
    if not LC.DataTerminalAt(ply) then return false, "Look at a Combine terminal to plug it in (or take it to the quartermaster, or sell it)." end
    LC.TakeItem(ply, chip)
    ply:EmitSound("buttons/combine_button1.wav", 65)
    if chip == "master_chip" then
        -- the motherlode: every comrade's record, not just yours
        local n = 0
        for _, p in ipairs(player.GetAll()) do
            if p == ply or IsResistance(p) then
                WipeOne(p)
                n = n + 1
                if p ~= ply then p:ChatPrint("[Resistance] Someone fed the master terminal's own code back into it. Your record comes back clean.") end
            end
        end
        ply:ChatPrint(string.format("[Resistance] The master core's code goes into the system. %d records come back clean: no violations, no BOLOs, nobody wanted. The core is spent.", n))
    else
        WipeOne(ply)
        ply:ChatPrint("[Resistance] The chip's code goes into the system. Your record comes back clean: no violations, no BOLO, not wanted. The chip is spent.")
    end
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then
        ply:ChatPrint("[Resistance] Your face is still known, though: a fighter in the open is hunted whatever the records say.")
    end
    return true
end

-- E on a terminal: steal (the Resistance); anyone else gets nothing from it
hook.Add("KeyPress", "LivingCityHeist", function(ply, key)
    if key ~= IN_USE or not cvOn:GetBool() or not ply:Alive() or not (LC.CanHack and LC.CanHack(ply)) then return end
    if (ply.lcHeistNext or 0) > CurTime() or (LC.Busy and LC.Busy(ply)) then return end
    if not LC.DataTerminalAt(ply) then return end
    ply.lcHeistNext = CurTime() + 1
    local ok, why = LC.StealData(ply)
    if not ok and why then ply:ChatPrint(why) end
end)

hook.Add("PlayerSay", "LivingCityHeist", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!decode" then
        local ok, why = LC.DecodeChip(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
end)

-- Using the chip from your pockets: the lab's scientist if he's here, else a terminal you're at
function LC.UseDataChip(ply, id)
    if IsResistance(ply) and LC.ScientistNear and LC.ScientistNear(ply:GetPos()) then
        return LC.DecodeChip(ply, id)
    end
    return LC.WipeRecordWithChip(ply, id)
end

-- Two fragments in your pockets, however they got there, are a chip.
hook.Add("LivingCityInventoryChanged", "LivingCityDataShards", function(ply)
    if not IsValid(ply) or not LC.HasItem(ply, "data_shard", 2) then return end
    LC.TakeItem(ply, "data_shard", 2)
    LC.GiveItem(ply, "data_chip", 1)
    ply.lcShardKey = nil
    ply:ChatPrint("[Resistance] Two data fragments, one whole chip.")
end)
