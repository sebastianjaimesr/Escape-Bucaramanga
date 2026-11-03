class_name Level
extends Node2D
## Nivel jugable. Construye el mapa desde data/levels/<level_id>.json y coordina
## jugador, persecución, misiones, amigos, diálogos, HUD y reapariciones.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const CHASE_SCENE := "res://scenes/enemies/chase_patrol.tscn"
const HUD_SCENE := "res://scenes/ui/hud.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_box.tscn"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const TOUCH_SCENE := "res://scenes/ui/touch_controls.tscn"

const NIGHT_COLORS := {
	"calles": Color(0.6, 0.6, 0.85),
	"comercial": Color(0.68, 0.62, 0.86),
	"cai": Color(0.62, 0.66, 0.84),
	"parque": Color(0.58, 0.66, 0.82),
	"barrio": Color(0.68, 0.62, 0.8),
	"viaducto": Color(0.6, 0.6, 0.86),
	"final": Color(0.7, 0.65, 0.85),
}

@export var level_id := "level_01"

var data: Dictionary = {}
var builder: LevelBuilder
var player: Player
var camera: CameraController
var chase: ChasePatrol
var mission: MissionSystem
var hud: HUD
var dialogue: DialogueBox
var pause_menu: PauseMenu
var trail: TrailRecorder
var exit_node = null  # LevelExit (scripts/obstacles/level_exit.gd)
var friend_node: FriendNPC
var followers: Array[FriendFollower] = []
var start_position := Vector2.ZERO
var total_granizados := 0
var total_pistas := 0
var finished := false
var elapsed := 0.0
var _chase_timer := -1.0


func _ready() -> void:
	data = GameState.load_level_data(level_id)
	if data.is_empty():
		push_error("No se encontraron datos para %s" % level_id)
		return
	var level_index := GameState.level_index_of(level_id)
	if level_index >= 0 and GameState.current_level != level_index:
		# Escena abierta directamente (editor o pruebas): sincroniza el estado.
		GameState.current_level = level_index
		GameState.friends = GameState.friends_before(level_index)
	builder = LevelBuilder.new(data)
	var theme: String = data.get("theme", "calles")
	ParallaxBuilder.build(self, theme)
	var night := CanvasModulate.new()
	night.color = NIGHT_COLORS.get(theme, Color(0.65, 0.65, 0.85))
	add_child(night)
	add_child(builder.build_tiles())
	var props := Node2D.new()
	props.name = "Props"
	add_child(props)
	var entities := Node2D.new()
	entities.name = "Entities"
	add_child(entities)
	var info := builder.spawn_entities(self, props, entities)
	start_position = info["player_start"]
	total_granizados = info["total_granizados"]
	total_pistas = info["total_pistas"]
	exit_node = info["exit"]
	friend_node = info["friend"]

	player = load(PLAYER_SCENE).instantiate()
	player.position = start_position
	player.fall_limit_y = builder.pixel_size().y + 48.0
	add_child(player)
	player.died.connect(_on_player_died)

	trail = TrailRecorder.new()
	trail.name = "Trail"
	trail.target = player
	add_child(trail)
	trail.reset(start_position)
	for id: String in GameState.friends:
		_add_follower(id)

	camera = CameraController.new()
	camera.name = "Camera"
	add_child(camera)
	camera.target = player
	camera.setup(builder.pixel_size())
	camera.make_current()
	camera.snap_to_target()

	chase = load(CHASE_SCENE).instantiate()
	chase.player = player
	add_child(chase)
	chase.configure(data.get("chase", {}))

	hud = load(HUD_SCENE).instantiate()
	add_child(hud)
	mission = MissionSystem.new()
	mission.name = "Missions"
	add_child(mission)
	mission.updated.connect(_on_mission_updated)
	mission.objective_completed.connect(_on_objective_completed)
	mission.setup(data.get("mission", []))
	hud.set_level_title(data.get("title", ""))
	hud.show_pistas(total_pistas > 0)
	chase.distance_changed.connect(hud.set_chase_distance)

	dialogue = load(DIALOGUE_SCENE).instantiate()
	add_child(dialogue)
	pause_menu = load(PAUSE_SCENE).instantiate()
	add_child(pause_menu)
	add_child(load(TOUCH_SCENE).instantiate())

	if exit_node != null:
		exit_node.reached.connect(_on_exit_reached)
		exit_node.set_open(mission.can_finish())
	if friend_node != null:
		friend_node.talk_requested.connect(_on_friend_talk)
	if data.get("rain", false) and GameState.settings.get("rain", true):
		_add_rain()
	AudioManager.play_music(data.get("music", "chase"))
	hud.refresh_all()
	_start_sequence()


