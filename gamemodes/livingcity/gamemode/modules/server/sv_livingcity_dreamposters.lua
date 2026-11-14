--[[
    Living City: posters that hint at dreams

    The owner, 12 November: "propaganda posters that hint at dreams. Posters in
    the city reflect and foreshadow the dreams (tonight's, or ones people have
    had)."

    Some of the city's own posters (the editor's "Civil notice poster") that
    would show the plain curfew notice, the one hung where no machine or desk
    is near, show a dream's poster instead: lc_dream_posters of them (a
    quarter), a different few each day. Posters beside a ration dispenser, the
    Commissary, Civil Intake, water or the law board keep teaching their rule,
    and posters hung by hand keep what they were hung as.

    Half of them foreshadow tonight's dream (the one the city would choose for
    tonight as the day stands: LC.DreamPlanDecide, LC.DreamPlanNext), half
    remember one the city dreamt lately (the last three, test dreams never);
    with none dreamt yet, all foreshadow. The words never name the dream: a
    poster hints, in the city's voice (HINTS below; any dream without its own
    lines gets its mood's).

    Your own picture for one: garrysmod/materials/livingcity/posters/dream_<id>.png
    (or .jpg; the dream's codeword, as lc_endings lists them), else dream.png
    for all of them, else the drawn notice. Painted over by the Resistance it
    reads WAKE UP.

    The owner, 14 November: every poster's small words read as one sentence;
    and the melons' picture is "too on the nose" for the waking city, so it
    hangs only inside that dream (dream_forecast.jpg, LC.DreamBillboard below,
    sv_livingcity_strangedreams.lua); the city's hint at it stays the drawn notice.
    The Nightmares' and propaganda dreams' words are the owner's own (14 November,
    their corrected list): leave them as they are.
]]

if CLIENT then return end

LC = LC or {}

local cvShare = CreateConVar("lc_dream_posters", "0.25", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Share of the city's plain curfew posters that show a poster hinting at a dream instead (tonight's or one dreamt lately; 0: none)")

