"""Creeping walls (combineinnerwall*) seated as the owner asked, 22 November: "the two instances of
'models/props_combine/combineinnerwall001c.mdl' are just floating at odd angles out of everything and these should
never do that; they can instead be put on a wall or used as a wall". So each stands upright, turned only in yaw, its
back flat on a wall face and its foot on a floor or a ledge, sized by asset_facts.json; a spot is kept only where the
model's box meets nothing (wall()), and seated() checks any VMF by numbers: every creeping wall's back within 2 of a
wall face, its foot within 2 of a floor, pitch and roll 0, nothing inside its box."""
import json
import math
import os

import numpy as np

from .measure import AL, as_brushes

FACTS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "asset_facts.json")
_BOX = {}


def bbox(model):
    """The model's box (x0 y0 z0 x1 y1 z1) about its origin: x back to front, y side to side, z up."""
    if not _BOX:
        with open(FACTS) as fh:
            for k, v in json.load(fh).items():
                if "bbox" in v:
                    _BOX[k.lstrip("./")] = v["bbox"]
    return _BOX[model]


def frame(yaw):
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    return np.array([c, s, 0.0]), np.array([-s, c, 0.0]), np.array([0.0, 0.0, 1.0])


def boxes_as_brushes(boxes):
    out = []
    for b in boxes:
        lo, hi = np.array(b[:3], float), np.array(b[3:], float)
        V = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])])
        N = np.vstack([np.eye(3), -np.eye(3)])
        out.append({"N": N, "D": np.concatenate([hi, -lo]), "V": V, "box": list(lo) + list(hi)})
    return out


class Room:
    """What a creeping wall must not meet and must stand on: brushes (N, D, V, box), with the ground below z 0."""

    def __init__(self, brushes, ground=True):
        self.B, self.ground = brushes, ground
        self.grid = AL.Grid(brushes, 256)

    def add(self, brush):
        self.B.append(brush)
        self.grid = AL.Grid(self.B, 256)

    def inside(self, p):
        if self.ground and p[2] < 0:
            return True
        return any(AL.inside(self.B[j], p) for j in self.grid.at(p))

    def meets(self, c, axes, half):
        """Whether the box (middle c, axes, half sizes) meets a brush (separating planes: the brush's faces, the box's)."""
        A = np.array(axes)
        ext = np.abs(A).T @ half
        box = [c[0] - ext[0], c[1] - ext[1], c[2] - ext[2], c[0] + ext[0], c[1] + ext[1], c[2] + ext[2]]
        if self.ground and box[2] < 0:
            return True
        for j in self.grid.near(box):
            b = self.B[j]
            if any(b["box"][k] >= box[k + 3] or b["box"][k + 3] <= box[k] for k in range(3)):
                continue
            if ((b["N"] @ c - np.abs(b["N"] @ A.T) @ half) >= b["D"]).any():
                continue
            pv, pc = b["V"] @ A.T, A @ c
            if ((pv.min(0) >= pc + half) | (pv.max(0) <= pc - half)).any():
                continue
            return True
        return False


