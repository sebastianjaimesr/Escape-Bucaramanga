class_name PatrolLights
extends Node2D
## Par de luces roja y azul que se alternan (patrullas ficticias).

@export var interval := 0.22
@export var energy := 1.2
@export var scale_amount := 1.4

var _red: PointLight2D
var _blue: PointLight2D
var _time := 0.0


func _ready() -> void:
	var tex: Texture2D = load("res://assets/sprites/light.png")
	_red = _make(tex, Color(1.0, 0.15, 0.2), Vector2(-6, 0))
	_blue = _make(tex, Color(0.2, 0.4, 1.0), Vector2(6, 0))
	_blue.enabled = false


func _make(tex: Texture2D, color: Color, offset: Vector2) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex
	l.color = color
	l.energy = energy
	l.texture_scale = scale_amount
	l.position = offset
	add_child(l)
	return l


func _process(delta: float) -> void:
	_time += delta
	if _time >= interval:
		_time = 0.0
		_red.enabled = not _red.enabled
		_blue.enabled = not _blue.enabled
