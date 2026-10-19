extends Node
## Comprobación del flujo real: menú -> nivel con introducción -> persecución.


## Inicia el nivel 1 como lo haría el menú, avanza el diálogo de introducción y muestra en consola
## si el juego se pausó y si la persecución arrancó después de la espera.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dummy := Node.new()
	get_tree().root.add_child.call_deferred(dummy)
	await get_tree().process_frame
	get_tree().current_scene = dummy
	GameState.intros_seen.clear()
	GameState.start_level(0)
	await SceneTransition.transition_finished
	var level := get_tree().current_scene as Level
	await get_tree().create_timer(0.5, true).timeout
	print("dialogo activo: ", level.dialogue.active, " pausado: ", get_tree().paused)
	var guard := 0
	while level.dialogue.active and guard < 60:
		var ev := InputEventAction.new()
		ev.action = "ui_accept"
		ev.pressed = true
		level.dialogue._input(ev)
		await get_tree().process_frame
		guard += 1
	print("tras diálogo pausado: ", get_tree().paused, " timer: ", level._chase_timer)
	await get_tree().create_timer(7.0, true).timeout
	print("persecución activa: ", level.chase.active, " timer: ", level._chase_timer)
	get_tree().quit()
