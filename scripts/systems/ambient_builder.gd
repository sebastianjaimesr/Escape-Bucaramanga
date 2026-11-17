class_name AmbientBuilder
extends RefCounted
## Vida ambiental por tema: luciérnagas, flores de guayacán que caen, cabinas del
## teleférico, luces de carros sobre el Viaducto y una viñeta suave de cámara.
## Todo usa partículas de CPU o tweens: barato y compatible con WebGL 2.

## Cable del teleférico dentro de landmark_final.png (ver tools/generate_landmarks.py).
const CABLE_START := Vector2(60, 330)
const CABLE_END := Vector2(560, 148)
const CABLE_TRIP := 26.0  # segundos de punta a punta

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.55;
uniform vec4 tint : source_color = vec4(0.03, 0.01, 0.08, 1.0);
void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= 1.25;
	float v = smoothstep(0.38, 0.92, length(uv));
	COLOR = vec4(tint.rgb, v * strength);
}
"""


static func build(level: Node2D, theme: String, camera: Camera2D, background: Node2D,
		with_vignette: bool = true) -> void:
	match theme:
		"parque":
			camera.add_child(_fireflies(28, Color(0.75, 1.0, 0.45)))
			camera.add_child(_petals())
		"final":
			camera.add_child(_fireflies(18, Color(1.0, 0.9, 0.55)))
			_cable_cars(background)
		"viaducto":
			_bridge_traffic(background)
		"barrio", "calles":
			camera.add_child(_fireflies(10, Color(1.0, 0.8, 0.5)))
	if with_vignette:
		level.add_child(_vignette())


static func _particle_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.25, Color(1, 1, 1, 1))
	ramp.add_point(0.75, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	return ramp


## Puntos de luz que flotan despacio alrededor de la cámara (en coordenadas del mundo).
static func _fireflies(amount: int, color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Fireflies"
	p.texture = load("res://assets/sprites/firefly.png")
	p.amount = amount
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(300, 120)
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, -3)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.color = color
	p.color_ramp = _particle_ramp()
	p.z_index = 4
	return p


## Flores de guayacán (amarillas) que caen en el Parque San Pío.
static func _petals() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Petals"
	p.texture = load(Effects.PARTICLE_TEX)
	p.amount = 18
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(320, 4)
	p.position = Vector2(0, -150)
	p.direction = Vector2(-0.3, 1.0)
	p.spread = 25.0
	p.gravity = Vector2(-4, 10)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 22.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.4
	p.color = Color(0.98, 0.8, 0.3)
	p.color_ramp = _particle_ramp()
	p.z_index = 14
	return p


static func _find_layer(background: Node2D, prefix: String) -> Parallax2D:
	if background == null:
		return null
	for child in background.get_children():
		if child is Parallax2D and String(child.name).to_lower().begins_with(prefix):
			return child
	return null


## Cabinas rojas que suben y bajan por el cable del Cerro del Santísimo.
static func _cable_cars(background: Node2D) -> void:
	var layer := _find_layer(background, "landmark")
	if layer == null:
		return
	var img := layer.get_node_or_null("Image") as Sprite2D
	if img == null:
		return
	var tex: Texture2D = load("res://assets/sprites/cable_car.png")
	for i in 4:
		var cabin := Sprite2D.new()
		cabin.texture = tex
		cabin.offset = Vector2(0, 6)
		img.add_child(cabin)
		var going_up := i % 2 == 0
		var a := CABLE_START if going_up else CABLE_END
		var b := CABLE_END if going_up else CABLE_START
		var line_offset := Vector2(0, 0 if going_up else 3)
		var t0 := float(i) / 4.0
		cabin.position = a.lerp(b, t0) + line_offset
		var tw := cabin.create_tween().set_loops()
		tw.tween_property(cabin, "position", b + line_offset, CABLE_TRIP * (1.0 - t0))
		tw.tween_property(cabin, "position", a + line_offset, 0.0)
		if t0 > 0.0:
			tw.tween_property(cabin, "position", a.lerp(b, t0) + line_offset, CABLE_TRIP * t0)


## Luces de carros que cruzan el tablero del puente dibujado en near_viaducto.png.
static func _bridge_traffic(background: Node2D) -> void:
	var layer := _find_layer(background, "near")
	if layer == null:
		return
	var img := layer.get_node_or_null("Image") as Sprite2D
	if img == null:
		return
	var tex: Texture2D = load("res://assets/sprites/car_lights.png")
	for i in 5:
		var car := Sprite2D.new()
		car.texture = tex
		var to_right := i % 2 == 0
		car.flip_h = not to_right
		car.modulate = Color(1, 1, 1) if to_right else Color(1.0, 0.35, 0.3)
		var y := 247.0 if to_right else 252.0
		var start_x := -30.0 if to_right else 510.0
		var end_x := 510.0 if to_right else -30.0
		car.position = Vector2(lerpf(start_x, end_x, float(i) / 5.0), y)
		img.add_child(car)
		var dur := 7.0 + i * 0.9
		var remaining := dur * (1.0 - float(i) / 5.0)
		var tw := car.create_tween().set_loops()
		tw.tween_property(car, "position:x", end_x, remaining)
		tw.tween_property(car, "position:x", start_x, 0.0)
		tw.tween_property(car, "position:x", car.position.x, dur - remaining)


## Viñeta oscura en los bordes: centra la mirada en el personaje.
static func _vignette() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 8
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	mat.shader = shader
	rect.material = mat
	layer.add_child(rect)
	return layer
