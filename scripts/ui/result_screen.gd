class_name ResultScreen
extends Node
## Pantallas de resultado: victoria de nivel, derrota y final de la historia.

@export_enum("victory", "game_over", "ending") var mode := "victory"

var _box: VBoxContainer


func _ready() -> void:
	get_tree().paused = false
	var backdrop := MenuBackdrop.new()
	match mode:
		"victory":
			backdrop.theme_name = _victory_theme()
			backdrop.running = false
			backdrop.show_chaser = false
			backdrop.characters = ["protagonist"] + GameState.friends
		"game_over":
			backdrop.theme_name = "cai"
			backdrop.running = false
			backdrop.show_chaser = true
			backdrop.characters = []
		"ending":
			backdrop.theme_name = "final"
			backdrop.running = false
			backdrop.show_chaser = false
			backdrop.characters = ["protagonist", "gorra", "rulos", "gafas"]
	add_child(backdrop)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.theme = UITheme.get_theme()
	layer.add_child(ui)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.06, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_bottom = 1.0 if mode == "victory" else 0.78
	ui.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	panel.add_child(_box)
	match mode:
		"victory":
			_build_victory()
		"game_over":
			_build_game_over()
		"ending":
			_build_ending()
	var buttons := _box.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		(buttons[0] as Button).call_deferred("grab_focus")