func _start_sequence() -> void:
	if SceneTransition.busy:
		await SceneTransition.transition_finished
	var intro: Variant = data.get("intro")
	if intro is String and intro != "" and not GameState.intros_seen.has(intro):
		GameState.intros_seen[intro] = true
		await dialogue.play(intro)
	var chase_data: Dictionary = data.get("chase", {})
	if chase_data.get("mode", "delay") == "delay":
		_chase_timer = float(chase_data.get("delay", 5.0))


func _physics_process(delta: float) -> void:
	if not finished:
		elapsed += delta
	if _chase_timer > 0.0:
		_chase_timer -= delta
		if _chase_timer <= 0.0:
			_start_chase()


func _start_chase() -> void:
	if finished or chase.active:
		return
	chase.activate()
	hud.set_chase_visible(true)
	hud.show_toast("¡El dron patrulla te sigue!", 2.0, Color(1, 0.45, 0.5))


func _add_follower(id: String) -> void:
	var f := FriendFollower.new()
	f.friend_id = id
	f.slot = followers.size()
	f.trail = trail
	f.position = player.position
	add_child(f)
	followers.append(f)


func _add_rain() -> void:
	var rain := CPUParticles2D.new()
	rain.name = "Rain"
	rain.texture = load("res://assets/sprites/raindrop.png")
	rain.amount = 160
	rain.lifetime = 0.75
	rain.preprocess = 0.75
	rain.local_coords = true
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(320, 4)
	rain.position = Vector2(60, -160)
	rain.direction = Vector2(-0.25, 1.0)
	rain.spread = 2.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 380.0
	rain.initial_velocity_max = 460.0
	rain.particle_flag_align_y = true
	rain.color = Color(0.75, 0.85, 1.0, 0.7)
	rain.z_index = 15
	camera.add_child(rain)


# ---------------------------------------------------------------------------
# Eventos
# ---------------------------------------------------------------------------
func _on_mission_updated(text: String) -> void:
	hud.set_objective(text)
	if exit_node != null:
		exit_node.set_open(mission.can_finish())


func _on_objective_completed(text: String) -> void:
	if text.is_empty() or finished:
		return
	hud.show_toast("¡Objetivo cumplido!", 1.8, Color(0.5, 1, 0.7))
	AudioManager.play_sfx("checkpoint")


func _on_player_died(reason: String) -> void:
	var lives := GameState.lose_life()
	if lives <= 0:
		chase.stop()
		GameState.last_result = {"title": data.get("title", ""), "reason": reason}
		SceneTransition.change_scene("res://scenes/menus/game_over.tscn")
		return
	var pos: Vector2 = GameState.checkpoint_position if GameState.has_checkpoint else start_position
	player.respawn(pos)
	trail.reset(pos)
	camera.snap_to_target()
	if chase.active:
		chase.reset_behind(pos)
	hud.show_toast("%s\nVidas restantes: %d" % [reason, lives], 2.2, Color(1, 0.6, 0.6))


func _on_friend_talk(friend: FriendNPC) -> void:
	await dialogue.play(friend.dialogue_id)
	friend.celebrate()
	GameState.add_friend(friend.friend_id)
	mission.mark_friend_found()
	GameState.set_checkpoint(friend.global_position)
	for cp in get_tree().get_nodes_in_group("checkpoints"):
		cp.deactivate()
	hud.show_toast("¡%s se unió al grupo!" % GameState.character_name(friend.friend_id), 2.2, Color(1, 0.9, 0.5))
	friend.queue_free()
	friend_node = null
	_add_follower(friend.friend_id)
	var chase_data: Dictionary = data.get("chase", {})
	if chase_data.get("mode") == "after_friend" and not chase.active:
		_chase_timer = float(chase_data.get("delay", 1.5))


func _on_exit_reached(_p: Player) -> void:
	if finished:
		return
	if not mission.can_finish():
		hud.show_toast("Aún falta: " + mission.pending_text(), 2.6, Color(1, 0.85, 0.4))
		AudioManager.play_sfx("alert")
		return
	finished = true
	_chase_timer = -1.0
	player.input_enabled = false
	chase.stop()
	AudioManager.play_sfx("win")
	for f in followers:
		f.cheer()
	hud.show_toast("¡Nivel completado!", 2.0, Color(0.5, 1, 0.7))
	var outro: Variant = data.get("outro")
	if outro is String and outro != "":
		await get_tree().create_timer(1.0).timeout
		await dialogue.play(outro)
	var stats := {
		"title": data.get("title", ""),
		"granizados": GameState.level_granizados,
		"total_granizados": total_granizados,
		"pistas": GameState.level_pistas,
		"total_pistas": total_pistas,
		"time": elapsed,
		"lives": GameState.lives,
		"friends": GameState.friends.size(),
	}
	var was_last := GameState.is_last_level()
	GameState.complete_level(stats)
	await get_tree().create_timer(1.2).timeout
	SceneTransition.change_scene("res://scenes/menus/ending.tscn" if was_last else "res://scenes/menus/victory.tscn")
