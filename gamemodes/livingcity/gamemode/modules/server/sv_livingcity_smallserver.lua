--[[
    Living City: small-server mode (the owner, 10 November: "yes please").

    With lc_small_server (4) players or fewer online, the city carries more
    of the story itself and the few players drive it:
      - automatic city events come half again as often
      - the Resistance's own fighters run their operations twice as often
      - the collapse can come with lc_small_black_players (2) on, not
        lc_black_min_players
      - a unit's shift doesn't ask for an inspection when nobody housed is
        online to inspect
      - any Resistance Member may plan an operation when no Fighter or higher
        is online
    It turns itself on and off as people come and go, and says so in chat.
    0 turns it off.

      lc_small_server (4), lc_small_black_players (2)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSmall = CreateConVar("lc_small_server", "4", FLAGS, "With this many players online or fewer, small-server mode: more city events and rebel operations, the collapse with fewer players (0: never)")
local cvBlack = CreateConVar("lc_small_black_players", "2", FLAGS, "In small-server mode, players online before the city can collapse to BLACK")

function LC.SmallServer()
    local n = cvSmall:GetInt()
    return n > 0 and #player.GetAll() <= n
end

-- How much sooner things come (multiplies the gaps).
function LC.SmallEventMul() return LC.SmallServer() and (2 / 3) or 1 end
function LC.SmallOpsMul() return LC.SmallServer() and 0.5 or 1 end
function LC.SmallBlackPlayers() return LC.SmallServer() and math.max(1, cvBlack:GetInt()) or nil end

local was
timer.Create("LivingCitySmallServer", 15, 0, function()
    local now = LC.SmallServer()
    SetGlobal2Bool("lc_small_server", now)
    if was ~= nil and now ~= was then
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint(now and "[Miscount] A quiet night in the city: with so few about, the city's own people carry more of it. Events and rebel operations come more often."
                or "[Miscount] The city's busy again: back to its usual pace.")
        end
    end
    was = now
end)
