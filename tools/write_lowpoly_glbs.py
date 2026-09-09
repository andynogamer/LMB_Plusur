#!/usr/bin/env python3
"""Low-poly GLB catalog for D-22.

One shared stadium mesh and one shared articulated player. Only kit colors
change. Stadiums are static. Players are a biped joint hierarchy with clips
named exactly `idle`, `gesto`, and `celebracion` (node TRS, not skinned).

Run from the repo root:

    python tools/write_lowpoly_glbs.py
    python tools/write_lowpoly_glbs.py --only leones_yucatan
"""

from __future__ import annotations

import argparse
import json
import math
import struct
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "assets" / "models"

# Seats / jersey / cap = primary. Wall stripe / crest / brim = secondary.
CLUBS: dict[str, tuple[tuple[float, float, float, float], tuple[float, float, float, float]]] = {
    "diablos_rojos": ((0.72, 0.08, 0.10, 1), (0.10, 0.10, 0.10, 1)),
    "bravos_leon": ((0.75, 0.12, 0.14, 1), (0.08, 0.14, 0.32, 1)),
    "conspiradores_queretaro": ((0.48, 0.10, 0.18, 1), (0.10, 0.10, 0.10, 1)),
    "aguila_veracruz": ((0.78, 0.12, 0.14, 1), (0.93, 0.93, 0.93, 1)),
    "guerreros_oaxaca": ((0.48, 0.12, 0.18, 1), (0.83, 0.66, 0.22, 1)),
    "leones_yucatan": ((0.11, 0.32, 0.16, 1), (0.83, 0.66, 0.22, 1)),
    "olmecas_tabasco": ((0.10, 0.16, 0.36, 1), (0.90, 0.45, 0.12, 1)),
    "pericos_puebla": ((0.12, 0.42, 0.18, 1), (0.92, 0.78, 0.12, 1)),
    "piratas_campeche": ((0.72, 0.08, 0.10, 1), (0.10, 0.10, 0.10, 1)),
    "tigres_quintana_roo": ((0.10, 0.16, 0.36, 1), (0.90, 0.45, 0.12, 1)),
}

GRASS = (0.16, 0.38, 0.18, 1.0)
DIRT = (0.62, 0.42, 0.24, 1.0)
WALL = (0.20, 0.20, 0.22, 1.0)
POLE = (0.32, 0.32, 0.35, 1.0)
LIGHT = (1.0, 0.95, 0.72, 1.0)
WHITE = (0.93, 0.93, 0.90, 1.0)
CONCRETE = (0.50, 0.50, 0.47, 1.0)
YELLOW = (0.95, 0.82, 0.18, 1.0)
SKIN = (0.76, 0.56, 0.42, 1.0)
PANTS = (0.90, 0.90, 0.88, 1.0)
SHOE = (0.12, 0.12, 0.12, 1.0)
WOOD = (0.45, 0.28, 0.14, 1.0)
BASE = (0.22, 0.22, 0.24, 1.0)


class Vec:
    __slots__ = ("x", "y", "z")

    def __init__(self, x: float, y: float, z: float) -> None:
        self.x = float(x)
        self.y = float(y)
        self.z = float(z)

    def __sub__(self, other: Vec) -> Vec:
        return Vec(self.x - other.x, self.y - other.y, self.z - other.z)

    def cross(self, other: Vec) -> Vec:
        return Vec(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )

    def normalized(self) -> Vec:
        length = math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
        if length < 1e-12:
            return Vec(0, 1, 0)
        return Vec(self.x / length, self.y / length, self.z / length)


Color = tuple[float, float, float, float]


