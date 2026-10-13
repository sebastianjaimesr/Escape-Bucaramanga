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
	await _wait(1.0)
	_shot("00_menu")
	for i in GameState.level_count():
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
		_shot("%02d_%s" % [i + 1, GameState.levels[i]["id"]])
	GameState.last_result = {"title": "Nivel 1: Calles nocturnas", "bocadillos": 21, "total_bocadillos": 30, "time": 95.0, "lives": 4}
	SceneTransition.change_scene("res://scenes/menus/victory.tscn")
	await SceneTransition.transition_finished
	await _wait(0.8)
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
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
