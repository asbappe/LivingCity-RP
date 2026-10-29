--[[
    Living City: flood guard

    A player's game can send the server messages (from windows, the menus,
    chat) as fast as it likes. Someone with a cheat or a script can send
    thousands a second, and every one costs the server work: lag, a crash,
    or the same purchase or sale repeated faster than anyone could click.
    This keeps every player to a sensible pace, whatever they send:

      Messages     each kind (lc_net_rate, 10 a second, in bursts of up to
                   lc_net_burst, 25) and all of them together (four times
                   that). Anything over is quietly ignored. Someone who keeps
                   at it (lc_net_kick, 400 ignored in ten seconds) is kicked,
                   and staff see it in the log. Staff are never held back.
      Chat         lc_chat_flood (6) lines in three seconds; past that, the
                   rest are dropped until they slow down.

    Nobody playing normally comes near any of it.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRate  = CreateConVar("lc_net_rate", "10", FLAGS, "Messages of one kind a player's game may send the server each second (more are ignored)")
local cvBurst = CreateConVar("lc_net_burst", "25", FLAGS, "How many messages of one kind a player's game may send at once before lc_net_rate applies")
local cvKick  = CreateConVar("lc_net_kick", "400", FLAGS, "Ignored messages in ten seconds before a player is kicked for flooding (0: never kick)")
local cvChat  = CreateConVar("lc_chat_flood", "6", FLAGS, "Chat lines a player may send in three seconds (0: no limit)")

local buckets = {} -- [ply] = { [name] = { n, t }, all = { n, t }, dropped, since }

local function Take(b, rate, burst, now)
    b.n = math.min(burst, b.n + (now - b.t) * rate)
    b.t = now
    if b.n < 1 then return false end
    b.n = b.n - 1
    return true
end

-- True if this message from this player may go through now.
function LC.NetAllowed(ply, name)
    if not IsValid(ply) or LC.TestMode or (ply.IsAdmin and ply:IsAdmin()) then return true end
    local now = CurTime()
    local rate, burst = math.max(1, cvRate:GetFloat()), math.max(1, cvBurst:GetFloat())
    local p = buckets[ply]
    if not p then p = { kinds = {}, all = { n = burst * 4, t = now }, dropped = 0, since = now } buckets[ply] = p end
    local b = p.kinds[name]
    if not b then b = { n = burst, t = now } p.kinds[name] = b end
    if Take(b, rate, burst, now) and Take(p.all, rate * 4, burst * 4, now) then return true end
    if now - p.since > 10 then p.dropped, p.since = 0, now end
    p.dropped = p.dropped + 1
    local kick = cvKick:GetInt()
    if kick > 0 and p.dropped >= kick and not p.kicked then
        p.kicked = true
        if LC.Log then LC.Log("warn", string.format("flood guard: kicked %s (%s) for flooding the server (%s)", ply:Nick(), ply:SteamID(), name)) end
        if ply.Kick then ply:Kick("Too many requests to the server") end
    end
    return false
end

-- Every handler registered from here on goes through the guard (this file loads before the rest).
if net and net.Receive and not LC.NetGuarded then
    LC.NetGuarded = true
    local receive = net.Receive
    net.Receive = function(name, fn)
        return receive(name, function(len, ply)
            if ply ~= nil and not LC.NetAllowed(ply, name) then return end
            return fn(len, ply)
        end)
    end
end

-- Chat: a few lines a second at most.
function LC.ChatAllowed(ply)
    local most = cvChat:GetInt()
    if most <= 0 or not IsValid(ply) or LC.TestMode or (ply.IsAdmin and ply:IsAdmin()) then return true end
    local now = CurTime()
    local keep = {}
    for _, t in ipairs(ply.lcChatTimes or {}) do if now - t < 3 then keep[#keep + 1] = t end end
    if #keep >= most then
        ply.lcChatTimes = keep
        if (ply.lcChatWarned or 0) < now then ply.lcChatWarned = now + 3 ply:ChatPrint("Slow down: you're sending messages too fast.") end
        return false
    end
    keep[#keep + 1] = now
    ply.lcChatTimes = keep
    return true
end
-- (checked before any of the chat hooks run, whichever order they're in; if another addon
-- replaces the hook library afterwards, the hook below does it instead)
if hook and hook.Call and not LC.ChatCallWrapped then
    local call = hook.Call
    LC.ChatCallWrapped = function(name, gm, ply, ...)
        if name == "PlayerSay" and not LC.ChatAllowed(ply) then return "" end
        return call(name, gm, ply, ...)
    end
    hook.Call = LC.ChatCallWrapped
end
hook.Add("PlayerSay", "LivingCityChatFlood", function(ply)
    if hook.Call == LC.ChatCallWrapped then return end -- (already checked)
    if not LC.ChatAllowed(ply) then return "" end
end)

hook.Add("PlayerDisconnected", "LivingCityGuard", function(ply) buckets[ply] = nil end)
