--[[
    Living City: what named people say, recorded (the owner, 11 November: "architect and design natural
    sounding lines so that we can pre record NPC lines and cover as much situational dialogs as possible
    with the least amount of lines")

    A small bank of lines, written to be recorded once and reused everywhere:

      by what the line DOES, not what it is about: a greeting, a refusal, "I don't know", a warning, a
      thanks. "I wouldn't know anything about that." answers a thousand questions.
      nobody's name, job, the time of day or a place in any of them, so any citizen can say any line
      short (a breath or two), so two can be said together: an opener ("Listen.") and then the line
      the same few feelings throughout: warm, plain, guarded, cold

    Who uses them:
      free talk (sv_livingcity_brain.lua): the hosted model is shown the bank and picks the line that
        says what the person would say; it only writes words of its own when none fits (lc_brain_lines)
      the director's approach: the citizen who walks up to a player opens with one
      the minds' breaks (sv_livingcity_mindsact.lua): what they shout, plead or mutter as it happens

    Recordings: a citizen's lines want a man's take and a woman's, in the folder the advice lines already
    use, garrysmod/sound/livingcity/citizens/: say_greet_warm_male1.wav, say_greet_warm_female1.wav (more
    takes ...2, ...3; one is picked at random). A unit's lines are one voice, in
    garrysmod/sound/livingcity/units/: unit_move1.wav (where Half-Life 2 has the line already, its own clip is
    used and nothing needs recording). Without a recording the line is words only (never
    Half-Life 2's voice in its place), and once any are recorded the named citizens of that sex speak ONLY
    with their recorded voice (LC.OwnVoice, below).
    VOICE_LINES.md lists them all (python3 _dev/voice_lines.py); lc_voice_missing says which are not there yet.
]]

LC = LC or {}

-- id = { words, when it is said, the words as pasted into ElevenLabs (Eleven v4 or v3: a direction in square
-- brackets changes how what follows is said) }. Citizens: every id starts say_. American wording (the owner, 11 November).
LC.StreetLines = {
    say_open_listen = { "Listen.", "Opener: before something that matters", "[low, urgent] Listen." },
    say_open_look = { "Look.", "Opener: before a refusal or a plain truth", "[tired, flat] Look." },
    say_open_please = { "Please.", "Opener: before asking, or begging off", "[pleading, quietly] Please." },
    say_open_quiet = { "Keep your voice down.", "Opener: before anything dangerous to say", "[whispers, tense] Keep your voice down." },
    say_open_well = { "Well.", "Opener: thinking it over", "[thinking it over] Well..." },
    say_open_you = { "You.", "Opener: stopping someone", "[sharp, low] You." },
    say_greet_warm = { "Oh, it's you. Good to see a friendly face.", "Greeting someone they like", "[relieved, warm] Oh, it's you. Good to see a friendly face." },
    say_greet_plain = { "Hey. Still here, huh? Me too.", "Greeting anyone", "[tired, dry] Hey. Still here, huh? [exhales] Me too." },
    say_greet_guarded = { "Do I know you?", "Greeting a stranger they are wary of", "[wary, guarded] Do I know you?" },
    say_greet_cold = { "What do you want?", "Greeting someone they dislike", "[cold, flat] What do you want?" },
    say_greet_unit = { "No trouble here, officer.", "Spoken to by a unit", "[nervous, too polite] No trouble here, officer." },
    say_bye_warm = { "Take care of yourself. I mean it.", "Parting from someone they like", "[warm, quietly] Take care of yourself. [sincere] I mean it." },
    say_bye_plain = { "I should get going.", "Ending a conversation", "[flat, tired] I should get going." },
    say_bye_cold = { "We're done here.", "Ending a conversation they want no more of", "[cold, final] We're done here." },
    say_yes = { "Yeah. All right.", "Agreeing to something", "[plain, tired] Yeah. All right." },
    say_yes_warm = { "For you? Of course.", "Agreeing, for someone they like", "[warm, a small smile] For you? Of course." },
    say_no = { "Sorry, but no.", "Refusing", "[flat, apologetic] Sorry, but no." },
    say_no_hard = { "No. And don't ask me again.", "Refusing for good", "[firm, low] No. [pause] And don't ask me again." },
    say_maybe = { "Maybe. I'd have to think about it.", "Not sure", "[hesitant] Maybe. I'd have to think about it." },
    say_later = { "Not now. Not here.", "Putting it off: the wrong time or place", "[hushed, tense] Not now. Not here." },
    say_dunno = { "I wouldn't know anything about that.", "Asked something they don't know, or won't say", "[guarded, flat] I wouldn't know anything about that." },
    say_dunno_scared = { "I don't know, and I don't want to know.", "Asked something dangerous", "[frightened, quick] I don't know, and I don't want to know." },
    say_heard = { "I've heard things. Everyone has.", "Asked about a rumour", "[low, careful] I've heard things. [pause] Everyone has." },
    say_cant_say = { "I can't talk about that. You know why.", "Asked what can't be said aloud", "[hushed, uneasy] I can't talk about that. You know why." },
    say_ask_else = { "You're asking the wrong person.", "Asked for something they can't give", "[tired, dismissive] You're asking the wrong person." },
    say_truth = { "Honestly? It's as bad as it looks.", "Asked how things are, by someone they trust", "[quiet, grim] Honestly? [sighs] It's as bad as it looks." },
    say_state_fine = { "Getting by. That's all I can do.", "Asked how they are: all right", "[worn, matter of fact] Getting by. That's all I can do." },
    say_state_hungry = { "I haven't had a real meal in days.", "Asked how they are: hungry", "[weak, hollow] I haven't had a real meal in days." },
    say_state_tired = { "I'm tired. Just so tired.", "Asked how they are: worn out", "[exhausted] I'm tired. [sighs] Just so tired." },
    say_state_scared = { "I'm scared. Aren't you?", "Asked how they are: afraid", "[frightened, hushed] I'm scared. Aren't you?" },
    say_state_angry = { "I've had about all I can take.", "Asked how they are: close to breaking", "[tight, barely holding it in] I've had about all I can take." },
    say_state_lonely = { "It's good to just talk to someone.", "Asked how they are: starved of company", "[soft, grateful] It's good to just talk to someone." },
    say_state_hopeful = { "It can't last forever. Nothing ever does.", "Asked how they are: in good spirits", "[quiet, hopeful] It can't last forever. Nothing ever does." },
    say_state_low = { "What's the point? Really, what is the point?", "Asked how they are: in despair", "[hollow, defeated] What's the point? [pause] Really, what is the point?" },
    say_thanks = { "Thank you. I won't forget it.", "Thanked for a kindness", "[sincere, quietly] Thank you. I won't forget it." },
    say_thanks_big = { "You didn't have to do that. Thank you.", "A real kindness: food, medicine, help", "[moved, voice catching] You didn't have to do that. Thank you." },
    say_sorry = { "I'm sorry. I didn't mean anything by it.", "Backing down", "[nervous, backing down] I'm sorry. I didn't mean anything by it." },
    say_insulted = { "Hey. There's no need for that.", "Insulted", "[stung, stiff] Hey. There's no need for that." },
    say_threatened = { "I don't want any trouble.", "Threatened", "[frightened, hands up] I don't want any trouble." },
    say_laugh = { "Ha. That's the first laugh I've had all week.", "Something funny was said", "[short laugh] Ha. [warm, surprised] That's the first laugh I've had all week." },
    say_agree = { "You're not wrong.", "Agreeing with an opinion", "[dry, low] You're not wrong." },
    say_disagree = { "Well, I don't see it that way.", "Disagreeing with an opinion", "[even, firm] Well, I don't see it that way." },
    say_loyal = { "The Administrator knows best. Everyone knows that!", "A loyal citizen, on the Combine", "[earnest, a little rehearsed] The Administrator knows best. Everyone knows that!" },
    say_loyal_warn = { "You shouldn't say things like that. Someone will hear.", "Hearing sedition, and not liking it", "[alarmed, hushed] You shouldn't say things like that. Someone will hear." },
    say_careful = { "Careful. The walls have ears.", "Warning someone who is talking too freely", "[whispers] Careful. The walls have ears." },
    say_units_near = { "Not with them standing right there.", "Won't talk with a unit close", "[under their breath] Not with them standing right there." },
    say_hate_quiet = { "One day they'll answer for all of it.", "A disloyal citizen, to someone they trust", "[low, bitter, controlled] One day they'll answer for all of it." },
    say_fear_units = { "Stay away from the units today. They're in a mood.", "A warning about Civil Protection", "[low, warning] Stay away from the units today. They're in a mood." },
    say_obey = { "Keep your head down and do what they say. That's how you make it.", "Advice to a newcomer", "[tired, kindly] Keep your head down and do what they say. That's how you make it." },
    say_res_deny = { "I don't know anything about any Resistance.", "Asked about the Resistance", "[quick, stiff, too careful] I don't know anything about any Resistance." },
    say_res_hint = { "There are people. That's all I'll say.", "A sympathizer, hinting to someone they trust", "[whispers, meaningful] There are people. [pause] That's all I'll say." },
    say_res_side = { "If someone needed a door left open, mine would be.", "A sympathizer, offering help", "[very quietly, steady] If someone needed a door left open, mine would be." },
    say_res_refuse = { "I've got people to think about. Leave me out of it.", "Asked to help the Resistance, and afraid", "[afraid, firm] I've got people to think about. Leave me out of it." },
    say_res_respect = { "Whoever they are, good luck to them.", "Quiet approval of the Resistance", "[quiet, a hint of a smile] Whoever they are, good luck to them." },
    say_warn_asked = { "Someone's been asking about you.", "A warning: they are being looked for", "[low, urgent] Someone's been asking about you." },
    say_warn_watched = { "You're being watched. Don't look now and don't turn around.", "A warning: an informant or a unit has an eye on them", "[whispers, barely moving lips] You're being watched. Don't look now and don't turn around." },
    say_warn_go = { "You should go. Now.", "A warning: get away", "[urgent, hushed] You should go. Now." },
    say_warn_informer = { "Watch who you talk to. Not everyone here is a friend.", "A warning about informants", "[low, careful] Watch who you talk to. Not everyone here is a friend." },
    say_tip_help = { "If you need something, ask. Quietly.", "Offering help", "[low, kind] If you need something, ask. [whispers] Quietly." },
    say_tip_trouble = { "There's gonna be trouble tonight. I can feel it.", "The city's mood is turning", "[uneasy, low] There's gonna be trouble tonight. I can feel it." },
    say_ask_food = { "You got anything to eat? Anything?", "Hungry, asking a player", "[weak, ashamed to ask] You got anything to eat? [pause] Anything?" },
    say_ask_smoke = { "You wouldn't have a smoke on you, would you?", "Craving, asking a player", "[edgy, hopeful] You wouldn't have a smoke on you, would you?" },
    say_ask_help = { "I need help. I've got nobody else to ask.", "In trouble, asking a player", "[desperate, quietly] I need help. I've got nobody else to ask." },
    say_offer = { "Here. Take it. Don't say where you got it.", "Giving something", "[hushed, quick] Here. Take it. Don't say where you got it." },
    say_decline_gift = { "I can't take that. Keep it.", "Refusing a gift", "[gentle, proud] I can't take that. Keep it." },
    say_break_tantrum = { "I've had enough! Do you hear me? Enough!", "A tantrum, in a unit's face", "[shouting, voice cracking] I've had enough! Do you hear me? Enough!" },
    say_break_despair = { "I can't. I just can't anymore.", "Despair", "[broken, near tears] I can't. [shaky breath] I just can't anymore." },
    say_break_defy = { "They can't scare all of us forever.", "Defiance: painting over a poster", "[quiet, defiant, steady] They can't scare all of us forever." },
    say_break_accuse = { "That one! That one talks to Civil Protection!", "Accusing someone of informing", "[loud, accusing, pointing] That one! That one talks to Civil Protection!" },
    say_break_accused = { "That's a lie! I never told them anything!", "Accused of informing", "[panicked, loud] That's a lie! I never told them anything!" },
    say_break_binge = { "Leave me alone. Just let me have this.", "Drinking in the street", "[slurred, tired, bitter] Leave me alone. Just let me have this." },
    say_break_seek = { "There you are. I've been looking for you.", "Finding a friend", "[relieved, a little shaky] There you are. I've been looking for you." },
    say_break_share = { "Go on, take half. You need it more than I do.", "Sharing food", "[gentle, insisting] Go on, take half. You need it more than I do." },
    say_break_steady = { "Easy. Easy now. We're going to be ok, right?", "Steadying the people near", "[calm, soothing, low] Easy. Easy now. We're going to be ok, right?" },
    say_break_inform = { "Officer. I've got something you'll want to hear.", "Informing to a unit", "[nervous, eager, hushed] Officer. I've got something you'll want to hear." },
    say_break_beaten = { "Stop! Please, I didn't do anything!", "Being beaten", "[crying out in pain, terrified] Stop! Please, I didn't do anything!" },
    say_saw_beating = { "Don't look. Just keep walking.", "Someone beaten in front of them", "[under their breath, tense] Don't look. Just keep walking." },
    say_saw_death = { "Oh God. Oh God, no.", "Someone killed in front of them", "[horrified, gasping] Oh God. Oh God, no." },
    say_grief = { "They took my friend. Just dragged them off.", "A friend arrested or dead", "[numb, grieving] They took my friend. [pause] Just dragged them off." },
}

-- A unit's lines: one voice. Every id starts unit_. A fourth entry names Half-Life 2's own Civil Protection
-- clips that say the same words (sound/npc/metropolice/vo/<name>.wav): with no recording of yours, the first
-- of them the server has is played, so those lines need no recording at all (the owner, 11 November: "already
-- exist in HL2").
LC.UnitLines = {
    unit_greet = { "Citizen.", "Spoken to", "[flat, clipped, cold] Citizen.", { "citizen" } },
    unit_greet_cp = { "Copy.", "Spoken to by another unit", "[flat, clipped, cold] Copy.", { "copy" } },
    unit_move = { "Move along.", "Wants them gone", "[flat, clipped, cold] Move along.", { "movealong", "keepmoving" } },
    unit_move_hard = { "Move it.", "Wants them gone, losing patience", "[flat, clipped, cold] Move it.", { "moveit", "moveit2" } },
    unit_papers = { "Don't move.", "Suspicious of them", "[flat, clipped, cold] Don't move.", { "dontmove", "holdit" } },
    unit_yes = { "Affirmative.", "Agreeing", "[flat, clipped, cold] Affirmative.", { "affirmative", "affirmative2" } },
    unit_no = { "Get out of here.", "Refusing", "[flat, clipped, cold] Get out of here.", { "getoutofhere" } },
    unit_dunno = { "Keep moving.", "Asked anything he won't answer", "[flat, clipped, cold] Keep moving.", { "keepmoving", "movealong" } },
    unit_busy = { "Now get out of here.", "Ending it", "[flat, clipped, cold] Now get out of here.", { "nowgetoutofhere" } },
    unit_curfew = { "Vacate, citizen.", "Curfew, a lockdown or a sweep", "[flat, clipped, cold] Vacate, citizen.", { "vacatecitizen" } },
    unit_warn_first = { "First warning: move away.", "A first warning", "[flat, clipped, cold] First warning: move away.", { "firstwarningmove" } },
    unit_warn_second = { "This is your second warning.", "A second warning", "[flat, clipped, cold] This is your second warning.", { "thisisyoursecondwarning", "secondwarning" } },
    unit_warn = { "Final warning.", "Pushed too far", "[flat, clipped, cold] Final warning.", { "finalwarning" } },
    unit_threat = { "Move back, right now.", "Threatened or crowded", "[flat, clipped, cold] Move back, right now.", { "movebackrightnow", "holditrightthere" } },
    unit_insulted = { "Looking for trouble?", "Insulted", "[flat, clipped, cold] Looking for trouble?", { "lookingfortrouble" } },
    unit_verdict = { "You want a malcompliance verdict?", "Insulted again, or defied", "[flat, clipped, cold] You want a malcompliance verdict?", { "youwantamalcomplianceverdict" } },
    unit_noted = { "Issuing malcompliant citation.", "Heard something he will report", "[flat, clipped, cold] Issuing malcompliant citation.", { "issuingmalcompliantcitation" } },
    unit_thanks = { "Roger that.", "Told something useful, or obeyed", "[flat, clipped, cold] Roger that.", { "rodgerthat", "ten4" } },
    unit_soft = { "All right, you can go.", "A unit with some kindness in him, to someone he doesn't mind", "[flat, clipped, cold] All right, you can go.", { "allrightyoucango" } },
    unit_brutal = { "Prepare for judgment.", "Brutality: to whoever is watching", "[flat, clipped, cold] Prepare for judgment.", { "prepareforjudgement" } },
    unit_drink = { "Watch it.", "Caught drinking on duty", "[flat, clipped, cold] Watch it.", { "watchit" } },
}


-- Half-Life 2's own citizens (the owner, 11 November: "if the NPCs personality lines up with the available default HL2
-- voice lines, then they could be used, and then save other NPCs for the custom voice lines"). The clips a named
-- person who keeps Half-Life 2's voice can say: id = { words, when, the clip's name in sound/vo/npc/male01 and
-- female01 }. The words are the game's own captions, from the owner's server (_dev/tools/hl2_lines.txt). Nothing
-- here needs recording. Left out: everything about Freeman, fighting, medkits by name, vortigaunts.
LC.HL2Lines = {
    hl_hi01 = { "Hi.", "Greeting anyone", "hi01" },
    hl_hi02 = { "Hi.", "Greeting anyone, brighter", "hi02" },
    hl_waitingsomebody = { "You waiting for somebody?", "Greeting a stranger, wary", "waitingsomebody" },
    hl_busy02 = { "Can't you see I'm busy?", "Greeting someone they dislike, or brushed off", "busy02" },
    hl_excuseme01 = { "Excuse me.", "Getting someone's attention, or getting past", "excuseme01" },
    hl_pardonme01 = { "Pardon me.", "Polite, backing off", "pardonme01" },
    hl_illstayhere01 = { "I'll stay here.", "Ending it: they are not going anywhere", "illstayhere01" },
    hl_littlecorner01 = { "I've got my little corner and I'm sticking to it.", "Refusing to get involved", "littlecorner01" },
    hl_outofyourway02 = { "Let me get out of your way.", "Parting, or giving way", "outofyourway02" },
    hl_leadtheway02 = { "Lead the way.", "Agreeing to follow", "leadtheway02" },
    hl_ok01 = { "Okay.", "Agreeing", "ok01" },
    hl_ok02 = { "Okay!", "Agreeing gladly", "ok02" },
    hl_yougotit02 = { "You got it.", "Agreeing to do something", "yougotit02" },
    hl_squad_affirm03 = { "Whatever you say.", "Agreeing without liking it", "squad_affirm03" },
    hl_answer32 = { "Right on.", "Approving", "answer32" },
    hl_answer13 = { "I'm with you.", "Taking their side", "answer13" },
    hl_readywhenyouare01 = { "Ready when you are.", "Willing", "readywhenyouare01" },
    hl_fantastic01 = { "Fantastic!", "Delighted", "fantastic01" },
    hl_finally = { "Finally!", "Relief at something long awaited", "finally" },
    hl_yeah02 = { "Yeah!", "Cheering", "yeah02" },
    hl_thislldonicely01 = { "This'll do nicely.", "Given something", "thislldonicely01" },
    hl_no01 = { "No!", "Refusing, or denying it", "no01" },
    hl_no02 = { "No!", "Refusing loudly; a shout of protest", "no02" },
    hl_answer38 = { "Leave it alone.", "Refusing to talk about it", "answer38" },
    hl_answer39 = { "That's enough outta you.", "Shutting someone up", "answer39" },
    hl_answer05 = { "Could we talk about this later?", "Putting it off: the wrong time or place", "answer05" },
    hl_answer22 = { "You never know.", "Not sure", "answer22" },
    hl_answer23 = { "Never can tell.", "Not sure, a shrug", "answer23" },
    hl_answer24 = { "Why are you telling me?", "Asked or told something that is not their business", "answer24" },
    hl_answer29 = { "What am I supposed to do about it?", "Asked for something they can't give", "answer29" },
    hl_answer26 = { "That's more information than I require.", "Told too much", "answer26" },
    hl_answer37 = { "You sure about that?", "Doubting", "answer37" },
    hl_answer21 = { "Don't be so sure of that.", "Disagreeing", "answer21" },
    hl_answer15 = { "That's one way of looking at it.", "Disagreeing politely", "answer15" },
    hl_answer25 = { "How about that?", "Mild surprise", "answer25" },
    hl_answer27 = { "Wanna bet?", "Defiant doubt", "answer27" },
    hl_answer07 = { "Same here.", "Agreeing with how they feel", "answer07" },
    hl_answer08 = { "Know what you mean.", "Sympathy", "answer08" },
    hl_answer14 = { "You and me both.", "Sharing a complaint", "answer14" },
    hl_answer33 = { "No argument there.", "Agreeing with an opinion", "answer33" },
    hl_answer03 = { "Figures.", "Unsurprised by bad news", "answer03" },
    hl_answer36 = { "Wouldn't be the first time.", "Unsurprised", "answer36" },
    hl_answer40 = { "There's a first time for everything.", "Wry", "answer40" },
    hl_answer04 = { "Try not to dwell on it.", "Comforting", "answer04" },
    hl_answer35 = { "Try not to let it get to you.", "Comforting, steadying", "answer35" },
    hl_answer02 = { "I won't hold it against you.", "Forgiving", "answer02" },
    hl_answer12 = { "Doesn't bear thinking about.", "Something terrible was mentioned", "answer12" },
    hl_answer10 = { "I wouldn't say that too loud.", "Warning someone who is talking too freely", "answer10" },
    hl_answer31 = { "You should nip that kind of talk in the bud.", "Hearing sedition, and not liking it", "answer31" },
    hl_answer19 = { "Keep your mind on your work.", "A loyal citizen's advice", "answer19" },
    hl_answer18 = { "Let's concentrate on the task at hand.", "Changing the subject", "answer18" },
    hl_answer16 = { "Have you ever had an original thought?", "Insulting back", "answer16" },
    hl_answer30 = { "You talking to me?", "Bristling", "answer30" },
    hl_answer09 = { "You're talking to yourself again.", "Teasing", "answer09" },
    hl_answer17 = { "I'm not even gonna tell you to shut up.", "Exasperated", "answer17" },
    hl_answer01 = { "That's you all over.", "Teasing a friend", "answer01" },
    hl_answer28 = { "I wish I had a dime for every time somebody said that.", "Heard it all before", "answer28" },
    hl_watchwhat = { "Watch what you're doing.", "Jostled or threatened", "watchwhat" },
    hl_vquestion01 = { "Stop looking at me like that.", "Uneasy at being stared at", "vquestion01" },
    hl_notthemanithought01 = { "You're not the man I thought you were.", "Let down by someone", "notthemanithought01" },
    hl_wetrustedyou01 = { "We trusted you.", "Betrayed, quietly", "wetrustedyou01" },
    hl_wetrustedyou02 = { "We trusted you!", "Betrayed, accusing out loud", "wetrustedyou02" },
    hl_heretohelp01 = { "We thought you were here to help.", "Let down, reproachful", "heretohelp01" },
    hl_sorry01 = { "Sorry.", "Backing down", "sorry01" },
    hl_whoops01 = { "Whoops.", "A small mistake", "whoops01" },
    hl_question28 = { "God I'm hungry.", "How they are: hungry", "question28" },
    hl_question09 = { "I could eat a horse, hooves and all.", "How they are: hungry, joking", "question09" },
    hl_question19 = { "I can't remember the last time I had a shower.", "How they are: worn and dirty", "question19" },
    hl_question31 = { "I can't remember the last time I had, well, anything.", "How they are: going without", "question31" },
    hl_question27 = { "I think I ate something bad.", "How they are: unwell", "question27" },
    hl_question25 = { "I just knew it was gonna be one of those days.", "How they are: a bad day", "question25" },
    hl_question12 = { "Looks to me like things are getting worse, not better.", "Asked how things are", "question12" },
    hl_question21 = { "I'm not a betting man, but the odds are not good.", "Asked how things will go", "question21" },
    hl_question01 = { "I don't think this war's ever gonna end.", "Gloom about the occupation", "question01" },
    hl_question18 = { "I don't feel anything anymore.", "How they are: numb", "question18" },
    hl_question03 = { "I don't dream anymore.", "How they are: worn down", "question03" },
    hl_question22 = { "Doesn't anyone care what I think?", "Ignored, aggrieved", "question22" },
    hl_question20 = { "Some day this will all be a bad memory.", "How they are: hopeful", "question20" },
    hl_question16 = { "Finally, change is in the air!", "Hope, to someone they trust", "question16" },
    hl_question17 = { "Do you feel it? I feel it!", "Excited hope", "question17" },
    hl_question15 = { "They're never gonna make a stalker out of me.", "Defiance", "question15" },
    hl_question26 = { "This is bullshit!", "Losing their temper", "question26" },
    hl_doingsomething = { "Shouldn't we be doing something?", "Restless, wanting to act", "doingsomething" },
    hl_gordead_ans11 = { "What's the use?", "Despair", "gordead_ans11" },
    hl_gordead_ans12 = { "What's the point?", "Despair", "gordead_ans12" },
    hl_gordead_ans13 = { "Why go on?", "Despair", "gordead_ans13" },
    hl_gordead_ans14 = { "We're done for.", "Despair, or fear", "gordead_ans14" },
    hl_gordead_ques10 = { "This is bad.", "Seeing trouble", "gordead_ques10" },
    hl_gordead_ques06 = { "This can't be!", "Shock", "gordead_ques06" },
    hl_gordead_ques14 = { "It's not supposed to end like this.", "Grief", "gordead_ques14" },
    hl_gordead_ans04 = { "Oh, God!", "Horror", "gordead_ans04" },
    hl_goodgod = { "Good god!", "Horror at what they see", "goodgod" },
    hl_ohno = { "Oh no!", "Dismay", "ohno" },
    hl_uhoh = { "Uh-oh.", "Trouble coming", "uhoh" },
    hl_gordead_ans10 = { "Spread the word.", "Passing on news or a warning", "gordead_ans10" },
    hl_civilprotection01 = { "Civil Protection!", "Warning that units are coming", "civilprotection01" },
    hl_cps01 = { "CPs!", "Warning that units are coming, hissed", "cps01" },
    hl_scanners01 = { "Scanners!", "Warning of a scanner", "scanners01" },
    hl_watchout = { "Watch out!", "A warning", "watchout" },
    hl_headsup01 = { "Heads up!", "A warning", "headsup01" },
    hl_gethellout = { "Get the hell out of here!", "A warning: get away", "gethellout" },
    hl_runforyourlife01 = { "Run for your life!", "Panic", "runforyourlife01" },
    hl_help01 = { "Help!", "Crying for help", "help01" },
    hl_overhere01 = { "Hey, over here!", "Calling someone over", "overhere01" },
    hl_squad_away03 = { "Follow me.", "Leading someone", "squad_away03" },
    hl_health05 = { "Here, patch yourself up.", "Giving something to someone hurt", "health05" },
    hl_squad_reinforce_single04 = { "Wait for me.", "Catching up with a friend", "squad_reinforce_single04" },
}

-- What someone with Half-Life 2's voice says in place of a line of the recorded bank (the minds' breaks, mostly).
LC.HL2Instead = { say_break_tantrum = "hl_question26", say_break_despair = "hl_gordead_ans12", say_break_defy = "hl_question15",
    say_break_accuse = "hl_wetrustedyou02", say_break_accused = "hl_no01", say_break_binge = "hl_answer38", say_break_seek = "hl_finally",
    say_break_share = "hl_health05", say_break_steady = "hl_answer35", say_break_inform = "hl_excuseme01", say_break_beaten = "hl_help01",
    say_saw_beating = "hl_answer12", say_saw_death = "hl_goodgod", say_grief = "hl_gordead_ques14", say_dunno = "hl_answer24",
    say_warn_asked = "hl_gordead_ans10", say_warn_watched = "hl_cps01", say_warn_go = "hl_gethellout", say_warn_informer = "hl_answer10",
    say_careful = "hl_answer10", say_greet_plain = "hl_hi01", say_greet_warm = "hl_hi02", say_greet_guarded = "hl_waitingsomebody",
    say_greet_cold = "hl_busy02", say_state_hungry = "hl_question28", say_state_low = "hl_gordead_ans11", say_state_hopeful = "hl_question20",
    say_tip_trouble = "hl_gordead_ques10", say_thanks = "hl_thislldonicely01", say_sorry = "hl_sorry01", say_no = "hl_no01", say_yes = "hl_ok01" }

LC.UnitVoiceRoot = "livingcity/units/"

local AUDIO = { wav = true, mp3 = true, ogg = true }
local unitClips
local function ScanUnits()
    unitClips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.UnitVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            unitClips[base] = unitClips[base] or {}
            table.insert(unitClips[base], LC.UnitVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.UnitVoiceRoot .. n) end
        end
    end
    return unitClips
end
LC.UnitLinesRescan = ScanUnits
hook.Add("Initialize", "LivingCityUnitLines", ScanUnits)

-- Half-Life 2's own clip for a unit's line, if the server has one of those named for it.
local STOCK_ROOT = "npc/metropolice/vo/"
local stockHas = {}
function LC.UnitLineStock(id)
    local l = LC.UnitLines[id]
    for _, name in ipairs(l and l[4] or {}) do
        if stockHas[name] == nil then stockHas[name] = file.Exists("sound/" .. STOCK_ROOT .. name .. ".wav", "GAME") == true end
        if stockHas[name] then return STOCK_ROOT .. name .. ".wav" end
    end
    return nil
end
function LC.UnitLinesForgetStock() stockHas = {} end

-- Your recording of it; else Half-Life 2's own, where it has one.
function LC.UnitLineClip(id, ownOnly)
    if not unitClips then ScanUnits() end
    local t = unitClips[id]
    if t then return t[math.random(#t)] end
    if ownOnly then return nil end
    return LC.UnitLineStock(id)
end

-- Three banks: "cop" a unit's, "hl2" Half-Life 2's own citizen clips, anything else the recorded bank.
local function Bank(role) return (role == "cop" and LC.UnitLines) or (role == "hl2" and LC.HL2Lines) or LC.StreetLines end

-- Two voices by personality. A named citizen keeps Half-Life 2's voice ("hl2") or has the recorded one ("own"),
-- for life, from who they are: the lively, sociable, hopeful and bold sound like Half-Life 2's citizens; the
-- despairing, timid, withdrawn do not. Until the recorded bank exists for their sex everyone has Half-Life 2's.
-- lc_voice_split 0: no split (every named citizen takes the recorded voice once it exists, as before).
local cvSplit = CreateConVar("lc_voice_split", "1", FCVAR_ARCHIVE, "Named citizens keep Half-Life 2's voice or get the recorded one by personality (0: all of them the recorded one, once it is recorded)")
function LC.VoiceOf(npc, st)
    if LC.VoiceForce then return LC.VoiceForce end -- (the tests)
    if not IsValid(npc) or not st or st.role ~= "citizen" then return "hl2" end
    local p = npc.lcProfile
    if not p or not p.name then return "hl2" end
    if not (LC.AdviceHasAny and LC.AdviceHasAny("say_", st.gender)) then return "hl2" end
    if not cvSplit:GetBool() then return "own" end
    if p.lcVoice == nil then
        local m = LC.Psy and LC.MindOf and LC.MindOf(p)
        local tr = m and LC.Psy.Traits(m)
        p.lcVoice = (not tr or (tr.social + tr.hope + 0.5 * tr.brave) >= 0) and "hl2" or "own"
    end
    return p.lcVoice
end

-- Which bank a person speaks from: "cop", "hl2" or "citizen" (the recorded one).
function LC.LineKey(npc, st)
    if st and st.role == "cop" then return "cop" end
    return LC.VoiceOf(npc, st) == "own" and "citizen" or "hl2"
end

-- Is this a line this kind of person has? opener: only an opener counts.
function LC.LineValid(role, id, opener)
    if type(id) ~= "string" or id == "" then return false end
    if not Bank(role)[id] then return false end
    local isOpener = string.sub(id, 1, 9) == "say_open_"
    if opener then return isOpener end
    return not isOpener
end

function LC.LineWords(role, id, lead)
    local l = Bank(role)[id]
    if not l then return "" end
    local o = lead and LC.StreetLines[lead]
    return (o and (o[1] .. " ") or "") .. l[1]
end

-- The ids a kind of person has, in order: for the model's list. openers: only those, or (false) none of them.
function LC.LineIds(role, openers)
    local out = {}
    for id in pairs(Bank(role)) do
        local isOpener = string.sub(id, 1, 9) == "say_open_"
        if (openers and isOpener) or (not openers and not isOpener) then out[#out + 1] = id end
    end
    table.sort(out)
    return out
end

-- The bank as the model reads it: "id: words (when)".
function LC.LineList(role, only)
    local out = {}
    for _, id in ipairs(LC.LineIds(role, false)) do
        if not only or only(id) then
            local l = Bank(role)[id]
            out[#out + 1] = id .. ": " .. l[1] .. " (" .. l[2] .. ")"
        end
    end
    return table.concat(out, "\n")
end

local function Clip(st, id)
    if st.role == "cop" then return LC.UnitLineClip(id) end
    local h = LC.HL2Lines[id]
    if h then return "vo/npc/" .. (st.gender == "female" and "female01" or "male01") .. "/" .. h[3] .. ".wav" end
    return LC.AdviceClip and LC.AdviceClip(id, st.gender) or nil
end

local function Emit(npc, st, id)
    local clip = Clip(st, id)
    if clip then
        npc:EmitSound(clip, 72)
        return (LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(clip)) or 0
    end
    return 0 -- (not recorded yet: the words only, never Half-Life 2's voice in its place)
end

-- One voice for each named person (the owner, 11 November). Once any of the bank is recorded for men (or for
-- women), the city's NAMED citizens of that sex stop speaking with Half-Life 2's citizen voice wherever the
-- gamemode chooses the sound (street chatter, the talk window, protests, under words the model wrote): the
-- words still show, and their recorded lines are their only voice. Unnamed citizens keep Half-Life 2's.
function LC.OwnVoice(npc, st, path)
    if not IsValid(npc) or not st or st.role ~= "citizen" then return false end
    if path and LC.VoiceReplacement and LC.VoiceReplacement(path) then return false end -- (that very clip has been re-recorded: it is their voice)
    local p = npc.lcProfile
    if not p or not p.name then return false end
    return LC.VoiceOf(npc, st) == "own" -- (those who keep Half-Life 2's voice go on using it)
end

-- They say it out loud (the sound only: whoever calls shows the words). lead: an opener first.
-- Returns the words.
function LC.LineSay(npc, st, id, lead)
    if not IsValid(npc) or not st then return "" end
    local key = LC.LineKey(npc, st)
    if key == "hl2" and not LC.HL2Lines[id] then id, lead = LC.HL2Instead[id], nil end -- (their own way of saying it, or nothing)
    if not id or not Bank(key)[id] then return "" end
    if lead and st.role ~= "cop" and LC.StreetLines[lead] then
        local secs = Emit(npc, st, lead)
        timer.Simple((secs > 0 and secs or 0.8) + 0.15, function()
            if IsValid(npc) and npc:Health() > 0 then Emit(npc, st, id) end
        end)
    else
        lead = nil
        Emit(npc, st, id)
    end
    return LC.LineWords(key, id, lead)
end

-- For lc_voice_missing (sv_livingcity_announcer.lua): the recordings not there yet.
function LC.LinesMissing()
    local cit, unit = {}, {}
    if LC.AdviceRescan then LC.AdviceRescan() end
    for id in pairs(LC.StreetLines) do
        for _, gen in ipairs({ "male", "female" }) do
            if not (LC.AdviceClip and LC.AdviceClip(id, gen)) then cit[#cit + 1] = id .. "_" .. gen end
        end
    end
    ScanUnits()
    for id in pairs(LC.UnitLines) do if not LC.UnitLineClip(id) then unit[#unit + 1] = id end end -- (Half-Life 2's own clip counts)
    table.sort(cit) table.sort(unit)
    return cit, unit
end

-- What Half-Life 2 already has (the owner, 11 November: "please double check if there are others"): lc_hl2_lines,
-- in the server console, writes data/livingcity/hl2_lines.txt: every clip of Half-Life 2's citizens (a man's and
-- a woman's) and of Civil Protection that the server can see, with its words where the game's caption file gives
-- them. Bring the file back and the bank can be matched to real clips for certain, instead of from memory.
function LC.HL2LinesDump()
    local out, n = {}, 0
    local words = {}
    for _, cc in ipairs({ "resource/closecaption_english.txt", "resource/subtitles_english.txt" }) do
        local raw = file.Read(cc, "GAME")
        if raw then
            raw = string.gsub(raw, "%z", "") -- (the file is two bytes a letter: drop the empty ones)
            for token, text in string.gmatch(raw, '"([%w_%.]+)"%s+"([^"\r\n]*)"') do
                local key = string.lower(token)
                if words[key] == nil then words[key] = (string.gsub(text, "<[^>]*>", "")) end
            end
        end
    end
    local function Folder(title, path, tokens)
        out[#out + 1] = "## " .. title .. " (sound/" .. path .. ")"
        local files = file.Find("sound/" .. path .. "*.wav", "GAME") or {}
        table.sort(files)
        for _, f in ipairs(files) do
            local base = string.lower(string.gsub(f, "%.wav$", ""))
            local text
            for _, pre in ipairs(tokens) do text = text or words[pre .. base] end
            out[#out + 1] = f .. "\t" .. (text or "")
            n = n + 1
        end
        out[#out + 1] = ""
    end
    Folder("A citizen, a man", "vo/npc/male01/", { "npc_citizen.", "citizen." })
    Folder("A citizen, a woman", "vo/npc/female01/", { "npc_citizen.", "citizen." })
    Folder("Civil Protection", "npc/metropolice/vo/", { "npc_metropolice.", "metropolice." })
    Folder("Overwatch soldiers", "npc/combine_soldier/vo/", { "npc_combine.", "combine_soldier.", "npc_combine_soldier." })
    Folder("Overwatch, the city's voice", "npc/overwatch/cityvoice/", { "npc_overwatch.", "overwatch." })
    Folder("Overwatch, on the radio", "npc/overwatch/radiovoice/", { "npc_overwatch.", "overwatch." })
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write("livingcity/hl2_lines.txt", table.concat(out, "\n"))
    return n
end
concommand.Add("lc_hl2_lines", function(ply)
    if IsValid(ply) and not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local ok, n = pcall(LC.HL2LinesDump)
    local msg = ok and ("wrote data/livingcity/hl2_lines.txt: " .. tostring(n) .. " clips. Bring it back to Claude.") or ("could not list them: " .. tostring(n))
    if IsValid(ply) then ply:ChatPrint("[Miscount] " .. msg) else print("[Miscount] " .. msg) end
end)

------------------------------------------------------------------------
-- Half-Life 2's own lines, replaced one by one (the owner, 11 November: "We are going to slowly replace all
-- the HL2 native voice lines with my custom generated ones, EXCEPT for Gman")
------------------------------------------------------------------------
-- A recording at garrysmod/sound/livingcity/hl2/<the clip's own path> takes the place of that Half-Life 2
-- clip wherever it is played, by the gamemode or by the game itself: sound/livingcity/hl2/vo/npc/male01/hi01.mp3
-- is heard instead of sound/vo/npc/male01/hi01.wav. No list to keep: a file being there is the whole of it,
-- so they can be added a few at a time. A clip with no replacement plays as it always did.
-- Only in these folders, and never the G-Man's.
local cvReplace = CreateConVar("lc_voice_replace", "1", FCVAR_ARCHIVE, "Half-Life 2's own voice clips are replaced by your recordings of them in sound/livingcity/hl2/ (a clip with none plays as before)")
LC.VoiceReplaceRoot = "livingcity/hl2/"
LC.VoiceReplaceFolders = { "vo/npc/male01/", "vo/npc/female01/", "npc/metropolice/vo/", "npc/combine_soldier/vo/", "npc/overwatch/cityvoice/", "npc/overwatch/radiovoice/" }

local replaced -- [clip path without its ending] = the recording's path
local function ScanReplaced()
    replaced = {}
    local n = 0
    for _, folder in ipairs(LC.VoiceReplaceFolders) do
        for _, f in ipairs(file.Find("sound/" .. LC.VoiceReplaceRoot .. folder .. "*", "GAME") or {}) do
            local base, ext = string.match(string.lower(f), "^(.-)%.(%w+)$")
            if base and AUDIO[ext] then
                local path = LC.VoiceReplaceRoot .. folder .. f
                replaced[folder .. base] = path
                n = n + 1
                if resource and resource.AddFile then resource.AddFile("sound/" .. path) end
                if util and util.PrecacheSound then util.PrecacheSound(path) end
            end
        end
    end
    LC.VoiceReplacedCount = n
    return n
end
LC.VoiceReplaceRescan = ScanReplaced
hook.Add("Initialize", "LivingCityVoiceReplace", ScanReplaced)

-- Your recording of a Half-Life 2 clip, or nil. path: as the game names it ("vo/npc/male01/hi01.wav").
function LC.VoiceReplacement(path)
    if not cvReplace:GetBool() or type(path) ~= "string" then return nil end
    if not replaced then ScanReplaced() end
    local p = string.lower(path)
    p = string.gsub(p, "^[^%w]+", "")   -- (the game puts marks in front of some names)
    p = string.gsub(p, "^sound/", "")
    p = string.gsub(p, "%.%w+$", "")
    if string.find(p, "gman", 1, true) then return nil end
    return replaced[p]
end

-- Mouths that move (the owner, 12 November: "With the new voices, can we get the NPCs' mouths to
-- move?"). The owner's recordings carry no phoneme data, so Source's own lip sync leaves the face
-- still. Whoever says one (anything under sound/livingcity/) is marked talking for as long as it
-- lasts, and every player's game near them works their jaw (cl_livingcity_lipsync.lua). Half-Life
-- 2's own clips are left to the engine, which has their phonemes.
function LC.MarkTalking(ent, path)
    if not IsValid(ent) or ent:IsPlayer() or type(path) ~= "string" then return false end
    local p = string.lower(path)
    p = string.gsub(p, "^[^%w]+", "")   -- (the game puts marks in front of some names)
    p = string.gsub(p, "^sound/", "")
    if string.sub(p, 1, 11) ~= "livingcity/" then return false end
    local secs = LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(p) or 0
    if not secs or secs <= 0.2 then secs = 2.5 end -- (a length unknown: about a line's)
    local now = CurTime()
    ent:SetNW2Float("lc_talk_from", now)
    ent:SetNW2Float("lc_talk_until", now + math.min(secs, 30))
    return true
end

hook.Add("EntityEmitSound", "LivingCityLipSync", function(data)
    if data and IsValid(data.Entity) then LC.MarkTalking(data.Entity, data.SoundName) end
end)

-- Every sound an entity makes passes here: a Half-Life 2 clip that has been re-recorded is swapped for the recording.
hook.Add("EntityEmitSound", "LivingCityVoiceReplace", function(data)
    local name = data and data.SoundName
    if not name then return end
    local mine = LC.VoiceReplacement(name)
    if not mine then return end
    -- a citizen's clip is swapped only for a named citizen with the recorded voice: the others keep Half-Life 2's
    if string.find(mine, "/vo/npc/", 1, true) then
        local ent = data.Entity
        local st = IsValid(ent) and LC.NPCs and LC.NPCs[ent]
        if not st or LC.VoiceOf(ent, st) ~= "own" then return end
    end
    data.SoundName = mine
    if IsValid(data.Entity) then LC.MarkTalking(data.Entity, mine) end -- (returning true ends the hooks: the jaw is marked here)
    return true
end)

concommand.Add("lc_voice_replaced", function(ply)
    if IsValid(ply) and not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local n = ScanReplaced()
    local msg = "Half-Life 2 clips replaced by your recordings (sound/" .. LC.VoiceReplaceRoot .. "): " .. n
    if IsValid(ply) then ply:ChatPrint("[Miscount] " .. msg) else print("[Miscount] " .. msg) end
end)
