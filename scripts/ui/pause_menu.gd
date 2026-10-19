class_name PauseMenu
extends CanvasLayer
## Pantalla de pausa: continuar, reiniciar nivel, opciones y menú principal.

var is_open := false
var _root: Control
var _menu: VBoxContainer
var _options: OptionsPanel


## Construye la pantalla de pausa (oculta); funciona aunque el juego esté en pausa.
func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.get_theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	center.add_child(_menu)
	_menu.add_child(UITheme.title_label("Pausa", 44, Color(1, 0.85, 0.5)))
	_menu.add_child(UITheme.button("Continuar", close))
	_menu.add_child(UITheme.button("Reiniciar nivel", _restart))
	_menu.add_child(UITheme.button("Opciones", _open_options))
	_menu.add_child(UITheme.button("Menú principal", _to_menu))
	var help := Label.new()
	help.text = "Mover: A/D o flechas · Saltar: ESPACIO/W · Correr: SHIFT · Hablar: E"
	help.add_theme_font_size_override("font_size", 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(help)
	_root.visible = false


## Abre o cierra la pausa con el botón de pausa.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if is_open:
			if _options == null:
				close()
		elif _can_open():
			open()


## No se puede pausar durante una transición, un diálogo o si el juego ya está pausado.
func _can_open() -> bool:
	if SceneTransition.busy:
		return false
	for box in get_tree().get_nodes_in_group("dialogue"):
		if box.active:
			return false
	return not get_tree().paused


## Pausa el juego y muestra el menú.
func open() -> void:
	is_open = true
	_root.visible = true
	get_tree().paused = true
	(_menu.get_child(1) as Button).grab_focus()


## Quita la pausa y oculta el menú.
func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false


## Reinicia el nivel actual.
func _restart() -> void:
	close()
	GameState.restart_level()


## Abre las opciones dentro de la pausa.
func _open_options() -> void:
	_menu.visible = false
	_options = OptionsPanel.new()
	_root.add_child(_options)
	_options.closed.connect(func() -> void:
		_options = null
		_menu.visible = true
		(_menu.get_child(3) as Button).grab_focus())


## Guarda y vuelve al menú principal.
func _to_menu() -> void:
	close()
	SaveSystem.save_game()
	SceneTransition.change_scene("res://scenes/menus/main_menu.tscn")
