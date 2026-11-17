extends Node
## Música y efectos. Crea los buses "Music" y "SFX" y un grupo de reproductores.
## La música cambia con un fundido cruzado y la tecla M silencia todo el juego.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 10
const MUSIC_DB := -4.0
const FADE_TIME := 0.8

signal mute_changed(muted: bool)

var _music: AudioStreamPlayer
var _music_old: AudioStreamPlayer
var _fade_tween: Tween
var _current_music := ""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	_music_old = AudioStreamPlayer.new()
	_music_old.bus = "Music"
	add_child(_music_old)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func set_bus_volume(bus_name: String, linear: float) -> void:
	_ensure_bus(bus_name)
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Audio no encontrado: %s" % path)
		return null
	var stream: AudioStream = load(path)
	_cache[path] = stream
	return stream


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute") and not event.is_echo():
		toggle_mute()


func is_muted() -> bool:
	return AudioServer.is_bus_mute(0)


func set_muted(value: bool) -> void:
	AudioServer.set_bus_mute(0, value)
	mute_changed.emit(value)


func toggle_mute() -> void:
	var value := not is_muted()
	set_muted(value)
	GameState.settings["muted"] = value
	SaveSystem.save_game()


func play_music(track: String) -> void:
	if track == _current_music and _music.playing:
		return
	_current_music = track
	var stream := _load(MUSIC_DIR + track + ".wav")
	if stream == null:
		return
	if _fade_tween:
		_fade_tween.kill()
	# Fundido cruzado: la pista anterior baja mientras la nueva sube.
	if _music.playing:
		_music_old.stream = _music.stream
		_music_old.volume_db = _music.volume_db
		_music_old.play(_music.get_playback_position())
	_music.stream = stream
	_music.volume_db = -40.0 if _music_old.playing else MUSIC_DB
	_music.play()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(_music, "volume_db", MUSIC_DB, FADE_TIME)
	if _music_old.playing:
		_fade_tween.tween_property(_music_old, "volume_db", -40.0, FADE_TIME)
		_fade_tween.chain().tween_callback(_music_old.stop)


func stop_music() -> void:
	_current_music = ""
	if _fade_tween:
		_fade_tween.kill()
	_music.stop()
	_music_old.stop()


func _on_music_finished() -> void:
	if _current_music != "":
		_music.play()


func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	var stream := _load(SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()
