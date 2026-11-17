extends Node
## Menú principal: pantalla de título, continuar, nueva partida, selección de nivel
## con estrellas y récords, cómo jugar, opciones y créditos.
##
## La pantalla de título espera una tecla, clic o toque antes de mostrar el menú:
## así el primer sonido llega después de una interacción, como exigen los navegadores.

const VERSION_TEXT := "v1.1"

static var _title_passed := false

var _ui: Control
var _menu: VBoxContainer
var _sub: Control
var _logo: TextureRect
var _tagline: Label
var _press: Label
var _footer: Label
var _waiting_start := false


func _ready() -> void:
	get_tree().paused = false
	var backdrop := MenuBackdrop.new()
	backdrop.theme_name = "final"
	backdrop.characters = ["protagonist"]
	backdrop.start_x = 150.0
	add_child(backdrop)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.theme = UITheme.get_theme()
	layer.add_child(_ui)
	# franja oscura arriba para que el logo resalte sobre el cielo
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0.02, 0.01, 0.06, 0.85))
	grad.gradient.set_color(1, Color(0.02, 0.01, 0.06, 0.0))
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(0, 1)
	shade.texture = grad
	shade.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 260
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)

	_logo = TextureRect.new()
	_logo.texture = load("res://assets/ui/logo.png")
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.anchor_left = 0.5
	_logo.anchor_right = 0.5
	_logo.offset_left = -300
	_logo.offset_right = 300
	_logo.offset_top = 12
	_logo.offset_bottom = 172
	_logo.pivot_offset = Vector2(300, 80)
	_ui.add_child(_logo)
	var tw := _logo.create_tween().set_loops()
	tw.tween_property(_logo, "modulate", Color(1, 0.88, 0.92), 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_logo, "modulate", Color(0.88, 0.92, 1), 1.2).set_trans(Tween.TRANS_SINE)

	_tagline = Label.new()
	_tagline.text = "Una noche, una confusión y toda la ciudad por delante"
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline.add_theme_font_size_override("font_size", 18)
	_tagline.add_theme_color_override("font_color", Color(1, 0.86, 0.6))
	_tagline.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tagline.offset_top = 168
	_tagline.offset_bottom = 196
	_ui.add_child(_tagline)

	_menu = VBoxContainer.new()
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.anchor_top = 0.0
	_menu.offset_top = 206
	_menu.offset_left = -160
	_menu.offset_right = 160
	_menu.add_theme_constant_override("separation", 8)
	_ui.add_child(_menu)
	_build_menu_buttons()

	_press = Label.new()
	_press.text = "Toca la pantalla para empezar" if DisplayServer.is_touchscreen_available() \
		else "Presiona cualquier tecla para empezar"
	_press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press.add_theme_font_size_override("font_size", 24)
	_press.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_press.anchor_left = 0.0
	_press.anchor_right = 1.0
	_press.offset_top = -170
	_press.offset_bottom = -130
	_ui.add_child(_press)
	var blink := _press.create_tween().set_loops()
	blink.tween_property(_press, "modulate:a", 0.25, 0.7)
	blink.tween_property(_press, "modulate:a", 1.0, 0.7)

	_footer = Label.new()
	_footer.text = "Obra de ficción inspirada en lugares reales de Bucaramanga y Floridablanca.  ·  M: silenciar  ·  %s" % VERSION_TEXT
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 13)
	_footer.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	_footer.anchor_left = 0.0
	_footer.anchor_right = 1.0
	_footer.anchor_top = 1.0
	_footer.anchor_bottom = 1.0
	_footer.offset_top = -30
	_footer.offset_bottom = -8
	_ui.add_child(_footer)

	if _title_passed:
		_show_menu(false)
	else:
		_menu.visible = false
		_waiting_start = true
		# Entrada cinematográfica del logo
		_logo.modulate.a = 0.0
		_logo.scale = Vector2(1.15, 1.15)
		_tagline.modulate.a = 0.0
		_press.visible = false
		var intro := create_tween()
		intro.tween_interval(0.3)
		intro.tween_property(_logo, "modulate:a", 1.0, 0.9)
		intro.parallel().tween_property(_logo, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		intro.tween_property(_tagline, "modulate:a", 1.0, 0.6)
		intro.tween_callback(func() -> void: _press.visible = true)


func _build_menu_buttons() -> void:
	for c in _menu.get_children():
		c.queue_free()
	var has_progress := SaveSystem.has_save() and (GameState.unlocked_level > 0 or GameState.current_level > 0)
	if has_progress:
		var lvl: Dictionary = GameState.levels[clampi(GameState.current_level, 0, GameState.level_count() - 1)]
		_menu.add_child(UITheme.button("Continuar  ·  %s" % String(lvl["title"]).get_slice(":", 0), _continue))
	_menu.add_child(UITheme.button("Nueva partida", _new_game))
	_menu.add_child(UITheme.button("Seleccionar nivel", _level_select))
	_menu.add_child(UITheme.button("Cómo jugar", _how_to_play))
	_menu.add_child(UITheme.button("Opciones", _options))
	_menu.add_child(UITheme.button("Créditos", _credits))
	if not OS.has_feature("web"):
		_menu.add_child(UITheme.button("Salir", func() -> void: get_tree().quit()))
	for b in _menu.get_children():
		(b as Button).custom_minimum_size = Vector2(320, 40)


func _input(event: InputEvent) -> void:
	if not _waiting_start or not _press.visible:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.is_echo()) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		_waiting_start = false
		_title_passed = true
		AudioManager.play_sfx("start")
		_show_menu(true)