class Mesh:
    def __init__(self) -> None:
        self.positions: list[float] = []
        self.normals: list[float] = []
        self.colors: list[float] = []
        self.indices: list[int] = []

    @property
    def vertex_count(self) -> int:
        return len(self.positions) // 3

    @property
    def triangle_count(self) -> int:
        return len(self.indices) // 3

    def tri(self, a: Vec, b: Vec, c: Vec, color: Color) -> None:
        cross = (b - a).cross(c - a)
        length = math.sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
        if length < 1e-12:
            return
        normal = Vec(cross.x / length, cross.y / length, cross.z / length)
        start = self.vertex_count
        for point in (a, b, c):
            self.positions.extend((point.x, point.y, point.z))
            self.normals.extend((normal.x, normal.y, normal.z))
            self.colors.extend(color)
        self.indices.extend((start, start + 1, start + 2))

    def quad(self, a: Vec, b: Vec, c: Vec, d: Vec, color: Color) -> None:
        self.tri(a, b, c, color)
        self.tri(a, c, d, color)

    def box(self, x0: float, y0: float, z0: float, x1: float, y1: float, z1: float, color: Color) -> None:
        if x0 > x1:
            x0, x1 = x1, x0
        if y0 > y1:
            y0, y1 = y1, y0
        if z0 > z1:
            z0, z1 = z1, z0
        p = Vec
        self.quad(p(x0, y1, z0), p(x0, y1, z1), p(x1, y1, z1), p(x1, y1, z0), color)
        self.quad(p(x0, y0, z0), p(x1, y0, z0), p(x1, y0, z1), p(x0, y0, z1), color)
        self.quad(p(x1, y0, z0), p(x1, y1, z0), p(x1, y1, z1), p(x1, y0, z1), color)
        self.quad(p(x0, y0, z1), p(x0, y1, z1), p(x0, y1, z0), p(x0, y0, z0), color)
        self.quad(p(x1, y0, z1), p(x1, y1, z1), p(x0, y1, z1), p(x0, y0, z1), color)
        self.quad(p(x0, y0, z0), p(x0, y1, z0), p(x1, y1, z0), p(x1, y0, z0), color)

    def extrude_xz(self, ring_xz: list[tuple[float, float]], y0: float, y1: float, color: Color) -> None:
        n = len(ring_xz)
        if n < 3:
            return
        top = [Vec(x, y1, z) for x, z in ring_xz]
        bot = [Vec(x, y0, z) for x, z in ring_xz]
        for i in range(1, n - 1):
            self.tri(top[0], top[i], top[i + 1], color)
        for i in range(1, n - 1):
            self.tri(bot[0], bot[i + 1], bot[i], color)
        for i in range(n):
            j = (i + 1) % n
            self.quad(bot[i], top[i], top[j], bot[j], color)

    def cylinder(
        self,
        cx: float,
        y0: float,
        cz: float,
        radius: float,
        height: float,
        sides: int,
        color: Color,
    ) -> None:
        ring = [
            (
                cx + radius * math.cos(2 * math.pi * i / sides),
                cz + radius * math.sin(2 * math.pi * i / sides),
            )
            for i in range(sides)
        ]
        self.extrude_xz(ring, y0, y0 + height, color)

    def sphere(self, cx: float, cy: float, cz: float, radius: float, color: Color, segments: int = 8) -> None:
        """Low-poly UV sphere for baseball VFX particles."""
        rings = max(4, segments // 2)
        segs = max(6, segments)
        for i in range(rings):
            v0 = i / rings
            v1 = (i + 1) / rings
            y0 = cy + math.cos(v0 * math.pi) * radius
            y1 = cy + math.cos(v1 * math.pi) * radius
            r0 = math.sin(v0 * math.pi) * radius
            r1 = math.sin(v1 * math.pi) * radius
            for j in range(segs):
                a0 = (j / segs) * math.tau
                a1 = ((j + 1) / segs) * math.tau
                p00 = Vec(cx + math.cos(a0) * r0, y0, cz + math.sin(a0) * r0)
                p01 = Vec(cx + math.cos(a1) * r0, y0, cz + math.sin(a1) * r0)
                p10 = Vec(cx + math.cos(a0) * r1, y1, cz + math.sin(a0) * r1)
                p11 = Vec(cx + math.cos(a1) * r1, y1, cz + math.sin(a1) * r1)
                if i == 0:
                    self.tri(p00, p11, p10, color)
                elif i == rings - 1:
                    self.tri(p00, p01, p10, color)
                else:
                    self.quad(p00, p01, p11, p10, color)

    def bounds(self) -> tuple[list[float], list[float]]:
        xs = self.positions[0::3]
        ys = self.positions[1::3]
        zs = self.positions[2::3]
        return [min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)]


def _ngon(radius: float, sides: int, start_deg: float = 0.0) -> list[tuple[float, float]]:
    start = math.radians(start_deg)
    return [
        (
            radius * math.cos(start + 2 * math.pi * i / sides),
            radius * math.sin(start + 2 * math.pi * i / sides),
        )
        for i in range(sides)
    ]


def _arc_quads(
    r_in: float,
    r_out: float,
    a0: float,
    a1: float,
    segs: int,
) -> list[list[tuple[float, float]]]:
    rings = []
    for i in range(segs):
        t0 = a0 + (a1 - a0) * i / segs
        t1 = a0 + (a1 - a0) * (i + 1) / segs
        inner0 = (r_in * math.cos(t0), r_in * math.sin(t0))
        inner1 = (r_in * math.cos(t1), r_in * math.sin(t1))
        outer1 = (r_out * math.cos(t1), r_out * math.sin(t1))
        outer0 = (r_out * math.cos(t0), r_out * math.sin(t0))
        rings.append([inner0, inner1, outer1, outer0])
    return rings


