--[[
    Flying a scanner from a Combine console (shared part): while you're linked,
    your keys steer the scanner, not your body, which stays where it is at the
    console for everyone to see. (sv_livingcity_scanner.lua, cl_livingcity_scanner.lua)
]]


LC = LC or {}

hook.Add("StartCommand", "LivingCityScannerLink", function(ply, cmd)
    local sc = ply:GetNW2Entity("lc_scanner")
    if not IsValid(sc) then return end
    if CLIENT then
        -- the keys have to reach the server to steer the scanner, so the client
        -- only stops the body walking off; the server takes the keys from there
        cmd:ClearMovement()
        return
    end
    if LC.ScannerInput then
        LC.ScannerInput(ply, {
            f = cmd:KeyDown(IN_FORWARD), b = cmd:KeyDown(IN_BACK), l = cmd:KeyDown(IN_MOVELEFT), r = cmd:KeyDown(IN_MOVERIGHT),
            up = cmd:KeyDown(IN_JUMP), down = cmd:KeyDown(IN_DUCK), fast = cmd:KeyDown(IN_SPEED),
            flash = cmd:KeyDown(IN_ATTACK), quit = cmd:KeyDown(IN_RELOAD) or cmd:KeyDown(IN_USE),
        })
    end
    -- the body stays put at the console
    cmd:ClearMovement()
    cmd:ClearButtons()
end)
