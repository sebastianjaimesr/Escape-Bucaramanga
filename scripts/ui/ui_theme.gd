class_name UITheme
extends RefCounted
## Tema visual compartido de la interfaz (neón nocturno, legible).

const ACCENT := Color(1.0, 0.33, 0.45)
const ACCENT_BLUE := Color(0.35, 0.6, 1.0)
const TEXT := Color(1.0, 0.97, 0.92)

static var _theme: Theme


## Estilo de panel con fondo, borde y esquinas redondeadas.
static func panel_style(bg: Color, border: Color, width: int = 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(border.r, border.g, border.b, 0.25)
	sb.shadow_size = 8
	return sb


## Tema común de la interfaz (se crea una vez y se reutiliza).
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0))
	t.set_constant("outline_size", "Label", 5)
	var normal := panel_style(Color(0.09, 0.07, 0.2, 0.9), Color(0.35, 0.3, 0.6), 2)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := panel_style(Color(0.2, 0.08, 0.22, 0.95), ACCENT, 3)
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	var pressed := panel_style(Color(0.35, 0.1, 0.2, 0.95), Color(1, 0.8, 0.3), 3)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	var disabled := panel_style(Color(0.08, 0.08, 0.1, 0.6), Color(0.25, 0.25, 0.3), 2)
	disabled.content_margin_top = 8
	disabled.content_margin_bottom = 8
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 0.9, 0.6))
	t.set_color("font_focus_color", "Button", Color(1, 0.9, 0.6))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.55))
	t.set_font_size("font_size", "Button", 22)
	t.set_stylebox("panel", "PanelContainer", panel_style(Color(0.05, 0.04, 0.12, 0.92), ACCENT_BLUE))
	t.set_font_size("font_size", "CheckButton", 20)
	t.set_color("font_color", "CheckButton", TEXT)
	return t


## Botón con sonidos al enfocarlo y presionarlo.
static func button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 46)
	b.pressed.connect(func() -> void: AudioManager.play_sfx("ui_select"))
	b.pressed.connect(callback)
	b.focus_entered.connect(func() -> void: AudioManager.play_sfx("ui_move"))
	return b


## Título grande con borde.
static func title_label(text: String, size: int = 40, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 8)
	return l
