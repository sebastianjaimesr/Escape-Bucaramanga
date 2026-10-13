extends Node
## Pruebas automáticas de integración. Ejecutar:
##   godot --headless --path . res://tests/test_runner.tscn
## Devuelve código de salida 0 si todo pasa y 1 si algo falla.

var _failures: Array[String] = []
var _passed := 0
var _current := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# El runner no debe ser la escena actual: las transiciones la reemplazan.
	var dummy := Node.new()
	dummy.name = "DummyScene"
	get_tree().root.add_child.call_deferred(dummy)
	await get_tree().process_frame
	get_tree().current_scene = dummy
	# Evita que los diálogos de introducción pausen las pruebas.
	for i in GameState.level_count():
		var d := GameState.load_level_data(GameState.levels[i]["id"])
		GameState.intros_seen[d.get("intro", "")] = true
	await get_tree().process_frame
	_begin("test_data_files")
	await test_data_files()
	_end()
	_begin("test_all_levels_build")
	await test_all_levels_build()
	_end()
	_begin("test_movement_and_jump")
	await test_movement_and_jump()
	_end()
	_begin("test_collisions_floor")
	await test_collisions_floor()
	_end()
	_begin("test_collectible")
	await test_collectible()
	_end()
	_begin("test_damage_and_checkpoint_respawn")
	await test_damage_and_checkpoint_respawn()
	_end()
	_begin("test_pit_death")
	await test_pit_death()
	_end()
	_begin("test_chase_catches_player")
	await test_chase_catches_player()
	_end()
	_begin("test_mission_locks_exit")
	await test_mission_locks_exit()
	_end()
	_begin("test_friend_joins")
	await test_friend_joins()
	_end()
	_begin("test_save_and_load")
	await test_save_and_load()
	_end()
	_begin("test_scene_transition")
	await test_scene_transition()
	_end()
	_begin("test_performance")
	await test_performance()
	_end()
	print("")
	print("==== RESULTADO: %d pruebas OK, %d fallos ====" % [_passed, _failures.size()])
	for f in _failures:
		print("  FALLO: " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)


var _before := 0


func _begin(test_name: String) -> void:
	_current = test_name
	_before = _failures.size()


func _end() -> void:
	if _failures.size() == _before:
		_passed += 1
		print("[OK]    " + _current)
	else:
		print("[FALLO] " + _current)
	get_tree().paused = false


func check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append("%s: %s" % [_current, msg])


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func spawn_level(level_id: String) -> Level:
	GameState.current_level = GameState.level_index_of(level_id)
	GameState.friends = GameState.friends_before(GameState.current_level)
	GameState.lives = GameState.MAX_LIVES
	GameState.health = GameState.MAX_HEALTH
	GameState.level_bocadillos = 0
	GameState.level_pistas = 0
	GameState.has_checkpoint = false
	var scene: PackedScene = load("res://scenes/levels/%s.tscn" % level_id)
	var level: Level = scene.instantiate()
	add_child(level)
	return level


func free_level(level: Level) -> void:
	level.queue_free()
	await get_tree().process_frame
	get_tree().paused = false


# ---------------------------------------------------------------------------
func test_data_files() -> void:
	check(GameState.level_count() == 7, "Se esperaban 7 niveles, hay %d" % GameState.level_count())
	for info: Dictionary in GameState.levels:
		var d := GameState.load_level_data(info["id"])
		check(not d.is_empty(), "Datos vacíos: %s" % info["id"])
		check(ResourceLoader.exists(info["scene"]), "Falta escena %s" % info["scene"])
		for key in ["intro", "outro"]:
			var dlg: Variant = d.get(key)
			if dlg is String and dlg != "":
				check(not DialogueBox.get_dialogue(dlg).is_empty(), "Diálogo inexistente: %s" % dlg)
		var friend: Variant = d.get("friend")
		if friend is Dictionary:
			check(not DialogueBox.get_dialogue(friend["dialogue"]).is_empty(), "Diálogo de amigo inexistente")
			check(ResourceLoader.exists(GameState.character_sheet(friend["id"])), "Falta spritesheet de %s" % friend["id"])


