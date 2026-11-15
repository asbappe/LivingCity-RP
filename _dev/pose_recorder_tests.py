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

# ----------------------------------------------------------------------------------------
# A pose put back on a skeleton, and things held in it
# ----------------------------------------------------------------------------------------
M = runtime("server")
M.execute("""
    PR = PoseRecorder
    B = "ValveBiped.Bip01_"
    SK = { { name = B .. "Pelvis" }, { name = B .. "Spine2", parent = 1 }, { name = B .. "R_UpperArm", parent = 2 },
        { name = B .. "R_Forearm", parent = 3 }, { name = B .. "R_Hand", parent = 4 }, { name = B .. "L_UpperArm", parent = 2 },
        { name = B .. "L_Clavicle", parent = 2 }, { name = B .. "R_Finger1", parent = 5 } }
    REL = { PR.FromAngles(0, 0, 90), PR.FromAngles(-80, 10, 90), PR.FromAngles(20, -70, 15), PR.FromAngles(25, -60, 10),
        PR.FromAngles(30, -55, 0), PR.FromAngles(20, 70, -15), PR.FromAngles(0, 80, 0), PR.FromAngles(31, -50, 3) }
    POS = { { 0, 0, 38 }, { 0, 0, 48 }, { 0, -8, 56 }, { 2, -12, 45 }, { 5, -14, 35 }, { 0, 8, 56 }, { 0, 4, 57 }, { 6, -14, 31 } }
    REC = { true, true, true, true, true, true, false, false }
    POSE = { [B .. "R_UpperArm"] = { 6, 40, 75 }, [B .. "R_Forearm"] = { 0, -75, 0 }, [B .. "R_Hand"] = { 0, 10, 0 }, [B .. "L_UpperArm"] = { -6, 40, -75 } }
    function Near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end
    function SameRot(a, b) for i = 1, 3 do for j = 1, 3 do if not Near(a[i][j], b[i][j]) then return false end end end return true end
    function Dist(a, b) return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2) end
""")
ok(M.eval("""(function()
    local rot, pos = PR.Apply(SK, REL, POS, {}, 0)
    for i = 1, #SK do if not SameRot(rot[i], REL[i]) or Dist(pos[i], POS[i]) > 1e-6 then return false end end
    return true end)()"""), "Apply with no pose: every bone is where the reference has it")
ok(M.eval("""(function()
    local rot = PR.Apply(SK, REL, POS, POSE, 30)
    local out, face = PR.Delta(SK, REL, rot, REC)
    if not Near(face, 30, 0.01) then return false end
    for name, a in pairs(POSE) do for k = 1, 3 do if not Near(out[name][k], a[k], 0.11) then return false end end end
    for _, name in ipairs({ B .. "Pelvis", B .. "Spine2" }) do for k = 1, 3 do if not Near(out[name][k], 0, 0.11) then return false end end end
    return out[B .. "L_Clavicle"] == nil end)()"""), "Apply then Delta gives the pose back, facing the same way (a pose goes onto a ragdoll and is read off it unchanged)")
ok(M.eval("""(function()
    local rot, pos = PR.Apply(SK, REL, POS, POSE, 30)
    for i, b in ipairs(SK) do
        if b.parent and not Near(Dist(pos[i], pos[b.parent]), Dist(POS[i], POS[b.parent]), 1e-6) then return false end
    end
    local finger = PR.Mul(rot[5], PR.Mul(PR.T(REL[5]), REL[8]))
    return SameRot(rot[8], finger) and Dist(pos[1], PR.Rotate(PR.FromAngles(0, 30, 0), POS[1])) < 1e-6 end)()"""),
   "the posed skeleton keeps its bones' lengths, and a bone with no turn of its own follows its parent")
ok(M.eval("""(function()
    local rot, pos = PR.Apply(SK, REL, POS, POSE, 30)
    local propRot, propPos = PR.FromAngles(12, -140, 33), { 20, 5, 30 }
    local lp, la = PR.Offset(rot[5], pos[5], propRot, propPos)
    local p2, r2 = PR.Place(rot[5], pos[5], lp, la)
    return Dist(p2, propPos) < 1e-6 and SameRot(r2, propRot) end)()"""), "a held thing measured from a bone and put back from it is where it was")
