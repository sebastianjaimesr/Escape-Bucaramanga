"""Genera todo el pixel art original de Escape de Bucaramanga.

Uso:  py tools/generate_art.py
Requiere Pillow y numpy. Todos los recursos son originales y procedurales.
"""
import math
import os
import random

from PIL import Image, ImageDraw

from pixelfont import draw_text, text_width

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets")
OUTLINE = (20, 12, 28, 255)


def path(*parts):
    p = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def shade(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))),
            max(0, min(255, int(c[2] * f))), c[3])


def add_outline(img, color=OUTLINE):
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0 and src[nx, ny] != color:
                    dst[x, y] = color
                    break
    return out


def thick_line(d, p0, p1, color, width):
    x0, y0 = p0
    x1, y1 = p1
    steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    r = width / 2.0
    for i in range(steps + 1):
        t = i / max(1, steps)
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        d.rectangle([round(x - r + 0.5), round(y - r + 0.5),
                     round(x + r - 0.5), round(y + r - 0.5)], fill=color)


# ---------------------------------------------------------------------------
# Personajes
# ---------------------------------------------------------------------------
SKIN = hexc("#c98a5e")
SKIN_DARK = hexc("#a46a44")

CHARACTERS = {
    # Protagonista: camiseta roja amplia con estampado, jeans azules rotos,
    # tenis blancos con rojo, mochila negra, pulsera dorada, cabello corto oscuro.
    "protagonist": dict(
        hair=hexc("#1b1414"), hair_style="short", shirt=hexc("#d7263d"),
        print_color=hexc("#f6f1e9"), pants=hexc("#3b6fb6"), rips=hexc("#a9c6ea"),
        shoes=hexc("#f4f4f4"), shoe_detail=hexc("#d7263d"), backpack=hexc("#151515"),
        bracelet=hexc("#f2c14e"), skin=SKIN, glasses=False, shorts=False, cap=None),
    # Amigo 1 "Gorra": gorra verde hacia atrÃ¡s, buzo verde, joggers negros.
    "friend_gorra": dict(
        hair=hexc("#2a1d14"), hair_style="short", shirt=hexc("#2f8f5b"),
        print_color=hexc("#9fe2bf"), pants=hexc("#26262e"), rips=None,
        shoes=hexc("#9a9aa6"), shoe_detail=hexc("#2f8f5b"), backpack=None,
        bracelet=None, skin=hexc("#b77b52"), glasses=False, shorts=False,
        cap=hexc("#1f6b43")),
    # Amigo 2 "Rulos": cabello rizado voluminoso, camiseta amarilla, bermuda beige.
    "friend_rulos": dict(
        hair=hexc("#3a2418"), hair_style="curly", shirt=hexc("#f2c14e"),
        print_color=hexc("#e07a1f"), pants=hexc("#c8b28a"), rips=None,
        shoes=hexc("#2b2b2b"), shoe_detail=hexc("#f4f4f4"), backpack=None,
        bracelet=None, skin=hexc("#8d5a3b"), glasses=False, shorts=True, cap=None),
    # Amigo 3 "Gafas": cabello largo, gafas, chaqueta azul sobre camiseta blanca.
    "friend_gafas": dict(
        hair=hexc("#4a2e1f"), hair_style="long", shirt=hexc("#2e4a8f"),
        print_color=hexc("#f4f4f4"), pants=hexc("#1f2440"), rips=None,
        shoes=hexc("#5a3a26"), shoe_detail=hexc("#2b1a10"), backpack=None,
        bracelet=None, skin=hexc("#d9a27a"), glasses=True, shorts=False, cap=None),
}

FRAME = 32
ANIMS = ["idle", "walk", "run", "jump", "fall", "hurt", "interact"]
ANIM_FRAMES = {"idle": 4, "walk": 6, "run": 6, "jump": 2, "fall": 2, "hurt": 2, "interact": 4}


def pose_for(anim, i):
    p = dict(bob=0, lean=0, front=(2, 0), back=(-2, 0), arm_f=8, arm_b=-8, tint=None, open_mouth=False)
    if anim == "idle":
        p["bob"] = [0, 0, 1, 1][i]
        p["arm_f"] = [6, 6, 9, 9][i]
        p["arm_b"] = [-6, -6, -9, -9][i]
    elif anim in ("walk", "run"):
        amp = 4 if anim == "walk" else 6
        lift = 2 if anim == "walk" else 3
        t = i / 6.0 * math.tau
        s = math.sin(t)
        c = math.cos(t)
        p["front"] = (round(amp * s), round(max(0.0, c) * lift))
        p["back"] = (round(-amp * s), round(max(0.0, -c) * lift))
        swing = 28 if anim == "walk" else 55
        p["arm_f"] = -swing * s
        p["arm_b"] = swing * s
        p["bob"] = 1 if abs(s) > 0.8 else 0
        if anim == "run":
            p["lean"] = 2
    elif anim == "jump":
        p["front"] = (3, 5 - i)
        p["back"] = (-3, 3 - i)
        p["arm_f"] = -140 + i * 15
        p["arm_b"] = 150
        p["bob"] = -1
    elif anim == "fall":
        p["front"] = (2, 0)
        p["back"] = (-3, 1)
        p["arm_f"] = -150 + i * 25
        p["arm_b"] = 160 - i * 25
    elif anim == "hurt":
        p["lean"] = -2
        p["front"] = (3, 1)
        p["back"] = (-1, 0)
        p["arm_f"] = -60
        p["arm_b"] = -110
        p["tint"] = (255, 80, 80) if i == 0 else (255, 255, 255)
        p["open_mouth"] = True
    elif anim == "interact":
        p["arm_f"] = [-150, -170, -150, -130][i]
        p["bob"] = [0, 0, 1, 0][i]
        p["open_mouth"] = i % 2 == 0
    return p


