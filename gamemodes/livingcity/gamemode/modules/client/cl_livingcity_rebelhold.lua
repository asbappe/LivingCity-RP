--[[
    Living City (client): the Resistance's holding cage (sv_livingcity_rebelhold.lua)

    E on a side of the cage, as a Fighter or above: a quick menu (number keys, as
    F1 and F2; the owner, 12 November: no mouse windows) with the gate, and each
    of those held: to the interrogation chair, or let go. A player held in it can
    be patted down or let go.
]]

LC_CL = LC_CL or {}

local function Do(cage, what, npc)
    net.Start("lc_cage_do")
    net.WriteEntity(cage)
    net.WriteString(what)
    net.WriteEntity(IsValid(npc) and npc or NULL)
    net.SendToServer()
end

net.Receive("lc_cage", function()
    local cage = net.ReadEntity()
    if not IsValid(cage) then
        if LC_CL.CloseSituation then LC_CL.CloseSituation("cage") end
        return
    end
    local open, chair = net.ReadBool(), net.ReadBool()
    local held = {}
    for _ = 1, net.ReadUInt(4) or 0 do held[#held + 1] = { npc = net.ReadEntity(), name = net.ReadString() } end
    -- an exchange (sv_livingcity_rebelanswer.lua): who of ours a prisoner could be offered for, and the Combine's offer
    local offerFor, combineOffer = net.ReadString() or "", net.ReadString() or ""
    if not LC_CL.OpenSituation then return end
    local items = { { label = open and "Shut the gate" or "Open the gate", run = function() Do(cage, "gate") end } }
    if combineOffer ~= "" then
        items[#items + 1] = { label = "The Combine offer " .. combineOffer, page = function()
            local function Answer(yes) net.Start("lc_xchg_do") net.WriteBool(yes) net.SendToServer() end
            return { title = "AN EXCHANGE", items = {
                { label = "Accept", run = function() Answer(true) end },
                { label = "Refuse", run = function() Answer(false) end },
            } }
        end }
    end
    local function PersonPage(hd)
        return function()
            local sub = {}
            sub[#sub + 1] = { label = "Pat them down", run = function() Do(cage, "pat", hd.npc) end }
            sub[#sub + 1] = { label = chair and "To the interrogation chair" or "To the interrogation chair (none free near)",
                run = function() Do(cage, "chair", hd.npc) end, disabled = not chair }
            if IsValid(hd.npc) and hd.npc:IsPlayer() then
                sub[#sub + 1] = { label = "Let them go", run = function() Do(cage, "free", hd.npc) end }
            else
                -- (three ways: sv_livingcity_rebelanswer.lua)
                sub[#sub + 1] = { label = "Let them go", page = function() return { title = "LET THEM GO", items = {
                    { label = "With a warning", run = function() Do(cage, "freewarn", hd.npc) end },
                    { label = "Blindfolded, walked out", run = function() Do(cage, "freeblind", hd.npc) end },
                    { label = "Turned: they feed the units lies", run = function() Do(cage, "freeturn", hd.npc) end },
                } } end }
                if offerFor ~= "" then
                    sub[#sub + 1] = { label = "Offer them for " .. offerFor, run = function() Do(cage, "xoffer", hd.npc) end }
                end
            end
            if LC_CL.ExecutionPage then
                sub[#sub + 1] = { label = "Execution", page = LC_CL.ExecutionPage(function(what) Do(cage, what, hd.npc) end, hd.npc) }
            end
            return { title = hd.name, items = sub }
        end
    end
    -- (the gate and eight held fill the nine keys; a ninth and later prisoner waits for a place on the list)
    local room = 9 - #items -- (the Combine's offer, when there is one, takes a place)
    for i = 1, math.min(#held, room) do items[#items + 1] = { label = held[i].name, page = PersonPage(held[i]) } end
    LC_CL.OpenSituation({ id = "cage", title = "The holding cage", items = items,
        note = #held == 0 and "Nobody is held here. To take someone prisoner: press E on a citizen nearby, then \"Take them prisoner\"." or nil,
        stay = function()
            local me = LocalPlayer()
            return IsValid(cage) and IsValid(me) and me:GetPos():DistToSqr(cage:GetPos()) < 350 * 350
        end })
end)
