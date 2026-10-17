--[[
    Living City: how the city feels to be in (the settings, shared)

    A person in a city too big for them, not a camera floating through a map.

      lc_fov          the widest view anyone gets (75, Half-Life 2's own;
                      players who run 90 or 100 see the world shrink).
                      0 leaves it to each player.
      lc_eye_height   where your eyes are, in units off the ground (61; GMod's
                      is 64). A little lower than everyone else's, so people
                      and units stand a touch over you.
      lc_view_bob     a faint sway in step with your feet, and a dip when you
                      land. Each player can turn theirs off (!bob).
                      lc_view_bob_amount (100, percent) sets how strong.
      lc_quiet_hud    no running score on screen: no XP bar or "+15 XP", no
                      credits or standing (they're at the top of your pockets,
                      F2), and hunger and thirst only show once they're low.

    The camera is cl_livingcity_view.lua, the eyes sv_livingcity_life.lua, the
    HUD cl_livingcity_needs.lua.
]]

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
CreateConVar("lc_fov", "75", FLAGS, "The widest field of view anyone sees (Half-Life 2's is 75); 0 leaves it to each player")
CreateConVar("lc_eye_height", "61", FLAGS, "Eye height in Civil Protection units (GMod's is 64): a little lower makes people and units stand over you")
CreateConVar("lc_view_bob", "1", FLAGS, "A faint camera sway in step with your feet, and a dip when you land (players can turn theirs off with !bob)")
CreateConVar("lc_view_bob_amount", "100", FLAGS, "How strong the camera sway and landing dip are, in percent (100 is the default, 50 half that)")
CreateConVar("lc_quiet_hud", "1", FLAGS, "No running score on screen: XP, credits and standing are in the menus, hunger and thirst show when they're low")

-- GMod's standing and crouched eyes are 64 and 28; the crouch comes down in proportion.
function LC.EyeHeights()
    local cv = GetConVar("lc_eye_height")
    local h = math.Clamp(cv and cv:GetFloat() or 64, 40, 72)
    return h, math.floor(28 * h / 64 + 0.5)
end
