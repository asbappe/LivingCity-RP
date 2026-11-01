--[[
    Occupations (shared config)

    Union jobs for citizens. Pick one from your board (F3). Each job hands you
    a steady stream of shifts in the real world. Mark workplaces with the editor
    ("Point: workplace", number = the job's number below) and shifts happen
    there; without them, shifts use the streets around you. NPC citizens go to
    work at those workplaces too.

    npcOnly: the city's own people work there, but players can't take it.
    gameOnly: a player's shifts there are all hands-on games
    (sv_livingcity_moregames.lua), so it's only open while lc_jobgames is on.
]]


LCJ = LCJ or {}

LCJ.Occupations = {
    { id = "sanitation", num = 1, name = "Sanitation Worker", place = "Sanitation depot",
      desc = "Pick up litter, empty bins and scrub off graffiti. The city must look clean, whatever it really is." },
    { id = "kitchen", num = 2, name = "Ration Production", place = "Ration plant",
      desc = "Seal ration packs on the line, count the packs against the register, and check ration cards at the counter, catching the forged ones. Nobody cooks here: rations are made in a factory, not cooked." },
    { id = "medic", num = 3, name = "Clinic Medic", place = "Clinic", tools = { "weapon_medkit" },
      desc = "Heal injured citizens with your medkit and write down how they got hurt. Sometimes you decide what goes in the report." },
    { id = "factory", num = 4, name = "Factory Worker", place = "Factory",
      desc = "Work the factory line to meet the quota: throw out the bad parts, pass the good ones. Nobody asks what the parts are for." },
    { id = "courier", num = 5, name = "Courier", place = "Post office",
      desc = "Deliver letters, parcels and sealed envelopes to people all over the district." },
    { id = "maintenance", num = 6, name = "Maintenance Technician", place = "Maintenance yard",
      desc = "Repair fuse boxes, streetlights and Combine terminals. You get to see what the terminals have logged." },
    { id = "porter", num = 7, name = "Intake Processor", place = "Train station",
      desc = "Check travelers' tickets and papers at the train station, return lost luggage, carry freight from the loading dock, and walk new arrivals to their housing." },
    { id = "clerk", num = 8, name = "Records Clerk", place = "Civil records office", gameOnly = true,
      desc = "File forms by citizen number at the civil records office. The cabinet of blank identity forms is rarely locked." },
    { id = "laundry", num = 9, name = "Uniform Laundry", place = "Nexus laundry", gameOnly = true,
      desc = "Sort washed and pressed Civil Protection uniforms by division. They're supposed to be counted, and usually are." },
    { id = "mortuary", num = 10, name = "Mortician", place = "City morgue",
      desc = "Collect bodies from the streets, search them and burn them in the incinerator. Nobody checks your work closely." },
    { id = "scrap", num = 11, name = "Reclamation Crew", place = "Reclamation yard",
      desc = "Collect scrap metal and clear rubble from the old city. Some of what's buried there was hidden on purpose." },
    { id = "radio", num = 12, name = "Radio Repair", place = "Radio repair shop", gameOnly = true,
      desc = "Repair loudspeakers and Union radios. Some come in tuned to frequencies that aren't supposed to exist." },
    { id = "groundskeeper", num = 14, name = "Groundskeeper", place = "the streets", noWorkplace = true, tools = { "weapon_lc_sprayer" },
      desc = "Spray the weeds coming up through the cracks before they take over: a tuft is quick, a bush takes a while. You're issued weedkiller." },
    -- (the owner, 2026-11-01: like contamination cleanup elsewhere; a faster way into Civil Protection than the records office)
    { id = "cleanup", num = 15, name = "Infestation Cleanup", place = "the infestation", noWorkplace = true, tools = { "weapon_lc_sprayer", "weapon_lc_hoover" },
      desc = "Into the infestation in a respirator, with weedkiller and a hoover: spray its growths dead, vacuum them up, and empty the hoover into the infestation control barrel. Civil Protection guards you; it's dangerous. Each shift counts double towards joining Civil Protection." },
    -- (the owner, 2026-11-01: something for the city's most loyal) players only, Exemplary standing; no workplace: your own block
    { id = "warden", num = 13, name = "Block Warden", place = "your housing block", minStanding = 400, playersOnly = true, noWorkplace = true,
      desc = "Exemplary citizens only (Civil Standing 400). Walk your own block, have a word with the neighbours, and report what isn't right. Paid when a report holds up; a false one costs you." },
}

-- Closed to players: an NPC-only post, or a games-only one with the games off.
function LCJ.Closed(o)
    if not o then return false end
    if o.npcOnly then return true end
    if o.gameOnly then
        local cv = GetConVar("lc_jobgames")
        return cv ~= nil and not cv:GetBool()
    end
    return false
end

LCJ.ById, LCJ.ByNum = {}, {}
for _, o in ipairs(LCJ.Occupations) do
    LCJ.ById[o.id] = o
    LCJ.ByNum[o.num] = o
end