func _text(text: String, size: int = 20, color: Color = UITheme.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
	return l


func _victory_theme() -> String:
	var idx := int(GameState.last_result.get("level_index", -1))
	if idx >= 0 and idx < GameState.level_count():
		return String(GameState.levels[idx].get("theme", "calles"))
	return "calles"


func _build_victory() -> void:
	AudioManager.play_music("park")
	var r: Dictionary = GameState.last_result
	_box.add_child(UITheme.title_label("¡Nivel superado!", 38, Color(0.5, 1, 0.7)))
	_text(String(r.get("title", "")), 20, Color(0.75, 0.85, 1))
	var stars := UITheme.stars_row(0, 40)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(stars)
	# Tabla de resultados: dos columnas (concepto / valor)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 0)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(grid)
	var t := int(r.get("time", 0.0))
	var rows: Array = [
		["Granizados", "%d / %d" % [int(r.get("granizados", 0)), int(r.get("total_granizados", 0))]],
		["Hormigas culonas", "%d / %d" % [int(r.get("hormigas", 0)), int(r.get("total_hormigas", 0))]],
		["Tiempo", "%d:%02d" % [t / 60, t % 60]],
	]
	if int(r.get("total_pistas", 0)) > 0:
		rows.append(["Pistas", "%d / %d" % [int(r.get("pistas", 0)), int(r.get("total_pistas", 0))]])
	rows.append(["Puntos en el nivel", str(int(r.get("base_score", 0)))])
	rows.append(["Nivel completado", "+%d" % int(r.get("bonus_complete", 0))])
	rows.append(["Bono de tiempo", "+%d" % int(r.get("bonus_time", 0))])
	rows.append(["Sin perder vidas", "+%d" % int(r.get("bonus_no_deaths", 0)) if int(r.get("bonus_no_deaths", 0)) > 0 else "—"])
	for row: Array in rows:
		var k := Label.new()
		k.text = row[0]
		k.add_theme_font_size_override("font_size", 15)
		k.add_theme_color_override("font_color", Color(0.78, 0.8, 0.95))
		grid.add_child(k)
		var v := Label.new()
		v.text = row[1]
		v.add_theme_font_size_override("font_size", 15)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(v)
	var total := _text("PUNTAJE  0", 28, Color(1, 0.9, 0.5))
	var record := _text("¡Nuevo récord!" if bool(r.get("new_record", false)) else "Récord: %d" % int(
		GameState.best_scores.get(_level_id(r), 0)), 16, Color(1, 0.6, 0.7) if bool(r.get("new_record", false)) else Color(0.7, 0.7, 0.85))
	record.modulate.a = 0.0
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(actions)
	for def: Array in [["Siguiente nivel", func() -> void: GameState.start_level(GameState.current_level)],
			["Repetir", func() -> void: GameState.start_level(int(r.get("level_index", 0)))],
			["Menú", _to_menu]]:
		var b := UITheme.button(def[0], def[1])
		b.custom_minimum_size = Vector2(190 if def[0] == "Siguiente nivel" else 130, 42)
		actions.add_child(b)
	_animate_victory(total, record, stars, int(r.get("score", 0)), int(r.get("stars", 1)))


func _level_id(r: Dictionary) -> String:
	var idx := int(r.get("level_index", 0))
	return String(GameState.levels[clampi(idx, 0, GameState.level_count() - 1)]["id"])


## Conteo del puntaje y aparición de las estrellas una a una.
func _animate_victory(total: Label, record: Label, stars: HBoxContainer, score: int, earned: int) -> void:
	await get_tree().create_timer(0.5).timeout
	var shown := 0.0
	var steps := 30
	for i in steps + 1:
		shown = score * float(i) / steps
		total.text = "PUNTAJE  %d" % int(shown)
		if i % 3 == 0:
			AudioManager.play_sfx("tally")
		await get_tree().create_timer(0.03).timeout
	for i in earned:
		var star := stars.get_child(i) as TextureRect
		star.texture = UITheme.star_icon(true).texture
		star.scale = Vector2(1.8, 1.8)
		var tw := star.create_tween()
		tw.tween_property(star, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioManager.play_sfx("star")
		await get_tree().create_timer(0.3).timeout
	record.create_tween().tween_property(record, "modulate:a", 1.0, 0.3)


func _build_game_over() -> void:
	AudioManager.stop_music()
	AudioManager.play_sfx("lose")
	var r: Dictionary = GameState.last_result
	_box.add_child(UITheme.title_label("¡Te alcanzaron!", 44, Color(1, 0.4, 0.45)))
	_text(String(r.get("title", "")), 20, Color(0.75, 0.85, 1))
	_text("Te quedaste sin vidas. Puedes reintentar el nivel desde el comienzo con 5 vidas.", 19)
	_box.add_child(UITheme.button("Reintentar nivel", func() -> void:
		GameState.lives = GameState.MAX_LIVES
		GameState.restart_level()))
	_box.add_child(UITheme.button("Menú principal", func() -> void:
		GameState.lives = GameState.MAX_LIVES
		_to_menu()))


func _build_ending() -> void:
	AudioManager.play_music("finale")
	_box.add_child(UITheme.title_label("¡Fin de la aventura!", 40, Color(1, 0.85, 0.5)))
	_text("Sebas, Buitrago, Diaz y Gordo llegaron juntos al mirador del Santísimo. El video aclaró la confusión y la noche terminó con granizados y la ciudad iluminada a sus pies.", 20)
	var total := 0
	for key: String in GameState.best_granizados:
		total += int(GameState.best_granizados[key])
	var hormigas := 0
	for key: String in GameState.best_hormigas:
		hormigas += int(GameState.best_hormigas[key])
	_text("Puntaje total: %d   ·   Estrellas: %d / %d" % [GameState.total_score(), GameState.total_stars(),
		GameState.level_count() * 3], 22, Color(1, 0.9, 0.5))
	_text("Granizados: %d   ·   Hormigas culonas: %d/%d" % [total, hormigas,
		GameState.level_count() * GameState.HORMIGAS_PER_LEVEL], 18, Color(1, 0.8, 0.8))
	_text("Gracias por jugar Escape de Bucaramanga. Vuelve a cualquier nivel para conseguir las tres estrellas.", 16, Color(0.75, 0.8, 1))
	_box.add_child(UITheme.button("Volver al menú", _to_menu))


func _to_menu() -> void:
	SceneTransition.change_scene("res://scenes/menus/main_menu.tscn")
