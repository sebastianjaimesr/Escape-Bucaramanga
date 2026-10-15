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
			backdrop.theme_name = "calles"
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
	center.anchor_bottom = 0.78
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
	for child in _box.get_children():
		if child is Button:
			(child as Button).call_deferred("grab_focus")
			break


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


func _build_victory() -> void:
	AudioManager.play_music("park")
	var r: Dictionary = GameState.last_result
	_box.add_child(UITheme.title_label("¡Nivel superado!", 40, Color(0.5, 1, 0.7)))
	_text(String(r.get("title", "")), 22, Color(0.75, 0.85, 1))
	var t := int(r.get("time", 0.0))
	var lines := "Granizados: %d / %d\nTiempo: %d:%02d\nVidas: %d" % [
		int(r.get("granizados", 0)), int(r.get("total_granizados", 0)), t / 60, t % 60, int(r.get("lives", 0))]
	if int(r.get("total_pistas", 0)) > 0:
		lines += "\nPistas: %d / %d" % [int(r.get("pistas", 0)), int(r.get("total_pistas", 0))]
	if int(r.get("friends", 0)) > 0:
		lines += "\nAmigos en el grupo: %d / 3" % int(r.get("friends", 0))
	_text(lines, 22)
	_text("Progreso guardado.", 15, Color(0.7, 0.7, 0.85))
	_box.add_child(UITheme.button("Siguiente nivel", func() -> void: GameState.start_level(GameState.current_level)))
	_box.add_child(UITheme.button("Menú principal", _to_menu))


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
	_text("Sebas, Buitrago, Diaz y Gordo llegaron juntos al mirador. El video aclaró la confusión y la noche terminó con granizados y la ciudad iluminada a sus pies.", 20)
	var total := 0
	for key: String in GameState.best_granizados:
		total += int(GameState.best_granizados[key])
	_text("Granizados (mejor marca total): %d" % total, 20, Color(1, 0.8, 0.8))
	_text("Gracias por jugar Escape de Bucaramanga. La historia puede continuar: nuevos niveles se agregan en data/levels.", 16, Color(0.75, 0.8, 1))
	_box.add_child(UITheme.button("Volver al menú", _to_menu))


func _to_menu() -> void:
	SceneTransition.change_scene("res://scenes/menus/main_menu.tscn")
