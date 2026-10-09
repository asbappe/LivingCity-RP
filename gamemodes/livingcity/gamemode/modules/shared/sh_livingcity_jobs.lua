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
      desc = "Litter, bins, graffiti. The city must look clean, whatever it is." },
    { id = "kitchen", num = 2, name = "Ration Kitchen", place = "Ration kitchen",
      desc = "Prepare, carry and hand out the rations everybody lines up for." },
    { id = "medic", num = 3, name = "Clinic Medic", place = "Clinic", tools = { "weapon_medkit" },
      desc = "Patch people up. Write down what happened. Decide what really happened." },
    { id = "factory", num = 4, name = "Factory Worker", place = "Factory",
      desc = "Quotas, parts and loading docks. Nobody asks what the parts are for." },
    { id = "courier", num = 5, name = "Courier", place = "Post office",
      desc = "Letters, parcels and sealed envelopes to every block in the district." },
    { id = "maintenance", num = 6, name = "Maintenance Technician", place = "Maintenance yard",
      desc = "Fuse boxes, streetlights and Combine terminals. You see a lot of logs." },
    { id = "porter", num = 7, name = "Station Porter", place = "Train station",
      desc = "Luggage, tickets and new arrivals who don't know where anything is yet." },
    { id = "clerk", num = 8, name = "Records Clerk", place = "Civil records office", gameOnly = true,
      desc = "Stamps, files and identity forms. The cabinet with the blank ones is rarely locked." },
    { id = "laundry", num = 9, name = "Uniform Laundry", place = "Nexus laundry", gameOnly = true,
      desc = "Civil Protection uniforms, washed, pressed and counted. Usually counted." },
    { id = "mortuary", num = 10, name = "Mortuary Attendant", place = "City morgue",
      desc = "Collect the dead. Process what they leave behind. Nobody checks your work." },
    { id = "scrap", num = 11, name = "Reclamation Crew", place = "Reclamation yard",
      desc = "Scrap and rubble from the old city. Some of it was hidden there on purpose." },
    { id = "radio", num = 12, name = "Radio Repair", place = "Radio repair shop", gameOnly = true,
      desc = "Loudspeakers and Union radios. Some come in tuned to frequencies that don't exist." },
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