func test_all_levels_build() -> void:
	for info: Dictionary in GameState.levels:
		var level := spawn_level(info["id"])
		await frames(2)
		check(level.player != null, "%s sin jugador" % info["id"])
		check(level.exit_node != null, "%s sin meta" % info["id"])
		check(level.get_node_or_null("Tiles") is TileMapLayer, "%s sin TileMapLayer" % info["id"])
		check(level.total_bocadillos > 0, "%s sin bocadillos" % info["id"])
		var d: Dictionary = level.data
		var f: Variant = d.get("friend")
		if f is Dictionary:
			check(level.friend_node != null, "%s debería tener un amigo" % info["id"])
		await free_level(level)


func test_movement_and_jump() -> void:
	var level := spawn_level("level_01")
	var p := level.player
	await frames(30)
	check(p.is_on_floor(), "El jugador debería estar en el suelo al iniciar")
	var x0 := p.global_position.x
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(p.global_position.x > x0 + 40.0, "No avanzó a la derecha (%.1f -> %.1f)" % [x0, p.global_position.x])
	check(p.facing == 1, "Debería mirar a la derecha")
	await frames(20)
	var y0 := p.global_position.y
	Input.action_press("jump")
	p.jump_buffer = Player.JUMP_BUFFER_TIME
	var min_y := y0
	for i in 40:
		await get_tree().physics_frame
		min_y = minf(min_y, p.global_position.y)
	Input.action_release("jump")
	check(y0 - min_y > 40.0, "Salto demasiado bajo: %.1f px" % (y0 - min_y))
	await frames(40)
	check(p.is_on_floor(), "Debería aterrizar tras el salto")
	check(absf(p.global_position.y - y0) < 2.0, "Aterrizó a otra altura (%.1f vs %.1f)" % [p.global_position.y, y0])
	# Correr es más rápido que caminar
	Input.action_press("move_right")
	Input.action_press("run")
	await frames(30)
	check(absf(p.velocity.x) > Player.WALK_SPEED + 10.0, "Correr no supera la velocidad de caminar")
	Input.action_release("move_right")
	Input.action_release("run")
	await free_level(level)


func test_collisions_floor() -> void:
	var level := spawn_level("level_01")
	var p := level.player
	await frames(60)
	var ground_y := p.global_position.y
	var r := fposmod(ground_y, 16.0)
	check(minf(r, 16.0 - r) < 0.6, "El jugador no descansa sobre un tile (%.2f)" % ground_y)
	await frames(30)
	check(absf(p.global_position.y - ground_y) < 0.5, "El jugador atraviesa el suelo")
	await free_level(level)


func test_collectible() -> void:
	var level := spawn_level("level_01")
	await frames(5)
	var target: Node2D = null
	for n in level.get_node("Entities").get_children():
		if n.get("kind") == "bocadillo":
			target = n
			break
	check(target != null, "No hay bocadillos")
	if target:
		level.player.global_position = target.global_position + Vector2(0, 10)
		await frames(4)
		check(GameState.level_bocadillos == 1, "No se contó el bocadillo (%d)" % GameState.level_bocadillos)
	await free_level(level)


func test_damage_and_checkpoint_respawn() -> void:
	var level := spawn_level("level_01")
	var p := level.player
	await frames(20)
	var cp = get_tree().get_nodes_in_group("checkpoints")[0]
	cp.activate(true)
	check(GameState.has_checkpoint, "El punto de control no se registró")
	var lives0 := GameState.lives
	for i in GameState.MAX_HEALTH:
		p.invulnerable_timer = 0.0
		p.take_damage(1, p.global_position + Vector2(10, 0))
		await frames(2)
	check(p.is_dead, "Debería morir al perder toda la salud")
	await frames(90)
	check(not p.is_dead, "No reapareció")
	check(GameState.lives == lives0 - 1, "No se descontó una vida")
	check(GameState.health == GameState.MAX_HEALTH, "La salud no se restauró")
	check(p.global_position.distance_to(cp.global_position) < 4.0, "No reapareció en el punto de control")
	await free_level(level)


func test_pit_death() -> void:
	var level := spawn_level("level_01")
	var p := level.player
	await frames(10)
	var lives0 := GameState.lives
	p.global_position.y = p.fall_limit_y + 10.0
	await frames(3)
	check(p.is_dead, "Caer al vacío debería matar al jugador")
	await frames(90)
	check(GameState.lives == lives0 - 1, "Caer al vacío no restó vida")
	check(p.global_position.distance_to(level.start_position) < 4.0, "No reapareció en el inicio")
	await free_level(level)


