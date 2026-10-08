--[[
    Living City: acts (shared)

      Poses you hold:  /sit   /kneel   /lie   /lean   /pose [1-4]   /cower
                       (and !handsup, which raises your hands)
      Gestures, once:  /wave  /salute  /bow  /nod  /shake  /point  /beckon  /halt  /cheer  /laugh

    Moving, jumping, ducking or drawing a weapon ends a pose. While you hold
    one the camera pulls back so you can see yourself (lc_act_thirdperson 0
    keeps it first person).

    Poses use whatever the model has: each one tries a list of animations in
    order, the GMod player animations first, then the Half-Life 2 ones. If a
    model has none of them, the pose still holds you still and says so.
]]


LCA = LCA or {}

-- name = { sequences to try (first found wins), activity to fall back to, eye height, what it's called }
LCA.Poses = {
    sit    = { seqs = { "sit_zen", "sit_ground", "sit" }, act = ACT_HL2MP_SIT, eye = 30, label = "sitting" },
    kneel  = { seqs = { "pose_ducking_01", "pose_ducking_02" }, act = ACT_GMOD_SHOWOFF_DUCK_01, eye = 40, label = "kneeling" },
    lie    = { seqs = { "zombie_slump_idle_02", "zombie_slump_idle_01", "d1_town05_wounded_idle_1" }, eye = 14, label = "lying down" },
    lean   = { seqs = { "lean_back", "plazaidle4", "pose_standing_02" }, act = ACT_GMOD_SHOWOFF_STAND_02, label = "leaning" },
    pose1  = { seqs = { "pose_standing_01" }, act = ACT_GMOD_SHOWOFF_STAND_01, label = "standing" },
    pose2  = { seqs = { "pose_standing_02" }, act = ACT_GMOD_SHOWOFF_STAND_02, label = "standing" },
    pose3  = { seqs = { "pose_standing_03" }, act = ACT_GMOD_SHOWOFF_STAND_03, label = "standing" },
    pose4  = { seqs = { "pose_standing_04" }, act = ACT_GMOD_SHOWOFF_STAND_04, label = "standing" },
    cower  = { seqs = { "idle_all_cower", "idle_all_scared", "cower_idle" }, label = "cowering" },
    handsup = { seqs = { "apcarrestidle", "idle_all_scared", "pose_standing_04" }, label = "hands up" },
}

-- Gestures: the game's own "act" command plays these on every model.
LCA.Gestures = {
    wave = "wave", salute = "salute", bow = "bow", nod = "agree", shake = "disagree", point = "forward",
    beckon = "becon", halt = "halt", cheer = "cheer", laugh = "laugh",
}

-- Which animation this player uses for a pose: a sequence number, an activity, or nil.
function LCA.Resolve(ply, name)
    local p = LCA.Poses[name]
    if not p then return nil end
    ply.lcActCache = ply.lcActCache or {}
    local model = ply:GetModel() or ""
    local key = model .. "|" .. name
    local c = ply.lcActCache[key]
    if c == nil then
        c = false
        for _, s in ipairs(p.seqs or {}) do
            local id = ply.LookupSequence and ply:LookupSequence(s) or -1
            if id and id > 0 then c = { seq = id } break end
        end
        if not c and p.act and ply.SelectWeightedSequence then
            local id = ply:SelectWeightedSequence(p.act)
            if id and id > 0 then c = { seq = id, act = p.act } end
        end
        ply.lcActCache[key] = c
    end
    return c or nil
end

function LCA.Current(ply)
    local a = ply:GetNW2String("lc_act", "")
    if a ~= "" then return a end
    if ply:GetNW2Bool("lc_handsup", false) then return "handsup" end
    return nil
end

-- Vortigaunts are played with the NPC model, which has its own walk and run:
-- the player animations it lacks are swapped for those.
local VORT = { idle = { "Idle01", "idle01", "Idle_Angry" }, walk = { "Walk_all", "walk_all" }, run = { "Run_all", "run_all" } }

local function VortSeq(ply, kind)
    ply.lcVortSeq = ply.lcVortSeq or {}
    local c = ply.lcVortSeq[kind]
    if c == nil then
        c = false
        for _, s in ipairs(VORT[kind]) do
            local id = ply:LookupSequence(s)
            if id and id > 0 then c = id break end
        end
        ply.lcVortSeq[kind] = c
    end
    return c or nil
end

function LCA.IsVortModel(ply) return string.find(string.lower(ply:GetModel() or ""), "vortigaunt", 1, true) ~= nil end

hook.Add("CalcMainActivity", "LivingCityActs", function(ply, vel)
    local name = LCA.Current(ply)
    if not name and LCA.IsVortModel(ply) then
        if ply.lcVortModel ~= ply:GetModel() then ply.lcVortSeq, ply.lcVortModel = nil, ply:GetModel() end
        local speed = vel and vel:Length2D() or 0
        local seq = VortSeq(ply, speed > 150 and "run" or (speed > 10 and "walk" or "idle")) or VortSeq(ply, "idle")
        if seq then return speed > 10 and (ACT_HL2MP_RUN or ACT_HL2MP_IDLE) or ACT_HL2MP_IDLE, seq end
        return
    end
    if not name then return end
    -- hands up while walking: let the legs walk
    if name == "handsup" and vel and vel:Length2DSqr() > 100 then return end
    local r = LCA.Resolve(ply, name)
    if not r then return end
    return r.act or ACT_HL2MP_IDLE, r.seq
end)
