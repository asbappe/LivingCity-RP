# Window styles: every window in your faction's look

The owner, 10 November: "artistic overhauls of all UI items that are consistent enough across the gamemode while still having flavours based on the faction and context of what the pop up is about".

**What players see.** Every window (anything built as a `DFrame`) is drawn in one of four looks:

| Look | Who | What it is |
|---|---|---|
| `combine` | Civil Protection, the Administration, stalkers | black glass, thin cyan lines, cut corners, a faint scan, "OVERWATCH LINK // SECTOR ACTIVE" |
| `rebel` | the Resistance | rust and scrap plate, a heavy welded edge, rivets, a hazard stripe, "NO MASTERS NO BENEFACTORS" |
| `citizen` | citizens, shackled vortigaunts | a grey concrete slab, a faded blue edge, "UNION RESIDENT SERVICES", "FORM 27-B" |
| `custody` | anyone, in the interrogation's question window | black under a hard light, a red title bar, "DETAINED. ANSWER. COMPLY." |

Plain buttons, combo boxes and scroll bars inside a window follow its look. The Civil Orientation pamphlet keeps its own paper look.

**Setting (client):** `lc_ui_theme` (1). 0 and every window is as it was before.

**How it works (`cl_livingcity_theme.lua`).**
- It wraps `vgui.Create`. A new `DFrame` is given the "LivingCity" Derma skin (the default skin with frames, buttons, combo boxes and scroll bars repainted), which its children inherit.
- A tick later, if the window has a Paint of its own, that Paint is wrapped: the themed back is drawn first, then the window's own Paint runs with its full-window box and its title strip left out (`draw.RoundedBox`, `draw.RoundedBoxEx` and `surface.DrawRect` at 0,0 covering the window or a 18 to 30 tall strip). Everything else it draws is kept.
- The look is the panel's own (`LC_CL.SetTheme(panel, "custody")`), else its window's, else yours by faction (`LC_CL.ThemeName`).
- `panel.lcNoTheme = true` (set right after creating it) opts a window out.
- If painting a back ever errors, styles switch themselves off for the session (`LC_CL.ThemeBroken`) and a line is printed to the console.
- The backs are pictures, `materials/livingcity/ui/combine.jpg`, `rust.jpg`, `concrete.jpg` (made by `node _dev/posters/ui.js OUTDIR`, sent to players at map start). Without them, flat colour.

**Not styled yet:** buttons and panels that paint themselves, right-click menus, the HUD, and popups that are not `DFrame`s.
