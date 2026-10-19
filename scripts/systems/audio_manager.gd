extends Node
## Música y efectos. Crea los buses "Music" y "SFX" y un grupo de reproductores.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 10  # cuántos efectos pueden sonar al mismo tiempo

var _music: AudioStreamPlayer
var _current_music := ""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache: Dictionary = {}


## Crea los buses de audio, el reproductor de música y 10 reproductores para efectos.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)


## Crea un bus de audio si no existe (Music o SFX) y lo envía al principal.
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## Cambia el volumen de un bus con un valor de 0 a 1 (se convierte a decibelios).
func set_bus_volume(bus_name: String, linear: float) -> void:
	_ensure_bus(bus_name)
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


## Carga un audio una sola vez y lo guarda en caché.
func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Audio no encontrado: %s" % path)
		return null
	var stream: AudioStream = load(path)
	_cache[path] = stream
	return stream


## Reproduce una pista de música (si ya suena, no la reinicia).
func play_music(track: String) -> void:
	if track == _current_music and _music.playing:
		return
	_current_music = track
	var stream := _load(MUSIC_DIR + track + ".wav")
	if stream == null:
		return
	_music.stream = stream
	_music.volume_db = -4.0
	_music.play()


## Detiene la música.
func stop_music() -> void:
	_current_music = ""
	_music.stop()


## Repite la música al terminar (bucle).
func _on_music_finished() -> void:
	if _current_music != "":
		_music.play()


## Reproduce un efecto con el siguiente reproductor libre (rotación circular);
## pitch_variation cambia un poco el tono para que no suene repetitivo.
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	var stream := _load(SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()
