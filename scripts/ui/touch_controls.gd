class_name TouchControls
extends CanvasLayer
## Controles táctiles básicos. Solo se ven en pantallas táctiles.

const BUTTONS := [
	["left", "move_left"],
	["right", "move_right"],
	["run", "run"],
	["action", "interact"],
	["jump", "jump"],
	["pause", "pause"],
]

var _buttons: Dictionary = {}


## Crea los botones táctiles; cada uno dispara una acción del juego (mover, saltar…).
func _ready() -> void:
	layer = 12
	for def: Array in BUTTONS:
		var b := TouchScreenButton.new()
		b.texture_normal = load("res://assets/ui/touch_%s.png" % def[0])
		b.action = def[1]
		b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		b.passby_press = def[1].begins_with("move_")
		var shape := CircleShape2D.new()
		shape.radius = 32.0
		b.shape = shape
		b.shape_centered = true
		b.modulate.a = 0.75
		add_child(b)
		_buttons[def[0]] = b
	get_viewport().size_changed.connect(_layout)
	_layout()


## Ubica los botones según el tamaño de la pantalla: dirección a la izquierda, acciones a la derecha.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var s := 1.4
	for b: TouchScreenButton in _buttons.values():
		b.scale = Vector2(s, s)
	var d := 64.0 * s
	var y := size.y - d - 18.0
	_buttons["left"].position = Vector2(18, y)
	_buttons["right"].position = Vector2(18 + d + 12, y)
	_buttons["jump"].position = Vector2(size.x - d - 18, y)
	_buttons["run"].position = Vector2(size.x - 2 * d - 30, y + 10)
	_buttons["action"].position = Vector2(size.x - d - 18, y - d - 10)
	_buttons["pause"].position = Vector2(size.x * 0.5 - d * 0.35, 8)
	_buttons["pause"].scale = Vector2(0.9, 0.9)
