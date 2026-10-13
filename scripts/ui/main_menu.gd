extends Node
## Menú principal: continuar, nueva partida, selección de nivel, opciones y créditos.

var _ui: Control
var _menu: VBoxContainer
var _sub: Control


func _ready() -> void:
	get_tree().paused = false
	var backdrop := MenuBackdrop.new()
	backdrop.characters = ["protagonist"]
	backdrop.start_x = 120.0
	add_child(backdrop)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.theme = UITheme.get_theme()
	layer.add_child(_ui)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.anchor_left = 0.5
	logo.anchor_right = 0.5
	logo.offset_left = -300
	logo.offset_right = 300
	logo.offset_top = 18
	logo.offset_bottom = 186
	_ui.add_child(logo)
	var tw := logo.create_tween().set_loops()
	tw.tween_property(logo, "modulate", Color(1, 0.85, 0.9), 0.9)
	tw.tween_property(logo, "modulate", Color(0.85, 0.9, 1), 0.9)
	_menu = VBoxContainer.new()
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.anchor_top = 0.38
	_menu.offset_left = -150
	_menu.offset_right = 150
	_menu.add_theme_constant_override("separation", 10)
	_ui.add_child(_menu)
	var has_progress := SaveSystem.has_save() and (GameState.unlocked_level > 0 or GameState.current_level > 0)
	if has_progress:
		var lvl: Dictionary = GameState.levels[clampi(GameState.current_level, 0, GameState.level_count() - 1)]
		_menu.add_child(UITheme.button("Continuar  (%s)" % String(lvl["title"]).get_slice(":", 0), _continue))
	_menu.add_child(UITheme.button("Nueva partida", _new_game))
	_menu.add_child(UITheme.button("Seleccionar nivel", _level_select))
	_menu.add_child(UITheme.button("Opciones", _options))
	_menu.add_child(UITheme.button("Créditos", _credits))
	if not OS.has_feature("web"):
		_menu.add_child(UITheme.button("Salir", func() -> void: get_tree().quit()))
	var footer := Label.new()
	footer.text = "A/D o flechas: mover · ESPACIO: saltar · SHIFT: correr · E: hablar · ESC: pausa\nObra de ficción inspirada en Bucaramanga. Personajes, lugares y persecución son imaginarios."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.anchor_left = 0.0
	footer.anchor_right = 1.0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_top = -52
	footer.offset_bottom = -8
	_ui.add_child(footer)
	AudioManager.play_music("menu")
	(_menu.get_child(0) as Button).call_deferred("grab_focus")


func _continue() -> void:
	GameState.continue_game()


func _new_game() -> void:
	GameState.new_game()


func _show_sub(panel: Control) -> void:
	_menu.visible = false
	_sub = panel
	_ui.add_child(panel)


func _close_sub() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = null
	_menu.visible = true
	(_menu.get_child(0) as Button).grab_focus()


func _options() -> void:
	var panel := OptionsPanel.new()
	panel.closed.connect(func() -> void:
		_sub = null
		_menu.visible = true
		(_menu.get_child(0) as Button).grab_focus())
	_menu.visible = false
	_ui.add_child(panel)
	_sub = panel


func _level_select() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Seleccionar nivel", 30, Color(1, 0.85, 0.5)))
	var first: Button = null
	for i in GameState.level_count():
		var info: Dictionary = GameState.levels[i]
		var best := int(GameState.best_bocadillos.get(info["id"], 0))
		var label := String(info["title"])
		if best > 0:
			label += "   (récord: %d bocadillos)" % best
		var idx := i
		var b := UITheme.button(label, func() -> void: GameState.start_level(idx))
		b.custom_minimum_size = Vector2(520, 40)
		b.disabled = i > GameState.unlocked_level
		if b.disabled:
			b.text = "Bloqueado: " + String(info["title"])
		box.add_child(b)
		if first == null and not b.disabled:
			first = b
	box.add_child(UITheme.button("Volver", _close_sub))
	_show_sub(panel)
	if first:
		first.grab_focus()


func _credits() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Créditos", 30, Color(1, 0.85, 0.5)))
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(600, 0)
	text.add_theme_font_size_override("font_size", 17)
	text.text = "Escape de Bucaramanga\n\nDiseño, programación, pixel art, música y efectos: generados de forma original para este proyecto (Godot 4 + GDScript).\nTodo el arte y el audio son procedurales y se distribuyen como CC0.\n\nLos personajes son ficticios e inspirados en fotografías de referencia del autor del proyecto. La persecución es un desafío de videojuego y no representa hechos reales."
	box.add_child(text)
	var back := UITheme.button("Volver", _close_sub)
	box.add_child(back)
	_show_sub(panel)
	back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _sub != null and event.is_action_pressed("ui_cancel") and not _sub is OptionsPanel:
		get_viewport().set_input_as_handled()
		_close_sub()
