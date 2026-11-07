"""
Pose Recorder tests (the separate addon in ../pose_recorder), offline with lupa:
  - the maths in lua/pose_recorder/core.lua: easing, the loop with wrap or stop, playing
    loop / once / hold at a speed, mirroring left and right, and checking files
    (old files still load; broken or hostile ones are turned down)
  - a file's round trip through JSON
  - lua/pose_recorder/play.lua with a fake server and two fake clients joined by a fake
    network: packs found on the server, a player's own animation sent up and checked, the
    play message reaching everyone, a late joiner seeing what's already playing, and each
    client turning the bones itself
Run from the repo root: python3 _dev/pose_recorder_tests.py (ends POSE RECORDER TESTS PASS)
"""
import json, math, os, sys
from lupa import luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
PR_DIR = os.path.join(HERE, "..", "pose_recorder", "lua", "pose_recorder")
CORE = open(os.path.join(PR_DIR, "core.lua")).read()
PLAY = open(os.path.join(PR_DIR, "play.lua")).read()
STUB = open(os.path.join(HERE, "gmod_stub.lua")).read()

passed, failed = 0, []


def ok(cond, what):
    global passed
    if cond:
        passed += 1
    else:
        failed.append(what)
        print("FAIL " + what)


def to_py(v):
    """A Lua table as JSON-able Python (a list when its keys are 1..n), as util.TableToJSON does."""
    if lj.lua_type(v) != "table":
        return v
    keys = list(v.keys())
    if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [to_py(v[i]) for i in range(1, len(keys) + 1)]
    return {str(k): to_py(v[k]) for k in keys}


def two(r):
    """A Lua call's result as (first, second): a call returning one value comes back bare."""
    if isinstance(r, tuple):
        return (r + (None, None))[:2]
    return r, None


def runtime(realm):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute(STUB)
    lt = L.eval("function(t) return t end")

    def from_py(x):
        if isinstance(x, dict):
            t = L.table()
            for k, v in x.items():
                t[k] = from_py(v)
            return t
        if isinstance(x, list):
            t = L.table()
            for i, v in enumerate(x):
                t[i + 1] = from_py(v)
            return t
        return x

    def t2j(t, pretty=False):
        return json.dumps(to_py(t), allow_nan=True)

    def j2t(s):
        try:
            return from_py(json.loads(s))
        except Exception:
            return None

    L.globals().util.TableToJSON = t2j
    L.globals().util.JSONToTable = j2t
    L.execute("""
        SERVER, CLIENT = %s, %s
        util.Decompress = function(s, max) if max and #s > max then return nil end return s end
        net.ReadData = function() return table.remove(net._q, 1) end
        net.WriteDouble, net.ReadDouble = net.WriteFloat, net.ReadFloat
        CreateClientConVar = function(n, d) return CreateConVar(n, d) end
        chat = { AddText = function(...) _said = { ... } end }
        function Color(r, g, b, a) return { r = r, g = g, b = b, a = a } end
        _ents = {}
        function FakeEnt(id, model, npc)
            local e = { id = id, manip = {}, valid = true }
            e.IsValid = function(s) return s.valid end
            e.GetModel = function() return model or "models/player/kleiner.mdl" end
            e.LookupBone = function(_, n)
                local ids = { ["ValveBiped.Bip01_Pelvis"] = 0, ["ValveBiped.Bip01_R_UpperArm"] = 1, ["ValveBiped.Bip01_L_UpperArm"] = 2 }
                return ids[n]
            end
            e.ManipulateBoneAngles = function(_, b, a) e.manip[b] = a end
            e.IsNPC = function() return npc == true end
            e.IsPlayer = function() return npc ~= true end
            e.IsAdmin = function() return false end
            e.SteamID64 = function() return "7656" .. id end
            e.UserID = function() return id end
            _ents[id] = e
            return e
        end
    """ % ("true" if realm == "server" else "false", "true" if realm == "client" else "false"))
    L.execute(CORE)
    return L


# ----------------------------------------------------------------------------------------
# The maths
# ----------------------------------------------------------------------------------------
L = runtime("none")
PR = L.globals().PoseRecorder
E = PR.Ease
for name in ("smooth", "snappy", "bouncy", "linear"):
    ok(abs(E[name](0)) < 1e-9 and abs(E[name](1) - 1) < 1e-9, "easing %s starts at 0 and ends at 1" % name)
