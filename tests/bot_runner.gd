extends Node
## Bot de recorrido: intenta cruzar cada nivel corriendo y saltando solo, para
## comprobar que la meta es alcanzable con la física real del jugador.
##   godot --headless --path . res://tests/bot_runner.tscn --fixed-fps 60
## (La persecución y el daño se desactivan; las misiones se marcan como cumplidas.)

const MAX_SECONDS := 150.0

var _results: Array[String] = []
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in GameState.level_count():
		var d := GameState.load_level_data(GameState.levels[i]["id"])
		GameState.intros_seen[d.get("intro", "")] = true
	await get_tree().process_frame
	var only := OS.get_environment("BOT_LEVEL")
	for i in GameState.level_count():
		var id: String = GameState.levels[i]["id"]
		if only != "" and only != id:
			continue
		await _run_level(id)
	print("")
	for r in _results:
		print(r)
	get_tree().quit(0 if _failed == 0 else 1)


func _run_level(level_id: String) -> void:
	GameState.current_level = GameState.level_index_of(level_id)
	GameState.friends = GameState.friends_before(GameState.current_level)
	GameState.lives = 99
	GameState.has_checkpoint = false
	var level: Level = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	await get_tree().physics_frame
	level._chase_timer = -1.0
	level.mission.friend_found = true
	GameState.level_granizados = 999
	GameState.level_pistas = 99
	level.mission.refresh()
	var p := level.player
	var b := level.builder
	var t := 0.0
	var deaths := 0
	var max_x := 0.0
	var stuck_time := 0.0
	var last_x := p.global_position.x
	var jump_hold := 0
	var was_dead := false
	var exit_x: float = level.exit_node.global_position.x
	Input.action_press("move_right")
	Input.action_press("run")
	while t < MAX_SECONDS and not level.finished:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if p.is_dead and not was_dead:
			deaths += 1
		was_dead = p.is_dead
		p.invulnerable_timer = maxf(p.invulnerable_timer, 0.2)
		max_x = maxf(max_x, p.global_position.x)
		if OS.get_environment("BOT_DEBUG") != "" and int(t * 60) % 3 == 0 and t < float(OS.get_environment("BOT_DEBUG")):
			print("%.2f x=%.1f y=%.1f vx=%.0f vy=%.0f floor=%s state=%s dead=%s L=%s R=%s" % [t, p.global_position.x, p.global_position.y, p.velocity.x, p.velocity.y, p.is_on_floor(), p.state_machine.current_name, p.is_dead, Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right")])
		# Detecta atascos (muro o caja): intenta saltar.
		if absf(p.global_position.x - last_x) < 0.3:
			stuck_time += 1.0 / 60.0
		else:
			stuck_time = 0.0
		last_x = p.global_position.x
		if p.is_on_floor() and (_should_jump(b, p) or stuck_time > 0.1):
			p.jump_buffer = Player.JUMP_BUFFER_TIME
			Input.action_press("jump")
			jump_hold = 26
		if jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0:
				Input.action_release("jump")
		# Como un jugador humano: en el aire, frena para aterrizar sobre una
		# plataforma si delante hay vacío.
		var braking := not p.is_on_floor() and p.velocity.y > -80.0 and _ground_below(b, p.global_position.x, p.global_position.y, 4) \
			and not _ground_below(b, p.global_position.x + 20.0, p.global_position.y, 6)
		# Si quedó a la derecha de la meta (saltó por encima), retrocede.
		if p.global_position.x > exit_x + 20.0:
			Input.action_release("move_right")
			Input.action_press("move_left")
		elif braking:
			Input.action_release("move_right")
			Input.action_press("move_left")
		elif p.global_position.x < exit_x - 4.0:
			Input.action_release("move_left")
			Input.action_press("move_right")
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("run")
	Input.action_release("jump")
	var ok := level.finished
	if not ok:
		_failed += 1
	_results.append("%s %s: %.1f s, caídas/muertes: %d, x máx: %.0f / meta %.0f" % [
		"[OK]   " if ok else "[FALLO]", level_id, t, deaths, max_x, exit_x])
	get_tree().paused = false
	level.queue_free()
	await get_tree().process_frame


## Salta si hay un muro, un hueco o un peligro justo delante (lo más tarde posible).
func _should_jump(b: LevelBuilder, p: Player) -> bool:
	var fx := p.global_position.x + 6.0
	var cy := int((p.global_position.y - 1.0) / 16.0)
	var near := int((fx + 6.0) / 16.0)
	if b.is_solid(near, cy) or b.is_solid(near, cy - 1):
		return true
	for x in [near, near + 1]:
		if b.cell(x, cy) in ["^", "n", "g", "c", "|"]:
			return true
	var ground_ahead := false
	for dy in range(1, 3):
		if b.is_solid(near, cy + dy) or b.cell(near, cy + dy) == "=":
			ground_ahead = true
	return not ground_ahead

func _ground_below(b: LevelBuilder, x: float, y: float, rows: int) -> bool:
	var cx := int(x / 16.0)
	var cy := int((y - 1.0) / 16.0)
	for dy in range(0, rows + 1):
		var ch := b.cell(cx, cy + dy)
		if b.is_solid(cx, cy + dy) or ch == "=" or ch == "M" or ch == "V":
			return true
	return false