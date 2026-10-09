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
          inside (risky, if a unit sees).

      Papers check (Station Porter)   Travelers step up to you one at a time.
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
        if pay > 0 and LC.AddCredits then LC.AddCredits(ply, pay, g.title) end
        if IsValid(ply) and LC.Notice then
            local text = (#g.notes > 0 and (table.concat(g.notes, " ") .. " ") or "") .. (pay > 0 and string.format("Paid %d credits for the work, on top of the shift.", pay) or "Nothing extra for that.")
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

local CARTS = { "models/props_wasteland/laundry_cart001.mdl", "models/props_wasteland/laundry_cart002.mdl", "models/props_junk/PushCart01a.mdl" }
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
    "A scrap of paper, folded small: 'Kleiner lives.' Underneath, a lambda.",
    "A ration wrapper with a map drawn on the inside: the canal, and an X.",
    "A note in a child's hand: 'Papa, they took the man from 4C. Come home the back way.'",
    "Half a Combine notice, the rest torn away: '...relocation of all residents of Block...'",
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
    local ph = Phys(cart)
    if ph and ph.ComputeShadowControl then
        ph:Wake()
        ph:ComputeShadowControl({ secondstoarrive = 0.15, pos = Vector(want.x, want.y, cart:GetPos().z), angle = Angle(0, fwd:Angle().y + 90, 0),
            maxangular = 400, maxangulardamp = 800, maxspeed = 400, maxspeeddamp = 600, dampfactor = 0.8, teleportdistance = 0, deltatime = 0.1 })
    else
        cart:SetPos(Vector(want.x, want.y, cart:GetPos().z))
    end
end

GAMES.sweep = {
    start = function(g)
        g.title = "Street sweep"
        local depot = g.opts.depot or g.ply:GetPos()
        g.depot = depot
        local cartPos = depot + Vector(0, 0, 4)
        g.cart = Spawn(FirstValid(CARTS), cartPos, Angle(0, g.ply:EyeAngles().y, 0))
        if not IsValid(g.cart) then error("no cart") end
        g.cart.lcCart = g
        local ph = Phys(g.cart)
        if ph then ph:SetMass(80) end
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
                            p:ChatPrint(string.format("[Sanitation] Wedged in it: %d credits in Union tokens. Finders keepers.", n))
                        elseif what == "note" then
                            if LC.Notice then LC.Notice(p, "event", "Found in the rubbish", Pick(NOTES), 10) end
                        else
                            LC.GiveOrDrop(p, what, 1)
                            p:ChatPrint("[Sanitation] Tucked inside it: " .. (LCS.Items[what] and LCS.Items[what].name or what) .. ". It's in your pockets.")
                        end
                    end
                end
                g.litter[#g.litter + 1] = e
                g.props[#g.props + 1] = e
                g.need = g.need + 1
            end
        end
        g.limit = CurTime() + 420
        g.ply:ChatPrint("[Sanitation] Your cart's at the depot. E on it to push it (E again to let go). Pick up the rubbish with E and throw it in (left click). Bring the cart back when it's full.")
        g.hud = function(gg)
            local left = math.max(0, math.ceil(gg.limit - CurTime()))
            local lines = { string.format("In the cart: %d of %d", gg.got, gg.need) }
            if gg.swish > 0 then lines[#lines + 1] = string.format("Long throws: %d", gg.swish) end
            lines[#lines + 1] = gg.got >= gg.need and "Full: push the cart back to the depot" or (gg.pushing and "Pushing the cart (E to let go)" or "E on the cart to push it")
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
                g.notes[#g.notes + 1] = "Quick work: the foreman nods."
            end
            if g.swish >= 3 then g.notes[#g.notes + 1] = string.format("%d long throws into the cart.", g.swish) end
            cart:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 75)
            return LC.JobGameEnd(g.ply, "done")
        end
        if now > g.limit then
            g.notes[#g.notes + 1] = "Out of time: what's in the cart counts."
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
        ply:ChatPrint("[Sanitation] You let go of the cart.")
    elseif tr and tr.Entity == g.cart and ply:GetPos():DistToSqr(g.cart:GetPos()) < CART_REACH * CART_REACH then
        g.pushing = true
    end
end)
-- (nobody walks off with the cart in their arms)
hook.Add("AllowPlayerPickup", "LivingCityJobCart", function(ply, ent) if ent.lcCart then return false end end)

------------------------------------------------------------------------
-- On the line (Factory)
------------------------------------------------------------------------

local PARTS = {
    "models/props_lab/reciever01a.mdl", "models/props_lab/reciever01b.mdl", "models/props_c17/canister01a.mdl",
    "models/props_lab/harddrive01.mdl", "models/props_junk/metal_paintcan001a.mdl", "models/props_c17/TrapPropeller_Lever.mdl",
    "models/props_lab/tpplug.mdl", "models/props_junk/garbage_metalcan001a.mdl",
}
local BIN = FirstValid({ "models/props_junk/TrashBin01a.mdl", "models/props_trainstation/trashcan_indoor001a.mdl" })
local RUST = Color(170, 95, 60)
local TOTAL_PARTS = 20

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
        g.title = "On the line"
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
        g.ply:ChatPrint("[Factory] The line's starting. Rust-red, sparking parts are bad: grab them (E) and throw them in the scrap bin. Let the good ones go through.")
        g.hud = function(gg)
            return {
                string.format("Parts: %d of %d", gg.spawned, TOTAL_PARTS),
                string.format("Bad parts binned: %d    Good parts through: %d", gg.caught, gg.shipped),
                string.format("Bad parts let through: %d    Good parts binned: %d", gg.missed, gg.wasted),
            }
        end
    end,
    tick = function(g, now)
        local b = g.belt
        if not IsValid(g.conv) then return LC.JobGameEnd(g.ply, "done") end
        -- the next part onto the belt, sooner as the shift goes on
        if g.spawned < TOTAL_PARTS and now >= g.nextPart then
            g.spawned = g.spawned + 1
            local start = b.origin - b.dir * (b.len / 2 - 14) + Vector(0, 0, 10)
            local e = Spawn(Pick(PARTS), start, Angle(0, math.random(0, 359), 0))
            if IsValid(e) then
                e.lcPart = { bad = math.random() < 0.32, rattle = g.spawned == g.rattle, t = now }
                if e.lcPart.bad then
                    e:SetColor(RUST)
                    e:SetNW2Bool("lc_defect", true)
                end
                if e.lcPart.rattle then
                    e.lcOnPickup = function(p) if p == g.ply and e.lcPart then p:ChatPrint("[Factory] Something rattles inside this one. R while you're holding it to slip it in your pocket.") end end
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
                    else g.wasted = g.wasted + 1 g.pay = g.pay - 1 g.ply:ChatPrint("[Foreman] That one was good! Watch what you're binning.") end
                elseif along > b.len / 2 - 4 and math.abs(across) < b.wid / 2 + 6 then
                    done = true
                    if p.bad then g.missed = g.missed + 1 g.pay = g.pay - 2 g.ply:ChatPrint("[Foreman] A bad one went through! That comes out of your pay.")
                    else g.shipped = g.shipped + 1 g.pay = g.pay + 1 end
                elseif up < -20 and now - (e.lcDroppedAt or p.t) > 4 then
                    done = true -- on the floor: lost
                    if p.bad then g.caught = g.caught + 1 g.pay = g.pay + 1 else g.wasted = g.wasted + 1 g.pay = g.pay - 1 end
                elseif math.abs(across) < b.wid / 2 + 4 and up > -4 and up < 30 then
                    -- riding the belt
                    local ph = Phys(e)
                    if ph then
                        local v = ph:GetVelocity()
                        ph:SetVelocity(b.dir * g.speed + Vector(0, 0, math.min(v.z, 0)))
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
            if g.missed == 0 and g.wasted == 0 then
                g.pay = g.pay + 6
                g.notes[#g.notes + 1] = "A clean shift: not a single mistake."
            end
            g.notes[#g.notes + 1] = string.format("%d of %d bad parts caught; %d good parts through.", g.caught, bad, g.shipped)
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
    finish = function(g)
        if IsValid(g.conv) then g.conv:SetNW2Bool("lc_running", false) end
    end,
}

local CONTRABAND = { "gun_parts", "ammo_pistol", "chemicals", "radio_tuned" }

-- R while holding the rattling part: what's inside goes in your pocket.
hook.Add("KeyPress", "LivingCityJobLine", function(ply, key)
    if key ~= IN_RELOAD then return end
    local g = LC.JobGames[ply]
    local e = ply.lcHolding
    if not g or g.kind ~= "line" or not IsValid(e) or not (e.lcPart and e.lcPart.rattle) then return end
    local what = Pick(CONTRABAND)
    if not LCS.Items[what] then what = "gun_parts" end
    e.lcPart.rattle = false
    LC.GiveOrDrop(ply, what, 1)
    ply:ChatPrint("[Factory] You work it open and palm what's inside: " .. (LCS.Items[what] and LCS.Items[what].name or what) .. ".")
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
        LC.ReportCrime(ply, "Theft from the factory floor", 120)
        ply:ChatPrint("[Civil Protection] A unit saw that.")
    end
    hook.Run("LivingCityLineContraband", ply, what)
end)

------------------------------------------------------------------------
-- Papers check (Station Porter)
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
    local out = { "Papers must be in date.", "The photo must be the bearer." }
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

local function NextTraveler(g)
    g.current = nil
    if g.done >= TRAVELERS then return end
    local post = g.post
    local fwd = g.facing
    local from = post + fwd * 500
    if LC.GroundAt then from = LC.GroundAt(from) or from end
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
        g.ply:ChatPrint("[Station] Travelers will come to you. E on one to check their papers against today's rules: approve, deny, or call a unit.")
        g.hud = function(gg)
            local lines = { string.format("Travelers checked: %d of %d", gg.done, TRAVELERS), string.format("Right: %d    Citations: %d", gg.right, gg.cites), "Today's rules:" }
            for _, l in ipairs(RuleLines(gg.rules)) do lines[#lines + 1] = "  " .. l end
            if gg.current and gg.current.arrived then lines[#lines + 1] = "E on the traveler to see their papers" end
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
            g.notes[#g.notes + 1] = "Not a single citation."
        end
        g.notes[#g.notes + 1] = string.format("%d of %d calls right.", g.right, g.done)
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

local function Walk(npc, to, secs)
    if not IsValid(npc) then return end
    if npc.SetLastPosition then npc:SetLastPosition(to) npc:SetSchedule(SCHED_FORCED_GO) end
    SafeRemoveEntityDelayed(npc, secs or 8)
end

-- The call: "approve", "deny" or "unit". True when it was right.
function LC.PapersDecide(ply, choice)
    local g = LC.JobGames[ply]
    if not g or g.kind ~= "papers" or not g.current then return nil end
    local c = g.current
    local right, cite, note
    if c.forged then
        if choice == "unit" then right = true g.pay = g.pay + 5 note = "A forgery: the seal reads " .. c.papers.seal .. ". A unit takes them away."
            if LC.AddStanding then LC.AddStanding(ply, 2) end
        elseif choice == "deny" then right = true g.pay = g.pay + 2 note = "Denied. (The seal was forged: a unit would have wanted to know.)"
        else
            right = false
            hook.Run("LivingCityPapersForgeryPassed", ply)
            if math.random() < 0.3 then cite = "Approved forged papers (the seal read " .. c.papers.seal .. ")." g.pay = g.pay - 4
                if LC.AddStanding then LC.AddStanding(ply, -5) end
            else note = "They walk through. Under their breath: 'Thank you.'" end
        end
    elseif c.wrong then
        if choice == "deny" or choice == "unit" then right = true g.pay = g.pay + 3
        else right = false g.pay = g.pay - 2
            cite = ({ expiry = "Approved papers out of date.", photo = "Approved a traveler whose photo wasn't them.",
                district = "Approved entry from " .. tostring(g.rules.banned) .. ".", permit = "Approved a traveler with no transit permit.",
                union = "Approved work travel without a Union stamp." })[c.wrong]
        end
    else
        if choice == "approve" then right = true g.pay = g.pay + 3
        else right = false g.pay = g.pay - 2 cite = "Turned away a traveler whose papers were in order." end
    end
    g.done = g.done + 1
    if right then g.right = g.right + 1 end
    if cite then
        g.cites = g.cites + 1
        ply:EmitSound("buttons/combine_button_locked.wav", 60)
        if LC.Notice then LC.Notice(ply, "warn", "Citation", cite .. " Pay docked.", 6) end
    elseif note then
        ply:ChatPrint("[Station] " .. note)
    end
    if choice == "approve" then Walk(c.npc, c.stand - g.facing * 600, 9)
    elseif choice == "unit" then
        Walk(c.npc, c.from, 5)
        if IsValid(c.npc) then c.npc:EmitSound("vo/npc/male01/no02.wav", 70) end
    else Walk(c.npc, c.from, 9) end
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