ok(abs(E.smooth(0.5) - 0.5) < 1e-9 and E.smooth(0.25) < 0.25, "smooth eases in slowly")
ok(E.snappy(0.25) > 0.6, "snappy is most of the way there early")
ok(max(E.bouncy(x / 20.0) for x in range(21)) > 1.05, "bouncy swings past the next pose")
ok(abs(E.linear(0.3) - 0.3) < 1e-9, "linear is even")

frames = L.eval("""{
    { beats = 2, ease = "linear", bones = { ["ValveBiped.Bip01_R_UpperArm"] = { 0, 0, 0 } } },
    { beats = 1, bones = { ["ValveBiped.Bip01_R_UpperArm"] = { 0, 90, 0 } } },
}""")
ok(abs(PR.Sample(frames, 1)["ValveBiped.Bip01_R_UpperArm"][2] - 45) < 1e-6, "linear keyframe: half way at half its beats")
ok(abs(PR.Sample(frames, 2.5)["ValveBiped.Bip01_R_UpperArm"][2] - 45) < 1e-6, "wrap: the last keyframe eases back to the first (no ease field: smooth)")
ok(abs(PR.Sample(frames, 2.5, False)["ValveBiped.Bip01_R_UpperArm"][2] - 90) < 1e-6, "wrap off: the last keyframe holds")
ok(abs(PR.Sample(frames, 3)["ValveBiped.Bip01_R_UpperArm"][2]) < 1e-6, "the loop goes round")
old = L.eval("""{ { beats = 1, bones = { a = { 0, 0, 0 } } }, { beats = 1, bones = { a = { 0, 80, 0 } } } }""")
ok(abs(PR.Sample(old, 0.25)["a"][2] - 80 * 0.15625) < 1e-6, "a keyframe without easing is smooth, as in the first version")

anim = L.eval("""{ mode = "keys", bpm = 60, wrap = false, frames = {
    { beats = 1, ease = "linear", bones = { a = { 0, 0, 0 } } },
    { beats = 1, ease = "linear", bones = { a = { 0, 60, 0 } } },
    { beats = 2, bones = { a = { 0, 30, 0 } } },
} }""")
ok(abs(PR.Duration(anim) - 4) < 1e-9 and abs(PR.LastKeyTime(anim) - 2) < 1e-9, "duration and when the last keyframe is reached")
pose, w, done = PR.Evaluate(anim, 0.1, L.eval("{ mode = 'loop' }"))
ok(abs(w - 0.5) < 1e-6 and not done, "it eases in from the idle over the first moment")
pose, w, done = PR.Evaluate(anim, 0.5, L.eval("{ mode = 'loop', speed = 2 }"))
ok(abs(pose["a"][2] - 60) < 1e-6 and w == 1, "speed 2: a second's keyframe in half a second")
pose, w, done = PR.Evaluate(anim, 9, L.eval("{ mode = 'hold' }"))
ok(abs(pose["a"][2] - 30) < 1e-6 and not done, "hold: stays in the last pose")
pose, w, done = PR.Evaluate(anim, 4.1, L.eval("{ mode = 'once' }"))
ok(abs(pose["a"][2] - 30) < 1e-6 and 0 < w < 1 and not done, "once: eases back out after one pass")
pose, w, done = PR.Evaluate(anim, 5, L.eval("{ mode = 'once' }"))
ok(done and w == 0, "once: over after one pass")
pose, w, done = PR.Evaluate(anim, 500, L.eval("{ mode = 'loop' }"))
ok(not done, "loop never ends")
rec = L.eval("""{ mode = "rec", frames = { { t = 0, bones = { a = { 0, 0, 0 } } }, { t = 2, bones = { a = { 0, 40, 0 } } } } }""")
pose = PR.Evaluate(rec, 1, L.eval("{ speed = 1 }"))[0]
ok(abs(pose["a"][2] - 20) < 1e-6, "a recording plays straight between samples")

