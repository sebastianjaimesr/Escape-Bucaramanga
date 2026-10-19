class_name ChasePatrol
extends Node2D
## Persecución ficticia: un dron patrulla avanza desde la izquierda con
## velocidad creciente. Si alcanza al jugador, este pierde una vida y reaparece
## en el último punto de control. Reglas claras y visibles en el HUD.

signal distance_changed(distance: float, max_distance: float)
signal caught_player

const MAX_GAP := 520.0  ## Si el jugador se aleja más, el dron recorta distancia.
const START_GAP := 300.0  # distancia inicial al activarse
const RESPAWN_GAP := 340.0  # distancia al reaparecer el jugador
const CATCH_GAP := 10.0  # a esta distancia el dron alcanza al jugador

var player: Player
var active := false
var base_speed := 55.0
var accel := 0.4
var max_speed := 80.0
var speed := 55.0
var stopped := false
var _x := 0.0
var _sprite: AnimatedSprite2D
var _siren: AudioStreamPlayer2D
var _cone: PointLight2D


## Crea el sprite del dron, las luces de patrulla, el cono de luz y la sirena.
func _ready() -> void:
	z_index = 6
	visible = false
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/patrol_drone.png", Vector2i(48, 32), 8.0)
	add_child(_sprite)
	_sprite.play()
	var lights := PatrolLights.new()
	lights.position = Vector2(-2, -6)
	lights.scale_amount = 2.4
	lights.energy = 1.4
	add_child(lights)
	_cone = PointLight2D.new()
	_cone.texture = load("res://assets/sprites/light_cone.png")
	_cone.color = Color(1.0, 0.95, 0.7)
	_cone.energy = 0.7
	_cone.offset = Vector2(0, 64)
	_cone.position = Vector2(0, 10)
	_cone.rotation = -0.5
	add_child(_cone)
	_siren = AudioStreamPlayer2D.new()
	_siren.stream = load("res://assets/audio/sfx/siren.wav")
	_siren.bus = "SFX"
	_siren.max_distance = 900.0
	_siren.volume_db = -6.0
	_siren.finished.connect(_on_siren_finished)
	add_child(_siren)


## Repite la sirena mientras la persecución esté activa.
func _on_siren_finished() -> void:
	if active and not stopped:
		_siren.play()


## Lee la velocidad inicial, la aceleración y la velocidad máxima del JSON del nivel.
func configure(settings: Dictionary) -> void:
	base_speed = float(settings.get("speed", 55.0))
	accel = float(settings.get("accel", 0.4))
	max_speed = float(settings.get("max_speed", 80.0))
	speed = base_speed


## Empieza la persecución detrás del jugador.
func activate() -> void:
	if active or player == null:
		return
	active = true
	stopped = false
	visible = true
	speed = base_speed
	_x = player.global_position.x - START_GAP
	global_position = Vector2(_x, player.global_position.y - 70.0)
	_siren.play()
	AudioManager.play_sfx("alert")


## Detiene la persecución (al terminar el nivel o perder).
func stop() -> void:
	stopped = true
	_siren.stop()


## Tras perder una vida: el dron vuelve atrás y su velocidad se reinicia.
func reset_behind(pos: Vector2) -> void:
	speed = base_speed
	_x = pos.x - RESPAWN_GAP
	global_position = Vector2(_x, pos.y - 80.0)


## Avanza el dron (cada vez más rápido), lo mantiene cerca si el jugador se aleja mucho,
## emite la distancia para el HUD y, si lo alcanza, el jugador pierde una vida.
func _physics_process(delta: float) -> void:
	if not active or player == null:
		return
	var py := player.global_position.y
	if stopped:
		_x += 30.0 * delta
	else:
		speed = minf(max_speed, speed + accel * delta)
		_x += speed * delta
		if player.global_position.x - _x > MAX_GAP:
			_x = player.global_position.x - MAX_GAP
	var target_y := py - 64.0 + sin(Time.get_ticks_msec() * 0.003) * 6.0
	global_position = Vector2(_x, lerpf(global_position.y, target_y, clampf(delta * 2.0, 0.0, 1.0)))
	var gap := player.global_position.x - _x
	_cone.rotation = clampf(atan2(gap, 64.0) * -0.8, -0.9, 0.9)
	distance_changed.emit(clampf(gap, 0.0, MAX_GAP), MAX_GAP)
	if not stopped and gap <= CATCH_GAP and not player.is_dead and player.input_enabled:
		caught_player.emit()
		player.die("¡Te alcanzó la patrulla!")
