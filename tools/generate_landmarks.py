"""Genera el arte de identidad de Bucaramanga (versión 1.1).

Uso:  py tools/generate_landmarks.py

Es un generador aditivo: no toca los recursos que crea generate_art.py.
Produce:
  backgrounds/landmark_<tema>.png  capa de lugar reconocible por nivel (960x360)
  backgrounds/clouds.png           nubes nocturnas que se desplazan solas
  backgrounds/haze.png             bruma baja que separa fondo y juego
  sprites/santisimo_far.png        silueta lejana del Santísimo (meta de la historia)
  sprites/hormiga.png              hormiga culona (coleccionable secundario, 4 cuadros)
  sprites/cable_car.png            cabina del teleférico del Cerro del Santísimo
  sprites/firefly.png              luciérnaga / chispa de ambiente
  sprites/car_lights.png           estela de luces de carro (Viaducto)
  ui/star.png                      estrella llena y vacía (32x32 cada una)
  ui/hormiga_icon.png              icono del HUD

Los lugares están inspirados en referencias públicas (Capilla de los Dolores e
Iglesia de San Laureano en el Parque García Rovira, guayacanes del Parque San Pío,
torres de Cabecera, Viaducto de la Novena, Cerro del Santísimo con su teleférico).
Son interpretaciones en pixel art, no reproducciones exactas.
"""
import math
import random

from PIL import Image, ImageDraw

from generate_art import add_outline, hexc, path, shade, radial_light

LW, BH = 960, 360  # capas de lugar: el doble de ancho que las demás para no repetirse seguido
GROUND = 322       # base de las construcciones (queda oculta tras el suelo del nivel)

# Datos que también usa scripts/systems/ambient_builder.gd (mantener sincronizados)
CABLE_START = (60, 330)
CABLE_END = (560, 148)


def windows(d, rng, x0, y0, x1, y1, step_x=5, step_y=7, chance=0.35, size=(2, 3),
            lit=("#ffd27a", "#ffe9b0", "#ffb35c"), dark="#1c1630"):
    for wy in range(y0, y1 - size[1], step_y):
        for wx in range(x0, x1 - size[0], step_x):
            col = hexc(rng.choice(lit)) if rng.random() < chance else hexc(dark)
            d.rectangle([wx, wy, wx + size[0] - 1, wy + size[1] - 1], fill=col)


def palm(d, x, base, h, trunk="#3a2a2a", leaf="#1f4a36", rng=None):
    rng = rng or random.Random(x)
    sway = rng.choice([-1, 1])
    for i in range(h):
        xx = x + int(sway * 3 * (i / h) ** 2)
        d.rectangle([xx - 1, base - i, xx + 1, base - i], fill=hexc(trunk) if i % 4 else shade(hexc(trunk), 1.4))
    top = (x + sway * 3, base - h)
    for ang in (-170, -140, -110, -80, -50, -20, 10):
        a = math.radians(ang)
        for k in range(1, 20):
            px = top[0] + math.cos(a) * k
            py = top[1] + math.sin(a) * k * 0.6 + (k * k) * 0.04
            w = 2 if k < 14 else 1
            d.rectangle([round(px), round(py), round(px) + w - 1, round(py) + w], fill=hexc(leaf))
            d.point((round(px), round(py) + w + 1), fill=shade(hexc(leaf), 0.65))
    d.ellipse([top[0] - 3, top[1] - 2, top[0] + 3, top[1] + 3], fill=shade(hexc(leaf), 0.8))