# mirroring
ok(PR.MirrorName("ValveBiped.Bip01_L_UpperArm") == "ValveBiped.Bip01_R_UpperArm", "mirror name: left to right")
ok(PR.MirrorName("ValveBiped.Bip01_R_Finger12") == "ValveBiped.Bip01_L_Finger12", "mirror name: right finger to left")
ok(PR.MirrorName("ValveBiped.Bip01_Spine2") == "ValveBiped.Bip01_Spine2", "mirror name: the spine stays")
ok(PR.MirrorName("hand.L") == "hand.R" and PR.MirrorName("Arm_R") == "Arm_L", "mirror name: other naming styles")
m = PR.MirrorAngles("ValveBiped.Bip01_R_UpperArm", L.eval("{ -40, -60, 15 }"))
ok(m[1] == 40 and m[2] == -60 and m[3] == -15, "an arm out to the side (pitch) flips, raised forward (yaw) stays: the owner's bone notes")
m = PR.MirrorAngles("ValveBiped.Bip01_Head1", L.eval("{ 10, 20, 30 }"))
ok(m[1] == 10 and m[2] == -20 and m[3] == -30, "the head: a nod stays, a tilt and a twist flip")
pose = L.eval("""{ ["ValveBiped.Bip01_R_UpperArm"] = { -40, -60, 15 }, ["ValveBiped.Bip01_Spine2"] = { 5, 10, 20 } }""")
mp = PR.MirrorPose(pose)
ok(mp["ValveBiped.Bip01_R_UpperArm"] is None and mp["ValveBiped.Bip01_L_UpperArm"][1] == 40, "the right arm's turn moves to the left arm")
back = PR.MirrorPose(mp)
ok(all(abs(back[n][i] - pose[n][i]) < 1e-9 for n in ("ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2") for i in (1, 2, 3)),
   "mirrored twice is the pose again")
mf = PR.MirrorFrames(L.eval("{ { beats = 3, ease = 'bouncy', bones = { ['ValveBiped.Bip01_L_Hand'] = { 1, 2, 3 } } } }"))
ok(mf[1].beats == 3 and mf[1].ease == "bouncy" and mf[1].bones["ValveBiped.Bip01_R_Hand"] is not None, "mirrored keyframes keep their length and easing")

# checking files
v1 = L.eval("""{ tool = "Pose Recorder 1.0", name = "My Dance", model = "models/player/kleiner.mdl", ref = "idle_all_01", bpm = 120, mode = "keys",
    note = "x", frames = { { beats = 1, bones = { ["ValveBiped.Bip01_R_UpperArm"] = { -40.2, -12.5, 3.1 } } }, { beats = 2, bones = {} } } }""")
c, err = two(PR.Sanitize(v1))
ok(c is not None and c.format == 2 and c.wrap is True and c.frames[1].ease == "smooth" and c.name == "my_dance" and c.note is None,
   "a first-version file loads: smooth, wrapping, its name cleaned, unknown fields dropped (%s)" % err)
ok(c is not None and abs(c.frames[1].bones["ValveBiped.Bip01_R_UpperArm"][1] + 40.2) < 1e-9, "its angles are kept")


def bad(src, what):
    c, err = two(PR.Sanitize(L.eval(src)))
    ok(c is None and err, "turned down: " + what)