-- [dream codeword] = { heading, body }. In the city's voice; a hint, never the dream's name.
local HINTS = {
    -- Happy
    flying = { "KEEP YOUR FEET ON THE GROUND", "The sky belongs to the Combine, and citizens who leave the ground will be returned to it." },
    melons = { "FORECAST: FAIR, WITH PRODUCE", "Fresh fruit is a privilege of compliance; do not look up for it." },
    lamarr = { "HAVE YOU SEEN THIS ANIMAL?", "A small, bald, beaked pet is loose in the city: do not approach it, do not feed it, report it." },
    dance = { "IDLE FEET ARE IDLE HANDS", "Movement without purpose is forbidden, and movement to music doubly so." },
    sheep = { "CAN'T SLEEP? COUNT YOUR BLESSINGS", "Not the other thing, never the other thing; sleep is mandatory." },
    derby = { "PARASITE RACING IS ILLEGAL", "Wagering on headcrabs is a crime against hygiene, and Sanitation is watching." },
    paint = { "PAINT IS A CONTROLLED SUBSTANCE", "All colour belongs to the city, and unlicensed colour will be scrubbed." },
    conga = { "SINGLE FILE. NO DANCING.", "Lines are for rations, not for fun." },
    bubbles = { "SOAP IS FOR WASHING", "Surplus soap must be returned to the Commissary, for nothing floats in this city." },
    rally = { "NO RACING AFTER CURFEW", "Unlicensed vehicles will be confiscated, and so will their drivers." },
    -- Neutral
    cheese = { "DAIRY IS A PRIVILEGE", "Citizens do not think about cheese; citizens think about their quota." },
    chairs = { "A SEAT FOR EVERY WORKER", "Unless there is not, so remain standing until told." },
    horse = { "KNOW YOUR OWN FACE", "Report any change to your appearance at once, especially hooves." },
    boxing = { "DISPUTES ARE SETTLED BY CIVIL PROTECTION", "Not in a ring, not with gloves and not under lights." },
    exam = { "ARE YOU READY FOR YOUR ASSESSMENT?", "Every citizen will be tested, and you will not know when, so study." },
    train = { "EVERY TRAIN ARRIVES ON TIME", "Do not ask where the last one goes." },
    potato = { "DO NOT PASS IT ON", "Whatever you are holding, it is now your responsibility." },
    simon = { "DO ONLY WHAT OVERWATCH SAYS", "And only when Overwatch says it, so listen closely." },
    clocks = { "TIME IS THE CITY'S", "Clocks are not to be stopped, wound back or argued with." },
    tea = { "GATHERINGS OF MORE THAN THREE ARE FORBIDDEN", "This includes tea, and this especially includes tea." },
    photo = { "SMILE. YOU ARE BEING RECORDED.", "Every face is on file, so keep yours still." },
    doors = { "NOT EVERY DOOR IS FOR YOU", "Open only the doors you were assigned, for some open onto nothing." },
    shh = { "SILENCE IS COMPLIANCE", "Quiet blocks are safe blocks, and something is listening for noise." },
    can = { "PICK IT UP", "Litter is disorder: when an officer tells you, you pick it up, then you put it in the bin." },
    -- Nightmares
    maze = { "THE PATROL KNOWS EVERY TURN", "Traitors can run, but they cannot hide." },
    barrels = { "DO NOT STACK BARRELS", "They're heavier than they look; an injury is just a fall away." },
    crumble = { "WATCH YOUR STEP", "Report cracks and traitor-sabotaged infrastructure. Thank you for helping keep everyone safe." },
    freeze = { "WHEN A UNIT SAYS FREEZE, YOU FREEZE", "Ignoring authority leads to punishment." },
    molasses = { "RUNNING IS FORBIDDEN", "Only traitors run, and they do not get far." },
    watchers = { "YOU ARE NEVER ALONE", "Even when you close your eyes." },
    -- Propaganda (her dreams)
    adore = { "KNEEL WHEN SHE PASSES", "Your Administrator does so much for the city; it's the least you can do." },
    roses = { "FLOWERS FOR THE ADMINISTRATOR", "She sacrifices herself for you, surely you can spare a single flower?" },
    mirror = { "WHO IS THE FAIREST?", "You already know the answer." },
    saviour = { "SHE WILL COME FOR YOU", "When monsters attack, trust in the Administrator." },
    quiz = { "DO YOU KNOW YOUR ADMINISTRATOR?", "Loyalty is tested and wrong answers are noted." },
    harvest = { "A RECORD HARVEST", "This year's yield exceeds every target, trust Her to count it for you." },
    shift = { "DOUBLE THE QUOTA. DOUBLE THE GLORY.", "Every day the Administrator does the work of fourteen people; what is your excuse?" },
    spy = { "CARELESS TALK COSTS LIVES", "Anyone could be listening, and anyone could be a traitor." },
    newsreel = { "GOOD NEWS", "Tonight's broadcast will show you how double good. Viewing is mandatory." },
    hate = { "TWO PURE MINUTES.", "Love your neighbour, hate the traitor." },
    massgames = { "WE ARE ONE", "We all help the Administrator, and she adorns us with her beauty." },
    guidance = { "WORKPLACE VISITS", "You wouldn't want to disappoint her; keep your workplace efficient and clean." },
    scrap = { "EVERY CAN COUNTS", "Waste not, want not." },
    flowers = { "GREET YOUR LIBERATORS", "They have given their lives to protect you; show your appreciation." },
    duck = { "DUCK AND COVER", "When the siren sounds, so does your training!" },
    ravenholm = { "WE DON'T GO TO RAVENHOLM", "Traitors beware: this is what happens when you threaten our citizens." },
    battleline = { "HOLD THE LINE", "Stand with her soldiers; the traitors are coming." },
}
LC.DreamPosterHints = HINTS

