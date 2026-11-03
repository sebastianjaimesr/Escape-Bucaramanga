class_name SettingsPanel
extends PanelContainer
## Configuración: gráficos, cámara y controles reasignables.
## Cada cambio se aplica y se guarda al momento (Settings / InputConfig).

signal closed

var _rebind_action := ""
var _rebind_buttons: Dictionary = {}
var _profile: OptionButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiStyle.PANEL
	sb.border_color = UiStyle.PANEL_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(24)
	add_theme_stylebox_override("panel", sb)
	custom_minimum_size = Vector2(560, 0)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	add_child(outer)
	outer.add_child(UiStyle.label("Configuración", 28))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	_section(list, "Gráficos")
	_profile = OptionButton.new()
	for id: String in QualityProfiles.ORDER:
		_profile.add_item(QualityProfiles.LABELS[id])
	_profile.selected = QualityProfiles.ORDER.find(Settings.quality_profile())
	_profile.item_selected.connect(func(i: int) -> void:
		Settings.set_value("graphics", "profile", QualityProfiles.ORDER[i]))
	_row(list, "Calidad", _profile)
	var renderer := UiStyle.label(QualityProfiles.renderer_name(), 14, UiStyle.TEXT_DIM)
	_row(list, "Renderizador", renderer)
	_row(list, "Medidor de rendimiento", _check("graphics", "show_fps"))
	if Settings.supports_fullscreen():
		_row(list, "Pantalla completa", _check("graphics", "fullscreen"))

	_section(list, "Cámara")
	_row(list, "Sensibilidad del ratón", _slider("camera", "mouse_sensitivity", 0.05, 0.8, 0.01))
	_row(list, "Sensibilidad del mando", _slider("camera", "stick_sensitivity", 60.0, 300.0, 5.0))
	_row(list, "Campo de visión", _slider("camera", "fov", 60.0, 90.0, 1.0))
	_row(list, "Invertir eje vertical", _check("camera", "invert_y"))

	_section(list, "Controles")
	list.add_child(UiStyle.label("Haz clic en una tecla y pulsa la nueva. Esc cancela.", 13, UiStyle.TEXT_DIM))
	for action: String in InputConfig.IN_USE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, 34)
		b.pressed.connect(_start_rebind.bind(action))
		_rebind_buttons[action] = b
		_row(list, InputConfig.label(action), b)
	var reset := UiStyle.button("Restaurar controles", 220)
	reset.pressed.connect(func() -> void: InputConfig.reset_defaults())
	list.add_child(reset)
	_refresh_bindings()
	InputConfig.bindings_changed.connect(_refresh_bindings)

	var close := UiStyle.button("Cerrar", 200)
	close.pressed.connect(func() -> void: closed.emit())
	outer.add_child(close)


func _input(event: InputEvent) -> void:
	if _rebind_action == "" or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	var key := (event as InputEventKey).physical_keycode
	var action := _rebind_action
	_rebind_action = ""
	if key != KEY_ESCAPE and key != KEY_NONE:
		InputConfig.rebind(action, key)
	_refresh_bindings()


func _start_rebind(action: String) -> void:
	_rebind_action = action
	(_rebind_buttons[action] as Button).text = "Pulsa una tecla…"


func _refresh_bindings() -> void:
	for action: String in _rebind_buttons:
		(_rebind_buttons[action] as Button).text = InputConfig.key_name(action)


func _section(parent: Control, title: String) -> void:
	var l := UiStyle.label(title.to_upper(), 13, UiStyle.ACCENT)
	parent.add_child(l)


func _row(parent: Control, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UiStyle.label(text, 16)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(control)
	parent.add_child(row)


func _check(section: String, key: String) -> CheckBox:
	var c := CheckBox.new()
	c.button_pressed = bool(Settings.get_value(section, key))
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(section, key, on))
	return c


func _slider(section: String, key: String, min_v: float, max_v: float, step: float) -> HBoxContainer:
	var box := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.custom_minimum_size = Vector2(160, 24)
	s.value = float(Settings.get_value(section, key))
	var v := UiStyle.label("", 14, UiStyle.TEXT_DIM)
	v.custom_minimum_size = Vector2(44, 0)
	v.text = str(snappedf(s.value, step))
	s.value_changed.connect(func(val: float) -> void:
		v.text = str(snappedf(val, step))
		Settings.set_value(section, key, val))
	box.add_child(s)
	box.add_child(v)
	return box