ok(M.eval("PR.CleanPose({ [B .. 'R_Hand'] = { 370, -190, 12.345 } })[B .. 'R_Hand'][1]") == 10
   and M.eval("PR.CleanPose({ [B .. 'R_Hand'] = { 370, -190, 12.345 } })[B .. 'R_Hand'][2]") == 170,
   "CleanPose: angles brought round to within a half turn")
ok(M.eval("PR.CleanPose({ a = { 0/0, 0, 0 } }) == nil and PR.CleanPose({ ['bad;name'] = { 0, 0, 0 } }) == nil and PR.CleanPose('x') == nil"),
   "CleanPose turns down what isn't plain numbers on plainly named bones")
ok(M.eval("""(function()
    local many = {}
    for i = 1, 81 do many['b' .. i] = { 0, 0, 0 } end
    return PR.CleanPose(many) == nil end)()"""), "and a pose with too many bones")
ok(M.eval("""(function()
    local p = PR.CleanProps({ broom = { bone = '', pos = { 1, 2, 3 }, ang = { 0, 400, 0 } } })
    return p and p.broom.bone == nil and p.broom.ang[2] == 40
        and PR.CleanProps({ broom = { bone = 'x', pos = { 1, 2, 9999 }, ang = { 0, 0, 0 } } }) == nil
        and PR.CleanProps({ broom = { pos = { 1, 2, 1/0 }, ang = { 0, 0, 0 } } }) == nil
        and PR.CleanProps({ broom = { bone = 'a;b', pos = { 1, 2, 3 }, ang = { 0, 0, 0 } } }) == nil end)()"""),
   "CleanProps: a held thing far away, at no real place, or hung from a badly named bone is turned down")

# ----------------------------------------------------------------------------------------
# Targets: another addon's pose on a mannequin, put in place and measured (a server, a client)
# ----------------------------------------------------------------------------------------
TARGETS = open(os.path.join(PR_DIR, "targets.lua")).read()
AUTO = open(os.path.join(PR_DIR, "..", "autorun", "pose_recorder.lua")).read()
TS = runtime("server")
TC = runtime("client")
SHARED = """
    PR = PoseRecorder
    B = "ValveBiped.Bip01_"
    _set = {}
    TARGET = {
        id = "test_sweep", label = "Sweeping", model = "models/vortigaunt.mdl", ref = "sweep",
        get = function()
            return { [B .. "R_UpperArm"] = { 6, 40, 75 }, [B .. "R_Forearm"] = Angle(0, -75, 0) },
                { broom = { model = "models/props_c17/pushbroom.mdl", bone = B .. "R_Hand", pos = Vector(3, 1, -2), ang = { 10, 90, 0 } },
                  cap = { model = "models/props_junk/cap.mdl", pos = { 12, 0, 70 }, ang = { 0, 45, 0 } } }
        end,
        set = function(ply, bones, props)
            if _refuse then return false, "Not today." end
            _set[#_set + 1] = { ply = ply, bones = bones, props = props }
        end,
        can = function(ply) return not ply.banned end,
        hang = function(name) return _hang and _hang[name] end,
    }
"""
TS.globals()._auto, TS.globals()._play, TS.globals()._targets, TS.globals()._core = AUTO, PLAY, TARGETS, CORE
TS.execute("""
    undo = { Create = function() end, AddEntity = function() end, SetPlayer = function() end, Finish = function() end }
    AddCSLuaFile = function() end
    include = function(p)
        local src = ({ ["pose_recorder/core.lua"] = _core, ["pose_recorder/play.lua"] = _play, ["pose_recorder/targets.lua"] = _targets })[p]
        return assert(loadstring(src, p))()
    end
    local RAG = { "Pelvis", "Spine2", "R_UpperArm", "R_Forearm", "R_Hand", "L_UpperArm" }
    function _EMT:GetPhysicsObjectCount() return self.cls == "prop_ragdoll" and #RAG or 1 end
    function _EMT:GetPhysicsObjectNum(i)
        self.phys = self.phys or {}
        if not self.phys[i] then
            local ph = { moving = true }
            ph.IsValid = function() return true end
            ph.EnableMotion = function(_, on) ph.moving = on end
            ph.Wake = function() end
            ph.SetPos = function(_, p) ph.pos = p end
            ph.SetAngles = function(_, a) ph.ang = a end
            self.phys[i] = ph
        end
        return self.phys[i]
    end
    function _EMT:GetPhysicsObject() return self:GetPhysicsObjectNum(0) end
    function _EMT:TranslatePhysBoneToBone(i) return i end
    function _EMT:GetBoneName(i) return "ValveBiped.Bip01_" .. RAG[i + 1] end
    function _EMT:DeleteOnRemove(e) self.goWith = self.goWith or {} table.insert(self.goWith, e) end
    assert(loadstring(_auto, "pose_recorder.lua"))()
    me1, me2 = FakeEnt(1), FakeEnt(2)
    for _, p in ipairs({ me1, me2 }) do
        p.EyePos = function() return Vector(0, 0, 64) end
        p.EyeAngles = function() return Angle(0, 0, 0) end
    end
""")
TS.execute(SHARED)
ok(TS.eval("PR.AddTarget(TARGET) == true and #PR.Targets() == 1 and PR.Target('test_sweep').ref == 'sweep'"), "AddTarget: another addon's pose is listed")
ok(TS.eval("PR.AddTarget({ id = 'no model', get = function() end }) == false and PR.AddTarget({ id = 'x', model = 'm.mdl' }) == false and #PR.Targets() == 1"),
   "a target with a bad id, or no get, is turned down")