-- A dream without its own lines: its mood's.
local BY_MOOD = {
    happy = { "SLEEP WELL, CITIZEN", "A compliant city dreams sweetly, and tonight may be one of those nights." },
    neutral = { "DREAMS ARE NOT YOUR CONCERN", "If tonight's seems strange, report it in the morning, then forget it." },
    nightmare = { "LOCK YOUR DOOR TONIGHT", "Whatever you see when your eyes are closed is not real, probably." },
    propaganda = { "SHE IS IN YOUR DREAMS", "Your Administrator never rests, not even while you do." },
}
LC.DreamPosterByMood = BY_MOOD

-- The last few dreams the city dreamt (newest last), never a test.
LC.DreamPosterSeen = LC.DreamPosterSeen or {}
hook.Add("LivingCityDreamStarted", "LivingCityDreamPosters", function(dream)
    if not dream or dream.test or not dream.ending then return end
    local seen = LC.DreamPosterSeen
    for i = #seen, 1, -1 do if seen[i] == dream.ending then table.remove(seen, i) end end
    seen[#seen + 1] = dream.ending
    while #seen > 3 do table.remove(seen, 1) end
end)

local function KindOf(id)
    if LC.DreamKind then return LC.DreamKind(id) end
    return LC.DreamMood and LC.DreamMood(id) or "neutral"
end

-- The poster for a dream: heading and body.
function LC.DreamPosterWords(id)
    local h = HINTS[id]
    if h then return h[1], h[2] end
    local m = BY_MOOD[KindOf(id)] or BY_MOOD.neutral
    return m[1], m[2]
end

-- The dream the city would dream tonight, as the day stands (nil: none to dream).
function LC.DreamPosterTonight()
    if not (LC.DreamPlanDecide and LC.DreamPlanNext) then return nil end
    local ok, kind = LC.Try(LC.DreamPlanDecide)
    if not ok or not kind then return nil end
    return LC.DreamPlanNext(kind) or LC.DreamPlanNext("neutral") or LC.DreamPlanNext("happy")
end

-- A whole number from a poster's place and the day, the same all day for that poster.
local function Roll(pos, day, salt)
    local h = math.floor(pos.x) * 73856093 + math.floor(pos.y) * 19349663 + math.floor(pos.z) * 83492791 + (day or 0) * 2654435 + (salt or 0) * 97
    h = h % 1000003
    if h < 0 then h = h + 1000003 end
    return h
end
LC.DreamPosterRoll = Roll

-- Does this poster (one that would show curfew) show a dream today? Its dream codeword, or nil.
function LC.DreamPosterFor(pos)
    local share = cvShare:GetFloat()
    if share <= 0 or not pos then return nil end
    local day = LC.DreamPlanTonight and LC.DreamPlanTonight() or 0
    if (Roll(pos, day, 1) % 1000) / 1000 >= share then return nil end
    local seen = LC.DreamPosterSeen
    if #seen > 0 and Roll(pos, day, 2) % 2 == 0 then
        return seen[(Roll(pos, day, 3) % #seen) + 1]
    end
    return LC.DreamPosterTonight() or seen[#seen]
end

-- A dream's own poster, standing inside the dream (the owner, 14 November): big times a wall
-- poster's size, its picture posters/dream_<art> (the drawn notice with the words without it),
-- the words dream id's. It never changes what it shows and is never one of the city's hung posters.
function LC.DreamBillboard(pos, facing, id, art, big)
    local e = ents.Create("lc_civposter")
    if not IsValid(e) then return nil end
    local head, body = LC.DreamPosterWords(id)
    e.lcDreamProp = true
    e:SetPos(pos)
    e:SetAngles(Angle(0, facing or 0, 0))
    e:Spawn()
    if e.SetModelScale then e:SetModelScale(big or 1) end -- (so it's drawn from as far as it's seen)
    e:SetNW2String("lc_notice", "dream")
    e:SetNW2String("lc_dream_id", art or id)
    e:SetNW2String("lc_dream_head", head)
    e:SetNW2String("lc_dream_body", body)
    e:SetNW2Float("lc_big", big or 1)
    return e
end
