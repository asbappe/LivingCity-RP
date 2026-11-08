--[[
    Living City: talking, knowing each other, and going down

      In-character chat   ordinary chat is spoken out loud and heard nearby.
                            /me <action>     ** Name looks over his shoulder.
                            /it <text>       ** A door slams somewhere above.
                            /y <text>        yell (heard much further away)
                            /w <text>        whisper (only right next to you)
                            /looc <text>     out of character, nearby
                            // or /ooc       out of character, everyone
                            /roll [max]      roll a die where people can see
                          Voice carries the same way: people near you hear you.

      Recognition         you don't know anyone's name until they tell you.
                          Until then you see what they look like: their
                          description (/chardesc <text> to set yours). Tell
                          people your name with /recognize (whoever you're
                          looking at), /recognize all (everyone close enough to
                          hear), or /recognize whisper (right next to you).
                          Units searching or stopping you read your papers.

      Going down          taking a killing blow puts you on the ground instead,
                          bleeding out (lc_downed_secs, 90). Someone can press
                          E on you to stabilize you (faster with a bandage), a
                          unit can cuff you where you lie if you're wanted, and
                          anyone can drag you (!drag, looking at you). Get shot
                          again, or run out of time, and that's the end. You can
                          give up with !giveup. Only in the Living City gamemode.

      lc_ic_chat 0/1, lc_chat_range (350), lc_ooc 0/1, lc_ooc_cooldown (10),
      lc_voice_range (900, 0 = everyone hears everyone), lc_downed 0/1,
      lc_downed_secs (90)
]]

if CLIENT then return end

util.AddNetworkString("lc_chat")
util.AddNetworkString("lc_recog")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvIC       = CreateConVar("lc_ic_chat", "1", FLAGS, "In-character proximity chat: /me, /it, /y, /w, /looc, //")
local cvRange    = CreateConVar("lc_chat_range", "350", FLAGS, "How far ordinary speech carries")
local cvOOC      = CreateConVar("lc_ooc", "1", FLAGS, "Allow global out-of-character chat (// or /ooc)")
local cvOOCWait  = CreateConVar("lc_ooc_cooldown", "10", FLAGS, "Seconds between global OOC messages per player (admins exempt)")
local cvVoice    = CreateConVar("lc_voice_range", "900", FLAGS, "How far voice chat carries (0 = everyone hears everyone)")
local cvDowned   = CreateConVar("lc_downed", "1", FLAGS, "A killing blow puts players down, bleeding out, instead of killing them outright")
local cvDownSecs = CreateConVar("lc_downed_secs", "90", FLAGS, "Seconds a downed player has before they bleed out")

local function Active() return cvIC:GetBool() end
LC.ICChatActive = Active

-- Slash commands other modules add (/request, /vo, ...): LC.SlashCommands[name] = function(ply, rest).
-- In-character chat runs them; without it, they're handled by the module's own chat hook.
LC.SlashCommands = LC.SlashCommands or {}

------------------------------------------------------------------------
-- Descriptions and recognition
------------------------------------------------------------------------

local function CID(ply) return IsValid(ply) and ply:GetNW2String("lc_cid", "") or "" end

local function Recog(ply)
    if not ply.lcRecog then
        ply.lcRecog = util.JSONToTable(ply:GetPData("lc_recog", "") or "") or {}
    end
    return ply.lcRecog
end

