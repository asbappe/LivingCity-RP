# Pose Recorder

A Garry's Mod tool for turning ragdoll poses into bone animation for code.

Pose a ragdoll with the physgun, snap it as a keyframe (or record it moving), and the tool works out each bone's angle the way `Entity:ManipulateBoneAngles` wants it: **relative to the model standing in its normal idle**, so the pose plays back on a live player or NPC. A blue ghost beside the ragdoll plays your keyframes back as a loop, to the beat, so you can see the result before you use it. Copy it to the clipboard or save it as JSON.

Made for [Living City](../README.md) (its secret endings' dances), and useful to anyone writing emotes, dances, taunts or cutscenes in Lua.

## Using it

1. **Tools, Poser, Pose Recorder.**
2. **Spawn a mannequin** from the tool's panel (your own model, standing, every limb frozen), or **left click** any ragdoll.
3. Pose it with the **physgun** (right click freezes a limb where you leave it).
4. **Right click** with the Pose Recorder to snap a keyframe. Pose it again, snap again. Each keyframe is held for its "beats per new keyframe" (set it before you snap).
5. **Reload** plays the loop on the ghost beside the ragdoll at your BPM. Reload again stops it.
6. **Copy to the clipboard** or **Save** (to `garrysmod/data/pose_recorder/<name>.json`); **Load** brings a saved one back to play or carry on with.

Or **Record / stop**: it samples the ragdoll as you move it (10 times a second by default), with timestamps instead of beats.

**Relative to:** players stand in `idle_all_01`, so that's the default. For an NPC that idles in another sequence, pick "NPC idle", or type any sequence name into `pose_recorder_ref`. "Reference pose" measures from the model's bind pose (for a model that isn't animating).

Only the bones a ragdoll can be posed by are recorded: on a player model that's the pelvis, the chest, the head, the upper arms, forearms and hands, the thighs, calves and feet. Bones without physics (fingers, the neck, the lower spine) are left as the idle has them.

## The file

```json
{
  "tool": "Pose Recorder 1.0",
  "name": "mydance",
  "model": "models/player/kleiner.mdl",
  "ref": "idle_all_01",
  "bpm": 120,
  "mode": "keys",
  "frames": [
    { "beats": 1, "bones": { "ValveBiped.Bip01_R_UpperArm": [ -40.2, -12.5, 3.1 ], "...": [] } },
    { "beats": 1, "bones": { "...": [] } }
  ]
}
```

Each bone's three numbers are pitch, yaw and roll, ready for `ent:ManipulateBoneAngles(ent:LookupBone(name), Angle(p, y, r))`. A recording (`"mode": "rec"`) has `"t"` (seconds) on each frame instead of `"beats"`.

Playing it back yourself: ease from each keyframe to the next over its beats (the tool uses smoothstep on each of the three angles), and apply the result every frame on the client. `PoseRecorder.Sample(frames, beat)` in `lua/pose_recorder/core.lua` does exactly that, and has no engine calls in it, so you can copy it into your own code.

## Console

`pose_recorder_mannequin`, `pose_recorder_snap`, `pose_recorder_undo`, `pose_recorder_record`, `pose_recorder_preview`, `pose_recorder_clear`, `pose_recorder_copy`, `pose_recorder_save`, `pose_recorder_load`; settings `pose_recorder_name`, `pose_recorder_bpm`, `pose_recorder_beats`, `pose_recorder_ref`, `pose_recorder_rate`.

## Publishing it to the Workshop (Linux)

From `garrysmod/../bin` (where `gmad_linux` and `gmpublish_linux` are), with this folder copied to `pose_recorder/` beside them and a 512x512 JPEG icon:

```
./gmad_linux create -folder pose_recorder -out pose_recorder.gma
./gmpublish_linux create -addon pose_recorder.gma -icon pose_recorder.jpg
```

Steam must be running and logged in. `gmpublish_linux update -addon pose_recorder.gma -id <the id it printed>` uploads a new version later.
