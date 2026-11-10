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
        "Contents: 1. The city's announcements (Overwatch and the Administrator) · 2. The radio · 3. The G-Man · 4. The dreams · 5. Citizens showing the way",
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
    text = "\n".join(doc).rstrip("\n") + "\n"
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote VOICE_LINES.md: %d lines" % count)


if __name__ == "__main__":
    main()
