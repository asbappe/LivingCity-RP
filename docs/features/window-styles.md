# Window styles: every window in your faction's look

The owner, 10 November: "artistic overhauls of all UI items that are consistent enough across the gamemode while still having flavours based on the faction and context of what the pop up is about".

**What players see.** Every window (anything built as a `DFrame`) is drawn in one of four looks:

| Look | Who and where | What it is |
|---|---|---|
| `combine` | Civil Protection, the Administration, stalkers; and every Combine machine whoever uses it: terminal screens in the world (the Commissary, Civil Intake, Housing, Labor), their fallback windows, the records terminal, her tablet's market page | black glass, thin cyan lines, cut corners, a faint scan, "OVERWATCH LINK // SECTOR ACTIVE" |
| `rebel` | the Resistance; and their places whoever stands there: the quartermaster and black market window, the Resistance lab | rust and scrap plate, a heavy welded edge, rivets, a hazard stripe, "NO MASTERS NO BENEFACTORS" |
| `citizen` | citizens, shackled vortigaunts | a grey concrete slab, a faded blue edge, "UNION RESIDENT SERVICES", "FORM 27-B" |
| `custody` | anyone, in the interrogation's question window and while being patted down | black under a hard light, a red title bar, "DETAINED. ANSWER. COMPLY." |

**What follows the look:**
- every window (`DFrame`), its plain buttons, combo boxes and scroll bars;
- buttons that paint themselves: they keep their own colours (which often mean something) and get the look's trim over them (an edge bar, rivets, a slab foot, a hover outline), only when they drew themselves a full back;
- right-click menus and combo box lists (`DMenu`): a dark plate, the row under the cursor lit;
- the F1 / F2 quick menu (which holds the Administrator's tablet entries): your side's back behind it;
- terminal screens drawn in the world (`cl_livingcity_screens.lua`): always the Combine look;
- the notice card (`LC.Notice`): your side's plate and line, its coloured edge still saying what kind of notice it is.

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

**Not styled yet:** the rest of the HUD (needs bars, the many small on-screen panels spread over about forty files), and panels inside windows that paint themselves (cards, lists).
