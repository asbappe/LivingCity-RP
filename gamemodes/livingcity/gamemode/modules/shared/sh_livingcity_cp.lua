--[[
    Civil Protection's toolset (shared config): voice lines, and the
    sociostability levels.

    Voice lines: a unit picks one from the menu (!vo, or bind a key to
    lc_vo_menu), types /vo <word>, or simply says the line's text in chat; the
    line is heard in the unit's mask voice. Add your own: any sound file the
    game has.
]]


LCCP = LCCP or {}

local MP = "npc/metropolice/vo/"
local CS = "npc/combine_soldier/vo/"

-- { short word for /vo, what it says, sound, group }
LCCP.Voice = {
    -- on the street
    { "movealong", "Move along.", MP .. "movealong.wav", "Street" },
    { "isaid", "I said move along.", MP .. "isaidmovealong.wav", "Street" },
    { "keepmoving", "Keep moving.", MP .. "keepmoving.wav", "Street" },
    { "moveit", "Move it!", MP .. "moveit.wav", "Street" },
    { "moveback", "Move back, right now!", MP .. "movebackrightnow.wav", "Street" },
    { "vacate", "Vacate, citizen!", MP .. "vacatecitizen.wav", "Street" },
    { "citizen", "Citizen.", MP .. "citizen.wav", "Street" },
    { "document", "Document.", MP .. "document.wav", "Street" },
    { "apply", "Apply.", MP .. "apply.wav", "Street" },
    { "youcango", "All right, you can go.", MP .. "allrightyoucango.wav", "Street" },
    { "pickup", "Pick up that can.", MP .. "pickupthecan1.wav", "Street" },
    { "trash", "Now put it in the trash can.", MP .. "putitinthetrash1.wav", "Street" },
    { "trouble", "Looking for trouble?", MP .. "lookingfortrouble.wav", "Street" },
    { "watchit", "Watch it.", MP .. "watchit.wav", "Street" },
    { "getout", "Now get out of here.", MP .. "nowgetoutofhere.wav", "Street" },
    { "chuckle", "(chuckles)", MP .. "chuckle.wav", "Street" },
    -- warnings and arrests
    { "holdit", "Hold it right there!", MP .. "holditrightthere.wav", "Warnings" },
    { "dontmove", "Don't move!", MP .. "dontmove.wav", "Warnings" },
    { "freeze", "Freeze!", MP .. "freeze.wav", "Warnings" },
    { "getdown", "Get down!", MP .. "getdown.wav", "Warnings" },
    { "first", "First warning, move away.", MP .. "firstwarningmove.wav", "Warnings" },
    { "second", "This is your second warning!", MP .. "thisisyoursecondwarning.wav", "Warnings" },
    { "final", "Final warning!", MP .. "finalwarning.wav", "Warnings" },
    { "verdict", "You want a malcompliance verdict?", MP .. "youwantamalcomplianceverdict.wav", "Warnings" },
    { "citation", "Issuing malcompliant citation.", MP .. "issuingmalcompliantcitation.wav", "Warnings" },
    { "judgment", "Prepare for judgment!", MP .. "prepareforjudgement.wav", "Warnings" },
    { "prosecute", "Ready to prosecute.", MP .. "readytoprosecute.wav", "Warnings" },
    { "sentence", "Sentence delivered.", MP .. "sentencedelivered.wav", "Warnings" },
    { "administered", "Final verdict administered.", MP .. "finalverdictadministered.wav", "Warnings" },
    -- on the radio and in a fight
    { "affirmative", "Affirmative.", MP .. "affirmative.wav", "Radio" },
    { "copy", "Copy.", MP .. "copy.wav", "Radio" },
    { "104", "10-4.", MP .. "ten4.wav", "Radio" },
    { "roger", "Roger that.", MP .. "rodgerthat.wav", "Radio" },
    { "108", "Unit is on duty, 10-8.", MP .. "unitisonduty10-8.wav", "Radio" },
    { "inposition", "In position.", MP .. "inposition.wav", "Radio" },
    { "sociostable", "We are sociostable at this location.", MP .. "wearesociostablethislocation.wav", "Radio" },
    { "searching", "Searching for suspect.", MP .. "searchingforsuspect.wav", "Radio" },
    { "thereheis", "There he is!", MP .. "thereheis.wav", "Radio" },
    { "running", "He's running!", MP .. "hesrunning.wav", "Radio" },
    { "bleeding", "Suspect is bleeding.", MP .. "suspectisbleeding.wav", "Radio" },
    { "backup", "Backup!", MP .. "backup.wav", "Radio" },
    { "1199", "11-99, officer needs assistance!", MP .. "11-99officerneedsassistance.wav", "Radio" },
    { "1099", "Officer down, I am 10-99!", MP .. "officerdowniam10-99.wav", "Radio" },
    { "shotsfired", "Shots fired, hostile malignants!", MP .. "shotsfiredhostilemalignants.wav", "Radio" },
    { "takecover", "Take cover!", MP .. "takecover.wav", "Radio" },
    { "goingin", "Cover me, I'm going in.", MP .. "covermegoingin.wav", "Radio" },
    { "grenade", "Grenade!", MP .. "grenade.wav", "Radio" },
    { "movein", "All units, move in!", MP .. "allunitsmovein.wav", "Radio" },
}

-- Overwatch soldiers sound different.
LCCP.VoiceOTA = {
    { "affirmative", "Affirmative.", CS .. "affirmative.wav", "Overwatch" },
    { "copy", "Copy that.", CS .. "copythat.wav", "Overwatch" },
    { "contact", "Contact!", CS .. "contact.wav", "Overwatch" },
    { "movein", "Move in.", CS .. "movein.wav", "Overwatch" },
    { "lostcontact", "Lost contact.", CS .. "lostcontact.wav", "Overwatch" },
}

-- What this player says through the mask: the Overwatch ranks have their own lines.
function LCCP.VoiceFor(ply)
    return (IsValid(ply) and LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply)) and LCCP.VoiceOTA or LCCP.Voice
end

-- City-wide sociostability. Set by events and the state of the city, or by
-- an officer (or an admin) for a while.
LCCP.Socio = {
    green = { name = "NOMINAL", long = "Sociostability nominal", color = Color(110, 200, 120) },
    yellow = { name = "MARGINAL", long = "Sociostability marginal", color = Color(235, 200, 70) },
    red = { name = "JUDGMENT WAIVER", long = "Judgment waiver in effect", color = Color(230, 70, 60) },
}
LCCP.SocioOrder = { "green", "yellow", "red" }
