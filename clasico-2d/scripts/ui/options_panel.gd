class_name OptionsPanel
extends PanelContainer
## Opciones de audio y visuales. Se usa en el menú principal y en la pausa.

signal closed

var _music: HSlider
var _sfx: HSlider
var _rain: CheckButton
var _fullscreen: CheckButton


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(460, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(UITheme.title_label("Opciones", 32, Color(1, 0.85, 0.5)))
	_music = _slider(box, "Música", float(GameState.settings.get("music", 0.7)))
	_music.value_changed.connect(func(v: float) -> void: _set_setting("music", v))
	_sfx = _slider(box, "Efectos de sonido", float(GameState.settings.get("sfx", 0.85)))
	_sfx.value_changed.connect(func(v: float) -> void:
		_set_setting("sfx", v)
		AudioManager.play_sfx("collect"))
	_rain = CheckButton.new()
	_rain.text = "Lluvia en los niveles que la tienen"
	_rain.button_pressed = bool(GameState.settings.get("rain", true))
	_rain.toggled.connect(func(on: bool) -> void: _set_setting("rain", on))
	box.add_child(_rain)
	_fullscreen = CheckButton.new()
	_fullscreen.text = "Pantalla completa"
	_fullscreen.button_pressed = bool(GameState.settings.get("fullscreen", false))
	_fullscreen.toggled.connect(func(on: bool) -> void: _set_setting("fullscreen", on))
	_fullscreen.visible = not OS.has_feature("web")
	box.add_child(_fullscreen)
	var back := UITheme.button("Volver", _close)
	box.add_child(back)
	back.call_deferred("grab_focus")


func _slider(parent: Container, label: String, value: float) -> HSlider:
	var l := Label.new()
	l.text = label
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(400, 24)
	parent.add_child(s)
	return s


func _set_setting(key: String, value: Variant) -> void:
	GameState.settings[key] = value
	SaveSystem.apply_settings()
	SaveSystem.save_game()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
