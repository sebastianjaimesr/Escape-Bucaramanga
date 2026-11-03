extends CanvasLayer
## Transiciones con fundido y tarjeta de título entre escenas.

signal transition_finished

var busy := false
var _fade: ColorRect
var _title: Label
var _subtitle: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.07, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_title = _make_label(40, Color(1, 0.96, 0.88))
	_title.position.y = -30
	_fade.add_child(_title)
	_subtitle = _make_label(20, Color(0.7, 0.85, 1.0))
	_subtitle.position.y = 30
	_fade.add_child(_subtitle)


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	return l


func change_scene(path: String, title: String = "", subtitle: String = "") -> void:
	if busy:
		return
	busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_title.text = title
	_subtitle.text = subtitle
	_title.visible = false
	_subtitle.visible = false
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.35)
	await tw.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("No se pudo cargar la escena %s (%d)" % [path, err])
	if title != "":
		_title.visible = true
		_subtitle.visible = subtitle != ""
		await get_tree().create_timer(1.3, true).timeout
	else:
		await get_tree().process_frame
	_title.visible = false
	_subtitle.visible = false
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, 0.4)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	transition_finished.emit()


## Destello rápido de pantalla (daño, cambios dramáticos).
func flash(color: Color = Color(1, 0.2, 0.25, 0.35), duration: float = 0.25) -> void:
	if busy:
		return
	var old := _fade.color
	_fade.color = color
	_fade.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, duration)
	await tw.finished
	_fade.color = old
