extends Node
## Estado global de la partida: vidas, salud, progreso, amigos y controles.
## Es un autoload porque varias escenas (niveles, menús, HUD) lo comparten.

signal lives_changed(lives: int)
signal health_changed(health: int, max_health: int)
signal bocadillos_changed(count: int)
signal pistas_changed(count: int)
signal friends_changed(friends: Array)

const MAX_LIVES := 5
const MAX_HEALTH := 3
const LEVELS_INDEX := "res://data/levels/levels.json"
const CHARACTERS_FILE := "res://data/dialogue/characters.json"

var levels: Array = []
var characters: Dictionary = {}
var current_level := 0
var unlocked_level := 0
var lives := MAX_LIVES
var health := MAX_HEALTH
var level_bocadillos := 0
var level_pistas := 0
var friends: Array = []
var checkpoint_position := Vector2.ZERO
var has_checkpoint := false
var intros_seen: Dictionary = {}
var best_bocadillos: Dictionary = {}
var last_result: Dictionary = {}
var settings := {"music": 0.7, "sfx": 0.85, "rain": true, "fullscreen": false}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	levels = load_json(LEVELS_INDEX).get("levels", [])
	characters = load_json(CHARACTERS_FILE)


# ---------------------------------------------------------------------------
# Datos
# ---------------------------------------------------------------------------
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("No existe el archivo de datos: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido: %s" % path)
	return {}


func level_count() -> int:
	return levels.size()


func level_index_of(level_id: String) -> int:
	for i in levels.size():
		if levels[i]["id"] == level_id:
			return i
	return -1


func load_level_data(level_id: String) -> Dictionary:
	return load_json("res://data/levels/%s.json" % level_id)


func character_name(id: String) -> String:
	return characters.get(id, {}).get("name", id)


func character_sheet(id: String) -> String:
	return characters.get(id, {}).get("sheet", "res://assets/characters/protagonist.png")


func character_portrait(id: String) -> String:
	return characters.get(id, {}).get("portrait", "")


# ---------------------------------------------------------------------------
# Flujo de partida
# ---------------------------------------------------------------------------
func new_game() -> void:
	lives = MAX_LIVES
	health = MAX_HEALTH
	intros_seen.clear()
	start_level(0)


func continue_game() -> void:
	start_level(clampi(current_level, 0, unlocked_level))


func start_level(index: int) -> void:
	index = clampi(index, 0, levels.size() - 1)
	current_level = index
	if lives <= 0:
		lives = MAX_LIVES
	health = MAX_HEALTH
	level_bocadillos = 0
	level_pistas = 0
	has_checkpoint = false
	friends = friends_before(index)
	SaveSystem.save_game()
	var info: Dictionary = levels[index]
	SceneTransition.change_scene(info["scene"], info["title"])


func restart_level() -> void:
	start_level(current_level)


## Amigos ya rescatados al comenzar el nivel indicado (progresión determinista).
func friends_before(index: int) -> Array:
	var result: Array = []
	for i in index:
		var data := load_level_data(levels[i]["id"])
		var friend: Variant = data.get("friend")
		if friend is Dictionary:
			result.append(friend["id"])
	return result


func complete_level(stats: Dictionary) -> void:
	var level_id: String = levels[current_level]["id"]
	best_bocadillos[level_id] = maxi(int(best_bocadillos.get(level_id, 0)), level_bocadillos)
	last_result = stats
	last_result["level_index"] = current_level
	if current_level + 1 < levels.size():
		unlocked_level = maxi(unlocked_level, current_level + 1)
		current_level += 1
	SaveSystem.save_game()


func is_last_level() -> bool:
	return current_level >= levels.size() - 1


# ---------------------------------------------------------------------------
# Vidas, salud y coleccionables
# ---------------------------------------------------------------------------
func damage(amount: int) -> int:
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	return health


func heal(amount: int) -> void:
	health = mini(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)


func lose_life() -> int:
	lives = maxi(0, lives - 1)
	health = MAX_HEALTH
	lives_changed.emit(lives)
	health_changed.emit(health, MAX_HEALTH)
	return lives


func add_bocadillo(amount: int = 1) -> void:
	level_bocadillos += amount
	bocadillos_changed.emit(level_bocadillos)
	# Cada 25 bocadillos se gana una vida extra.
	if level_bocadillos % 25 == 0 and lives < MAX_LIVES:
		lives += 1
		lives_changed.emit(lives)


func add_pista() -> void:
	level_pistas += 1
	pistas_changed.emit(level_pistas)


func add_friend(id: String) -> void:
	if not friends.has(id):
		friends.append(id)
		friends_changed.emit(friends)


func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true


# ---------------------------------------------------------------------------
# Controles (teclado, mando y táctil mediante acciones)
# ---------------------------------------------------------------------------
func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP, KEY_Z],
		"run": [KEY_SHIFT, KEY_X],
		"interact": [KEY_E, KEY_S, KEY_DOWN],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	var buttons := {
		"move_left": [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"jump": [JOY_BUTTON_A],
		"run": [JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER],
		"interact": [JOY_BUTTON_Y, JOY_BUTTON_B],
		"pause": [JOY_BUTTON_START],
	}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for key: int in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for button: int in buttons[action]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = button
			InputMap.action_add_event(action, jb)
	for pair: Array in [["move_left", -1.0], ["move_right", 1.0]]:
		var motion := InputEventJoypadMotion.new()
		motion.axis = JOY_AXIS_LEFT_X
		motion.axis_value = pair[1]
		InputMap.action_add_event(pair[0], motion)