TC.globals()._targets = TARGETS
TC.execute("""
    PR = PoseRecorder
    PR.Say = function(m) _said = m end
    B = "ValveBiped.Bip01_"
    local SK = { { name = B .. "Pelvis" }, { name = B .. "Spine2", parent = 1 }, { name = B .. "R_UpperArm", parent = 2 },
        { name = B .. "R_Forearm", parent = 3 }, { name = B .. "R_Hand", parent = 4 }, { name = B .. "L_UpperArm", parent = 2 },
        { name = B .. "R_Finger1", parent = 5 } }
    local REL = { PR.FromAngles(0, 0, 90), PR.FromAngles(-80, 10, 90), PR.FromAngles(20, -70, 15), PR.FromAngles(25, -60, 10),
        PR.FromAngles(30, -55, 0), PR.FromAngles(20, 70, -15), PR.FromAngles(31, -50, 3) }
    local POS = { { 0, 0, 38 }, { 0, 0, 48 }, { 0, -8, 56 }, { 2, -12, 45 }, { 5, -14, 35 }, { 0, 8, 56 }, { 6, -14, 31 } }
    PR.Reference = function(model, seq) _refAsked = model .. "|" .. seq return { bones = SK, rel = REL, pos = POS, seq = 0 } end
    -- the mannequin and what it holds, as this game sees them: wherever the server put them
    _placed = { bones = {}, props = {} }
    local function Matrix(at)
        return { GetAngles = function() return Angle(at.ang[1], at.ang[2], at.ang[3]) end,
            GetTranslation = function() return Vector(at.pos[1], at.pos[2], at.pos[3]) end }
    end
    local rag = { IsValid = function() return true end, GetModel = function() return "models/vortigaunt.mdl" end }
    rag.LookupBone = function(_, n) return _placed.bones[n] and n or nil end
    rag.GetBoneMatrix = function(_, n) return _placed.bones[n] and Matrix(_placed.bones[n]) or nil end
    function Entity(idx)
        if idx == _ragIdx then return rag end
        for name, i in pairs(PR.sel and PR.sel.props or {}) do
            if i == idx and _placed.props[name] then
                local at = _placed.props[name]
                return { IsValid = function() return true end, GetPos = function() return Vector(at.pos[1], at.pos[2], at.pos[3]) end,
                    GetAngles = function() return Angle(at.ang[1], at.ang[2], at.ang[3]) end }
            end
        end
        return nil
    end
    -- (the real one reads the ragdoll's bones off the screen: lua/autorun/pose_recorder.lua)
    PR.Snapshot = function(refName)
        local ref = PR.Reference("models/vortigaunt.mdl", refName)
        local posed, record = {}, {}
        for i, b in ipairs(ref.bones) do
            local at = _placed.bones[b.name]
            if at then posed[i] = PR.FromAngles(at.ang[1], at.ang[2], at.ang[3]) end
            record[i] = PR.sel.phys[b.name] or false
        end
        return PR.Delta(ref.bones, ref.rel, posed, record)
    end
    function LocalPlayer() return FakeEnt(1) end
    assert(loadstring(_targets, "targets.lua"))()
""")
TC.execute(SHARED)
TC.execute("PR.AddTarget(TARGET)")
client_send(TC, None)


