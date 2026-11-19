--[[
    Living City (client): informing to Civil Protection (sv_livingcity_inform.lua)

    E on a unit (or F1 > Inform, looking at one), with something to report: a
    quick menu (number keys, as F1 and F2) listing what you could tell him,
    each with its reward.
]]

LC_CL = LC_CL or {}

net.Receive("lc_inform", function()
    local unit = net.ReadEntity()
    if not IsValid(unit) then
        if LC_CL.CloseSituation then LC_CL.CloseSituation("inform") end
        return
    end
    local items = {}
    for _ = 1, net.ReadUInt(4) or 0 do
        local id, label, disabled = net.ReadString(), net.ReadString(), net.ReadBool()
        items[#items + 1] = { label = label, disabled = disabled, run = function()
            net.Start("lc_inform_do")
            net.WriteEntity(unit)
            net.WriteString(id)
            net.SendToServer()
        end }
    end
    if #items == 0 or not LC_CL.OpenSituation then return end
    LC_CL.OpenSituation({ id = "inform", title = "Inform", items = items,
        stay = function()
            local me = LocalPlayer()
            return IsValid(unit) and IsValid(me) and me:GetPos():DistToSqr(unit:GetPos()) < 260 * 260
        end })
end)