# ---------------------------------------------------------------------------
# Capas de lugar
# ---------------------------------------------------------------------------
def landmark_centro():
    """Centro (Calle 35): casas republicanas de dos pisos con balcones de madera."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(1622)  # año de fundación de Bucaramanga
    walls = ["#5d4f63", "#6b5a52", "#53506b", "#6a4d58", "#5a5a52"]
    x = 0
    while x < LW:
        w = rng.randint(64, 104)
        h = rng.randint(78, 96)
        top = GROUND - h
        wall = hexc(rng.choice(walls))
        d.rectangle([x, top, x + w - 1, BH], fill=wall)
        d.rectangle([x, top, x + w - 1, top + 3], fill=shade(wall, 1.25))  # cornisa
        d.rectangle([x - 1, top - 2, x + w, top], fill=hexc("#6e3428"))   # alero de teja
        # segundo piso: ventanas altas con balcón corrido de madera
        n = max(2, w // 26)
        gap = w / n
        for i in range(n):
            wx = int(x + gap * i + gap / 2 - 5)
            lit = rng.random() < 0.55
            col = hexc("#ffcf7a") if lit else hexc("#231a30")
            d.rectangle([wx, top + 12, wx + 9, top + 30], fill=col)
            d.rectangle([wx + 4, top + 12, wx + 5, top + 30], fill=shade(col, 0.7))
            # postigos
            d.rectangle([wx - 3, top + 12, wx - 1, top + 30], fill=hexc("#2f4a3c"))
            d.rectangle([wx + 10, top + 12, wx + 12, top + 30], fill=hexc("#2f4a3c"))
        by = top + 31
        d.rectangle([x + 3, by, x + w - 4, by + 2], fill=hexc("#4a2c22"))
        for bx in range(x + 4, x + w - 4, 3):
            d.line([(bx, by - 7), (bx, by)], fill=hexc("#4a2c22"))
        d.line([(x + 3, by - 8), (x + w - 4, by - 8)], fill=hexc("#5c3a2c"))
        # primer piso: puertas y vitrinas
        for i in range(n):
            dx = int(x + gap * i + gap / 2 - 6)
            if rng.random() < 0.4:
                d.rectangle([dx, top + 46, dx + 12, GROUND], fill=hexc("#ffd88a"))
                d.rectangle([dx + 1, top + 47, dx + 11, top + 50], fill=hexc("#fff2c8"))
            else:
                d.rectangle([dx, top + 46, dx + 12, GROUND], fill=hexc("#2a2232"))
                for k in range(top + 48, GROUND, 3):
                    d.line([(dx, k), (dx + 12, k)], fill=hexc("#3a3242"))
        x += w + rng.randint(0, 3)
    return img


def tower(d, rng, x, w, h, base, color, lit_chance=0.4, beacon=True):
    top = base - h
    col = hexc(color)
    d.rectangle([x, top, x + w - 1, BH], fill=col)
    d.rectangle([x + w - 3, top, x + w - 1, BH], fill=shade(col, 0.8))  # cara en sombra
    d.rectangle([x, top, x + w - 1, top + 2], fill=shade(col, 1.3))
    windows(d, rng, x + 3, top + 6, x + w - 4, base, step_x=4, step_y=6, chance=lit_chance,
            size=(2, 3), lit=("#ffe0a0", "#bfe4ff", "#ffd27a"), dark="#211a38")
    # balcones horizontales típicos de los edificios de apartamentos
    for by in range(top + 10, base - 4, 12):
        d.line([(x, by), (x + w - 1, by)], fill=shade(col, 1.18))
    if beacon:
        d.rectangle([x + w // 2, top - 6, x + w // 2, top], fill=shade(col, 1.3))
        d.point((x + w // 2, top - 7), fill=(255, 60, 70, 255))
    return top


def landmark_cabecera(seed=7, count_scale=1.0):
    """Cabecera: torres residenciales altas con balcones y luces de aviación."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(seed)
    x = rng.randint(0, 30)
    colors = ["#3a3060", "#433868", "#372f58", "#4a3d70"]
    while x < LW - 40:
        w = rng.randint(28, 46)
        h = rng.randint(120, 210)
        if rng.random() < 0.35 * count_scale:
            tower(d, rng, x, w, h, GROUND, rng.choice(colors))
            x += w + rng.randint(6, 30)
        else:
            x += rng.randint(30, 70)
    return img


def landmark_cai():
    """Alrededores del CAI de San Pío: torres de Cabecera y una cancha iluminada."""
    img = landmark_cabecera(seed=33, count_scale=0.8)
    d = ImageDraw.Draw(img)
    # cancha de baloncesto con reflectores, a la izquierda de la capa
    cx = 600
    d.rectangle([cx, 262, cx + 150, GROUND], fill=hexc("#2a3b4a"))
    for fx in range(cx, cx + 151, 6):
        d.line([(fx, 262), (fx, 300)], fill=hexc("#4a5d6e"))
    d.line([(cx, 262), (cx + 150, 262)], fill=hexc("#6c8094"))
    for lx in (cx + 4, cx + 146):
        d.rectangle([lx, 220, lx + 1, 300], fill=hexc("#5a5f70"))
        d.rectangle([lx - 4, 216, lx + 5, 220], fill=hexc("#fff6d0"))
    return img


