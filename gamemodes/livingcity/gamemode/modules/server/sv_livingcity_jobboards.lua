--[[
    Living City: job boards in the world (the owner, 13 November: "we haven't ironed out how jobs boards
    work at terminals"). How they work now:

      - A job board is an editor fixture ("Fixture: job board", entities/lc_jobboard.lua), placed where a
        side would put one. Whose it is follows where it stands: rebel ground, the Resistance's
        Operations; Combine ground, Civil Protection's Directives; anywhere else, the Union's Assignments.
      - Its glass lists what's up on that board right now (up to five titles, every 15 seconds).
      - E on it: your Jobs (F4) open if it's your side's board; if not, it says whose it is.
      - F4's Jobs stay as they are, for everyone, wherever they are (and a unit's directives also on the
        radio's menu). A board is one more way in, never the only one (house rule 2).
]]

if CLIENT then return end

LC = LC or {}

local NAMES = { resistance = "Operations", cp = "Directives", citizen = "Assignments" }

function LC.JobBoardSide(board)
    local p = board:GetPos()
    if LC.InRebelZone and LC.InRebelZone(p) then return "resistance" end
    if LC.InCombineZone and LC.InCombineZone(p) then return "cp" end
    return "citizen"
end

local function Refresh(board)
    local side = LC.JobBoardSide(board)
    board:SetNW2String("lc_board_side", side)
    board:SetNW2String("lc_board_name", NAMES[side] or "Assignments")
    local titles = {}
    local now = CurTime()
    for _, p in ipairs(LC.Postings and LC.Postings[side] or {}) do
        if #titles >= 5 then break end
        if not p.dead and not p.story and (p.q or now < (p.expiresPost or 0)) then titles[#titles + 1] = string.sub(p.title or "", 1, 48) end
    end
    board:SetNW2String("lc_board_list", table.concat(titles, "\n"))
end
LC.JobBoardRefresh = Refresh

function LC.UseJobBoard(ply, board)
    if not IsValid(ply) or not IsValid(board) then return false end
    local side = LC.JobBoardSide(board)
    local mine = LC.QuestFaction and LC.QuestFaction(ply) or ply:GetNW2String("lcf_faction", "citizen")
    if mine == "ota" or mine == "admin" then mine = "cp" end
    if mine ~= side then
        ply:ChatPrint("[Job board] This is the " .. (NAMES[side] or "Union's") .. " board: " ..
            (side == "resistance" and "the Resistance's work." or (side == "cp" and "Civil Protection's directives." or "the Union's work for citizens.")) ..
            " Your own jobs are on F4.")
        return false
    end
    if LC.OpenHub then LC.OpenHub(ply) elseif LC.SendBoard then LC.SendBoard(ply) end
    return true
end

timer.Create("LivingCityJobBoards", 15, 0, function()
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("lc_jobboard") or ents.FindByClass("lc_jobboard")) do
        if IsValid(b) then pcall(Refresh, b) end
    end
end)
