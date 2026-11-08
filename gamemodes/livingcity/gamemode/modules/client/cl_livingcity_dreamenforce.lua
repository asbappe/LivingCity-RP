--[[
    Living City (client): Enforcers in the dreams

    An Enforcer (Civil Protection or the Administration, in a nightmare or a
    propaganda dream) sees the dreamers who misbehave glowing red, and a line
    on screen while one does. A dreamer who's glowing is told so, at the
    bottom of the screen. The server side is sv_livingcity_dreamenforcers.lua.
]]

LC_CL = LC_CL or {}

local RED = Color(255, 50, 50)

local function Bad(p) return IsValid(p) and p:GetNW2Float("lc_dream_bad_until", 0) > CurTime() end

hook.Add("PreDrawHalos", "LivingCityDreamEnforce", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_enforcer", false) then return end
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= me and Bad(p) and p:GetNW2Bool("lc_dreaming", false) then list[#list + 1] = p end
    end
    if #list > 0 and halo and halo.Add then halo.Add(list, RED, 3, 3, 2, true, true) end
end)

hook.Add("HUDPaint", "LivingCityDreamEnforce", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then return end
    local text
    if me:GetNW2Bool("lc_enforcer", false) then
        local n = 0
        for _, p in ipairs(player.GetAll()) do if p ~= me and Bad(p) then n = n + 1 end end
        if n > 0 then text = n == 1 and "A dreamer is misbehaving: punish them with your baton (they glow red)." or (n .. " dreamers are misbehaving: punish them with your baton (they glow red).") end
    elseif Bad(me) then
        text = "An Enforcer can see you misbehaving. Their baton would cost you a life."
    end
    if not text then return end
    draw.SimpleTextOutlined(text, "DermaLarge", ScrW() / 2, ScrH() * 0.86, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 220))
end)
