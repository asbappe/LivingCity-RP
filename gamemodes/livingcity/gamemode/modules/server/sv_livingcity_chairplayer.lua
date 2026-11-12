--[[
    Living City (server): a player prisoner in the Resistance's interrogation chair

    From the cage's quick menu a Fighter or above sends a held player to a free
    chair near it. The one asking has the chair's usual menu; each question goes
    to the prisoner as a quick menu of their own: the truth, a lie, or nothing.
    The asker hears an answer, never which it was (a lie is sometimes seen
    through). The truth comes from the chronicle: what that player really did,
    or saw. Blows hurt, and stop short of killing. Then back to the cage, or out.
]]

LC = LC or {}

local STAY, SESSION, MAX_HITS, ANSWER_SECS = 320, 240, 6, 20

LC.ChairPlayers = LC.ChairPlayers or {} -- chair -> { chair, ply, asker, from, hits, at, told, q }
local S = LC.ChairPlayers

if util.AddNetworkString then
    util.AddNetworkString("lc_chair_q")
    util.AddNetworkString("lc_chair_a")
end

local LIES = { "they've done nothing but queue for rations and keep their head down", "they saw a unit take a man off the ration line, and nothing since",
    "they were at their work shift the whole time, ask anyone", "they heard shots two streets over and went home" }
local SILENT = { "They say nothing. The lamp hums.", "They look at the floor.", "Nothing. Not a word." }