def build_stadium(primary: Color, secondary: Color) -> Mesh:
    mesh = Mesh()
    # Home plate at -Z, center field at +Z. Y-up. ~11 cm to the light fixtures.
    mesh.extrude_xz(_ngon(0.092, 12), 0.0, 0.002, GRASS)

    diamond = 0.038
    mesh.extrude_xz(
        [(0.0, -diamond), (diamond, 0.0), (0.0, diamond), (-diamond, 0.0)],
        0.002,
        0.0032,
        DIRT,
    )
    mesh.cylinder(0.0, 0.0032, -0.006, 0.008, 0.004, 8, DIRT)
    mesh.box(-0.004, 0.007, -0.0072, 0.004, 0.0078, -0.0052, WHITE)

    def base_pad(x: float, z: float) -> None:
        mesh.box(x - 0.003, 0.0032, z - 0.003, x + 0.003, 0.0042, z + 0.003, WHITE)

    base_pad(diamond * 0.90, 0.0)
    base_pad(0.0, diamond * 0.90)
    base_pad(-diamond * 0.90, 0.0)
    home_z = -diamond
    mesh.extrude_xz(
        [
            (0.0, home_z - 0.004),
            (0.0045, home_z),
            (0.0025, home_z + 0.004),
            (-0.0025, home_z + 0.004),
            (-0.0045, home_z),
        ],
        0.0032,
        0.0044,
        WHITE,
    )

    # Foul lines, home toward 1B / 3B.
    mesh.box(0.0, 0.0032, home_z, 0.042, 0.0038, home_z + 0.0012, WHITE)
    mesh.box(-0.042, 0.0032, home_z, 0.0, 0.0038, home_z + 0.0012, WHITE)
    mesh.box(diamond - 0.0006, 0.0032, -0.002, diamond + 0.0006, 0.0038, 0.002, WHITE)
    mesh.box(-diamond - 0.0006, 0.0032, -0.002, -diamond + 0.0006, 0.0038, 0.002, WHITE)

    # Dugouts just outside the diamond.
    mesh.box(0.048, 0.002, -0.018, 0.062, 0.010, 0.012, CONCRETE)
    mesh.box(0.046, 0.010, -0.020, 0.064, 0.012, 0.014, primary)
    mesh.box(-0.062, 0.002, -0.018, -0.048, 0.010, 0.012, CONCRETE)
    mesh.box(-0.064, 0.010, -0.020, -0.046, 0.012, 0.014, primary)

    # Backstop behind home.
    mesh.box(-0.028, 0.002, -0.062, 0.028, 0.018, -0.056, WALL)

    wall_a0 = math.radians(28)
    wall_a1 = math.radians(152)
    for ring in _arc_quads(0.078, 0.084, wall_a0, wall_a1, 8):
        mesh.extrude_xz(ring, 0.002, 0.016, WALL)
    for ring in _arc_quads(0.077, 0.085, wall_a0, wall_a1, 8):
        mesh.extrude_xz(ring, 0.016, 0.019, secondary)

    # Crest on the center-field wall, facing the infield (-Z).
    cx, cy, cz = 0.0, 0.018, 0.081
    w, h = 0.009, 0.011
    top, right, bot, left = (
        Vec(cx, cy + h / 2, cz),
        Vec(cx + w / 2, cy, cz),
        Vec(cx, cy - h / 2, cz),
        Vec(cx - w / 2, cy, cz),
    )
    mesh.quad(top, right, bot, left, secondary)
    mesh.quad(top, left, bot, right, primary)

    for i, ring in enumerate(_arc_quads(0.086, 0.104, wall_a0, wall_a1, 8)):
        y0 = 0.002
        y1 = 0.016 + (i % 3) * 0.010
        mesh.extrude_xz(ring, y0, y1, primary)
        mesh.extrude_xz(
            [
                (ring[2][0], ring[2][1]),
                (ring[3][0], ring[3][1]),
                (ring[3][0] * 1.04, ring[3][1] * 1.04),
                (ring[2][0] * 1.04, ring[2][1] * 1.04),
            ],
            y1,
            y1 + 0.006,
            CONCRETE,
        )

    def tower(angle_deg: float) -> None:
        ang = math.radians(angle_deg)
        x = 0.100 * math.cos(ang)
        z = 0.100 * math.sin(ang)
        mesh.box(x - 0.0022, 0.002, z - 0.0022, x + 0.0022, 0.108, z + 0.0022, POLE)
        mesh.box(x - 0.009, 0.100, z - 0.009, x + 0.009, 0.112, z + 0.009, LIGHT)

    for deg in (40, 70, 110, 140):
        tower(deg)

    def foul_pole(angle_deg: float) -> None:
        ang = math.radians(angle_deg)
        x = 0.083 * math.cos(ang)
        z = 0.083 * math.sin(ang)
        mesh.box(x - 0.0014, 0.002, z - 0.0014, x + 0.0014, 0.072, z + 0.0014, YELLOW)

    foul_pole(28)
    foul_pole(152)
    return mesh


# Player bones. Limb meshes extend along local -Y from the joint.
HIP_Y = 0.050
THIGH_LEN = 0.024
SHIN_LEN = 0.022
UPPER_ARM_LEN = 0.016
FOREARM_LEN = 0.015
Q_I = (0.0, 0.0, 0.0, 1.0)


def _part_box(x0: float, y0: float, z0: float, x1: float, y1: float, z1: float, color: Color) -> Mesh:
    mesh = Mesh()
    mesh.box(x0, y0, z0, x1, y1, z1, color)
    return mesh


def _limb(length: float, half: float, color: Color) -> Mesh:
    return _part_box(-half, -length, -half, half, 0.0, half, color)


