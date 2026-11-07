--[[
    Living City: ways to get by

    Everything a person can just do, found by playing rather than reading:
    F1 > What now? > Ways to get by (or !ways) lists it for who you are right
    now, one plain line each, with what it takes. Ready ones first; the rest
    say the one thing missing. Each has a button: show me the way there, or
    open the screen it happens on.
]]

if CLIENT then return end

LC = LC or {}

local function Price(id)
    local g = LCS and LCS.GoodsById and LCS.GoodsById[id]
    return g and g.price or nil
end

local function Has(ply, id) return LC.HasItem ~= nil and LC.HasItem(ply, id) end

-- The list for this person: { text, how, need (nil: ready), way (a place to mark), open (f2/f3/f4/characters) }
function LC.WaysToGetBy(ply)
    local out = {}
    local function Add(text, how, need, way, open) out[#out + 1] = { text = text, how = how, need = need, way = way, open = open } end
    local f = ply:GetNW2String("lcf_faction", "")
    local standing = LC.Standing and LC.Standing(ply) or 0
    local job = LC.Job and LC.Job(ply)

    if f == "stalker" then
        Add("Do the work you're given", "Your board (F3): The Stalker's Lot.", nil, nil, "f3")
        return out
    end

    if f == "cp" then
        Add("Take directives", "Patrols, stops and arrests for XP and rank: your board (F3).", nil, nil, "f3")
        Add("Get your issue", "Grenades, ammunition, armour and your ration at the Civil Protection Commissary.", nil, "cpsupply")
        Add("Kick a door in", "G (or F1 > Kick). Locked doors give on the second kick.")
        Add("Fly a scanner", "F1 > Unit tools, at a Combine console, a data terminal, or anywhere in the Nexus. Photographs earn XP; rebels go out as BOLOs.", nil, nil, "f1")
        if not LCF.IsOverwatch(ply) then
            local rank = ply:GetNW2Int("lcf_rank", 1)
            Add("Join the Overwatch", "A Division Leader is offered the conditioning: the Overwatch Candidate story on your board (F3).",
                rank < 3 and "Needs Division Leader (more XP)" or nil, nil, "f3")
        end
        return out
    end

    -- the citizen's city (the Resistance live in it too)
    Add("Eat and drink", "Your ration at a dispenser, every ten minutes; water from a sink or a machine.", nil, "dispenser")
    Add("Search bins and dumpsters", "E on any bin: scrap, food, things to sell or make with.", nil, "bin")
    if job then
        Add("Work a shift as " .. (job.name or "a Union worker"), "Shifts pay credits: your board (F3).", nil, "work", "f3")
    else
        Add("Get a Union job", "Twelve to choose from on your board (F3). Shifts pay credits.", nil, nil, "f3")
    end
    local license, stall = Has(ply, "business_license"), Has(ply, "vendor_stall")
    if license and stall then
        Add("Sell from a market stall", "Set your stall down from your pockets (F2), then look at it with your pockets open to put things on it.", nil, nil, "f2")
    elseif license then
        Add("Sell from a market stall", string.format("Buy a market stall at the Commissary (%d credits) and set it down; or look at the one you have, with your pockets open.", Price("vendor_stall") or 60), nil, "shop")
    else
        Add("Sell from a market stall", string.format("A CWU business license (%d credits), then a stall, both at the Commissary.", Price("business_license") or 75),
            standing < 50 and string.format("Needs Civil Standing 50 (you have %d)", standing) or nil, "shop")
    end
    Add("Rent an apartment", "Look at a free apartment door with empty hands and right click: 40 credits for three hours, and a lock of your own.")
    Add("Salvage junk", "Hold a crowbar and press E on wrecks, engines, pipes and radiators.", not Has(ply, "crowbar") and not ply:HasWeapon("weapon_crowbar") and "Needs a crowbar (bins, or the black market)" or nil)
    Add("Fish the canal", string.format("A fishing line (Commissary, %d credits): Fish from your pockets, at the water.", Price("fishing_line") or 15),
        not Has(ply, "fishing_line") and "Needs a fishing line" or nil, "shop")
    Add("Write notes and posters", "Paper (Commissary, or bins): Write, from your pockets (F2).", not Has(ply, "paper") and "Needs paper" or nil, "shop")
    if f == "resistance" then
        Add("Run operations", "Raids, breakouts and supply runs: your board (F3).", nil, nil, "f3")
        Add("Get what the cell makes", "The scientist at the lab: vests, jammers, medicine, and decoding chips.", nil, "lab")
    elseif f == "citizen" or f == "" then
        local need = 100
        Add("Join Civil Protection", "Put on the uniform: F4.", standing < need and string.format("Needs Civil Standing %d (you have %d)", need, standing) or nil, nil, "f4")
        Add("Join the Resistance", "F4. The low ranks still pass for citizens; the higher you rise, the more you're hunted.", nil, nil, "f4")
    end
    if GetConVar("lc_char_slots") and GetConVar("lc_char_slots"):GetInt() >= 2 then
        Add("Be someone else", "Your other characters, close calls left, and your lives so far: !characters.", nil, nil, "characters")
    end
    -- ready ones first
    local ready, later = {}, {}
    for _, w in ipairs(out) do if w.need then later[#later + 1] = w else ready[#ready + 1] = w end end
    for _, w in ipairs(later) do ready[#ready + 1] = w end
    return ready
end

function LC.SendWays(ply)
    if not IsValid(ply) or not LC.SendCompressed then return false end
    LC.SendCompressed("lc_ways", { ways = LC.WaysToGetBy(ply) }, ply)
    return true
end

if util.AddNetworkString then util.AddNetworkString("lc_ways") end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.ways = function(ply) LC.SendWays(ply) end
