# Window styles: every window in your faction's look

The owner, 10 November: "artistic overhauls of all UI items that are consistent enough across the gamemode while still having flavours based on the faction and context of what the pop up is about".

**What players see.** Every window (anything built as a `DFrame`) is drawn in one of four looks:

| Look | Who and where | What it is |
|---|---|---|
| `combine` | Civil Protection, stalkers; and every Combine machine whoever uses it: terminal screens in the world (the Commissary, Civil Intake, Housing, Labor), their fallback windows, the records terminal, her tablet's market page | black glass, thin cyan lines, cut corners, a faint scan, "OVERWATCH LINK // SECTOR ACTIVE" |
| `rebel` | the Resistance; and their places whoever stands there: the quartermaster's window, the Resistance lab | rust and scrap plate, a heavy welded edge, rivets, a hazard stripe, "NO MASTERS NO BENEFACTORS" |
| `citizen` | citizens, shackled vortigaunts | a grey concrete slab, a faded blue edge, "UNION RESIDENT SERVICES", "FORM 27-B" |
| `custody` | anyone, in the interrogation's question window and while being patted down | black under a hard light, a red title bar, "DETAINED. ANSWER. COMPLY." |
| `office` | the Administration (her faction), by default | the Combine glass in the posters' ivory and red, "OFFICE OF THE CITY ADMINISTRATOR" |
| `scrap` | the black market dealer's window, whoever buys (the dealer isn't Resistance) | rust with nobody's mark, duller, "NO QUESTIONS" |
| `vort` | free vortigaunts (a Resistance member whose role is `vortigaunt`) | green dark, veins of light, a glow from the foot, three eyes, "THE VORTESSENCE" |
| `bound` | shackled vortigaunts (the `vort` faction) | the same green, under the Combine's cyan line, "COLLARED. PROPERTY OF THE COMBINE." |
| `staff`, `ooc` | staff tools (Staff, Admin testing tools, the performance debugger, the endings tuner, the debug report); choosing and making a character | plain charcoal, nobody's side, "STAFF // OUT OF CHARACTER" in amber, or "OUT OF CHARACTER" |

**The Resistance's lambda.** Windows in the `rebel` look (a Resistance member's own windows, the quartermaster's, the lab's) have a yellow lambda sprayed by hand over the rust, bottom right (`materials/livingcity/ui/lambda.png`, `lambda = 150` in the look). The dealer's `scrap` look has none, so the two are told apart at a glance.

Each look names a way of being drawn (`style`: combine, rebel, citizen, custody, vort, plain), so a new look is a row of colours and words.

**What follows the look:**
- every window (`DFrame`), its plain buttons, combo boxes and scroll bars;
- buttons that paint themselves: they keep their own colours (which often mean something) and get the look's trim over them (an edge bar, rivets, a slab foot, a hover outline), only when they drew themselves a full back;
- right-click menus and combo box lists (`DMenu`): a dark plate, the row under the cursor lit;
- the F1 / F2 quick menu (which holds the Administrator's tablet entries): your side's back behind it;
- terminal screens drawn in the world (`cl_livingcity_screens.lua`): always the Combine look;
- the notice card (`LC.Notice`): your side's plate and line, its coloured edge still saying what kind of notice it is.
- **the whole HUD:** every dark panel drawn on the screen (behind needs, tips, timers, cards, job panels and the rest) is your side's plate, at the same fade as before. Bars, coloured edges and fills, and full-screen fades are untouched.

The Civil Orientation pamphlet keeps its own paper look.

**Setting (client):** `lc_ui_theme` (1). 0 and every window is as it was before.

**How it works (`cl_livingcity_theme.lua`).**
- It wraps `vgui.Create`. A new `DFrame` is given the "LivingCity" Derma skin (the default skin with frames, buttons, combo boxes and scroll bars repainted), which its children inherit.
- A tick later, if the window has a Paint of its own, that Paint is wrapped: the themed back is drawn first, then the window's own Paint runs with its full-window box and its title strip left out (`draw.RoundedBox`, `draw.RoundedBoxEx` and `surface.DrawRect` at 0,0 covering the window or a 18 to 30 tall strip). Everything else it draws is kept.
- The look is the panel's own (`LC_CL.SetTheme(panel, "custody")`), else its window's, else yours by faction (`LC_CL.ThemeName`).
- `panel.lcNoTheme = true` (set right after creating it) opts a window out.
- If painting a back ever errors, styles switch themselves off for the session (`LC_CL.ThemeBroken`) and a line is printed to the console.
- The backs are pictures, `materials/livingcity/ui/combine.jpg`, `rust.jpg`, `concrete.jpg` (made by `node _dev/posters/ui.js OUTDIR`, sent to players at map start). Without them, flat colour.

- A popup that is not a `DFrame` asks for it: `LC_CL.ThemeWindow(panel, "DPanel")`. Something drawn straight on the screen asks for a back: `LC_CL.PaintThemePanel(x, y, w, h, headHeight, name)`.
- A new `DButton` waits one frame (a `Think` hook), then, if it has a Paint of its own and sits inside a styled window, that Paint is wrapped to add the trim.

- **The HUD.** About forty files draw the HUD, each with its own dark `draw.RoundedBox` behind its words. While the HUD is being painted (between the `HUDPaintBackground` and `PostDrawHUD` hooks) `draw.RoundedBox` and `draw.RoundedBoxEx` restyle a box that is dark (red and green 60 or less, blue 64 or less, alpha 40 or more), at least 100 by 20, and less than 35% of the screen: it is filled in the look's colour at the box's own alpha, with a small trim (cyan line and brackets; orange line and rivets; a slab foot and blue edge). Anything else passes through. HUD backs drawn with `surface.DrawRect` are not caught.

**Not styled yet:** panels inside windows that paint themselves (cards, lists), and HUD backs drawn with `surface.DrawRect` rather than `draw.RoundedBox`.
