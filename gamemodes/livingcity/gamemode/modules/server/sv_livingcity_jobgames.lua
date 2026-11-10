--[[
    Living City: work you actually do

    Three Union shifts are small games, played with your hands in the world
    (sv_livingcity_work.lua puts them in the shift lists):

      Street sweep (Sanitation)   A wheeled cart at the depot: E grabs its
          handle and you push it, E again lets go. Litter lies about as real
          things (cans, bottles, scrap metal, chemical jugs, newspaper): pick
          a piece up (E) and throw it in (left click while holding it). Long
          throws pay extra. Some pieces hide something. Push the full cart
          back to the depot.

      On the line (Factory)       A conveyor carries parts past you. The
          defective ones are rust-red and spark: grab them and throw them in
          the scrap bin before they reach the end. Good parts go through.
          It speeds up. One part rattles: R while you hold it pockets what's
          inside (risky, if a unit sees). R on a good part skims it (Union
          machine parts, for the dealer or the quartermaster); take more than
          one and the foreman may find the count short.

      Papers check (Intake Processor)   Travelers step up to you one at a time.
          E on one opens their papers (a photo, name, district, expiry,
          stamps) beside today's rules. Approve, deny, or call a unit.
          Mistakes earn a citation. Forgeries carry a seal that's not quite
          right.

    Each pays on top of the shift for how well you did. A game is one stage
    of a shift: walking there starts it (LC.JobGameStart), finishing it
    advances the shift (event "game_done").

      lc_jobgames 0 puts the old shifts back.
]]

if CLIENT then return end

LC = LC or {}
LC.JobGames = LC.JobGames or {} -- [ply] = game

util.AddNetworkString("lc_jobgame")         -- server -> client: what's going on (HUD)
util.AddNetworkString("lc_papers_check")    -- server -> client: a traveler's papers
util.AddNetworkString("lc_papers_decide")   -- client -> server: approve / deny / unit

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_jobgames", "1", FLAGS, "Some Union shifts are hands-on games (street sweep, the factory line, papers check)")
function LC.JobGamesOn() return cvOn:GetBool() end