local function Roll() return LC.PatdownRoll and LC.PatdownRoll() or math.random() end
local function Pick(t) return t[math.random(#t)] end
local function Key(p) return LC.MindsWhoKey and LC.MindsWhoKey(p) or nil end
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < 600 * 600 then ply:ChatPrint("** " .. text) end
    end
end

function LC.ChairPlayerOf(ply)
    for _, s in pairs(S) do if s.ply == ply then return s end end
    return nil
end

local function SendMenu(s, said)
    if not IsValid(s.asker) then return end
    net.Start("lc_chair")
    net.WriteEntity(s.chair)
    net.WriteString(s.ply:Nick())
    net.WriteString(said or "")
    net.WriteUInt(s.hits, 4)
    net.WriteUInt(MAX_HITS, 4)
    net.WriteBool(s.from ~= nil and IsValid(s.from.cage))
    net.WriteBool(true) -- (a player: no kind options, they speak for themselves)
    net.Send(s.asker)
end

-- Out of the chair. how: "cage" (back to it), "free" (let go, uncuffed), nil (only forgotten).
local function End(s, how)
    S[s.chair] = nil
    local ply, chair = s.ply, s.chair
    if IsValid(chair) then
        if chair.SetLamp then chair:SetLamp(false) end
        chair:SetNW2Entity("lc_chair_sitter", NULL)
    end
    if IsValid(s.asker) then net.Start("lc_chair") net.WriteEntity(NULL) net.Send(s.asker) end
    if not IsValid(ply) then return end
    ply:Freeze(false)
    ply:SetNW2Entity("lc_chair_in", NULL)
    net.Start("lc_chair_q") net.WriteEntity(NULL) net.WriteString("") net.Send(ply)
    if not ply:Alive() then return end
    if how == "cage" and s.from and IsValid(s.from.cage) and LC.CagePutPlayer and LC.IsTied(ply) then
        if LC.CagePutPlayer(ply, s.from.cage, s.asker) and LC.RebelHeldPly[ply] then LC.RebelHeldPly[ply].at = s.from.at or CurTime() end
    elseif how == "free" then
        if LC.IsTied(ply) then LC.Untie(ply, nil, true) end
        ply:ChatPrint("[Miscount] They cut you loose and point at the door. 'Go.'")
    end
end
function LC.ChairPlayerEnd(ply) local s = LC.ChairPlayerOf(ply) if s then End(s) end end

-- From the cage's menu: this held player to a free chair near it. Returns what's said.
function LC.ChairPlayerTake(by, ply, cage)
    local h = LC.RebelHeldPly and LC.RebelHeldPly[ply]
    if not h or h.cage ~= cage or not (LC.RebelMayHold and LC.RebelMayHold(by)) then return nil end
    local chair = LC.ChairNear and LC.ChairNear(cage:GetPos())
    if not IsValid(chair) then return "There's no free chair near enough." end
    local from = { cage = cage, at = h.at }
    LC.CageFreePlayer(ply)
    local s = { chair = chair, ply = ply, asker = by, from = from, hits = 0, at = CurTime(), told = {} }
    S[chair] = s
    ply:SetPos(chair:GetPos() + Vector(0, 0, 4))
    ply:SetEyeAngles(Angle(0, chair:GetAngles().y, 0))
    ply:SetLocalVelocity(Vector(0, 0, 0))
    ply:Freeze(true)
    ply:SetNW2Entity("lc_chair_in", chair)
    if chair.SetLamp then chair:SetLamp(true) end
    chair:SetNW2Entity("lc_chair_sitter", ply)
    Scene(chair:GetPos(), ply:Nick() .. " is pushed down into the chair. The lamp comes on.")
    ply:ChatPrint("[Miscount] The chair. The lamp is all you can see. They will ask, and what you answer is yours to choose.")
    local key, okey = Key(by), Key(ply)
    if key and okey and LC.ChronicleAdd then LC.ChronicleAdd({ k = "chair", s = key, o = okey, pred = "put " .. ply:Nick() .. " in the chair", pos = chair:GetPos(), w = 3 }) end
    SendMenu(s, "They squint up at you through the light.")
    return "To the chair with them."
end

-- The prisoner's answer: "truth", "lie" or "silent". Returns what the asker hears.
function LC.ChairPlayerAnswer(ply, how)
    local s = LC.ChairPlayerOf(ply)
    if not s or not s.q then return nil end
    local what = s.q
    s.q, s.qAt = nil, nil
    local said
    if how == "truth" then
        local e = LC.ChronicleKnows and LC.ChronicleKnows(Key(ply), what, s.told)
        if e then
            s.told[e.n] = true
            said = (what == "done" and "It comes out of them: " or "They saw something: ") .. e.sn .. " " .. e.pred .. "."
        else
            said = "'There's nothing. I swear it.' They hold your eye."
        end
    elseif how == "lie" then
        said = (what == "done" and "It comes out of them: " or "They saw something: ") .. Pick(LIES) .. "."
        if Roll() < 0.35 + 0.05 * s.hits then said = said .. " Their eyes slide off yours. You don't believe it." end
    else
        said = Pick(SILENT)
    end
    SendMenu(s, said)
    return said
end

net.Receive("lc_chair_a", function(_, ply) LC.ChairPlayerAnswer(ply, net.ReadString()) end)

-- The asker's menu. Returns what's said (the menu is sent again by whoever called).
function LC.ChairPlayerDo(by, chair, what)
    local s = IsValid(chair) and S[chair]
    if not s or s.asker ~= by or not IsValid(s.ply) then return nil end
    local ply = s.ply
    if what == "free" then
        Scene(chair:GetPos(), ply:Nick() .. " is let out of the chair.")
        End(s, "free")
        return "You let them go."
    elseif what == "cage" then
        Scene(chair:GetPos(), ply:Nick() .. " is pulled out of the chair and marched back to the cage.")
        End(s, "cage")
        return "Back to the cage with them."
    elseif what == "hit" then
        if s.hits >= MAX_HITS then return "Any more and you'd kill them." end
        s.hits = s.hits + 1
        ply:SetHealth(math.max(10, ply:Health() - 12))
        ply:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
        if ply.ViewPunch then ply:ViewPunch(Angle(-8, math.random(-6, 6), 0)) end
        ply:ChatPrint("[Miscount] A fist. The light swims.")
        if LC.RebelAgainstRules then LC.RebelAgainstRules(by, "brutal", ply:Nick()) end
        return "You hit them. Their head snaps to the side."
    elseif what == "done" or what == "seen" then
        if s.q then return "You've asked. They're taking their time." end
        s.q, s.qAt = what, CurTime()
        net.Start("lc_chair_q")
        net.WriteEntity(chair)
        net.WriteString(what == "done" and "'What have you done? All of it.'" or "'What have you seen? Names.'")
        net.Send(ply)
        return "You ask. They take their time."
    elseif what == "execute" or what == "askleave" or what == "execnoleave" then
        return LC.RebelExecDo and LC.RebelExecDo(by, ply, what) or nil
    end
    return nil
end

-- E on a chair with a player in it (sv_livingcity_chair.lua hands it over). true: handled.
function LC.ChairPlayerUse(by, chair)
    local s = S[chair]
    if not s then return false end
    if not (LC.RebelMayHold and LC.RebelMayHold(by)) then by:ChatPrint("[Miscount] This is none of your business. Walk on.") return true end
    if s.asker ~= by and (not IsValid(s.asker) or s.asker:GetPos():DistToSqr(chair:GetPos()) > STAY * STAY) then s.asker = by end
    if s.asker ~= by then by:ChatPrint("[Miscount] Someone else is asking the questions.") return true end
    SendMenu(s, "They squint up at you through the light.")
    return true
end

function LC.ChairPlayerTick(now)
    now = now or CurTime()
    for chair, s in pairs(S) do
        local ply = s.ply
        if not IsValid(chair) or not IsValid(ply) or not ply:Alive() then End(s)
        elseif not LC.IsTied(ply) then End(s)
        else
            if s.q and now - (s.qAt or now) > ANSWER_SECS then LC.ChairPlayerAnswer(ply, "silent") end
            local near = IsValid(s.asker) and s.asker:GetPos():DistToSqr(chair:GetPos()) < STAY * STAY
            if near then s.farSince = nil else s.farSince = s.farSince or now end
            if now - s.at > SESSION or (s.farSince and now - s.farSince > 20) then End(s, s.from and IsValid(s.from.cage) and "cage" or "free") end
        end
    end
end
if timer and timer.Create then timer.Create("LivingCityChairPlayers", 1, 0, function() LC.ChairPlayerTick(CurTime()) end) end

hook.Add("PlayerDisconnected", "LivingCityChairPlayers", function(ply) LC.ChairPlayerEnd(ply) end)
