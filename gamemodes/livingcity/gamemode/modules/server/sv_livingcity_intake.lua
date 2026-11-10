--[[
    Living City: Civil Intake (becoming somebody)

    A new person (the first time you join, after a permanent death, a new
    character slot) arrives with nothing: no papers, no room, no ration card.
    Ration cards aren't handed out here: each Union shift you finish earns
    one, and each ration at a dispenser takes one (sv_livingcity_work.lua).
    They step off at an arrival point ("Point: arrival", or failing that the
    train platform) and have to ask the city for each of those things:

      1. Civil Intake ("Fixture: Civil Intake (registration)"). E opens the
         registration form: a name, a face and a description, entered into
         the terminal, not handed out. It takes lc_intake_secs (8) to process
         you; stay at it. Then you're on the register, with a citizen number,
         and your identity papers are in your pockets (F3).
         The screen then points you to Housing Allocation.
         Registered, E shows your record, and replaces lost papers (10
         credits): lc_papers_fee.
      2. Housing Allocation ("Fixture: Housing Allocation"). E opens the
         housing register: every block, how many live there, how far. Present
         your papers and apply for one (or "any block"); it takes as long
         again. A crowded block is only granted to someone in good standing
         (50); otherwise you get the least crowded one. Housed, E shows where
         you live and how you got it, marks the way home, and takes requests
         to transfer to another block (standing 25, once every 30 minutes).
         A map without this desk gives you a room with your papers.
      Labor Assignment ("Fixture: Labor Assignment"), when the map has one,
         comes between the two: it gives you your Union work, and Housing
         Allocation only houses citizens with work (sv_livingcity_labor.lua).

    Your papers: a unit who stops you asks for them, and carrying none costs
    a little standing. Show them to someone from F3 (Use) or the quick menu.
    The ration dispensers take a card for each ration (a forged one still works).

    Until you're registered: no rations (a forged ration card still works),
    no Union job, no Commissary, and a unit who stops you tells you to get
    to Civil Intake. After lc_intake_grace (10) minutes it's "Failure to
    register": you're wanted. Someone arrested before they register is
    processed in custody. Until you have a room, a curfew finds you waiting
    it out near Civil Intake (or the arrival point) rather than at home.

    One person at a desk at a time: "Processing another citizen. Wait your
    turn." New arrivals off the train (sv_livingcity_trains.lua) queue at the
    desks too, in a line in front of each, before they go home.

    Everyone who was already in the city counts as registered and housed. A
    map with no Civil Intake desk registers people as they arrive (as before),
    and lc_intake 0 turns all of it off.

      lc_intake, lc_intake_secs, lc_intake_grace, lc_papers_fee
      Players: !papers.  Admin: lc_register <name>, lc_unregister <name>
      (back through all of it: papers, register, and a room).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn    = CreateConVar("lc_intake", "1", FLAGS, "New people arrive with nothing and go through Civil Intake: register, then ask for a room (only on maps with the desks placed)")
local cvSecs  = CreateConVar("lc_intake_secs", "8", FLAGS, "Seconds a Civil Intake or Housing Allocation terminal takes to process someone")
local cvGrace = CreateConVar("lc_intake_grace", "10", FLAGS, "Minutes a new arrival has to register before a Civil Protection unit who stops them makes it a crime")
local cvPapersFee = CreateConVar("lc_papers_fee", "10", FLAGS, "Credits Civil Intake charges to replace lost identity papers")

util.AddNetworkString("lc_intake_ui")
util.AddNetworkString("lc_intake_act")
util.AddNetworkString("lc_papers_card")

local GOOD_STANDING = 50      -- a crowded block is granted anyway
local TRANSFER_STANDING = 25  -- to ask for a transfer at all
local TRANSFER_WAIT = 1800    -- seconds between transfers

local NEAR = 160         -- how far from the terminal you can be while it works
local SHELTER = 1200     -- someone with no room yet can wait out a curfew this close to intake
local QUEUE_GAP = 42     -- between people in the line
local QUEUE_SLOTS = 8    -- places in the line; anyone further back waits at the last
local QUEUE_WAIT = 150   -- seconds an NPC will stand in line before giving up on it

local function BlockKey() return "lc_block_" .. game.GetMap() end

------------------------------------------------------------------------
-- Who's been through it
------------------------------------------------------------------------

-- Which desk a terminal is: "register", "housing" or "labor" (Labor Assignment: sv_livingcity_labor.lua).
local DESK_OF = { housingterm = "housing", laborterm = "labor" }
local POINT_OF = { housing = "housingterm", labor = "laborterm" }
local function Kind(ent)
    local k = IsValid(ent) and ent:GetNW2String("lc_ikind", "") or ""
    if k ~= "" then return k end
    return IsValid(ent) and DESK_OF[ent.lcFixtureKind or ""] or "register"
end
LC.IntakeKind = Kind

function LC.IntakeOn() return cvOn:GetBool() end

-- This city has the desk (it's in the layout; the terminal itself may still be spawning).
local function HasDesk(kind)
    local pk = POINT_OF[kind] or "intake"
    if LC.CountPointsOfKind then return LC.CountPointsOfKind(pk) > 0 end
    return #(LC.PointsOfKind and LC.PointsOfKind(pk) or {}) > 0
end
LC.IntakeHasDesk = HasDesk

local function Citizen(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "" or f == "citizen"
end

-- Who carries papers: citizens, and the Resistance (they're citizens too, on paper).
local function Papered(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "" or f == "citizen" or f == "resistance"
end
LC.CarriesPapers = Papered

-- What's saved about this person, read once (saved data is a database query
-- each time) and read again whenever it changes: here, a new life, a character
-- switch, a room being handed out (sv_livingcity_housing.lua clears it).
local function State(ply)
    local s = ply.lcIntakeState
    if not s then
        s = {
            fresh = ply:GetPData("lc_intake", "0") == "1", -- arrived under these rules (everyone from before is on the register)
            registered = ply:GetPData("lc_registered", "1") == "1",
            room = (tonumber(ply:GetPData(BlockKey(), 0)) or 0) > 0,
        }
        ply.lcIntakeState = s
    end
    return s
end
local function Save(ply, key, value)
    ply:SetPData(key, value)
    ply.lcIntakeState = nil
end
function LC.IntakeForget(ply) if IsValid(ply) then ply.lcIntakeState, ply.lcDocs = nil, nil end end
hook.Add("LivingCityCharacterSwitched", "LivingCityIntake", function(ply) LC.IntakeForget(ply) end)

local function Fresh(ply) return State(ply).fresh end

-- Not on the register yet (and this city has a desk to register at).
function LC.IntakePending(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not cvOn:GetBool() or not Fresh(ply) then return false end
    if State(ply).registered then return false end
    if not Citizen(ply) then return false end
    if not HasDesk("register") then
        Save(ply, "lc_registered", "1") -- (the desk is gone: they're on the register)
        return false
    end
    return true
end
function LC.IsRegistered(ply) return not LC.IntakePending(ply) end

-- No room in this city yet, and one has to be asked for (or comes with the papers).
function LC.AwaitingHousing(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not cvOn:GetBool() or not Fresh(ply) or not Citizen(ply) then return false end
    if State(ply).room then return false end
    if not (LC.BlockNumbers and #LC.BlockNumbers() > 0) then return false end
    return LC.IntakePending(ply) or HasDesk("housing")
end

-- What the HUD needs to know.
local function Flags(ply)
    if not IsValid(ply) then return end
    local pending = LC.IntakePending(ply)
    ply:SetNW2Bool("lc_unreg", pending)
    ply:SetNW2Bool("lc_unhoused", not pending and LC.AwaitingHousing(ply))
    ply:SetNW2Bool("lc_unassigned", (not pending and LC.AwaitingLabor and LC.AwaitingLabor(ply)) and true or false)
end
LC.IntakeFlags = Flags

-- A brand-new person (sv_livingcity_character.lua, Assign).
function LC.IntakeNew(ply)
    if not IsValid(ply) then return end
    ply:SetPData("lc_intake", "1")
    ply:SetPData("lc_docs", "0") -- (no papers yet)
    ply.lcDocs = nil
    ply:RemovePData("lc_housed_how")
    local on = cvOn:GetBool()
    local desk = on and HasDesk("register")
    ply:SetPData("lc_registered", desk and "0" or "1")
    if on and (desk or HasDesk("housing")) then
        -- a new person has no room here until they're given one
        ply:RemovePData(BlockKey())
        ply:SetNW2Int("lc_block", 0)
    end
    ply.lcIntakeState = nil
    ply.lcIntakeSince = CurTime()
    ply.lcArrive = true -- (the next spawn is an arrival)
    if LC.LaborNew then LC.LaborNew(ply) end -- (a new person has never had a work assignment)
    if LC.TutorReset then LC.TutorReset(ply) end -- (a new person hasn't been searched: sv_livingcity_intaketutor.lua)
    Flags(ply)
end

------------------------------------------------------------------------
-- Being processed
------------------------------------------------------------------------

-- Their identity papers, in their pockets (if they don't already have them).
-- Ration cards are earned, a shift at a time (sv_livingcity_work.lua), never issued here.
function LC.IssueDocuments(ply)
    if not IsValid(ply) or not LC.GiveItem then return end
    if not LC.HasItem(ply, "id_papers") then LC.GiveItem(ply, "id_papers") end
    ply:SetPData("lc_docs", "1")
    ply.lcDocs = true
end
local function Documented(ply)
    if ply.lcDocs == nil then ply.lcDocs = ply:GetPData("lc_docs", "0") == "1" end
    return ply.lcDocs
end
LC.HasBeenIssuedPapers = Documented

-- A citizen with no ration card in their pockets: the dispensers say no (sv_livingcity_survival.lua).
-- (Civil Protection eat at their Commissary and need none.)
function LC.LacksRationCard(ply)
    return IsValid(ply) and ply:IsPlayer() and Papered(ply) and not LC.HasItem(ply, "ration_card")
end
function LC.RationCards(ply)
    return LC.Inventory and (LC.Inventory(ply).ration_card or 0) or 0
end

function LC.RegisterPerson(ply, how)
    if not IsValid(ply) then return false end
    Save(ply, "lc_registered", "1")
    ply.lcIntakeSince = nil
    LC.IssueDocuments(ply)
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    local cid = ply:GetNW2String("lc_cid", "")
    if how == "custody" then
        ply:ChatPrint(string.format("[Civil Intake] You were processed while in custody: %s, citizen %s. Your papers are in your pockets (F3). Ration cards come from work: each Union shift you finish earns one.", name, cid))
    else
        ply:ChatPrint(string.format("[Civil Intake] Registration complete. %s, citizen %s. Your identity papers are in your pockets (F3): keep them on you. Ration cards come from work: each Union shift you finish earns one.", name, cid))
    end
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    -- a Labor Assignment terminal in this city: work first, then a room (sv_livingcity_labor.lua)
    local labor = LC.AwaitingLabor and LC.AwaitingLabor(ply)
    if labor then
        ply:ChatPrint("[Civil Intake] Next, go to Labor Assignment to be given your Union work. It's marked on your screen.")
        if LC.WaypointTo then LC.WaypointTo(ply, "labor") end
    end
    if LC.AwaitingHousing(ply) and HasDesk("housing") then
        if labor then
            ply:ChatPrint("[Civil Intake] Then Housing Allocation gives you a room: it only houses citizens with a work assignment.")
        else
            ply:ChatPrint("[Civil Intake] Next, go to Housing Allocation to get a room. It's marked on your screen.")
            if LC.WaypointTo then LC.WaypointTo(ply, "housing") end
            if LC.Hint then LC.Hint(ply, "intake_housing") end
        end
    elseif n then
        ply:ChatPrint("[Civil Intake] You already have a room: " .. LC.BlockName(n) .. ". Ask at Housing Allocation if you want to know more.")
    elseif LC.AssignBlock then
        n = LC.AssignBlock(ply, false, true) -- (no housing desk here: a room comes with the papers)
        if n then
            ply:SetPData("lc_housed_how", "papers")
            ply:ChatPrint("[Civil Intake] You've been given a room in " .. LC.BlockName(n) .. ".")
        end
    end
    Flags(ply)
    hook.Run("LivingCityRegistered", ply, how)
    return true
end

-- The blocks, and how many people live in each.
local function Residents()
    local counts = {}
    for _, p in ipairs(player.GetAll()) do
        local n = LC.PlayerBlock and LC.PlayerBlock(p)
        if n then counts[n] = (counts[n] or 0) + 1 end
    end
    return counts
end

-- Which block they get: what they asked for if it isn't crowded (or their
-- standing is good), otherwise the least crowded. n, and whether the request
-- stood (nil: they didn't ask for one).
function LC.ChooseBlock(ply, pref, except)
    local blocks = LC.BlockNumbers and LC.BlockNumbers() or {}
    if #blocks == 0 then return nil end
    local counts = Residents()
    if except then counts[except] = (counts[except] or 1) - 1 end -- (they'd be leaving it)
    local least, leastN
    for _, b in ipairs(blocks) do
        if b ~= except and (not leastN or (counts[b] or 0) < least) then least, leastN = counts[b] or 0, b end
    end
    if not leastN then return nil end
    pref = tonumber(pref) or 0
    if pref > 0 and pref ~= except then
        for _, b in ipairs(blocks) do
            if b == pref then
                if (counts[b] or 0) <= least + 1 or (LC.Standing and LC.Standing(ply) >= GOOD_STANDING) then return b, true end
                return leastN, false
            end
        end
    end
    return leastN, nil
end

local function SetBlock(ply, n, how)
    ply:SetNW2Int("lc_block", n)
    ply:SetPData(BlockKey(), n)
    ply:SetPData("lc_housed_how", how)
    ply.lcIntakeState = nil
end

function LC.HousePerson(ply, pref)
    if not IsValid(ply) then return nil end
    local n, granted = LC.ChooseBlock(ply, pref)
    if n then
        SetBlock(ply, n, "allocation")
        if granted == false then
            ply:ChatPrint("[Housing Allocation] " .. LC.BlockName(tonumber(pref) or 0) .. " is full, so your request was declined. You've been given a room in " .. LC.BlockName(n) .. ".")
        end
        ply:ChatPrint("[Housing Allocation] Approved: a room in " .. LC.BlockName(n) .. ". It's marked on your screen. From now on, go home there when curfew starts.")
        if LC.WaypointTo then LC.WaypointTo(ply, "home") end
    else
        ply:ChatPrint("[Housing Allocation] This city has no rooms to give out.")
    end
    Flags(ply)
    hook.Run("LivingCityHoused", ply, n)
    return n
end

-- A housed citizen moving to another block.
function LC.CanTransfer(ply)
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    if not n then return false, "You have no room to move from." end
    if LC.Standing and LC.Standing(ply) < TRANSFER_STANDING then
        return false, "Transfers are for citizens in good standing (" .. TRANSFER_STANDING .. " or more)."
    end
    local wait = (tonumber(ply:GetPData("lc_transfer_at", 0)) or 0) + TRANSFER_WAIT - os.time()
    if wait > 0 then return false, string.format("You moved blocks too recently. Ask again in %d minutes.", math.ceil(wait / 60)), wait end
    return true
end

function LC.TransferPerson(ply, pref)
    local ok, why = LC.CanTransfer(ply)
    if not ok then ply:ChatPrint("[Housing Allocation] " .. why) return nil end
    local from = LC.PlayerBlock(ply)
    local n, granted = LC.ChooseBlock(ply, pref, from)
    if not n then ply:ChatPrint("[Housing Allocation] There's no other block to move you to.") return nil end
    if granted == false then
        ply:ChatPrint("[Housing Allocation] Transfer declined: " .. LC.BlockName(tonumber(pref) or 0) .. " is full, so you can't move there. You stay in " .. LC.BlockName(from) .. ".")
        return nil
    end
    SetBlock(ply, n, "transfer")
    ply:SetPData("lc_transfer_at", os.time())
    ply:ChatPrint("[Housing Allocation] Transfer approved: " .. LC.BlockName(from) .. " to " .. LC.BlockName(n) .. ". It's marked on your screen.")
    if LC.WaypointTo then LC.WaypointTo(ply, "home") end
    Flags(ply)
    hook.Run("LivingCityHoused", ply, n)
    return n
end

-- One person (or NPC) at a desk at a time.
local Busy = {} -- [terminal] = { who, untilT, form }
local function BusyWith(ent)
    local b = Busy[ent]
    if b and IsValid(b.who) and CurTime() < b.untilT then return b.who end
    Busy[ent] = nil
    return nil
end
local function Hold(ent, who, secs, form) Busy[ent] = { who = who, untilT = CurTime() + secs, form = form } end
local function Release(ent, who) if Busy[ent] and (who == nil or Busy[ent].who == who) then Busy[ent] = nil end end
LC.IntakeBusyWith = BusyWith

local Jobs = {} -- [ply] = { ent, what, untilT, beep }

local DOING = {
    register = { "Processing your registration", "[Civil Intake] Stand still next to the terminal while it registers you." },
    housing = { "Searching the housing register", "[Housing Allocation] Stand still next to the terminal while it finds you a room." },
    transfer = { "Processing your transfer request", "[Housing Allocation] Stand still next to the terminal while it processes your move." },
    papers = { "Printing your identity papers", "[Civil Intake] Stand still next to the terminal while it prints your new papers." },
    labor = { "Processing your work assignment", "[Labor Assignment] Stand still next to the terminal while it processes your assignment." },
}

local function Process(ply, ent, what, data)
    local secs = math.max(1, cvSecs:GetFloat() * (what == "papers" and 0.5 or 1))
    local now = CurTime()
    Jobs[ply] = { ent = ent, what = what, data = data or {}, untilT = now + secs, beep = now + 1.5 }
    Hold(ent, ply, secs + 2)
    ply:SetNW2Float("lc_intake_until", now + secs)
    ply:SetNW2Float("lc_intake_secs", secs)
    local d = DOING[what] or DOING.register
    ply:SetNW2String("lc_intake_doing", d[1])
    ent:EmitSound("buttons/combine_button1.wav", 65)
    ply:ChatPrint(d[2])
end

-- What the terminal does once it's worked on them.
local function Finish(ply, j)
    if j.what == "register" then LC.RegisterPerson(ply, "terminal")
    elseif j.what == "housing" then LC.HousePerson(ply, j.data.pref)
    elseif j.what == "transfer" then LC.TransferPerson(ply, j.data.pref)
    elseif j.what == "labor" then if LC.LaborFinish then LC.LaborFinish(ply, j.data) end
    elseif j.what == "papers" then
        local id, fee = "id_papers", cvPapersFee:GetInt()
        if LC.HasItem(ply, id) then return end
        if fee > 0 and LC.Credits and LC.Credits(ply) < fee then
            ply:ChatPrint("[Civil Intake] You don't have enough credits. New papers cost " .. fee .. ".")
            return
        end
        if fee > 0 and LC.AddCredits then LC.AddCredits(ply, -fee, "replacement " .. j.what) end
        LC.IssueDocuments(ply)
        ply:ChatPrint("[Civil Intake] New identity papers issued (" .. fee .. " credits). Keep them on you.")
    end
end

local function EndJob(ply, j)
    Jobs[ply] = nil
    if IsValid(ply) then
        ply:SetNW2Float("lc_intake_until", 0)
        ply:SetNW2String("lc_intake_doing", "")
    end
    if j and IsValid(j.ent) then Release(j.ent, ply) end
end

function LC.IntakeProcessing(ply) return Jobs[ply] ~= nil end

local QueueCount -- (below)

function LC.UseIntake(ply, ent)
    if not IsValid(ply) or not IsValid(ent) or not ply:Alive() then return end
    local now = CurTime()
    if (ply.lcIntakeNextUse or 0) > now then return end
    ply.lcIntakeNextUse = now + 0.8
    local kind = Kind(ent)
    local title = kind == "housing" and "[Housing Allocation] " or kind == "labor" and "[Labor Assignment] " or "[Civil Intake] "
    if kind == "labor" then
        -- Labor Assignment works whatever lc_intake is (it's the Union's desk: sv_livingcity_labor.lua)
        if Jobs[ply] then return end
        if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return ply:ChatPrint(title .. "This terminal assigns Union work to citizens.") end
        if not Papered(ply) then return ply:ChatPrint(title .. "This terminal is only for citizens.") end
        return LC.SendDesk(ply, ent)
    end
    if not cvOn:GetBool() then
        return ply:ChatPrint(title .. "The screen says CLOSED. In this city, new arrivals are registered automatically.")
    end
    if Jobs[ply] then return end -- (already being processed)
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then
        return ply:ChatPrint(title .. string.format("%d waiting in line.", QueueCount(ent)))
    end
    if not Papered(ply) then return ply:ChatPrint(title .. "This terminal is only for citizens.") end
    -- the registered (and anyone at Housing Allocation): the terminal's own screen
    if kind ~= "register" or not LC.IntakePending(ply) then return LC.SendDesk(ply, ent) end
    local who = BusyWith(ent)
    if who and who ~= ply then
        ent:EmitSound("buttons/combine_button_locked.wav", 60)
        return ply:ChatPrint(title .. "Processing another citizen. Wait your turn.")
    end
    if ply:GetPData("lc_chosen", "0") ~= "1" then
        -- the form first: who you are, entered into the terminal
        Hold(ent, ply, 240, true)
        ply.lcIntakeTerm = ent
        ent:EmitSound("buttons/combine_button1.wav", 60)
        if LC.OpenCharacterCreator then LC.OpenCharacterCreator(ply, { intake = true }) end
        return
    end
    return Process(ply, ent, "register")
end

------------------------------------------------------------------------
-- The terminals' screens: your record, the housing register
------------------------------------------------------------------------

function LC.SendDesk(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    ply.lcDeskEnt = ent
    local kind = Kind(ent)
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    local okT, whyT = LC.CanTransfer(ply)
    local t = {
        kind = kind, name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick(), cid = ply:GetNW2String("lc_cid", ""),
        pending = LC.IntakePending(ply), awaiting = LC.AwaitingHousing(ply), block = n or 0,
        blockName = n and LC.BlockName(n) or nil, how = ply:GetPData("lc_housed_how", ""),
        papers = LC.HasItem(ply, "id_papers"), cards = LC.RationCards(ply),
        credits = LC.Credits and LC.Credits(ply) or 0, standing = LC.Standing and LC.Standing(ply) or 0,
        papersFee = cvPapersFee:GetInt(), good = GOOD_STANDING, transferStanding = TRANSFER_STANDING,
        transfer = okT and true or false, transferWhy = whyT, housingDesk = HasDesk("housing"), blocks = {},
        needWork = (LC.AwaitingLabor and LC.AwaitingLabor(ply)) and true or false, laborDesk = HasDesk("labor"),
    }
    if kind == "labor" and LC.LaborDeskInfo then t.labor = LC.LaborDeskInfo(ply) end
    if kind == "housing" then
        local counts = Residents()
        for _, b in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
            local c = LC.BlockCenter and LC.BlockCenter(b)
            t.blocks[#t.blocks + 1] = { n = b, name = LC.BlockName(b), residents = counts[b] or 0,
                m = c and math.max(1, math.floor(c:Distance(ent:GetPos()) / 40 + 0.5)) or nil }
        end
    end
    LC.SendCompressed("lc_intake_ui", t, { ply })
    ent:EmitSound("buttons/combine_button1.wav", 55)
end

-- A button on a terminal's screen. True if the terminal took it on.
function LC.DeskAction(ply, ent, action, arg)
    if not IsValid(ply) or not IsValid(ent) or not ply:Alive() or Jobs[ply] then return false end
    local kind = Kind(ent)
    local title = kind == "housing" and "[Housing Allocation] " or kind == "labor" and "[Labor Assignment] " or "[Civil Intake] "
    local who = BusyWith(ent)
    if who and who ~= ply then
        ent:EmitSound("buttons/combine_button_locked.wav", 60)
        ply:ChatPrint(title .. "Processing another citizen. Wait your turn.")
        return false
    end
    if kind == "housing" and (action == "apply" or action == "transfer") then
        if LC.IntakePending(ply) then ply:ChatPrint(title .. "You're not registered. Register at Civil Intake first.") return false end
        if not LC.HasItem(ply, "id_papers") then
            ply:ChatPrint(title .. "Present your identity papers. You have none on you: Civil Intake can give you new ones.")
            return false
        end
        if action == "apply" then
            if not LC.AwaitingHousing(ply) then ply:ChatPrint(title .. "You already have a room. Ask for a transfer instead.") return false end
            if LC.AwaitingLabor and LC.AwaitingLabor(ply) then
                ply:ChatPrint(title .. "You have no work assignment, and the city only houses its workers. Go to Labor Assignment first: it's marked on your screen.")
                if LC.WaypointTo then LC.WaypointTo(ply, "labor") end
                return false
            end
            Process(ply, ent, "housing", { pref = tonumber(arg) or 0 })
            return true
        end
        local ok, why = LC.CanTransfer(ply)
        if not ok then ply:ChatPrint(title .. why) return false end
        Process(ply, ent, "transfer", { pref = tonumber(arg) or 0 })
        return true
    end
    if kind == "labor" and (action == "assign" or action == "choose") then
        if not LC.LaborCanAct then return false end
        local ok, why, jobId = LC.LaborCanAct(ply, action, arg)
        if not ok then
            if why then ply:ChatPrint(title .. why) end
            return false
        end
        Process(ply, ent, "labor", { job = jobId })
        return true
    end
    if kind == "register" and action == "card" then
        ply:ChatPrint(title .. "Ration cards aren't issued here. You earn one for each Union shift you finish.")
        return false
    end
    if kind == "register" and action == "papers" then
        if LC.IntakePending(ply) then return false end
        if LC.HasItem(ply, "id_papers") then ply:ChatPrint(title .. "You already have your papers on you.") return false end
        local fee = cvPapersFee:GetInt()
        if fee > 0 and LC.Credits and LC.Credits(ply) < fee then
            ply:ChatPrint(title .. "New papers cost " .. fee .. " credits, and you don't have enough.")
            return false
        end
        Process(ply, ent, action)
        return true
    end
    return false
end

local WAYS = { "intake", "housing", "home", "labor" }
net.Receive("lc_intake_act", function(_, ply)
    if not IsValid(ply) or (ply.lcDeskNext or 0) > CurTime() then return end
    ply.lcDeskNext = CurTime() + 0.5
    local action, arg = net.ReadString(), net.ReadInt(16)
    if action == "way" then
        if WAYS[arg] and LC.WaypointTo then LC.WaypointTo(ply, WAYS[arg]) end
        return
    end
    local ent = ply.lcDeskEnt
    if not IsValid(ent) or ply:GetPos():DistToSqr(ent:GetPos()) > (NEAR + 60) * (NEAR + 60) then
        return ply:ChatPrint("[Civil Intake] Go back and stand next to the terminal.")
    end
    LC.DeskAction(ply, ent, action, arg)
end)

-- The registration form, handed in (sv_livingcity_character.lua asks first).
function LC.IntakeFormCheck(ply, desc)
    local ent = ply.lcIntakeTerm
    if not IsValid(ent) then return true end
    if ply:GetPos():DistToSqr(ent:GetPos()) > (NEAR + 60) * (NEAR + 60) then
        return false, "Stand next to the terminal to fill in your details."
    end
    desc = string.Trim(tostring(desc or ""))
    if #desc < 8 then return false, "Describe yourself: what a stranger would notice about you (at least 8 characters)." end
    if #desc > 120 then return false, "Your description is too long (120 characters at most)." end
    return true
end

hook.Add("LivingCityCharacterChosen", "LivingCityIntake", function(ply)
    local ent = ply.lcIntakeTerm
    ply.lcIntakeTerm = nil
    if not IsValid(ent) or not LC.IntakePending(ply) then return end
    Release(ent, ply)
    Process(ply, ent, "register")
end)

util.AddNetworkString("lcc_cancel")
net.Receive("lcc_cancel", function(_, ply)
    local ent = ply.lcIntakeTerm
    ply.lcIntakeTerm = nil
    if IsValid(ent) then Release(ent, ply) end
end)

-- The creator waits for the desk: the form is filled in there.
function LC.IntakeDefersCreator(ply) return LC.IntakePending(ply) end

timer.Create("LivingCityIntake", 0.25, 0, function()
    local now = CurTime()
    for ply, j in pairs(Jobs) do
        if not IsValid(ply) or not ply:Alive() or not IsValid(j.ent) then
            EndJob(ply, j)
        elseif ply:GetPos():DistToSqr(j.ent:GetPos()) > NEAR * NEAR then
            j.ent:EmitSound("buttons/combine_button_locked.wav", 65)
            ply:ChatPrint((j.what == "labor" and "[Labor Assignment]" or "[Civil Intake]") .. " You walked away from the terminal, so it stopped. Go back to it to carry on.")
            EndJob(ply, j)
        elseif now >= j.untilT then
            EndJob(ply, j)
            j.ent:EmitSound("buttons/combine_button3.wav", 70)
            Finish(ply, j)
        elseif now >= j.beep then
            j.beep = now + 2
            j.ent:EmitSound("buttons/blip1.wav", 55, 110)
        end
    end
    -- a form left open, or walked away from
    for ent, b in pairs(Busy) do
        if b.form and (not IsValid(b.who) or not IsValid(ent) or now > b.untilT
            or b.who:GetPos():DistToSqr(ent:GetPos()) > (NEAR + 120) * (NEAR + 120)) then
            Busy[ent] = nil
            if IsValid(b.who) and b.who.lcIntakeTerm == ent then b.who.lcIntakeTerm = nil end
        end
    end
end)

timer.Create("LivingCityIntakeFlags", 1, 0, function()
    for _, p in ipairs(player.GetAll()) do Flags(p) end
end)

------------------------------------------------------------------------
-- Arriving
------------------------------------------------------------------------

local function ArrivalSpots()
    local pts = LC.PointsOfKind and LC.PointsOfKind("arrival") or {}
    if #pts == 0 and LC.TrainPlatforms then pts = LC.TrainPlatforms() end
    return pts
end
LC.ArrivalSpots = ArrivalSpots

hook.Add("PlayerSpawn", "LivingCityIntake", function(ply)
    local first = not ply.lcIntakeSeenSpawn
    ply.lcIntakeSeenSpawn = true
    local pending = LC.IntakePending(ply)
    -- on the register, but never handed their papers (everyone from before they were things you carry)
    if not pending and Papered(ply) and not Documented(ply) then
        timer.Simple(1, function()
            if not IsValid(ply) or Documented(ply) or LC.IntakePending(ply) or not Papered(ply) then return end
            LC.IssueDocuments(ply)
            ply:ChatPrint("[Papers] Your identity papers are in your pockets (F3). Keep them on you: Civil Protection units ask for them.")
        end)
    end
    -- a new arrival (or someone still not registered) steps off where arrivals do, in a city with the desks
    local arriving = pending or (ply.lcArrive and cvOn:GetBool() and HasDesk("housing") and LC.AwaitingHousing(ply))
    if not arriving then
        ply.lcArrive = nil
        Flags(ply)
        return
    end
    if pending then ply.lcIntakeSince = ply.lcIntakeSince or CurTime() end
    timer.Simple(0.15, function() -- (after the factions have put them where they spawn)
        if not IsValid(ply) or not ply:Alive() then return end
        if LC.Prisoners and LC.Prisoners[ply] then return end
        local pts = ArrivalSpots()
        if #pts > 0 then
            local p = pts[math.random(#pts)]
            local pos = p.pos + Vector(0, 0, 8)
            for _ = 1, 6 do
                local try = p.pos + Vector(math.Rand(-60, 60), math.Rand(-60, 60), 8)
                if not LC.ClearSpot or LC.ClearSpot(try) then pos = try break end
            end
            ply:SetPos(pos)
            if ply.SetEyeAngles then ply:SetEyeAngles(Angle(0, p.yaw or 0, 0)) end
        end
        Flags(ply)
        if ply.lcArrive then
            ply.lcArrive = nil
            if LC.IntakePending(ply) then
                ply:ChatPrint("[Civil Intake] You've arrived in the city with nothing: no papers and no room. Report to Civil Intake to register. Your screen shows the way.")
            else
                ply:ChatPrint("[Housing Allocation] You have nowhere to sleep yet. Go to Housing Allocation and ask for a room. Your screen shows the way.")
            end
            if not first and LC.AnnounceWelcome then LC.AnnounceWelcome(ply) end -- (someone joining hears it anyway)
        end
    end)
end)

-- Someone arrested before they registered is processed in custody.
hook.Add("LivingCityReleased", "LivingCityIntake", function(ply)
    if IsValid(ply) and ply:IsPlayer() and LC.IntakePending(ply) then LC.RegisterPerson(ply, "custody") end
end)

-- A unit who stops someone with no papers (sv_livingcity_underground.lua).
-- True: dealt with here (no search).
function LC.IntakeStopped(ply, cop)
    if not LC.IntakePending(ply) then
        -- on the register: are they carrying their papers?
        if IsValid(ply) and ply:IsPlayer() and Papered(ply) and Documented(ply) and not LC.HasItem(ply, "id_papers") and not ply.lcIdentity then
            ply:ChatPrint("[Civil Protection] Papers. None? Carry them at all times. Civil Intake replaces lost papers.")
            if LC.AddStanding then LC.AddStanding(ply, -2, "no papers on them") end
        end
        return false
    end
    local since = ply.lcIntakeSince or CurTime()
    if CurTime() - since < cvGrace:GetFloat() * 60 then
        if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/movealong.wav", 75) end
        ply:ChatPrint("[Civil Protection] No papers. New arrival? Report to Civil Intake. Now.")
        return false -- (and they're searched like anyone)
    end
    if IsValid(cop) then cop:EmitSound("npc/metropolice/vo/prepareforjudgement.wav", 78) end
    ply:ChatPrint("[Civil Protection] Still no papers. Failure to register.")
    if LC.ReportCrime then LC.ReportCrime(ply, "Failure to register", 120) end
    return true
end

-- A unit's own search finds no papers.
hook.Add("LivingCitySearched", "LivingCityIntake", function(searcher, target)
    if not (IsValid(searcher) and searcher:IsPlayer() and IsValid(target) and target:IsPlayer()) then return end
    if LC.IntakePending(target) then
        searcher:ChatPrint("[Records] No papers, and not registered: a new arrival who has to register at Civil Intake.")
    elseif Papered(target) and Documented(target) and not LC.HasItem(target, "id_papers") and not target.lcIdentity then
        searcher:ChatPrint("[Records] Registered, but not carrying their papers.")
    end
end)

-- Curfew (sv_livingcity_events.lua): someone with no room yet isn't out of
-- bounds waiting near the desks or where they arrived.
function LC.IntakeShelter(ply)
    if not LC.AwaitingHousing(ply) then return false end
    local pos = ply:GetPos()
    for _, kind in ipairs({ "intake", "housingterm", "laborterm", "arrival", "platform" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            if p.pos:DistToSqr(pos) < SHELTER * SHELTER then return true end
        end
    end
    return false
end

------------------------------------------------------------------------
-- The line in front of each desk (NPC arrivals off the train)
------------------------------------------------------------------------

local Queues = {} -- [terminal] = { npc, npc, ... }

local function Clean(ent)
    local q = Queues[ent]
    if not q then return {} end
    for i = #q, 1, -1 do
        local n = q[i]
        local st = LC.NPCs and LC.NPCs[n]
        if not IsValid(n) or not st or not st.npcWork or st.npcWork.id ~= "arrival" then table.remove(q, i) end
    end
    return q
end

function QueueCount(ent) return #Clean(ent) end
LC.IntakeQueue = function(ent) return Clean(ent) end

local function Place(ent, n)
    local q = Clean(ent)
    for i, x in ipairs(q) do if x == n then return i end end
    q[#q + 1] = n
    Queues[ent] = q
    return #q
end

local function Leave(ent, n)
    local q = Queues[ent]
    if not q then return end
    for i = #q, 1, -1 do if q[i] == n then table.remove(q, i) end end
end

-- Where the i-th person in line stands: straight out from the screen.
function LC.IntakeQueueSpot(ent, i)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local k = math.min(i, QUEUE_SLOTS)
    local pos = ent:LocalToWorld(Vector((maxs and maxs.x or 16) + 30 + (k - 1) * QUEUE_GAP, 0, (mins and mins.z or 0) + 4))
    if i > QUEUE_SLOTS then pos = pos + Vector(math.Rand(-30, 30), math.Rand(-30, 30), 0) end
    return LC.GroundAt and LC.GroundAt(pos) or pos
end

local function Nearest(pos, kind)
    local best, bd
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_intake") or {}) do
        if IsValid(e) and Kind(e) == kind then
            local d = e:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end
LC.NearestIntake = Nearest

local BEEP = { "buttons/blip1.wav", "buttons/combine_button1.wav" }

local function QueueSteps(steps, ent, waiting, doing)
    -- in line, one place further up each time the front moves
    steps[#steps + 1] = {
        pos = function(n) return LC.IntakeQueueSpot(ent, Place(ent, n)) end,
        face = function() return IsValid(ent) and ent:GetPos() or nil end,
        check = function() return IsValid(ent) end,
        secs = 2, doing = waiting,
        done = function(n, s, w)
            w.data.since = w.data.since or CurTime()
            local q = Clean(ent)
            local free = BusyWith(ent) == nil
            if (q[1] ~= n or not free) and CurTime() - w.data.since < QUEUE_WAIT then
                w.i = w.i - 1 -- (not yet: the same step again)
            elseif q[1] ~= n then
                Leave(ent, n) -- (waited long enough; another day)
                w.data.skip = true
            end
        end,
    }
    -- at the desk
    steps[#steps + 1] = {
        pos = function(n, s, w) if w.data.skip then return n:GetPos() end return LC.IntakeQueueSpot(ent, 1) end,
        face = function() return IsValid(ent) and ent:GetPos() or nil end,
        check = function() return IsValid(ent) end,
        secs = math.max(1, cvSecs:GetFloat()), doing = doing, sound = BEEP, lvl = 55, every = 2.5,
        onArrive = function(n, s, w)
            if w.data.skip then s.untilT = CurTime() return end
            Hold(ent, n, cvSecs:GetFloat() + 3)
        end,
        done = function(n, s, w)
            w.data.since, w.data.skip = nil, nil
            Leave(ent, n)
            Release(ent, n)
            if IsValid(ent) then ent:EmitSound("buttons/combine_button3.wav", 60) end
        end,
    }
end

-- The steps a new arrival takes at the desks before going home (empty when
-- there are none, or intake is off).
function LC.IntakeSteps(npc)
    local steps = {}
    if not cvOn:GetBool() or not IsValid(npc) then return steps end
    local reg = Nearest(npc:GetPos(), "register")
    if reg then QueueSteps(steps, reg, "in line at Civil Intake", "being registered at Civil Intake") end
    local house = Nearest(npc:GetPos(), "housing")
    if house then QueueSteps(steps, house, "in line for Housing Allocation", "waiting on a housing allocation") end
    return steps
end

------------------------------------------------------------------------
-- Settings changing, the layout changing
------------------------------------------------------------------------

local function Recheck()
    for _, p in ipairs(player.GetAll()) do
        Flags(p)
        if LC.AssignBlock and not (LC.PlayerBlock and LC.PlayerBlock(p)) and not LC.AwaitingHousing(p) then LC.AssignBlock(p) end
    end
end
LC.IntakeRecheck = Recheck

if cvars and cvars.AddChangeCallback then
    cvars.AddChangeCallback("lc_intake", function() timer.Simple(0, Recheck) end, "LivingCityIntake")
end
hook.Add("LivingCityLayoutChanged", "LivingCityIntake", function() timer.Simple(0.5, Recheck) end)

hook.Add("PlayerDisconnected", "LivingCityIntake", function(ply)
    local j = Jobs[ply]
    if j then EndJob(ply, j) end
    for ent, b in pairs(Busy) do if b.who == ply then Busy[ent] = nil end end
end)

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

-- What their papers say: their own, or the forged ones they're living under.
function LC.PapersInfo(ply)
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    local t = {
        name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick(), cid = ply:GetNW2String("lc_cid", ""),
        block = n and LC.BlockName(n) or (LC.AwaitingHousing(ply) and "None yet (ask Housing Allocation)" or "None on file"),
        desc = ply:GetNW2String("lc_desc", ""), cards = LC.RationCards(ply),
        model = ply:GetModel(),
        stalker = (LC.PlayerIsStalker and LC.PlayerIsStalker(ply)) or nil, -- (stamped across: Combine property)
        model = (LC.ModelCitizen and LC.ModelCitizen(ply)) or nil, -- (stamped: MODEL CITIZEN, sv_livingcity_loyalty.lua)
    }
    local id = LC.Identity and LC.Identity(ply)
    if id and id.alias then
        t.name, t.cid, t.forged = "Citizen " .. id.alias, id.alias, true
    end
    return t
end

local function SendCard(to, info, from)
    info.from = from
    LC.SendCompressed("lc_papers_card", info, { to })
end

-- Show your papers to whoever you're looking at (or read them yourself).
function LC.ShowPapers(ply)
    if not IsValid(ply) then return false end
    if LC.IntakePending(ply) then return false, "[Papers] You have none. Report to Civil Intake to register." end
    local has = LC.HasItem(ply, "id_papers") or ply.lcIdentity ~= nil
    if not has then return false, "[Papers] You have no papers on you. Civil Intake can give you new ones." end
    local tr = ply:GetEyeTrace()
    local other = tr and tr.Entity
    local info = LC.PapersInfo(ply)
    if IsValid(other) and other:IsPlayer() and other:GetPos():DistToSqr(ply:GetPos()) < 130 * 130 then
        SendCard(other, info, true)
        other:ChatPrint(string.format("[Papers] They show you their papers: %s, citizen %s.", info.name, info.cid))
        if not info.forged and LC.Introduce then LC.Introduce(ply, other) end -- (now they know the name: sv_livingcity_rp.lua)
        ply:ChatPrint("[Papers] You hold your papers up for them to see.")
        ply:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 55)
        hook.Run("LivingCityShowedPapers", ply, other)
        return true
    end
    SendCard(ply, info, nil)
    return true
end

local function Papers(ply)
    if LC.IntakePending(ply) then
        ply:ChatPrint("[Papers] You have none. Report to Civil Intake to register.")
        return
    end
    local info = LC.PapersInfo(ply)
    local carrying = LC.HasItem(ply, "id_papers")
    ply:ChatPrint(string.format("[Papers] %s, citizen %s. Housing: %s.%s", info.name, info.cid, info.block,
        carrying and "" or " (Your papers aren't on you: Civil Intake replaces them.)"))
    if carrying or ply.lcIdentity then SendCard(ply, info, nil) end
end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.papers = Papers
LC.SlashCommands.showpapers = function(ply)
    local ok, why = LC.ShowPapers(ply)
    if not ok and why then ply:ChatPrint(why) end
end

hook.Add("PlayerSay", "LivingCityIntakeChat", function(ply, text)
    if string.lower(string.Trim(text)) == "!papers" then Papers(ply) return "" end
end)

local function AdminTarget(ply, args, usage)
    if IsValid(ply) and not ply:IsAdmin() then return nil end
    local target = LC.FindPlayer and LC.FindPlayer(args[1])
    if not target then
        if IsValid(ply) then ply:ChatPrint(usage) else print(usage) end
        return nil
    end
    return target
end

concommand.Add("lc_register", function(ply, _, args)
    local target = AdminTarget(ply, args, "[Living City] Usage: lc_register <name>")
    if not target then return end
    target:SetPData("lc_chosen", "1") -- (whatever name they have now is the one on file)
    LC.RegisterPerson(target, "staff")
end)

concommand.Add("lc_unregister", function(ply, _, args)
    local target = AdminTarget(ply, args, "[Living City] Usage: lc_unregister <name> (sends them back through Civil Intake)")
    if not target then return end
    target:SetPData("lc_intake", "1")
    Save(target, "lc_registered", "0")
    -- all of it: no papers, no card, no room
    for _, id in ipairs({ "id_papers", "ration_card" }) do
        if LC.HasItem(target, id) and LC.TakeItem then LC.TakeItem(target, id, LC.Inventory(target)[id]) end
    end
    target:SetPData("lc_docs", "0")
    target.lcDocs = nil
    target:RemovePData(BlockKey())
    target:RemovePData("lc_housed_how")
    target:SetNW2Int("lc_block", 0)
    target.lcIntakeState = nil
    target.lcIntakeSince = CurTime()
    Flags(target)
    target:ChatPrint("[Living City] Staff have unregistered you. Register again at Civil Intake, then ask Housing Allocation for a room.")
end)
