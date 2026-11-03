class_name PrototypeWorld
extends Node3D
## Escena del prototipo de la Fase 2: manzana de prueba, luz de día, jugador,
## cámara en tercera persona, HUD, pausa y perfiles de calidad.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const FALL_RESET_Y := -25.0

var points: Dictionary = {}
var player: PlayerController
var camera_rig: ThirdPersonCamera
var environment: Environment
var sun: DirectionalLight3D
var hud: Hud
var pause_menu: PauseMenu


func _ready() -> void:
	_build_environment()
	points = PrototypeBlockBuilder.new(self).build()
	player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player)
	player.teleport(points["spawn"], points["spawn_yaw"])
	camera_rig = ThirdPersonCamera.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.set_target(player)
	camera_rig.camera.make_current()
	hud = Hud.new()
	add_child(hud)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.respawn_requested.connect(respawn)
	apply_quality()
	Settings.changed.connect(_on_setting_changed)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.5, 0.78)
	sky_mat.sky_horizon_color = Color(0.72, 0.78, 0.86)
	sky_mat.ground_horizon_color = Color(0.6, 0.62, 0.64)
	sky_mat.ground_bottom_color = Color(0.25, 0.25, 0.27)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.7, 0.76, 0.84)
	environment.fog_density = 1.0
	environment.fog_depth_curve = 1.5
	environment.fog_sky_affect = 0.15
	environment.ssao_radius = 1.2
	environment.ssao_intensity = 1.6
	environment.volumetric_fog_density = 0.008
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.04
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = environment
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_blend_splits = true
	add_child(sun)


func apply_quality() -> void:
	var profile := Settings.quality_profile()
	QualityProfiles.apply(profile, get_viewport(), environment, sun, camera_rig.camera)


func respawn() -> void:
	player.teleport(points["spawn"], points["spawn_yaw"])
	camera_rig.yaw = points["spawn_yaw"]
	camera_rig.snap()


var _was_captured := false


func _physics_process(_delta: float) -> void:
	if player.global_position.y < FALL_RESET_Y:
		respawn()


func _process(_delta: float) -> void:
	# En el navegador, Esc suelta el ratón sin que el juego reciba la tecla:
	# si el ratón deja de estar capturado mientras se juega, se abre la pausa.
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _was_captured and not captured and not get_tree().paused:
		pause_menu.open()
	_was_captured = captured


func _unhandled_input(event: InputEvent) -> void:
	# Clic dentro del juego: capturar el ratón para mover la cámara.
	if event is InputEventMouseButton and event.pressed and not get_tree().paused:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			EventBus.mouse_capture_changed.emit(true)


func _notification(what: int) -> void:
	# Si el navegador o el sistema sueltan el ratón (Esc en web, Alt+Tab), se pausa.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not get_tree().paused and pause_menu != null:
		pause_menu.open()


func _on_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == "graphics" and key == "profile":
		apply_quality()
