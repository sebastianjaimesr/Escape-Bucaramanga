class_name Effects
extends RefCounted
## Efectos visuales reutilizables (partículas de un solo disparo, textos flotantes).

const PARTICLE_TEX := "res://assets/sprites/particle.png"


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 90.0,
		lifetime: float = 0.5, gravity: float = 200.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.texture = load(PARTICLE_TEX)
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 20
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func dust(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, Color(0.8, 0.78, 0.85, 0.8), 6, 40.0, 0.35, 60.0)


static func floating_text(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.position = pos - Vector2(12, 12)
	l.z_index = 30
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 16.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)