def _player_meshes(primary: Color, secondary: Color) -> list[Mesh]:
    base = Mesh()
    base.cylinder(0.0, 0.0, 0.0, 0.016, 0.003, 10, BASE)

    hips = _part_box(-0.012, -0.006, -0.007, 0.012, 0.007, 0.007, PANTS)
    hips.box(-0.012, -0.001, -0.0075, 0.012, 0.002, 0.0075, SHOE)

    spine = _part_box(-0.011, 0.0, -0.007, 0.011, 0.015, 0.007, primary)
    chest = _part_box(-0.014, 0.0, -0.008, 0.014, 0.017, 0.008, primary)
    chest.box(-0.005, 0.006, 0.007, 0.005, 0.013, 0.0095, secondary)

    head = Mesh()
    head.box(-0.008, 0.0, -0.008, 0.008, 0.016, 0.008, SKIN)
    head.box(-0.003, 0.006, 0.007, 0.003, 0.009, 0.009, (0.12, 0.10, 0.10, 1))

    cap = Mesh()
    cap.box(-0.009, 0.0, -0.009, 0.009, 0.008, 0.008, primary)
    cap.box(-0.007, 0.0, 0.008, 0.007, 0.004, 0.016, secondary)

    bat = Mesh()
    bat.cylinder(0.0, 0.0, 0.0, 0.0022, 0.018, 6, WOOD)
    bat.cylinder(0.0, 0.016, 0.0, 0.0036, 0.036, 6, WOOD)
    bat.cylinder(0.0, -0.003, 0.0, 0.0030, 0.004, 6, WOOD)

    return [
        base,
        hips,
        spine,
        chest,
        head,
        cap,
        _limb(UPPER_ARM_LEN, 0.004, primary),
        _limb(FOREARM_LEN, 0.0035, SKIN),
        _limb(UPPER_ARM_LEN, 0.004, primary),
        _limb(FOREARM_LEN, 0.0035, SKIN),
        bat,
        _limb(THIGH_LEN, 0.005, PANTS),
        _limb(SHIN_LEN, 0.0045, PANTS),
        _part_box(-0.005, -0.004, -0.004, 0.005, 0.0, 0.012, SHOE),
        _limb(THIGH_LEN, 0.005, PANTS),
        _limb(SHIN_LEN, 0.0045, PANTS),
        _part_box(-0.005, -0.004, -0.004, 0.005, 0.0, 0.012, SHOE),
    ]


def _quat_axis_angle(ax: float, ay: float, az: float, radians: float) -> tuple[float, float, float, float]:
    half = radians * 0.5
    s = math.sin(half)
    return (ax * s, ay * s, az * s, math.cos(half))


def _q_mul(
    a: tuple[float, float, float, float],
    b: tuple[float, float, float, float],
) -> tuple[float, float, float, float]:
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    )


def _q_euler(rx: float, ry: float, rz: float) -> tuple[float, float, float, float]:
    return _q_mul(
        _q_mul(_quat_axis_angle(1, 0, 0, rx), _quat_axis_angle(0, 1, 0, ry)),
        _quat_axis_angle(0, 0, 1, rz),
    )


def _q_deg(rx: float = 0.0, ry: float = 0.0, rz: float = 0.0) -> tuple[float, float, float, float]:
    return _q_euler(math.radians(rx), math.radians(ry), math.radians(rz))


def _q_add(rest: tuple[float, float, float, float], rx: float = 0.0, ry: float = 0.0, rz: float = 0.0):
    return _q_mul(rest, _q_deg(rx, ry, rz))


def _pad(data: bytes, fill: bytes) -> bytes:
    extra = (4 - (len(data) % 4)) % 4
    return data + fill * extra


def _append_array(blob: bytearray, values: array) -> tuple[int, int]:
    offset = len(blob)
    raw = values.tobytes()
    blob.extend(raw)
    pad = (4 - (len(blob) % 4)) % 4
    blob.extend(b"\x00" * pad)
    return offset, len(raw)


def _mesh_views(
    blob: bytearray,
    mesh: Mesh,
    buffer_views: list[dict],
    accessors: list[dict],
) -> dict:
    pos = array("f", mesh.positions)
    nrm = array("f", mesh.normals)
    col = array("f", mesh.colors)
    idx = array("H", mesh.indices)
    pos_off, pos_len = _append_array(blob, pos)
    nrm_off, nrm_len = _append_array(blob, nrm)
    col_off, col_len = _append_array(blob, col)
    idx_off, idx_len = _append_array(blob, idx)
    mn, mx = mesh.bounds()
    pos_view = len(buffer_views)
    buffer_views.append(
        {"buffer": 0, "byteOffset": pos_off, "byteLength": pos_len, "target": 34962}
    )
    nrm_view = len(buffer_views)
    buffer_views.append(
        {"buffer": 0, "byteOffset": nrm_off, "byteLength": nrm_len, "target": 34962}
    )
    col_view = len(buffer_views)
    buffer_views.append(
        {"buffer": 0, "byteOffset": col_off, "byteLength": col_len, "target": 34962}
    )
    idx_view = len(buffer_views)
    buffer_views.append(
        {"buffer": 0, "byteOffset": idx_off, "byteLength": idx_len, "target": 34963}
    )
    pos_acc = len(accessors)
    accessors.append(
        {
            "bufferView": pos_view,
            "componentType": 5126,
            "count": mesh.vertex_count,
            "type": "VEC3",
            "min": mn,
            "max": mx,
        }
    )
    nrm_acc = len(accessors)
    accessors.append(
        {
            "bufferView": nrm_view,
            "componentType": 5126,
            "count": mesh.vertex_count,
            "type": "VEC3",
        }
    )
    col_acc = len(accessors)
    accessors.append(
        {
            "bufferView": col_view,
            "componentType": 5126,
            "count": mesh.vertex_count,
            "type": "VEC4",
        }
    )
    idx_acc = len(accessors)
    accessors.append(
        {
            "bufferView": idx_view,
            "componentType": 5123,
            "count": len(mesh.indices),
            "type": "SCALAR",
        }
    )
    return {
        "attributes": {"POSITION": pos_acc, "NORMAL": nrm_acc, "COLOR_0": col_acc},
        "indices": idx_acc,
        "material": 0,
    }


