class_name HUD
extends CanvasLayer
## HUD: salud, vidas, granizados, pistas, amigos, objetivo y distancia de la patrulla.

var _hearts: Array[TextureRect] = []
var _lives_label: Label
var _boca_label: Label
var _pistas_box: HBoxContainer
var _pistas_label: Label
var _friends_label: Label
var _objective: Label
var _level_title: Label
var _chase_box: VBoxContainer
var _chase_bar: ProgressBar
var _hint: Label
var _prompt: Label
var _toast: Label
var _hint_time := 0.0
var _toast_time := 0.0
var _heart_full: AtlasTexture
var _heart_empty: AtlasTexture
var _fill_styles: Dictionary = {}


## Construye el HUD por código (esquinas: salud y contadores, título y objetivo, barra de la
## patrulla, mensajes) y se conecta a las señales de GameState para actualizarse solo.
func _ready() -> void:
	layer = 10
	add_to_group("hud")
	_heart_full = SpriteFactory.atlas("res://assets/ui/hearts.png", Rect2(0, 0, 16, 16))
	_heart_empty = SpriteFactory.atlas("res://assets/ui/hearts.png", Rect2(16, 0, 16, 16))
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	# Esquina superior izquierda: salud, vidas y contadores
	var left := VBoxContainer.new()
	left.position = Vector2(16, 12)
	left.add_theme_constant_override("separation", 4)
	root.add_child(left)
	var hearts_row := HBoxContainer.new()
	hearts_row.add_theme_constant_override("separation", 2)
	left.add_child(hearts_row)
	for i in GameState.MAX_HEALTH:
		var tr := TextureRect.new()
		tr.texture = _heart_full
		tr.custom_minimum_size = Vector2(32, 32)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hearts_row.add_child(tr)
		_hearts.append(tr)
	var counters := HBoxContainer.new()
	counters.add_theme_constant_override("separation", 14)
	left.add_child(counters)
	var life_icon := TextureRect.new()
	life_icon.texture = load("res://assets/ui/life_icon.png")
	life_icon.custom_minimum_size = Vector2(28, 28)
	life_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	life_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	counters.add_child(life_icon)
	_lives_label = _label("x5", 20)
	counters.add_child(_lives_label)
	var boca_icon := TextureRect.new()
	boca_icon.texture = SpriteFactory.atlas("res://assets/sprites/granizado.png", Rect2(0, 0, 16, 16))
	boca_icon.custom_minimum_size = Vector2(28, 28)
	boca_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boca_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	counters.add_child(boca_icon)
	_boca_label = _label("0", 20)
	counters.add_child(_boca_label)
	_pistas_box = HBoxContainer.new()
	counters.add_child(_pistas_box)
	var pista_icon := TextureRect.new()
	pista_icon.texture = SpriteFactory.atlas("res://assets/sprites/pista.png", Rect2(0, 0, 16, 16))
	pista_icon.custom_minimum_size = Vector2(28, 28)
	pista_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pista_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pistas_box.add_child(pista_icon)
	_pistas_label = _label("0", 20)
	_pistas_box.add_child(_pistas_label)
	_pistas_box.visible = false
	_friends_label = _label("", 16)
	_friends_label.add_theme_color_override("font_color", Color(1, 0.88, 0.5))
	left.add_child(_friends_label)

	# Centro superior: nivel y objetivo
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.anchor_left = 0.5
	top.anchor_right = 0.5
	top.offset_left = -260
	top.offset_right = 260
	top.offset_top = 10
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_level_title = _label("", 16)
	_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_title.add_theme_color_override("font_color", Color(0.75, 0.8, 1.0))
	top.add_child(_level_title)
	_objective = _label("", 20)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_objective)

	# Esquina superior derecha: distancia a la patrulla
	_chase_box = VBoxContainer.new()
	_chase_box.anchor_left = 1.0
	_chase_box.anchor_right = 1.0
	_chase_box.offset_left = -220
	_chase_box.offset_right = -16
	_chase_box.offset_top = 14
	root.add_child(_chase_box)
	var chase_label := _label("Distancia a la patrulla", 15)
	chase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chase_box.add_child(chase_label)
	_chase_bar = ProgressBar.new()
	_chase_bar.custom_minimum_size = Vector2(200, 16)
	_chase_bar.show_percentage = false
	_chase_bar.max_value = 1.0
	_chase_bar.step = 0.001
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.2, 0.85)
	bg.set_corner_radius_all(4)
	bg.border_color = Color(0.4, 0.5, 1.0)
	bg.set_border_width_all(2)
	_chase_bar.add_theme_stylebox_override("background", bg)
	_chase_box.add_child(_chase_bar)
	_set_bar_color(Color(0.3, 1.0, 0.6))
	_chase_box.visible = false

	# Mensajes
	_hint = _label("", 20)
	_hint.anchor_left = 0.1
	_hint.anchor_right = 0.9
	_hint.anchor_top = 0.86
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	root.add_child(_hint)
	_prompt = _label("", 18)
	_prompt.anchor_left = 0.3
	_prompt.anchor_right = 0.7
	_prompt.anchor_top = 0.56
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	root.add_child(_prompt)
	_toast = _label("", 28)
	_toast.anchor_left = 0.05
	_toast.anchor_right = 0.95
	_toast.anchor_top = 0.3
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_toast)

	GameState.health_changed.connect(_on_health_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.granizados_changed.connect(_on_granizados_changed)
	GameState.pistas_changed.connect(_on_pistas_changed)
	GameState.friends_changed.connect(_on_friends_changed)
	refresh_all()


## Crea un texto del tamaño indicado que no bloquea el mouse.
func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Cambia el color de la barra de la patrulla (reutiliza estilos ya creados).
func _set_bar_color(c: Color) -> void:
	if not _fill_styles.has(c):
		var fill := StyleBoxFlat.new()
		fill.bg_color = c
		fill.set_corner_radius_all(4)
		_fill_styles[c] = fill
	_chase_bar.add_theme_stylebox_override("fill", _fill_styles[c])


## Actualiza todos los indicadores con los valores actuales.
func refresh_all() -> void:
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_on_lives_changed(GameState.lives)
	_on_granizados_changed(GameState.level_granizados)
	_on_pistas_changed(GameState.level_pistas)
	_on_friends_changed(GameState.friends)


## Muestra el título del nivel.
func set_level_title(text: String) -> void:
	_level_title.text = text


## Muestra el objetivo actual.
func set_objective(text: String) -> void:
	_objective.text = text


## Muestra u oculta el contador de pistas (solo en niveles que las tienen).
func show_pistas(value: bool) -> void:
	_pistas_box.visible = value


## Muestra u oculta la barra de la patrulla.
func set_chase_visible(value: bool) -> void:
	_chase_box.visible = value


## Actualiza la barra de distancia: roja y parpadeando si la patrulla está muy cerca,
## amarilla a media distancia y verde lejos.
func set_chase_distance(distance: float, max_distance: float) -> void:
	var ratio := clampf(distance / max_distance, 0.0, 1.0)
	_chase_bar.value = ratio
	if ratio < 0.25:
		_set_bar_color(Color(1.0, 0.25, 0.3) if int(Time.get_ticks_msec() / 150) % 2 == 0 else Color(1, 0.6, 0.3))
	elif ratio < 0.5:
		_set_bar_color(Color(1.0, 0.75, 0.3))
	else:
		_set_bar_color(Color(0.3, 1.0, 0.6))


## Muestra un consejo durante 5 segundos.
func show_hint(text: String) -> void:
	_hint.text = text
	_hint_time = 5.0


## Muestra una indicación fija (por ejemplo, "Presiona E para hablar"); vacío la oculta.
func show_prompt(text: String) -> void:
	_prompt.text = text


## Muestra un aviso temporal en el centro.
func show_toast(text: String, duration: float = 2.5, color: Color = Color(1, 0.95, 0.85)) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast_time = duration
	_toast.modulate.a = 1.0


## Desvanece el consejo y el aviso cuando se acaba su tiempo.
func _process(delta: float) -> void:
	if _hint_time > 0.0:
		_hint_time -= delta
		_hint.modulate.a = clampf(_hint_time, 0.0, 1.0)
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time * 2.0, 0.0, 1.0)


## Dibuja corazones llenos o vacíos según la salud.
func _on_health_changed(health: int, max_health: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = _heart_full if i < health else _heart_empty
		_hearts[i].visible = i < max_health


## Actualiza el contador de vidas.
func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "x%d" % lives


## Actualiza el contador de granizados.
func _on_granizados_changed(count: int) -> void:
	_boca_label.text = str(count)


## Actualiza el contador de pistas.
func _on_pistas_changed(count: int) -> void:
	_pistas_label.text = str(count)


## Muestra los nombres de los amigos que ya se unieron.
func _on_friends_changed(friends: Array) -> void:
	if friends.is_empty():
		_friends_label.text = ""
		return
	var names := PackedStringArray()
	for id: String in friends:
		names.append(GameState.character_name(id))
	_friends_label.text = "Grupo: " + ", ".join(names)
