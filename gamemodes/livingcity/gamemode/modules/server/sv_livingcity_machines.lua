--[[
    Living City: machines that answer in their own voice

    The ration dispenser and the vending machines tell you what's wrong
    themselves, out loud and as words low on the screen (like anyone talking
    to you), instead of a card at the top (the owner, 10 November: "machines
    that talk back"). "No ration card detected. Report for labor assignment."
    The full explanation still goes into chat, to read if you need it.

    Recordings, if you make them: garrysmod/sound/livingcity/machines/, named
    for the line (dispenser_nocard1.wav). Every line: VOICE_LINES.md section 8
    (LC.MachineLines below). Without one, the machine's beep.

    Setting: lc_machine_voice (1; 0 and the messages are cards as before).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvVoice = CreateConVar("lc_machine_voice", "1", FLAGS, "The ration dispenser and vending machines say what's wrong out loud and on screen, instead of a card")

LC.MachineVoiceRoot = "livingcity/machines/"

-- id = { who says it, what they say }
LC.MachineLines = {
    dispenser_unregistered = { "Ration dispenser", "Identity not found. Report to Civil Intake." },
    dispenser_nocard = { "Ration dispenser", "No ration card detected. Report for labor assignment." },
    dispenser_suspended = { "Ration dispenser", "Ration privileges suspended." },
    dispenser_wait = { "Ration dispenser", "Allocation not yet available. Return later." },
    dispenser_withheld = { "Ration dispenser", "Allocation withheld. Noncompliance is recorded." },
    dispenser_empty = { "Ration dispenser", "Distribution suspended." },
    dispenser_short = { "Ration dispenser", "Supply shortfall. Try again shortly." },
    dispenser_blackout = { "Ration dispenser", "Power failure. Service unavailable." },
    vending_credits = { "Vending machine", "Insufficient credits." },
    vending_blackout = { "Vending machine", "Power failure. Service unavailable." },
}

-- Which line a message is (the words the code already uses).
local MATCH = {
    { "aren't registered", "dispenser_unregistered" }, { "No ration card", "dispenser_nocard" },
    { "privileges have been suspended", "dispenser_suspended" }, { "Next allocation in", "dispenser_wait" },
    { "Allocation withheld", "dispenser_withheld" }, { "stores are empty", "dispenser_empty" },
    { "Supply shortfall", "dispenser_short" }, { "no rations until power", "dispenser_blackout" },
    { "Insert ", "vending_credits" }, { "Vending machines can't", "vending_blackout" },
}
function LC.MachineLineOf(text)
    for _, m in ipairs(MATCH) do if string.find(text or "", m[1], 1, true) then return m[2] end end
end

local AUDIO = { wav = true, mp3 = true, ogg = true }
local clips
local function Scan()
    clips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.MachineVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            clips[base] = clips[base] or {}
            table.insert(clips[base], LC.MachineVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.MachineVoiceRoot .. n) end
        end
    end
end
LC.MachineRescan = Scan
hook.Add("Initialize", "LivingCityMachines", Scan)

function LC.MachineClip(id)
    if not clips then Scan() end
    local t = clips[id]
    return t and t[math.random(#t)] or nil
end

-- The machine says it. False (do it the old way) when it's off or the message isn't one of its lines.
function LC.MachineSpeak(ent, ply, text, beep)
    if not cvVoice:GetBool() or not IsValid(ply) then return false end
    local id = LC.MachineLineOf(text)
    local line = id and LC.MachineLines[id]
    if not line then return false end
    local src = IsValid(ent) and ent or ply
    local clip = LC.MachineClip(id)
    if clip then src:EmitSound(clip, 70)
    elseif beep ~= false then src:EmitSound(beep or "buttons/combine_button_locked.wav", 65) end
    if LC.Notice then LC.Notice(ply, "speech", line[1], line[2]) end
    -- the full explanation in chat, without the tag (so it isn't a card as well)
    local rest = string.gsub(tostring(text), "^%[[^%]]+%]%s*", "")
    ply:ChatPrint("(" .. line[1] .. ") " .. rest)
    return true, id
end
