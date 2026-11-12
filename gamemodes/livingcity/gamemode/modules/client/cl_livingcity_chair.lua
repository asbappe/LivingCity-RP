--[[
    Living City (client): the interrogation chair (sv_livingcity_chair.lua)

    The quick menu of the one asking (E on the chair while someone sits in it:
    number keys, as F1 and F2; the owner, 12 November: no mouse windows),
    and the lamp in the eyes of whoever is in the chair.
]]

LC_CL = LC_CL or {}


local function Do(chair, what)
    net.Start("lc_chair_do")
    net.WriteEntity(chair)
    net.WriteString(what)
    net.SendToServer()
end

net.Receive("lc_chair", function()
    local chair = net.ReadEntity()
    if not IsValid(chair) then
        if LC_CL.CloseSituation then LC_CL.CloseSituation("chair") end
        return
    end
    local name, said, hits, max = net.ReadString(), net.ReadString(), net.ReadUInt(4), net.ReadUInt(4)
    local fromCage = net.ReadBool()
    local isPlayer = net.ReadBool()
    if not LC_CL.OpenSituation then return end
    -- A quick menu, not a window (the owner, 12 November): number keys, and you can still move and look.
    local items = {
        { label = "Ask what they've done", run = function() Do(chair, "done") end },
        { label = "Ask what they've seen", run = function() Do(chair, "seen") end },
    }
    if not isPlayer then
        -- the kind options (sv_livingcity_rebelrule.lua)
        items[#items + 1] = { label = "Be kind", page = function()
            return { title = "Be kind", items = {
                { label = "Talk to them, no threats", run = function() Do(chair, "talk") end },
                { label = "Give them food or water (from your pockets)", run = function() Do(chair, "food") end },
                { label = "Ask them to join us", run = function() Do(chair, "recruit") end },
            } }
        end }
    end
    items[#items + 1] = { label = hits >= max and "Hit them (any more would kill them)" or ("Hit them (" .. hits .. " of " .. max .. ")"),
        run = function() Do(chair, "hit") end, disabled = hits >= max }
    if fromCage then items[#items + 1] = { label = "Back to the cage with them", run = function() Do(chair, "cage") end } end
    items[#items + 1] = { label = "Let them go", run = function() Do(chair, "free") end }
    if LC_CL.ExecutionPage then
        local sitter = chair:GetNW2Entity("lc_chair_sitter")
        items[#items + 1] = { label = "Execution", page = LC_CL.ExecutionPage(function(what) Do(chair, what) end, sitter) }
    end
    LC_CL.OpenSituation({ id = "chair", title = name .. ", in the chair", items = items, note = said,
        stay = function()
            local me = LocalPlayer()
            return IsValid(chair) and IsValid(me) and me:GetPos():DistToSqr(chair:GetPos()) < 350 * 350
        end })
end)

-- In the chair yourself: the lamp is all you can see.
hook.Add("RenderScreenspaceEffects", "LivingCityChair", function()
    local me = LocalPlayer()
    if not IsValid(me) or not IsValid(me:GetNW2Entity("lc_chair_in")) then return end
    if DrawBloom then DrawBloom(0.25, 3.5, 12, 12, 2, 1, 1, 1, 1) end
    surface.SetDrawColor(255, 250, 235, 150 + math.floor(math.sin(CurTime() * 2.3) * 22))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)
