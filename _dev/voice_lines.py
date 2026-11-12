#!/usr/bin/env python3
"""Makes VOICE_LINES.md: every voice line the gamemode looks for, in one place, for the owner to record or
generate (the owner, 10 November: "consolidate all the missing voice lines that still need to be recorded/
generated ... all in a single document"). The lists come from the code itself (the announcer's triggers and
tones, the radio's, the G-Man's collapse lines, every dream line), so it's never out of date: rerun it after
adding lines. Never edit VOICE_LINES.md by hand.

    python3 _dev/voice_lines.py

The words suggested for the announcements are below (WORDS); the G-Man's clip list is _dev/gman_sounds.md
(where each comes from in Half-Life 2, and what to splice); the dream lines are read by dream_lines.py.
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "VOICE_LINES.md")
sys.path.insert(0, HERE)
import dream_lines  # noqa: E402

# When each announcement plays, and words to say: (when, Overwatch, the Administrator). Overwatch is cold and
# clinical, a dispatcher; she is a kindly parent with a dash of the cheerful host (sterner as her tone goes up).
WORDS = {
    "rations": ("A ration distribution starts", "Attention, residents: ration distribution is now in progress. Report to your assigned distribution point.", "Good news, everyone! Rations are being handed out right now. Come along, and don't forget your card."),
    "rations_soon": ("Two minutes before a ration distribution", "Attention, residents: ration distribution begins in two minutes.", "In just a couple of minutes, rations! Start making your way over, dears."),
    "sweep": ("An inspection sweep starts", "Attention, residents: inspection sweep in progress. Remain where you are and present your identification.", "A little inspection, nothing to worry about. Stand still, papers out, and it'll be over before you know it."),
    "curfew": ("Curfew starts", "Attention, residents: curfew is now in effect. Return to your residence block immediately.", "Bedtime, everyone. Curfew starts now: home you go, and stay there till morning."),
    "curfew_soon": ("Two minutes before curfew", "Attention, residents: curfew begins in two minutes. Proceed to your residence block.", "Curfew in two minutes. Finish up and head home, please."),
    "lockdown": ("A lockdown starts", "Attention, all residents: the city is now in lockdown. Remain indoors. Civil Protection is authorized to use force.", "The city is in lockdown. Stay inside. I am not asking."),
    "raid": ("A raid on a block starts", "Attention, residents: a block inspection is under way. Do not interfere with Civil Protection.", "Civil Protection is visiting one of our blocks. Cooperate, and everyone sleeps soundly tonight."),
    "supply": ("A supply convoy arrives", "Attention, residents: supply convoy in transit. Clear the route.", "A supply convoy is coming through! Step aside and let it pass, there's a love."),
    "ended": ("An event is over", "Attention, residents: sociostabilization restored. Resume assigned duties.", "That's all done. Thank you, everyone. Back to your day."),
    "socio_green": ("Sociostability goes green", "Sociostability nominal. Resume normal activity.", "Everything is calm again. Well done, all of you."),
    "socio_yellow": ("Sociostability goes yellow", "Sociostability marginal. Expect increased inspections. Keep your papers ready.", "Things are a little tense. Papers ready, heads down, and we'll get through it."),
    "socio_red": ("Sociostability goes red", "Judgment waiver in effect. Civil Protection may act at their discretion. Remain indoors.", "We are on red. Go home. Whatever happens out there now, you were warned."),
    "socio_black": ("The city collapses to BLACK (also every 5 minutes while it lasts): open rebellion, the curfew and the shelling, in one", "Attention all residents: sociostability has collapsed. Martial law is in effect. Mandatory curfew. Suppression fire authorized on all exposed sectors.", "Citizens. The city has been overrun by its own ingratitude. Go indoors and stay there. Anyone in the open will be fired upon from the Nexus. This is not a request."),
    "dawn": ("Dawn", "Attention, residents: a new work cycle begins. Report to your assignments.", "Good morning, everyone! Rise and shine: a brand new day for the city."),
    "day": ("Midday", "Attention, residents: productivity quotas remain in effect.", "Halfway through the day. Keep it up, I'm proud of you."),
    "dusk": ("Dusk", "Attention, residents: the work cycle is ending. Prepare for curfew.", "The day's nearly done. Finish up, and think about heading home."),
    "night": ("Night", "Attention, residents: night cycle. Movement outside residence blocks is restricted.", "Goodnight, everyone. Sleep well, and dream of the city."),
    "outbreak": ("Infected break out into the streets", "Alert: biotic contamination in the city. Avoid the affected area. Containment teams are responding.", "Something has got out of the infestation. Keep away from it and let the crews do their work."),
    "blackout": ("A district loses power", "Alert: power failure in your district. Remain calm. Maintenance has been dispatched.", "A little power cut, nothing more. The crews are on it, so stay calm."),
    "power_restored": ("Power comes back", "Power restored. Resume normal activity.", "Lights back on! Thank you for your patience."),
    "skirmish_raid": ("Overwatch answers a fight with the Resistance", "Overwatch response team deployed. Residents, clear the area.", "Overwatch is dealing with some trouble. Stay well away from it."),
    "skirmish_sweep": ("Overwatch sweeps into rebel ground", "Overwatch sweep under way in an anticivil sector. Residents, remain clear.", "Overwatch is cleaning up a troubled corner of the city. Let them work."),
    "response": ("A response squad is sent", "Protection response team dispatched. Do not interfere.", "A response team is on its way. Please don't get in their way."),
    "breakout": ("Prisoners break out", "Alert: unauthorized departure from detention. All residents, report sightings to Civil Protection.", "Some people have run from where they belong. If you see them, tell a unit. Now."),
    "overwatch_drop": ("Overwatch soldiers are dropped in", "Overwatch deployment in progress. Residents, clear the landing zone.", "Overwatch soldiers are arriving. Make way for them."),
    "block_raided": ("A housing block is raided", "Housing block inspection in progress. Remain in your unit.", "We're checking one of our housing blocks. Stay in your room and it'll be quick."),
    "territory_grew": ("The Resistance gains ground", "Alert: anticivil activity expanding. Avoid unregistered areas.", "Some troublemakers are spreading out. Don't go near them, and don't listen to them."),
    "train_arrival": ("A train arrives", "Attention: new arrivals at the platform. Proceed to Civil Intake.", "Welcome to the city, all you new faces! Civil Intake is just this way."),
    "welcome": ("Someone joins the server (just for them)", "Attention, new resident: report to Civil Intake for registration.", "Hello, and welcome to the city! You're going to love it here."),
    "ambient": ("General city announcements now and then (also her addresses, with lc_breen_broadcasts 1)", "Attention, residents: inaction is conspiracy. Report suspicious behavior.", "Remember, a good citizen is a happy citizen. And I do so want you all to be happy."),
    "jog": ("The morning jog", "Attention, residents: morning exercise. Assemble for the run.", "Morning, everyone! Shoes on: time for our little jog."),
    "drill": ("The morning drill", "Attention, residents: morning drill. Assemble in the yard.", "Into the yard, everyone, for our morning exercises. Stretch!"),
    "parade": ("The morning parade", "Attention, residents: assemble for the parade.", "Parade time! Chins up, shoulders back, and let's show the city who we are."),
    "black_stand": ("Her last stand begins", "Overwatch acknowledges incursion at the Nexus. All units, converge and protect the Administrator.", "So you have come for me. Come, then. You will not reach me."),
    "black_fallen": ("She's dead (always Overwatch's: she can't announce her own death)", "Administrator biosignal lost. City administration suspended. All units, fall back to the Nexus.", None),
    "black_crushed": ("The uprising is crushed (time ran out)", "Incursion contained. Sociostability restoring. Remain indoors.", "It is over. The city is mine again, and I will remember every one of you."),
    "suppressor_down": ("The suppression device is destroyed", "Alert: Nexus suppression device offline. All units, contain and repair.", "They have silenced the Nexus. It changes nothing."),
}

RADIO = [
    ("static", "The hiss between stations on the radio repair bench (long and loopable is best)", "(no words: radio static)"),
    ("union", "An ordinary station, the Union band (none: her ambient recordings play instead)", "Union broadcast music or a calm announcer: \"This is the Union band. Work hard, sleep well.\""),
    ("freq7", "The Resistance's pirate broadcast, between songs (its .txt is shown on the panel)", "\"This is Frequency 7. They can't jam us all. Stay low, stay alive.\""),
    ("freq7_song", "Songs on Freq 7 (lc_freq7_songs 1); name them freq7_song_<anything>.ogg", "(music)"),
    ("jam", "The jamming whine when the Combine find Freq 7 (a stock sound otherwise)", "(no words: a harsh whine)"),
    ("freq7_sweep", "Freq 7 warns: a sweep is coming", "\"Heads up: a sweep is coming into our ground. Hide what you've got.\""),
    ("freq7_raid", "Freq 7 warns: a raid is coming", "\"They're raiding a block. If you can get out, get out now.\""),
    ("freq7_curfew", "Freq 7 warns: curfew", "\"Curfew's coming. Get where you need to be.\""),
    ("freq7_supply", "Freq 7 warns: a supply convoy (a chance to hit it)", "\"Supply convoy on the move. Anyone feeling brave?\""),
    ("freq7_incursion", "Freq 7 warns: the Combine are in rebel ground", "\"Combine in our territory. Everyone to your posts.\""),
    ("freq7_lockdown", "Freq 7 warns: lockdown", "\"Lockdown. Stay put, stay quiet, wait it out.\""),
    ("freq7_dropship", "Freq 7 warns: a dropship", "\"Dropship incoming. Find cover.\""),
]


def dump():
    """The announcer's lists and the G-Man's collapse lines, read from the gamemode itself (loaded the way the tests load it)."""
    lua = r'''
local out = io.open(_VOICE_OUT, "w")
local function W(...) out:write(table.concat({ ... }, "\t") .. "\n") end
for _, t in ipairs(LC.AnnounceTriggers or {}) do W("trigger", t, tostring((LC.AnnounceBaseTier or {})[t] or 1), (LC.AnnounceTitles or {})[t] or "") end
for _, n in ipairs(LC.AnnounceTierNames or {}) do W("tier", n) end
for v, ts in pairs(LC.AnnounceExtra or {}) do for _, t in ipairs(ts) do W("extra", v, t) end end
for id, words in pairs(LC.AdviceLines or {}) do W("advice", id, words) end
for _, t in ipairs(LC.InfoDeskTopics or {}) do W("clerk", t[1], t[2], t[3]) end
for id, words in pairs(LC.InfoDeskLines or {}) do W("clerk", id, "", words) end
for _, t in ipairs(LC.OldTimerTopics or {}) do W("oldtimer", t[1], t[3], t[4]) end
for id, words in pairs(LC.OldTimerLines or {}) do W("oldtimer", id, "", words) end
for _, t in ipairs(LC.OldTimerTroubles or {}) do W("oldtimer", "hint_" .. t[1], "What's troubling him (said instead of his greeting)", t[3]) W("oldtimer", "thanks_" .. t[1], "You helped him with it", t[4]) end
for id, l in pairs(LC.MachineLines or {}) do W("machine", id, l[1], l[2]) end
for id, words in pairs(LC.ColonelLines or {}) do W("colonel", id, "", words) end
for id, l in pairs(LC.StreetLines or {}) do W("street", id, l[2], l[1], l[3] or l[1]) end
for id, l in pairs(LC.UnitLines or {}) do W("unitline", id, l[2], l[1], l[3] or l[1], table.concat(l[4] or {}, ", ")) end
for key, g in pairs(LC.CollapseGmanLines or {}) do
    local cv = GetConVar(g[1])
    W("gman", key, g[1], cv and cv:GetString() or "", g[2])
end
out:close()
return 0, 0, ""
'''
    with tempfile.TemporaryDirectory() as tmp:
        script, data = os.path.join(tmp, "dump.lua"), os.path.join(tmp, "dump.txt")
        with open(script, "w") as f:
            f.write("_VOICE_OUT = %r\n" % data + lua)
        r = subprocess.run([sys.executable, "run_tests.py", script], cwd=HERE, capture_output=True, text=True)
        if not os.path.exists(data):
            sys.exit("couldn't load the gamemode:\n" + r.stdout[-2000:] + r.stderr[-2000:])
        rows = [l.rstrip("\n").split("\t") for l in open(data, encoding="utf-8")]
    return rows


def her_file(trig, tier, tiers):
    word = tiers[tier - 1] if 1 <= tier <= len(tiers) else "warm"
    return ("%s1.wav" % trig) if word == "warm" else ("%s_%s1.wav" % (trig, word)), word


def demote(lines):
    return [("#" + l) if l.startswith("#") else l for l in lines]


def main():
    rows = dump()
    triggers = [(r[1], int(r[2]), r[3]) for r in rows if r[0] == "trigger"]
    tiers = [r[1] for r in rows if r[0] == "tier"]
    gman = {r[1]: (r[2], r[3], r[4]) for r in rows if r[0] == "gman"}
    count = 0
    doc = [
        "# Voice lines to record",
        "",
        "**Every voice line the gamemode looks for, in one place** (the owner, 10 November). Made from the code by "
        "`python3 _dev/voice_lines.py`: never edit it by hand, rerun it. Tick them off as you go.",
        "",
        "- **Which ones your server still lacks:** run `lc_voice_missing` in the server console: it lists exactly what isn't there yet. "
        "Paste its output to Claude and the boxes here can be ticked for you.",
        "- **Formats:** `.wav` (signed 16-bit PCM, 44100 Hz, mono), `.mp3` or `.ogg`. More than one take: `...1`, `...2` and so on; one is picked at random.",
        "- **Different words from the ones suggested?** Put them in a `.txt` file with the same name beside the recording "
        "(`curfew1.txt` beside `curfew1.wav`): that's what shows in chat or on screen.",
        "- **After adding files:** press FastDL sync on the host panel, then change the map (players download new sounds when they join).",
        "- **Without a recording** the moment is silent (or Half-Life 2's own voice, for Overwatch, with `lc_announce_stock` 1), and the words still show.",
        "",
        "Contents: 1. The city's announcements (Overwatch and the Administrator) · 2. The radio · 3. The G-Man · 4. The dreams · 5. Citizens showing the way · 6. The Citizen Information clerk · 7. The old-timer · 8. Machines · 9. The Colonel · 10. What named citizens say · 11. What units say",
        "",
        "## 1. The city's announcements",
        "",
        "Folders on the server: **`garrysmod/sound/livingcity/overwatch/`** and **`garrysmod/sound/livingcity/administrator/`**. "
        "Which voice speaks: the Administrator's with nobody playing the Administrator, Overwatch's with a player in the post. "
        "**Her tone:** each line has a usual tone, the word in her file name (warm has no word: `rations1.wav`; then `firm`, `stern`, `furious`: "
        "`curfew_firm1.wav`). Her tone goes up a step on red sociostability and again after a run of violence, so a `stern` or `furious` take of any line "
        "is worth having; with none in the tone she needs, she uses the nearest one she has.",
        "",
        "| Done | Trigger | When it plays | Overwatch file | Overwatch says | Administrator file (her usual tone) | She says |",
        "|---|---|---|---|---|---|---|",
    ]
    for trig, tier, title in triggers:
        when, ow, adm = WORDS.get(trig, (title or trig, "", ""))
        hf, word = her_file(trig, tier, tiers)
        doc.append("| [ ] | `%s` | %s | `%s1.wav` | %s | %s | %s |" % (
            trig, when, trig, ow or "", ("`%s` (%s)" % (hf, word)) if adm is not None else "(not hers)", adm or ""))
        count += 2 if adm is not None else 1
    doc += [
        "",
        "## 2. The radio",
        "",
        "Folder: **`garrysmod/sound/livingcity/radio/`**. One voice of your choosing (a Union announcer for `union`, a Resistance voice for Freq 7).",
        "",
        "| Done | File | When it plays | Suggested |",
        "|---|---|---|---|",
    ]
    extra = {r[2] for r in rows if r[0] == "extra" and r[1] == "radio"}
    for trig, when, words in RADIO:
        if extra and trig not in extra:
            continue
        name = "freq7_1.wav" if trig == "freq7" else ("freq7_song_<anything>.ogg" if trig == "freq7_song" else "%s1.wav" % trig)
        doc.append("| [ ] | `%s` | %s | %s |" % (name, when, words))
        count += 1
    doc += [
        "",
        "## 3. The G-Man",
        "",
        "Nothing here needs a new voice: every line is one of his real clips (Half-Life 2, the Episodes, Half-Life: Alyx), as it is or spliced "
        "(\"Mr. Freeman\" cut out). Each has a setting pointing at its file; a `.txt` beside a clip gives its exact words on screen.",
        "",
    ]
    src = open(os.path.join(HERE, "gman_sounds.md"), encoding="utf-8").read().split("\n")
    body = [l for l in src[1:] if not l.startswith("# ")]
    doc += demote(body)
    count += sum(1 for l in body if re.match(r"^\| \d+ \|", l))
    doc += ["", "## 4. The dreams", "",
            "Every line said in the dreams you play. Folder: **`garrysmod/sound/livingcity/dreams/voice/`** (`.mp3`, `.ogg` or `.wav`). "
            "If the words you recorded differ, a `.txt` of the same name holds them. **Music** for any dream goes in `garrysmod/sound/livingcity/dreams/`, "
            "named for the dream's codeword (in brackets): `horse1.mp3`, `boxing1.mp3`; Dance Marathon's tempo goes in `dance1.txt` (just the BPM).",
            "",
            "**The voices in the dark:** The Cheese Dream uses Half-Life 2's own citizens. Hooves and All uses Half-Life 2's hungry line too, unless you record "
            "`horse_intro_male1.mp3` and `horse_intro_female1.mp3`.", ""]
    for heading, rowsfn in (("The strange dreams", dream_lines.strange), ("The propaganda dreams", dream_lines.propaganda)):
        doc += ["### " + heading, ""]
        if heading == "The propaganda dreams":
            doc += ["(The Loyalty Quiz's questions, `quiz_q1` onwards, are read out too: each is its question.)", ""]
        order, by = dream_lines.group(rowsfn())
        for key in order:
            doc.append("#### %s (`%s`)" % (dream_lines.NAMES.get(key, key), key))
            doc.append("")
            t = dream_lines.table(by[key])
            doc.append("| Done " + t[0])
            doc.append("|---" + t[1])
            for l in t[2:]:
                doc.append("| [ ] " + l)
                count += 1
            doc.append("")
    advice = sorted((r[1], r[2]) for r in rows if r[0] == "advice")
    order = {"advice": 0, "lead": 1}
    advice.sort(key=lambda r: (order.get(r[0].split("_")[0], 2), r[0]))
    doc += ["", "## 5. Citizens showing the way", "",
            "When you chat with a citizen and they notice what you need, they say one of these, then point the way (a marker and a trail) "
            "or, if they like you, walk you there. Folder: **`garrysmod/sound/livingcity/citizens/`**. Each line wants a man's take and a woman's "
            "(the citizen's own voice): `advice_bins_male1.wav`, `advice_bins_female1.wav`; more takes `...2`, `...3`. "
            "Without a recording they speak with Half-Life 2's own citizen voice, and the words still show.",
            "",
            "| Done | Man's file | Woman's file | When | Says |",
            "|---|---|---|---|---|"]
    for id, words in advice:
        when = "Walking you there" if id.startswith("lead_") else ("No such place on this map" if id == "advice_nowhere" else "Advice")
        doc.append("| [ ] | `%s_male1.wav` | `%s_female1.wav` | %s | %s |" % (id, id, when, words))
        count += 2
    def simple(kind, num, title, intro, whohead):
        nonlocal count
        rs = [r for r in rows if r[0] == kind]
        topics = [r for r in rs if r[2] != ""] if kind != "machine" else []
        others = sorted([r for r in rs if r[2] == ""], key=lambda r: r[1]) if kind != "machine" else sorted(rs, key=lambda r: r[1])
        doc.extend(["", "## %d. %s" % (num, title), "", intro, "", "| Done | File | %s | Says |" % whohead, "|---|---|---|---|"])
        for r in topics + others:
            doc.append("| [ ] | `%s1.wav` | %s | %s |" % (r[1], r[2] if r[2] else "(said between answers)", r[3]))
            count += 1
    simple("clerk", 6, "The Citizen Information clerk",
           "The clerk behind the Citizen Information desk: flat, tired, official. Folder: **`garrysmod/sound/livingcity/clerk/`**. "
           "One voice for every clerk (or record a man's and a woman's take and keep whichever fits). Without a recording, a terminal's chime, and the words show.",
           "The question asked")
    simple("oldtimer", 7, "The old-timer",
           "The old man who gives advice: warm, worn, a little wry. Folder: **`garrysmod/sound/livingcity/oldtimer/`**. "
           "For \"Is anyone fighting back?\" he goes on to say where the Resistance gathers (that part changes with the map, so it only shows as words). "
           "Without a recording, Half-Life 2's own citizen voice.",
           "The question asked")
    simple("machine", 8, "Machines",
           "The ration dispenser and the vending machines, in a flat machine voice (a Combine terminal's). Folder: **`garrysmod/sound/livingcity/machines/`**. "
           "Without a recording, the machine's beep.",
           "Which machine")
    def colonel_when(i):
        for k, v in (("greet", "Greeting (by how well he knows you)"), ("job_", "What he needs (end of his greeting)"), ("thanks_", "You helped"),
                     ("intel_", "What's the word?"), ("debrief_", "Debrief me"), ("whisper_", "Heard anything strange?"), ("ask", "What's happening to you? (by how ghostly he looks)")):
            if i.startswith(k): return v
        return "Between answers"
    rs = sorted([r for r in rows if r[0] == "colonel"], key=lambda r: r[1])
    doc.extend(["", "## 9. The Colonel", "",
                "The old fighter at the Resistance camp (Odessa Cubbage's face): weary, dry, kind underneath, a ghost who doesn't quite know it at first. "
                "Folder: **`garrysmod/sound/livingcity/colonel/`**. Only the player he's talking to hears these. Without a recording he's silent and the words show. "
                "`job_unit` names a unit's designation where it says %s: record it without the number (\"Designation... still walking around\").",
                "", "| Done | File | When | Says |", "|---|---|---|---|"])
    for r in rs:
        doc.append("| [ ] | `%s1.wav` | %s | %s |" % (r[1], colonel_when(r[1]), r[3]))
        count += 1
    street = sorted([r for r in rows if r[0] == "street"], key=lambda r: r[1])
    groups = [("say_open_", "Openers (a word or two before another line)"), ("say_greet_", "Hello"), ("say_bye_", "Goodbye"),
              ("say_yes", "Yes, no, perhaps"), ("say_no", "Yes, no, perhaps"), ("say_maybe", "Yes, no, perhaps"), ("say_later", "Yes, no, perhaps"),
              ("say_dunno", "What they know"), ("say_heard", "What they know"), ("say_cant_say", "What they know"), ("say_ask_else", "What they know"), ("say_truth", "What they know"),
              ("say_state_", "How they are"),
              ("say_thanks", "Answering how they were spoken to"), ("say_sorry", "Answering how they were spoken to"), ("say_insulted", "Answering how they were spoken to"),
              ("say_threatened", "Answering how they were spoken to"), ("say_laugh", "Answering how they were spoken to"), ("say_agree", "Answering how they were spoken to"),
              ("say_disagree", "Answering how they were spoken to"),
              ("say_loyal", "The Combine"), ("say_careful", "The Combine"), ("say_units_near", "The Combine"), ("say_hate_", "The Combine"), ("say_fear_", "The Combine"), ("say_obey", "The Combine"),
              ("say_res_", "The Resistance"), ("say_warn_", "Warnings and tips"), ("say_tip_", "Warnings and tips"),
              ("say_ask_", "Asking and giving"), ("say_offer", "Asking and giving"), ("say_decline_", "Asking and giving"),
              ("say_break_", "As a mind gives way"), ("say_saw_", "What they saw"), ("say_grief", "What they saw")]
    def group_of(i):
        for k, v in groups:
            if i.startswith(k): return v
        return "Other"
    order = []
    for _, v in groups:
        if v not in order: order.append(v)
    doc.extend(["", "## 10. What named citizens say", "",
                "A small bank of lines the city's named citizens say everywhere: answering you in free talk (the hosted model picks the one that fits), "
                "walking up to you when the director sends them, and as their minds give way. Written by what the line does, not what it is about, "
                "with no names, jobs, places or times in them, so any citizen can say any line. Folder: **`garrysmod/sound/livingcity/citizens/`** "
                "(the same as section 5). Each line wants a man's take and a woman's: `say_dunno_male1.wav`, `say_dunno_female1.wav`; more takes `...2`, `...3`. "
                "Keep them short and flat: tired people, speaking low. An opener is said just before another line, so record it to run on (\"Listen.\" ... \"You should go. Now.\"). "
                "Without a recording they speak with Half-Life 2's own citizen voice, and the words still show. "
                "How it works: `docs/features/recorded-lines.md`.",
                "", "| Done | Man's file | Woman's file | When | Says |", "|---|---|---|---|---|"])
    for g in order + ["Other"]:
        rs = [r for r in street if group_of(r[1]) == g]
        if not rs: continue
        doc.append("| | | | **%s** | |" % g)
        for r in rs:
            doc.append("| [ ] | `%s_male1.wav` | `%s_female1.wav` | %s | %s |" % (r[1], r[1], r[2], r[3]))
            count += 2
    units = sorted([r for r in rows if r[0] == "unitline"], key=lambda r: r[1])
    doc.extend(["", "## 11. What units say", "",
                "The named Civil Protection units' answers in free talk, and what they say when their minds give way. One voice for every unit, "
                "clipped and cold, through the mask (a radio or vocoder effect over it helps). Folder: **`garrysmod/sound/livingcity/units/`**. "
                "**Where Half-Life 2 already has the line** (marked in the table) its own clip is played and nothing needs recording. "
                "Without a recording or a clip a unit is silent and the words show.",
                "", "| Done | File | When | Says |", "|---|---|---|---|"])
    for r in units:
        stock = r[5] if len(r) > 5 else ""
        if stock:
            doc.append("| n/a | `%s1.wav` (optional) | %s | %s (Half-Life 2 has it: `npc/metropolice/vo/%s.wav`, used by itself) |" % (r[1], r[2], r[3], stock.split(", ")[0]))
        else:
            doc.append("| [ ] | `%s1.wav` | %s | %s |" % (r[1], r[2], r[3]))
            count += 1
    text = "\n".join(doc).rstrip("\n") + "\n"
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote VOICE_LINES.md: %d lines" % count)
    scripts(doc, street, units, group_of, order)


HER_TONE = {"warm": "[warm, motherly, smiling]", "firm": "[firm, composed, still kind]", "stern": "[stern, cold, slowly]",
            "furious": "[furious, barely controlled, clipped]"}
GMAN_TAG = "[slow, breathy, unsettling calm, odd pauses and emphasis]"

def scripts(doc, street, units, group_of, order):
    """VOICE_SCRIPTS.md: the same lines as text to paste into ElevenLabs, with voice descriptions."""
    out = ["# Voice scripts: what to paste into ElevenLabs", "",
           "**Made from the code by `python3 _dev/voice_lines.py`: never edit it by hand.** The lines of `VOICE_LINES.md` that are generated speech "
           "(named citizens, units, the Administrator, and the G-Man's made-up lines), written the way ElevenLabs wants them, with a voice description for each voice.", "",
           "## How to use it", "",
           "- **Model:** Eleven v4 (or v3). A direction in **square brackets** changes how what follows is said: `[whispers] Careful.` It is not read out. "
           "Put it just before the words it changes. Your own wording works (`[tired, flat]`), as do reactions (`[sighs]`, `[exhales]`, `[short laugh]`) and `[pause]`. "
           "If a tag is read aloud, the model is not v4 or v3, or the brackets are not square.",
           "- **Copy the \"Paste\" cell as it is.** Generate two or three takes and keep the best; a second good take can be saved as `...2` (one is picked at random in game).",
           "- **Save each file under the name in the table**, `.mp3` or `.wav`, into the folder named above the table (on the server, under `garrysmod/sound/livingcity/`).",
           "- **Tags are a starting point.** If a line comes out overacted, delete the tag or soften it (`[quietly]`): these are tired people, not actors. The breaks are the only loud ones.",
           "- **The same voice for every line of a kind:** design the voice once (below), save it to your voices, and use that saved voice for the whole table.",
           "- **Staying legal:** the descriptions below describe a kind of voice in ordinary words. Do not name a game, a character or an actor in a voice prompt, "
           "and do not upload audio from the games to clone a voice: that needs the performer's consent, and ElevenLabs' terms forbid it.", "",
           "## All of them at once (instead of pasting each line)", "",
           "`_dev/tools/elevenlabs_batch.py` sends every line to ElevenLabs and saves each file under its right name, in the right folder, ready to upload. "
           "On Linux Mint, in a terminal in the gamemode's folder:", "",
           "**Just the citizens, the simple way:** keep `record_citizens.sh`, `elevenlabs_batch.py` and `voice_batch.tsv` together in one folder (any folder) and run `bash record_citizens.sh` there: it makes 3 test lines only. `bash record_citizens.sh all` then makes the rest. It asks for your key (hidden, never saved) and makes them louder (needs `ffmpeg`). The two voice ids are at the top of the script. Upload what lands in `voice_out/sound/livingcity/citizens/` (made beside the script) to the server's `garrysmod/sound/livingcity/citizens/`.", "",
           "```",
           "export ELEVENLABS_API_KEY='your key here'",
           "python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --dry-run",
           "python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --limit 3",
           "python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --unit VOICE_ID --administrator VOICE_ID --gman VOICE_ID",
           "```", "",
           "- **A voice id** is shown beside each voice in ElevenLabs' voice list (design and save the voices first, below). Only the voices you give are made: leave one out to skip its lines.",
           "- **`--dry-run`** makes nothing: it says how many lines and characters it would send, so you know the cost first. **`--limit 3`** makes just the first three, to listen before doing the rest.",
           "- **It never makes a file twice:** a file already in the output folder is skipped, so you can stop and run it again, delete the takes you dislike and rerun, or add `--takes 2` for a second take of each (`...2`).",
           "- **Where they go:** `voice_out/sound/livingcity/...`, laid out like the server's `garrysmod/sound/`, so the whole `sound` folder can be uploaded as it is. "
           "Unit lines go to `voice_out/units_clean/` instead: run `bash _dev/tools/unit_radio.sh voice_out/units_clean voice_out/sound/livingcity/units` for their radio sound.",
           "- **Only what your server lacks:** run `lc_voice_missing` on the server, download `data/livingcity/voice_missing.txt`, and add `--missing voice_missing.txt`: lines the server already has a recording of are left out.",
           "- **`--extras`** also makes the G-Man lines that are not in the game yet. **`--model eleven_v4_turbo`** is cheaper than the default `eleven_v4`.",
           "- The G-Man's files must be `.wav`: with `ffmpeg` installed (`sudo apt install ffmpeg`) the script converts them itself.",
           "- **Half-Life 2's own lines, in your voices** (they then play in place of Half-Life 2's clips; never the G-Man): run `lc_hl2_lines` in the server console, download `data/livingcity/hl2_lines.txt`, "
           "then `python3 _dev/tools/elevenlabs_batch.py --hl2 hl2_lines.txt --man ID --woman ID --unit ID --soldier ID --overwatch ID --dry-run`. More: `docs/features/recorded-lines.md`.",
           "- **Not yet tried against the real service.** If the first run prints an error from ElevenLabs, paste it to Claude.", "",
           "## Voice descriptions (ElevenLabs: Voices > Voice Design; paste one, listen, adjust)", "",
           "Each is written to sit close to the people already heard in the city without copying anyone. Try the first; the others lean a different way.", "",
           "### The citizen, a man (every named male citizen)", "",
           "The Half-Life 2 man is not gruff or deep: he is a clear, fairly light, well-spoken voice in his thirties, lively and a little theatrical, an actor playing an ordinary guy. "
           "Start with the first; the others move one thing each (lighter and younger; a touch older and drier).", "",
           "1. `An American man in his mid thirties with a clear, light baritone that leans toward tenor. Clean, neutral General American accent, crisp consonants, well-spoken. A friendly, earnest everyman with a slightly wry edge: lively and expressive, quick to sound worried or urgent, never gravelly, never deep, never sleepy. Sounds like a trained stage actor playing a regular guy. Close, dry studio recording, no reverb.`",
           "2. `American man around thirty, bright clear tenor-baritone, smooth with no rasp. Neutral accent, precise and articulate, energetic and a little breathless, sincere, slightly nervous good humour. An approachable, ordinary, educated-sounding guy. Close, dry studio recording.`",
           "3. `American man in his late thirties, clear medium-pitched voice, clean and resonant but not deep, neutral General American. Articulate, steady, dryly humorous, concerned and alert, speaks with energy and clear emphasis. No gravel, no drawl. Close, dry studio recording.`", "",
           "**If it still misses,** change one word at a time and listen: too deep or old (add `higher, lighter, younger`), too flat (add `animated, expressive`), too smooth or like an announcer (add `natural, conversational, slightly breathy`), too gruff (add `smooth, clean, no rasp`). "
           "The tags on the lines ask for tired and quiet; if this voice then sounds unlike itself, delete the tag for that line.", "",
           "**A voice that is right but too high** (ElevenLabs will not lower a voice without changing it): make the lines with it as it is, then "
           "`bash _dev/tools/voice_deeper.sh FOLDER_IN FOLDER_OUT` writes a deeper copy of every file at the same speed. `SEMITONES=-1` is subtle, `-1.5` the default, `-2` clearly deeper, "
           "`-3` about as far as it stays natural: `SEMITONES=-2 bash _dev/tools/voice_deeper.sh in out`. The originals are never overwritten.", "",
           "### The citizen, a woman (every named female citizen)", "",
           "The Half-Life 2 woman is likewise clear and medium-pitched, in her thirties, earnest and expressive, not husky or low.", "",
           "1. `An American woman in her early thirties with a clear, medium-pitched voice, warm and smooth with no rasp. Clean, neutral General American accent, articulate. Earnest, capable and caring, expressive, quick to sound concerned or urgent, never husky, never low, never sleepy. Sounds like a trained stage actor playing an ordinary woman. Close, dry studio recording, no reverb.`",
           "2. `American woman around thirty, bright clear mezzo voice, neutral accent, precise and lively, sincere, a little anxious, friendly. An approachable, ordinary, educated-sounding woman. Close, dry studio recording.`",
           "3. `American woman in her late thirties, clear mid voice with gentle warmth, neutral General American, steady and articulate, wry, alert and concerned, speaks with clear emphasis. No rasp, no drawl. Close, dry studio recording.`", "",
           "### The unit (one voice for every Civil Protection unit)", "",
           "**The radio sound is not the voice: it is an effect put on afterwards.** No voice model will make it reliably. Record the lines CLEAN with a plain, deep, flat voice, then run them through the effect (next heading). A clean voice to start from:", "",
           "1. `An American man in his forties, deep and flat. Low baritone, clipped and cold, every word the same weight, no emotion, like a man reading orders he has read a thousand times. Speaks close to the microphone, firmly, a little too loud. Dry studio recording, no reverb.`",
           "2. `Deep-voiced American man, thirties, hard and bored. Gravelly bass-baritone, short flat sentences bitten off at the end, faintly contemptuous. Close, dry recording.`",
           "3. `American man, fifties, heavy chest voice. Slow, toneless, official, slightly muffled as if speaking behind a mask, no rise or fall. Close, dry recording.`", "",
           "If you would rather ElevenLabs tried the effect itself, add this to the end of any of them (results vary a lot from take to take): "
           "`Heard through a small helmet radio: narrow, tinny, compressed and slightly distorted, with a faint electronic buzz.`", "",
           "### Giving the unit's lines their radio sound", "",
           "On Linux Mint, once, in a terminal: `sudo apt install ffmpeg`. Then put the clean unit recordings in one folder and run the script that comes with the gamemode:", "",
           "```",
           "bash _dev/tools/unit_radio.sh ~/unit_clean ~/unit_radio",
           "```", "",
           "It writes a `.wav` of each into the second folder: a little deeper, the lows and highs cut like a small speaker, squashed flat and loud, a little digital grit and a fast buzz for the gargle, "
           "and a click of static before and after. Listen to one. To change it, put settings in front: `DEPTH=0.90 BUZZ=0.5 CRUSH=0.4 bash _dev/tools/unit_radio.sh ...` "
           "(DEPTH 0.90 deeper to 1.00 as recorded; BUZZ 0 none to 0.6 heavy; CRUSH 0 clean to 0.6 gritty). Upload the results to `garrysmod/sound/livingcity/units/`.", "",
           "By hand in Audacity instead, in this order: Effect > Pitch and Tempo > Change Pitch (about -6%); Effect > EQ and Filters > High-Pass Filter (300 Hz) and Low-Pass Filter (3000 Hz); "
           "Effect > Volume and Compression > Compressor (ratio 8:1, threshold -24 dB); Effect > Distortion and Modulation > Distortion (Hard Clipping, a little); "
           "Effect > Distortion and Modulation > Tremolo (about 85 Hz, depth 35%).", "",
           "### The G-Man (only for his lines that are not real clips)", "",
           "Most of his lines in game are his real clips and need nothing. These are for the few made-up ones, so they sit beside the real ones without imitating the performer. "
           "Expect to generate several takes: what sells him is where the stress falls, and the tags only nudge that.", "",
           "1. `A middle-aged American man with a soft, breathy, slightly hoarse voice and a strange, halting way of speaking: pauses in the wrong places, stress on the wrong syllables, sibilants drawn out a little, pitch rising and falling where it should not. Polite, bureaucratic, quietly menacing, as if human speech were learned from a manual. Very slow and deliberate. Close, dry recording.`",
           "2. `Older man, sixties, thin dry voice barely above a whisper, formal and courteous, oddly musical, each phrase beginning slowly and ending in a small upward lilt. Unsettlingly calm, patient, amused. Close, dry recording.`",
           "3. `Man in his fifties, smooth low voice with a faint rasp, a government official's careful diction, long unnatural gaps between words, cold and detached, never raising his voice. Close, dry recording.`", "",
           "## The Administrator's announcements", "",
           "Folder: `administrator/`. **Use the voice her existing recordings were made with.** Each line is given in her usual tone; the tone is the word in the file name "
           "(none: warm). A harsher take of any line is worth having, since she steps up a tone when the city is on red or after violence: paste the same words after "
           "`" + HER_TONE["stern"] + "` and save as `<trigger>_stern1`, or after `" + HER_TONE["furious"] + "` as `<trigger>_furious1`.", "",
           "| Done | File | When | Paste |", "|---|---|---|---|"]
    n = 0
    batch = []  # (voice, path under sound/ without its ending, text)
    in1 = False
    for l in doc:
        if l.startswith("## 1."): in1 = True; continue
        if l.startswith("## ") and in1: break
        if not in1 or not l.startswith("| [ ] |"): continue
        c = [x.strip() for x in l.strip().strip("|").split("|")]
        if len(c) < 7: continue
        m = re.match(r"`([^`]+)`\s*\((\w+)\)", c[5])
        if not m or not c[6]: continue
        out.append("| [ ] | `%s` | %s | %s %s |" % (m.group(1), c[2], HER_TONE.get(m.group(2), HER_TONE["warm"]), c[6]))
        batch.append(("administrator", "livingcity/administrator/" + re.sub(r"\.\w+$", "", m.group(1)), HER_TONE.get(m.group(2), HER_TONE["warm"]) + " " + c[6]))
        n += 1
    out += ["", "## What named citizens say", "",
            "Folder: `citizens/`. Paste each line twice: once with the man's voice (save as the man's file), once with the woman's.", "",
            "| Done | Man's file | Woman's file | Paste |", "|---|---|---|---|"]
    for g in order + ["Other"]:
        rs = [r for r in street if group_of(r[1]) == g]
        if not rs: continue
        out.append("| | | | **%s** |" % g)
        for r in rs:
            out.append("| [ ] | `%s_male1` | `%s_female1` | %s |" % (r[1], r[1], r[4] if len(r) > 4 else r[3]))
            batch.append(("man", "livingcity/citizens/%s_male1" % r[1], r[4] if len(r) > 4 else r[3]))
            batch.append(("woman", "livingcity/citizens/%s_female1" % r[1], r[4] if len(r) > 4 else r[3]))
            n += 2
    out += ["", "## What units say", "",
            "Folder: `units/`. Record clean, then give them the radio sound (above). Half-Life 2's own units are heard beside these, "
            "so the closer the effect gets to theirs the better: compare one of yours with `npc/metropolice/vo/movealong.wav`.", "",
            "| Done | File | Paste |", "|---|---|---|"]
    for r in units:
        if len(r) > 5 and r[5]: continue
        out.append("| [ ] | `%s1` | %s |" % (r[1], r[4] if len(r) > 4 else r[3]))
        batch.append(("unit", "livingcity/units/%s1" % r[1], r[4] if len(r) > 4 else r[3]))
        n += 1
    have = [r for r in units if len(r) > 5 and r[5]]
    if have:
        out += ["", "**Nothing to record for these:** Half-Life 2's own Civil Protection voice says them, and the game uses its clip "
                "(`npc/metropolice/vo/`): " + "; ".join('"%s" (`%s`)' % (r[3], r[5].split(", ")[0]) for r in have) + ". "
                "The clip names are from memory: `lc_voice_missing` on your server lists any unit line that has neither a recording nor a clip, and those can then be recorded."]
    out += ["", "## The G-Man: the lines that are not real clips", "",
            "Folder: as in the File column, under `garrysmod/sound/`. These are the collapse lines the gamemode already looks for; until a file is there the moment is silent and the words show. "
            "Save as `.wav` (signed 16-bit, 44100 Hz, mono).", "",
            "| Done | File | When | Paste |", "|---|---|---|---|"]
    in3 = False
    for l in doc:
        if l.startswith("## 3."): in3 = True; continue
        if l.startswith("## ") and in3: break
        if not in3 or not re.match(r"^\| \d+ \|", l): continue
        c = [x.strip() for x in l.strip().strip("|").split("|")]
        f = next((x for x in c if x.startswith("`livingcity/gman/black_")), None)
        words = next((x for x in c if x.startswith('"')), None)
        if not f or not words: continue
        w = re.match(r'"([^"]+)"', words).group(1)
        out.append("| [ ] | %s | %s | %s %s |" % (f.split(" ")[0], c[1], GMAN_TAG, w))
        batch.append(("gman", re.sub(r"\.\w+$", "", f.split(" ")[0].strip("`")), GMAN_TAG + " " + w))
        n += 1
    out += ["", "## The G-Man: lines it would be nice to have", "",
            "**Not in the game yet.** Nothing plays these today: they are offered as lines worth making while you are designing his voice. "
            "Tell Claude which you record and where you want them heard, and they can be wired in. Suggested folder: `livingcity/gman/`.", "",
            "| File | Where it could be heard | Paste |", "|---|---|---|"]
    for f, where, w in NICE_GMAN:
        out.append("| `%s` | %s | %s |" % (f, where, w))
        batch.append(("gman_extra", "livingcity/gman/" + re.sub(r"\.\w+$", "", f), w))
    with open(os.path.join(HERE, "tools", "voice_batch.tsv"), "w", encoding="utf-8") as fh:
        fh.write("# Made by python3 _dev/voice_lines.py for _dev/tools/elevenlabs_batch.py: voice, file (under garrysmod/sound/, no ending), text\n")
        for v, path, text in batch:
            fh.write("%s\t%s\t%s\n" % (v, path, text))
    with open(os.path.join(os.path.dirname(OUT), "VOICE_SCRIPTS.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out).rstrip("\n") + "\n")
    print("wrote VOICE_SCRIPTS.md: %d lines to paste" % n)


NICE_GMAN = [
    ("gman_asked_again.wav", "The collapse: he asks the city's own Administrator again", "[slow, breathy, patient, faintly amused] I will ask ... once more."),
    ("gman_poorly.wav", "The collapse: she refuses him again", "[slow, soft, mock regret] She was given a choice. [pause] She chose ... poorly."),
    ("gman_vote_yes.wav", "His vote passes, as time starts again", "[slow, pleased, breathy] Then it is ... decided."),
    ("gman_new_admin.wav", "A new City Administrator takes the post", "[slow, courteous, cold] Congratulations ... Administrator. We will be ... watching."),
    ("gman_glimpse.wav", "A glimpse of him about the city", "[barely a whisper, amused] Not yet."),
    ("gman_crate_taken.wav", "A player takes a weapon from one of his crates", "[slow, breathy, approving] A wise ... investment."),
    ("gman_dream_open.wav", "The start of one of his riddles in a dream", "[very slow, soft, dreamlike] Rise ... and listen."),
    ("gman_dream_close.wav", "The end of one of his riddles", "[slow, fading] Remember this ... when you wake."),
    ("gman_last_stand_won.wav", "The uprising is crushed", "[slow, dry, faintly disappointed] How ... disappointing. Another time, then."),
    ("gman_last_stand_lost.wav", "The Administrator falls in her office", "[slow, satisfied, breathy] The city ... thanks you. In its way."),
    ("gman_time_resumes.wav", "Time starts again after his vote", "[slow, businesslike] Time, I think ... to resume."),
    ("gman_patience.wav", "A directive has waited too long", "[slow, cold, quiet] My employers ... are not patient."),
]


if __name__ == "__main__":
    main()
