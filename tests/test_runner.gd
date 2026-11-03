extends Node
## Pruebas de integración del prototipo 3D, ejecutadas dentro del motor.
##
##   godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
##
## Cada prueba crea una manzana de prueba nueva, simula la entrada del jugador
## con Input.action_press y avanza cuadros de física reales. Al final imprime
## el resumen y sale con código 0 (todo bien) o 1 (algún fallo).
## Usa un archivo de configuración aparte para no tocar el del jugador.

const WORLD_SCENE := "res://scenes/world/prototype/prototype_world.tscn"
const TEST_SETTINGS := "user://test_settings.cfg"

var _passed := 0
var _failed: Array[String] = []
var _current := ""
var _current_ok := true
var world: PrototypeWorld
var player: PlayerController


func _ready() -> void:
	Settings.config_path = TEST_SETTINGS
	_remove_test_settings()
	Settings.load_settings()
	InputConfig.apply_all()
	await get_tree().process_frame
	for test: String in [
		"test_project_configuration",
		"test_input_actions_exist",
		"test_rebind_and_persist",
		"test_rebind_swaps_conflicting_key",
		"test_settings_roundtrip_and_corrupt_file",
		"test_world_builds",
		"test_player_lands_on_ground",
		"test_walk_relative_to_camera",
		"test_run_is_faster_and_uses_stamina",
		"test_stamina_exhaustion_forces_walk",
		"test_jump_height",
		"test_short_jump_is_lower",
		"test_wall_blocks_player",
		"test_step_up_curb",
		"test_climb_stairs",
		"test_walk_up_ramp",
		"test_steep_slope_not_climbable",
		"test_box_heights",
		"test_crouch_tunnel",
		"test_camera_does_not_clip_wall",
		"test_camera_rotation_moves_player_direction",
		"test_quality_profiles_apply",
		"test_scene_loader_missing_scene",
		"test_fall_reset",
	]:
		await _run(test)
	_remove_test_settings()
	print("")
	if _failed.is_empty():
		print("==== RESULTADO: %d pruebas OK, 0 fallos ====" % _passed)
	else:
		print("==== RESULTADO: %d OK, %d FALLOS: %s ====" % [_passed, _failed.size(), ", ".join(_failed)])
	get_tree().quit(0 if _failed.is_empty() else 1)


func _run(test: String) -> void:
	_current = test
	_current_ok = true
	await call(test)
	_release_all()
	if world != null:
		world.queue_free()
		world = null
		player = null
		await get_tree().process_frame
	get_tree().paused = false
	if _current_ok:
		_passed += 1
		print("[OK]    ", test)
	else:
		_failed.append(test)
		print("[FALLO] ", test)


# ---------------------------------------------------------------------------
# Ayudas
# ---------------------------------------------------------------------------
func check(cond: bool, message: String) -> void:
	if not cond:
		_current_ok = false
		print("        ✗ ", message)


func _remove_test_settings() -> void:
	for suffix: String in ["", ".tmp", ".bad"]:
		if FileAccess.file_exists(TEST_SETTINGS + suffix):
			DirAccess.remove_absolute(TEST_SETTINGS + suffix)


func spawn_world() -> void:
	world = (load(WORLD_SCENE) as PackedScene).instantiate()
	add_child(world)
	player = world.player
	await frames(30)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(ceil(s * Engine.physics_ticks_per_second)))


func hold(actions: Array, s: float) -> void:
	for a: String in actions:
		Input.action_press(a)
	await seconds(s)
	for a: String in actions:
		Input.action_release(a)


func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)


func _release_all() -> void:
	for a: String in InputConfig.ACTIONS:
		Input.action_release(a)


## Coloca al jugador mirando en la dirección yaw (la cámara también).
func place(pos: Vector3, yaw: float) -> void:
	player.teleport(pos + Vector3.UP * 0.05, yaw)
	world.camera_rig.yaw = yaw
	world.camera_rig.snap()
	await frames(20)


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


