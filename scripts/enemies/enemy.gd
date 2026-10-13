class_name Enemy
extends Area2D
## Base de enemigos de contacto. Si can_be_stomped, saltar encima lo desactiva.

@export var can_be_stomped := true
@export var damage := 1

var defeated := false


func _setup_area(size: Vector2, offset: Vector2) -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	add_child(shape)


func _check_player_contact() -> void:
	if defeated:
		return
	for body in get_overlapping_bodies():
		if not body is Player:
			continue
		var p := body as Player
		if p.is_dead:
			continue
		var from_above := p.velocity.y > 20.0 and p.global_position.y < global_position.y + 2.0
		if can_be_stomped and from_above:
			p.bounce()
			defeat()
			return
		p.take_damage(damage, global_position)


func defeat() -> void:
	defeated = true
	AudioManager.play_sfx("stomp")
	Effects.burst(get_parent(), global_position, Color(1, 0.8, 0.4), 14, 100.0)
	Effects.floating_text(get_parent(), global_position + Vector2(0, -10), "¡Fuera!", Color(1, 0.9, 0.5))
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.2), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
