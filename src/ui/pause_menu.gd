class_name PauseMenu
extends CanvasLayer
## Pausa (Esc): continuar, configuración, volver al punto de inicio, menú principal.

signal respawn_requested

var _dim: ColorRect
var _menu: VBoxContainer
var _settings: SettingsPanel
var _center: CenterContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	_center.add_child(_menu)
	_menu.add_child(UiStyle.label("Pausa", 34))
	var resume := UiStyle.button("Continuar")
	resume.pressed.connect(close)
	_menu.add_child(resume)
	var settings := UiStyle.button("Configuración")
	settings.pressed.connect(_show_settings)
	_menu.add_child(settings)
	var respawn := UiStyle.button("Volver al punto de inicio")
	respawn.pressed.connect(func() -> void:
		respawn_requested.emit()
		close())
	_menu.add_child(respawn)
	var menu := UiStyle.button("Menú principal")
	menu.pressed.connect(func() -> void: SceneLoader.change_scene(SceneLoader.MAIN_MENU, "Menú principal"))
	_menu.add_child(menu)
	_settings = SettingsPanel.new()
	_settings.closed.connect(_hide_settings)
	_settings.visible = false
	_center.add_child(_settings)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if not visible:
		open()
	elif _settings.visible:
		_hide_settings()
	else:
		close()


func open() -> void:
	if visible:
		return
	visible = true
	_hide_settings()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	EventBus.pause_changed.emit(true)
	(_menu.get_child(1) as Button).grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	EventBus.pause_changed.emit(false)
	# En el navegador, capturar el ratón solo funciona dentro de un clic del jugador:
	# el clic en "Continuar" lo es; si no, el HUD pide hacer clic.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_settings() -> void:
	_menu.visible = false
	_settings.visible = true


func _hide_settings() -> void:
	_settings.visible = false
	_menu.visible = true
