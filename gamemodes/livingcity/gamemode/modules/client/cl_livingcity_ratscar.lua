--[[
    Living City (client): the rat carved into a burned informant's cheek
    (the owner, 10 November: "an extremely crude geometric rat ... as if they
    tried to carve a very simplistic geometric rat onto their cheek").

    Anyone the Resistance has scarred (sv_livingcity_snitches.lua, NW
    lc_scar_mark) has a few red, uneven cut lines on the right cheek: a
    pointed snout, an ear, a lumpy body, two legs and a tail. Drawn on the
    head, so it follows it. Where it sits is lc_ratscar_pos (the server's
    setting): forward, right, up from the head, and how far it turns toward
    the side of the face.
]]

LC_CL = LC_CL or {}

local cvPos = GetConVar("lc_ratscar_pos") or CreateConVar("lc_ratscar_pos", "3.4 2.6 -1.6 55", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Where the carved rat sits on a scarred face, from the head bone: forward right up turn")

-- The cuts, in a 70 by 40 box: snout on the left, tail on the right. Wobbly on purpose.
local CUTS = {
    { 2, 22, 12, 13 }, { 12, 13, 30, 10 }, { 30, 10, 47, 16 }, { 47, 16, 48, 27 }, { 48, 27, 31, 32 }, { 31, 32, 12, 29 }, { 12, 29, 2, 22 }, -- body
    { 12, 13, 13, 3 }, { 13, 3, 20, 11 },     -- the ear
    { 7, 19, 9, 19 },                          -- the eye
    { 16, 30, 13, 37 }, { 36, 31, 39, 38 },    -- legs
    { 48, 24, 57, 19 }, { 57, 19, 62, 28 }, { 62, 28, 69, 21 }, -- the tail
}
LC_CL.RatScarCuts = CUTS

local function Nums()
    local v = {}
    for w in string.gmatch(cvPos and cvPos:GetString() or "", "%S+") do v[#v + 1] = tonumber(w) or 0 end
    return v[1] or 3.4, v[2] or 2.6, v[3] or -1.6, v[4] or 55
end

local RED = Color(150, 25, 20, 235)
local DARK = Color(90, 10, 10, 200)

function LC_CL.DrawRatScar(ply)
    if not IsValid(ply) or not ply:GetNW2Bool("lc_scar_mark", false) or not ply:Alive() then return end
    local bone = ply.LookupBone and ply:LookupBone("ValveBiped.Bip01_Head1")
    if not bone then return end
    local pos = ply:GetBonePosition(bone)
    if not pos then return end
    local fwd, right, up, turn = Nums()
    local face = Angle(0, ply:EyeAngles().y, 0)
    local origin = pos + face:Forward() * fwd + face:Right() * right + face:Up() * up
    -- facing out of the cheek: the face's forward, turned toward the right side
    local out = Angle(0, face.y - turn, 0)
    local ang = out:Forward():Angle()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    cam.Start3D2D(origin - ang:Forward() * 1.2 - ang:Right() * -0.7, ang, 0.034)
        for _, c in ipairs(CUTS) do
            surface.SetDrawColor(DARK)
            surface.DrawLine(c[1], c[2] + 1, c[3], c[4] + 1)
            surface.SetDrawColor(RED)
            surface.DrawLine(c[1], c[2], c[3], c[4])
        end
    cam.End3D2D()
end

hook.Add("PostPlayerDraw", "LivingCityRatScar", LC_CL.DrawRatScar)