# ---------------------------------------------------------------------------
# Configuración y controles
# ---------------------------------------------------------------------------
func test_project_configuration() -> void:
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "PC debe usar Forward+")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.web") == "gl_compatibility", "Web debe usar Compatibilidad")
	check(ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics", "Física 3D debe ser Jolt")
	for autoload: String in ["EventBus", "Settings", "InputConfig", "SceneLoader"]:
		check(get_tree().root.has_node(autoload), "Falta el autoload %s" % autoload)
	check(ResourceLoader.exists(MainMenu.PROTOTYPE_SCENE), "Existe la escena del prototipo")


func test_input_actions_exist() -> void:
	var expected := {
		"move_forward": KEY_W, "move_left": KEY_A, "move_back": KEY_S, "move_right": KEY_D,
		"run": KEY_SHIFT, "jump": KEY_SPACE, "crouch": KEY_C, "interact": KEY_E,
		"vehicle": KEY_F, "inventory": KEY_TAB, "map": KEY_M, "pause": KEY_ESCAPE,
	}
	for action: String in expected:
		check(InputMap.has_action(action), "Existe la acción %s" % action)
		var found := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == expected[action]:
				found = true
		check(found, "%s usa la tecla del encargo" % action)


func test_rebind_and_persist() -> void:
	InputConfig.rebind("jump", KEY_K)
	check(InputConfig.primary_key("jump") == KEY_K, "Salto reasignado a K")
	var has_k := false
	for ev in InputMap.action_get_events("jump"):
		has_k = has_k or (ev is InputEventKey and ev.physical_keycode == KEY_K)
	check(has_k, "InputMap actualizado con K")
	Settings.load_settings()   # Simula reiniciar el juego.
	InputConfig.apply_all()
	check(InputConfig.primary_key("jump") == KEY_K, "La reasignación sobrevive a reiniciar")
	InputConfig.reset_defaults()
	check(InputConfig.primary_key("jump") == KEY_SPACE, "Restaurar vuelve a Espacio")


func test_rebind_swaps_conflicting_key() -> void:
	InputConfig.rebind("jump", KEY_C)  # C era agacharse.
	check(InputConfig.primary_key("jump") == KEY_C, "Salto en C")
	check(InputConfig.primary_key("crouch") == KEY_SPACE, "Agacharse recibe la tecla anterior del salto")
	InputConfig.rebind("crouch", KEY_ESCAPE)
	check(InputConfig.primary_key("crouch") == KEY_SPACE, "Esc está reservada para la pausa")
	InputConfig.reset_defaults()


func test_settings_roundtrip_and_corrupt_file() -> void:
	Settings.set_value("camera", "mouse_sensitivity", 0.4)
	Settings.set_value("graphics", "profile", "alto")
	Settings.load_settings()
	check(is_equal_approx(float(Settings.get_value("camera", "mouse_sensitivity")), 0.4), "Sensibilidad guardada")
	check(Settings.quality_profile() == "alto", "Perfil guardado")
	var f := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	f.store_string("[camera\nesto no es un archivo válido = = =")
	f.close()
	var ok := Settings.load_settings()
	check(not ok, "Detecta el archivo dañado")
	check(Settings.last_error != "", "Informa el error")
	check(is_equal_approx(float(Settings.get_value("camera", "mouse_sensitivity")), 0.25), "Vuelve a los valores por defecto")
	check(FileAccess.file_exists(TEST_SETTINGS + ".bad"), "Conserva el archivo dañado como .bad")
	Settings.reset_to_defaults()


# ---------------------------------------------------------------------------
# Mundo y movimiento
# ---------------------------------------------------------------------------
func test_world_builds() -> void:
	await spawn_world()
	check(world.points.has("spawn"), "Hay punto de aparición")
	check(int(world.points.get("window_count", 0)) > 100, "Ventanas con MultiMesh (%s)" % world.points.get("window_count"))
	check(world.sun.shadow_enabled, "El sol proyecta sombras")
	check(world.get_viewport().get_camera_3d() == world.camera_rig.camera, "La cámara del jugador está activa")


func test_player_lands_on_ground() -> void:
	await spawn_world()
	await seconds(1.0)
	check(player.is_on_floor(), "Está en el suelo")
	check(absf(player.global_position.y - PrototypeBlockBuilder.CURB_HEIGHT) < 0.05,
			"A la altura de la acera (y=%.3f)" % player.global_position.y)
	check(player.state_machine.current_name == &"Idle", "Estado Idle (%s)" % player.state_machine.current_name)


func test_walk_relative_to_camera() -> void:
	await spawn_world()
	await place(Vector3(-40, 0.15, 12), 0.0)
	var start := player.global_position
	await hold(["move_forward"], 1.0)
	var moved := flat(player.global_position - start)
	check(moved.z < -2.0, "Avanza hacia el norte (-Z) con la cámara mirando al norte (dz=%.2f)" % moved.z)
	check(absf(moved.x) < 0.1, "No se desvía (dx=%.2f)" % moved.x)
	check(moved.length() < PlayerController.WALK_SPEED * 1.05, "Velocidad de caminar (%.2f m/s)" % moved.length())


func test_run_is_faster_and_uses_stamina() -> void:
	await spawn_world()
	await place(Vector3(-40, 0.15, 12), PI)  # Mirando al sur (+Z).
	var start := player.global_position
	Input.action_press("run")
	await hold(["move_forward"], 1.0)
	Input.action_release("run")
	var d := flat(player.global_position - start).length()
	check(d > PlayerController.WALK_SPEED * 1.5, "Corre más rápido que caminando (%.2f m en 1 s)" % d)
	check(player.stamina < PlayerController.MAX_STAMINA - 10.0, "Gasta resistencia (%.1f)" % player.stamina)
	var after := player.stamina
	await seconds(2.0)
	check(player.stamina > after, "La resistencia se recupera al parar")


func test_stamina_exhaustion_forces_walk() -> void:
	await spawn_world()
	await place(Vector3(-46, 0.15, 12), PI * 0.5)  # Cámara al oeste; se corre hacia el este.
	player.stamina = 5.0
	Input.action_press("run")
	Input.action_press("move_back")  # Hacia el este: hay espacio libre.
	await seconds(1.0)
	check(player.exhausted, "Queda agotado")
	check(player.state_machine.current_name == &"Walk", "Pasa a caminar (%s)" % player.state_machine.current_name)
	check(player.horizontal_speed() <= PlayerController.WALK_SPEED + 0.05, "Va a velocidad de caminar")
	Input.action_release("run")
	Input.action_release("move_back")


func test_jump_height() -> void:
	await spawn_world()
	await place(Vector3(-40, 0.15, 12), 0.0)
	var base := player.global_position.y
	var peak := base
	Input.action_press("jump")
	for i in 90:
		await frames(1)
		peak = maxf(peak, player.global_position.y)
	Input.action_release("jump")
	var h := peak - base
	check(h > 1.0 and h < 1.3, "Altura de salto ≈ 1,17 m (%.2f)" % h)
	check(player.is_on_floor(), "Aterriza")


func test_short_jump_is_lower() -> void:
	await spawn_world()
	await place(Vector3(-40, 0.15, 12), 0.0)
	var base := player.global_position.y
	await tap("jump")
	var peak := base
	for i in 90:
		await frames(1)
		peak = maxf(peak, player.global_position.y)
	check(peak - base < 0.9, "Salto corto más bajo (%.2f)" % (peak - base))


func test_wall_blocks_player() -> void:
	await spawn_world()
	var key := _first_building("no_x_")
	var info: Dictionary = world.points[key]
	var face: Vector3 = info["face"]
	# Fachada que mira al sur (+Z): el jugador camina al norte contra ella.
	await place(face + Vector3(0, 0, 2.0), 0.0)
	await hold(["move_forward"], 2.0)
	check(player.global_position.z > face.z, "No atraviesa la fachada (z=%.2f, fachada=%.2f)" % [player.global_position.z, face.z])


func test_step_up_curb() -> void:
	await spawn_world()
	await place(Vector3(-2.0, 0.0, 12.0), PI * 0.5)  # En la calzada, mirando al oeste hacia la acera.
	check(player.global_position.y < 0.08, "Empieza en la calzada")
	await hold(["move_forward"], 1.5)
	check(player.global_position.x < -5.0, "Avanzó sobre la acera (x=%.2f)" % player.global_position.x)
	check(absf(player.global_position.y - PrototypeBlockBuilder.CURB_HEIGHT) < 0.05, "Subió el bordillo (y=%.3f)" % player.global_position.y)


func test_climb_stairs() -> void:
	await spawn_world()
	await place(world.points["stairs_bottom"], PI)  # Hacia el sur (+Z), escaleras arriba.
	await hold(["move_forward"], 3.0)
	var top: float = world.points["platform_top_y"]
	check(absf(player.global_position.y - top) < 0.06, "Llega arriba (y=%.2f, plataforma=%.2f)" % [player.global_position.y, top])


func test_walk_up_ramp() -> void:
	await spawn_world()
	await place(world.points["ramp_bottom"], PI * 0.5)  # Hacia el oeste, rampa arriba.
	await hold(["move_forward"], 4.0)
	var top: float = world.points["platform_top_y"]
	check(absf(player.global_position.y - top) < 0.06, "Sube la rampa (y=%.2f)" % player.global_position.y)


func test_steep_slope_not_climbable() -> void:
	await spawn_world()
	await place(world.points["steep_bottom"], PI * 0.5)  # Hacia el oeste, contra la pendiente.
	await hold(["move_forward"], 3.0)
	check(player.global_position.y < 0.9, "No sube la pendiente de 50° (y=%.2f)" % player.global_position.y)


func test_box_heights() -> void:
	await spawn_world()
	var g := PrototypeBlockBuilder.CURB_HEIGHT
	# Caja de 0,3 m: se sube caminando.
	var low: Vector3 = world.points["box_3"]
	await place(low + Vector3(0, 0, -2.0), PI)
	var top := await _max_floor_height(["move_forward"], [], 1.5)
	check(top > g + 0.25, "Sube la caja de 0,3 m sin saltar (y=%.2f)" % top)
	# Caja de 0,6 m: caminando no; saltando sí.
	var mid: Vector3 = world.points["box_6"]
	await place(mid + Vector3(0, 0, -2.0), PI)
	top = await _max_floor_height(["move_forward"], [], 1.5)
	check(top < g + 0.1, "No sube 0,6 m caminando (y=%.2f)" % top)
	await place(mid + Vector3(0, 0, -2.0), PI)
	Input.action_press("move_forward")
	await seconds(0.2)
	top = await _max_floor_height(["move_forward"], ["jump"], 1.5)
	check(top > g + 0.55, "Sube 0,6 m saltando (y=%.2f)" % top)


## Mantiene las acciones y devuelve la mayor altura a la que estuvo apoyado en el suelo.
## Las acciones de "once" se pulsan al empezar. Suelta todo al aterrizar tras un salto.
func _max_floor_height(hold_actions: Array, once: Array, s: float) -> float:
	for a: String in hold_actions + once:
		Input.action_press(a)
	var best := -INF
	var was_air := false
	for i in int(s * Engine.physics_ticks_per_second):
		await frames(1)
		if not player.is_on_floor():
			was_air = true
		elif was_air:
			for a: String in hold_actions + once:
				Input.action_release(a)
		if player.is_on_floor():
			best = maxf(best, player.global_position.y)
	_release_all()
	return best


func test_crouch_tunnel() -> void:
	await spawn_world()
	var entry: Vector3 = world.points["tunnel_entry"]
	var exit_x: float = world.points["tunnel_exit_x"]
	await place(entry, PI * 0.5)  # Hacia el oeste, al túnel.
	await hold(["move_forward"], 2.5)
	check(player.global_position.x > -24.0, "De pie no entra al túnel (x=%.2f)" % player.global_position.x)
	await place(entry, PI * 0.5)
	await tap("crouch")
	await frames(5)
	check(player.crouching, "Se agacha")
	Input.action_press("move_forward")
	await seconds(2.5)
	check(player.global_position.x < -24.5, "Agachado entra al túnel (x=%.2f)" % player.global_position.x)
	Input.action_release("move_forward")
	await tap("crouch")
	await frames(5)
	check(player.crouching, "No puede levantarse bajo el techo")
	Input.action_press("move_forward")
	await seconds(5.0)
	Input.action_release("move_forward")
	check(player.global_position.x < exit_x + 0.5, "Sale del túnel (x=%.2f)" % player.global_position.x)
	await tap("crouch")
	await frames(5)
	check(not player.crouching, "Fuera del túnel se levanta")


func test_camera_does_not_clip_wall() -> void:
	await spawn_world()
	var info: Dictionary = world.points[_first_building("no_x_")]
	var face: Vector3 = info["face"]
	# De espaldas a la fachada a 1 m: la cámara quedaría dentro del edificio.
	await place(face + Vector3(0, 0, 1.0), PI)
	world.camera_rig.pitch = 0.0
	await frames(30)
	var d := world.camera_rig.current_distance()
	check(d < 1.3, "El brazo de la cámara se acorta ante la pared (%.2f m)" % d)
	var cam_z := world.camera_rig.camera.global_position.z
	check(cam_z > face.z, "La cámara queda fuera del edificio (z=%.2f, fachada=%.2f)" % [cam_z, face.z])
	world.camera_rig.yaw = 0.0  # Mirando a la pared: detrás hay calle libre.
	await frames(30)
	check(world.camera_rig.current_distance() > ThirdPersonCamera.ARM_LENGTH - 0.3, "Con espacio libre usa la distancia completa")


func test_camera_rotation_moves_player_direction() -> void:
	await spawn_world()
	await place(Vector3(-40, 0.15, 12), 0.0)
	world.camera_rig.rotate_view(-PI * 0.5, 0.0)  # Girar la cámara 90° a la derecha (mirar al este).
	await frames(3)
	var start := player.global_position
	await hold(["move_forward"], 1.0)
	var moved := flat(player.global_position - start)
	check(moved.x > 2.0 and absf(moved.z) < 0.2, "Avanzar sigue a la cámara (dx=%.2f, dz=%.2f)" % [moved.x, moved.z])
	check(absf(wrapf(player.facing_yaw - world.camera_rig.yaw, -PI, PI)) < 0.2, "El cuerpo gira hacia donde avanza")


func test_quality_profiles_apply() -> void:
	await spawn_world()
	for id: String in QualityProfiles.ORDER:
		Settings.set_value("graphics", "profile", id)
		await frames(2)
		var p: Dictionary = QualityProfiles.PROFILES[id]
		check(is_equal_approx(world.get_viewport().scaling_3d_scale, p["render_scale"]), "%s: escala de render" % id)
		check(is_equal_approx(world.camera_rig.camera.far, p["draw_distance"]), "%s: distancia de dibujo" % id)
		check(is_equal_approx(world.sun.directional_shadow_max_distance, p["shadow_distance"]), "%s: distancia de sombras" % id)
		if not QualityProfiles.is_forward_plus():
			check(not world.environment.ssao_enabled, "%s: sin SSAO fuera de Forward+" % id)
	Settings.reset_to_defaults()


func test_scene_loader_missing_scene() -> void:
	var failures: Array = []
	var cb := func(path: String, message: String) -> void: failures.append([path, message])
	SceneLoader.load_failed.connect(cb)
	SceneLoader.change_scene("res://no_existe.tscn")
	await frames(3)
	SceneLoader.load_failed.disconnect(cb)
	check(failures.size() == 1, "Informa la escena inexistente")
	check(not SceneLoader.busy, "El cargador queda libre para otra carga")
	SceneLoader._screen.hide_screen()


func test_fall_reset() -> void:
	await spawn_world()
	player.teleport(Vector3(-40, -40, 12))
	await frames(5)
	check(player.global_position.distance_to(world.points["spawn"]) < 1.0, "Si cae fuera del mapa vuelve al inicio")


func _first_building(prefix: String) -> String:
	for key: String in world.points:
		if key.begins_with("building_" + prefix):
			return key
	push_error("No hay edificio %s" % prefix)
	return ""
