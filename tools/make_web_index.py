"""Rellena web/shell.html y escribe index.html en una carpeta de exportación web.

Uso:  py tools/make_web_index.py build/web

Godot ya usa web/shell.html al exportar (export_presets.cfg → html/custom_html_shell),
así que este script solo hace falta cuando se actualiza únicamente index.pck
(por ejemplo con `godot --headless --export-pack "Web" build/web/index.pck`) y se
reutilizan index.js / index.wasm de una exportación anterior de la misma versión de Godot.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(out_dir):
    with open(os.path.join(ROOT, "web", "shell.html"), encoding="utf-8") as f:
        shell = f.read()
    sizes = {}
    for name in ("index.pck", "index.wasm"):
        p = os.path.join(out_dir, name)
        if not os.path.exists(p):
            sys.exit("Falta %s en %s" % (name, out_dir))
        sizes[name] = os.path.getsize(p)
    config = {"args": [], "canvasResizePolicy": 2, "emscriptenPoolSize": 8,
              "ensureCrossOriginIsolationHeaders": True, "executable": "index", "experimentalVK": False,
              "fileSizes": sizes, "focusCanvas": True, "gdextensionLibs": [], "godotPoolSize": 4}
    head = ('<link id="-gd-engine-icon" rel="icon" type="image/png" href="index.icon.png" />\n'
            '<link rel="apple-touch-icon" href="index.apple-touch-icon.png"/>')
    html = (shell.replace("$GODOT_PROJECT_NAME", "Escape de Bucaramanga")
            .replace("$GODOT_HEAD_INCLUDE", head)
            .replace("$GODOT_URL", "index.js")
            .replace("$GODOT_CONFIG", json.dumps(config, separators=(",", ":")))
            .replace("$GODOT_THREADS_ENABLED", "false"))
    assert "$GODOT" not in html, "Quedó un marcador sin reemplazar"
    with open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(html)
    print("index.html generado en", out_dir, sizes)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "web"))
