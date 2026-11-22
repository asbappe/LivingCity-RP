--[[
    Living City: the walled garden's planting spots

    The owner, 20 November: "Make the garden beds have some sort of entity or
    brush that allows the gamemode to register the beds as planting spots,
    with about 8 evenly but slightly off kilter planting spots" (melons and
    pumpkins). The map's garden module (_dev/tools/map_mods_b.py, m_garden)
    puts info_targets lc_garden_plot_1 to _8 on the soil of its beds.

      The plots     one at each lc_garden_plot_N the map has (none: nothing
                    happens). Plots 1 to 4 grow melons, 5 to 8 pumpkins.
      Planting      E on the bare soil there with a seed packet (or Use the
                    packet from your pockets standing by one). The plant
                    shows: a sprout that swells into its melon or pumpkin
                    over lc_garden_minutes (a pumpkin takes half as long
                    again), then E to pick it: vegetables, 3 from a melon,
                    4 from a pumpkin. Anyone may plant and pick.
      Units         a plot inside rebel territory is the Resistance's: Civil
                    Protection pull it up (E), as they do the pots.
      Nothing new   no new settings, items or commands (lc_garden_minutes is
                    the pots' own).
]]

if CLIENT then return end

LC = LC or {}
LC.Garden = LC.Garden or {}
local G = LC.Garden

G.MAX = 16                 -- lc_garden_plot_1 .. _16 are looked for (the garden module has 8)
G.CROPS = {
    melon   = { model = "models/props_junk/watermelon01.mdl", yield = 3, slow = 1.0, name = "Melon" },
    pumpkin = { model = "models/props_outland/pumpkin01.mdl", yield = 4, slow = 1.5, name = "Pumpkin" },
}
G.SPROUT = 0.2             -- the size a plant starts at, of its full size
G.Plots = G.Plots or {}    -- [n] = the plot's prop

function G.CropFor(n) return (n or 1) <= 4 and "melon" or "pumpkin" end

local function Minutes()
    local cv = GetConVar("lc_garden_minutes")
    return cv and cv:GetFloat() or 8
end

-- Show the plot as it is: nothing on bare soil, the crop at its size while it grows.
local function Show(e)
    local s = e.lcPlot
    if s.state == "empty" then
        e:SetNoDraw(true)
        e:SetModelScale(G.SPROUT)
    else
        e:SetNoDraw(false)
        local grown = 1
        if s.state == "growing" then
            local span = math.max(1, s.readyAt - s.plantedAt)
            grown = math.Clamp((CurTime() - s.plantedAt) / span, 0, 1)
        end
        e:SetModelScale(G.SPROUT + (1 - G.SPROUT) * grown, 4)
    end
end

function G.Set(e, state, readyAt)
    if not (IsValid(e) and e.lcPlot) then return end
    local s = e.lcPlot
    s.state, s.readyAt = state, readyAt or 0
    if state == "growing" then s.plantedAt = CurTime() end
    if state == "empty" then s.planter = nil end
    e:SetNW2String("lc_pot_state", state)
    e:SetNW2Float("lc_pot_ready", readyAt or 0)
    Show(e)
end

-- One plot's prop, on the soil at the map's spot: the crop's own model, hidden while the soil is bare, and
-- out of everyone's way underfoot (debris: E finds it, feet don't).
local function MakePlot(n, target)
    local crop = G.CropFor(n)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(G.CROPS[crop].model)
    e:SetPos(target:GetPos() + Vector(0, 0, 2))
    e:SetAngles(Angle(0, target.GetAngles and target:GetAngles().y or 0, 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if e.SetCollisionGroup then e:SetCollisionGroup(COLLISION_GROUP_DEBRIS or 1) end
    e.lcPlot = { n = n, crop = crop, state = "empty", readyAt = 0 }
    e:SetNW2String("lc_label_kind", "plot")
    e:SetNW2String("lc_plot_crop", crop)
    G.Set(e, "empty")
    return e
end

-- Find the map's spots and put a plot on each that has none. -> how many plots there are.
function G.Ensure()
    local n = 0
    for k = 1, G.MAX do
        local target = ents.FindByName("lc_garden_plot_" .. k)[1]
        if IsValid(target) then
            if not IsValid(G.Plots[k]) then G.Plots[k] = MakePlot(k, target) end
            if IsValid(G.Plots[k]) then n = n + 1 end
        elseif IsValid(G.Plots[k]) then
            G.Plots[k]:Remove()
            G.Plots[k] = nil
        end
    end
    return n
end

-- The plot nearest a player, within reach.
function G.Near(ply, r)
    local best, bd
    for _, e in pairs(G.Plots) do
        local d = IsValid(e) and e:GetPos():DistToSqr(ply:GetPos())
        if d and d < (r or 120) ^ 2 and (not bd or d < bd) then best, bd = e, d end
    end
    return best
end

local function Rebel(e) return LC.InRebelZone and LC.InRebelZone(e:GetPos()) and true or false end

function G.Plant(ply, e)
    local s = e.lcPlot
    if s.state ~= "empty" then return false end
    if not LC.HasItem(ply, "seeds") then
        ply:ChatPrint("Bare soil. Plant a seed packet here.")
        return false
    end
    LC.TakeItem(ply, "seeds")
    G.Set(e, "growing", CurTime() + Minutes() * 60 * G.CROPS[s.crop].slow)
    s.planter = ply
    e:EmitSound("player/footsteps/dirt" .. math.random(1, 4) .. ".wav", 60)
    hook.Run("LivingCityPlanted", ply, e)
    return true
end

function G.Use(ply, e)
    local s = e.lcPlot
    if not s then return end
    if s.state == "growing" and CurTime() >= s.readyAt then G.Set(e, "ripe") end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) and Rebel(e) then
        if s.state ~= "empty" then
            G.Set(e, "empty")
            e:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 65)
            if LC.AddXP then LC.AddXP(ply, 3, "uprooted an illegal garden") end
        end
        return
    end
    if s.state == "empty" then return G.Plant(ply, e) end
    if s.state == "ripe" then
        if LC.InvSpace(ply) < 1 then ply:ChatPrint("Your pockets are full.") return end
        local n = math.min(G.CROPS[s.crop].yield, LC.InvSpace(ply, "vegetables"))
        LC.GiveItem(ply, "vegetables", n)
        local planter = s.planter
        G.Set(e, "empty")
        e:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 60)
        if IsValid(planter) and planter ~= ply then planter:ChatPrint("Someone's picked what you grew in the garden.") end
        hook.Run("LivingCityHarvested", ply, e, n)
    end
    -- (growing: the plant shows how far along it is, and its label the time left)
end

hook.Add("PlayerUse", "LivingCityGardenPlots", function(ply, ent)
    if not (IsValid(ent) and ent.lcPlot) then return end
    if (ply.lcPropUseNext or 0) > CurTime() then return false end
    ply.lcPropUseNext = CurTime() + 0.6
    G.Use(ply, ent)
    return false
end)

-- plots set up as soon as the map's spots are there, and the plants grow
timer.Create("LivingCityGarden", 5, 0, function()
    LC.Try(function()
        G.Ensure()
        local now = CurTime()
        for _, e in pairs(G.Plots) do
            if IsValid(e) and e.lcPlot and e.lcPlot.state == "growing" then
                if now >= e.lcPlot.readyAt then G.Set(e, "ripe") else Show(e) end
            end
        end
    end)
end)
hook.Add("PostCleanupMap", "LivingCityGarden", function() G.Plots = {} end)
