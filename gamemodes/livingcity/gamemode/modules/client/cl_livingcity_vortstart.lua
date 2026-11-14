--[[
    Living City: the choice at a new life's start (sv_livingcity_vortstart.lua)

    Two cards side by side: a citizen of the city, or a shackled vortigaunt. A citizen goes on to the
    character screen (or the train and Civil Intake) as before; a vortigaunt wakes in its collar.
]]

LC_CL = LC_CL or {}

local INK, DIM, ACCENT, GREEN = Color(235, 230, 220), Color(170, 165, 155), Color(230, 200, 120), Color(150, 210, 120)

local function Wrap(text, font, w)
    if LC_CL.WrapPlain then return LC_CL.WrapPlain(text, font, w) end
    return { text }
end

local CHOICES = {
    { id = "citizen", title = "A citizen", col = ACCENT, model = "models/humans/group01/male_07.mdl",
      text = "You come in on the train with nothing, are registered at Civil Intake, and make what life you can in the city: work for the Union, keep your head down, or find the Resistance. Any side is open to you." },
    { id = "vort", title = "A vortigaunt", col = GREEN, model = "models/vortigaunt.mdl",
      text = "You are Combine property: collared, shackled, put to the city's dirtiest labour. After a few minutes of it you can reach out through the vortessence, and the Resistance may come to cut you loose. Once free you fight with them. A vortigaunt is never human, and never becomes one." },
}

function LC_CL.OpenRacePick()
    if IsValid(LC_CL.RaceFrame) then LC_CL.RaceFrame:Remove() end
    local W, H = math.min(ScrW() - 40, 820), math.min(ScrH() - 40, 520)
    local f = vgui.Create("DFrame")
    LC_CL.RaceFrame = f
    if LC_CL.SetTheme then LC_CL.SetTheme(f, "ooc") end
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetSize(W, H)
    f:Center()
    f:MakePopup()
    f.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(22, 20, 18, 250))
        draw.SimpleText("A NEW LIFE: WHO ARE YOU?", "DermaLarge", 20, 14, ACCENT)
        draw.SimpleText("Chosen once, for this life.", "DermaDefault", w - 20, 26, DIM, TEXT_ALIGN_RIGHT)
    end
    local cw = (W - 60) / 2
    for i, c in ipairs(CHOICES) do
        local card = vgui.Create("DPanel", f)
        card:SetPos(20 + (i - 1) * (cw + 20), 60)
        card:SetSize(cw, H - 80)
        local lines = Wrap(c.text, "DermaDefault", cw - 24)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(36, 32, 28, 245))
            draw.SimpleText(c.title, "DermaLarge", 12, 10, c.col)
            local y = h - 70 - #lines * 16
            for _, l in ipairs(lines) do draw.SimpleText(l, "DermaDefault", 12, y, INK) y = y + 16 end
        end
        local mp = vgui.Create("DModelPanel", card)
        mp:SetPos(10, 48)
        mp:SetSize(cw - 20, H - 80 - 48 - 80 - #lines * 16)
        mp:SetModel(c.model)
        mp:SetFOV(38)
        local b = vgui.Create("DButton", card)
        b:SetPos(12, H - 80 - 56)
        b:SetSize(cw - 24, 42)
        b:SetText(i == 1 and "Be a citizen" or "Be a vortigaunt")
        b.DoClick = function()
            net.Start("lc_race_chosen")
            net.WriteString(c.id)
            net.SendToServer()
            f:Remove()
        end
    end
    return f
end

net.Receive("lc_race_pick", function() LC_CL.OpenRacePick() end)
