extends Node
## Capturas de pantalla del prototipo para revisar el aspecto visual.
##
##   godot --path . --rendering-method gl_compatibility res://tests/screenshots.tscn -- <carpeta_salida>
##
## Necesita una ventana (no funciona con --headless). Sin carpeta, guarda en user://capturas.

const VIEWS := [
	# [nombre, posición del jugador, yaw de la cámara, pitch de la cámara]
	["01_cruce", Vector3(-8.0, 0.15, 9.0), -PI * 0.25, -0.12],
	["02_calle", Vector3(-1.5, 0.0, 30.0), 0.0, -0.08],
	["03_plaza_pruebas", Vector3(-12.0, 0.15, 12.0), PI * 0.8, -0.3],
	["04_escaleras", Vector3(-24.0, 0.15, 13.0), PI * 0.95, -0.2],
	["05_tunel", Vector3(-20.0, 0.15, 37.0), PI * 0.5, -0.15],
	["06_fachadas", Vector3(20.0, 0.15, 5.5), PI * 0.1, 0.15],
]


func _ready() -> void:
	var out := "user://capturas"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var profile := "medio"
	if args.size() > 1:
		profile = args[1]
	Settings.config_path = "user://screenshot_settings.cfg"
	Settings.load_settings()
	Settings.set_value("graphics", "profile", profile, false)
	var world: PrototypeWorld = (load("res://scenes/world/prototype/prototype_world.tscn") as PackedScene).instantiate()
	add_child(world)
	world.hud.visible = false
	for v: Array in VIEWS:
		world.player.teleport(v[1], v[2])
		world.camera_rig.yaw = v[2]
		world.camera_rig.pitch = v[3]
		world.camera_rig.snap()
		for i in 40:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := out.path_join("%s_%s.png" % [v[0], profile])
		img.save_png(path)
		print("Captura: ", ProjectSettings.globalize_path(path))
	get_tree().quit()