def _write_glb(path: Path, gltf: dict, blob: bytes) -> None:
    json_bytes = _pad(json.dumps(gltf, separators=(",", ":")).encode("utf-8"), b" ")
    bin_bytes = _pad(blob, b"\x00")
    total = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
    out = bytearray()
    out.extend(struct.pack("<III", 0x46546C67, 2, total))
    out.extend(struct.pack("<II", len(json_bytes), 0x4E4F534A))
    out.extend(json_bytes)
    out.extend(struct.pack("<II", len(bin_bytes), 0x004E4942))
    out.extend(bin_bytes)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(out)


def write_stadium(path: Path, primary: Color, secondary: Color) -> Mesh:
    mesh = build_stadium(primary, secondary)
    blob = bytearray()
    buffer_views: list[dict] = []
    accessors: list[dict] = []
    primitive = _mesh_views(blob, mesh, buffer_views, accessors)
    gltf = {
        "asset": {"version": "2.0", "generator": "LMB Plusur low-poly stadium"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "estadio", "mesh": 0}],
        "meshes": [{"name": "estadio", "primitives": [primitive]}],
        "materials": [
            {
                "name": "vertexColor",
                "pbrMetallicRoughness": {
                    "baseColorFactor": [1, 1, 1, 1],
                    "metallicFactor": 0.05,
                    "roughnessFactor": 0.72,
                },
            }
        ],
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    _write_glb(path, gltf, bytes(blob))
    return mesh


