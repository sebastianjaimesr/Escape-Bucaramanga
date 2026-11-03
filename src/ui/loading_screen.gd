class_name LoadingScreen
extends CanvasLayer
## Pantalla de carga y de error de carga. La usa SceneLoader.

signal back_requested

var _root: Control
var _title: Label
var _bar: ProgressBar
var _message: Label
var _back: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = ColorRect.new()
	(_root as ColorRect).color = UiStyle.BG
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	_title = UiStyle.label("Cargando…", 30, UiStyle.TEXT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_bar = ProgressBar.new()
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(420, 10)
	UiStyle.style_bar(_bar, UiStyle.ACCENT)
	box.add_child(_bar)
	_message = UiStyle.label("", 16, UiStyle.TEXT_DIM)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message)
	_back = UiStyle.button("Volver al menú principal")
	_back.pressed.connect(func() -> void: back_requested.emit())
	box.add_child(_back)
	hide_screen()


func show_loading(title: String) -> void:
	visible = true
	_title.text = title if title != "" else "Cargando…"
	_bar.visible = true
	_bar.value = 0.0
	_message.text = ""
	_back.visible = false


func set_progress(value: float) -> void:
	_bar.value = clampf(value, 0.0, 1.0)


func show_error(message: String, allow_back: bool) -> void:
	visible = true
	_title.text = "No se pudo cargar"
	_bar.visible = false
	_message.text = message
	_back.visible = allow_back
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func hide_screen() -> void:
	visible = false