func test_chase_catches_player() -> void:
	var level := spawn_level("level_01")
	var p := level.player
	await frames(10)
	level._start_chase()
	check(level.chase.active, "La persecución no se activó")
	var lives0 := GameState.lives
	level.chase._x = p.global_position.x - 5.0
	await frames(3)
	check(p.is_dead, "La patrulla debería alcanzar al jugador")
	await frames(90)
	check(GameState.lives == lives0 - 1, "Ser alcanzado no restó vida")
	check(p.global_position.x - level.chase._x > 200.0, "La patrulla no retrocedió tras la captura")
	await free_level(level)


func test_mission_locks_exit() -> void:
	var level := spawn_level("level_02")
	await frames(5)
	check(not level.mission.can_finish(), "La meta no debería abrirse sin bocadillos")
	check(not level.exit_node.is_open, "La meta debería verse cerrada")
	level.exit_node.reached.emit(level.player)
	await frames(2)
	check(not level.finished, "No debería terminar el nivel con objetivos pendientes")
	for i in 18:
		GameState.add_bocadillo()
	await frames(2)
	check(level.mission.can_finish(), "Con 18 bocadillos la meta debería abrir")
	check(level.exit_node.is_open, "La meta no cambió a abierta")
	await free_level(level)


func test_friend_joins() -> void:
	var level := spawn_level("level_04")
	await frames(5)
	var friend := level.friend_node
	check(friend != null, "No hay amigo en el nivel 4")
	if friend == null:
		await free_level(level)
		return
	friend.interact(level.player)
	await frames(2)
	check(level.dialogue.active, "El diálogo del amigo no se abrió")
	# Avanza el diálogo hasta el final
	var guard := 0
	while level.dialogue.active and guard < 40:
		var ev := InputEventAction.new()
		ev.action = "ui_accept"
		ev.pressed = true
		level.dialogue._input(ev)
		level.dialogue._input(ev)
		await get_tree().process_frame
		guard += 1
	await frames(3)
	check(GameState.friends.has("gorra"), "Gorra no se unió al grupo")
	check(level.followers.size() == 1, "No apareció el seguidor")
	check(level.mission.friend_found, "La misión del amigo no se marcó")
	await frames(2)
	check(level._chase_timer > 0.0 or level.chase.active, "La persecución del parque no se programó")
	await free_level(level)


func test_save_and_load() -> void:
	var backup := ""
	if FileAccess.file_exists(SaveSystem.SAVE_PATH):
		backup = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)
	GameState.unlocked_level = 3
	GameState.current_level = 2
	GameState.best_bocadillos["level_01"] = 21
	check(SaveSystem.save_game(), "No se pudo guardar")
	GameState.unlocked_level = 0
	GameState.current_level = 0
	GameState.best_bocadillos.clear()
	check(SaveSystem.load_game(), "No se pudo cargar")
	check(GameState.unlocked_level == 3, "unlocked_level no se restauró")
	check(GameState.current_level == 2, "current_level no se restauró")
	check(int(GameState.best_bocadillos.get("level_01", 0)) == 21, "Récord no se restauró")
	if backup != "":
		var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
		SaveSystem.load_game()
	else:
		SaveSystem.delete_save()
		GameState.unlocked_level = 0
		GameState.current_level = 0
		GameState.best_bocadillos.clear()


func test_scene_transition() -> void:
	SceneTransition.change_scene("res://scenes/levels/level_03.tscn", "Prueba")
	await SceneTransition.transition_finished
	var scene := get_tree().current_scene
	check(scene is Level and (scene as Level).level_id == "level_03", "La transición no cargó el nivel 3")
	SceneTransition.change_scene("res://scenes/menus/main_menu.tscn")
	await SceneTransition.transition_finished
	check(get_tree().current_scene != null and get_tree().current_scene.name == "MainMenu", "No volvió al menú")


func test_performance() -> void:
	var level := spawn_level("level_06")
	level._start_chase()
	await frames(10)
	var t0 := Time.get_ticks_usec()
	Input.action_press("move_right")
	await frames(120)
	Input.action_release("move_right")
	var avg_ms := (Time.get_ticks_usec() - t0) / 1000.0 / 120.0
	print("        promedio por cuadro de física (headless): %.2f ms" % avg_ms)
	check(avg_ms < 40.0, "Rendimiento insuficiente: %.2f ms por cuadro" % avg_ms)
	await free_level(level)
