--[[
    Civil notice poster (Living City). Place it with the Living City Editor
    ("Fixture: Civil notice poster") on a wall: it faces you.

    Its words fit whatever official thing is nearest, so a poster teaches
    the rule right where it applies, on any map (the owner, 10 November:
    "signs and posters that teach"): beside the ration dispenser, that labor
    earns rations; at the Commissary, that credits come from work; at Civil
    Intake and the desks, that arrivals must register; by a sink or a water
    machine, that untreated water carries parasites; by the law board, to
    know the law; anywhere else, curfew.

    Eleven more are hung by hand only, by the Director of Propaganda (the
    poster roll, weapon_lc_posters.lua; LC.HangPoster): work, loyalty,
    informants, contraband, radio, illness, infestation, housing, vortigaunt,
    recruit, administrator. Those keep the poster they were hung as.

    The Resistance answers (the owner, 10 November): a spray can used on any
    poster paints over it (lc_defaced: the picture <kind>_x, the words in
    DEFACED below; LC.DefacePoster), until someone with a roll pastes a fresh
    one over it or takes it down. And four paste-ups of their own, which only
    a Resistance member holding a roll can hang: rebel_leash, rebel_water,
    rebel_home, rebel_watch.

    Some plain curfew ones hint at a dream instead, a different few each day
    (the owner, 12 November; sv_livingcity_dreamposters.lua, lc_dream_posters):
    lc_notice "dream", its words in lc_dream_head and lc_dream_body.

    Press E to read it closely: that's learning it, and its tip cards don't
    come (LC.Learn, sv_livingcity_learning.lua).

    Your own artwork: garrysmod/materials/livingcity/posters/<kind>.png (or
    .jpg), kind = any of the names below; a 3:4
    portrait picture (768 x 1024 is plenty). With one, the poster shows it;
    without, the drawn notice below. They're sent to players when the map
    starts. The brief for each picture: POSTER_BRIEF.md.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Civil notice poster"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- kind = { heading, body } (what reading each teaches: LC.CivPosterTips, sv_livingcity_learning.lua)
local NOTICES = {
    dispenser = { "LABOR EARNS RATIONS", "One ration card for each ration. One card for each completed Union shift. No card, no ration." },
    commissary = { "THE COMMISSARY SERVES THE COMPLIANT", "Food, water, medicine and tablets, for credits. Credits are earned by work." },
    intake = { "ALL ARRIVALS MUST REGISTER", "Unregistered persons receive no rations, no work and no housing. Carry your papers at all times." },
    water = { "UNTREATED WATER CARRIES PARASITES", "Drink only from approved taps and machines. Antiparasitic tablets are available at the Commissary." },
    law = { "KNOW THE LAW", "Ignorance of the law is no defence. The city's laws are posted here. Comply." },
    curfew = { "CURFEW IS ABSOLUTE", "At the two-minute warning, return to your housing block. Do not run in the presence of Civil Protection." },
    -- hung by hand only (the Director of Propaganda's posters: weapon_lc_posters.lua)
    work = { "IDLE HANDS BURDEN THE CITY", "Every citizen has a shift. Report to Labor Assignment. The Union remembers who works." },
    loyalty = { "LOYALTY IS NOTICED", "Good standing opens doors. Poor standing closes them. Your record is always current." },
    informants = { "REPORT WHAT YOU HEAR", "A word to Civil Protection keeps your block safe. Silence protects no one." },
    contraband = { "CONTRABAND FEEDS THE ENEMY", "Unlicensed goods are confiscated. So are those who carry them. Submit to search." },
    radio = { "UNLICENSED FREQUENCIES ARE MONITORED", "The city speaks on approved channels only. We hear the others too." },
    illness = { "A COUGH UNREPORTED IS A COUGH SHARED", "Report illness at once. Medicine is available at the Commissary. Rest, and return to work." },
    infestation = { "DO NOT APPROACH. REPORT.", "Growths and spores spread by touch. Keep away. Sanitation crews will cleanse the area." },
    housing = { "YOUR ROOM IS A PRIVILEGE", "Housing is assigned to registered workers. Keep it clean. Keep it quiet. Keep it." },
    vortigaunt = { "THEY SERVE, AS YOU SERVE", "Shackled labor keeps your streets clean. Do not speak to it. Do not free it." },
    recruit = { "JOIN CIVIL PROTECTION. EAT BETTER.", "Better rations. Better housing. A place in the new order. Apply at any post." },
    administrator = { "SHE WATCHES OVER YOU", "Your Administrator works while you sleep. Work well, sleep well, and trust in her." },
    -- (the owner's own slogan, 14 November: never reword it; it has no smaller words)
    neighbour = { "LOVE YOUR NEIGHBOUR, HATE THE TRAITOR", "" },
    -- the Resistance's own paste-ups (only a Resistance member with a roll hangs these)
    rebel_leash = { "THE RATION IS THE LEASH", "They feed you so you will not bite." },
    rebel_water = { "DON'T DRINK THE WATER", "They put something in it to make you forget." },
    rebel_home = { "THIS IS NOT YOUR HOME", "Remember who you were." },
    rebel_watch = { "SHE WATCHES. WE SEE.", "The Resistance is closer than you think." },
}
ENT.Notices = NOTICES
ENT.RebelOrder = { "rebel_watch", "rebel_leash", "rebel_water", "rebel_home" }
-- what the Resistance paints over each of the city's posters (the picture: <kind>_x)
local DEFACED = {
    dispenser = "CHAINS", commissary = "THE COMBINE", intake = "LIKE CATTLE", water = "DON'T DRINK IT. It makes you forget",
    law = "BREAK IT", curfew = "THE NIGHT IS OURS", work = "BUSY HANDS BUILD CAGES", loyalty = "SO IS COURAGE",
    informants = "SNITCHES BURN", contraband = "ARMS US", radio = "WE HEAR YOU TOO", illness = "THE CITY IS THE SICKNESS",
    infestation = "THEY LET IT GROW", housing = "IS A CELL", vortigaunt = "FREE THEM", recruit = "TRAITORS", administrator = "LIAR", neighbour = "LIES",
}
DEFACED.dream = "WAKE UP"
ENT.Defaced = DEFACED

-- Its heading and body (a dream's poster carries its own words: sv_livingcity_dreamposters.lua).
function ENT:Words()
    local kind = self:GetNW2String("lc_notice", "curfew")
    if kind == "dream" then
        return { self:GetNW2String("lc_dream_head", "SLEEP WELL, CITIZEN"), self:GetNW2String("lc_dream_body", "") }
    end
    return NOTICES[kind] or NOTICES.curfew
end
-- (the order the Director's poster roll lists them in)
ENT.NoticeOrder = { "administrator", "neighbour", "loyalty", "informants", "work", "housing", "recruit", "contraband", "radio", "illness", "infestation", "vortigaunt",
    "curfew", "law", "dispenser", "commissary", "intake", "water" }

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/paper01.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-2, -24, -32), Vector(2, 24, 32))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self:SetNW2String("lc_notice", "curfew")
    -- the other fixtures may not be out yet: look a moment later, and again now and then
    timer.Simple(2, function() if IsValid(self) then self:PickNotice() end end)
end

if SERVER then
    -- (what's nearest, and what reading it teaches: sv_livingcity_learning.lua)
    function ENT:PickNotice()
        -- (a dream's own billboard is what it was made as: LC.DreamBillboard)
        if self.lcDreamProp then self.lcPickedAt = CurTime() return self:GetNW2String("lc_notice", "dream") end
        -- (one hung by hand keeps the poster it was hung as: LC.HangPoster)
        local best = self.lcFixedKind or (LC and LC.CivPosterNotice and LC.CivPosterNotice(self:GetPos())) or "curfew"
        -- (a plain curfew one may hint at a dream instead today: sv_livingcity_dreamposters.lua)
        if best == "curfew" and not self.lcFixedKind and LC and LC.DreamPosterFor then
            local id = LC.DreamPosterFor(self:GetPos())
            if id then
                local head, body = LC.DreamPosterWords(id)
                self:SetNW2String("lc_dream_id", id)
                self:SetNW2String("lc_dream_head", head)
                self:SetNW2String("lc_dream_body", body)
                best = "dream"
            end
        end
        self:SetNW2String("lc_notice", best)
        self.lcPickedAt = CurTime()
        return best
    end

    function ENT:Think()
        if CurTime() - (self.lcPickedAt or 0) > 120 then self:PickNotice() end
        self:NextThink(CurTime() + 30)
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local kind = self:GetNW2String("lc_notice", "curfew")
        local n = self:Words()
        if self:GetNW2Bool("lc_defaced", false) then
            activator:ChatPrint("[City] " .. n[1] .. ". Someone has painted over it: " .. (DEFACED[kind] or "the lambda") .. ".")
            return
        end
        if string.sub(kind, 1, 6) == "rebel_" then activator:ChatPrint("[Paste-up] " .. n[1] .. " " .. n[2]) return end
        activator:ChatPrint("[City] " .. n[1] .. "." .. (n[2] ~= "" and (" " .. n[2]) or ""))
        if kind ~= "dream" and LC and LC.CivPosterRead then LC.CivPosterRead(activator, kind) end
    end
end

if CLIENT then
    local PAPER, INK, RED, ORANGE = Color(205, 200, 185, 245), Color(25, 25, 28), Color(150, 20, 20), Color(232, 145, 42)
    local NIGHT = Color(40, 46, 96) -- (a dream's poster: night blue where the others are red)
    local art = {} -- [kind] = the owner's picture (a Material), or false
    local function Art(kind)
        if art[kind] == nil then
            art[kind] = false
            for _, ext in ipairs({ "png", "jpg" }) do
                local path = "livingcity/posters/" .. kind .. "." .. ext
                if file.Exists("materials/" .. path, "GAME") then art[kind] = Material(path, "smooth mips") break end
            end
        end
        return art[kind]
    end
    function ENT:Draw()
        -- (a billboard inside a dream is several times the size: LC.DreamBillboard)
        local big = math.max(1, self:GetNW2Float("lc_big", 1))
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > (900 * big) ^ 2 then return end
        if big > 1 and self.lcBigBounds ~= big and self.SetRenderBounds then
            self.lcBigBounds = big
            self:SetRenderBounds(Vector(-4, -26, -34) * big, Vector(4, 26, 34) * big)
        end
        local kind = self:GetNW2String("lc_notice", "curfew")
        local n = self:Words()
        local dreamy = kind == "dream"
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        -- painted over: its own picture when there is one, else the words daubed across the clean one
        local defaced = self:GetNW2Bool("lc_defaced", false)
        local pic = defaced and Art(kind .. "_x") or nil
        local daub = nil
        if not (pic and not pic:IsError()) then
            pic = Art(kind)
            -- (a dream's: its own picture, dream_<id>, else dream.png)
            if dreamy then
                local own = Art("dream_" .. self:GetNW2String("lc_dream_id", ""))
                if own and not own:IsError() then pic = own end
            end
            daub = defaced and (DEFACED[kind] or "LIES") or nil
        end
        if pic and not pic:IsError() then
            cam.Start3D2D(self:GetPos() + self:GetForward() * 0.6, ang, 0.1 * big)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(pic)
                surface.DrawTexturedRect(-230, -310, 460, 620)
                if daub then draw.SimpleTextOutlined(daub, "DermaLarge", 0, -60, ORANGE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, INK) end
            cam.End3D2D()
            return
        end
        cam.Start3D2D(self:GetPos() + self:GetForward() * 0.6, ang, 0.1 * big)
            draw.RoundedBox(0, -230, -310, 460, 620, PAPER)
            draw.RoundedBox(0, -230, -310, 460, 70, dreamy and NIGHT or RED)
            draw.SimpleText(dreamy and "SLEEP WELL, CITIZEN" or "CITY ADMINISTRATION", "DermaLarge", 0, -275, PAPER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if self.lcWrappedH ~= n[1] and LC_CL and LC_CL.WrapText then
                self.lcHead, self.lcBody = LC_CL.WrapText(n[1], "DermaLarge", 420), LC_CL.WrapText(n[2], "DermaDefaultBold", 400)
                self.lcWrappedH = n[1]
            end
            local y = -200
            for _, l in ipairs(self.lcHead or { n[1] }) do
                draw.SimpleText(l, "DermaLarge", 0, y, INK, TEXT_ALIGN_CENTER)
                y = y + 40
            end
            y = y + 30
            for _, l in ipairs(self.lcBody or { n[2] }) do
                draw.SimpleText(l, "DermaDefaultBold", 0, y, INK, TEXT_ALIGN_CENTER)
                y = y + 26
            end
            draw.SimpleText("Your cooperation is noted.", "DermaDefault", 0, 280, INK, TEXT_ALIGN_CENTER)
            if daub then draw.SimpleTextOutlined(daub, "DermaLarge", 0, -60, ORANGE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, INK) end
        cam.End3D2D()
    end
end
