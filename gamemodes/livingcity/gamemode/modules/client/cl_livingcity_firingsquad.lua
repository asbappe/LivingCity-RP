--[[
    Living City (client): firing squads (sv_livingcity_firingsquad.lua)

    Her F2 > City orders > Firing squad...: who in the cells may be shot, as a
    quick menu (number keys). Choosing one orders it.
]]

LC_CL = LC_CL or {}

net.Receive("lc_fsquad", function()
    local note = net.ReadString()
    local items = {}
    for _ = 1, net.ReadUInt(4) or 0 do
        local who, label = net.ReadEntity(), net.ReadString()
        items[#items + 1] = { label = label, run = function()
            net.Start("lc_fsquad_do")
            net.WriteEntity(who)
            net.SendToServer()
        end }
    end
    if note == "-" then
        if LC_CL.CloseSituation then LC_CL.CloseSituation("fsquad") end
        return
    end
    if not LC_CL.OpenSituation then return end
    LC_CL.OpenSituation({ id = "fsquad", title = "Firing squad", items = items, note = note ~= "" and note or nil })
end)
