class_name TouchControls
extends CanvasLayer
## Controles táctiles. Solo se ven en pantallas táctiles (o si force_visible es true,
## útil para capturas y pruebas). Se ubican en las esquinas inferiores para no tapar
## el HUD superior ni el centro de la acción, y escalan con la altura de la pantalla.

static var force_visible := false

const BUTTONS := [
	["left", "move_left"],
	["right", "move_right"],
	["run", "run"],
	["action", "interact"],
	["jump", "jump"],
	["pause", "pause"],
]

var _buttons: Dictionary = {}


func _ready() -> void:
	layer = 12
	for def: Array in BUTTONS:
		var b := TouchScreenButton.new()
		b.texture_normal = load("res://assets/ui/touch_%s.png" % def[0])
		b.action = def[1]
		b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS if force_visible \
			else TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		b.passby_press = def[1].begins_with("move_")
		var shape := CircleShape2D.new()
		shape.radius = 32.0
		b.shape = shape
		b.shape_centered = true
		b.modulate.a = 0.6
		add_child(b)
		_buttons[def[0]] = b
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	# Botones de ~1/4.5 del alto de la pantalla, con límites razonables.
	var s := clampf(size.y / 4.5 / 64.0, 1.0, 1.6)
	for b: TouchScreenButton in _buttons.values():
		b.scale = Vector2(s, s)
	var d := 64.0 * s
	var m := 14.0
	var y := size.y - d - m
	_buttons["left"].position = Vector2(m, y)
	_buttons["right"].position = Vector2(m + d + 10, y)
	_buttons["jump"].position = Vector2(size.x - d - m, y)
	_buttons["run"].position = Vector2(size.x - 2 * d - m - 10, y + d * 0.2)
	_buttons["action"].position = Vector2(size.x - d - m, y - d - 8)
	# Pausa: esquina derecha, debajo del panel de puntaje y la barra de persecución.
	var ps := s * 0.7
	_buttons["pause"].scale = Vector2(ps, ps)
	_buttons["pause"].position = Vector2(size.x - 64.0 * ps - m, 112)
