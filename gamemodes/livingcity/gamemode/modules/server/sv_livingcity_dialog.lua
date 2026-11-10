--[[
    Living City: a window for someone (or something) that answers questions

    One window, used by the Citizen Information clerk (sv_livingcity_infodesk.lua),
    the old-timer (sv_livingcity_oldtimer.lua) and the orientation pamphlet
    (sv_livingcity_pamphlet.lua): a title, a line under it, what's being said,
    and buttons. Each button sends its id back to whoever opened the window.

      LC.OpenDialog(ply, key, ent, { title, sub, text, options = { { id, label }, ... } })
      LC.DialogHandlers[key] = function(ply, ent, id) ... end

    With an entity, the window closes when you walk away from it.
]]

if CLIENT then return end

LC = LC or {}
LC.DialogHandlers = LC.DialogHandlers or {}

util.AddNetworkString("lc_dialog")
util.AddNetworkString("lc_dialog_do")

function LC.OpenDialog(ply, key, ent, d)
    if not IsValid(ply) then return end
    ply.lcDialog = { key = key, ent = ent }
    net.Start("lc_dialog")
    net.WriteEntity(IsValid(ent) and ent or NULL)
    net.WriteString(d.title or "")
    net.WriteString(d.sub or "")
    net.WriteString(d.text or "")
    local opts = d.options or {}
    net.WriteUInt(math.min(#opts, 12), 4)
    for i = 1, math.min(#opts, 12) do
        net.WriteString(tostring(opts[i][1]))
        net.WriteString(tostring(opts[i][2]))
    end
    net.Send(ply)
end

function LC.CloseDialog(ply)
    if not IsValid(ply) then return end
    ply.lcDialog = nil
    net.Start("lc_dialog") net.WriteEntity(NULL) net.WriteString("") net.WriteString("") net.WriteString("") net.WriteUInt(0, 4) net.Send(ply)
end

-- (also for tests)
function LC.DialogDo(ply, id)
    local d = IsValid(ply) and ply.lcDialog
    if not d then return end
    if d.ent ~= nil and d.ent ~= NULL and (not IsValid(d.ent) or ply:GetPos():DistToSqr(d.ent:GetPos()) > 260 * 260) then return end
    local fn = LC.DialogHandlers[d.key]
    if fn then return fn(ply, d.ent, id) end
end

net.Receive("lc_dialog_do", function(_, ply)
    local id = net.ReadString()
    if (ply.lcDialogNext or 0) > CurTime() then return end
    ply.lcDialogNext = CurTime() + 0.3
    if id == "" then ply.lcDialog = nil return end
    LC.DialogDo(ply, id)
end)