def obb_brush(model, origin, yaw):
    """The model's box at origin and yaw as a brush (N, D, V, box), so the next prop keeps out of it."""
    x0, y0, z0, x1, y1, z1 = bbox(model)
    A = np.array(frame(yaw))
    o = np.array(origin, float)
    V = np.array([o + A.T @ np.array([x, y, z]) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
    N = np.vstack([A, -A])
    D = np.concatenate([A @ o + np.array([x1, y1, z1]), -(A @ o) - np.array([x0, y0, z0])])
    return {"N": N, "D": D, "V": V, "box": list(V.min(0)) + list(V.max(0))}


def samples(model, origin, yaw):
    """Points on the back (with the way out) and under the foot, and the box's middle, axes and half sizes."""
    x0, y0, z0, x1, y1, z1 = bbox(model)
    ex, ey, ez = frame(yaw)
    o = np.array(origin, float)
    back = [o + ex * x0 + ey * y + ez * z for y in np.linspace(y0 + 8, y1 - 8, 5) for z in np.linspace(z0 + 8, z1 - 8, 9)]
    foot = [o + ex * x + ey * y + ez * z0 for x in np.linspace(x0 + 8, x1 - 8, 3) for y in np.linspace(y0 + 8, y1 - 8, 5)]
    mid = o + ex * (x0 + x1) / 2 + ey * (y0 + y1) / 2 + ez * (z0 + z1) / 2
    return back, foot, ex, mid, (ex, ey, ez), np.array([(x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2])


def fits(room, model, origin, yaw, tol=2, back_on_wall=True):
    """None when the model at origin and yaw stands with its back on a wall (unless back_on_wall is False) and its
    foot on a floor, meeting nothing; else what is wrong."""
    back, foot, ex, mid, axes, half = samples(model, origin, yaw)
    ez = np.array([0.0, 0.0, 1.0])
    if back_on_wall and not all(room.inside(p - ex * tol) and not room.inside(p + ex * tol) for p in back):
        return "its back is not on a wall"
    if not all(room.inside(p - ez * tol) and not room.inside(p + ez * tol) for p in foot):
        return "its foot is not on a floor"
    if room.meets(mid, axes, half - tol):
        return "something stands inside it"
    return None


def wall(room, model, along, n, s_range, z_floor, r, step=16):
    """A spot for model on a wall: the face's point at s is along(s) (world), its outward normal n (world, level); the
    model upright with its back on the face, its foot on z_floor, its middle somewhere in s_range (scanned from a
    random start). Returns (origin, yaw) or None."""
    x0, y0, z0, x1, y1, z1 = bbox(model)
    yaw = math.degrees(math.atan2(n[1], n[0])) % 360
    yaw_i = int(round(yaw))
    s0, s1 = s_range
    ss = list(np.arange(s0, s1 + 1, step))
    if not ss:
        return None
    k = r.randrange(len(ss))
    for s in ss[k:] + ss[:k]:
        p = np.array(along(s), float)
        ex, ey, _ = frame(yaw_i)
        o = p - ex * x0 - ey * (y0 + y1) / 2
        o = (int(round(o[0])), int(round(o[1])), int(round(z_floor - z0)))
        if fits(room, model, o, yaw_i) is None:
            return o, yaw_i
    return None


class Sink:
    def __init__(self):
        self.props = []


def stand(room, sink, model, origin, yaw, back_on_wall=False, sunk=None):
    """Model into sink's props at origin (its foot's height) and yaw when it stands there meeting nothing; True if so.
    sunk: the origin's height for a model Valve sinks into the ground (barricades, booths): only what stands above
    the ground must meet nothing."""
    yaw = int(round(yaw)) % 360
    x0, y0, z0, x1, y1, z1 = bbox(model)
    if sunk is None:
        o = (int(round(origin[0])), int(round(origin[1])), int(round(origin[2] - z0)))
        ok = fits(room, model, o, yaw, back_on_wall=back_on_wall) is None
    else:
        o = (int(round(origin[0])), int(round(origin[1])), sunk)
        ex, ey, ez = frame(yaw)
        lo = max(z0, 2 - sunk)
        mid = np.array(o, float) + ex * (x0 + x1) / 2 + ey * (y0 + y1) / 2 + ez * (lo + z1) / 2
        ok = not room.meets(mid, (ex, ey, ez), np.array([(x1 - x0) / 2, (y1 - y0) / 2, (z1 - lo) / 2]) - 2)
    if ok:
        room.add(obb_brush(model, o, yaw))
        sink.props.append((model, o, (0, yaw, 0)))
    return ok


def seated(path):
    """The creeping walls in a VMF (read as text only), each checked: [(model, origin, angles, None or the fault)]."""
    B, ents = AL.parse(path)
    B = [b for b in B if b["cls"] in AL.STRUCT_CLASSES and b["kind"] not in ("tools", "sky")]
    room = Room(B, ground=False)
    out = []
    for e in ents:
        m = e.get("model", "")
        if e.get("classname", "").startswith("prop_") and "combineinnerwall" in m:
            o = [float(c) for c in e.get("origin", "0 0 0").split()]
            p, y, rl = (float(c) for c in e.get("angles", "0 0 0").split())
            fault = "tilted (pitch %g, roll %g)" % (p, rl) if abs(p) > 0.01 or abs(rl) > 0.01 else fits(room, m, o, y)
            out.append((m, o, (p, y, rl), fault))
    return out


__all__ = ["bbox", "boxes_as_brushes", "obb_brush", "Room", "wall", "fits", "stand", "seated", "as_brushes"]
