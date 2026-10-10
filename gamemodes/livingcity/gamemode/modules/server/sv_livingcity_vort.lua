--[[
    Living City: vortigaunts

    Shackled vortigaunts (the "Vortigaunt" faction) are Combine property: they
    work the Union's shifts, and the collar holds their vortessence in. A
    Resistance Member or above can cut the shackles: !unshackle, looking at
    one up close, ten seconds, and no unit can be watching. The vortigaunt is
    free: it joins the Resistance as a Free Vortigaunt, charges vests and strikes with
    its vortessence, and is hunted on sight.
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local function Shackled(ply) return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "vort" end

function LC.StartUnshackle(ply)
    if ply:GetNW2String("lcf_faction", "") ~= "resistance" or ply:GetNW2Int("lcf_rank", 1) < 2 then
        return false, "Only the Resistance (Member and up) knows how to cut a vortigaunt's shackles."
    end
    local tr = ply:GetEyeTrace()
    local vort = tr and tr.Entity
    if not Shackled(vort) or vort:GetPos():DistToSqr(ply:GetPos()) > 120 * 120 then return false, "Look at a shackled vortigaunt, up close." end
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then return false, "Not with a unit watching." end
    vort:ChatPrint("[Living City] Someone is working at your shackles.")
    return LC.StartTask(ply, 10, "Cutting the shackles...", {
        maxMove = 40, cancelText = "You stop.",
        done = function(p)
            if not Shackled(vort) or p:GetPos():DistToSqr(vort:GetPos()) > 150 * 150 then return end
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                return p:ChatPrint("A unit is watching. Not now.")
            end
            LC.SetFaction(vort, "resistance", "vortigaunt", true)
            vort:ChatPrint("[Living City] The shackles fall away. The vortessence is yours again: left click strikes, right click charges a vest (yours or a comrade's). The Combine will want you back.")
            p:ChatPrint("The shackles fall. The vortigaunt is free.")
            if LC.AddXP then LC.AddXP(p, 30, "freeing a vortigaunt") end
            if LC.RadioNotice then LC.RadioNotice("resistance", "A vortigaunt has been freed. Welcome it.") end
            hook.Run("LivingCityVortFreed", vort, p)
        end,
    })
end

LC.SlashCommands.unshackle = function(ply) local ok, why = LC.StartUnshackle(ply) if not ok and why then ply:ChatPrint(why) end end

hook.Add("PlayerSay", "LivingCityVortChat", function(ply, text)
    local t = string.lower(string.Trim(text or ""))
    if t ~= "!unshackle" and not (t == "/unshackle" and not (LC.ICChatActive and LC.ICChatActive())) then return end
    LC.SlashCommands.unshackle(ply)
    return ""
end)