def up2(cid):
    outs = list(TC.globals()._out.values())
    TC.execute("_out = {}")
    for m in outs:
        q = TS.table()
        for i, v in enumerate(m.data.values()):
            q[i + 1] = v
        TS.globals().net._q = q
        TS.globals().net["recv_" + m.name](100000, TS.globals()._ents[cid])
    return [m.name for m in outs]


def see_placed():
    """What the server put where, as the client's game would see it."""
    js = TS.eval("""(function()
        local m = PR.TargetOf(me1)
        local out = { bones = {}, props = {} }
        for name, i in pairs(m.phys) do
            local ph = m.ent:GetPhysicsObjectNum(i)
            if ph.pos then out.bones[name] = { pos = { ph.pos.x, ph.pos.y, ph.pos.z }, ang = { ph.ang.p, ph.ang.y, ph.ang.r } } end
        end
        for name, e in pairs(m.props) do
            local p, a = e:GetPos(), e:GetAngles()
            out.props[name] = { pos = { p.x, p.y, p.z }, ang = { a.p, a.y, a.r } }
        end
        return util.TableToJSON(out) end)()""")
    TC.globals()._placed = TC.globals().util.JSONToTable(js)


ok(two(TS.eval("PR.TargetMannequin(me1, 'nothing', Vector(100, 200, 0), 90)"))[0] is None, "no mannequin for a pose that isn't there")
TS.execute("me2.banned = true")
ok(two(TS.eval("PR.TargetMannequin(me2, 'test_sweep', Vector(100, 200, 0), 90)"))[0] is None, "or for someone the target says may not")
TS.execute("me2.banned = nil  _rag = PR.TargetMannequin(me1, 'test_sweep', Vector(100, 200, 0), 90)")
ok(TS.eval("IsValid(_rag) and _rag:GetClass() == 'prop_ragdoll' and _rag:GetModel() == 'models/vortigaunt.mdl'"), "TargetMannequin: a ragdoll of the target's model")
ok(TS.eval("""(function()
    local m = PR.TargetOf(me1)
    if not (m and IsValid(m.props.broom) and IsValid(m.props.cap) and m.props.broom:GetModel() == 'models/props_c17/pushbroom.mdl') then return false end
    for i = 0, 5 do if _rag:GetPhysicsObjectNum(i).moving ~= false then return false end end
    return m.props.broom:GetPhysicsObject().moving == false end)()"""), "every limb frozen, and each held thing a frozen prop")
TC.globals()._ragIdx = TS.eval("_rag:EntIndex()")
deliver(TS, [(TC, 1)])
ok(TC.eval("PR.sel and PR.sel.target == 'test_sweep' and PR.sel.idx == _ragIdx and PR.sel.phys[B .. 'R_Hand'] == true and PR.sel.props.broom ~= nil"),
   "the player's game is told which mannequin is theirs, its limbs and what it holds")
ok(TC.eval("_refAsked") == "models/vortigaunt.mdl|sweep", "the pose is worked out on the target's model, on top of its own sequence")
ok(up2(1) == ["pose_recorder_place"], "and sends where each limb and held thing goes")
ok(TS.eval("""(function()
    local m = PR.TargetOf(me1)
    local hand = _rag:GetPhysicsObjectNum(m.phys[B .. 'R_Hand'])
    local pelvis = _rag:GetPhysicsObjectNum(m.phys[B .. 'Pelvis'])
    -- (the pelvis: 38 up from the spot, the model turned to face 90)
    return hand.pos ~= nil and hand.moving == false and math.abs(pelvis.pos.x - 100) < 0.01 and math.abs(pelvis.pos.y - 200) < 0.01
        and math.abs(pelvis.pos.z - 38) < 0.01 and math.abs(pelvis.ang.y - 90) < 0.01 end)()"""),
   "the server puts each limb there, turned to the way the mannequin faces, still frozen")