bad("{ frames = { { beats = 1, bones = { a = { 0/0, 0, 0 } } } } }", "a NaN angle")
bad("{ frames = { { beats = 1, bones = { a = { math.huge, 0, 0 } } } } }", "an infinite angle")
bad("{ frames = { { beats = 1, bones = { a = { 1e12, 0, 0 } } } } }", "an enormous angle")
bad("{ frames = { { beats = 1, bones = { a = { '5', 0, 0 } } } } }", "a number written as text")
bad("{ frames = { { beats = 1, bones = { a = { 1, 2 } } } } }", "an angle missing a number")
bad("{ frames = { { beats = 1, bones = { ['bad\\nname'] = { 1, 2, 3 } } } } }", "a bone name with a line break")
bad("{ frames = { { beats = 1, bones = { [string.rep('x', 100)] = { 1, 2, 3 } } } } }", "a very long bone name")
bad("{ frames = {} }", "no keyframes")
bad("{ frames = { x = { beats = 1, bones = {} } } }", "keyframes that aren't a list")
bad("(function() local f = {} for i = 1, 601 do f[i] = { beats = 1, bones = {} } end return { frames = f } end)()", "too many keyframes")
bad("(function() local b = {} for i = 1, 81 do b['b' .. i] = { 0, 0, 0 } end return { frames = { { bones = b } } } end)()", "too many bones")
bad("{ mode = 'rec', frames = { { t = 1, bones = {} }, { t = 0.5, bones = {} } } }", "a recording going backwards in time")
bad("{ mode = 'rec', frames = { { t = 1e5, bones = {} } } }", "a recording hours long")
bad("'not a table'", "not a table at all")
c = two(PR.Sanitize(L.eval("{ bpm = 1e7, model = 'models/../../x;rm', frames = { { beats = -5, ease = 'wobbly', bones = { a = { 190, 0, 0 } } } } }")))[0]
ok(c is not None and c.bpm == 400 and c.frames[1].beats == 0.05 and c.frames[1].ease == "smooth" and c.frames[1].bones["a"][1] == -170,
   "out-of-range values are brought into range, an unknown easing is smooth")
ok(c is not None and c.model is None, "a model path with odd characters is dropped")
ok(PR.CleanName("../../cfg/autoexec") == "______cfg_autoexec" and PR.CleanName("   ") is None, "names can't leave the folder")

# a file's round trip through JSON (as util.TableToJSON and util.JSONToTable do it in the game)
L.execute(open(os.path.join(PR_DIR, "play.lua")).read().split("if SERVER then")[0])
data = L.eval("""{ tool = "Pose Recorder 2.0", format = 2, name = "wave", bpm = 90, mode = "keys", wrap = false,
    frames = { { beats = 1.5, ease = "snappy", bones = { ["ValveBiped.Bip01_R_UpperArm"] = { -70, -20, 5.25 } } },
               { beats = 0.5, ease = "bouncy", bones = { ["ValveBiped.Bip01_R_UpperArm"] = { -90, 10, 0 } } } } }""")
text = L.globals().util.TableToJSON(data)
back, err = two(PR.Decode(text))
ok(back is not None and back.wrap is False and back.bpm == 90 and back.frames[1].ease == "snappy" and back.frames[2].beats == 0.5
   and back.frames[1].bones["ValveBiped.Bip01_R_UpperArm"][3] == 5.25, "a saved file reads back the same (%s)" % err)
again = two(PR.Decode(L.globals().util.TableToJSON(back)))[0]
ok(json.dumps(to_py(again), sort_keys=True) == json.dumps(to_py(back), sort_keys=True), "and again: nothing drifts")
ok(two(PR.Decode("{ not json"))[0] is None and two(PR.Decode("x" * 300000))[0] is None, "unreadable or oversized text is turned down")
ok(two(PR.Decode('{"frames":[{"beats":1,"bones":{"a":[NaN,0,0]}}]}'))[0] is None, "NaN in the JSON is turned down")

# ----------------------------------------------------------------------------------------
# Playing: a server, two clients, a fake network between them
# ----------------------------------------------------------------------------------------
S = runtime("server")
C1 = runtime("client")
C2 = runtime("client")
WAVE = json.dumps({"name": "wave", "bpm": 60, "mode": "keys", "frames": [
    {"beats": 1, "ease": "linear", "bones": {"ValveBiped.Bip01_R_UpperArm": [0, 0, 0]}},
    {"beats": 1, "bones": {"ValveBiped.Bip01_R_UpperArm": [0, -80, 0]}}]})
S.globals()._files["pose_recorder/wave.json"] = WAVE
S.globals()._files["data_static/pose_recorder/bow.json"] = WAVE.replace('"wave"', '"bow"')
S.globals()._files["pose_recorder/broken.json"] = '{"frames":[{"beats":1,"bones":{"a":[1,2]}}]}'
for R in (S, C1, C2):
    R.execute("me1, me2, npc = FakeEnt(1), FakeEnt(2), FakeEnt(3, 'models/combine_soldier.mdl', true)")
