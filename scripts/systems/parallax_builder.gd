class_name ParallaxBuilder
extends RefCounted
## Crea las capas de fondo con Parallax2D, de lejos a cerca:
##   cielo → nubes (se mueven solas) → Santísimo lejano → montañas → [lugar] →
##   ciudad lejana → [lugar] → bruma → fachadas cercanas → [lugar]
## La capa de lugar (landmark_<tema>.png) da identidad a cada nivel: el Centro,
## Cabecera, San Pío, García Rovira, el Viaducto o el Cerro del Santísimo.

const BG_DIR := "res://assets/backgrounds/"
const LAYER_WIDTH := 480.0
const LANDMARK_WIDTH := 960.0
const TOP := -40.0

## Desplazamiento y profundidad de la capa de lugar por tema.
## depth: "back" (detrás de la ciudad lejana), "mid" (antes de las fachadas cercanas)
## o "front" (delante de las fachadas cercanas).
## feature: columna de la imagen con el elemento principal; start_x: dónde debe verse
## en pantalla (0-480) al comenzar el nivel; y: ajuste vertical.
const LANDMARKS := {
	"calles": {"scroll": 0.62, "depth": "front", "feature": 0.0, "start_x": 0.0, "y": 0.0},
	"comercial": {"scroll": 0.22, "depth": "back", "feature": 0.0, "start_x": 0.0, "y": 0.0},
	"cai": {"scroll": 0.22, "depth": "back", "feature": 675.0, "start_x": 330.0, "y": 0.0},
	"parque": {"scroll": 0.38, "depth": "mid", "feature": 535.0, "start_x": 380.0, "y": -46.0},
	"barrio": {"scroll": 0.3, "depth": "mid", "feature": 580.0, "start_x": 400.0, "y": -14.0},
	"viaducto": {"scroll": 0.18, "depth": "back", "feature": 0.0, "start_x": 0.0, "y": 0.0},
	"final": {"scroll": 0.16, "depth": "back", "feature": 600.0, "start_x": 420.0, "y": 62.0},
}
## Media pantalla en unidades del mundo (960 px de ventana con zoom 2).
const HALF_VIEW := 240.0

## Escala de la silueta lejana del Santísimo según el nivel (se acerca con la historia).
const SANTISIMO_SCALE := [0.5, 0.56, 0.62, 0.7, 0.78, 0.86]


## Desplazamiento horizontal para que la columna `feature` de una capa con
## scroll_scale `s` aparezca en `start_x` de la pantalla cuando la cámara está al
## inicio del nivel (centro en HALF_VIEW). Fórmula medida con Parallax2D y zoom 2:
## x_pantalla = offset + feature - s * centro_cámara - (1 - 2s) * HALF_VIEW.
static func offset_for(feature: float, start_x: float, s: float) -> float:
	return start_x - feature + (1.0 - s) * HALF_VIEW


static func build(parent: Node, theme: String, autoscroll_speed: float = 0.0, level_index: int = -1) -> Node2D:
	var root := Node2D.new()
	root.name = "Background"
	root.z_index = -100
	parent.add_child(root)
	var lm: Dictionary = LANDMARKS.get(theme, {})
	var layers: Array = [["sky", 0.02], ["clouds", 0.04], ["mountains", 0.12]]
	if lm.get("depth") == "back":
		layers.append(["landmark_" + theme, lm["scroll"]])
	layers.append(["city_far", 0.28])
	if lm.get("depth") == "mid":
		layers.append(["landmark_" + theme, lm["scroll"]])
	layers.append(["haze", 0.4])
	layers.append(["near_" + theme, 0.5])
	if lm.get("depth") == "front":
		layers.append(["landmark_" + theme, lm["scroll"]])
	var z := 0
	for def: Array in layers:
		var tex_name := String(def[0])
		var path := BG_DIR + tex_name + ".png"
		if not ResourceLoader.exists(path):
			continue
		var is_landmark := tex_name.begins_with("landmark_")
		var p := Parallax2D.new()
		p.name = tex_name.capitalize().replace(" ", "")
		p.scroll_scale = Vector2(float(def[1]), 1.0)
		p.repeat_size = Vector2(LANDMARK_WIDTH if is_landmark else LAYER_WIDTH, 0)
		p.repeat_times = 3 if is_landmark else 4
		var drift := 0.0
		if tex_name == "clouds":
			drift = -6.0  # las nubes avanzan aunque la cámara esté quieta
		if autoscroll_speed != 0.0:
			drift -= autoscroll_speed * float(def[1])
		if drift != 0.0:
			p.autoscroll = Vector2(drift, 0)
		var spr := Sprite2D.new()
		spr.name = "Image"
		spr.texture = load(path)
		spr.centered = false
		if is_landmark:
			var off := offset_for(float(lm["feature"]), float(lm["start_x"]), float(def[1]))
			spr.position = Vector2(off, TOP + float(lm.get("y", 0.0)))
		else:
			spr.position = Vector2(0, TOP)
		p.add_child(spr)
		p.z_index = z
		z += 1
		root.add_child(p)
		if tex_name == "mountains" and theme != "final":
			_add_far_santisimo(root, level_index, z)
			z += 1
	return root


## Silueta lejana del monumento sobre los cerros orientales: es la meta de la
## historia, siempre visible a la derecha y más grande en cada nivel.
static func _add_far_santisimo(root: Node2D, level_index: int, z: int) -> void:
	var p := Parallax2D.new()
	p.name = "SantisimoFar"
	p.scroll_scale = Vector2(0.12, 1.0)
	p.z_index = z
	root.add_child(p)
	var s: float = SANTISIMO_SCALE[clampi(level_index, 0, SANTISIMO_SCALE.size() - 1)]
	# El monumento aparece a la derecha (hacia donde avanza el jugador) y se desliza
	# despacio hacia la izquierda a lo largo del nivel.
	var cx := 420.0 + offset_for(0.0, 0.0, 0.12)
	var base_y := TOP + 200.0
	var hill := Polygon2D.new()
	hill.color = Color(30.0 / 255.0, 22.0 / 255.0, 58.0 / 255.0)
	hill.polygon = PackedVector2Array([Vector2(cx - 90, base_y + 60), Vector2(cx - 22, base_y + 2), Vector2(cx, base_y),
		Vector2(cx + 22, base_y + 2), Vector2(cx + 90, base_y + 60), Vector2(cx + 90, 400), Vector2(cx - 90, 400)])
	p.add_child(hill)
	var statue := Sprite2D.new()
	statue.texture = load("res://assets/sprites/santisimo_far.png")
	statue.centered = false
	statue.offset = Vector2(-20, -47)
	statue.position = Vector2(cx, base_y + 1)
	statue.scale = Vector2(s, s)
	statue.modulate = Color(0.78, 0.76, 0.85)
	p.add_child(statue)
	var glow := PointLight2D.new()
	glow.texture = load("res://assets/sprites/light.png")
	glow.color = Color(1.0, 0.92, 0.75)
	glow.energy = 0.35
	glow.texture_scale = 0.35
	glow.position = Vector2(cx, base_y - 22.0 * s)
	p.add_child(glow)