func _show_menu(animated: bool) -> void:
	_press.visible = false
	_menu.visible = true
	AudioManager.play_music("menu")
	if animated:
		_menu.modulate.a = 0.0
		_menu.position.y += 24
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_menu, "modulate:a", 1.0, 0.35)
		tw.tween_property(_menu, "position:y", _menu.position.y - 24, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	(_menu.get_child(0) as Button).call_deferred("grab_focus")


func _continue() -> void:
	GameState.continue_game()


func _new_game() -> void:
	GameState.new_game()


func _show_sub(panel: Control) -> void:
	_menu.visible = false
	_logo.visible = false
	_tagline.visible = false
	_sub = panel
	_ui.add_child(panel)


func _close_sub() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = null
	_menu.visible = true
	_logo.visible = true
	_tagline.visible = true
	(_menu.get_child(0) as Button).grab_focus()


func _options() -> void:
	var panel := OptionsPanel.new()
	panel.closed.connect(func() -> void:
		_sub = null
		_close_sub())
	_show_sub(panel)


func _centered_panel(width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(width, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	return panel


# ---------------------------------------------------------------------------
# Selección de nivel con estrellas, puntaje y hormigas culonas
# ---------------------------------------------------------------------------
func _level_select() -> void:
	var panel := _centered_panel(720)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UITheme.title_label("Ruta por Bucaramanga", 28, Color(1, 0.85, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var totals := Label.new()
	totals.text = "Estrellas %d / %d     Puntaje total: %d" % [GameState.total_stars(), GameState.level_count() * 3,
		GameState.total_score()]
	totals.add_theme_font_size_override("font_size", 16)
	totals.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	totals.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(totals)
	var first: Button = null
	for i in GameState.level_count():
		var b := _level_card(i)
		box.add_child(b)
		if first == null and not b.disabled:
			first = b
	var hint := Label.new()
	hint.text = "Estrellas: completar el nivel · 75 % de los granizados · las 3 hormigas culonas"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.95))
	box.add_child(hint)
	var back := UITheme.button("Volver", _close_sub)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	_show_sub(panel)
	if first:
		first.grab_focus()


func _level_card(i: int) -> Button:
	var info: Dictionary = GameState.levels[i]
	var id: String = info["id"]
	var locked := i > GameState.unlocked_level
	var b := UITheme.button("", func() -> void: GameState.start_level(i))
	b.custom_minimum_size = Vector2(690, 50)
	b.disabled = locked
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var num := Label.new()
	num.text = str(i + 1)
	num.add_theme_font_size_override("font_size", 26)
	num.add_theme_color_override("font_color", Color(1, 0.4, 0.5) if not locked else Color(0.4, 0.4, 0.5))
	num.custom_minimum_size = Vector2(26, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(num)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", -4)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var name_l := Label.new()
	name_l.text = String(info["title"]).get_slice(": ", 1) if not locked else "Bloqueado"
	name_l.add_theme_font_size_override("font_size", 19)
	name_l.add_theme_color_override("font_color", UITheme.TEXT if not locked else Color(0.5, 0.5, 0.58))
	texts.add_child(name_l)
	var place := Label.new()
	place.text = String(info.get("place", "")) if not locked else "Completa el nivel anterior"
	place.add_theme_font_size_override("font_size", 13)
	place.add_theme_color_override("font_color", Color(0.7, 0.75, 0.95) if not locked else Color(0.45, 0.45, 0.55))
	texts.add_child(place)
	if not locked:
		var best := int(GameState.best_scores.get(id, 0))
		var stats := Label.new()
		stats.text = ("Récord %d" % best if best > 0 else "Sin jugar") + \
			"\nHormigas %d/3" % int(GameState.best_hormigas.get(id, 0))
		stats.add_theme_font_size_override("font_size", 13)
		stats.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(stats)
		row.add_child(UITheme.stars_row(int(GameState.best_stars.get(id, 0)), 22))
	for c in row.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# ---------------------------------------------------------------------------
# Cómo jugar
# ---------------------------------------------------------------------------
func _how_to_play() -> void:
	var panel := _centered_panel(760)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Cómo jugar", 30, Color(1, 0.85, 0.5)))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size = Vector2(720, 0)
	text.add_theme_font_size_override("normal_font_size", 16)
	text.add_theme_font_size_override("bold_font_size", 16)
	text.text = how_to_play_text()
	box.add_child(text)
	var back := UITheme.button("Entendido", _close_sub)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	_show_sub(panel)
	back.grab_focus()


static func how_to_play_text() -> String:
	return "[color=#ffd27a][b]Historia[/b][/color]  Sebas fue confundido con un ladrón. Cruza la ciudad, reúne a tus tres amigos y llega al mirador del Cerro del Santísimo antes de que el dron patrulla te alcance.\n\n" \
		+ "[color=#ffd27a][b]Controles[/b][/color]  Mover: A/D o flechas · Saltar: ESPACIO, W o Z (mantener = más alto) · Correr: SHIFT o X · Hablar: E o flecha abajo · Pausa: ESC · Silenciar: M.  En celular aparecen botones táctiles; con mando: cruceta, A saltar, X correr, Y hablar.\n\n" \
		+ "[color=#ffd27a][b]Reglas[/b][/color]  Tienes 3 corazones y 5 vidas. Vidrios, conos y drones quitan un corazón; caer al vacío o que te alcance la patrulla cuesta una vida. Reapareces en el último punto de control. Salta encima de los drones vigía; a los policías solo se les esquiva.\n\n" \
		+ "[color=#ffd27a][b]Puntaje[/b][/color]  Granizado 10 · Dron pisado 50 (combo x2, x3… si encadenas sin tocar el suelo) · Pista 150 · Hormiga culona 300 · Amigo 500. Al terminar: +1000, bono por tiempo y +1500 si no perdiste vidas.\n\n" \
		+ "[color=#ffd27a][b]Estrellas[/b][/color]  Una por completar el nivel, otra por recoger el 75 % de los granizados y otra por encontrar las 3 hormigas culonas escondidas en las rutas altas. Cada 25 granizados ganas una vida."


func _credits() -> void:
	var panel := _centered_panel(680)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Créditos", 30, Color(1, 0.85, 0.5)))
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(640, 0)
	text.add_theme_font_size_override("font_size", 16)
	text.text = "Escape de Bucaramanga %s\nCreado por Juan Sebastián Jaimes Rolon.\n\nHecho con Godot 4 y GDScript. Pixel art, música y efectos de sonido originales y procedurales (CC0), generados con las herramientas de la carpeta tools/.\n\nEscenarios inspirados en el Centro y la Calle 35, Cabecera, el Parque San Pío, el Parque García Rovira (Iglesia de San Laureano y Capilla de los Dolores), el Viaducto de la Novena y el Cerro del Santísimo. Son interpretaciones artísticas, no reproducciones exactas.\n\nLos personajes son ficticios. La persecución es un desafío de videojuego y no representa hechos reales." % VERSION_TEXT
	box.add_child(text)
	var back := UITheme.button("Volver", _close_sub)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	_show_sub(panel)
	back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _sub != null and event.is_action_pressed("ui_cancel") and not _sub is OptionsPanel:
		get_viewport().set_input_as_handled()
		_close_sub()
