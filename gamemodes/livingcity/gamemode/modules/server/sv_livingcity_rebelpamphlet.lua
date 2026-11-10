--[[
    Living City: the Resistance pamphlet

    The owner, 10 November: a pamphlet "resistance members can either give to
    sympathisers or leave about on purpose for people to find".

    THE ITEM "rebel_pamphlet": a cheap sheet run off by hand. Contraband. The
    quartermaster sells five for 15 credits. Pockets > Read opens it as the
    sheet itself (cl_livingcity_dialog.lua, style "rebelpamphlet"; the paper is
    materials/livingcity/pamphlet/rebel_paper.jpg, made by
    _dev/posters/rebelpamphlet.js). Its words are LC.RebelPamphletPages below:
    the Resistance's answer to the Civil Orientation pamphlet, and true to how
    the city works (how a citizen earns the Resistance's trust).

    HANDING IT OVER
      to a player     F1 > their name > Hand them a Resistance pamphlet (or
                      Pockets > Give, as with anything).
      to a citizen    F1 > This person > Hand them a Resistance pamphlet. A
                      sympathiser takes it. Anyone else may take it and become
                      one, may tuck it away, or may push it back. An informant
                      takes it too, and Civil Protection hears of it soon after.

    LEAVING IT      F1 > Leave a Resistance pamphlet here (Resistance), or the
                    "Leave it here" button on the sheet (anyone holding one):
                    it lies on the floor, bench or table in front of you
                    (entity lc_rebelpamphlet). Anyone presses E on it to read
                    it, and may pocket it; Civil Protection may confiscate it.
                    Citizens walking past sometimes read it (three readers and
                    someone has carried it off; a reader may become a
                    sympathiser), and a unit walking past takes it away. One
                    player can have lc_rebel_pamphlets_max (6) lying about; each
                    lasts lc_rebel_pamphlet_minutes (30).

    Seen by a unit handing one over or leaving one: a crime, as with a paste-up.
    The first one a citizen ever reads is worth 1 sympathy.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMax = CreateConVar("lc_rebel_pamphlets_max", "6", FLAGS, "Resistance pamphlets one player can have lying about at once (the oldest goes)")
local cvLife = CreateConVar("lc_rebel_pamphlet_minutes", "30", FLAGS, "Minutes a Resistance pamphlet left lying about stays there")

local ITEM = "rebel_pamphlet"
local CRIME = "Distributing seditious material"

local COVER = "READ THIS\n\nYou were not brought here for your protection. You were brought here to be counted, worked and kept quiet. Everything in their pamphlet is true, and none of it is the truth. This one is ours. Read it where they can't see you.\n\nA friend"

-- id, the page's title, the page.
LC.RebelPamphletPages = {
    { "water", "The water",
      "They put something in the water. It doesn't hurt. It helps you forget: what year it is, who lived next door, what you were angry about. If there are mornings you can't account for, that is why. Drink what you have collected yourself, when you can." },
    { "rations", "The ration",
      "A ration is not a gift. It is a leash, and it is exactly as long as they want it to be. Count what a shift pays you and what a day costs you. It never quite covers it. That isn't a mistake." },
    { "watchers", "Who is listening",
      "Some of your neighbours inform. They aren't monsters. They're hungry, and it pays. Say nothing in a queue that you wouldn't say to a mask. The flying cameras take pictures: keep your head down and your hands empty." },
    { "stopped", "If they stop you",
      "Don't run. Running is the one thing they are always ready for. Show your papers and say little. Whatever you carry that you shouldn't, carry it deep, or don't carry it. They can't search what they have no reason to look for." },
    { "help", "If you want to help",
      "You don't have to fight. Leave food in our supply crates. Sell what you find to our quartermaster. Do a job for us when one is offered. Keep quiet about what you see. We notice who helps. When we have seen enough, we will come and ask you." },
    { "pass", "Pass it on",
      "This sheet is worth a beating. Don't keep it and don't burn it. Leave it where the next person will find it: a bench, a stairwell, a ration queue. One sheet read by five people is five people who know they aren't alone." },
}

LC.RebelPamphlets = LC.RebelPamphlets or {} -- the ones lying about, oldest first

local function Combine(ply)
    if ply:GetNW2String("lcf_faction", "") == "cp" then return true end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return true end
    return LC.IsAdministrator ~= nil and LC.IsAdministrator(ply) == true
end
local function Member(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end
local function Roll() return LC.RebelPamphletRoll and LC.RebelPamphletRoll() or math.random() end

-- Caught at it, or (a member, unseen) a little XP.
local function Risk(ply, xp)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        if LC.ReportCrime then LC.ReportCrime(ply, CRIME, 120) end
        ply:ChatPrint("[Civil Protection] A Civil Protection unit saw that.")
        return true
    end
    if xp and xp > 0 and Member(ply) and LC.AddXP then LC.AddXP(ply, xp, "pamphlets") end
    return false
end

------------------------------------------------------------------------
-- Reading it
------------------------------------------------------------------------

local function Near(ply, ent) return IsValid(ent) and ent.lcRebelPamphlet and ply:GetPos():DistToSqr(ent:GetPos()) < 200 * 200 end

local function Pages(ply, ent, text)
    local opts = {}
    for _, t in ipairs(LC.RebelPamphletPages) do opts[#opts + 1] = { t[1], t[2] } end
    if IsValid(ent) then
        opts[#opts + 1] = Combine(ply) and { "_seize", "Confiscate it" } or { "_take", "Pocket it" }
    else
        opts[#opts + 1] = { "_leave", "Leave it here" }
    end
    LC.OpenDialog(ply, "rebelpamphlet", IsValid(ent) and ent or nil, { title = "Resistance pamphlet", sub = "Cheap paper. The purple ink comes off on your fingers.",
        text = text, options = opts, style = "rebelpamphlet" })
end

-- The first one a citizen ever reads stays with them.
local function FirstRead(ply, ent)
    if Combine(ply) or Member(ply) or ply:GetPData("lc_rpamphlet_read", "0") == "1" then return end
    ply:SetPData("lc_rpamphlet_read", "1")
    if LC.AddTrait then LC.AddTrait(ply, "sympathy", 1) end
    ply:ChatPrint("Some of it stays with you. (Sympathy +1: the Resistance notices who listens.)")
    local sid = IsValid(ent) and ent.lcOwnerSid
    if not sid then return end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:SteamID() == sid then
            p:ChatPrint("[Resistance] Someone new has read one of your pamphlets.")
            if Member(p) and LC.AddXP then LC.AddXP(p, 2, "pamphlets") end
        end
    end
end

-- From the pockets (ent nil), or one lying about.
function LC.ReadRebelPamphlet(ply, ent)
    if not IsValid(ply) or not LC.OpenDialog then return false end
    if ent ~= nil then
        if not Near(ply, ent) then return false end
    elseif not LC.HasItem(ply, ITEM) then
        return false
    end
    Pages(ply, ent, COVER)
    FirstRead(ply, ent)
    hook.Run("LivingCityPamphletRead", ply, ent)
    return true
end

LC.DialogHandlers = LC.DialogHandlers or {}
LC.DialogHandlers.rebelpamphlet = function(ply, ent, id)
    local lying = ent ~= nil and ent ~= NULL
    if lying then
        if not Near(ply, ent) then return end
    elseif not LC.HasItem(ply, ITEM) then
        return
    end
    if id == "_leave" and not lying then
        local ok, why = LC.LeaveRebelPamphlet(ply)
        if not ok and why then ply:ChatPrint(why) end
        if ok and LC.CloseDialog then LC.CloseDialog(ply) end
        return id
    elseif id == "_take" and lying then
        if Combine(ply) then return end
        if LC.CanCarry and not LC.CanCarry(ply, ITEM, 1) then ply:ChatPrint("You can't carry any more.") return end
        ent:Remove()
        LC.GiveItem(ply, ITEM, 1)
        ply:ChatPrint("You fold it into a pocket. It's contraband: don't be searched with it.")
        if LC.CloseDialog then LC.CloseDialog(ply) end
        return id
    elseif id == "_seize" and lying then
        if not Combine(ply) then return end
        local sid = ent.lcOwnerSid
        ent:Remove()
        ply:ChatPrint("[Civil Protection] Seditious material recovered.")
        hook.Run("LivingCityPamphletSeized", ply, sid)
        if LC.CloseDialog then LC.CloseDialog(ply) end
        return id
    end
    for _, t in ipairs(LC.RebelPamphletPages) do
        if t[1] == id then
            Pages(ply, lying and ent or nil, string.upper(t[2]) .. "\n\n" .. t[3])
            return id
        end
    end
end

------------------------------------------------------------------------
-- Leaving it about
------------------------------------------------------------------------

local function Forget(ent)
    for i = #LC.RebelPamphlets, 1, -1 do
        if LC.RebelPamphlets[i] == ent or not IsValid(LC.RebelPamphlets[i]) then table.remove(LC.RebelPamphlets, i) end
    end
end

function LC.LeaveRebelPamphlet(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not LC.HasItem(ply, ITEM) then return false, "You have no Resistance pamphlet. (Their quartermaster sells them.)" end
    local fwd = ply:GetAimVector()
    fwd = Vector(fwd.x, fwd.y, 0)
    if fwd:LengthSqr() < 0.01 then fwd = Vector(1, 0, 0) end
    fwd:Normalize()
    local eye = ply:EyePos()
    local from = eye + fwd * 45
    local wall = util.TraceLine({ start = eye, endpos = from, filter = ply })
    if wall and wall.Hit then from = eye + fwd * 8 end
    local d = util.TraceLine({ start = from, endpos = from - Vector(0, 0, 150), filter = ply })
    if not d or not d.Hit or (d.HitNormal and d.HitNormal.z < 0.6) then return false, "There's nowhere flat to leave it here." end
    local ent = ents.Create("lc_rebelpamphlet")
    if not IsValid(ent) then return false end
    ent:SetPos(d.HitPos + Vector(0, 0, 1))
    ent:SetAngles(Angle(0, math.random(0, 359), 0))
    ent:Spawn()
    ent.lcRebelPamphlet = true
    ent.lcOwnerSid = ply:SteamID()
    ent.lcBorn = CurTime()
    ent.lcReaders, ent.lcReadCount = setmetatable({}, { __mode = "k" }), 0
    LC.TakeItem(ply, ITEM)
    Forget(nil)
    LC.RebelPamphlets[#LC.RebelPamphlets + 1] = ent
    -- no more than a few of one player's lying about: the oldest goes
    local max, mine = math.max(1, cvMax:GetInt()), {}
    for _, e in ipairs(LC.RebelPamphlets) do if e.lcOwnerSid == ent.lcOwnerSid then mine[#mine + 1] = e end end
    for i = 1, #mine - max do mine[i]:Remove() end
    Forget(nil)
    if ply.EmitSound then ply:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 55, 130) end
    ply:ChatPrint("You leave it where someone will find it.")
    Risk(ply, 1)
    hook.Run("LivingCityPamphletLeft", ply, ent)
    return true, ent
end

------------------------------------------------------------------------
-- Handing it over
------------------------------------------------------------------------

local function MakeSympathiser(npc, st)
    st.rebel = true
    if st.profile then st.profile.rebel = true end
    npc:SetNW2Bool("lc_prebel", true)
end

function LC.GiveRebelPamphlet(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false, "Look at the person you want to give it to, up close." end
    if not LC.HasItem(ply, ITEM) then return false, "You have no Resistance pamphlet. (Their quartermaster sells them.)" end
    if target:IsPlayer() then return LC.GiveTo(ply, ITEM) end -- (the hook below sees to who was watching)
    local st = LC.NPCs and LC.NPCs[target]
    if not st or st.role ~= "citizen" or target:GetPos():DistToSqr(ply:GetPos()) > 160 * 160 then return false, "They wouldn't take it." end
    local now = CurTime()
    if (target.lcPamphletAt or 0) > now then return false, "They've been offered one already. Give it time." end
    target.lcPamphletAt = now + 300
    if LC.Face then LC.Face(target, ply:GetPos()) end
    if LC.IsSnitch and LC.IsSnitch(target) then
        -- an informant: takes it like anyone, and Civil Protection hears of it a little later
        LC.TakeItem(ply, ITEM)
        ply:ChatPrint("They take it without a word and walk on, a little quickly.")
        timer.Simple(20, function()
            if IsValid(ply) and LC.ReportCrime then
                LC.ReportCrime(ply, CRIME, 180)
                ply:ChatPrint("[Civil Protection] Someone has informed on you.")
            end
        end)
        return true
    end
    if st.rebel then
        LC.TakeItem(ply, ITEM)
        ply:ChatPrint("They know already. They take it anyway: it'll be on a bench by evening.")
        Risk(ply, 1)
        return true
    end
    local r = Roll()
    if r < 0.35 then
        LC.TakeItem(ply, ITEM)
        MakeSympathiser(target, st)
        ply:ChatPrint("They read the first lines, look round, and fold it into a sleeve. A sympathiser now.")
        Risk(ply, 2)
        hook.Run("LivingCityPamphletWon", ply, target)
    elseif r < 0.75 then
        LC.TakeItem(ply, ITEM)
        ply:ChatPrint("They tuck it away without looking at it. Later, perhaps.")
        Risk(ply, 1)
    else
        ply:ChatPrint("They push it back at you. \"Are you trying to get us both killed?\"")
        Risk(ply, 0)
    end
    return true
end

-- (handed to a player any way at all: Pockets > Give as well)
hook.Add("LivingCityGave", "LivingCityRebelPamphlet", function(ply, target, id)
    if id ~= ITEM or not IsValid(ply) then return end
    Risk(ply, 1)
    if IsValid(target) then target:ChatPrint("It's a Resistance pamphlet. Read it from your pockets, somewhere quiet.") end
end)

LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.givepamphlet = function(ply, target) return LC.GiveRebelPamphlet(ply, target) end
LC.TargetActions.leavepamphlet = function(ply) return LC.LeaveRebelPamphlet(ply) end

------------------------------------------------------------------------
-- The city walking past the ones left lying
------------------------------------------------------------------------

local lastRadio = 0
function LC.RebelPamphletsTick(now)
    Forget(nil)
    if #LC.RebelPamphlets == 0 then return end
    local life = math.max(1, cvLife:GetFloat()) * 60
    for i = #LC.RebelPamphlets, 1, -1 do
        local e = LC.RebelPamphlets[i]
        if now - (e.lcBorn or now) > life then e:Remove() table.remove(LC.RebelPamphlets, i) end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if #LC.RebelPamphlets == 0 then break end
        if IsValid(npc) and not st.test and npc:Health() > 0 and (st.role == "citizen" or LC.IsSecurity(st)) then
            local pos = npc:GetPos()
            for _, e in ipairs(LC.RebelPamphlets) do
                if IsValid(e) and e:GetPos():DistToSqr(pos) < 110 * 110 then
                    if st.role ~= "citizen" then
                        -- a unit: it's gone, and the others hear where
                        local at = e:GetPos()
                        e:Remove()
                        if now > lastRadio + 120 and LC.RadioNotice then
                            lastRadio = now
                            LC.RadioNotice("cp", "Dispatch: seditious material recovered " .. (LC.DescribePlace and LC.DescribePlace(at) or "in the city") .. ".")
                        end
                    elseif not e.lcReaders[npc] and Roll() < 0.34 then
                        e.lcReaders[npc] = true
                        e.lcReadCount = e.lcReadCount + 1
                        local snitch = LC.IsSnitch and LC.IsSnitch(npc)
                        if not st.rebel and not snitch and Roll() < 0.2 then MakeSympathiser(npc, st) end
                        if snitch or e.lcReadCount >= 3 then e:Remove() end -- (handed in, or carried off)
                    end
                    break
                end
            end
            Forget(nil)
        end
    end
end

timer.Create("LivingCityRebelPamphlets", 15, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.RebelPamphletsTick, CurTime())
    if not ok and LC.Error then LC.Error("rebel pamphlets", err) end
end)

hook.Add("LivingCityStopped", "LivingCityRebelPamphlets", function()
    for _, e in ipairs(LC.RebelPamphlets) do if IsValid(e) then e:Remove() end end
    LC.RebelPamphlets = {}
end)
