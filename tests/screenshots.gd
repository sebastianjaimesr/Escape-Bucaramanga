extends Node
## Captura pantallas del menú y de cada nivel para revisión visual.
##   godot --path . res://tests/screenshots.tscn
## Las imágenes quedan en user://screenshots/.

const OUT := "user://screenshots/"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OUT)
	for i in GameState.level_count():
		var d := GameState.load_level_data(GameState.levels[i]["id"])
		GameState.intros_seen[d.get("intro", "")] = true
	var dummy := Node.new()
	get_tree().root.add_child.call_deferred(dummy)
	await get_tree().process_frame
	get_tree().current_scene = dummy
	SceneTransition.change_scene("res://scenes/menus/main_menu.tscn")
	await SceneTransition.transition_finished
	await _wait(2.4)
	_shot("00a_titulo")
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_ENTER
	Input.parse_input_event(ev)
	await _wait(0.8)
	_shot("00b_menu")
	var menu := get_tree().current_scene
	menu.call("_level_select")
	await _wait(0.3)
	_shot("00c_seleccion")
	menu.call("_close_sub")
	menu.call("_how_to_play")
	await _wait(0.3)
	_shot("00d_como_jugar")
	menu.call("_close_sub")
	for i in GameState.level_count():
		TouchControls.force_visible = i == 0  # el nivel 1 se captura con controles táctiles
		GameState.start_level(i)
		await SceneTransition.transition_finished
		await _wait(0.6)
		var level := get_tree().current_scene as Level
		if level:
			# Avanza un poco para mostrar el escenario con la persecución activa.
			level.player.global_position.x += 260.0 + i * 40.0
			level._start_chase()
			level.chase._x = level.player.global_position.x - 180.0
			level.camera.snap_to_target()
		await _wait(1.2)
		if level:
			level.hud._toast_time = 0.0
			level.hud._toast.modulate.a = 0.0
		_shot("%02d_%s" % [i + 1, GameState.levels[i]["id"]])
		if i == 2 and level:
			level.pause_menu.open()
			await _wait(0.2)
			_shot("%02d_pausa" % (i + 1))
			level.pause_menu.close()
	GameState.last_result = {"title": "Nivel 4: Parque San Pío", "granizados": 18, "total_granizados": 20,
		"hormigas": 3, "total_hormigas": 3, "time": 41.0, "lives": 4, "level_index": 3, "base_score": 1430,
		"bonus_complete": 1000, "bonus_time": 900, "bonus_no_deaths": 1500, "score": 4830, "stars": 3,
		"new_record": true}
	SceneTransition.change_scene("res://scenes/menus/victory.tscn")
	await SceneTransition.transition_finished
	await _wait(0.8)
	await _wait(2.6)
	_shot("08_victoria")
	SceneTransition.change_scene("res://scenes/menus/ending.tscn")
	await SceneTransition.transition_finished
	await _wait(0.8)
	_shot("09_final")
	print("Capturas en ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _shot(name: String) -> void:
	print("captura ", name)
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