def write_player(path: Path, primary: Color, secondary: Color) -> tuple[int, tuple[list[float], list[float]]]:
    meshes = _player_meshes(primary, secondary)
    blob = bytearray()
    buffer_views: list[dict] = []
    accessors: list[dict] = []
    primitives = [_mesh_views(blob, mesh, buffer_views, accessors) for mesh in meshes]
    mesh_names = [
        "base",
        "hips",
        "spine",
        "chest",
        "head",
        "cap",
        "l_arm",
        "l_fore",
        "r_arm",
        "r_fore",
        "bate",
        "l_thigh",
        "l_shin",
        "l_foot",
        "r_thigh",
        "r_shin",
        "r_foot",
    ]

    l_arm_rest = _q_deg(rx=8, rz=14)
    r_arm_rest = _q_deg(rx=-22, rz=-42)
    l_fore_rest = Q_I
    r_fore_rest = _q_deg(rx=-82)
    bat_rest = _q_deg(rx=168, ry=18, rz=-28)

    nodes = [
        {"name": "jugador", "children": [1, 2]},
        {"name": "base", "mesh": 0},
        {
            "name": "hips",
            "mesh": 1,
            "translation": [0.0, HIP_Y, 0.0],
            "children": [3, 12, 15],
        },
        {"name": "spine", "mesh": 2, "translation": [0.0, 0.007, 0.0], "children": [4]},
        {
            "name": "chest",
            "mesh": 3,
            "translation": [0.0, 0.015, 0.0],
            "children": [5, 7, 9],
        },
        {"name": "head", "mesh": 4, "translation": [0.0, 0.017, 0.0], "children": [6]},
        {"name": "cap", "mesh": 5, "translation": [0.0, 0.012, 0.0]},
        {
            "name": "l_arm",
            "mesh": 6,
            "translation": [-0.017, 0.010, 0.0],
            "rotation": list(l_arm_rest),
            "children": [8],
        },
        {
            "name": "l_fore",
            "mesh": 7,
            "translation": [0.0, -UPPER_ARM_LEN, 0.0],
            "rotation": list(l_fore_rest),
        },
        {
            "name": "r_arm",
            "mesh": 8,
            "translation": [0.017, 0.010, 0.0],
            "rotation": list(r_arm_rest),
            "children": [10],
        },
        {
            "name": "r_fore",
            "mesh": 9,
            "translation": [0.0, -UPPER_ARM_LEN, 0.0],
            "rotation": list(r_fore_rest),
            "children": [11],
        },
        {
            "name": "bate",
            "mesh": 10,
            "translation": [0.0, -FOREARM_LEN, 0.002],
            "rotation": list(bat_rest),
        },
        {
            "name": "l_thigh",
            "mesh": 11,
            "translation": [-0.008, 0.0, 0.0],
            "children": [13],
        },
        {
            "name": "l_shin",
            "mesh": 12,
            "translation": [0.0, -THIGH_LEN, 0.0],
            "children": [14],
        },
        {"name": "l_foot", "mesh": 13, "translation": [0.0, -SHIN_LEN, 0.0]},
        {
            "name": "r_thigh",
            "mesh": 14,
            "translation": [0.008, 0.0, 0.0],
            "children": [16],
        },
        {
            "name": "r_shin",
            "mesh": 15,
            "translation": [0.0, -THIGH_LEN, 0.0],
            "children": [17],
        },
        {"name": "r_foot", "mesh": 16, "translation": [0.0, -SHIN_LEN, 0.0]},
    ]

    # Node indices for animation targets.
    n_hips, n_spine, n_chest, n_head = 2, 3, 4, 5
    n_l_arm, n_l_fore, n_r_arm, n_r_fore, n_bat = 7, 8, 9, 10, 11
    n_l_thigh, n_l_shin, n_r_thigh, n_r_shin = 12, 13, 15, 16

    def acc_f(values: array, type_name: str, count: int, tmin: float | None = None, tmax: float | None = None) -> int:
        off, length = _append_array(blob, values)
        view = len(buffer_views)
        buffer_views.append({"buffer": 0, "byteOffset": off, "byteLength": length})
        idx = len(accessors)
        spec: dict = {
            "bufferView": view,
            "componentType": 5126,
            "count": count,
            "type": type_name,
        }
        if tmin is not None:
            spec["min"] = [tmin]
            spec["max"] = [tmax]
        accessors.append(spec)
        return idx

    def quat_track(keys: list[tuple[float, float, float, float]]) -> array:
        out: list[float] = []
        for key in keys:
            out.extend(key)
        return array("f", out)

    idle_times = array("f", [0.0, 0.75, 1.5, 2.25, 3.0])
    idle_t = acc_f(idle_times, "SCALAR", 5, 0.0, 3.0)
    # Weight shift L → rest → R → rest, plus a breath on the spine.
    idle_tracks = [
        (n_hips, quat_track([Q_I, _q_deg(ry=6, rz=-5), Q_I, _q_deg(ry=-6, rz=5), Q_I])),
        (n_spine, quat_track([Q_I, _q_deg(rx=6), _q_deg(rx=9), _q_deg(rx=6), Q_I])),
        (n_chest, quat_track([Q_I, _q_deg(rx=3), _q_deg(rx=5), _q_deg(rx=3), Q_I])),
        (n_head, quat_track([Q_I, _q_deg(rx=-4), Q_I, _q_deg(rx=-4), Q_I])),
        (
            n_l_arm,
            quat_track(
                [
                    l_arm_rest,
                    _q_add(l_arm_rest, rz=6),
                    l_arm_rest,
                    _q_add(l_arm_rest, rz=-4),
                    l_arm_rest,
                ]
            ),
        ),
        (
            n_r_arm,
            quat_track(
                [
                    r_arm_rest,
                    _q_add(r_arm_rest, rz=-4),
                    r_arm_rest,
                    _q_add(r_arm_rest, rz=6),
                    r_arm_rest,
                ]
            ),
        ),
        (n_l_thigh, quat_track([Q_I, _q_deg(rx=5, rz=4), Q_I, _q_deg(rx=3, rz=-3), Q_I])),
        (n_r_thigh, quat_track([Q_I, _q_deg(rx=3, rz=-3), Q_I, _q_deg(rx=5, rz=4), Q_I])),
        (n_l_shin, quat_track([Q_I, _q_deg(rx=8), Q_I, _q_deg(rx=4), Q_I])),
        (n_r_shin, quat_track([Q_I, _q_deg(rx=4), Q_I, _q_deg(rx=8), Q_I])),
    ]

    r_arm_wind = _q_deg(rx=12, rz=-58)
    r_arm_point = _q_deg(rx=-82, ry=16, rz=-12)
    r_fore_wind = _q_deg(rx=-105)
    r_fore_point = _q_deg(rx=-18)
    bat_point = _q_deg(rx=180, ry=8)
    l_arm_point = _q_deg(rx=-18, rz=28)
    hips_point = _q_deg(ry=16, rz=-6)
    spine_point = _q_deg(rx=-8, ry=20)
    chest_point = _q_deg(ry=8)
    head_point = _q_deg(rx=-6, ry=12)

    gesto_times = array("f", [0.0, 0.45, 1.1, 1.7, 2.4])
    gesto_t = acc_f(gesto_times, "SCALAR", 5, 0.0, 2.4)
    gesto_tracks = [
        (n_hips, quat_track([Q_I, _q_deg(ry=8, rz=-4), hips_point, hips_point, Q_I])),
        (n_spine, quat_track([Q_I, _q_deg(ry=10), spine_point, spine_point, Q_I])),
        (n_chest, quat_track([Q_I, _q_deg(ry=4), chest_point, chest_point, Q_I])),
        (n_head, quat_track([Q_I, _q_deg(rx=-8), head_point, head_point, Q_I])),
        (n_l_arm, quat_track([l_arm_rest, _q_add(l_arm_rest, rx=-10), l_arm_point, l_arm_point, l_arm_rest])),
        (n_l_fore, quat_track([l_fore_rest, _q_deg(rx=-20), _q_deg(rx=-12), _q_deg(rx=-12), l_fore_rest])),
        (n_r_arm, quat_track([r_arm_rest, r_arm_wind, r_arm_point, r_arm_point, r_arm_rest])),
        (n_r_fore, quat_track([r_fore_rest, r_fore_wind, r_fore_point, r_fore_point, r_fore_rest])),
        (n_bat, quat_track([bat_rest, bat_rest, bat_point, bat_point, bat_rest])),
        (n_l_thigh, quat_track([Q_I, _q_deg(rx=6), _q_deg(rx=10, rz=3), _q_deg(rx=10, rz=3), Q_I])),
        (n_r_thigh, quat_track([Q_I, _q_deg(rx=4, rz=-2), _q_deg(rx=6, rz=-4), _q_deg(rx=6, rz=-4), Q_I])),
        (n_l_shin, quat_track([Q_I, _q_deg(rx=6), _q_deg(rx=12), _q_deg(rx=12), Q_I])),
        (n_r_shin, quat_track([Q_I, _q_deg(rx=4), _q_deg(rx=8), _q_deg(rx=8), Q_I])),
    ]

    # Home-run celebration: both arms up, bat overhead, small hop, hold, return.
    r_arm_up = _q_deg(rx=-150, rz=-18)
    l_arm_up = _q_deg(rx=-145, rz=22)
    r_fore_up = _q_deg(rx=-25)
    l_fore_up = _q_deg(rx=-20)
    bat_up = _q_deg(rx=200, ry=-10)
    hips_hop = _q_deg(rx=-8, ry=10)
    spine_cheer = _q_deg(rx=-18, ry=8)
    chest_cheer = _q_deg(rx=-10)
    head_cheer = _q_deg(rx=-22, ry=6)

    celeb_times = array("f", [0.0, 0.35, 0.9, 1.8, 2.8])
    celeb_t = acc_f(celeb_times, "SCALAR", 5, 0.0, 2.8)
    celeb_tracks = [
        (n_hips, quat_track([Q_I, _q_deg(rx=-4, ry=6), hips_hop, hips_hop, Q_I])),
        (n_spine, quat_track([Q_I, _q_deg(rx=-8), spine_cheer, spine_cheer, Q_I])),
        (n_chest, quat_track([Q_I, _q_deg(rx=-6), chest_cheer, chest_cheer, Q_I])),
        (n_head, quat_track([Q_I, _q_deg(rx=-10), head_cheer, head_cheer, Q_I])),
        (n_l_arm, quat_track([l_arm_rest, _q_add(l_arm_rest, rx=-40), l_arm_up, l_arm_up, l_arm_rest])),
        (n_l_fore, quat_track([l_fore_rest, _q_deg(rx=-30), l_fore_up, l_fore_up, l_fore_rest])),
        (n_r_arm, quat_track([r_arm_rest, _q_add(r_arm_rest, rx=-50), r_arm_up, r_arm_up, r_arm_rest])),
        (n_r_fore, quat_track([r_fore_rest, _q_deg(rx=-40), r_fore_up, r_fore_up, r_fore_rest])),
        (n_bat, quat_track([bat_rest, _q_deg(rx=160), bat_up, bat_up, bat_rest])),
        (n_l_thigh, quat_track([Q_I, _q_deg(rx=8), _q_deg(rx=14, rz=4), _q_deg(rx=14, rz=4), Q_I])),
        (n_r_thigh, quat_track([Q_I, _q_deg(rx=8, rz=-3), _q_deg(rx=12, rz=-5), _q_deg(rx=12, rz=-5), Q_I])),
        (n_l_shin, quat_track([Q_I, _q_deg(rx=10), _q_deg(rx=16), _q_deg(rx=16), Q_I])),
        (n_r_shin, quat_track([Q_I, _q_deg(rx=8), _q_deg(rx=14), _q_deg(rx=14), Q_I])),
    ]

    def animation(name: str, time_acc: int, tracks: list[tuple[int, array]]) -> dict:
        samplers = []
        channels = []
        for node, values in tracks:
            output = acc_f(values, "VEC4", len(values) // 4)
            sampler = len(samplers)
            samplers.append({"input": time_acc, "output": output, "interpolation": "LINEAR"})
            channels.append({"sampler": sampler, "target": {"node": node, "path": "rotation"}})
        return {"name": name, "samplers": samplers, "channels": channels}

    gltf = {
        "asset": {"version": "2.0", "generator": "LMB Plusur low-poly biped"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": nodes,
        "meshes": [{"name": name, "primitives": [prim]} for name, prim in zip(mesh_names, primitives)],
        "materials": [
            {
                "name": "vertexColor",
                "pbrMetallicRoughness": {
                    "baseColorFactor": [1, 1, 1, 1],
                    "metallicFactor": 0.08,
                    "roughnessFactor": 0.65,
                },
            }
        ],
        "animations": [
            animation("idle", idle_t, idle_tracks),
            animation("gesto", gesto_t, gesto_tracks),
            animation("celebracion", celeb_t, celeb_tracks),
        ],
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    _write_glb(path, gltf, bytes(blob))
    tris = sum(mesh.triangle_count for mesh in meshes)
    return tris, ([0.0, 0.0, -0.016], [0.016, 0.115, 0.016])


def write_efecto_jonron(path: Path) -> tuple[int, tuple[list[float], list[float]]]:
    """One baseball for US-13. Dart spawns several nodes and animates them."""
    mesh = Mesh()
    ball = (0.96, 0.96, 0.92, 1.0)
    stitch = (0.86, 0.10, 0.12, 1.0)
    seam = (0.78, 0.78, 0.74, 1.0)
    r = 0.009
    mesh.sphere(0.0, 0.0, 0.0, r, ball, segments=12)
    # Classic horseshoe stitches (thin curved strips approximated by boxes).
    for side in (-1.0, 1.0):
        for i in range(6):
            t = (i + 0.5) / 6
            ang = (t - 0.5) * 1.6
            y = math.sin(ang) * r * 0.72
            z = side * math.cos(ang) * r * 0.55
            x = side * (0.35 + 0.45 * math.cos(ang)) * r
            mesh.box(x - 0.0012, y - 0.0009, z - 0.0022, x + 0.0012, y + 0.0009, z + 0.0022, stitch)
    # Soft equator seam so the ball reads as a sphere, not a blob.
    mesh.box(-r * 0.85, -0.0006, -0.0006, r * 0.85, 0.0006, 0.0006, seam)

    blob = bytearray()
    buffer_views: list[dict] = []
    accessors: list[dict] = []
    prim = _mesh_views(blob, mesh, buffer_views, accessors)
    gltf = {
        "asset": {"version": "2.0", "generator": "LMB Plusur pelota efecto"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "pelota"}],
        "meshes": [{"name": "pelota", "primitives": [prim]}],
        "materials": [
            {
                "name": "vertexColor",
                "pbrMetallicRoughness": {
                    "baseColorFactor": [1, 1, 1, 1],
                    "metallicFactor": 0.04,
                    "roughnessFactor": 0.62,
                },
            }
        ],
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    _write_glb(path, gltf, bytes(blob))
    return mesh.triangle_count, mesh.bounds()


def _report(kind: str, path: Path, tris: int, size: int, bounds: tuple[list[float], list[float]]) -> None:
    mn, mx = bounds
    height = mx[1] - mn[1]
    print(
        f"{kind:8} {path.relative_to(ROOT)}  {size:6} B  {tris:4} tris  "
        f"h={height*100:.1f} cm  y=[{mn[1]*100:.1f},{mx[1]*100:.1f}]"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Write the D-22 low-poly GLB catalog.")
    parser.add_argument("--only", help="Single club id, e.g. leones_yucatan")
    parser.add_argument("--stadiums-only", action="store_true")
    parser.add_argument("--players-only", action="store_true")
    parser.add_argument("--efecto-only", action="store_true")
    args = parser.parse_args()
    if args.efecto_only:
        path = MODELS / "efecto_jonron" / "modelo.glb"
        tris, bounds = write_efecto_jonron(path)
        _report("efecto", path, tris, path.stat().st_size, bounds)
        return 0
    clubs = CLUBS
    if args.only:
        if args.only not in CLUBS:
            raise SystemExit(f"Unknown club {args.only!r}. Known: {', '.join(CLUBS)}")
        clubs = {args.only: CLUBS[args.only]}

    for club, (primary, secondary) in clubs.items():
        folder = MODELS / club
        if not args.players_only:
            path = folder / "estadio.glb"
            mesh = write_stadium(path, primary, secondary)
            _report("estadio", path, mesh.triangle_count, path.stat().st_size, mesh.bounds())
            if club == "leones_yucatan":
                scan = MODELS / "marcador_estadio_leones" / "modelo.glb"
                scan.write_bytes(path.read_bytes())
                _report("scan", scan, mesh.triangle_count, scan.stat().st_size, mesh.bounds())
        if not args.stadiums_only:
            path = folder / "jugador.glb"
            tris, bounds = write_player(path, primary, secondary)
            _report("jugador", path, tris, path.stat().st_size, bounds)
            if club == "olmecas_tabasco":
                scan = MODELS / "marcador_jugador_olmecas" / "modelo.glb"
                scan.write_bytes(path.read_bytes())
                _report("scan", scan, tris, scan.stat().st_size, bounds)

    if not args.stadiums_only and not args.only:
        path = MODELS / "efecto_jonron" / "modelo.glb"
        tris, bounds = write_efecto_jonron(path)
        _report("efecto", path, tris, path.stat().st_size, bounds)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
