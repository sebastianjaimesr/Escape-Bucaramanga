class_name ParallaxBuilder
extends RefCounted
## Crea las capas de fondo con Parallax2D (cielo, montañas, ciudad lejana y cercana).

const BG_DIR := "res://assets/backgrounds/"
const LAYER_WIDTH := 480.0
const TOP := -40.0


## Crea cuatro capas de fondo; las lejanas se mueven más despacio que las cercanas
## (scroll_scale), lo que da sensación de profundidad.
static func build(parent: Node, theme: String, autoscroll_speed: float = 0.0) -> Node2D:
	var root := Node2D.new()
	root.name = "Background"
	root.z_index = -100
	parent.add_child(root)
	var layers := [
		["sky", 0.02],
		["mountains", 0.12],
		["city_far", 0.28],
		["near_" + theme, 0.5],
	]
	for i in layers.size():
		var def: Array = layers[i]
		var p := Parallax2D.new()
		p.name = String(def[0]).capitalize()
		p.scroll_scale = Vector2(float(def[1]), 1.0)
		p.repeat_size = Vector2(LAYER_WIDTH, 0)
		p.repeat_times = 4
		if autoscroll_speed != 0.0:
			p.autoscroll = Vector2(-autoscroll_speed * float(def[1]), 0)
		var spr := Sprite2D.new()
		spr.texture = load(BG_DIR + String(def[0]) + ".png")
		spr.centered = false
		spr.position = Vector2(0, TOP)
		p.add_child(spr)
		p.z_index = i
		root.add_child(p)
	return root