local function Pick(t) return t[math.random(#t)] end
local function Valid(m) return not util.IsValidModel or util.IsValidModel(m) end
local function FirstValid(list) for _, m in ipairs(list) do if Valid(m) then return m end end return list[#list] end
local function Phys(e) local p = IsValid(e) and e.GetPhysicsObject and e:GetPhysicsObject() return (p and IsValid(p)) and p or nil end
local function Held(e) return IsValid(e) and e.IsPlayerHolding and e:IsPlayerHolding() end

local function Hud(ply, g)
    if not IsValid(ply) then return end
    LC.SendCompressed("lc_jobgame", g and { kind = g.kind, title = g.title, lines = g.hud and g.hud(g) or {} } or {}, { ply })
end

local function Spawn(model, pos, ang, frozen)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    if ang then e:SetAngles(ang) end
    e:Spawn()
    e:Activate()
    e.lcJobProp = true
    local ph = Phys(e)
    if ph then if frozen then ph:EnableMotion(false) else ph:Wake() end end
    return e
end

------------------------------------------------------------------------
-- The engine: start, tick, end
------------------------------------------------------------------------

local GAMES = {}

-- Start a game for this player. opts: what the shift worked out (where).
function LC.JobGameStart(ply, kind, q, opts)
    local def = GAMES[kind]
    if not def or not IsValid(ply) then return false end
    if LC.JobGames[ply] then LC.JobGameEnd(ply, "replaced") end
    local g = { kind = kind, ply = ply, q = q, opts = opts or {}, startT = CurTime(), props = {}, pay = 0, notes = {} }
    LC.JobGames[ply] = g
    local ok, err = pcall(def.start, g)
    if not ok then
        LC.JobGames[ply] = nil
        if LC.Error then LC.Error("job game " .. kind, err) end
        if LC.QuestEvent then LC.QuestEvent("game_done", ply) end -- (don't leave the shift stuck)
        return false
    end
    Hud(ply, g)
    return true
end

-- End it. how: "done", "quit", "test", "replaced"
function LC.JobGameEnd(ply, how)
    local g = LC.JobGames[ply]
    if not g then return end
    LC.JobGames[ply] = nil
    local def = GAMES[g.kind]
    if def.finish then pcall(def.finish, g, how) end
    for _, e in ipairs(g.props) do if IsValid(e) then e:Remove() end end
    Hud(ply, nil)
    if how == "done" or how == "test" then
        local pay = math.max(0, math.floor(g.pay))
        -- community service is unpaid (sv_livingcity_work.lua): the work still counts
        if g.q and g.q.title and string.find(g.q.title, "Community service", 1, true) then pay = 0 end
        if pay > 0 and LC.SurvivalPayMul then pay = math.floor(pay * LC.SurvivalPayMul(ply) + 0.5) end -- (Realistic survival: sv_livingcity_survivalmode.lua)
        if pay > 0 and LC.AddCredits then LC.AddCredits(ply, pay, g.title) end
        if IsValid(ply) and LC.Notice then
            local text = (#g.notes > 0 and (table.concat(g.notes, " ") .. " ") or "") .. (pay > 0 and string.format("You earned %d extra credits for this work, on top of your normal shift pay.", pay) or "No extra credits for this work.")
            LC.Notice(ply, "info", g.title .. ": done", text, 9)
        end
        if LC.QuestEvent then LC.QuestEvent("game_done", ply) end
    end
end

timer.Create("LivingCityJobGames", 0.1, 0, function()
    local now = CurTime()
    for ply, g in pairs(LC.JobGames) do
        if not IsValid(ply) or not ply:Alive() or (g.q and LC.QuestOf and LC.QuestOf[ply] ~= g.q) then
            LC.JobGameEnd(ply, "quit")
        elseif ply.lcRationBreak then
            -- (on a ration break: the game waits too)
        else
            local ok, err = pcall(GAMES[g.kind].tick, g, now)
            if not ok then
                if LC.Error then LC.Error("job game " .. g.kind, err) end
                LC.JobGameEnd(ply, "done")
            elseif (g.nextHud or 0) < now then
                g.nextHud = now + 0.5
                Hud(ply, g)
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityJobGames", function(ply) LC.JobGameEnd(ply, "quit") end)

-- Who's holding what (the engine's own pickup with E)
hook.Add("OnPlayerPhysicsPickup", "LivingCityJobGames", function(ply, ent)
    ply.lcHolding = ent
    if ent.lcOnPickup then ent.lcOnPickup(ply, ent) end
end)
hook.Add("OnPlayerPhysicsDrop", "LivingCityJobGames", function(ply, ent, thrown)
    if ply.lcHolding == ent then ply.lcHolding = nil end
    if IsValid(ent) then
        ent.lcDroppedAt, ent.lcDroppedFrom, ent.lcThrown = CurTime(), ply:GetPos(), thrown == true
    end
end)

-- Inside a container prop's open top (its own box, a little above the rim too)?
local function InBox(box, pos, pad)
    if not IsValid(box) then return false end
    local l = box:WorldToLocal(pos)
    local mins, maxs = box:OBBMins(), box:OBBMaxs()
    pad = pad or 0
    return l.x > mins.x - pad and l.x < maxs.x + pad and l.y > mins.y - pad and l.y < maxs.y + pad
        and l.z > mins.z - 4 and l.z < maxs.z + 24
end

------------------------------------------------------------------------
-- Street sweep (Sanitation)
------------------------------------------------------------------------

-- (the smaller laundry cart first: the big one was the biggest cart in the game)
local CARTS = { "models/props_wasteland/laundry_cart002.mdl", "models/props_junk/PushCart01a.mdl", "models/props_wasteland/laundry_cart001.mdl" }
local LITTER = {
    "models/props_junk/garbage_metalcan001a.mdl", "models/props_junk/PopCan01a.mdl", "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_glassbottle001a.mdl", "models/props_junk/garbage_milkcarton001a.mdl", "models/props_junk/garbage_newspaper001a.mdl",
    "models/props_junk/garbage_takeoutcarton001a.mdl", "models/props_junk/metal_paintcan001a.mdl", "models/props_junk/glassjug01.mdl",
    "models/props_lab/jar01a.mdl", "models/props_c17/canisterchunk01a.mdl", "models/props_junk/plasticbucket001a.mdl",
    "models/props_junk/garbage_bag001a.mdl", "models/props_c17/metalPot002a.mdl",
}
-- What's under the wrapper: { item, weight } (credits for "coins")
local FINDS = { { "ration", 4 }, { "coins", 4 }, { "bandage", 2 }, { "ammo_pistol", 1 }, { "papers_blank", 1 }, { "note", 3 } }
local NOTES = {
    "A small folded scrap of paper. It says 'Kleiner lives.', with a lambda (the Resistance symbol) drawn underneath.",
    "A ration wrapper with a map drawn on the inside: it shows the canal, with an X marked on it.",
    "A note written by a child: 'Papa, they took the man from 4C. Come home the back way.'",
    "Half of a torn Combine notice. All that's left: '...relocation of all residents of Block...'",
}
local function RollFind()
    local total = 0
    for _, f in ipairs(FINDS) do total = total + f[2] end
    local r = math.random() * total
    for _, f in ipairs(FINDS) do r = r - f[2] if r <= 0 then return f[1] end end
    return "coins"
end

local CART_REACH = 150

local function Push(g, now)
    local ply, cart = g.ply, g.cart
    if not g.pushing or not IsValid(cart) then return end
    if ply:GetPos():DistToSqr(cart:GetPos()) > CART_REACH * CART_REACH * 2 then g.pushing = false return end
    local fwd = ply:GetAimVector() fwd.z = 0 fwd:Normalize()
    local want = ply:GetPos() + fwd * 58
    -- the floor where it's going, so it goes up and down steps with you (it used to stay at one height)
    local z = cart:GetPos().z
    local tr = util.TraceLine({ start = want + Vector(0, 0, 40), endpos = want - Vector(0, 0, 80), mask = MASK_SOLID_BRUSHONLY, filter = { cart, ply } })
    if tr and tr.Hit and math.abs(tr.HitPos.z + (g.cartLift or 4) - z) < 60 then z = tr.HitPos.z + (g.cartLift or 4) end
    local ph = Phys(cart)
    if ph and ph.ComputeShadowControl then
        ph:Wake()
        ph:ComputeShadowControl({ secondstoarrive = 0.15, pos = Vector(want.x, want.y, z), angle = Angle(0, fwd:Angle().y + 90, 0),
            maxangular = 400, maxangulardamp = 800, maxspeed = 400, maxspeeddamp = 600, dampfactor = 0.8, teleportdistance = 0, deltatime = 0.1 })
    else
        cart:SetPos(Vector(want.x, want.y, z))
    end
end

GAMES.sweep = {
    start = function(g)
        g.title = "Street sweep"
        local depot = g.opts.depot or g.ply:GetPos()
        g.depot = depot
        local cartPos = depot + Vector(0, 0, 4)
        -- (turned the way it's pushed: it used to stand sideways to you)
        g.cart = Spawn(FirstValid(CARTS), cartPos, Angle(0, g.ply:EyeAngles().y + 90, 0))
        if not IsValid(g.cart) then error("no cart") end
        g.cart.lcCart = g
        -- standing on the floor, whatever the model's origin (the owner, 1 November: it came up out of the ground
        -- with only its handle showing): lifted by how far its bottom sits below its origin
        local mins = g.cart.OBBMins and g.cart:OBBMins()
        g.cartLift = math.max(4, (mins and -mins.z or 0) + 2)
        local ground = LC.GroundAt and LC.GroundAt(depot) or depot
        g.cart:SetPos(ground + Vector(0, 0, g.cartLift))
        local ph = Phys(g.cart)
        if ph then ph:SetMass(80) end
        -- it doesn't knock into people (grabbing it spun it into you and hurt)
        if g.cart.SetCollisionGroup and COLLISION_GROUP_DEBRIS then g.cart:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end
        g.props[#g.props + 1] = g.cart
        g.cart:SetNW2Bool("lc_cart", true)
        g.litter, g.need, g.got, g.swish = {}, 0, 0, 0
        local finds = 2
        for _, sp in ipairs(g.opts.spots or {}) do
            local e = Spawn(Pick(LITTER), sp + Vector(0, 0, 8), Angle(0, math.random(0, 359), 0))
            if IsValid(e) then
                e:SetNW2Bool("lc_litter", true)
                e.lcLitter = g
                if finds > 0 and math.random() < 0.3 then
                    finds = finds - 1
                    e.lcFind = RollFind()
                    e.lcOnPickup = function(p, ent)
                        if p ~= g.ply or not ent.lcFind then return end
                        local what = ent.lcFind
                        ent.lcFind = nil
                        if what == "coins" then
                            local n = math.random(3, 8)
                            if LC.AddCredits then LC.AddCredits(p, n, "found in the rubbish") end
                            p:ChatPrint(string.format("[Sanitation] You found %d credits in Union tokens stuck in that rubbish. They're yours to keep.", n))
                        elseif what == "note" then
                            if LC.Notice then LC.Notice(p, "event", "Found in the rubbish", Pick(NOTES), 10) end
                        else
                            LC.GiveOrDrop(p, what, 1)
                            p:ChatPrint("[Sanitation] You found " .. (LCS.Items[what] and LCS.Items[what].name or what) .. " hidden in that rubbish. It's in your pockets now.")
                        end
                    end
                end
                g.litter[#g.litter + 1] = e
                g.props[#g.props + 1] = e
                g.need = g.need + 1
            end
        end
        g.limit = CurTime() + 420
        g.ply:ChatPrint("[Sanitation] Your cart is waiting at the depot. Look at it and press E to grab it and push it; press E again to let go. Pick up each piece of rubbish with E and throw it into the cart with left click (long throws pay extra). When the cart is full, push it back to the depot to finish. You have 7 minutes, and finishing in under 3 earns a bonus.")
        g.hud = function(gg)
            local left = math.max(0, math.ceil(gg.limit - CurTime()))
            local lines = { string.format("Rubbish in the cart: %d of %d", gg.got, gg.need) }
            if gg.swish > 0 then lines[#lines + 1] = string.format("Long throws (extra pay): %d", gg.swish) end
            lines[#lines + 1] = gg.got >= gg.need and "Cart full: push it back to the depot to finish" or (gg.pushing and "Pushing the cart (press E to let go)" or "Press E on the cart to push it")
            lines[#lines + 1] = string.format("%d:%02d left", math.floor(left / 60), left % 60)
            return lines
        end
    end,
    tick = function(g, now)
        Push(g, now)
        local cart = g.cart
        if not IsValid(cart) then return LC.JobGameEnd(g.ply, "done") end
        cart:SetNW2Int("lc_fill", g.got)
        cart:SetNW2Int("lc_need", g.need)
        for i = #g.litter, 1, -1 do
            local e = g.litter[i]
            if not IsValid(e) then
                table.remove(g.litter, i)
            elseif not Held(e) and InBox(cart, e:GetPos(), -2) then
                table.remove(g.litter, i)
                g.got = g.got + 1
                g.pay = g.pay + 1
                local far = e.lcThrown and e.lcDroppedFrom and e.lcDroppedFrom:Distance(cart:GetPos()) > 160
                if far then
                    g.swish = g.swish + 1
                    g.pay = g.pay + 1
                    g.ply:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 65)
                else
                    g.ply:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 60)
                end
                e:Remove()
            end
        end
        if g.got >= g.need and cart:GetPos():DistToSqr(g.depot) < 220 * 220 then
            if now - g.startT < 180 then
                g.pay = g.pay + 5
                g.notes[#g.notes + 1] = "Done in under 3 minutes: 5 credits bonus."
            end
            if g.swish >= 3 then g.notes[#g.notes + 1] = string.format("%d long throws into the cart (1 extra credit each).", g.swish) end
            cart:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 75)
            return LC.JobGameEnd(g.ply, "done")
        end
        if now > g.limit then
            g.notes[#g.notes + 1] = "Time's up: you're paid for the rubbish already in the cart."
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
}

-- E on your cart: take the handle, or let go.
hook.Add("KeyPress", "LivingCityJobCart", function(ply, key)
    if key ~= IN_USE then return end
    local g = LC.JobGames[ply]
    if not g or g.kind ~= "sweep" or not IsValid(g.cart) then return end
    if IsValid(ply.lcHolding) then return end
    local tr = ply:GetEyeTrace()
    if g.pushing then
        g.pushing = false
        ply:ChatPrint("[Sanitation] You let go of the cart. Press E on it to push it again.")
    elseif tr and tr.Entity == g.cart and ply:GetPos():DistToSqr(g.cart:GetPos()) < CART_REACH * CART_REACH then
        g.pushing = true
    end
end)
-- (nobody walks off with the cart in their arms)
hook.Add("AllowPlayerPickup", "LivingCityJobCart", function(ply, ent) if ent.lcCart then return false end end)

------------------------------------------------------------------------
-- On the line (Factory)
------------------------------------------------------------------------

-- (all of them boxy enough to sit on a belt and big enough to grab with E: the little lever
-- and plug couldn't be picked up, and round ones rolled)
local PARTS = {
    "models/props_lab/reciever01a.mdl", "models/props_lab/reciever01b.mdl", "models/props_lab/box01a.mdl",
    "models/props_lab/harddrive01.mdl", "models/props_junk/metal_paintcan001a.mdl", "models/props_lab/reciever01d.mdl",
    "models/props_c17/BriefCase001a.mdl", "models/props_junk/cardboard_box004a.mdl",
}
LC.LineParts = PARTS
local BIN = FirstValid({ "models/props_junk/TrashBin01a.mdl", "models/props_trainstation/trashcan_indoor001a.mdl" })
local RUST = Color(170, 95, 60)
local TOTAL_PARTS = 20

-- The same line, other work: the ration plant's sealing line (opts.variant = "rations").
local LINES = {
    factory = { title = "Factory line", tag = "[Factory]", word = "parts", parts = PARTS, bad = RUST,
        intro = "The conveyor belt is starting. Rust-red, sparking parts are faulty: pick them up with E and throw them (left click) into the scrap bin beside the belt. Leave the good parts on the belt so they reach the end. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a good part to hide it in your coat; the dealer and the quartermaster buy them. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)",
        rattle = "Something rattles inside this part. Press R while holding it to open it and pocket what's hidden inside." },
    rations = { title = "Ration sealing line", tag = "[Ration plant]", word = "packs", parts = { "models/weapons/w_package.mdl" }, bad = Color(120, 140, 70),
        intro = "The ration sealing belt is starting. Split, leaking packs (the sickly green ones) are faulty: pick them up with E and throw them (left click) into the reject bin beside the belt. Leave the sealed packs on the belt so they reach the end and go on to the dispensers. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a sealed pack to hide it in your coat. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)",
        rattle = "This pack is heavier than a ration should be. Press R while holding it to open it and pocket what's hidden inside." },
}
local function LineOf(g) return LINES[g and g.opts and g.opts.variant or "factory"] or LINES.factory end

-- A belt's frame: start, the way along it, how long, how wide, its top.
local function Belt(conv)
    local mins, maxs = conv:OBBMins(), conv:OBBMaxs()
    local alongX = (maxs.x - mins.x) >= (maxs.y - mins.y)
    local len = alongX and (maxs.x - mins.x) or (maxs.y - mins.y)
    local wid = alongX and (maxs.y - mins.y) or (maxs.x - mins.x)
    local c = (mins + maxs) * 0.5
    local dirL = alongX and Vector(1, 0, 0) or Vector(0, 1, 0)
    local sideL = alongX and Vector(0, 1, 0) or Vector(-1, 0, 0)
    local function W(v) return conv:LocalToWorld(v) end
    local origin = W(Vector(c.x, c.y, maxs.z))
    local dir = (W(Vector(c.x, c.y, maxs.z) + dirL) - origin):GetNormalized()
    local side = (W(Vector(c.x, c.y, maxs.z) + sideL) - origin):GetNormalized()
    return { origin = origin, dir = dir, side = side, len = len, wid = wid, top = origin.z }
end
LC.ConveyorBelt = Belt

-- Where pos is along the belt (-len/2 .. len/2), across it, and above its top.
local function OnBelt(b, pos)
    local d = pos - b.origin
    return d:Dot(b.dir), d:Dot(b.side), pos.z - b.top
end

-- The factory's own conveyor, or one set up for the shift where they stand.
local function FindConveyor(g)
    local near = LC.NearestEntOf and LC.NearestEntOf(g.ply:GetPos(), { "lc_conveyor" })
    if IsValid(near) and near:GetPos():DistToSqr(g.ply:GetPos()) < 1500 * 1500 then return near, false end
    local fwd = g.ply:GetAimVector() fwd.z = 0 fwd:Normalize()
    local pos = (g.opts.station or g.ply:GetPos()) + fwd * 70
    local e = ents.Create("lc_conveyor")
    if not IsValid(e) then return nil end
    e:SetPos(pos + Vector(0, 0, 34))
    e:SetAngles(Angle(0, fwd:Angle().y + 90, 0))
    e:Spawn()
    if not e:GetModel() or e:GetModel() == "" then e:SetModel("models/hunter/plates/plate1x6.mdl") end
    local ph = Phys(e)
    if ph then ph:EnableMotion(false) end
    return e, true
end

GAMES.line = {
    start = function(g)
        local L = LineOf(g)
        g.title = L.title
        local conv, temp = FindConveyor(g)
        if not IsValid(conv) then error("no conveyor") end
        g.conv = conv
        if temp then g.props[#g.props + 1] = conv end
        conv:SetNW2Bool("lc_running", true)
        local b = Belt(conv)
        g.belt = b
        -- the scrap bin at the side, halfway along
        local binPos = b.origin + b.side * (b.wid / 2 + 34)
        binPos.z = b.top - 34
        g.bin = Spawn(BIN, LC.GroundAt and LC.GroundAt(binPos) or binPos, Angle(0, 0, 0), true)
        if IsValid(g.bin) then g.props[#g.props + 1] = g.bin g.bin:SetNW2Bool("lc_scrapbin", true) end
        g.parts, g.spawned, g.nextPart = {}, 0, CurTime() + 2
        g.caught, g.wasted, g.missed, g.shipped = 0, 0, 0, 0
        g.rattle = math.random(4, TOTAL_PARTS - 2)
        g.speed = 40
        g.ply:ChatPrint(L.tag .. " " .. L.intro)
        local w = L.word
        g.hud = function(gg)
            return {
                string.format("%s: %d of %d", w:sub(1, 1):upper() .. w:sub(2), gg.spawned, TOTAL_PARTS),
                string.format("Faulty %s binned: %d    Good %s passed: %d", w, gg.caught, w, gg.shipped),
                string.format("Faulty %s missed: %d    Good %s binned by mistake: %d", w, gg.missed, w, gg.wasted),
            }
        end
    end,
    tick = function(g, now)
        local b = g.belt
        if not IsValid(g.conv) then return LC.JobGameEnd(g.ply, "done") end
        -- the next part onto the belt, sooner as the shift goes on
        if g.spawned < TOTAL_PARTS and now >= g.nextPart then
            g.spawned = g.spawned + 1
            -- well onto the belt (not at its very end, where they tipped off the back), square
            -- to it, sitting on it rather than dropped onto it
            local start = b.origin - b.dir * (b.len / 2 - 36)
            local L = LineOf(g)
            local e = Spawn(Pick(L.parts), start, Angle(0, b.dir:Angle().y, 0))
            if IsValid(e) then
                local mn = e.OBBMins and e:OBBMins() or Vector(0, 0, 0)
                e:SetPos(Vector(start.x, start.y, b.top - mn.z + 1))
                -- light enough for anyone to pick up with E (some weren't), and not spinning about
                local ph = Phys(e)
                if ph then
                    if ph.SetMass then ph:SetMass(8) end
                    if ph.SetDamping then ph:SetDamping(0.5, 30) end
                end
                e.lcPart = { bad = math.random() < 0.32, rattle = g.spawned == g.rattle, t = now }
                if e.lcPart.bad then
                    e:SetColor(L.bad)
                    e:SetNW2Bool("lc_defect", true)
                end
                if e.lcPart.rattle then
                    e.lcOnPickup = function(p) if p == g.ply and e.lcPart then p:ChatPrint(L.tag .. " " .. L.rattle) end end
                end
                g.parts[#g.parts + 1] = e
                g.props[#g.props + 1] = e
            end
            local f = g.spawned / TOTAL_PARTS
            g.speed = 40 + 45 * f
            g.nextPart = now + math.max(1.3, 3.2 - 2.0 * f)
        end
        for i = #g.parts, 1, -1 do
            local e = g.parts[i]
            local p = IsValid(e) and e.lcPart
            if not p then
                table.remove(g.parts, i)
            elseif not Held(e) then
                local along, across, up = OnBelt(b, e:GetPos())
                local done
                if IsValid(g.bin) and InBox(g.bin, e:GetPos(), 2) then
                    done = true
                    if p.bad then g.caught = g.caught + 1 g.pay = g.pay + 2 g.ply:EmitSound("physics/metal/metal_barrel_impact_soft" .. math.random(1, 4) .. ".wav", 60)
                    else g.wasted = g.wasted + 1 g.pay = g.pay - 1 g.ply:ChatPrint("[Foreman] That one was good! Binning good ones comes out of your pay.") end
                elseif along > b.len / 2 - 4 and math.abs(across) < b.wid / 2 + 6 then
                    done = true
                    if p.bad then g.missed = g.missed + 1 g.pay = g.pay - 2 g.ply:ChatPrint("[Foreman] A faulty one reached the end of the belt! That comes out of your pay.")
                    else g.shipped = g.shipped + 1 g.pay = g.pay + 1 end
                elseif up < -20 and now - (e.lcDroppedAt or p.t) > 4 then
                    done = true -- on the floor: lost
                    if p.bad then g.caught = g.caught + 1 g.pay = g.pay + 1 else g.wasted = g.wasted + 1 g.pay = g.pay - 1 end
                elseif math.abs(across) < b.wid / 2 + 4 and up > -4 and up < 30 then
                    -- riding the belt
                    local ph = Phys(e)
                    if ph then
                        local v = ph:GetVelocity()
                        -- along the belt, and drawn back to its middle (round ones used to roll off the side);
                        -- no spinning (a spinning part sank through the belt)
                        ph:SetVelocity(b.dir * g.speed - b.side * (across * 2) + Vector(0, 0, math.min(v.z, 0)))
                        if ph.GetAngleVelocity and ph.AddAngleVelocity then ph:AddAngleVelocity(-ph:GetAngleVelocity()) end
                        ph:Wake()
                    else
                        e:SetPos(e:GetPos() + b.dir * g.speed * 0.1)
                    end
                end
                if done then
                    table.remove(g.parts, i)
                    e:Remove()
                end
            end
            -- the defective ones spark now and then
            if IsValid(e) and p and p.bad and math.random() < 0.06 and EffectData then
                local fx = EffectData()
                fx:SetOrigin(e:WorldSpaceCenter())
                util.Effect("Sparks", fx, true, true)
            end
        end
        if g.spawned >= TOTAL_PARTS and #g.parts == 0 then
            local bad = g.caught + g.missed
            -- the foreman counts what went through: skim more than one and he may find it short
            local sk = g.skimmed or 0
            if sk > 0 and math.random() < math.min(0.9, (sk - 1) * 0.25) then
                g.pay = g.pay - 2 * sk
                g.notes[#g.notes + 1] = string.format("The foreman found %d missing from his count. It comes out of your pay, and you lose Civil Standing.", sk)
                if LC.AddStanding then LC.AddStanding(g.ply, -5 * sk, "Goods went missing on your shift") end
            end
            if g.missed == 0 and g.wasted == 0 then
                g.pay = g.pay + 6
                g.notes[#g.notes + 1] = "No mistakes all shift: 6 credits bonus."
            end
            g.notes[#g.notes + 1] = string.format("Faulty parts binned: %d of %d. Good parts passed: %d.", g.caught, bad, g.shipped)
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
    finish = function(g)
        if IsValid(g.conv) then g.conv:SetNW2Bool("lc_running", false) end
        for _, e in ipairs(g.parts or {}) do if IsValid(e) then e:Remove() end end
        g.parts = {}
    end,
}

local CONTRABAND = { "gun_parts", "ammo_pistol", "chemicals", "radio_tuned" }

-- Skimming (sv_livingcity_funding.lua): R while holding a good part pockets it. A unit who sees
-- it makes you wanted; and the more you take, the likelier the foreman finds the count short.
local SKIM = { factory = "union_goods", rations = "ration" }
function LC.LineSkim(ply, g, e)
    local what = SKIM[g.opts and g.opts.variant or "factory"] or "union_goods"
    if not LCS.Items[what] then return false end
    if e.lcPart.bad then ply:ChatPrint(LineOf(g).tag .. " That one is faulty: nobody would buy it, so it's not worth stealing.") return false end
    for i, p in ipairs(g.parts) do if p == e then table.remove(g.parts, i) break end end
    e.lcPart = nil
    e:Remove()
    LC.GiveOrDrop(ply, what, 1)
    g.skimmed = (g.skimmed or 0) + 1
    ply:ChatPrint(LineOf(g).tag .. " You hid " .. LCS.Items[what].name .. " in your coat. The foreman's count will be one short.")
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
        LC.ReportCrime(ply, "Theft from the factory floor", 120)
        ply:ChatPrint("[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted.")
    end
    return true
end

-- R while holding the rattling part: what's inside goes in your pocket (a good part: skimmed).
hook.Add("KeyPress", "LivingCityJobLine", function(ply, key)
    if key ~= IN_RELOAD then return end
    local g = LC.JobGames[ply]
    local e = ply.lcHolding
    if not g or g.kind ~= "line" or not IsValid(e) or not e.lcPart then return end
    if not e.lcPart.rattle then return LC.LineSkim(ply, g, e) end
    local what = Pick(CONTRABAND)
    if not LCS.Items[what] then what = "gun_parts" end
    e.lcPart.rattle = false
    LC.GiveOrDrop(ply, what, 1)
    ply:ChatPrint(LineOf(g).tag .. " You open it and pocket what was hidden inside: " .. (LCS.Items[what] and LCS.Items[what].name or what) .. ".")
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
        LC.ReportCrime(ply, "Theft from the factory floor", 120)
        ply:ChatPrint("[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted.")
    end
    hook.Run("LivingCityLineContraband", ply, what)
end)

------------------------------------------------------------------------
-- Papers check (Intake Processor)
------------------------------------------------------------------------

local MALE = { "models/Humans/Group01/male_01.mdl", "models/Humans/Group01/male_02.mdl", "models/Humans/Group01/male_03.mdl",
    "models/Humans/Group01/male_04.mdl", "models/Humans/Group01/male_05.mdl", "models/Humans/Group01/male_06.mdl",
    "models/Humans/Group01/male_07.mdl", "models/Humans/Group01/male_08.mdl", "models/Humans/Group01/male_09.mdl" }
local FEMALE = { "models/Humans/Group01/female_01.mdl", "models/Humans/Group01/female_02.mdl", "models/Humans/Group01/female_03.mdl",
    "models/Humans/Group01/female_04.mdl", "models/Humans/Group01/female_06.mdl", "models/Humans/Group01/female_07.mdl" }
local DISTRICTS = { "District 2", "District 4", "District 7", "District 9", "District 12", "District 17" }
local PURPOSES = { "Work", "Family", "Relocation", "Work", "Medical" }
local TRAVELERS = 5

local function OtherFace(model)
    local m = string.lower(model or "")
    local pool = string.find(m, "female", 1, true) and FEMALE or MALE
    for _ = 1, 10 do
        local c = Pick(pool)
        if string.lower(c) ~= m then return c end
    end
    return pool[1]
end

-- Today's rules: always expiry and the photo, and one or two more.
local function Rules()
    local r = { expiry = true, photo = true }
    local extra = { "district", "permit", "union" }
    for _ = 1, math.random(1, 2) do
        local k = table.remove(extra, math.random(#extra))
        r[k] = true
    end
    if r.district then r.banned = Pick(DISTRICTS) end
    return r
end

local function RuleLines(r)
    local out = { "Papers must not be expired.", "The photo must match the person in front of you." }
    if r.district then out[#out + 1] = "No entry from " .. r.banned .. "." end
    if r.permit then out[#out + 1] = "Every traveler needs a transit permit stamp." end
    if r.union then out[#out + 1] = "Travel for work needs a Union stamp." end
    return out
end

-- One traveler's papers, and what's wrong with them (if anything).
local function MakePapers(g, npc)
    local r, today = g.rules, g.today
    local model = npc:GetModel()
    local name = (LC.RandomName and LC.RandomName()) or Pick({ "Anya Vasek", "Pavel Orlov", "Mira Kessler", "Tomas Hrabal", "Ilse Brandt", "Jonas Petrov" })
    local p = {
        name = name, cid = string.format("%02d-%03d", math.random(10, 99), math.random(100, 999)),
        model = model, district = Pick(DISTRICTS), expires = today + math.random(3, 40),
        permit = true, union = true, purpose = Pick(PURPOSES), seal = "OCS",
    }
    if r.district then while p.district == r.banned do p.district = Pick(DISTRICTS) end end
    local wrong
    if math.random() < 0.5 then
        local can = { "expiry", "photo" }
        if r.district then can[#can + 1] = "district" end
        if r.permit then can[#can + 1] = "permit" end
        if r.union and p.purpose == "Work" then can[#can + 1] = "union" end
        wrong = Pick(can)
        if wrong == "expiry" then p.expires = today - math.random(1, 30)
        elseif wrong == "photo" then p.model = OtherFace(model)
        elseif wrong == "district" then p.district = r.banned
        elseif wrong == "permit" then p.permit = false
        elseif wrong == "union" then p.union = false end
    end
    -- a stamp nobody asked for is just ink: vary it so its absence isn't a tell
    if not r.permit and math.random() < 0.5 then p.permit = false end
    if not r.union and math.random() < 0.5 then p.union = false end
    local forged = math.random() < 0.15
    if forged then p.seal = Pick({ "0CS", "OC5", "QCS" }) end
    return p, wrong, forged
end

-- Where travelers come from and go to: the platform (or an arrival point), else somewhere
-- out of your sight a little way off; failing both, straight in front of you, at a distance.
local function TravelerSpot(g, away)
    local post = g.post
    for _, kind in ipairs(away and { "release", "spawn", "platform" } or { "platform", "spawn", "release" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            local d = p.pos:DistToSqr(post)
            if d > 300 * 300 and d < 3000 * 3000 then return p.pos end
        end
    end
    local hide = LC.QB and LC.QB.HideSpots and LC.QB.HideSpots(post, 1, 900, true)
    if hide and hide[1] and hide[1]:DistToSqr(post) > 250 * 250 then return hide[1] end
    local p = post + g.facing * (away and -700 or 500)
    return LC.GroundAt and LC.GroundAt(p) or p
end

local function NextTraveler(g)
    g.current = nil
    if g.done >= TRAVELERS then return end
    local post = g.post
    local fwd = g.facing
    -- they walk up from the platform (or out of sight), not appear in front of you
    local from = TravelerSpot(g, false)
    if not (LC.Spawners and LC.Spawners.citizen) then g.done = TRAVELERS return end
    local npc, st = LC.Spawners.citizen(from)
    if not IsValid(npc) or not st then g.done = TRAVELERS return end
    LC.SetState(npc, st, "event")
    st.eventUntil = CurTime() + 600
    st.questLock = true
    st.unmanaged = true
    local stand = post + fwd * 64
    if npc.SetLastPosition then npc:SetLastPosition(stand) npc:SetSchedule(SCHED_FORCED_GO) end
    local papers, wrong, forged = MakePapers(g, npc)
    g.current = { npc = npc, st = st, stand = stand, papers = papers, wrong = wrong, forged = forged, arrived = false, from = from }
    g.props[#g.props + 1] = npc
end

GAMES.papers = {
    start = function(g)
        g.title = "Papers check"
        g.post = g.ply:GetPos()
        local fwd = g.ply:GetAimVector() fwd.z = 0
        g.facing = fwd:GetNormalized()
        g.rules = Rules()
        g.today = 200 + math.random(0, 150)
        g.done, g.right, g.cites = 0, 0, 0
        g.ply:ChatPrint("[Station] Travelers will walk up to you one at a time. Press E on each one to see their papers and check them against today's rules (listed on your screen). Then choose: approve them, deny them, or call a Civil Protection unit if the papers are forged (look closely at the seal). Right calls pay; wrong ones get you a citation and docked pay.")
        g.hud = function(gg)
            local lines = { string.format("Travelers checked: %d of %d", gg.done, TRAVELERS), string.format("Right calls: %d    Citations (mistakes): %d", gg.right, gg.cites), "Today's rules:" }
            for _, l in ipairs(RuleLines(gg.rules)) do lines[#lines + 1] = "  " .. l end
            if gg.current and gg.current.arrived then lines[#lines + 1] = "Press E on the traveler to see their papers" end
            return lines
        end
        NextTraveler(g)
    end,
    tick = function(g, now)
        local c = g.current
        if not c then
            if g.done >= TRAVELERS then return LC.JobGameEnd(g.ply, "done") end
            return
        end
        if not IsValid(c.npc) then g.done = g.done + 1 return NextTraveler(g) end
        if not c.arrived and c.npc:GetPos():DistToSqr(c.stand) < 70 * 70 then
            c.arrived = true
            if LC.Face then LC.Face(c.npc, g.ply:GetPos()) end
            if c.npc.SetSchedule then c.npc:SetSchedule(SCHED_IDLE_STAND) end
        elseif not c.arrived and now - (c.t or now) > 25 then
            c.npc:SetPos(c.stand) -- (held up somewhere: steps up anyway)
        end
        c.t = c.t or now
    end,
    finish = function(g)
        if g.cites == 0 and g.done >= TRAVELERS then
            g.pay = g.pay + 5
            g.notes[#g.notes + 1] = "No citations all shift: 5 credits bonus."
        end
        g.notes[#g.notes + 1] = string.format("%d of %d decisions right.", g.right, g.done)
    end,
}

local function ShowPapers(ply, g)
    local c = g.current
    net.Start("lc_papers_check")
    net.WriteString(util.TableToJSON({ papers = c.papers, rules = RuleLines(g.rules), today = g.today, n = g.done + 1, of = TRAVELERS }))
    net.Send(ply)
end

-- E on the traveler in front of you: their papers.
hook.Add("KeyPress", "LivingCityJobPapers", function(ply, key)
    if key ~= IN_USE then return end
    local g = LC.JobGames[ply]
    if not g or g.kind ~= "papers" or not g.current or not g.current.arrived then return end
    local tr = ply:GetEyeTrace()
    if tr and tr.Entity == g.current.npc and ply:GetPos():DistToSqr(g.current.npc:GetPos()) < 200 * 200 then ShowPapers(ply, g) end
end)

-- Off they go: walking away (to the platform or the exits), and gone once nobody can see
-- them (or after a while regardless), not standing there or vanishing in front of you.
local walking = {}
local function Walk(npc, to, secs)
    if not IsValid(npc) then return end
    if npc.SetLastPosition then npc:SetLastPosition(to) npc:SetSchedule(SCHED_FORCED_GO) end
    walking[npc] = { to = to, t0 = CurTime(), max = math.max(20, (secs or 8) * 3) }
end
LC.PapersWalking = walking
timer.Create("LivingCityTravelersOff", 1, 0, function()
    local now = CurTime()
    for npc, w in pairs(walking) do
        if not IsValid(npc) then
            walking[npc] = nil
        else
            local gone = now - w.t0 > w.max
            if not gone and now - w.t0 > 3 then
                local away = npc:GetPos():DistToSqr(w.to) < 120 * 120
                local seen = LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))
                gone = (away or now - w.t0 > 6) and not seen
            end
            if gone then walking[npc] = nil npc:Remove()
            elseif npc.IsCurrentSchedule and not npc:IsCurrentSchedule(SCHED_FORCED_GO) and npc.SetSchedule then
                npc:SetLastPosition(w.to) npc:SetSchedule(SCHED_FORCED_GO) -- (keep walking)
            end
        end
    end
end)

-- The call: "approve", "deny" or "unit". True when it was right.
function LC.PapersDecide(ply, choice)
    local g = LC.JobGames[ply]
    if not g or g.kind ~= "papers" or not g.current then return nil end
    local c = g.current
    local right, cite, note
    if c.forged then
        if choice == "unit" then right = true g.pay = g.pay + 5 note = "Forged papers: the seal reads " .. c.papers.seal .. ". A Civil Protection unit takes the traveler away."
            if LC.AddStanding then LC.AddStanding(ply, 2) end
        elseif choice == "deny" then right = true g.pay = g.pay + 2 note = "Denied. The seal was forged, so calling a Civil Protection unit would have paid more."
        else
            right = false
            hook.Run("LivingCityPapersForgeryPassed", ply)
            if math.random() < 0.3 then cite = "You approved forged papers (the seal read " .. c.papers.seal .. ")." g.pay = g.pay - 4
                if LC.AddStanding then LC.AddStanding(ply, -5) end
            else note = "They walk through on forged papers. Under their breath: 'Thank you.' Nobody noticed this time." end
        end
    elseif c.wrong then
        if choice == "deny" or choice == "unit" then right = true g.pay = g.pay + 3
        else right = false g.pay = g.pay - 2
            cite = ({ expiry = "You approved papers that had expired.", photo = "You approved a traveler whose photo didn't match them.",
                district = "You approved entry from a banned district, " .. tostring(g.rules.banned) .. ".", permit = "You approved a traveler with no transit permit stamp.",
                union = "You approved travel for work without a Union stamp." })[c.wrong]
        end
    else
        if choice == "approve" then right = true g.pay = g.pay + 3
        else right = false g.pay = g.pay - 2 cite = "You turned away a traveler whose papers were all in order." end
    end
    g.done = g.done + 1
    if right then g.right = g.right + 1 end
    if cite then
        g.cites = g.cites + 1
        ply:EmitSound("buttons/combine_button_locked.wav", 60)
        if LC.Notice then LC.Notice(ply, "warn", "Citation", cite .. " Your pay is docked for this.", 6) end
    elseif note then
        ply:ChatPrint("[Station] " .. note)
    end
    if choice == "approve" then Walk(c.npc, TravelerSpot(g, true), 9)
    elseif choice == "unit" then
        Walk(c.npc, c.from, 5)
        if IsValid(c.npc) then c.npc:EmitSound("vo/npc/male01/no02.wav", 70) end
    else Walk(c.npc, c.from, 9) end
    -- (theirs to walk off now, not the shift's to remove at the end)
    for i = #g.props, 1, -1 do if g.props[i] == c.npc then table.remove(g.props, i) end end
    c.npc = nil -- (it walks off on its own now)
    g.nextHud = 0
    NextTraveler(g)
    return right
end

net.Receive("lc_papers_decide", function(_, ply)
    local choice = net.ReadString()
    if choice ~= "approve" and choice ~= "deny" and choice ~= "unit" then return end
    LC.PapersDecide(ply, choice)
end)

------------------------------------------------------------------------
-- Rewiring (Maintenance): the panel opens on a board of scrambled circuit
-- tiles. Turn them (click: a quarter turn; right-click: back) until the
-- current runs from the feed on the left to the lamp on the right; the
-- tiles it reaches light up. Live sparks jump round the board: turn a tile
-- while it's sparking and it bites (a shock, and seconds off the clock).
-- Too slow and the breaker trips: the board scrambles again, for less pay.
-- Done in no more turns than it needs (par, plus two) is a bonus; during a
-- blackout it pays double. A terminal's board is bigger, with more sparks.
------------------------------------------------------------------------

util.AddNetworkString("lc_wire_open")    -- server -> client: the board (and "{}" closes it)
util.AddNetworkString("lc_wire_try")     -- client -> server: turn tile k (and which way)

local function Shuffle(t)
    for i = #t, 2, -1 do local j = math.random(i) t[i], t[j] = t[j], t[i] end
    return t
end

-- a tile is the sides it joins: N 1, E 2, S 4, W 8
local N, E, S, W = 1, 2, 4, 8
local DIRS = { { N, 0, -1, S }, { E, 1, 0, W }, { S, 0, 1, N }, { W, -1, 0, E } }
local function TurnCW(m) return bit.band(bit.bor(bit.lshift(m, 1), bit.rshift(m, 3)), 15) end
local function TurnCCW(m) return bit.band(bit.bor(bit.rshift(m, 1), bit.lshift(m, 3)), 15) end
LC.WireTurn = TurnCW

-- Which tiles the current reaches (from the feed, left of row g.feed), and whether it gets to the lamp.
local function Lit(g)
    local lit, w, h = {}, g.w, g.h
    local start = (g.feed - 1) * w + 1
    if bit.band(g.tiles[start], W) == 0 then return lit, false end
    local q = { start }
    lit[start] = true
    while #q > 0 do
        local k = table.remove(q)
        local x, y = (k - 1) % w + 1, math.floor((k - 1) / w) + 1
        for _, d in ipairs(DIRS) do
            local nx, ny = x + d[2], y + d[3]
            if bit.band(g.tiles[k], d[1]) ~= 0 and nx >= 1 and nx <= w and ny >= 1 and ny <= h then
                local nk = (ny - 1) * w + nx
                if not lit[nk] and bit.band(g.tiles[nk], d[4]) ~= 0 then lit[nk] = true q[#q + 1] = nk end
            end
        end
    end
    local lamp = (g.lamp - 1) * w + w
    return lit, lit[lamp] == true and bit.band(g.tiles[lamp], E) ~= 0
end
LC.WireLit = Lit

-- A winding way from the feed to the lamp (a random walk that backs out of dead ends).
local function Route(w, h, from, to)
    for _ = 1, 40 do
        local path, seen, budget = { (from - 1) * w + 1 }, { [(from - 1) * w + 1] = true }, 600
        local function Walk()
            budget = budget - 1
            if budget < 0 then return false end
            local k = path[#path]
            if k == (to - 1) * w + w then return #path >= w + h end
            local x, y = (k - 1) % w + 1, math.floor((k - 1) / w) + 1
            local order = { 1, 2, 3, 4 }
            for i = 4, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
            for _, di in ipairs(order) do
                local d = DIRS[di]
                local nx, ny = x + d[2], y + d[3]
                local nk = (ny - 1) * w + nx
                if nx >= 1 and nx <= w and ny >= 1 and ny <= h and not seen[nk] then
                    path[#path + 1], seen[nk] = nk, true
                    if Walk() then return true end
                    path[#path], seen[nk] = nil, nil
                end
            end
            return false
        end
        if Walk() then return path end
    end
    -- (never in practice: straight along, then up or down the last column)
    local path = {}
    for x = 1, w do path[#path + 1] = (from - 1) * w + x end
    local step = to > from and 1 or -1
    for y = from + step, to, step do if from ~= to then path[#path + 1] = (y - 1) * w + w end end
    return path
end

local function Side(w, a, b)
    local d = b - a
    if d == 1 then return E elseif d == -1 then return W elseif d == w then return S else return N end
end

-- A fresh board: the right way laid, odd tiles everywhere else, every one turned at random.
local function Deal(g)
    local w, h = g.w, g.h
    g.feed, g.lamp = math.random(h), math.random(h)
    local path = Route(w, h, g.feed, g.lamp)
    local want, onPath = {}, {}
    for i, k in ipairs(path) do
        local m = 0
        m = bit.bor(m, i == 1 and W or Side(w, k, path[i - 1]))
        m = bit.bor(m, i == #path and E or Side(w, k, path[i + 1]))
        want[k], onPath[k] = m, true
    end
    g.tiles = {}
    for k = 1, w * h do
        local m = want[k]
        if not m then
            local r = math.random()
            m = r < 0.4 and (N + E) or r < 0.7 and (N + S) or (N + E + S) -- (bends, straights, tees)
        end
        for _ = 1, math.random(0, 3) do m = TurnCW(m) end
        g.tiles[k] = m
    end
    local _, done = Lit(g)
    if done then local k = path[math.random(#path)] g.tiles[k] = TurnCW(g.tiles[k]) end
    -- par: the fewest quarter turns that put the right way down
    g.par = 0
    for k in pairs(onPath) do
        local best, m = 4, g.tiles[k]
        for r = 0, 3 do
            if m == want[k] then best = math.min(best, r, 4 - r) end
            m = TurnCW(m)
        end
        g.par = g.par + best
    end
    g.want, g.turns = want, 0
    g.sparks = {}
    for i = 1, g.nSparks do g.sparks[i] = { k = math.random(w * h), since = CurTime(), moveAt = CurTime() + 1 + math.random() * 1.5 } end
end
LC.WireDeal = Deal

local function SendWires(g, zap)
    local lit = Lit(g)
    local litList, sparks = {}, {}
    for k in pairs(lit) do litList[#litList + 1] = k end
    for _, sp in ipairs(g.sparks) do sparks[#sparks + 1] = sp.k end
    net.Start("lc_wire_open")
    net.WriteString(util.TableToJSON({ w = g.w, h = g.h, tiles = g.tiles, feed = g.feed, lamp = g.lamp, lit = litList, sparks = sparks,
        zap = zap, turns = g.turns, par = g.par, shocks = g.shocks, secs = math.max(1, math.ceil(g.limit - CurTime())), what = g.what, dark = g.dark or false }))
    net.Send(g.ply)
end

GAMES.wiring = {
    start = function(g)
        g.title = "Rewiring"
        g.what = g.opts.what or "the panel"
        local big = g.what == "the terminal"
        g.w, g.h, g.nSparks = big and 6 or 5, big and 5 or 4, big and 3 or 2
        g.secs = big and 75 or 55
        g.shocks = 0
        Deal(g)
        g.limit = CurTime() + g.secs
        g.dark = LC.CityDark or (LC.PoweredAt and g.opts.pos and not LC.PoweredAt(g.opts.pos))
        g.hud = function(gg)
            local left = math.max(0, math.ceil(gg.limit - CurTime()))
            return { string.format("Turns used: %d (fewest possible: %d)", gg.turns, gg.par), string.format("Shocks: %d", gg.shocks),
                (gg.dark and "Blackout: this job pays double. " or "") .. string.format("%d seconds", left) }
        end
        SendWires(g)
    end,
    tick = function(g, now)
        if now > g.limit then
            -- the breaker trips: a new board (and paid less)
            g.trips = (g.trips or 0) + 1
            Deal(g)
            g.limit = now + g.secs
            g.ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 70)
            g.ply:ChatPrint("[Maintenance] Too slow: the breaker tripped and the wires are scrambled. Start again (this job now pays less).")
            SendWires(g)
            return
        end
        -- the sparks jump about
        local moved = false
        for _, sp in ipairs(g.sparks) do
            if now >= sp.moveAt then
                local k
                for _ = 1, 6 do
                    k = math.random(g.w * g.h)
                    local taken = false
                    for _, o in ipairs(g.sparks) do if o ~= sp and o.k == k then taken = true end end
                    if not taken and k ~= sp.k then break end
                end
                sp.k, sp.since, sp.moveAt = k, now, now + 1.2 + math.random() * 1.4
                moved = true
            end
        end
        if moved then SendWires(g) end
    end,
    finish = function(g)
        net.Start("lc_wire_open") net.WriteString("{}") net.Send(g.ply) -- (closes the panel)
    end,
}

-- Turn tile k a quarter (ccw: back the other way). True when it turns, false when a spark bites.
function LC.WireTry(ply, k, ccw)
    local g = LC.JobGames[ply]
    if not g or g.kind ~= "wiring" or not g.tiles[k] then return nil end
    local now = CurTime()
    for _, sp in ipairs(g.sparks) do
        -- (a spark that only just landed there doesn't count: the click was on its way)
        if sp.k == k and now - sp.since >= 0.3 then
            g.shocks = g.shocks + 1
            g.limit = g.limit - 4
            ply:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 70)
            local d = DamageInfo and DamageInfo()
            if d and ply.TakeDamageInfo then d:SetDamage(4) d:SetDamageType(DMG_SHOCK) d:SetAttacker(game.GetWorld and game.GetWorld() or ply) ply:TakeDamageInfo(d) end
            if EffectData then local fx = EffectData() fx:SetOrigin(ply:EyePos() + ply:GetAimVector() * 30) util.Effect("Sparks", fx, true, true) end
            SendWires(g, k)
            return false
        end
    end
    g.tiles[k] = ccw and TurnCCW(g.tiles[k]) or TurnCW(g.tiles[k])
    g.turns = g.turns + 1
    ply:EmitSound("buttons/lightswitch2.wav", 55, math.random(95, 110))
    local _, done = Lit(g)
    if done then
        ply:EmitSound("buttons/lever7.wav", 60)
        local base = math.max(1, 3 + math.max(0, 3 - g.shocks) - 2 * (g.trips or 0))
        if g.turns <= g.par + 2 then base = base + 2 g.notes[#g.notes + 1] = "Finished in close to the fewest turns: 2 credits bonus." end
        if g.dark then base = base * 2 g.notes[#g.notes + 1] = "Blackout: pay doubled." end
        g.pay = base
        if g.shocks == 0 then g.notes[#g.notes + 1] = "Not shocked once." end
        if g.opts.onFixed then pcall(g.opts.onFixed) end
        LC.JobGameEnd(ply, "done")
        return true
    end
    SendWires(g)
    return true
end

net.Receive("lc_wire_try", function(_, ply)
    local k, ccw = net.ReadUInt(6), net.ReadBool()
    LC.WireTry(ply, k, ccw)
end)

------------------------------------------------------------------------
-- Triage (Clinic Medic): patients bleeding out at different rates. Treat
-- them with the medkit (primary fire) before they're gone: the worst first.
------------------------------------------------------------------------

-- How fast each gets worse (health a second, roughly): an emergency department's mix, not everyone
-- bleeding out alike (the owner: a broken arm isn't dying like someone bleeding out). 0: stable, in pain, can wait.
local INJURIES = {
    { label = "Gunshot wound, bleeding heavily", rate = 2.2 }, { label = "Stab wound", rate = 1.6 },
    { label = "Electrocuted, heart racing", rate = 1.8 }, { label = "Head injury (blunt force)", rate = 1.2 },
    { label = "Crushed under rubble", rate = 1.0 }, { label = "Stunstick beating", rate = 0.8, beaten = true },
    { label = "Severe burns", rate = 0.5 }, { label = "Smoke inhalation", rate = 0.6 },
    { label = "Broken arm", rate = 0 }, { label = "Dislocated shoulder", rate = 0 },
}
local function Urgency(inj)
    if inj.rate <= 0 then return " (stable: can wait)" end
    if inj.rate >= 1.6 then return " (critical)" end
    return ""
end

GAMES.triage = {
    start = function(g)
        g.title = "Triage"
        local center = g.opts.center or g.ply:GetPos()
        -- as many patients going downhill as ever (3 or 4), and one more who's stable on top: someone who
        -- can wait doesn't make the shift easier (the owner)
        local deadly, stable = {}, {}
        for _, inj in ipairs(Shuffle(table.Copy(INJURIES))) do
            if inj.rate > 0 then deadly[#deadly + 1] = inj else stable[#stable + 1] = inj end
        end
        local inj = {}
        for i = 1, math.random(3, 4) do inj[#inj + 1] = deadly[(i - 1) % #deadly + 1] end
        if #stable > 0 then inj[#inj + 1] = stable[1] end
        local spots = {}
        for i, v in ipairs(g.opts.spots or {}) do spots[i] = v end
        while #spots < #inj do
            local k = #spots + 1
            spots[k] = center + Vector(math.cos(k * 1.25) * 110, math.sin(k * 1.25) * 110, 0)
        end
        g.patients, g.saved, g.lost = {}, 0, 0
        for i = 1, #inj do
            if not (LC.Spawners and LC.Spawners.citizen) then break end
            local npc, st = LC.Spawners.citizen(spots[i])
            if IsValid(npc) and st then
                LC.SetState(npc, st, "event")
                st.eventUntil, st.questLock, st.unmanaged = CurTime() + 900, true, true
                if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
                local max = npc:GetMaxHealth() > 0 and npc:GetMaxHealth() or 40
                npc:SetHealth(math.floor(max * math.Rand(0.35, 0.55)))
                local injury = inj[(i - 1) % #inj + 1]
                g.patients[#g.patients + 1] = { npc = npc, injury = injury, max = max, hp = npc:Health() }
                npc:SetNW2Bool("lc_patient", true)
                npc:SetNW2String("lc_injury", injury.label)
                npc:SetNW2Int("lc_hpmax", max)
                g.props[#g.props + 1] = npc
            end
        end
        if #g.patients == 0 then error("no patients") end
        g.ply:ChatPrint("[Clinic] Patients are coming in, and their health keeps dropping. Aim your medkit at a patient and left click to heal them, until each one is almost fully healed. Treat the worst injuries first (critical ones go downhill fast; a broken arm can wait): a patient whose health reaches zero dies.")
        g.hud = function(gg)
            local lines = { string.format("Saved: %d    Lost: %d    Waiting: %d", gg.saved, gg.lost, #gg.patients - gg.saved - gg.lost) }
            for _, p in ipairs(gg.patients) do
                if not p.done then lines[#lines + 1] = string.format("%s%s: %d%%", p.injury.label, Urgency(p.injury), math.floor(100 * p.hp / p.max)) end
            end
            return lines
        end
    end,
    tick = function(g, now)
        for _, p in ipairs(g.patients) do
            if not p.done then
                local npc = p.npc
                if not IsValid(npc) or npc:Health() <= 0 then
                    p.done, g.lost = true, g.lost + 1
                    g.ply:ChatPrint("[Clinic] A patient has died: " .. p.injury.label .. ".")
                else
                    -- the medkit heals them; the wound takes them back down
                    local hp = npc:Health()
                    if hp > p.hp then p.healed = true end
                    p.drain = (p.drain or 0) + p.injury.rate * 0.1 * (p.healed and 0.5 or 1)
                    if p.drain >= 1 then
                        local d = math.floor(p.drain)
                        p.drain = p.drain - d
                        hp = hp - d
                        npc:SetHealth(math.max(0, hp))
                        if hp <= 0 then
                            p.done, g.lost = true, g.lost + 1
                            npc:SetNW2Bool("lc_patient", false)
                            if npc.TakeDamage then pcall(npc.TakeDamage, npc, 100, game.GetWorld and game.GetWorld() or npc) end
                            g.ply:ChatPrint("[Clinic] A patient has died: " .. p.injury.label .. ".")
                        end
                    end
                    if not p.done and npc:Health() >= p.max * 0.9 then
                        p.done, g.saved = true, g.saved + 1
                        npc:SetNW2Bool("lc_patient", false)
                        npc:EmitSound("vo/npc/" .. (((LC.NPCs[npc] or {}).gender == "female") and "female01" or "male01") .. "/thanks0" .. math.random(1, 2) .. ".wav", 70)
                        if p.injury.beaten then
                            local pst = LC.NPCs[npc]
                            local she = (pst and pst.gender == "female") or string.find(string.lower(npc:GetModel() or ""), "female", 1, true)
                            g.ply:ChatPrint("[Clinic] " .. (she and "She" or "He") .. " grabs your wrist on the way out. 'Thank you. Please... don't write down what did this.'")
                        end
                    end
                    p.hp = npc:Health()
                    npc:SetNW2Int("lc_hp", p.hp)
                end
            end
        end
        local open = 0
        for _, p in ipairs(g.patients) do if not p.done then open = open + 1 end end
        if open == 0 then
            g.pay = g.saved * 4 - g.lost * 2
            if g.lost == 0 then g.pay = g.pay + 6 g.notes[#g.notes + 1] = "Every patient survived: 6 credits bonus." end
            g.notes[#g.notes + 1] = string.format("%d patients saved, %d lost.", g.saved, g.lost)
            -- the survivors go home in their own time
            for _, p in ipairs(g.patients) do
                if IsValid(p.npc) and p.npc:Health() > 0 then
                    for i, e in ipairs(g.props) do if e == p.npc then table.remove(g.props, i) break end end
                    local st = LC.NPCs and LC.NPCs[p.npc]
                    if st then st.questLock, st.eventUntil = nil, 0 LC.SetState(p.npc, st, "idle") st.untilT = CurTime() + 3 end
                    SafeRemoveEntityDelayed(p.npc, 60)
                end
            end
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
}

------------------------------------------------------------------------
-- Rubble (Reclamation Crew): a pile of broken concrete to smash apart with
-- a crowbar (lent for the shift if you haven't one). Each block breaks
-- into scrap you can pocket; now and then something else is under there.
------------------------------------------------------------------------

local CHUNKS = {}
for _, m in ipairs({ "models/props_debris/concrete_chunk01a.mdl", "models/props_debris/concrete_chunk02a.mdl",
    "models/props_debris/concrete_chunk03a.mdl", "models/props_debris/concrete_chunk04a.mdl", "models/props_junk/cinderblock01a.mdl" }) do
    if Valid(m) then CHUNKS[#CHUNKS + 1] = m end
end
if #CHUNKS == 0 then CHUNKS = { "models/props_junk/cinderblock01a.mdl" } end

GAMES.rubble = {
    start = function(g)
        g.title = "Rubble"
        local pos = g.opts.pos or (g.ply:GetPos() + g.ply:GetForward() * 80)
        g.chunks, g.broken = {}, 0
        for i = 1, math.random(4, 6) do
            local a = math.random() * math.pi * 2
            local at = pos + Vector(math.cos(a), math.sin(a), 0) * math.random(0, 50) + Vector(0, 0, 6 + (i % 2) * 10)
            local e = Spawn(Pick(CHUNKS), at, Angle(math.random(0, 359), math.random(0, 359), math.random(0, 359)), true)
            if IsValid(e) then
                e.lcRubble = g
                e.lcHits = math.random(2, 4)
                e:SetNW2Bool("lc_rubble", true)
                g.chunks[#g.chunks + 1] = e
                g.props[#g.props + 1] = e
            end
        end
        if #g.chunks == 0 then error("no rubble") end
        g.total = #g.chunks
        if not g.ply:HasWeapon("weapon_crowbar") then
            g.ply:Give("weapon_crowbar")
            g.lent = true
        end
        g.ply.lcJobCrowbar = true
        if g.ply.SelectWeapon then g.ply:SelectWeapon("weapon_crowbar") end
        g.ply:ChatPrint("[Reclamation] Smash every block in the pile with your crowbar (left click). Each broken block drops a piece of scrap you can pick up, and sometimes something else. You're paid 1 credit per block.")
        g.hud = function(gg) return { string.format("Blocks broken: %d of %d", gg.broken, gg.total), "Hit the blocks with the crowbar (left click)" } end
    end,
    tick = function(g)
        if g.broken >= g.total then
            g.pay = g.total
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
    finish = function(g)
        if IsValid(g.ply) then
            g.ply.lcJobCrowbar = nil
            if g.lent and g.ply:HasWeapon("weapon_crowbar") and g.ply.StripWeapon then g.ply:StripWeapon("weapon_crowbar") end
        end
    end,
}

-- A blow lands on a block: it cracks, then breaks.
local function Smash(ent, g)
    ent.lcHits = (ent.lcHits or 1) - 1
    ent:EmitSound("physics/concrete/concrete_impact_hard" .. math.random(1, 3) .. ".wav", 70)
    if EffectData then
        local fx = EffectData() fx:SetOrigin(ent:WorldSpaceCenter()) fx:SetScale(1)
        util.Effect("GlassImpact", fx, true, true)
    end
    if ent.lcHits > 0 then return end
    g.broken = g.broken + 1
    ent:EmitSound("physics/concrete/concrete_break" .. math.random(2, 3) .. ".wav", 75)
    local at = ent:WorldSpaceCenter()
    for i, c in ipairs(g.chunks) do if c == ent then table.remove(g.chunks, i) break end end
    ent:Remove()
    if LC.SpawnWorldItem then
        LC.SpawnWorldItem("scrap", at + Vector(0, 0, 8))
        if math.random() < 0.15 then LC.SpawnWorldItem(Pick({ "gun_parts", "chemicals", "ration" }), at + Vector(0, 0, 12)) end
    end
end
LC.RubbleSmash = Smash

hook.Add("EntityTakeDamage", "LivingCityJobRubble", function(ent, dmg)
    local g = IsValid(ent) and ent.lcRubble
    if not g or LC.JobGames[g.ply] ~= g then return end
    if dmg:GetAttacker() ~= g.ply then return true end
    local inf = dmg:GetInflictor()
    local club = dmg:IsDamageType(DMG_CLUB) or (IsValid(inf) and inf:GetClass() == "weapon_crowbar")
    if club then Smash(ent, g) end
    return true
end)

------------------------------------------------------------------------
-- For the other games (sv_livingcity_moregames.lua): a game can have a
-- panel on screen (lc_jg_panel, answered with lc_jg_act), and E on things
-- in the world (def.use). LC.JobGameKit is the toolbox above.
------------------------------------------------------------------------

util.AddNetworkString("lc_jg_panel") -- server -> client: { kind, ... } ({} closes it)
util.AddNetworkString("lc_jg_act")   -- client -> server: action, argument (JSON)
util.AddNetworkString("lc_radio_listen") -- server -> client: your own radio switched on ({ dial, ... }) or off ({})
util.AddNetworkString("lc_radio_dial")   -- client -> server: where you've turned your radio's dial (0 switches it off)
util.AddNetworkString("lc_radio_bench") -- server -> nearby clients: a radio repair set, as it is tuned (sv_livingcity_moregames.lua)

function LC.JobGameDefine(kind, def) GAMES[kind] = def end
function LC.JobGameDef(kind) return GAMES[kind] end

-- Show (or update) the game's panel; nil closes it.
function LC.JobGamePanel(g, data)
    if not g or not IsValid(g.ply) then return end
    if data then data.kind = data.kind or g.kind g.panelOpen = true else g.panelOpen = nil end
    LC.SendCompressed("lc_jg_panel", data or {}, { g.ply })
end

-- Something done on the panel. Returns whatever the game says.
function LC.JobGameAct(ply, action, arg)
    local g = LC.JobGames[ply]
    local def = g and GAMES[g.kind]
    if g and action == "closed" then g.panelOpen = nil return true end -- (they shut it: E brings it back)
    if not def or not def.act then return nil end
    local ok, r = pcall(def.act, g, tostring(action or ""), arg)
    if not ok then if LC.Error then LC.Error("job game " .. g.kind, r) end return nil end
    g.nextHud = 0
    return r
end

-- E on something in the world, for the game that wants it.
function LC.JobGameUse(ply, ent)
    local g = LC.JobGames[ply]
    local def = g and GAMES[g.kind]
    if not def or not def.use or not IsValid(ent) then return nil end
    local ok, r = pcall(def.use, g, ent)
    if not ok then if LC.Error then LC.Error("job game " .. g.kind, r) end return nil end
    g.nextHud = 0
    return r
end

-- Close a panel left open when the game ends, however it ends.
local baseEnd = LC.JobGameEnd
function LC.JobGameEnd(ply, how)
    local g = LC.JobGames[ply]
    if g and g.panelOpen and IsValid(ply) then LC.SendCompressed("lc_jg_panel", {}, { ply }) end
    return baseEnd(ply, how)
end

hook.Add("KeyPress", "LivingCityJobGameUse", function(ply, key)
    if key ~= IN_USE then return end
    local g = LC.JobGames[ply]
    if not g or not GAMES[g.kind].use then return end
    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if IsValid(ent) and ent:GetPos():DistToSqr(ply:GetPos()) < 160 * 160 then LC.JobGameUse(ply, ent) end
end)

net.Receive("lc_jg_act", function(_, ply)
    local action = net.ReadString()
    local knob = action == "dial" or action == "screw"
    local key = knob and "lcJgDialAt" or "lcJgActAt" -- (turning a dial or a screw never eats a click)
    if (ply[key] or 0) > CurTime() then return end
    ply[key] = CurTime() + (knob and 0.1 or 0.08)
    local arg = util.JSONToTable(net.ReadString() or "") or {}
    LC.JobGameAct(ply, action, arg.v)
end)

-- Mark a thing for this player's game (the client outlines it). col: "target", "person", "danger", "done"
local function Mark(ent, ply, col)
    if not IsValid(ent) then return end
    ent:SetNW2Entity("lc_jg_owner", ply)
    ent:SetNW2String("lc_jg_mark", col or "target")
end

-- Is a Civil Protection unit (or anyone, with others) looking at them, within dist? The unit, or nil.
local function Watcher(ply, dist, others)
    local eye = ply:EyePos()
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (LC.IsSecurity(st) or (others and st.role == "citizen" and not st.questLock)) then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            local lim = LC.IsSecurity(st) and dist or dist * 0.45
            if d < lim * lim and (not bd or d < bd) then
                local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
                if tr.Fraction > 0.97 and not (LC.SmokeBlocks and LC.SmokeBlocks(npc:EyePos(), eye)) then best, bd = npc, d end
            end
        end
    end
    return best
end

-- A citizen for a game (a traveler, a resident, a suspect): stands where it's put, belongs to the game.
local function Extra(g, pos, secs)
    if not (LC.Spawners and LC.Spawners.citizen) then return nil end
    local npc, st = LC.Spawners.citizen(pos)
    if not IsValid(npc) or not st then return nil end
    LC.SetState(npc, st, "event")
    st.eventUntil, st.questLock, st.unmanaged = CurTime() + (secs or 900), true, true
    if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
    g.props[#g.props + 1] = npc
    return npc, st
end

-- Let one of them go about their business (and out of the game's props).
local function Release(g, npc, walkTo, secs)
    if not IsValid(npc) then return end
    for i, e in ipairs(g.props) do if e == npc then table.remove(g.props, i) break end end
    npc:SetNW2String("lc_jg_mark", "")
    local st = LC.NPCs and LC.NPCs[npc]
    if walkTo then
        if npc.SetLastPosition then npc:SetLastPosition(walkTo) npc:SetSchedule(SCHED_FORCED_GO_RUN) end
    elseif st then
        st.questLock, st.unmanaged, st.eventUntil = nil, nil, 0
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 3
    end
    SafeRemoveEntityDelayed(npc, secs or 60)
end

LC.JobGameKit = {
    Pick = Pick, Valid = Valid, FirstValid = FirstValid, Phys = Phys, Held = Held, Spawn = Spawn, InBox = InBox,
    Shuffle = Shuffle, Hud = Hud, Mark = Mark, Watcher = Watcher, Extra = Extra, Release = Release,
}