C1.execute("function LocalPlayer() return me1 end")
C2.execute("function LocalPlayer() return me2 end")
S.execute(PLAY)
ok(S.eval("PoseRecorder.Anims.wave ~= nil and PoseRecorder.Anims.bow ~= nil"), "packs: the data folder's and an addon's data_static are both found")
ok(S.eval("PoseRecorder.Anims.broken == nil"), "a broken pack file is skipped")
C1.execute(PLAY)
C2.execute(PLAY)


def ent_id(v):
    return v.id if lj.lua_type(v) == "table" and v.id is not None else None


def deliver(src, dst_runtimes, sender_id=None):
    """Hand every message src has sent to its receivers, entities swapped for theirs."""
    msgs = list(src.globals().net.sent.values())
    src.execute("net.sent = {}")
    for m in msgs:
        to = m.to
        for R, rid in dst_runtimes:
            if to is not None and lj.lua_type(to) == "table" and ent_id(to) != rid:
                continue
            q = R.table()
            for i, v in enumerate(m.data.values()):
                eid = ent_id(v)
                q[i + 1] = R.globals()._ents[eid] if eid is not None else v
            R.globals().net._q = q
            fn = R.globals().net["recv_" + m.name]
            if fn is None:
                continue
            fn(100000, R.globals()._ents[sender_id] if sender_id else None)


def client_send(C, cid):
    """A client's net.Start / Write / SendToServer, carried to the server as from player cid."""
    C.execute("""
        _out = {}
        local cur
        net.Start = function(n) cur = { name = n, data = {} } end
        for _, w in ipairs({ "UInt", "String", "Entity", "Float", "Double", "Data", "Bool" }) do
            net["Write" .. w] = function(v) table.insert(cur.data, v) end
        end
        net.SendToServer = function() table.insert(_out, cur) end
    """)


for C in (C1, C2):
    client_send(C, None)
C1.globals().hook.t.InitPostEntity.PoseRecorderPlay()


def up(C, cid):
    outs = list(C.globals()._out.values())
    C.execute("_out = {}")
    for m in outs:
        q = S.table()
        for i, v in enumerate(m.data.values()):
            eid = ent_id(v)
            q[i + 1] = S.globals()._ents[eid] if eid is not None else v
        S.globals().net._q = q
        S.globals().net["recv_" + m.name](100000, S.globals()._ents[cid])


up(C1, 1)
deliver(S, [(C1, 1)])
ok(list(C1.globals().PoseRecorder.Packs.values()) == ["bow", "wave"], "a joining client is told the server's packs")
ok(C1.eval("table.concat(PoseRecorder.Choices(), ',')") == "bow,wave", "they're in the tool's list and the context menu")

# a pack on an NPC, from the context menu
C1.execute("PoseRecorder.RequestPlay(npc, 'wave', 'loop', 1)")
up(C1, 1)
ok(S.eval("PoseRecorder.Playing[npc] and PoseRecorder.Playing[npc].key") == "wave", "the server plays the pack on the NPC")
deliver(S, [(C1, 1), (C2, 2)])
up(C1, 1)  # (C1 asks for the animation it hasn't got)
deliver(S, [(C1, 1)])
ok(C1.eval("PoseRecorder.Library.wave ~= nil"), "the client fetched the animation's keyframes")
S.execute("_advance(0.5)")
C1.execute("_advance(0.5) for _, h in pairs(hook.t.Think) do h() end")
ok(abs(C1.eval("npc.manip[1] and npc.manip[1].y or 0") + 40) < 1e-6, "the client turns the NPC's bones itself, from the start time")

# a late joiner sees what's already playing
C2.globals().hook.t.InitPostEntity.PoseRecorderPlay()
up(C2, 2)
deliver(S, [(C2, 2)])
up(C2, 2)
deliver(S, [(C2, 2)])
C2.execute("_advance(0.5) for _, h in pairs(hook.t.Think) do h() end")
ok(abs(C2.eval("npc.manip[1] and npc.manip[1].y or 0") + 40) < 1e-6, "a late joiner sees the NPC at the same point in the animation")

