"""Validación estática del proyecto (no necesita Godot).

Uso:  py tools/validate_project.py
Comprueba: rutas res:// existentes, JSON válidos, mapas de niveles coherentes,
diálogos y personajes referenciados, escenas con scripts válidos y que cada
nivel pueda completarse según un análisis de alcanzabilidad simplificado.
"""
import json
import os
import re
import sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = []
warnings = []


def res_to_path(res):
    return os.path.join(ROOT, res[len("res://"):].replace("/", os.sep))


def check_res_paths():
    pattern = re.compile(r'res://[A-Za-z0-9_./%-]+')
    for folder in ("scripts", "scenes", "data", "tests"):
        for dirpath, _, files in os.walk(os.path.join(ROOT, folder)):
            for name in files:
                if not name.endswith((".gd", ".tscn", ".json", ".tres")):
                    continue
                full = os.path.join(dirpath, name)
                with open(full, encoding="utf-8") as f:
                    text = f.read()
                for m in pattern.findall(text):
                    if "%" in m:
                        continue  # rutas formateadas, se validan aparte
                    if not os.path.exists(res_to_path(m.rstrip("."))):
                        errors.append("%s: ruta inexistente %s" % (os.path.relpath(full, ROOT), m))
    with open(os.path.join(ROOT, "project.godot"), encoding="utf-8") as f:
        for m in pattern.findall(f.read()):
            if not os.path.exists(res_to_path(m)):
                errors.append("project.godot: ruta inexistente %s" % m)


def load_json(rel):
    try:
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:  # noqa: BLE001
        errors.append("%s: JSON inválido (%s)" % (rel, e))
        return {}


SOLID = set("#B")
STAND = set("#B=")
JUMP_UP = 3      # celdas que se pueden subir con un salto
JUMP_ACROSS = 6  # celdas de hueco con carrera


def reachable(rows):
    """Búsqueda aproximada de alcanzabilidad desde P hasta X sobre superficies."""
    h, w = len(rows), len(rows[0])

    def standable(x, y):
        if not (0 <= x < w and 0 <= y < h - 1):
            return False
        here = rows[y][x]
        below = rows[y + 1][x]
        if here in SOLID:
            return False
        # Las plataformas móviles cuentan como suelo en un área cercana.
        return below in STAND or below in "MV" or here in "MV"

    def surface_y(x, y_from):
        for y in range(max(0, y_from), h - 1):
            if standable(x, y):
                return y
            if rows[y][x] in SOLID:
                return None
        return None

    start = goal = None
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "P":
                start = (x, y)
            elif ch == "X":
                goal = (x, y)
    if start is None or goal is None:
        return False, None
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        if abs(x - goal[0]) <= 1 and abs(y - goal[1]) <= 2:
            return True, None
        for dx in range(-JUMP_ACROSS - 1, JUMP_ACROSS + 2):
            nx = x + dx
            if not 0 <= nx < w:
                continue
            for top in range(y - JUMP_UP, y + 1):
                ny = surface_y(nx, top)
                if ny is None:
                    continue
                if ny < y - JUMP_UP:
                    continue
                up = max(0, y - ny)
                down = max(0, ny - y)
                if abs(dx) > JUMP_ACROSS + 1 - (up + 1) // 2 + down // 2:
                    continue
                if (nx, ny) not in seen:
                    seen.add((nx, ny))
                    q.append((nx, ny))
                break
    far = max(seen, key=lambda p: p[0])
    return False, far


def check_levels():
    index = load_json("data/levels/levels.json")
    dialogues = load_json("data/dialogue/dialogues.json")
    characters = load_json("data/dialogue/characters.json")
    for speaker_lines in dialogues.values():
        for line in speaker_lines:
            if line.get("speaker") not in characters:
                errors.append("Diálogo con personaje desconocido: %s" % line.get("speaker"))
    for c in characters.values():
        for key in ("sheet", "portrait"):
            if c.get(key) and not os.path.exists(res_to_path(c[key])):
                errors.append("Recurso de personaje inexistente: %s" % c[key])
    for info in index.get("levels", []):
        lid = info["id"]
        if not os.path.exists(res_to_path(info["scene"])):
            errors.append("%s: escena inexistente" % lid)
        d = load_json("data/levels/%s.json" % lid)
        rows = d.get("map", [])
        if not rows or len({len(r) for r in rows}) != 1:
            errors.append("%s: mapa vacío o irregular" % lid)
            continue
        flat = "".join(rows)
        for ch, n in (("P", 1), ("X", 1)):
            if flat.count(ch) != n:
                errors.append("%s: se esperaba %d '%s'" % (lid, n, ch))
        if flat.count("!") > len(d.get("hints", [])):
            errors.append("%s: faltan textos de ayuda" % lid)
        for key in ("intro", "outro"):
            if d.get(key) and d[key] not in dialogues:
                errors.append("%s: diálogo '%s' inexistente" % (lid, d[key]))
        if d.get("friend"):
            if flat.count("F") != 1:
                errors.append("%s: el nivel tiene amigo pero no un 'F' en el mapa" % lid)
            if d["friend"]["dialogue"] not in dialogues:
                errors.append("%s: diálogo del amigo inexistente" % lid)
            if d["friend"]["id"] not in characters:
                errors.append("%s: personaje del amigo inexistente" % lid)
        for m in d.get("mission", []):
            if m["type"] == "collect" and flat.count("o") < m["count"]:
                errors.append("%s: la misión pide %d granizados y hay %d" % (lid, m["count"], flat.count("o")))
            if m["type"] == "pistas" and flat.count("p") < m["count"]:
                errors.append("%s: la misión pide %d pistas y hay %d" % (lid, m["count"], flat.count("p")))
        ok, far = reachable(rows)
        if not ok:
            errors.append("%s: la meta parece inalcanzable (último punto: %s)" % (lid, far))
        if d.get("music") and not os.path.exists(os.path.join(ROOT, "assets", "audio", "music", d["music"] + ".wav")):
            errors.append("%s: música inexistente" % lid)
        if not os.path.exists(os.path.join(ROOT, "assets", "backgrounds", "near_%s.png" % d.get("theme"))):
            errors.append("%s: fondo de temática inexistente" % lid)


def check_scenes():
    for dirpath, _, files in os.walk(os.path.join(ROOT, "scenes")):
        for name in files:
            if name.endswith(".tscn"):
                with open(os.path.join(dirpath, name), encoding="utf-8") as f:
                    text = f.read()
                if not text.startswith("[gd_scene"):
                    errors.append("%s: cabecera de escena inválida" % name)


def check_gdscript_basics():
    """Detección sencilla de errores comunes de indentación mixta."""
    for dirpath, _, files in os.walk(os.path.join(ROOT, "scripts")):
        for name in files:
            if not name.endswith(".gd"):
                continue
            with open(os.path.join(dirpath, name), encoding="utf-8") as f:
                for i, line in enumerate(f, 1):
                    stripped = line.lstrip("\t")
                    if stripped.startswith(" ") and stripped.strip() and not stripped.lstrip().startswith(("#", "\"", "or ", "and ")):
                        warnings.append("%s:%d indentación con espacios" % (name, i))


def main():
    check_res_paths()
    check_levels()
    check_scenes()
    check_gdscript_basics()
    for w in warnings:
        print("AVISO:", w)
    for e in errors:
        print("ERROR:", e)
    print("Validación: %d errores, %d avisos" % (len(errors), len(warnings)))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
