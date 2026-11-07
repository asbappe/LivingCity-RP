# Pose Recorder

A Garry's Mod tool for making your own animations from ragdoll poses, smoothing them, and playing them on yourself or any NPC for everyone on the server to see. No coder needed.

Pose a ragdoll with the physgun, snap it as a keyframe (or record it moving), and the tool works out each bone's angle the way `Entity:ManipulateBoneAngles` wants it: **relative to the model standing in its normal idle**, so the pose plays back on a live player or NPC. A blue ghost beside the ragdoll plays your keyframes back as a loop, to the beat, so you can see the result as you work. Then play it on yourself, put it on an NPC from the context menu, save it, share it as a small file, or bundle a pack of them in your own addon.

**The limit:** these are bone turns on top of the model's idle, not compiled animations, so they can't change walking or running. (Exporting real animation files, SMD, for modelers is a separate, later project.)

Made for [Living City](../README.md) (its secret endings' dances), and useful to anyone making emotes, dances, taunts, cutscenes or screenshots.

## Workshop description

> **Pose Recorder: make animations from ragdoll poses, and play them for everyone.**
> Tools, Poser, Pose Recorder. Spawn a mannequin, pose it with the physgun, snap keyframes (or record it moving) and watch a ghost play the loop beside it. Smooth it with buttons: each keyframe's length and easing (smooth, snappy, bouncy, linear), mirror left and right, wrap the loop or stop on the last pose. Play it on yourself or, from the context menu, on any NPC: everyone sees it, looping, once, or holding the last pose, at any speed. Animations are small files you can send to friends; put a folder of them in your own addon's `data_static/pose_recorder/` and everyone with that addon gets them. Lua coders: `PoseRecorder.Play(ent, "wave")`.
> These are bone turns on top of the model's idle, not compiled animations, so they can't change walking or running.

## Making one

1. **Tools, Poser, Pose Recorder.**
2. **Spawn a mannequin** from the tool's panel (your own model, standing, every limb frozen), or **left click** any ragdoll.
3. Pose it with the **physgun** (right click freezes a limb where you leave it).
4. **Right click** with the Pose Recorder to snap a keyframe. Pose it again, snap again. Each new keyframe gets the panel's "beats per new keyframe" and "easing for new keyframes".
5. **Reload** plays the loop on the ghost beside the ragdoll at your BPM. Reload again stops it.
6. **Copy to the clipboard** or **Save** (to `garrysmod/data/pose_recorder/<name>.json`); **Load** brings a saved one back to play or carry on with.

Or **Record / stop**: it samples the ragdoll as you move it (10 times a second by default), with timestamps instead of beats.

**Relative to:** players stand in `idle_all_01`, so that's the default. For an NPC that idles in another sequence, pick "NPC idle", or type any sequence name into `pose_recorder_ref`. "Reference pose" measures from the model's bind pose (for a model that isn't animating).

Only the bones a ragdoll can be posed by are recorded: on a player model that's the pelvis, the chest, the head, the upper arms, forearms and hands, the thighs, calves and feet. Bones without physics (fingers, the neck, the lower spine) are left as the idle has them.

## Smoothing (buttons in the panel)

The panel lists your keyframes with each one's length and easing. Pick one or more (none picked means all of them), then:

- **Give them the beats per new keyframe:** each keyframe's length.
- **Give them the easing for new keyframes:** how it moves into the next keyframe. **Smooth** eases out and in (the default, and how the first version always played), **snappy** is off the mark at once and settles gently, **bouncy** swings a little past the next pose and settles back, **linear** moves at an even speed.
- **Mirror them:** left and right swapped (the right arm's pose goes to the left arm, and the other way round; the head and spine tilt and twist the other way).
- **Add a mirrored copy of the whole loop on the end:** wave with the right hand, then the left.
- **Wrap:** on, the last keyframe eases back into the first; off, the loop stops on the last keyframe, held for its beats.

## Playing it, seen by everyone

- **On yourself:** in the panel, pick how it plays (**loop**, **once** then back to normal, or **hold** the last pose) and a **speed**, then **Play what I'm making on me** (it needn't be saved), or pick one of your saved animations or the server's in the list and **Play the picked one on me**. **Stop mine** stops it.
- **On an NPC:** hold the context menu key (C), right click the NPC, **Play animation**, and pick one. **Stop animation** is there while it plays.
- Console extras: `pose_play <name> [loop|once|hold] [speed]` and `pose_stop`.

How it works: the server only sends "this entity plays this animation from this moment, looping, at this speed"; each player's game eases the bones itself. Someone who joins later sees what's already playing, at the same point. Your own animation is sent to the server once, checked, and passed on to the others.

Server settings: `pose_recorder_play_self` (players may play animations on themselves, default 1), `pose_recorder_play_npcs` (0 nobody, 1 anyone allowed to use the context menu on that NPC, 2 admins; default 1), `pose_recorder_uploads` (players may play their own animations, not just the server's packs; default 1). A server's Lua can decide with the hook `PoseRecorderCanPlay(ply, ent)` (return true or false). An animation stops when the player dies.

## Sharing

- **A friend:** send them your `garrysmod/data/pose_recorder/<name>.json`; they put it in theirs and it's in their list.
- **A pack:** put the files in your own addon's `data_static/pose_recorder/` folder (for example `myaddon/data_static/pose_recorder/wave.json`). Every server and player with that addon finds them on start; the server offers them to everyone in the panel's list and the context menu. A server can also drop files into its own `garrysmod/data/pose_recorder/`. (`pose_recorder_reload_packs` reads them again without a restart, for admins.)
- **Lua coders:**

```lua
PoseRecorder.Play(ent, "wave")                                  -- on the server: everyone sees it
PoseRecorder.Play(ent, "wave", { mode = "once", speed = 1.5 })  -- mode: "loop", "once" or "hold"
PoseRecorder.Stop(ent)
PoseRecorder.Register("wave", data)  -- (server) add one from a table, as a saved file has it
PoseRecorder.Get("wave")             -- the checked animation, or nil
PoseRecorder.PlayingOn(ent)          -- name, mode, speed, start time, or nil
```

On a client, `PoseRecorder.Play` plays it only on that client's screen (handy for a clientside model in a menu).

Every file, from a friend, a pack or a player, is checked before it's used: at most 600 keyframes, 80 bones each, plain numbers only (no NaN or infinity), sensible lengths, known easing names, and 256 KB of text. A broken file is turned down with the reason, and never played.

## The file

```json
{
  "tool": "Pose Recorder 2.0",
  "format": 2,
  "name": "mydance",
  "model": "models/player/kleiner.mdl",
  "ref": "idle_all_01",
  "bpm": 120,
  "mode": "keys",
  "wrap": true,
  "frames": [
    { "beats": 1, "ease": "smooth", "bones": { "ValveBiped.Bip01_R_UpperArm": [ -40.2, -12.5, 3.1 ], "...": [] } },
    { "beats": 2, "ease": "bouncy", "bones": { "...": [] } }
  ]
}
```

Each bone's three numbers are pitch, yaw and roll, ready for `ent:ManipulateBoneAngles(ent:LookupBone(name), Angle(p, y, r))`. A recording (`"mode": "rec"`) has `"t"` (seconds) on each frame instead of `"beats"` and `"ease"`.

Versions: a file from the first Pose Recorder has no `"format"`, `"wrap"` or `"ease"`; it loads and plays exactly as before (smooth easing, wrapping round). The first version reads a new file too (it ignores what it doesn't know).

Playing it back yourself: `PoseRecorder.Evaluate(anim, seconds, { mode = "loop", speed = 1 })` in `lua/pose_recorder/core.lua` gives the pose and how much of it to apply, and `PoseRecorder.Sample(frames, beat, wrap)` the pose at a beat. They have no engine calls in them, so you can copy them into your own code.

## Console

Making: `pose_recorder_mannequin`, `pose_recorder_snap`, `pose_recorder_undo`, `pose_recorder_record`, `pose_recorder_preview`, `pose_recorder_clear`, `pose_recorder_copy`, `pose_recorder_save`, `pose_recorder_load`; smoothing: `pose_recorder_key_beats <beats> [keyframe|all]`, `pose_recorder_key_ease <smooth|snappy|bouncy|linear> [keyframe|all]`, `pose_recorder_mirror [keyframe|all]`, `pose_recorder_mirror_add`; playing: `pose_recorder_play_mine`, `pose_play`, `pose_stop`; settings `pose_recorder_name`, `pose_recorder_bpm`, `pose_recorder_beats`, `pose_recorder_ease`, `pose_recorder_wrap`, `pose_recorder_ref`, `pose_recorder_rate`, `pose_recorder_playmode`, `pose_recorder_speed`.

## Publishing it to the Workshop (Linux)

From `garrysmod/../bin` (where `gmad_linux` and `gmpublish_linux` are), with this folder copied to `pose_recorder/` beside them and a 512x512 JPEG icon:

```
./gmad_linux create -folder pose_recorder -out pose_recorder.gma
./gmpublish_linux create -addon pose_recorder.gma -icon pose_recorder.jpg
```

Steam must be running and logged in. `gmpublish_linux update -addon pose_recorder.gma -id <the id it printed>` uploads a new version later.