# a player's own animation (not on the server): sent up, checked, and on to everyone
C1.globals()._files["pose_recorder/mine.json"] = WAVE.replace('"wave"', '"mine"').replace("-80", "60")
C1.execute("RunConsoleCommand = function() end concommand.list.pose_play(nil, nil, { 'mine', 'hold', '2' })")
up(C1, 1)
st = S.eval("PoseRecorder.Playing[me1]")
ok(st is not None and st.key == "~76561/mine" and st.mode == "hold" and st.speed == 2, "pose_play: the player's own file plays on them, as asked")
deliver(S, [(C1, 1), (C2, 2)])
up(C2, 2)
deliver(S, [(C2, 2)])
C2.execute("_advance(3) for _, h in pairs(hook.t.Think) do h() end")
ok(abs(C2.eval("me1.manip[1] and me1.manip[1].y or 0") - 60) < 1e-6, "another player sees it, holding the last pose")

# hostile uploads are turned down
up(C1, 1)  # (C1 fetches its own animation back, as everyone does)
deliver(S, [(C1, 1)])
ok(C1.eval("PoseRecorder.Library['~76561/mine'] ~= nil"), "the player who sent it gets it back like everyone else")
C1.globals()._files["pose_recorder/evil.json"] = '{"frames":[{"beats":1,"bones":{"a":[1e300,0,0]}}]}'
C1.execute("concommand.list.pose_play(nil, nil, { 'evil' })")
ok(len(list(C1.globals()._out.values())) == 0, "the client won't even send a broken file %r" % [
    (m.name, list(m.data.values())) for m in C1.globals()._out.values()])
S.execute("_advance(5)")
S.globals().net._q = S.eval("{ 2, me1, 'evil', 'loop', 1, 40 }")
S.globals().net._q[7] = '{"frames":[{"beats":1,"bones":{"a":[1e300,0,0]}}]}'
S.globals().net["recv_pose_recorder_net"](100000, S.globals()._ents[1])
ok(S.eval("PoseRecorder.Anims['~76561/evil'] == nil"), "the server turns down a hostile file sent straight to it")
said = [m for m in S.globals().net.sent.values() if m.name == "pose_recorder_say"]
ok(said and "turned that animation down" in said[-1].data[1], "and says why")
S.execute("net.sent = {}")
S.globals().net._q = S.eval("{ 2, me1, 'big', 'loop', 1, 65000, 'x' }")
S.globals().net["recv_pose_recorder_net"](100000, S.globals()._ents[1])
ok(S.eval("PoseRecorder.Anims['~76561/big'] == nil"), "an oversized upload is ignored")
S.globals().net._q = S.eval("{ 1, me2, 'wave', 'loop', 1 }")
S.globals().net["recv_pose_recorder_net"](100000, S.globals()._ents[1])
ok(S.eval("PoseRecorder.Playing[me2] == nil"), "you can't play an animation on another player")

# stopping, and the bones put back
C1.execute("concommand.list.pose_stop()")
up(C1, 1)
deliver(S, [(C1, 1), (C2, 2)])
ok(S.eval("PoseRecorder.Playing[me1] == nil") and C2.eval("PoseRecorder.Active[me1] == nil"), "pose_stop stops it for everyone")
ok(C2.eval("me1.manip[1].y == 0"), "and the bones go back to the model's own")

# Lua coders: PoseRecorder.Play on the server
okp = S.eval("PoseRecorder.Play(npc, 'bow', { mode = 'once', speed = 0.5 })")
ok(okp is True or (isinstance(okp, tuple) and okp[0] is True), "PoseRecorder.Play(ent, name, opts) on the server")
key = S.eval("PoseRecorder.Register('Custom', { frames = { { beats = 1, bones = { ['ValveBiped.Bip01_Pelvis'] = { 0, 0, 10 } } } } })")
ok(key == "custom" or (isinstance(key, tuple) and key[0] == "custom"), "PoseRecorder.Register adds an animation from Lua")
ok(S.eval("PoseRecorder.Get('custom').frames[1].ease") == "smooth", "PoseRecorder.Get returns it, checked")
ok(two(S.eval("PoseRecorder.Play(npc, 'nothing')"))[0] is False, "playing an animation that doesn't exist says no")

print("pose recorder tests: %d passed, %d failed" % (passed, len(failed)))
print("POSE RECORDER TESTS " + ("PASS" if not failed else "FAIL"))
sys.exit(1 if failed else 0)
