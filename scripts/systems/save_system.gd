extends Node
## Guardado de progreso y configuración en user://save.json.

const SAVE_PATH := "user://save.json"
const VERSION := 1


## Al iniciar el juego carga la partida guardada y aplica la configuración.
func _ready() -> void:
	load_game()
	apply_settings()


## true si existe una partida guardada.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Guarda progreso y configuración en JSON. Devuelve false si no se pudo escribir.
func save_game() -> bool:
	var data := {
		"version": VERSION,
		"current_level": GameState.current_level,
		"unlocked_level": GameState.unlocked_level,
		"lives": GameState.lives,
		"best_granizados": GameState.best_granizados,
		"intros_seen": GameState.intros_seen,
		"settings": GameState.settings,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


## Lee la partida guardada; si el archivo está dañado lo ignora.
func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		push_warning("Archivo de guardado dañado; se ignora.")
		return false
	var data: Dictionary = parsed
	GameState.current_level = int(data.get("current_level", 0))
	GameState.unlocked_level = int(data.get("unlocked_level", 0))
	GameState.lives = clampi(int(data.get("lives", GameState.MAX_LIVES)), 1, GameState.MAX_LIVES)
	GameState.best_granizados = data.get("best_granizados", {})
	GameState.intros_seen = data.get("intros_seen", {})
	var s: Variant = data.get("settings", {})
	if s is Dictionary:
		for key: String in s:
			GameState.settings[key] = s[key]
	return true


## Borra la partida guardada.
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Aplica volumen de música y efectos y la pantalla completa.
func apply_settings() -> void:
	AudioManager.set_bus_volume("Music", float(GameState.settings.get("music", 0.7)))
	AudioManager.set_bus_volume("SFX", float(GameState.settings.get("sfx", 0.85)))
	var fs := bool(GameState.settings.get("fullscreen", false))
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)
