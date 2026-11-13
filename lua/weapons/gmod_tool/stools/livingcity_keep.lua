--[[
    Save with the gamemode (toolgun)
    Q menu > Tools > Miscount > Save with the gamemode

    The owner, 12 November: a separate tool next to the editor that marks props
    as belonging to the gamemode, saved with the layout, and marked props glow
    green while the tool is out.

    Left click   on a prop you spawned: it belongs to the gamemode now, frozen
                 and saved with the map's layout (data/livingcity/<map>.json),
                 back every time the map loads; on one already marked: saved
                 again as it is now (moved, recoloured, re-skinned)
    Right click  on a marked prop: no longer saved; it stays where it is until
                 the map changes, an ordinary prop again
    Reload       how many props are saved with the gamemode on this map
    Z            undo, like any other tool

    It is the same as the editor's "Prop: make persistent" mode (the same
    props, the same file: sv_livingcity_props.lua), on a tool of its own.
    Only those who may edit the layout (superadmins) can use it.
]]

-- Only in the Living City gamemode (elsewhere it isn't listed)
if engine.ActiveGamemode() ~= "livingcity" then TOOL.AddToMenu = false return end

TOOL.Category = "Miscount"
TOOL.Name = "#tool.livingcity_keep.name"
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.livingcity_keep.name", "Save with the gamemode")
    language.Add("tool.livingcity_keep.desc", "Mark props as part of Miscount: saved with the map's layout, back every time the map loads")
    language.Add("tool.livingcity_keep.left", "Save this prop with the gamemode (again: save it as it is now)")
    language.Add("tool.livingcity_keep.right", "Stop saving this prop")
    language.Add("tool.livingcity_keep.reload", "How many props are saved")
end

local function Tell(ply, msg) ply:ChatPrint("[Miscount] " .. msg) end

local function Undoable(ply, label, fn)
    if not undo then return end
    undo.Create("Miscount: " .. label)
    undo.AddFunction(function() fn() end)
    undo.SetPlayer(ply)
    undo.Finish()
end

local function Allowed(ply)
    if LC and LC.CanEdit and LC.CanEdit(ply) then return true end
    Tell(ply, "Only superadmins can save props with the gamemode.")
    return false
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not Allowed(ply) or not LC.PersistProp then return false end
    local e = trace.Entity
    local ok, what = LC.PersistProp(ply, e)
    if not ok then Tell(ply, what) return false end
    if what == "new" then
        Undoable(ply, "saved with the gamemode", function() if IsValid(e) and e.lcPersistId then LC.UnpersistProp(e, true) end end)
        Tell(ply, "Saved with the gamemode: frozen, and back every time the map loads. (Right click: not any more.)")
    else
        Tell(ply, "Saved again, as it is now.")
    end
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not Allowed(ply) or not LC.UnpersistProp then return false end
    local e = trace.Entity
    if not (IsValid(e) and e.lcPersistId) then Tell(ply, "That prop isn't saved with the gamemode.") return false end
    LC.UnpersistProp(e, true)
    Undoable(ply, "no longer saved", function() if IsValid(e) then LC.PersistProp(ply, e) end end)
    Tell(ply, "No longer saved with the gamemode: it stays until the map changes (the remover takes it away now).")
    return true
end

function TOOL:Reload()
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not Allowed(ply) then return false end
    local n = #(LC.Props or {})
    Tell(ply, n == 0 and "No props are saved with the gamemode on this map yet."
        or string.format("%d prop%s saved with the gamemode on this map (glowing green while this tool is out).", n, n == 1 and " is" or "s are"))
    return false
end

if CLIENT then
    local GREEN = Color(60, 255, 90)

    -- Is the local player holding this tool right now?
    local function Holding()
        local me = LocalPlayer()
        local w = IsValid(me) and me.GetActiveWeapon and me:GetActiveWeapon()
        if not IsValid(w) or w:GetClass() ~= "gmod_tool" then return false end
        return w.GetMode ~= nil and w:GetMode() == "livingcity_keep"
    end
    TOOL.HoldingKeep = Holding

    -- Every prop saved with the gamemode, near enough to matter.
    local function Marked()
        local out = {}
        local me = LocalPlayer()
        local eye = IsValid(me) and me:EyePos() or Vector(0, 0, 0)
        for _, cls in ipairs({ "prop_physics", "prop_physics_multiplayer", "prop_dynamic" }) do
            for _, e in ipairs(ents.FindByClass(cls)) do
                if IsValid(e) and e:GetNW2Bool("lc_persist", false) and e:GetPos():DistToSqr(eye) < 6000 * 6000 then out[#out + 1] = e end
            end
        end
        return out
    end
    TOOL.MarkedProps = Marked

    -- (looked for twice a second, not every frame)
    local cache, nextLook = {}, 0
    hook.Add("PreDrawHalos", "LivingCityKeepTool", function()
        if not Holding() then return end
        if CurTime() >= nextLook then
            nextLook = CurTime() + 0.5
            cache = Marked()
        end
        if #cache > 0 and halo and halo.Add then halo.Add(cache, GREEN, 2, 2, 2, true, true) end
    end)

    function TOOL:DrawHUD()
        local tr = LocalPlayer():GetEyeTrace()
        local e = tr and tr.Entity
        local text = "Left click a prop you spawned to save it with the gamemode. Saved props glow green."
        if IsValid(e) and e:GetNW2Bool("lc_persist", false) then
            text = "Saved with the gamemode. Left click: save it as it is now. Right click: stop saving it."
        end
        draw.SimpleTextOutlined(text, "DermaDefaultBold", ScrW() / 2, ScrH() * 0.62, GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
end

function TOOL.BuildCPanel(panel)
    panel:Help("Spawn a prop, put it where you want it, and left click it with this tool: it belongs to the gamemode now, frozen and saved with the map's layout, and it's back every time the map loads.")
    panel:Help("Left click a saved prop again to save it as it is now (after moving it with the physgun, recolouring or re-skinning it). Right click: stop saving it. Reload: how many are saved.")
    panel:Help("While this tool is out, every saved prop glows green. The editor's \"Prop: make persistent\" mode does the same.")
end