local function SendRecog(ply)
    local list = {}
    for cid in pairs(Recog(ply)) do list[#list + 1] = cid end
    LC.SendCompressed("lc_recog", { cids = list }, { ply })
end
LC.SendRecog = SendRecog

local function Masked(ply)
    return (LC.PlayerIsCP and LC.PlayerIsCP(ply) and ply:GetNW2String("lcf_faction", "") ~= "admin")
        or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
end

-- Does `who` know `whom` by name?
function LC.Recognizes(who, whom)
    if who == whom then return true end
    if not IsValid(who) or not IsValid(whom) then return false end
    local cid = CID(whom)
    return cid ~= "" and Recog(who)[cid] == true
end

function LC.Introduce(from, to)
    if not IsValid(to) or to == from then return false end
    local cid = CID(from)
    if cid == "" or Recog(to)[cid] then return false end
    Recog(to)[cid] = true
    to:SetPData("lc_recog", util.TableToJSON(to.lcRecog))
    SendRecog(to)
    hook.Run("LivingCityIntroduced", from, to)
    return true
end

local function Gender(ply)
    local m = string.lower(ply:GetModel() or "")
    if string.find(m, "female", 1, true) or string.find(m, "police_fem", 1, true) or string.find(m, "alyx", 1, true) then return "woman" end
    return "man"
end

function LC.Description(ply)
    if Masked(ply) then return "A masked Civil Protection unit" end
    local f = ply:GetNW2String("lcf_faction", "")
    if LCF.IsOverwatch(ply) then return "An Overwatch soldier" end
    if string.find(string.lower(ply:GetModel() or ""), "vortigaunt", 1, true) then
        return f == "vort" and "A shackled vortigaunt" or "A vortigaunt"
    end
    local own = ply:GetNW2String("lc_desc", "")
    if own ~= "" then return own end
    local d = LC.Disguise and LC.Disguise(ply)
    local clothes = (d == "rebel" and "in Resistance gear") or (d == "citizen" and "in Union blue")
        or (string.find(string.lower(ply:GetModel() or ""), "group03", 1, true) and "in Resistance gear") or "in Union blue"
    return "A " .. Gender(ply) .. " " .. clothes
end

local function Short(text)
    if #text <= 40 then return text end
    local cut = string.sub(text, 1, 40)
    return (string.match(cut, "^(.*)%s") or cut) .. "..."
end

-- What `listener` calls `speaker`.
function LC.NameFor(listener, speaker)
    if Masked(speaker) then
        local t = (LC.DisguisedAsCP and LC.DisguisedAsCP(speaker)) and speaker:GetNW2String("lcd_title", "") or speaker:GetNW2String("lcf_title", "")
        if t ~= "" then return t end
    end
    if LC.Recognizes(listener, speaker) then
        local n = speaker:GetNW2String("lc_char", "")
        local alias = speaker:GetNW2String("lcd_alias", "")
        if alias ~= "" and listener ~= speaker then return "citizen " .. alias end -- forged papers: the name they gave
        return n ~= "" and n or speaker:Nick()
    end
    return "[" .. Short(LC.Description(speaker)) .. "]"
end

function LC.SetDescription(ply, text)
    text = string.Trim(tostring(text or ""))
    if text == "" then
        ply:SetNW2String("lc_desc", "")
        ply:SetPData("lc_desc", "")
        return true, "Description cleared: people see your clothes and build."
    end
    if #text < 8 then return false, "A little more than that (8 characters at least)." end
    if #text > 120 then return false, "Shorter, please (120 characters at most)." end
    if not string.match(text, "^[Aa]n? ") and not string.match(text, "^[Tt]he ") then text = "A " .. string.lower(string.sub(text, 1, 1)) .. string.sub(text, 2) end
    ply:SetNW2String("lc_desc", text)
    ply:SetPData("lc_desc", text)
    return true, "People who don't know you now see: " .. text
end

hook.Add("PlayerInitialSpawn", "LivingCityRP", function(ply)
    ply:SetNW2String("lc_desc", ply:GetPData("lc_desc", "") or "")
    timer.Simple(5, function() if IsValid(ply) then SendRecog(ply) end end)
end)

-- switching to another of your characters (sv_livingcity_slots.lua): their own acquaintances
hook.Add("LivingCityCharacterSwitched", "LivingCityRP", function(ply)
    ply.lcRecog = nil
    SendRecog(ply)
end)

-- a new life: nobody knows the new person, and the new person knows nobody
hook.Add("LivingCityNewCharacter", "LivingCityRP", function(ply)
    ply.lcRecog = {}
    ply:SetPData("lc_recog", "{}")
    ply:SetNW2String("lc_desc", "")
    ply:SetPData("lc_desc", "")
    SendRecog(ply)
end)

-- units reading your papers learn your name
hook.Add("LivingCitySearched", "LivingCityRP", function(searcher, target)
    if IsValid(searcher) and searcher:IsPlayer() and IsValid(target) and target:IsPlayer() then LC.Introduce(target, searcher) end
end)

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

local COL = {
    say = Color(235, 235, 220), me = Color(255, 200, 120), it = Color(255, 200, 120), yell = Color(255, 235, 200),
    whisper = Color(190, 190, 205), looc = Color(170, 200, 255), ooc = Color(150, 220, 150), roll = Color(200, 170, 255),
    dim = Color(160, 160, 160),
}

-- listener: one player, or a list of them (the same line to everyone: packed once)
local function Send(listener, parts)
    local packed = {}
    for _, p in ipairs(parts) do
        if type(p) == "table" then packed[#packed + 1] = { p.r, p.g, p.b } else packed[#packed + 1] = tostring(p) end
    end
    local recips = (type(listener) == "table" and listener[1] ~= nil) and listener or { listener }
    LC.SendCompressed("lc_chat", { p = packed }, recips)
end
LC.SendChat = Send

local function Near(pos, range)
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():DistToSqr(pos) < range * range then out[#out + 1] = p end
    end
    return out
end

local function Speak(ply, kind, text)
    -- a stalker has no words left (sv_livingcity_custody.lua): only the sound comes out
    if (kind == "say" or kind == "yell" or kind == "whisper") and LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then
        ply:EmitSound("npc/stalker/go_alert2a.wav", kind == "whisper" and 55 or 65, 100, 0.3) -- (0.3: a scream, and 0.5 was still too loud)
        kind, text = "me", "screams: a strained, wordless noise."
    end
    -- a unit saying one of the mask's lines word for word: heard in its voice too (sv_livingcity_cp.lua)
    if (kind == "say" or kind == "yell") and LC.VoiceForText then LC.VoiceForText(ply, text, kind) end
    local range = cvRange:GetFloat()
    if kind == "yell" then range = range * 2.8 elseif kind == "whisper" then range = 100 end
    for _, l in ipairs(Near(ply:GetPos(), range)) do
        local name = LC.NameFor(l, ply)
        if kind == "say" then
            Send(l, { COL.say, name .. " says: \"" .. text .. "\"" })
        elseif kind == "yell" then
            Send(l, { COL.yell, name .. " yells: \"" .. string.upper(text) .. "!\"" })
        elseif kind == "whisper" then
            Send(l, { COL.whisper, name .. " whispers: \"" .. text .. "\"" })
        elseif kind == "me" then
            Send(l, { COL.me, "** " .. name .. " " .. text })
        elseif kind == "it" then
            Send(l, { COL.it, "** " .. text })
        elseif kind == "looc" then
            Send(l, { COL.looc, "[LOOC] " .. ply:Nick() .. ": ", COL.dim, text })
        end
    end
    LC.Log("chat", string.format("[%s] %s (%s): %s", kind, ply:Nick(), ply:GetNW2String("lc_char", ""), text))
    hook.Run("LivingCitySpoke", ply, kind, text) -- (the morning parade listens for cheering: sv_livingcity_exercise.lua)
end
LC.Speak = Speak

local PREFIX = {
    ["/me "] = "me", ["/it "] = "it", ["/y "] = "yell", ["/yell "] = "yell", ["/w "] = "whisper", ["/whisper "] = "whisper",
    ["/looc "] = "looc", ["/l "] = "looc", [".// "] = "looc",
}

local function Recognize(ply, arg)
    arg = string.lower(string.Trim(arg or ""))
    local targets = {}
    if arg == "all" or arg == "everyone" then
        for _, p in ipairs(Near(ply:GetPos(), cvRange:GetFloat())) do targets[#targets + 1] = p end
    elseif arg == "whisper" or arg == "w" then
        for _, p in ipairs(Near(ply:GetPos(), 100)) do targets[#targets + 1] = p end
    else
        local tr = ply:GetEyeTrace()
        local e = tr and tr.Entity
        if IsValid(e) and e:IsPlayer() and e:GetPos():DistToSqr(ply:GetPos()) < 250 * 250 then targets[1] = e end
    end
    local told = 0
    for _, t in ipairs(targets) do
        if t ~= ply and LC.Introduce(ply, t) then
            told = told + 1
            Send(t, { COL.me, "** " .. Short(LC.Description(ply)) .. " introduces themselves as " .. ply:GetNW2String("lc_char", ply:Nick()) .. "." })
        end
    end
    if told == 0 then
        ply:ChatPrint(#targets == 0 and "Look at someone (or /recognize all, for everyone close enough to hear)." or "They already know who you are.")
    else
        ply:ChatPrint(string.format("You tell %d %s your name.", told, told == 1 and "person" or "people"))
    end
    return told
end
LC.Recognize = Recognize

hook.Add("PlayerSay", "LivingCityICChat", function(ply, text, team)
    local raw = string.Trim(text or "")
    if raw == "" then return end
    if LC.RadioRaisedSay and LC.RadioRaisedSay(ply, raw) then return "" end -- (the radio's up: it went over the band)
    if LC.AdmireSay and LC.AdmireSay(ply, raw) then return "" end -- (a compliment in the Administrator's dream: it stays in the dream)
    local lower = string.lower(raw)

    -- always available, whatever the chat mode
    local recArg = (lower == "/recognize" or lower == "!recognize" or lower == "/rec" or lower == "!rec") and ""
        or string.match(lower, "^[/!]recognize%s+(.*)$") or string.match(lower, "^[/!]rec%s+(.*)$")
    if recArg then Recognize(ply, recArg) return "" end
    local desc = string.match(raw, "^[/!][Cc][Hh][Aa][Rr][Dd][Ee][Ss][Cc]%s*(.*)$")
    if desc then
        if desc == "" then
            ply:ChatPrint("Your description: " .. LC.Description(ply) .. "  (/chardesc <text> to change it, /chardesc clear to reset)")
        else
            local _, msg = LC.SetDescription(ply, string.lower(desc) == "clear" and "" or desc)
            ply:ChatPrint(msg)
        end
        return ""
    end

    if not Active() then return end
    if string.sub(raw, 1, 1) == "!" then return end -- game commands belong to the other modules
    if string.sub(raw, 1, 1) == "@" then return end -- a ticket to staff (sv_livingcity_staff.lua)

    -- global out of character
    local ooc = string.match(raw, "^//%s*(.+)$") or string.match(raw, "^/ooc%s+(.+)$") or string.match(raw, "^/a%s+(.+)$")
    if ooc then
        if not cvOOC:GetBool() then ply:ChatPrint("Global OOC is off on this server. /looc talks out of character to people nearby.") return "" end
        if not ply:IsAdmin() and (ply.lcOOCNext or 0) > CurTime() then
            ply:ChatPrint(string.format("Wait %ds before OOC again.", math.ceil(ply.lcOOCNext - CurTime())))
            return ""
        end
        ply.lcOOCNext = CurTime() + cvOOCWait:GetFloat()
        Send(player.GetAll(), { COL.ooc, "[OOC] " .. ply:Nick() .. ": ", color_white, ooc })
        LC.Log("chat", "[ooc] " .. ply:Nick() .. ": " .. ooc)
        return ""
    end

    local roll = string.match(lower, "^/roll%s*(%d*)$")
    if roll then
        local max = math.Clamp(tonumber(roll) or 100, 2, 1000)
        local n = math.random(1, max)
        for _, l in ipairs(Near(ply:GetPos(), cvRange:GetFloat())) do
            Send(l, { COL.roll, "** " .. LC.NameFor(l, ply) .. " rolls " .. n .. " out of " .. max .. "." })
        end
        return ""
    end

    for pre, kind in pairs(PREFIX) do
        if string.sub(lower, 1, #pre) == pre then
            local body = string.Trim(string.sub(raw, #pre + 1))
            if body == "" then return "" end
            if not ply:Alive() and kind ~= "looc" then ply:ChatPrint("The dead don't talk.") return "" end
            Speak(ply, kind, body)
            return ""
        end
    end
    if string.sub(raw, 1, 1) == "/" then
        -- other modules' slash commands (/request, /vo, ...)
        local cmd, rest = string.match(raw, "^/(%S+)%s*(.*)$")
        local fn = cmd and LC.SlashCommands[string.lower(cmd)]
        if fn then fn(ply, rest or "") return "" end
        -- a command nobody knows: don't say it out loud
        local extra = {}
        for k in pairs(LC.SlashCommands) do extra[#extra + 1] = "/" .. k end
        table.sort(extra)
        ply:ChatPrint("Unknown command. Chat: /me /it /y /w /looc // /roll /recognize /chardesc" .. (#extra > 0 and (" " .. table.concat(extra, " ")) or ""))
        return ""
    end

    if not ply:Alive() then ply:ChatPrint("The dead don't talk. (// for OOC.)") return "" end
    if team then Speak(ply, "looc", raw) return "" end
    Speak(ply, ply.lcDowned and "whisper" or "say", raw) -- on the ground, you can barely speak
    return ""
end)

-- Voice: heard near you, and from where you are.
hook.Add("PlayerCanHearPlayersVoice", "LivingCityVoice", function(listener, talker)
    if LC.LiveSpeaker and talker == LC.LiveSpeaker then return end -- on air: the broadcast decides (sv_livingcity_propaganda.lua)
    if LC.RadioVoice then -- (talking into a radio: the band, and whoever is right beside them)
        local hear, near = LC.RadioVoice(listener, talker)
        if hear ~= nil then return hear, near end
    end
    local r = cvVoice:GetFloat()
    if r <= 0 or not Active() then return end
    if not talker:Alive() and listener:Alive() then return false, false end
    return listener:GetPos():DistToSqr(talker:GetPos()) < r * r, true
end)

------------------------------------------------------------------------
-- Going down
------------------------------------------------------------------------

LC.Downed = LC.Downed or {} -- [ply] = { rag, untilT, weapons, dragger }

local function DownedActive()
    return cvDowned:GetBool()
end
LC.DownedActive = DownedActive

function LC.IsDowned(ply) return LC.Downed[ply] ~= nil end

local function Rag(ply)
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return nil end
    rag:SetModel(ply:GetModel())
    rag:SetPos(ply:GetPos())
    rag:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    if ply.GetSkin and rag.SetSkin then rag:SetSkin(ply:GetSkin()) end
    rag:Spawn()
    rag:Activate()
    local count = rag.GetPhysicsObjectCount and rag:GetPhysicsObjectCount() or 0
    local vel = ply:GetVelocity()
    for i = 0, count - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        local bone = rag:TranslatePhysBoneToBone(i)
        if IsValid(phys) and bone and ply.GetBonePosition then
            local pos, ang = ply:GetBonePosition(bone)
            if pos then phys:SetPos(pos) end
            if ang then phys:SetAngles(ang) end
            phys:SetVelocity(vel)
        end
    end
    rag.lcDownedPly = ply
    rag:SetNW2Bool("lc_downed_body", true)
    rag:SetNW2Entity("lc_downed_ply", ply)
    return rag
end

-- Called from the gamemode before damage is applied. True: the blow was absorbed (they went down).
function LC.TryDown(ply, dmg)
    if not DownedActive() or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LC.Downed[ply] or ply.lcFinishing then return false end
    if dmg:GetDamage() < ply:Health() then return false end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return false end -- the infested just die
    if ply:GetNW2Bool("lc_build", false) then return false end
    if dmg:GetDamage() >= 300 then return false end -- nobody gets up from that
    LC.GoDown(ply, dmg:GetAttacker())
    return true
end

function LC.GoDown(ply, attacker)
    local now = CurTime()
    local d = { untilT = now + cvDownSecs:GetFloat(), weapons = {}, attacker = attacker, at = now }
    for _, w in ipairs(ply:GetWeapons()) do d.weapons[#d.weapons + 1] = w:GetClass() end
    d.rag = Rag(ply)
    LC.Downed[ply] = d
    ply.lcDowned = true
    ply:SetHealth(1)
    if ply.StripWeapons then ply:StripWeapons() end
    if ply.AddFlags then ply:AddFlags(FL_NOTARGET or 65536) end
    if IsValid(d.rag) then
        if ply.Spectate then ply:Spectate(OBS_MODE_CHASE or 5) end
        if ply.SpectateEntity then ply:SpectateEntity(d.rag) end
        ply:SetNoDraw(true)
        if ply.SetNotSolid then ply:SetNotSolid(true) end
    end
    ply:SetNW2Float("lc_downed_until", d.untilT)
    ply:EmitSound("vo/npc/" .. (string.find(string.lower(ply:GetModel() or ""), "female", 1, true) and "female01" or "male01") .. "/pain0" .. math.random(1, 9) .. ".wav", 75)
    ply:ChatPrint("[Living City] You're down, bleeding out. Someone can help you up (E on you). Hold on, or F1 > Give up.")
    -- whoever was after them stops shooting at a body
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.enemy == ply or st.foe == ply) then
            if LC.IsSecurity(st) and LC.CalmOne then LC.CalmOne(npc, st, now) end
            if st.role == "rebel" then st.foe = nil npc:SetEnemy(NULL) end
        end
    end
    hook.Run("LivingCityDowned", ply, attacker)
end

local function Restore(ply, d, keepRag)
    LC.Downed[ply] = nil
    ply.lcDowned = nil
    ply:SetNW2Float("lc_downed_until", 0)
    if ply.RemoveFlags then ply:RemoveFlags(FL_NOTARGET or 65536) end
    local pos = IsValid(d.rag) and d.rag:GetPos() or ply:GetPos()
    if ply.UnSpectate then ply:UnSpectate() end
    ply:SetNoDraw(false)
    if ply.SetNotSolid then ply:SetNotSolid(false) end
    if ply.SetMoveType then ply:SetMoveType(MOVETYPE_WALK) end
    ply:SetPos(pos + Vector(0, 0, 8))
    if IsValid(d.rag) then
        if keepRag then
            -- letting go: the body that is already on the ground stays as the body
            local rag = d.rag
            timer.Simple(60, function() if IsValid(rag) then rag:Remove() end end)
        else
            d.rag:Remove()
        end
    end
    return pos
end

function LC.Revive(ply, hp, by)
    local d = LC.Downed[ply]
    if not d then return false end
    Restore(ply, d)
    ply:SetHealth(math.max(1, hp or 15))
    for _, cls in ipairs(d.weapons) do ply:Give(cls) end
    if ply.SelectWeapon then ply:SelectWeapon("weapon_lc_hands") end
    ply:ChatPrint(IsValid(by) and ("[Living City] " .. LC.NameFor(ply, by) .. " gets you back on your feet.") or "[Living City] You get back on your feet.")
    hook.Run("LivingCityRevived", ply, by)
    return true
end

-- The end: they die where they lie.
function LC.FinishDowned(ply, why)
    local d = LC.Downed[ply]
    if not d then return false end
    local attacker = d.attacker
    Restore(ply, d, true)
    ply.lcFinishing = true
    ply.lcNoDeathRag = IsValid(d.rag) or nil -- (no second ragdoll on top of the one already there)
    if ply.lcNoDeathRag then ply:SetNoDraw(true) ply.lcHidForDeath = true end
    -- credited to whoever put them down (the conduct system judges that kill)
    ply:TakeDamage(ply:Health() + 500, IsValid(attacker) and attacker or ply, IsValid(attacker) and attacker or ply)
    if ply:Alive() and ply.Kill then ply:Kill() end
    ply.lcFinishing = nil
    ply.lcNoDeathRag = nil
    if why then ply:ChatPrint("[Living City] " .. why) end
    return true
end

-- Dying after being down: the ragdoll is already on the ground, so the default
-- death ragdoll is skipped (returning a value here stops the gamemode's own).
hook.Add("DoPlayerDeath", "LivingCityNoSecondRagdoll", function(ply)
    if ply.lcNoDeathRag then return true end
end)
hook.Add("PlayerSpawn", "LivingCityNoSecondRagdoll", function(ply)
    ply.lcNoDeathRag = nil
    if ply.lcHidForDeath then ply.lcHidForDeath = nil ply:SetNoDraw(false) end
end)

-- A unit cuffs a wanted person where they lie.
local function CuffDowned(cop, ply)
    if not LC.Incarcerate then return false end
    local d = LC.Downed[ply]
    if not d then return false end
    LC.Revive(ply, 10, cop)
    local secs = GetConVar("lc_prison_time") and GetConVar("lc_prison_time"):GetFloat() or 180
    LC.Incarcerate(ply, secs, "Arrested while incapacitated", cop)
    return true
end

local function HelpDowned(helper, ply)
    local d = LC.Downed[ply]
    if not d or LC.Busy and LC.Busy(helper) then return end
    if helper == ply then return end
    local cop = LC.PlayerIsCP(helper) and LC.PlayerIsWanted and LC.PlayerIsWanted(ply)
    local bandage = LC.HasItem and LC.HasItem(helper, "bandage")
    local secs = cop and 3 or (bandage and 4 or 8)
    local text = cop and "Cuffing them..." or (bandage and "Bandaging the wound..." or "Stopping the bleeding with your hands...")
    LC.StartTask(helper, secs, text, {
        maxMove = 60, cancelText = "You leave them.",
        done = function(p)
            if not LC.Downed[ply] then return end
            if cop then
                CuffDowned(p, ply)
                p:ChatPrint("You cuff them where they lie. They'll live long enough for a cell.")
                return
            end
            if bandage and LC.TakeItem(p, "bandage") then
                LC.Revive(ply, 30, p)
            else
                LC.Revive(ply, 10, p)
            end
            p:ChatPrint("You get them back on their feet.")
            if LC.AddStanding and not LC.PlayerIsCP(p) then LC.AddStanding(p, 2) end
        end,
    })
end

hook.Add("PlayerUse", "LivingCityDowned", function(ply, ent)
    if not IsValid(ent) or not ent.lcDownedPly then return end
    if (ply.lcDownUseNext or 0) > CurTime() then return false end
    ply.lcDownUseNext = CurTime() + 0.6
    if IsValid(ent.lcDownedPly) then HelpDowned(ply, ent.lcDownedPly) end
    return false
end)

-- hitting someone who's down finishes them
hook.Add("EntityTakeDamage", "LivingCityDownedBody", function(ent, dmg)
    local ply = ent.lcDownedPly
    if not IsValid(ply) or not LC.Downed[ply] then return end
    if dmg:GetDamage() >= 8 then
        LC.Downed[ply].attacker = dmg:GetAttacker()
        LC.FinishDowned(ply, "They finished what they started.")
    end
    return true
end)

-- dragging a body
function LC.ToggleDrag(ply)
    -- someone tied up: walked along instead (sv_livingcity_cp.lua)
    if LC.TryEscort then
        local handled, why = LC.TryEscort(ply)
        if handled ~= nil then return handled, why end
    end
    for victim, d in pairs(LC.Downed) do
        if d.dragger == ply then d.dragger = nil ply:ChatPrint("You let go.") return true end
    end
    local tr = ply:GetEyeTrace()
    local rag = tr and tr.Entity
    if not (IsValid(rag) and rag.lcDownedPly and LC.Downed[rag.lcDownedPly]) or rag:GetPos():DistToSqr(ply:GetPos()) > 150 * 150 then
        return false, "Look at someone who's down, up close."
    end
    LC.Downed[rag.lcDownedPly].dragger = ply
    ply:ChatPrint("You take hold and drag. (F1 > Drag them along again to let go.)")
    return true
end

timer.Create("LivingCityDowned", 0.1, 0, function()
    local now = CurTime()
    for ply, d in pairs(LC.Downed) do
        if not IsValid(ply) then
            if IsValid(d.rag) then d.rag:Remove() end
            LC.Downed[ply] = nil
        elseif now >= d.untilT then
            LC.FinishDowned(ply, "You bled out.")
        else
            local dr = d.dragger
            if IsValid(dr) and dr:Alive() and IsValid(d.rag) then
                local phys = d.rag.GetPhysicsObjectNum and d.rag:GetPhysicsObjectNum(0)
                local target = dr:GetPos() - dr:GetForward() * 45 + Vector(0, 0, 20)
                if dr:GetPos():DistToSqr(d.rag:GetPos()) > 250 * 250 then
                    d.dragger = nil
                elseif IsValid(phys) then
                    phys:SetVelocity((target - phys:GetPos()) * 6)
                else
                    d.rag:SetPos(target) -- (no physics to pull on)
                end
            elseif dr ~= nil then
                d.dragger = nil
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityDowned", function(ply)
    local d = LC.Downed[ply]
    if d and IsValid(d.rag) then d.rag:Remove() end
    LC.Downed[ply] = nil
end)

-- a death that happens anyway (a fall, the world) cleans up the body
hook.Add("PlayerDeath", "LivingCityDowned", function(ply)
    local d = LC.Downed[ply]
    if d then Restore(ply, d) end
end)

hook.Add("PlayerSay", "LivingCityDownedChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!giveup" or t == "/giveup" then
        if LC.Downed[ply] then LC.FinishDowned(ply, "You let go.") else ply:ChatPrint("You're not down.") end
        return ""
    end
    if t == "!drag" or t == "/drag" then
        local ok, why = LC.ToggleDrag(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
end)

concommand.Add("lc_drag", function(ply) if IsValid(ply) then local ok, why = LC.ToggleDrag(ply) if not ok and why then ply:ChatPrint(why) end end end)
