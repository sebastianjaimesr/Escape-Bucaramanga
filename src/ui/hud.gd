class_name Hud
extends CanvasLayer
## HUD del prototipo: resistencia, ayuda de controles y aviso para capturar el ratón.
## El HUD completo (salud, minimapa, objetivos, persecución…) llega en la Fase 9.

const HINT_TIME := 14.0

var stamina_bar: ProgressBar
var _stamina_box: Control
var _hint: Label
var _capture: Label
var _hint_timer := HINT_TIME
var _stamina_visible_timer := 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_stamina_box = VBoxContainer.new()
	UiStyle.place(_stamina_box, Vector4(0, 1, 0, 1), Vector4(28, -72, 260, -28))
	root.add_child(_stamina_box)
	_stamina_box.add_child(UiStyle.label("RESISTENCIA", 12, UiStyle.TEXT_DIM))
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(220, 8)
	stamina_bar.max_value = PlayerController.MAX_STAMINA
	stamina_bar.value = PlayerController.MAX_STAMINA
	stamina_bar.show_percentage = false
	UiStyle.style_bar(stamina_bar, UiStyle.OK)
	_stamina_box.add_child(stamina_bar)
	_stamina_box.modulate.a = 0.0

	_hint = UiStyle.label("", 15, UiStyle.TEXT)
	_hint.position = Vector2(28, 24)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	root.add_child(_hint)
	_refresh_hint()

	_capture = UiStyle.label("Haz clic para controlar la cámara", 18, UiStyle.TEXT)
	UiStyle.place(_capture, Vector4(0.5, 1, 0.5, 1), Vector4(-250, -150, 250, -110))
	_capture.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capture.add_theme_constant_override("outline_size", 6)
	_capture.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	root.add_child(_capture)

	add_child(PerformanceOverlay.new())
	EventBus.stamina_changed.connect(_on_stamina_changed)
	InputConfig.bindings_changed.connect(_refresh_hint)


func _refresh_hint() -> void:
	var move := "%s%s%s%s" % [InputConfig.key_name("move_forward"), InputConfig.key_name("move_left"),
			InputConfig.key_name("move_back"), InputConfig.key_name("move_right")]
	_hint.text = "%s  mover\n%s  correr\n%s  saltar\n%s  agacharse\nRatón  cámara\nEsc  pausa\n%s  rendimiento" % [
		move, InputConfig.key_name("run"), InputConfig.key_name("jump"),
		InputConfig.key_name("crouch"), InputConfig.key_name("toggle_fps")]


func _process(delta: float) -> void:
	_capture.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_tree().paused
	if _hint_timer > 0.0:
		_hint_timer -= delta
		_hint.modulate.a = clampf(_hint_timer / 2.0, 0.0, 1.0)
	_stamina_visible_timer -= delta
	var target := 1.0 if _stamina_visible_timer > 0.0 else 0.0
	_stamina_box.modulate.a = move_toward(_stamina_box.modulate.a, target, delta * 3.0)


func _on_stamina_changed(value: float, max_value: float, exhausted: bool) -> void:
	stamina_bar.value = value
	UiStyle.style_bar(stamina_bar, UiStyle.WARN if exhausted else UiStyle.OK)
	# La barra solo aparece mientras cambia y un momento después de llenarse.
	_stamina_visible_timer = 1.5 if value >= max_value else 3.0