def guayacan(d, rng, x, base, r, bloom):
    trunk = hexc("#2c1f22")
    d.rectangle([x - 2, base - r - 18, x + 1, base], fill=trunk)
    d.line([(x, base - r - 6), (x - r // 2, base - r - 16)], fill=trunk, width=2)
    d.line([(x, base - r - 8), (x + r // 2, base - r - 18)], fill=trunk, width=2)
    cy = base - r - 26
    for _ in range(9):
        ox = rng.randint(-r, r)
        oy = rng.randint(-r // 2, r // 3)
        rr = rng.randint(r // 2, int(r * 0.8))
        d.ellipse([x + ox - rr, cy + oy - rr * 0.7, x + ox + rr, cy + oy + rr * 0.7],
                  fill=rng.choice([hexc("#1f3f30"), hexc("#234a36"), hexc("#1a3528")]))
    # flores de guayacán (amarillo o rosado) salpicadas en la copa
    for _ in range(r * 5):
        ang = rng.random() * math.tau
        rad = rng.random() * r
        fx = x + math.cos(ang) * rad
        fy = cy + math.sin(ang) * rad * 0.6
        d.point((round(fx), round(fy)), fill=hexc(bloom))


def landmark_san_pio():
    """Parque San Pío: guayacanes florecidos, palmas y la biblioteca del parque."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(1964)  # año de fundación del parque
    for x in range(30, LW, rng.randint(70, 90)):
        bloom = rng.choice(["#f2c14e", "#f2c14e", "#e88bb5"])
        guayacan(d, rng, x + rng.randint(-10, 10), GROUND, rng.randint(26, 36), bloom)
    for x in (140, 420, 700, 880):
        palm(d, x, GROUND, rng.randint(80, 100), rng=rng)
    # biblioteca: pabellón bajo con ventanales iluminados
    bx = 480
    d.rectangle([bx, 270, bx + 110, GROUND], fill=hexc("#4a4060"))
    d.rectangle([bx - 6, 264, bx + 116, 270], fill=hexc("#5e5478"))
    for wx in range(bx + 6, bx + 104, 14):
        d.rectangle([wx, 278, wx + 9, 300], fill=hexc("#ffe0a0"))
    return img


def landmark_garcia_rovira():
    """Parque García Rovira: Iglesia de San Laureano (dos torres), Capilla de los
    Dolores (blanca, techo de teja a dos aguas), palmas y la estatua del prócer."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(1748)
    # --- Iglesia de San Laureano: fachada amarillo pálido con dos torres
    ox = 520
    yellow = hexc("#d8c27a")
    yshadow = hexc("#a8935a")
    d.rectangle([ox, 220, ox + 120, GROUND], fill=yellow)                  # nave
    d.polygon([(ox, 220), (ox + 60, 196), (ox + 120, 220)], fill=yellow)  # frontón
    d.line([(ox, 220), (ox + 60, 196), (ox + 120, 220)], fill=hexc("#f0e2a8"))
    for tx in (ox - 22, ox + 120):
        d.rectangle([tx, 160, tx + 22, GROUND], fill=yellow)
        d.rectangle([tx + 18, 160, tx + 22, GROUND], fill=yshadow)
        d.rectangle([tx - 2, 158, tx + 24, 162], fill=hexc("#f0e2a8"))
        d.rectangle([tx + 4, 140, tx + 18, 158], fill=yellow)            # campanario
        d.rectangle([tx + 8, 144, tx + 14, 154], fill=hexc("#2a2232"))   # vano de campana
        d.polygon([(tx + 3, 140), (tx + 11, 124), (tx + 19, 140)], fill=hexc("#8a5a3a"))
        d.rectangle([tx + 10, 116, tx + 11, 124], fill=hexc("#e8d8a0"))  # cruz
        d.rectangle([tx + 8, 119, tx + 13, 120], fill=hexc("#e8d8a0"))
        for wy in (176, 206, 240):
            d.rectangle([tx + 8, wy, tx + 13, wy + 10], fill=hexc("#ffd88a"))
    d.rectangle([ox + 48, 262, ox + 72, GROUND], fill=hexc("#3a2418"))   # portón
    d.pieslice([ox + 48, 252, ox + 72, 272], 180, 360, fill=hexc("#3a2418"))
    d.ellipse([ox + 54, 226, ox + 66, 238], fill=hexc("#ffcf7a"))         # rosetón
    for wx in (ox + 16, ox + 92):
        d.rectangle([wx, 236, wx + 10, 256], fill=hexc("#ffcf7a"))
    # --- Capilla de los Dolores: pequeña, encalada, techo de teja a dos aguas
    cx = 250
    white = hexc("#e6e0d4")
    d.rectangle([cx, 262, cx + 70, GROUND], fill=white)
    d.polygon([(cx - 6, 264), (cx + 35, 238), (cx + 76, 264)], fill=hexc("#9a4630"))
    d.line([(cx - 6, 264), (cx + 35, 238), (cx + 76, 264)], fill=hexc("#c0603e"))
    d.polygon([(cx + 22, 262), (cx + 35, 246), (cx + 48, 262)], fill=white)  # espadaña
    d.rectangle([cx + 33, 250, cx + 37, 256], fill=hexc("#2a2232"))
    d.rectangle([cx + 28, 288, cx + 42, GROUND], fill=hexc("#4a2c1c"))
    d.pieslice([cx + 28, 282, cx + 42, 294], 180, 360, fill=hexc("#4a2c1c"))
    d.rectangle([cx + 70, 262, cx + 72, GROUND], fill=shade(white, 0.8))
    # --- Estatua de Custodio García Rovira sobre su pedestal
    sx = 420
    d.rectangle([sx - 9, 284, sx + 9, GROUND], fill=hexc("#8a8494"))
    d.rectangle([sx - 12, 280, sx + 12, 284], fill=hexc("#a29cae"))
    bronze = hexc("#5a4a3a")
    d.rectangle([sx - 3, 262, sx + 3, 280], fill=bronze)
    d.ellipse([sx - 3, 255, sx + 3, 262], fill=bronze)
    d.line([(sx + 3, 266), (sx + 9, 260)], fill=bronze, width=2)
    # --- palmas altas del parque
    for x in (360, 460, 700, 780, 60, 160):
        palm(d, x, GROUND, rng.randint(95, 130), rng=rng)
    return img


def landmark_escarpe():
    """La meseta de Bucaramanga vista desde el Viaducto: ladera con luces."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    px = img.load()
    rng = random.Random(9)
    phase = [rng.random() * math.tau for _ in range(3)]
    for x in range(LW):
        t = x / LW * math.tau
        top = 205 + 18 * math.sin(t + phase[0]) + 8 * math.sin(3 * t + phase[1]) + 4 * math.sin(9 * t + phase[2])
        for y in range(int(top), BH):
            k = (y - top) / (BH - top)
            px[x, y] = (int(40 + 10 * k), int(30 + 6 * k), int(70 + 10 * k), 255)
        # borde de la meseta con edificios bajos
        if rng.random() < 0.35:
            h = rng.randint(4, 14)
            for y in range(int(top) - h, int(top)):
                px[x, y] = (46, 36, 80, 255)
    # barrios de la ladera: grupos de luces, no ruido uniforme
    for _ in range(70):
        cx = rng.randrange(LW)
        cy = rng.randint(215, BH - 30)
        for _ in range(rng.randint(6, 22)):
            x = (cx + rng.randint(-14, 14)) % LW
            y = cy + rng.randint(-5, 5)
            if px[x, y][3]:
                px[x, y] = hexc(rng.choice(["#ffd27a", "#ffb35c", "#ffe9b0", "#a8d8ff"]))
    return img


def santisimo_figure(d, cx, base, s, robe="#d4cedc", shade_col="#a39cb0"):
    """Silueta respetuosa del monumento del Santísimo (figura con túnica y brazos abiertos)."""
    robe_c = hexc(robe)
    sh = hexc(shade_col)
    # pedestal
    d.rectangle([cx - 7 * s, base - 8 * s, cx + 7 * s, base], fill=hexc("#7a7488"))
    d.rectangle([cx - 9 * s, base - 9 * s, cx + 9 * s, base - 8 * s], fill=hexc("#9a94a8"))
    # túnica (trapecio)
    top = base - 40 * s
    d.polygon([(cx - 3 * s, top + 8 * s), (cx + 3 * s, top + 8 * s), (cx + 7 * s, base - 9 * s),
               (cx - 7 * s, base - 9 * s)], fill=robe_c)
    d.polygon([(cx + 1 * s, top + 8 * s), (cx + 3 * s, top + 8 * s), (cx + 7 * s, base - 9 * s),
               (cx + 2 * s, base - 9 * s)], fill=sh)
    # brazos abiertos hacia arriba
    d.polygon([(cx - 3 * s, top + 9 * s), (cx - 12 * s, top + 2 * s), (cx - 13 * s, top + 4 * s),
               (cx - 3 * s, top + 13 * s)], fill=robe_c)
    d.polygon([(cx + 3 * s, top + 9 * s), (cx + 12 * s, top + 2 * s), (cx + 13 * s, top + 4 * s),
               (cx + 3 * s, top + 13 * s)], fill=sh)
    # cabeza
    d.ellipse([cx - 2 * s, top + 2 * s, cx + 2 * s, top + 7 * s], fill=robe_c)


def landmark_santisimo():
    """Cerro del Santísimo: el monumento en la cima, teleférico y luces del mirador."""
    img = Image.new("RGBA", (LW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    px = img.load()
    # el cerro
    peak_x = 600
    for x in range(LW):
        dx = (x - peak_x) / 260.0
        top = 170 + 150 * (1 - math.exp(-dx * dx * 1.6)) + 6 * math.sin(x * 0.05)
        for y in range(int(top), BH):
            k = (y - top) / max(1.0, BH - top)
            px[x, y] = (int(34 + 8 * k), int(40 + 10 * k), int(58 + 8 * k), 255)
    rng = random.Random(2015)  # año de apertura del ecoparque
    # bosque en la ladera
    for _ in range(500):
        x = rng.randrange(LW)
        dx = (x - peak_x) / 260.0
        top = 170 + 150 * (1 - math.exp(-dx * dx * 1.6))
        y = int(top + rng.randint(2, 40))
        if y < BH:
            r = rng.randint(2, 4)
            d.ellipse([x - r, y - r, x + r, y + r], fill=rng.choice([hexc("#1f3a30"), hexc("#24443a")]))
    # mirador iluminado y el monumento
    d.rectangle([peak_x - 40, 166, peak_x + 40, 172], fill=hexc("#9a94a8"))
    for lx in range(peak_x - 38, peak_x + 40, 6):
        d.point((lx, 165), fill=hexc("#ffe9b0"))
    santisimo_figure(d, peak_x, 166, 2)
    # torres y cable del teleférico (las cabinas se animan en el juego)
    x0, y0 = CABLE_START
    x1, y1 = CABLE_END
    d.line([(x0, y0), (x1, y1)], fill=hexc("#8a8fa0"))
    d.line([(x0, y0 + 3), (x1, y1 + 3)], fill=hexc("#5f6474"))
    for t in (0.25, 0.55, 0.82):
        tx = int(x0 + (x1 - x0) * t)
        ty = int(y0 + (y1 - y0) * t)
        d.rectangle([tx - 1, ty, tx + 1, ty + 46], fill=hexc("#6a6f80"))
        d.rectangle([tx - 4, ty - 1, tx + 4, ty + 1], fill=hexc("#8a8fa0"))
        d.point((tx, ty - 2), fill=(255, 60, 70, 255))
    d.rectangle([x1 - 10, y1 - 4, x1 + 14, y1 + 10], fill=hexc("#6a6480"))  # estación superior
    d.rectangle([x1 - 8, y1 - 2, x1 + 12, y1 + 2], fill=hexc("#ffe0a0"))
    return img


# ---------------------------------------------------------------------------
# Ambiente
# ---------------------------------------------------------------------------
def make_clouds():
    img = Image.new("RGBA", (480, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(77)
    for _ in range(9):
        cx = rng.randint(0, 480)
        cy = rng.randint(30, 150)
        w = rng.randint(50, 110)
        for k in range(7):
            ox = rng.randint(-w // 2, w // 2)
            oy = rng.randint(-5, 5)
            r = rng.randint(8, 18)
            for wrap in (-480, 0, 480):  # repetición perfecta
                d.ellipse([cx + ox - r * 1.6 + wrap, cy + oy - r * 0.6, cx + ox + r * 1.6 + wrap, cy + oy + r * 0.6],
                          fill=(120, 100, 160, 38))
    img.save(path("backgrounds", "clouds.png"))


def make_haze():
    img = Image.new("RGBA", (480, BH), (0, 0, 0, 0))
    px = img.load()
    for y in range(BH):
        t = max(0.0, (y - 220) / 100.0)
        a = int(min(1.0, t) * 70)
        for x in range(480):
            px[x, y] = (90, 50, 120, a)
    img.save(path("backgrounds", "haze.png"))


def make_santisimo_far():
    img = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    santisimo_figure(d, 20, 47, 1)
    img.save(path("sprites", "santisimo_far.png"))


def make_hormiga():
    """Hormiga culona: abdomen grande y brillante, 4 cuadros de patas."""
    sheet = Image.new("RGBA", (16 * 4, 16), (0, 0, 0, 0))
    for f in range(4):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        body = hexc("#7a2a1a")
        light = hexc("#c8553a")
        d.ellipse([7, 6, 14, 13], fill=body)          # abdomen (culo)
        d.ellipse([8, 7, 11, 9], fill=light)          # brillo
        d.ellipse([4, 8, 7, 11], fill=body)           # tórax
        d.ellipse([1, 7, 4, 10], fill=body)           # cabeza
        d.line([(1, 7), (0, 4)], fill=body)           # antenas
        d.line([(3, 7), (3, 4)], fill=body)
        off = (0, 1, 0, -1)[f]
        for lx in (4, 6, 8):
            d.line([(lx, 11), (lx - 1 + off, 14)], fill=hexc("#3a1410"))
        sheet.paste(add_outline(img), (16 * f, 0))
    sheet.save(path("sprites", "hormiga.png"))
    icon = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    icon.paste(sheet.crop((0, 0, 16, 16)), (0, 0))
    icon.save(path("ui", "hormiga_icon.png"))


def make_cable_car():
    img = Image.new("RGBA", (12, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(6, 0), (6, 4)], fill=hexc("#8a8fa0"))
    d.rectangle([1, 4, 10, 12], fill=hexc("#d84a4a"))
    d.rectangle([2, 6, 9, 8], fill=hexc("#ffe9b0"))
    d.rectangle([1, 12, 10, 13], fill=hexc("#8a2a2a"))
    img.save(path("sprites", "cable_car.png"))


def make_firefly():
    img = radial_light(8, power=1.2)
    img.save(path("sprites", "firefly.png"))


def make_car_lights():
    img = Image.new("RGBA", (24, 3), (0, 0, 0, 0))
    px = img.load()
    for x in range(24):
        a = int(255 * (x / 23) ** 1.5)
        for y in range(3):
            px[x, y] = (255, 230, 170, a if y == 1 else a // 3)
    img.save(path("sprites", "car_lights.png"))


def make_stars():
    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (fill, edge) in enumerate(((hexc("#ffd44a"), hexc("#fff4b0")), (hexc("#3a3458"), hexc("#5a5480")))):
        cx, cy = 16 + i * 32, 17
        pts = []
        for k in range(10):
            r = 14 if k % 2 == 0 else 6
            a = -math.pi / 2 + k * math.pi / 5
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        d.polygon(pts, fill=fill)
        d.line(pts[:3], fill=edge)
    add_outline(img).save(path("ui", "star.png"))


def main():
    for name, fn in (("calles", landmark_centro), ("comercial", landmark_cabecera), ("cai", landmark_cai),
                     ("parque", landmark_san_pio), ("barrio", landmark_garcia_rovira),
                     ("viaducto", landmark_escarpe), ("final", landmark_santisimo)):
        fn().save(path("backgrounds", "landmark_%s.png" % name))
    make_clouds()
    make_haze()
    make_santisimo_far()
    make_hormiga()
    make_cable_car()
    make_firefly()
    make_car_lights()
    make_stars()
    print("Arte de Bucaramanga generado.")


if __name__ == "__main__":
    main()