see_placed()
ok(TC.eval("""(function()
    local cap = _placed.props.cap
    -- (held from the spot it stands on: 12 ahead and 70 up, with the mannequin facing 90)
    return math.abs(cap.pos[1] - 100) < 0.01 and math.abs(cap.pos[2] - 212) < 0.01 and math.abs(cap.pos[3] - 70) < 0.01
        and math.abs(cap.ang[2] - 135) < 0.01 end)()"""), "a thing held from no bone goes where the target says, from the spot the mannequin stands on")
TC.execute("concommand.list.pose_recorder_take()")
ok(up2(1) == ["pose_recorder_take"], "pose_recorder_take measures the mannequin and sends the pose")
ok(TS.eval("""(function()
    local s = _set[#_set]
    if not (s and s.ply == me1) then return false end
    local up, fore = s.bones[B .. 'R_UpperArm'], s.bones[B .. 'R_Forearm']
    local function Near(a, b) return math.abs(a - b) < 0.11 end
    return Near(up[1], 6) and Near(up[2], 40) and Near(up[3], 75) and Near(fore[2], -75)
        and Near(s.bones[B .. 'Spine2'][1], 0) and s.bones[B .. 'R_Finger1'] == nil end)()"""),
   "the target's set gets the bones a ragdoll is posed by: untouched, the pose it was stood in comes back")
ok(TS.eval("""(function()
    local b, c = _set[#_set].props.broom, _set[#_set].props.cap
    local function Near(a, x) return math.abs(a - x) < 0.02 end
    return b.bone == B .. 'R_Hand' and Near(b.pos[1], 3) and Near(b.pos[2], 1) and Near(b.pos[3], -2) and Near(b.ang[1], 10) and Near(b.ang[2], 90)
        and c.bone == nil and Near(c.pos[1], 12) and Near(c.pos[3], 70) and Near(c.ang[2], 45) end)()"""),
   "and each held thing's place and angle from its bone (or from the spot it stands on), unchanged when nothing was moved")
said = [m for m in TS.globals().net.sent.values() if m.name == "pose_recorder_told"]
ok(said and said[-1].data[1] == "Sweeping: set.", "the player is told it's set")
TS.execute("net.sent = {}")
# the broom moved by hand (the physgun): 5 units along the hand's own forward
TC.execute("""
    local hand, broom = _placed.bones[B .. 'R_Hand'], _placed.props.broom
    local f = PR.Rotate(PR.FromAngles(hand.ang[1], hand.ang[2], hand.ang[3]), { 5, 0, 0 })
    broom.pos = { broom.pos[1] + f[1], broom.pos[2] + f[2], broom.pos[3] + f[3] }
    -- and the forearm bent a further 20 degrees at the elbow (its own yaw)
    local fore = _placed.bones[B .. 'R_Forearm']
    local p, y, r = PR.ToAngles(PR.Mul(PR.FromAngles(fore.ang[1], fore.ang[2], fore.ang[3]), PR.FromAngles(0, -20, 0)))
    fore.ang = { p, y, r }
    PR.TakeTarget()
""")
up2(1)
ok(TS.eval("math.abs(_set[#_set].props.broom.pos[1] - 8) < 0.02 and math.abs(_set[#_set].props.broom.pos[2] - 1) < 0.02"),
   "a held thing moved by hand: its new place from the bone is what is set")
ok(TS.eval("math.abs(_set[#_set].bones[B .. 'R_Forearm'][2] + 95) < 0.11 and math.abs(_set[#_set].bones[B .. 'R_UpperArm'][2] - 40) < 0.11"),
   "a limb moved by hand: its new turn is what is set, the others as they were")
