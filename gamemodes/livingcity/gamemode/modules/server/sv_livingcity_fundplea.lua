--[[
    Living City: the Resistance asks for its fund when it runs dry

    The owner, 19 November: "please also add some lines for the resistance leader/cubbage if the
    fund is down to 0 for more than 10 minutes, or if it's hovering extremely low (under 50) for
    that long, basically begging for donations both to any player interacting and his
    speeches/announcements".

    Low         the fund (sv_livingcity_resistancefund.lua) under LOW (50) credits for LOW_MINUTES
                (10) in a row. It stops as soon as it holds 50 or more, and the ten minutes start
                again the next time it drops. The moment it went under is kept with the fund in the
                ledger ("fundLowSince" in data/livingcity/<map>_city.json, the clock's own time),
                so a restart doesn't reset it.
    The Colonel the ghost only the Resistance sees (sv_livingcity_colonel.lua): E on him while it's
                low, and he asks for it in place of his greeting (LC.ColonelLines fund_*, recorded
                in sound/livingcity/colonel/), at most once a player in TALK_GAP (5 minutes), never
                the same line twice running.
    Cubbage     his answer to her address (sv_livingcity_speechanswer.lua) ends with one more
                piece while it's low (LC.SpeechAnswerLines fund_*, recorded as
                sound/livingcity/cubbage/answer_fund_*1.wav), heard as the rest of it is.
    Freq 7      at most once in BROADCAST_GAP (20 minutes) while it's low, Freq 7's own warning
                way (LC.Freq7Warn) cuts in with freq7_fund (sound/livingcity/radio/freq7_fund1.wav
                to 4: VOICE_SCRIPTS.md); with no recording, nothing.

    No notice, no popup: spoken lines, shown as each one's own lines are.

    LC.FundLow(now)                  low for ten minutes now? (now: os.time(), for tests)
    LC.FundPleaWatch(now)            notes when it went under, or that it's back up
    LC.FundPleaLine(ply, place)      a line id for the Colonel to say instead, or nil
    LC.FundPleaPiece(place)          a piece id for Cubbage's answer, or nil
    LC.FundPleaBroadcast(now)        Freq 7's call, when it's due (now: CurTime())
]]

if CLIENT then return end

LC = LC or {}

local LOW = 50               -- credits: under this, the fund is low
local LOW_MINUTES = 10       -- low this long in a row before anyone asks
local TALK_GAP = 300         -- seconds between the Colonel's pleas to one player
local BROADCAST_GAP = 20 * 60 -- seconds between Freq 7's calls
local RETRY = 60             -- seconds before trying Freq 7 again when it couldn't (no recording, jammed)
local PREFIX = "fund_"       -- the plea lines' ids, in each one's own lines

LC.FundPlea = LC.FundPlea or { last = {}, nextCast = 0 }
local S = LC.FundPlea

local function Book() return LC.Ledger and LC.Ledger() or nil end
local function Fund() return LC.ResistanceFund and LC.ResistanceFund() or 0 end

local LINES = {
    colonel = function() return LC.ColonelLines end,
    cubbage = function() return LC.SpeechAnswerLines end,
}

local function Ids(place)
    local out = {}
    for id in pairs(LINES[place] and LINES[place]() or {}) do
        if string.sub(id, 1, #PREFIX) == PREFIX then out[#out + 1] = id end
    end
    table.sort(out)
    return out
end

-- One of a place's plea lines, never the one it said last.
local function Pick(place)
    local ids, pool = Ids(place), {}
    for _, id in ipairs(ids) do if id ~= S.last[place] or #ids == 1 then pool[#pool + 1] = id end end
    if #pool == 0 then return nil end
    local id = pool[math.random(#pool)]
    S.last[place] = id
    return id
end

function LC.FundPleaWatch(now)
    local book = Book()
    if not book then return end
    local low = Fund() < LOW
    if low and not tonumber(book.fundLowSince) then
        book.fundLowSince = math.floor(now or os.time())
        if LC.LedgerSave then LC.Try(LC.LedgerSave) end
    elseif not low and book.fundLowSince ~= nil then
        book.fundLowSince = nil
        if LC.LedgerSave then LC.Try(LC.LedgerSave) end
    end
end

function LC.FundLow(now)
    local book = Book()
    local since = book and tonumber(book.fundLowSince)
    return since ~= nil and Fund() < LOW and (now or os.time()) - since >= LOW_MINUTES * 60
end

function LC.FundPleaLine(ply, place)
    if not IsValid(ply) or not LC.FundLow() then return nil end
    ply.lcFundPleaAt = ply.lcFundPleaAt or {}
    local at = ply.lcFundPleaAt[place]
    if at and CurTime() - at < TALK_GAP then return nil end
    local id = Pick(place)
    if id then ply.lcFundPleaAt[place] = CurTime() end
    return id
end

function LC.FundPleaPiece(place)
    if not LC.FundLow() then return nil end
    return Pick(place)
end

function LC.FundPleaBroadcast(now)
    now = now or CurTime()
    if now < (S.nextCast or 0) or not LC.FundLow() then return false end
    local said = LC.Freq7Warn and LC.Freq7Warn("fund") or false
    S.nextCast = now + (said and BROADCAST_GAP or RETRY)
    return said == true
end

timer.Create("LivingCityFundPlea", 5, 0, function()
    local okP, err = LC.Try(function()
        LC.FundPleaWatch()
        LC.FundPleaBroadcast()
    end)
    if not okP and LC.Error then LC.Error("the Resistance's fund (asking for it)", err) end
end)
