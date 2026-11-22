--[[
    Living City (client): the Resistance's headquarters as the Combine see it (sv_livingcity_hq.lua).

      The Administrator's F2 > City orders > "The Resistance's headquarters: <what we know>": Raid it, greyed
      until they know the building. Nothing shows while the Resistance have no headquarters up.
      A unit's radio menu (the CP net): "Send a scanner to scout" (it flies where they aim).
]]

LC_CL = LC_CL or {}

LC_CL.CityOrderExtras = LC_CL.CityOrderExtras or {}
LC_CL.CityOrderExtras[#LC_CL.CityOrderExtras + 1] = function(me)
    if not IsValid(me) or me:GetNW2String("lcf_faction", "") ~= "admin" then return nil end
    local t = util.JSONToTable(GetGlobal2String("lc_hq", "") or "")
    if not istable(t) or not t.words then return nil end
    return { label = "The Resistance's headquarters: " .. tostring(t.words), page = function()
        local why = t.raid and "a raid is under way" or (not t.can and (t.words ~= "the building" and "not found yet" or "not yet")) or nil
        return { title = "THEIR HEADQUARTERS", items = {
            { label = "Raid it" .. (why and (" (" .. why .. ")") or ""), disabled = why ~= nil,
              run = function() net.Start("lc_hq_raid") net.SendToServer() end },
        } }
    end }
end

LC_CL.RadioExtras = LC_CL.RadioExtras or {}
LC_CL.RadioExtras[#LC_CL.RadioExtras + 1] = function(me, band)
    if band ~= "cp" then return nil end
    local f = IsValid(me) and me:GetNW2String("lcf_faction", "") or ""
    if f ~= "cp" and f ~= "ota" then return nil end
    local left = me:GetNW2Float("lc_hqscan_next", 0) - CurTime()
    return { label = "Send a scanner to scout" .. (left > 0 and string.format(" (back in %d:%02d)", math.floor(left / 60), math.floor(left % 60)) or ""),
        disabled = left > 0, run = function() net.Start("lc_hq_scan") net.SendToServer() end }
end
