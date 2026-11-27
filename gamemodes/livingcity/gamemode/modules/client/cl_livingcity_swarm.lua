--[[
    Living City: the Swarm, as you see it (sv_livingcity_swarm.lua). No words anywhere:

      the essence in the nest brightens while it is harvested (the server says how far: its lc_swarm_glow);
      whoever carries the extract glows with it (lc_swarm_carry), and so does the essence in a vortigaunt's hands;
      freed vortigaunts at the ritual stand in a purple light (lc_swarm_chant), as Episode Two's turn blue;
      the city falling to the swarm: the ground shakes and rumbles for everyone (lc_swarm_fall).
    (The dropped extract lights itself: entities/lc_swarm_extract.lua.)
]]

LC_CL = LC_CL or {}
LC_CL.Swarm = LC_CL.Swarm or {}
local SW = LC_CL.Swarm

local glow = Material("sprites/light_glow02_add")
local GLOW, PURPLE = Color(190, 255, 140), Color(175, 90, 255)

-- What glows now: { pos, col, size (of the light), sprite (its size), id }.
function SW.Glowing()
    local out = {}
    local ess = GetGlobal2Entity("lc_swarm_essence", NULL)
    if IsValid(ess) then
        local f = ess:GetNW2Float("lc_swarm_glow", 0)
        if f > 0 then out[#out + 1] = { pos = ess:GetPos(), col = GLOW, size = 120 + 380 * f, sprite = 30 + 120 * f, id = ess:EntIndex() } end
    end
    local hand = GetGlobal2Entity("lc_swarm_inhand", NULL)
    if IsValid(hand) then out[#out + 1] = { pos = hand:GetPos(), col = GLOW, size = 150, sprite = 26, id = hand:EntIndex() } end
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:Alive() then
            if p:GetNW2Bool("lc_swarm_carry", false) then
                out[#out + 1] = { pos = p:GetPos() + Vector(0, 0, 40), col = GLOW, size = 190, sprite = 0, id = p:EntIndex() }
            end
            if p:GetNW2Bool("lc_swarm_chant", false) then
                out[#out + 1] = { pos = p:GetPos() + Vector(0, 0, 50), col = PURPLE, size = 220, sprite = 70, id = p:EntIndex() + 4096 }
            end
        end
    end
    for _, v in ipairs(ents.FindByClass and ents.FindByClass("npc_vortigaunt") or {}) do
        if IsValid(v) and v:GetNW2Bool("lc_swarm_chant", false) then
            out[#out + 1] = { pos = v:GetPos() + Vector(0, 0, 50), col = PURPLE, size = 240, sprite = 80, id = v:EntIndex() + 4096 }
        end
    end
    return out
end

hook.Add("Think", "LivingCitySwarm", function()
    if not DynamicLight then return end
    for _, g in ipairs(SW.Glowing()) do
        local d = DynamicLight(g.id)
        if d then
            d.pos = g.pos
            d.r, d.g, d.b = g.col.r, g.col.g, g.col.b
            d.brightness = 2
            d.Decay = 800
            d.Size = g.size
            d.DieTime = CurTime() + 0.25
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "LivingCitySwarm", function(_, sky)
    if sky or not render then return end
    local list = SW.Glowing()
    if #list == 0 then return end
    render.SetMaterial(glow)
    local pulse = 1 + 0.12 * math.sin(CurTime() * 4)
    for _, g in ipairs(list) do
        if g.sprite > 0 then render.DrawSprite(g.pos, g.sprite * pulse, g.sprite * pulse, g.col) end
    end
end)

-- The city falls to the swarm: a long shake and the ground's rumble, nothing written.
function SW.Fall()
    if util and util.ScreenShake and IsValid(LocalPlayer()) then util.ScreenShake(LocalPlayer():GetPos(), 6, 3, 6, 5000) end
    if surface and surface.PlaySound then
        surface.PlaySound("ambient/atmosphere/thunder" .. math.random(1, 4) .. ".wav")
        timer.Simple(1.5, function() if surface and surface.PlaySound then surface.PlaySound("ambient/atmosphere/thunder" .. math.random(1, 4) .. ".wav") end end)
    end
    SW.fellAt = CurTime()
end
net.Receive("lc_swarm_fall", function() LC.Try(SW.Fall) end)