def draw_character(spec, pose):
    img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bob = pose["bob"]
    lean = pose["lean"]
    hip = (16, 21 + bob)
    shoulder = (16 + lean, 13 + bob)
    skin = spec["skin"]
    pants = spec["pants"]
    pants_back = shade(pants, 0.72)

    def leg(foot_off, color, front):
        fx, lift = foot_off
        foot = (16 + fx, 29 - lift)
        knee = ((hip[0] + foot[0]) / 2 + (1.5 if front else 1), (hip[1] + foot[1]) / 2)
        if spec["shorts"]:
            thick_line(d, hip, knee, color, 3)
            thick_line(d, knee, foot, skin if front else shade(skin, 0.8), 2)
        else:
            thick_line(d, hip, knee, color, 3)
            thick_line(d, knee, foot, color, 3)
            if spec["rips"] is not None and front:
                d.point((round(knee[0]), round(knee[1])), fill=spec["rips"])
                d.point((round(knee[0]) + 1, round(knee[1]) - 1), fill=spec["rips"])
        shoe = spec["shoes"] if front else shade(spec["shoes"], 0.8)
        d.rectangle([foot[0] - 2, foot[1], foot[0] + 2, foot[1] + 2], fill=shoe)
        d.point((foot[0] + 3, foot[1] + 2), fill=shoe)
        d.point((foot[0] - 1, foot[1] + 1), fill=spec["shoe_detail"])
        d.point((foot[0], foot[1] + 1), fill=spec["shoe_detail"])

    def arm(angle_deg, front):
        a = math.radians(angle_deg)
        length = 7
        sx, sy = shoulder[0], shoulder[1] + 1
        elbow = (sx + math.sin(a) * 3, sy + math.cos(a) * 3)
        hand = (sx + math.sin(a) * length, sy + math.cos(a) * length)
        sleeve = spec["shirt"] if front else shade(spec["shirt"], 0.75)
        sk = skin if front else shade(skin, 0.8)
        thick_line(d, (sx, sy), elbow, sleeve, 3)
        thick_line(d, elbow, hand, sk, 2)
        if front and spec["bracelet"] is not None:
            wx = sx + math.sin(a) * 5.5
            wy = sy + math.cos(a) * 5.5
            d.point((round(wx), round(wy)), fill=spec["bracelet"])

    # Capas traseras
    arm(pose["arm_b"], False)
    leg(pose["back"], pants_back, False)
    if spec["hair_style"] == "long":
        d.rectangle([12 + lean, 6 + bob, 14 + lean, 14 + bob], fill=shade(spec["hair"], 0.85))
    if spec["backpack"] is not None:
        d.rectangle([9 + lean, 13 + bob, 12 + lean, 20 + bob], fill=spec["backpack"])
        d.point((10 + lean, 15 + bob), fill=(60, 60, 60, 255))
        d.point((11 + lean, 18 + bob), fill=(60, 60, 60, 255))
    leg(pose["front"], pants, True)
    # Torso (camiseta amplia, ligeramente inclinada)
    shirt = spec["shirt"]
    d.polygon([(12 + lean, 12 + bob), (20 + lean, 12 + bob), (20, 22 + bob), (12, 22 + bob)], fill=shirt)
    d.line([(12, 22 + bob), (20, 22 + bob)], fill=shade(shirt, 0.8))
    if spec["backpack"] is not None:
        d.line([(14 + lean, 12 + bob), (13, 20 + bob)], fill=spec["backpack"])
    # Estampado
    pc = spec["print_color"]
    d.rectangle([16 + lean, 15 + bob, 18 + lean, 17 + bob], fill=pc)
    d.point((17 + lean, 16 + bob), fill=shade(shirt, 0.6))
    if spec["hair_style"] == "long":  # chaqueta abierta con camiseta clara
        d.line([(19 + lean, 13 + bob), (19, 21 + bob)], fill=pc)
    # Cabeza
    hx = 13 + lean
    hy = 4 + bob
    d.rectangle([hx, hy, hx + 6, hy + 7], fill=skin)
    d.point((hx, hy), fill=(0, 0, 0, 0))
    d.point((hx + 6, hy + 7), fill=(0, 0, 0, 0))
    d.point((hx + 2, hy + 4), fill=SKIN_DARK)  # oreja
    d.point((hx + 5, hy + 3), fill=(25, 18, 22, 255))  # ojo
    if pose["open_mouth"]:
        d.point((hx + 6, hy + 6), fill=(90, 30, 30, 255))
    else:
        d.point((hx + 5, hy + 6), fill=shade(skin, 0.75))
    hair = spec["hair"]
    style = spec["hair_style"]
    if style == "short":
        d.rectangle([hx - 1, hy - 1, hx + 6, hy + 1], fill=hair)
        d.rectangle([hx - 1, hy, hx + 1, hy + 4], fill=hair)
        d.point((hx + 6, hy + 2), fill=hair)
    elif style == "curly":
        for (cx, cy) in [(-2, -2), (0, -3), (2, -3), (4, -3), (6, -2), (-2, 0), (-2, 2), (7, 0), (-1, 4)]:
            d.rectangle([hx + cx, hy + cy, hx + cx + 2, hy + cy + 2], fill=hair)
        d.point((hx + 1, hy - 2), fill=shade(hair, 1.5))
        d.point((hx + 4, hy - 2), fill=shade(hair, 1.5))
    elif style == "long":
        d.rectangle([hx - 1, hy - 1, hx + 6, hy + 1], fill=hair)
        d.rectangle([hx - 2, hy, hx + 1, hy + 9], fill=hair)
    if spec["cap"] is not None:
        cap = spec["cap"]
        d.rectangle([hx - 1, hy - 2, hx + 6, hy + 1], fill=cap)
        d.rectangle([hx - 4, hy, hx - 1, hy + 1], fill=shade(cap, 0.75))  # visera hacia atrÃ¡s
    if spec["glasses"]:
        d.line([(hx + 3, hy + 3), (hx + 7, hy + 3)], fill=(20, 20, 30, 255))
        d.point((hx + 5, hy + 3), fill=(170, 220, 255, 255))
        d.point((hx + 6, hy + 3), fill=(170, 220, 255, 255))
    arm(pose["arm_f"], True)
    img = add_outline(img)
    if pose["tint"] is not None:
        tr, tg, tb = pose["tint"]
        px = img.load()
        for y in range(FRAME):
            for x in range(FRAME):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = ((r + tr) // 2, (g + tg) // 2, (b + tb) // 2, a)
    return img


def make_character_sheets():
    cols = max(ANIM_FRAMES.values())
    for name, spec in CHARACTERS.items():
        sheet = Image.new("RGBA", (FRAME * cols, FRAME * len(ANIMS)), (0, 0, 0, 0))
        for row, anim in enumerate(ANIMS):
            for i in range(ANIM_FRAMES[anim]):
                sheet.paste(draw_character(spec, pose_for(anim, i)), (i * FRAME, row * FRAME))
        sheet.save(path("characters", name + ".png"))
        # Retrato 4x para diÃ¡logos (vista lateral idle, ampliada sin filtrado)
        face = draw_character(spec, pose_for("idle", 0)).crop((6, 0, 26, 20))
        face = face.resize((80, 80), Image.NEAREST)
        face.save(path("characters", name + "_portrait.png"))


# ---------------------------------------------------------------------------
# Enemigos y persecuciÃ³n
# ---------------------------------------------------------------------------

def make_patrol_drone():
    """Dron patrulla ficticio (perseguidor) con luces rojas y azules."""
    w, h = 48, 32
    sheet = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
    for f in range(4):
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        body = hexc("#e8ecf2")
        navy = hexc("#1d2b53")
        d.rounded_rectangle([8, 12, 40, 24], radius=5, fill=body)
        d.rectangle([8, 18, 40, 21], fill=navy)
        d.rectangle([26, 14, 35, 17], fill=hexc("#7fd4ff"))  # cabina
        d.point((28, 15), fill=(255, 255, 255, 255))
        # brazos y rotores
        d.line([(10, 12), (4, 8)], fill=navy, width=2)
        d.line([(38, 12), (44, 8)], fill=navy, width=2)
        blade = hexc("#c8d0dc", 200)
        if f % 2 == 0:
            d.line([(0, 7), (9, 7)], fill=blade)
            d.line([(39, 7), (47, 7)], fill=blade)
        else:
            d.line([(2, 6), (7, 8)], fill=blade)
            d.line([(41, 8), (46, 6)], fill=blade)
        # barra de luces
        red_on = f < 2
        d.rectangle([16, 9, 21, 11], fill=hexc("#ff2a3d") if red_on else hexc("#5a1018"))
        d.rectangle([22, 9, 27, 11], fill=hexc("#3d7bff") if not red_on else hexc("#101a5a"))
        # foco inferior
        d.rectangle([22, 24, 27, 26], fill=hexc("#fff4b0"))
        d.rectangle([10, 25, 12, 28], fill=navy)
        d.rectangle([36, 25, 38, 28], fill=navy)
        img = add_outline(img)
        sheet.paste(img, (f * w, 0))
    sheet.save(path("sprites", "patrol_drone.png"))


def make_small_drone():
    w = 16
    sheet = Image.new("RGBA", (w * 2, w), (0, 0, 0, 0))
    for f in range(2):
        img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([3, 5, 12, 11], fill=hexc("#3a3f55"))
        d.rectangle([6, 7, 9, 8], fill=hexc("#ff3b30") if f == 0 else hexc("#ffb0a8"))
        blade = hexc("#b9c2d0", 220)
        if f == 0:
            d.line([(0, 3), (6, 3)], fill=blade)
            d.line([(9, 3), (15, 3)], fill=blade)
        else:
            d.line([(1, 2), (5, 4)], fill=blade)
            d.line([(10, 4), (14, 2)], fill=blade)
        d.line([(4, 4), (4, 6)], fill=hexc("#3a3f55"))
        d.line([(11, 4), (11, 6)], fill=hexc("#3a3f55"))
        sheet.paste(add_outline(img), (f * w, 0))
    sheet.save(path("sprites", "drone.png"))


def make_dog():
    w, h = 24, 16
    sheet = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
    fur = hexc("#9c6b3c")
    dark = hexc("#6e4524")
    for f in range(4):
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        bob = 1 if f % 2 else 0
        d.rectangle([5, 6 + bob, 17, 10 + bob], fill=fur)  # cuerpo
        d.rectangle([16, 3 + bob, 21, 8 + bob], fill=fur)  # cabeza
        d.rectangle([21, 6 + bob, 22, 7 + bob], fill=dark)  # hocico
        d.point((19, 5 + bob), fill=(20, 15, 15, 255))
        d.rectangle([16, 2 + bob, 17, 3 + bob], fill=dark)  # oreja
        d.line([(5, 6 + bob), (2, 3 + bob + (f % 2))], fill=fur, width=1)  # cola
        offs = [(-2, 2), (0, 0), (2, -2), (0, 0)][f]
        for lx, o in ((7, offs[0]), (9, offs[1]), (14, offs[1] * -1), (16, offs[0] * -1)):
            d.line([(lx, 10 + bob), (lx + o, 14)], fill=dark if lx in (9, 14) else fur)
        d.rectangle([10, 6 + bob, 13, 7 + bob], fill=hexc("#c79a63"))
        d.point((18, 8 + bob), fill=hexc("#d7263d"))  # collar
        sheet.paste(add_outline(img), (f * w, 0))
    sheet.save(path("sprites", "dog.png"))


# ---------------------------------------------------------------------------
# Objetos y obstÃ¡culos
# ---------------------------------------------------------------------------

def make_items():
    # Bocadillo veleÃ±o envuelto en hoja de bijao (coleccionable)
    sheet = Image.new("RGBA", (16 * 4, 16), (0, 0, 0, 0))
    for f in range(4):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        bob = [0, -1, -1, 0][f]
        d.rectangle([3, 5 + bob, 12, 11 + bob], fill=hexc("#5f8f2f"))
        d.rectangle([4, 6 + bob, 11, 10 + bob], fill=hexc("#a3162d"))
        d.rectangle([4, 6 + bob, 6, 10 + bob], fill=hexc("#f0e2c8"))  # capa de leche
        d.line([(3, 8 + bob), (12, 8 + bob)], fill=hexc("#3f6b1f"))
        if f in (1, 2):
            d.point((10, 6 + bob), fill=(255, 255, 255, 255))
        sheet.paste(add_outline(img), (f * 16, 0))
    sheet.save(path("sprites", "bocadillo.png"))

    # Pista (volante con informaciÃ³n)
    sheet = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    for f in range(2):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        bob = -f
        d.polygon([(3, 3 + bob), (12, 2 + bob), (13, 13 + bob), (4, 14 + bob)], fill=hexc("#fff6d5"))
        d.line([(6, 6 + bob), (10, 6 + bob)], fill=hexc("#7a7a7a"))
        d.line([(6, 8 + bob), (11, 8 + bob)], fill=hexc("#7a7a7a"))
        d.rectangle([7, 10 + bob, 9, 12 + bob], fill=hexc("#d7263d"))
        sheet.paste(add_outline(img, hexc("#f2c14e") if f else OUTLINE), (f * 16, 0))
    sheet.save(path("sprites", "pista.png"))

    # CorazÃ³n de vida extra
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    heart(ImageDraw.Draw(img), 2, 3, hexc("#ff3d5a"))
    add_outline(img).save(path("sprites", "heart_pickup.png"))


def heart(d, x, y, color):
    pts = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    for j, row in enumerate(pts):
        for i, b in enumerate(row):
            if b == "1":
                d.rectangle([x + i * 2 - 1, y + j * 2 - 1, x + i * 2, y + j * 2], fill=color)


def make_obstacles():
    # Vidrios rotos (peligro)
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    glass = hexc("#9fe7ff", 230)
    for x0, hgt in ((0, 6), (4, 9), (8, 5), (11, 8)):
        d.polygon([(x0, 15), (x0 + 2, 15 - hgt), (x0 + 4, 15)], fill=glass)
        d.point((x0 + 2, 16 - hgt), fill=(255, 255, 255, 255))
    d.line([(0, 15), (15, 15)], fill=hexc("#5d7d8c"))
    add_outline(img).save(path("sprites", "hazard_glass.png"))

    # Cono de trÃ¡nsito (peligro alternativo)
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(4, 14), (8, 2), (11, 14)], fill=hexc("#ff7a1a"))
    d.line([(6, 9), (10, 9)], fill=(255, 255, 255, 255))
    d.rectangle([2, 14, 13, 15], fill=hexc("#ff7a1a"))
    add_outline(img).save(path("sprites", "hazard_cone.png"))

    # Plataforma mÃ³vil 48x8
    img = Image.new("RGBA", (48, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 47, 7], fill=hexc("#5b6478"))
    d.rectangle([0, 0, 47, 1], fill=hexc("#9aa5bd"))
    for x in range(4, 48, 10):
        d.rectangle([x, 3, x + 1, 4], fill=hexc("#f2c14e"))
    d.rectangle([2, 8, 45, 9], fill=hexc("#ff3b8d", 160))
    add_outline(img).save(path("sprites", "moving_platform.png"))

    # Barrera del CAI 10x48 (2 cuadros: cerrada con luz roja / luz apagada)
    sheet = Image.new("RGBA", (24, 48), (0, 0, 0, 0))
    for f in range(2):
        img = Image.new("RGBA", (12, 48), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for y in range(4, 48, 8):
            d.rectangle([2, y, 9, y + 3], fill=hexc("#f4f4f4"))
            d.rectangle([2, y + 4, 9, y + 7], fill=hexc("#d7263d"))
        d.rectangle([3, 0, 8, 3], fill=hexc("#ff2a3d") if f == 0 else hexc("#4a1018"))
        sheet.paste(add_outline(img), (f * 12, 0))
    sheet.save(path("sprites", "barrier.png"))

    # Punto de control: poste de parada con luz neÃ³n (apagado/encendido)
    sheet = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    for f in range(2):
        img = Image.new("RGBA", (16, 40), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([7, 10, 8, 39], fill=hexc("#6b7287"))
        col = hexc("#3dffa0") if f else hexc("#3b4152")
        d.rounded_rectangle([1, 0, 14, 11], radius=2, fill=col)
        d.rectangle([4, 3, 11, 8], fill=hexc("#0d2b1f") if f else hexc("#262a36"))
        d.polygon([(6, 4), (10, 6), (6, 8)], fill=col)
        d.rectangle([4, 37, 11, 39], fill=hexc("#4a5064"))
        sheet.paste(add_outline(img), (f * 16, 0))
    sheet.save(path("sprites", "checkpoint.png"))

    # Meta / salida: arco con letrero (bloqueada roja / abierta verde)
    sheet = Image.new("RGBA", (96, 56), (0, 0, 0, 0))
    for f in range(2):
        img = Image.new("RGBA", (48, 56), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        frame_col = hexc("#2c3044")
        d.rectangle([2, 10, 5, 55], fill=frame_col)
        d.rectangle([42, 10, 45, 55], fill=frame_col)
        neon = hexc("#3dffa0") if f else hexc("#ff3b5c")
        d.rounded_rectangle([0, 0, 47, 12], radius=2, fill=hexc("#11131c"))
        d.rounded_rectangle([0, 0, 47, 12], radius=2, outline=neon)
        draw_text(img, 10, 3, "META", neon)
        d.polygon([(20, 30), (28, 36), (20, 42)], fill=neon)
        sheet.paste(add_outline(img), (f * 48, 0))
    sheet.save(path("sprites", "exit.png"))

    # PartÃ­culas
    img = Image.new("RGBA", (4, 4), (255, 255, 255, 255))
    img.save(path("sprites", "particle.png"))
    img = Image.new("RGBA", (1, 6), (0, 0, 0, 0))
    for y in range(6):
        img.putpixel((0, y), (170, 200, 255, 60 + y * 30))
    img.save(path("sprites", "raindrop.png"))


def radial_light(size, power=1.6):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            r = math.hypot(x - c, y - c) / c
            a = max(0.0, 1.0 - r) ** power
            px[x, y] = (255, 255, 255, int(255 * a))
    return img


def make_lights():
    radial_light(128).save(path("sprites", "light.png"))
    # Cono de linterna hacia abajo
    w, h = 96, 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        half = 4 + (w / 2 - 4) * (y / h)
        for x in range(w):
            dx = abs(x - w / 2)
            if dx <= half:
                a = (1 - y / h) ** 0.8 * (1 - dx / half) ** 0.6
                px[x, y] = (255, 255, 255, int(200 * a))
    img.save(path("sprites", "light_cone.png"))


# ---------------------------------------------------------------------------
# Accesorios urbanos
# ---------------------------------------------------------------------------

def make_props():
    # Farola
    img = Image.new("RGBA", (24, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pole = hexc("#3a3f55")
    d.rectangle([11, 8, 12, 71], fill=pole)
    d.rectangle([9, 66, 14, 71], fill=pole)
    d.line([(12, 8), (18, 4)], fill=pole, width=2)
    d.rectangle([15, 4, 22, 7], fill=pole)
    d.rectangle([16, 7, 21, 8], fill=hexc("#ffe9a8"))
    add_outline(img).save(path("sprites", "lamp.png"))

    # SeÃ±ales de trÃ¡nsito
    img = Image.new("RGBA", (16, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([7, 12, 8, 35], fill=hexc("#8a90a2"))
    d.rounded_rectangle([1, 0, 14, 13], radius=2, fill=hexc("#1f5fbf"))
    d.rectangle([3, 2, 12, 11], outline=(255, 255, 255, 255))
    d.polygon([(5, 9), (8, 3), (11, 9)], fill=(255, 255, 255, 255))
    add_outline(img).save(path("sprites", "sign.png"))

    img = Image.new("RGBA", (16, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([7, 12, 8, 35], fill=hexc("#8a90a2"))
    d.regular_polygon((8, 7, 7), 8, fill=hexc("#d7263d"))
    d.rectangle([4, 6, 11, 7], fill=(255, 255, 255, 255))
    add_outline(img).save(path("sprites", "sign_stop.png"))

    # Carros estacionados (taxi amarillo, rojo, gris, azul)
    for name, body in (("car_taxi", "#f2c14e"), ("car_red", "#b8323f"),
                       ("car_gray", "#8a90a2"), ("car_blue", "#2e5fa8")):
        img = Image.new("RGBA", (56, 28), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        b = hexc(body)
        d.rounded_rectangle([1, 12, 54, 22], radius=3, fill=b)
        d.polygon([(12, 12), (17, 4), (38, 4), (45, 12)], fill=b)
        d.polygon([(15, 12), (19, 6), (27, 6), (27, 12)], fill=hexc("#9fd6ff"))
        d.polygon([(29, 12), (29, 6), (37, 6), (42, 12)], fill=hexc("#9fd6ff"))
        d.line([(1, 16), (54, 16)], fill=shade(b, 0.75))
        d.rectangle([52, 14, 54, 15], fill=hexc("#fff4b0"))
        d.rectangle([1, 14, 2, 15], fill=hexc("#ff3b30"))
        for wx in (12, 43):
            d.ellipse([wx - 5, 17, wx + 5, 27], fill=hexc("#1a1a1f"))
            d.ellipse([wx - 2, 20, wx + 2, 24], fill=hexc("#9aa0ad"))
        if name == "car_taxi":
            d.rectangle([24, 1, 31, 3], fill=hexc("#fff4b0"))
            for x in range(4, 52, 4):
                d.point((x, 19), fill=(20, 20, 20, 255))
        add_outline(img).save(path("sprites", name + ".png"))

    # Patrulla estacionada (decoraciÃ³n, con luces)
    img = Image.new("RGBA", (64, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1, 14, 62, 24], radius=3, fill=hexc("#e8ecf2"))
    d.polygon([(14, 14), (20, 6), (44, 6), (52, 14)], fill=hexc("#e8ecf2"))
    d.rectangle([1, 18, 62, 20], fill=hexc("#1d2b53"))
    d.polygon([(17, 14), (22, 8), (31, 8), (31, 14)], fill=hexc("#9fd6ff"))
    d.polygon([(33, 14), (33, 8), (43, 8), (48, 14)], fill=hexc("#9fd6ff"))
    d.rectangle([24, 3, 31, 5], fill=hexc("#ff2a3d"))
    d.rectangle([32, 3, 39, 5], fill=hexc("#3d7bff"))
    for wx in (14, 50):
        d.ellipse([wx - 5, 19, wx + 5, 29], fill=hexc("#1a1a1f"))
        d.ellipse([wx - 2, 22, wx + 2, 26], fill=hexc("#9aa0ad"))
    add_outline(img).save(path("sprites", "patrol_car.png"))

    # Palmera
    img = Image.new("RGBA", (48, 88), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    trunk = hexc("#6b4a2e")
    for y in range(20, 88, 1):
        x = 24 + int(3 * math.sin(y / 18.0))
        d.rectangle([x - 2, y, x + 1, y], fill=trunk if (y // 3) % 2 else shade(trunk, 0.8))
    leaf = hexc("#2f7d4a")
    for ang in (-160, -120, -60, -20, -95):
        a = math.radians(ang)
        for t in range(22):
            x = 24 + math.cos(a) * t
            y = 20 + math.sin(a) * t * 0.6 + (t * t) / 40.0
            d.rectangle([round(x) - 1, round(y), round(x) + 1, round(y) + 1], fill=leaf if t % 3 else shade(leaf, 1.3))
    add_outline(img).save(path("sprites", "palm.png"))

    # Ãrbol frondoso (parques)
    img = Image.new("RGBA", (56, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([25, 36, 30, 71], fill=hexc("#5a3d27"))
    random.seed(7)
    for _ in range(60):
        cx = random.randint(8, 47)
        cy = random.randint(6, 40)
        r = random.randint(4, 8)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=random.choice([hexc("#2b6b3f"), hexc("#357f4a"), hexc("#23573a")]))
    for _ in range(15):
        d.point((random.randint(10, 46), random.randint(8, 38)), fill=hexc("#f28fb1"))  # flores de guayacÃ¡n
    add_outline(img).save(path("sprites", "tree.png"))

    # Banca
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 29, 4], fill=hexc("#8a5a33"))
    d.rectangle([2, 8, 29, 10], fill=hexc("#8a5a33"))
    d.rectangle([4, 4, 5, 15], fill=hexc("#3a3f55"))
    d.rectangle([26, 4, 27, 15], fill=hexc("#3a3f55"))
    add_outline(img).save(path("sprites", "bench.png"))

    # Caneca de basura
    img = Image.new("RGBA", (12, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 3, 10, 15], fill=hexc("#2f8f5b"))
    d.rectangle([0, 1, 11, 3], fill=hexc("#236b44"))
    add_outline(img).save(path("sprites", "trash.png"))

    # CAI (edificio ficticio de referencia narrativa)
    img = Image.new("RGBA", (128, 88), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wall = hexc("#e8ecf2")
    d.rectangle([4, 24, 123, 87], fill=wall)
    d.rectangle([0, 18, 127, 25], fill=hexc("#2a7a4a"))
    d.rectangle([4, 70, 123, 73], fill=hexc("#2a7a4a"))
    for wx in (14, 44, 92):
        d.rectangle([wx, 36, wx + 20, 58], fill=hexc("#ffe9a8"))
        d.rectangle([wx, 46, wx + 20, 47], fill=hexc("#8a90a2"))
        d.rectangle([wx + 10, 36, wx + 10, 58], fill=hexc("#8a90a2"))
    d.rectangle([70, 40, 86, 87], fill=hexc("#3a3f55"))
    d.rectangle([72, 42, 84, 85], fill=hexc("#7fd4ff"))
    d.rounded_rectangle([40, 2, 88, 16], radius=2, fill=hexc("#11131c"))
    draw_text(img, 55, 6, "CAI", hexc("#3dffa0"))
    d.rectangle([60, 0, 63, 2], fill=hexc("#ff2a3d"))
    d.rectangle([64, 0, 67, 2], fill=hexc("#3d7bff"))
    add_outline(img).save(path("sprites", "cai.png"))

    # Vitrinas de tiendas con neÃ³n
    for name, word, neon, glow in (("shop_1", "TIENDA", "#ff3b8d", "#ffd6ea"),
                                   ("shop_2", "CAFE", "#3dffa0", "#d6ffe9"),
                                   ("shop_3", "MODA", "#3dc6ff", "#d6f3ff"),
                                   ("shop_4", "PAN", "#f2c14e", "#fff1c8")):
        img = Image.new("RGBA", (64, 56), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([0, 8, 63, 55], fill=hexc("#2a2d3e"))
        d.rectangle([4, 24, 59, 51], fill=hexc(glow, 255))
        d.rectangle([4, 24, 59, 26], fill=hexc("#ffffff"))
        for x in range(10, 60, 14):
            d.rectangle([x, 36, x + 6, 51], fill=shade(hexc(neon), 0.7))
        d.rectangle([0, 0, 63, 12], fill=hexc("#11131c"))
        tw = text_width(word)
        draw_text(img, (64 - tw) // 2, 3, word, hexc(neon))
        add_outline(img).save(path("sprites", name + ".png"))

    # Escalera de casa / muro del barrio: matera con flores
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 9, 12, 15], fill=hexc("#b5532f"))
    for x, c in ((4, "#ff3b5c"), (7, "#f2c14e"), (10, "#ff7ab8")):
        d.rectangle([x, 4, x + 2, 7], fill=hexc(c))
        d.line([(x + 1, 7), (x + 1, 9)], fill=hexc("#2f7d4a"))
    add_outline(img).save(path("sprites", "flowerpot.png"))


# ---------------------------------------------------------------------------
# Tileset (16x16), una fila por temÃ¡tica
# ---------------------------------------------------------------------------
THEMES = ["calles", "comercial", "cai", "parque", "barrio", "viaducto", "final"]


def noise_fill(d, x0, y0, base, rng, amount=10, n=10):
    d.rectangle([x0, y0, x0 + 15, y0 + 15], fill=base)
    for _ in range(n):
        x = x0 + rng.randint(0, 15)
        y = y0 + rng.randint(0, 15)
        f = 1 + rng.choice([-1, 1]) * amount / 100.0
        d.point((x, y), fill=shade(base, f))


def make_tileset():
    T = 16
    cols = 4  # 0 superficie, 1 relleno, 2 plataforma de un sentido, 3 caja
    img = Image.new("RGBA", (T * cols, T * len(THEMES)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(42)
    for row, theme in enumerate(THEMES):
        y = row * T
        if theme == "calles":
            fill, top, edge = hexc("#3a3346"), hexc("#7b7f8e"), hexc("#f2c14e")
        elif theme == "comercial":
            fill, top, edge = hexc("#4a3f52"), hexc("#c9b79c"), hexc("#ff3b8d")
        elif theme == "cai":
            fill, top, edge = hexc("#454a5c"), hexc("#9aa0ad"), hexc("#2a7a4a")
        elif theme == "parque":
            fill, top, edge = hexc("#4a3423"), hexc("#3f9b4f"), hexc("#7bd36a")
        elif theme == "barrio":
            fill, top, edge = hexc("#7a3b2a"), hexc("#b5532f"), hexc("#e0a070")
        elif theme == "viaducto":
            fill, top, edge = hexc("#56596a"), hexc("#8a8fa0"), hexc("#ff3b30")
        else:
            fill, top, edge = hexc("#3b3550"), hexc("#a58fb8"), hexc("#3dffa0")
        # Relleno
        noise_fill(d, T, y, fill, rng, 12, 14)
        if theme == "barrio":
            for by in range(0, 16, 4):
                d.line([(T, y + by), (T + 15, y + by)], fill=shade(fill, 0.7))
                off = 0 if (by // 4) % 2 == 0 else 4
                for bx in range(off, 16, 8):
                    d.line([(T + bx, y + by), (T + bx, y + by + 3)], fill=shade(fill, 0.7))
        elif theme == "viaducto":
            d.line([(T, y + 7), (T + 15, y + 7)], fill=shade(fill, 0.8))
            d.point((T + 4, y + 11), fill=hexc("#8a5a33"))
        # Superficie
        noise_fill(d, 0, y, fill, rng, 12, 10)
        d.rectangle([0, y, 15, y + 5], fill=top)
        d.line([(0, y), (15, y)], fill=shade(top, 1.25))
        d.line([(0, y + 5), (15, y + 5)], fill=edge)
        if theme == "parque":
            for x in range(0, 16, 3):
                d.point((x, y + 6), fill=top)
                d.point((x + 1, y + 7), fill=top)
            d.point((5, y + 1), fill=hexc("#ff7ab8"))
            d.point((12, y + 2), fill=hexc("#f2c14e"))
        elif theme == "comercial":
            d.line([(7, y + 1), (7, y + 4)], fill=shade(top, 0.85))
            d.line([(15, y + 1), (15, y + 4)], fill=shade(top, 0.85))
        elif theme == "calles":
            d.line([(4, y + 3), (9, y + 3)], fill=shade(top, 0.85))
        elif theme == "viaducto":
            d.rectangle([0, y + 1, 15, y + 2], fill=shade(top, 0.9))
        # Plataforma de un sentido (toldo / andamio / tablÃ³n)
        px = 2 * T
        if theme in ("comercial", "final"):
            for x in range(0, 16, 4):
                d.rectangle([px + x, y, px + x + 1, y + 5], fill=edge)
                d.rectangle([px + x + 2, y, px + x + 3, y + 5], fill=hexc("#f4f4f4"))
            d.line([(px, y + 5), (px + 15, y + 5)], fill=shade(edge, 0.6))
        elif theme in ("parque", "barrio"):
            d.rectangle([px, y, px + 15, y + 4], fill=hexc("#8a5a33"))
            d.line([(px, y), (px + 15, y)], fill=hexc("#b07a4a"))
            d.point((px + 4, y + 2), fill=hexc("#5a3a20"))
            d.point((px + 11, y + 2), fill=hexc("#5a3a20"))
        else:
            d.rectangle([px, y, px + 15, y + 3], fill=hexc("#6b7287"))
            d.line([(px, y), (px + 15, y)], fill=hexc("#aab2c8"))
            for x in range(1, 16, 5):
                d.line([(px + x, y + 3), (px + x + 3, y + 8)], fill=hexc("#4a5064"))
        # Caja / bloque
        bx = 3 * T
        crate = hexc("#9a6a3a") if theme not in ("viaducto", "cai") else hexc("#5b6478")
        d.rectangle([bx, y, bx + 15, y + 15], fill=crate)
        d.rectangle([bx, y, bx + 15, y + 15], outline=shade(crate, 0.6))
        d.line([(bx + 1, y + 1), (bx + 14, y + 14)], fill=shade(crate, 0.75))
        d.line([(bx + 14, y + 1), (bx + 1, y + 14)], fill=shade(crate, 0.75))
        d.line([(bx + 1, y + 1), (bx + 14, y + 1)], fill=shade(crate, 1.3))
    img.save(path("tilesets", "tiles.png"))


# ---------------------------------------------------------------------------
# Fondos parallax
# ---------------------------------------------------------------------------
BW, BH = 480, 360


def make_sky():
    img = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    px = img.load()
    top = (10, 8, 30)
    mid = (36, 22, 70)
    bot = (110, 40, 90)
    for y in range(BH):
        t = y / (BH - 1)
        if t < 0.6:
            k = t / 0.6
            c = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.6) / 0.4
            c = tuple(int(mid[i] + (bot[i] - mid[i]) * k) for i in range(3))
        for x in range(BW):
            px[x, y] = c + (255,)
    rng = random.Random(3)
    for _ in range(160):
        x, y = rng.randint(0, BW - 1), rng.randint(0, int(BH * 0.6))
        b = rng.randint(120, 255)
        px[x, y] = (b, b, min(255, b + 20), 255)
    d = ImageDraw.Draw(img)
    d.ellipse([360, 40, 392, 72], fill=(245, 236, 210, 255))
    d.ellipse([368, 46, 376, 54], fill=(222, 210, 185, 255))
    d.ellipse([378, 58, 384, 64], fill=(222, 210, 185, 255))
    img.save(path("backgrounds", "sky.png"))


def ridge(rng, base, amp, freq_list, width=BW):
    phases = [rng.random() * math.tau for _ in freq_list]
    ys = []
    for x in range(width):
        y = base
        for (f, a), ph in zip(freq_list, phases):
            # frecuencias enteras => repeticiÃ³n horizontal perfecta
            y += a * amp * math.sin(math.tau * f * x / width + ph)
        ys.append(int(y))
    return ys


def make_mountains():
    img = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    px = img.load()
    rng = random.Random(11)
    far = ridge(rng, 170, 30, [(1, 1.0), (3, 0.5), (7, 0.2)])
    near = ridge(rng, 215, 25, [(2, 1.0), (5, 0.4), (11, 0.15)])
    for x in range(BW):
        for y in range(far[x], BH):
            px[x, y] = (46, 32, 84, 255)
        for y in range(near[x], BH):
            px[x, y] = (30, 22, 58, 255)
    # luces de casas sobre la ladera (meseta y escarpe)
    for _ in range(260):
        x = rng.randint(0, BW - 1)
        y = rng.randint(near[x] + 4, BH - 1)
        if y < BH - 30:
            c = rng.choice([(255, 214, 120), (255, 180, 90), (210, 230, 255)])
            px[x, y] = c + (255,)
    img.save(path("backgrounds", "mountains.png"))


def building_row(img, rng, base_y, min_h, max_h, colors, window_chance, win_colors, seed_step=0,
                 neon=False, antenna=True):
    d = ImageDraw.Draw(img)
    x = 0
    while x < BW:
        w = rng.randint(24, 56)
        if x + w > BW:
            w = BW - x
        h = rng.randint(min_h, max_h)
        top = base_y - h
        col = rng.choice(colors)
        d.rectangle([x, top, x + w - 1, BH], fill=col)
        d.line([(x, top), (x + w - 1, top)], fill=shade(col, 1.25))
        for wy in range(top + 4, BH - 4, 6):
            for wx in range(x + 3, x + w - 3, 5):
                if rng.random() < window_chance:
                    d.rectangle([wx, wy, wx + 2, wy + 2], fill=rng.choice(win_colors))
        if antenna and rng.random() < 0.3 and w > 20:
            ax = x + w // 2
            d.line([(ax, top - 10), (ax, top)], fill=shade(col, 1.2))
            d.point((ax, top - 11), fill=(255, 50, 60, 255))
        if neon and rng.random() < 0.5 and w > 30:
            nc = rng.choice([hexc("#ff3b8d"), hexc("#3dffa0"), hexc("#3dc6ff"), hexc("#f2c14e")])
            ny = top + rng.randint(8, max(9, min(40, h - 10)))
            d.rectangle([x + 4, ny, x + w - 5, ny + 4], fill=nc)
            d.rectangle([x + 5, ny + 1, x + w - 6, ny + 3], fill=shade(nc, 1.4))
        x += w


def make_city_far():
    img = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    rng = random.Random(21)
    building_row(img, rng, 300, 40, 115,
                 [hexc("#241b45"), hexc("#2a2050"), hexc("#1f1840")], 0.22,
                 [hexc("#ffd27a"), hexc("#ffb35c"), hexc("#a8d8ff"), hexc("#3a2f60")])
    img.save(path("backgrounds", "city_far.png"))


def make_near_layers():
    configs = {
        "calles": dict(colors=["#2d2440", "#33284a", "#2a2238"], neon=False, minh=40, maxh=100, chance=0.3),
        "comercial": dict(colors=["#30264a", "#3a2c55", "#281f3c"], neon=True, minh=50, maxh=120, chance=0.45),
        "cai": dict(colors=["#2a2a40", "#30304a"], neon=False, minh=50, maxh=110, chance=0.25),
        "parque": None,
        "barrio": dict(colors=["#6b3b4a", "#3f5a6b", "#7a6a3a", "#4a3b6b", "#3b6b55"], neon=False, minh=40,
                       maxh=80, chance=0.35),
        "viaducto": None,
        "final": dict(colors=["#2d2440", "#3a2c55"], neon=True, minh=40, maxh=100, chance=0.4),
    }
    for theme in THEMES:
        img = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
        rng = random.Random(THEMES.index(theme) * 97 + 5)
        cfg = configs[theme]
        d = ImageDraw.Draw(img)
        if theme == "parque":
            # copas de Ã¡rboles y faroles del parque
            for x in range(-10, BW + 10, 18):
                r = rng.randint(16, 26)
                cy = 270 - rng.randint(0, 20)
                d.ellipse([x - r, cy - r, x + r, cy + r], fill=rng.choice([hexc("#1d3b2c"), hexc("#20452f"), hexc("#183324")]))
            d.rectangle([0, 270, BW, BH], fill=hexc("#16291f"))
            for x in range(20, BW, 80):
                d.rectangle([x, 230, x + 1, 300], fill=hexc("#1a1a24"))
                d.ellipse([x - 3, 226, x + 4, 233], fill=hexc("#ffe9a8"))
        elif theme == "viaducto":
            # puente atirantado y ciudad iluminada debajo
            building_row(img, rng, 330, 20, 60, [hexc("#241b45"), hexc("#2a2050")], 0.5,
                         [hexc("#ffd27a"), hexc("#ffb35c"), hexc("#a8d8ff")], antenna=False)
            deck = 250
            d.rectangle([0, deck, BW, deck + 8], fill=hexc("#4a4d5e"))
            d.line([(0, deck), (BW, deck)], fill=hexc("#8a8fa0"))
            for x in range(0, BW, 240):
                px0 = x + 120
                d.rectangle([px0 - 3, 120, px0 + 3, deck + 90], fill=hexc("#5b5f73"))
                for k in range(1, 9):
                    d.line([(px0, 130 + k * 4), (px0 - k * 14, deck)], fill=hexc("#8a8fa0"))
                    d.line([(px0, 130 + k * 4), (px0 + k * 14, deck)], fill=hexc("#8a8fa0"))
                d.point((px0, 118), fill=(255, 50, 60, 255))
            for x in range(4, BW, 12):
                d.point((x, deck + 3), fill=hexc("#ffe9a8"))
        else:
            building_row(img, rng, 320, cfg["minh"], cfg["maxh"], [hexc(c) for c in cfg["colors"]],
                         cfg["chance"], [hexc("#ffd27a"), hexc("#ffe9b0"), hexc("#a8d8ff"), hexc("#2a2238")],
                         neon=cfg["neon"])
            if theme == "barrio":
                # tejados de barro
                x = 0
                while x < BW:
                    w = rng.randint(30, 50)
                    y = 300 - rng.randint(40, 80)
                    d.polygon([(x - 2, y), (x + w // 2, y - 10), (x + w + 2, y)], fill=hexc("#8a3b25"))
                    x += w
            if theme == "cai":
                for x in range(30, BW, 120):
                    d.rectangle([x, 240, x + 30, 300], fill=hexc("#1f2f2a"))
        img.save(path("backgrounds", "near_" + theme + ".png"))


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

def make_ui():
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    heart(d, 2, 3, hexc("#ff3d5a"))
    heart(d, 18, 3, hexc("#3a2f45"))
    add_outline(img).save(path("ui", "hearts.png"))

    # Icono de vida (cara del protagonista)
    face = draw_character(CHARACTERS["protagonist"], pose_for("idle", 0)).crop((9, 1, 25, 17))
    face.save(path("ui", "life_icon.png"))

    # Botones tÃ¡ctiles
    def button(name, symbol):
        size = 64
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([2, 2, size - 3, size - 3], fill=(20, 16, 40, 140), outline=(255, 255, 255, 180), width=2)
        w = (255, 255, 255, 220)
        if symbol == "left":
            d.polygon([(40, 18), (20, 32), (40, 46)], fill=w)
        elif symbol == "right":
            d.polygon([(24, 18), (44, 32), (24, 46)], fill=w)
        elif symbol == "jump":
            d.polygon([(18, 40), (32, 20), (46, 40)], fill=w)
        elif symbol == "run":
            d.polygon([(16, 20), (30, 32), (16, 44)], fill=w)
            d.polygon([(32, 20), (46, 32), (32, 44)], fill=w)
        elif symbol == "action":
            draw_text(img, 26, 25, "E", w, scale=2)
        elif symbol == "pause":
            d.rectangle([22, 20, 28, 44], fill=w)
            d.rectangle([36, 20, 42, 44], fill=w)
        img.save(path("ui", "touch_" + name + ".png"))

    for n in ("left", "right", "jump", "run", "action", "pause"):
        button(n, n)

    # Logotipo del tÃ­tulo
    line1, line2 = "ESCAPE DE", "BUCARAMANGA"
    scale2 = 6
    w = text_width(line2) * scale2 + 40
    h = 7 * 4 + 7 * scale2 + 50
    logo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for (dx, dy, c) in ((3, 3, hexc("#3d7bff")), (-3, 3, hexc("#ff2a3d"))):
        draw_text(logo, (w - text_width(line1) * 4) // 2 + dx, 10 + dy, line1, c, scale=4)
        draw_text(logo, 20 + dx, 52 + dy, line2, c, scale=scale2)
    draw_text(logo, (w - text_width(line1) * 4) // 2, 10, line1, hexc("#fff4e0"), scale=4)
    draw_text(logo, 20, 52, line2, hexc("#fff4e0"), scale=scale2)
    add_outline(logo).save(path("ui", "logo.png"))

    # Icono de la aplicaciÃ³n
    icon = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    d.rounded_rectangle([0, 0, 127, 127], radius=20, fill=hexc("#1d1638"))
    d.pieslice([-40, -40, 80, 80], 0, 90, fill=hexc("#ff2a3d", 110))
    d.pieslice([48, -40, 168, 80], 90, 180, fill=hexc("#3d7bff", 110))
    face = draw_character(CHARACTERS["protagonist"], pose_for("run", 1)).resize((128, 128), Image.NEAREST)
    icon.alpha_composite(face, (0, 0))
    icon.save(os.path.join(ROOT, "icon.png"))


def main():
    make_character_sheets()
    make_patrol_drone()
    make_small_drone()
    make_dog()
    make_items()
    make_obstacles()
    make_lights()
    make_props()
    make_tileset()
    make_sky()
    make_mountains()
    make_city_far()
    make_near_layers()
    make_ui()
    print("Arte generado en", OUT)


if __name__ == "__main__":
    main()
