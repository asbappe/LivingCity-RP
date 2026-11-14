--[[
    Living City: the Resistance's way marks

    The owner, 14 November: "graffiti arrows and such to be used by the editor
    tool specifically as permanent decals to point the way towards resistance
    territory ... one should be pointing left, the other decal right, another
    forward, and another down ... the same orange color as the lambda that is
    also in the decal, or maybe ... 'Freedom this way'".

    Five marks the Miscount Editor paints on a wall (Mark: Resistance arrow ...,
    Mark: FREEDOM THIS WAY): a "waymark" point in the layout, its number the mark,
    its yaw the way the wall faces. They are sent to every player with the
    sprayed tags (lc_tags, sv_livingcity_scavenge.lua) and painted the same way
    (cl_livingcity_war.lua), but they are the layout's own: they never fade, and
    no spray can makes one. Only the editor takes one away for good (right
    click, as any point).

    Scrubbed off, it comes back (the owner, 14 November: "allow them to be
    scrubbed off, but they just reappear a few minutes later when no one is
    looking"): anyone who could scrub a sprayed tag scrubs one the same way, for
    the same thanks; LC.WayMarkReturn seconds later (240), once no player is
    near enough to see the wall, someone has painted it again.

    Pictures: garrysmod/materials/livingcity/graffiti/arrow_left.png,
    arrow_right.png, arrow_up.png, arrow_down.png, freedom.png (512 x 512,
    see-through; livingcity_content.zip). Without its picture a mark is the
    game's own lambda spray.
]]

if CLIENT then return end

LC = LC or {}

-- [the point's number] = the mark (the editor's modes are way_<id>: livingcity_editor.lua)
LC.WayMarkKinds = {
    { id = "arrow_left", name = "an arrow pointing left" },
    { id = "arrow_right", name = "an arrow pointing right" },
    { id = "arrow_up", name = "an arrow pointing up (straight on)" },
    { id = "arrow_down", name = "an arrow pointing down" },
    { id = "freedom", name = "FREEDOM THIS WAY" },
}

LC.WayMarkReturn = 240 -- (seconds a scrubbed mark stays off, at least)
LC.WayMarkSight = 2500 -- (a player nearer than this, with a clear line to the wall, is looking)
LC.WayMarkGone = LC.WayMarkGone or setmetatable({}, { __mode = "k" }) -- [the point] = when it was scrubbed

-- The layout's marks, as the sprayed tags are sent: where, which way the wall faces, which mark.
function LC.WayMarks()
    local out = {}
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "waymark" then
            if not LC.WayMarkGone[p] then
                local k = LC.WayMarkKinds[p.group or 0] or LC.WayMarkKinds[1]
                local n = Angle(0, p.yaw or 0, 0):Forward()
                out[#out + 1] = { pos = p.pos + n * 0.5, normal = n, kind = k.id, permanent = true, point = p }
            end
        end
    end
    return out
end

-- A mark on the wall near here (one that's up), as LC.TagNear gives a sprayed tag.
function LC.WayMarkNear(pos, r)
    for _, t in ipairs(LC.WayMarks()) do
        if t.pos:DistToSqr(pos) < r * r then return t end
    end
    return nil
end

-- Scrubbed off (LC.CleanTag): gone from every wall, until it is painted again.
function LC.ScrubWayMark(p)
    if not p or p.kind ~= "waymark" or LC.WayMarkGone[p] then return false end
    LC.WayMarkGone[p] = CurTime()
    if LC.SendTags then LC.SendTags() end
    return true
end

-- Can any player see that wall just now? (Near it, with nothing of the map in between.)
function LC.WayMarkSeen(p)
    local n = Angle(0, p.yaw or 0, 0):Forward()
    local at = p.pos + n * 6
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply:GetPos():DistToSqr(at) < LC.WayMarkSight * LC.WayMarkSight then
            local tr = util.TraceLine({ start = ply:EyePos(), endpos = at, mask = MASK_SOLID_BRUSHONLY })
            if not tr or not tr.Hit or (tr.Fraction or 0) > 0.97 then return true end
        end
    end
    return false
end

-- Painted again: every mark scrubbed long enough ago, with nobody looking. How many came back.
function LC.WayMarkTick()
    local back, now = 0, CurTime()
    for p, at in pairs(LC.WayMarkGone) do
        local there = false
        for _, q in ipairs(LC.Points or {}) do if q == p then there = true break end end
        if not there then
            LC.WayMarkGone[p] = nil -- (the editor took it away meanwhile)
        elseif now - at >= LC.WayMarkReturn and not LC.WayMarkSeen(p) then
            LC.WayMarkGone[p] = nil
            back = back + 1
        end
    end
    if back > 0 and LC.SendTags then LC.SendTags() end
    return back
end

-- Paint one from the editor: on a wall (not a floor or a ceiling). The point, or nil and why.
function LC.AddWayMark(pos, normal, num)
    if not LC.WayMarkKinds[num or 0] then return nil, "No such mark." end
    if not pos or not normal or math.abs(normal.z) > 0.4 then return nil, "Aim at a wall: the mark is painted on it." end
    local flat = Vector(normal.x, normal.y, 0)
    local p = LC.AddPoint(pos, flat:Angle().y, "waymark", num)
    if p and LC.SendTags then LC.SendTags() end
    return p
end

-- Marks put up or taken down (the editor, an undo, another layout loaded): everyone's walls follow.
local last = nil
timer.Create("LivingCityWayMarks", 3, 0, function()
    LC.WayMarkTick()
    local sig = {}
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "waymark" then sig[#sig + 1] = string.format("%d:%d:%d:%d:%d", p.pos.x, p.pos.y, p.pos.z, p.yaw or 0, p.group or 0) end
    end
    sig = table.concat(sig, "|")
    if last ~= nil and sig ~= last and LC.SendTags then LC.SendTags() end
    last = sig
end)
