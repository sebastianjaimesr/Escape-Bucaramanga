class_name DialogueBox
extends CanvasLayer
## Caja de diálogo con retrato, nombre y texto que aparece letra por letra.
## Pausa el juego mientras está abierta. Uso:  await dialogue_box.play("id")

signal finished

const DIALOGUES_FILE := "res://data/dialogue/dialogues.json"
const CHARS_PER_SECOND := 45.0

static var _db: Dictionary = {}

var active := false
var _lines: Array = []
var _index := 0
var _visible_chars := 0.0
var _panel: PanelContainer
var _portrait: TextureRect
var _name: Label
var _text: Label
var _hint: Label
var _was_paused := false


static func get_dialogue(id: String) -> Array:
	if _db.is_empty():
		_db = GameState.load_json(DIALOGUES_FILE)
	var lines: Variant = _db.get(id, [])
	return lines if lines is Array else []


func _ready() -> void:
	layer = 15
	add_to_group("dialogue")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -170
	_panel.offset_bottom = -20
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.05, 0.04, 0.12, 0.92), Color(1, 0.35, 0.45)))
	root.add_child(_panel)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	_panel.add_child(hbox)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(_portrait)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_text)
	_hint = Label.new()
	_hint.text = "ESPACIO / E / clic para continuar"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(_hint)
	_panel.visible = false


## Reproduce una conversación y espera hasta que termine.
func play(dialogue_id: String) -> void:
	var lines := get_dialogue(dialogue_id)
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	active = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.visible = true
	_show_line()
	await finished


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "narrator")
	var info: Dictionary = GameState.characters.get(speaker, {})
	_name.text = info.get("name", "")
	_name.visible = _name.text != ""
	_name.add_theme_color_override("font_color", Color.from_string(info.get("color", "#ffffff"), Color.WHITE))
	_text.text = line.get("text", "")
	_text.visible_characters = 0
	_visible_chars = 0.0
	_portrait.texture = _portrait_for(info)
	_portrait.visible = _portrait.texture != null
	_text.add_theme_color_override("font_color", Color(0.85, 0.82, 1.0) if speaker == "narrator" else Color(1, 1, 1))
	AudioManager.play_sfx("blip")


func _portrait_for(info: Dictionary) -> Texture2D:
	var path: String = info.get("portrait", "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var region: Variant = info.get("portrait_region")
	if region is Array and region.size() == 4:
		return SpriteFactory.atlas(path, Rect2(region[0], region[1], region[2], region[3]))
	return load(path)


func _process(delta: float) -> void:
	if not active:
		return
	var total := _text.get_total_character_count()
	if _visible_chars < total:
		_visible_chars += CHARS_PER_SECOND * delta
		_text.visible_characters = int(_visible_chars)


func _input(event: InputEvent) -> void:
	if not active:
		return
	var advance := event.is_action_pressed("jump") or event.is_action_pressed("interact") \
		or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if event is InputEventScreenTouch and event.pressed:
		advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	var total := _text.get_total_character_count()
	if _text.visible_characters < total and _text.visible_characters != -1:
		_visible_chars = total
		_text.visible_characters = total
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	active = false
	_panel.visible = false
	get_tree().paused = _was_paused
	# Evita que el mismo botón dispare un salto al reanudar.
	Input.action_release("jump")
	finished.emit()