# measured from another bone when the target asks (hang)
TC.execute("_hang = { broom = B .. 'R_Forearm' }  PR.TakeTarget()")
up2(1)
ok(TS.eval("_set[#_set].props.broom.bone == B .. 'R_Forearm'"), "hang: a held thing measured from the bone the target names")
TC.execute("_hang = nil")
# refusals
n_set = TS.eval("#_set")
TS.execute("_refuse = true")
TC.execute("PR.TakeTarget()")
up2(1)
said = [m for m in TS.globals().net.sent.values() if m.name == "pose_recorder_told"]
ok(TS.eval("#_set") == n_set and said and said[-1].data[1] == "Not today.", "a target's set can refuse, and the player is told why")
TS.execute("_refuse = nil  net.sent = {}")
ok(two(TS.eval("PR.TargetTake(me2, 'test_sweep', {}, {})"))[0] is False, "someone with no mannequin of that pose can't set it")
ok(two(TS.eval("PR.TargetTake(me1, 'test_sweep', { [B .. 'R_Hand'] = { 0/0, 0, 0 } }, {})"))[0] is False and TS.eval("#_set") == n_set,
   "a pose that isn't plain numbers is turned down")
TS.execute("PR.TargetTake(me1, 'test_sweep', { [B .. 'R_Hand'] = { 1, 2, 3 }, ['ValveBiped.Bip01_Tail'] = { 9, 9, 9 } }, { hat = { pos = { 0, 0, 0 }, ang = { 0, 0, 0 } } })")
ok(TS.eval("_set[#_set].bones['ValveBiped.Bip01_Tail'] == nil and _set[#_set].bones[B .. 'R_Hand'][1] == 1 and _set[#_set].props.hat == nil"),
   "bones the mannequin hasn't got, and things it doesn't hold, are left out")
ok(TS.eval("""(function()
    local ok1 = PR.TargetPlace(me1, { [B .. 'R_Hand'] = { pos = { 0, 0, 99999 }, ang = { 0, 0, 0 } } }, {})
    local hand = _rag:GetPhysicsObjectNum(PR.TargetOf(me1).phys[B .. 'R_Hand'])
    return hand.pos.z < 1000 and PR.TargetPlace(me2, {}, {}) == false end)()"""), "a limb can't be sent far from its mannequin, or by someone who has none")
# whatever is let go of stays put; the mannequin goes with its player
TS.execute("_rag:GetPhysicsObjectNum(3).moving = true  hook.Run('PhysgunDrop', me1, _rag)")
ok(TS.eval("_rag:GetPhysicsObjectNum(3).moving == false"), "a limb let go of with the physgun stays where it is")
TS.execute("_broom = PR.TargetOf(me1).props.broom  hook.Run('PlayerDisconnected', me1)")
ok(TS.eval("not IsValid(_rag) and not IsValid(_broom) and PR.TargetOf(me1) == nil"), "when the player leaves, the mannequin and what it held are removed")
TS.execute("_r2 = PR.TargetMannequin(me1, 'test_sweep', Vector(0, 0, 0), 0)  _r3 = PR.TargetMannequin(me1, 'test_sweep', Vector(50, 0, 0), 0)")
ok(TS.eval("not IsValid(_r2) and IsValid(_r3)"), "standing it again moves it: one mannequin each")
TS.execute("concommand.list.pose_recorder_target_remove(me1)")
ok(TS.eval("not IsValid(_r3)"), "pose_recorder_target_remove takes it away")
# a mannequin of any model
TS.execute("net.sent = {}  concommand.list.pose_recorder_mannequin(me1, nil, { 'models/stalker.mdl' })")
ok(TS.eval("""(function()
    for _, e in ipairs(ents.FindByClass('prop_ragdoll')) do if e:GetModel() == 'models/stalker.mdl' then return true end end
    return false end)()"""), "pose_recorder_mannequin <model>: a mannequin of any model, not only your own")
TS.execute("concommand.list.pose_recorder_mannequin(me1, nil, {})")
ok(TS.eval("""(function()
    for _, e in ipairs(ents.FindByClass('prop_ragdoll')) do if e:GetModel() == 'models/player/kleiner.mdl' then return true end end
    return false end)()"""), "with no model named: your own, as before")

print("pose recorder tests: %d passed, %d failed" % (passed, len(failed)))
print("POSE RECORDER TESTS " + ("PASS" if not failed else "FAIL"))
sys.exit(1 if failed else 0)
