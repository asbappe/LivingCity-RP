# The Miscount Poser: the hand-made poses, set by hand

The owner, 15 November: "I need a way to spawn a simulated NPC that is cuffed (actually, any/all NPC animations that are custom in this gamemode, including vortigaunt sweep animation/pose, etc) ... please add a new Miscount category tool via the tool menu, put it below the editor tool". Of the street vortigaunt: "no the broom is not in its claws." And then: "it might be easier for me to adjust the limbs with the physgun using the pose recorder tool than using sliders."

So the gamemode's hand-made poses are tuned in the game, by eye, and what is set is what the game then uses, with no coder in the middle.

## Using it

Q > Tools > Miscount > **Miscount Poser** (directly below the Miscount Editor). Superadmins only. It needs the **Pose Recorder** addon (`pose_recorder/`, version 2.1 or later) installed on the server: the mannequin and the measuring are its work. Without it the panel says so in one line, and every pose plays as it always did.

1. Pick a pose in the panel's list.
2. **Left click** where you aim: the pose's mannequin stands there. It is a ragdoll of the right model (not an NPC: it doesn't think and can't be hurt), already in the pose the game uses now, every limb frozen, and what it holds (a broom) a frozen prop in its place. Left click again: it is stood there instead (one mannequin each).
3. Move its limbs, and the broom itself, with the **physgun**. Whatever you let go of stays where it is.
4. **Right click** on the mannequin (or the broom): use this pose. It is measured in your own game, checked and kept on the server, and every real one in the game changes at once (a cuffed player, a sweeping vortigaunt).
5. **Reload** takes the mannequin away. It also goes when you leave, and it is never saved with the map.

The panel has **Held from** (for a pose that holds something: which bone the broom's place is measured from, a claw or hand, or the model's feet), **Reset this pose** (back to the built-in numbers) and **Copy the numbers** (the pose as text, on the clipboard and in the console, to send to a coder to make the new built-in). A pose that is set shows "yes" under "Set by hand".

The Pose Recorder's own tool (Tools > Poser) lists the same poses, as "Miscount: ...", and does the same.

## The poses

Each is one entry in `modules/shared/sh_livingcity_poses.lua`, read by the code that poses people through `LC.PoseBones(id)` and `LC.PoseProp(id, name)`. With nothing set these give exactly the numbers the code had before.

| Pose | On the mannequin | Built-in | May also be turned |
|---|---|---|---|
| Cuffed (`cuffed`) | citizen | the arms behind the back, from `lc_cuff_pose` | chest, head |
| Vortigaunt sweeping (`vort_sweep`) | shackled vortigaunt, with its broom | no bone turned; the broom worked out from its hands and the floor every tick | any of its bones |
| Stalker sweeping (`stalker_sweep`) | stalker, with its broom | the broom held from its feet, from `lc_broom_hold` | (the broom only) |
| Hand over the eyes, over the mouth (`hand_eyes`, `hand_mouth`) | citizen | the left arm, from `lc_handface_eyes` and `lc_handface_mouth` | |
| Drill: arms up (`drill_arms_up`) | citizen | both arms up, for the jump | chest, head, hands |
| Salute, crowd (`salute_crowd`) | citizen | the right arm; a limp salute is a part of it | right hand, chest, head |
| Salute, Careless Talk (`salute_talk`) | citizen | the right arm and hand | chest, head |
| Unit's bow (`review_bow`) | Civil Protection unit | head and chest | the arms |

- **The brooms.** Once the vortigaunt's broom is set by hand it hangs from that claw's own bone, at the place and angle measured, so the engine carries it with the claw through every animation; it is no longer worked out from the floor. Reset this pose brings that back. `lc_vort_broom_flip` only matters while it is worked out. The stalker's broom keeps `lc_broom_hold` as its built-in; a hold set by hand wins, and may hang from a hand's bone instead of the feet.
- **Settings still work.** `lc_cuff_pose`, `lc_handface_eyes`, `lc_handface_mouth` and `lc_broom_hold` are the built-in numbers of their poses; a bone or a hold set by hand wins over them.
- **What a mannequin can set.** Only bones a ragdoll has physics for: the chest, the head, the upper arms, forearms and hands (and hips and legs, which only the vortigaunt's pose accepts). Fingers and the neck have none: they keep the built-in. A bone measured as the code already has it (within a quarter of a degree) is not kept as set.
- **Not in the registry** (they are worked out every frame from the time, so there is no one pose to set): the kick, the fiddling at the cuffs, the dreams' figures (`cl_livingcity_dreamacting.lua`), and the endings' dances, which have their own tuner (the Endings menu).

## Where it is kept, and the checks

- **File:** `data/livingcity/poses.json` on the server (`LC.PoseFile`), written through the safe file writer a second after a change, read when the server starts. Sent to every player when they join and whenever a pose changes (`lc_poses`).
- **Checks, on the server** (`LC.PoseSet`, `LC.PoseReset`): a superadmin (whoever may edit the layout), a pose that exists, only that pose's own bones and held things, a bone the held thing may hang from, real numbers, angles brought within a half turn, a place at most 120 units from its bone. A held thing that fails the check keeps the hold it had.
- **Messages:** `lc_poses` (server to players), `lc_pose_reset` (the panel's button). The mannequin's own messages are the Pose Recorder's (`pose_recorder_target`, `pose_recorder_place`, `pose_recorder_take`, `pose_recorder_told`).
- **Code:** `modules/shared/sh_livingcity_poses.lua` (the registry, the checks, the bridge to the Pose Recorder), `modules/server/sv_livingcity_poses.lua` (keeping, sending, the mannequin), `lua/weapons/gmod_tool/stools/livingcity_pose.lua` (the tool). Tests: unit `PoseToolTests`, the Miscount Poser block of `_dev/client_smoke.py`, and `_dev/pose_recorder_tests.py` for the Pose Recorder's side.
