class_name PerformanceOverlay
extends CanvasLayer
## Medidor de rendimiento (F3 por defecto): FPS, tiempo de cuadro, llamadas de
## dibujo, objetos, memoria de video, renderizador y perfil de calidad.
## Los valores vienen de Performance y RenderingServer: son medidos, no estimados.

const REFRESH := 0.25

var _label: Label
var _timer := 0.0
var _frame_times: PackedFloat32Array = []


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.set_content_margin_all(10)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	UiStyle.place(panel, Vector4(1, 0, 1, 0), Vector4(-316, 16, -16, 16))
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	_label = UiStyle.label("", 13, Color(0.85, 1.0, 0.85))
	panel.add_child(_label)
	visible = bool(Settings.get_value("graphics", "show_fps"))
	Settings.changed.connect(_on_setting_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		Settings.set_value("graphics", "show_fps", not visible)


func _process(delta: float) -> void:
	_frame_times.append(delta * 1000.0)
	if _frame_times.size() > 120:
		_frame_times.remove_at(0)
	_timer -= delta
	if not visible or _timer > 0.0:
		return
	_timer = REFRESH
	var worst := 0.0
	var total := 0.0
	for t in _frame_times:
		worst = maxf(worst, t)
		total += t
	var avg := total / maxf(1.0, _frame_times.size())
	_label.text = "FPS %d\nCuadro %.1f ms (peor %.1f ms)\nDibujo: %d llamadas, %d objetos\nVRAM %.0f MB\n%s\nPerfil: %s" % [
		Engine.get_frames_per_second(), avg, worst,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		QualityProfiles.renderer_name(),
		QualityProfiles.LABELS[Settings.quality_profile()],
	]


func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section == "graphics" and key == "show_fps":
		visible = bool(value)
		_timer = 0.0
