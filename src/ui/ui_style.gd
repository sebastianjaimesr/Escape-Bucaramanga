class_name UiStyle
extends RefCounted
## Colores y fábricas de controles compartidos por toda la interfaz.

const BG := Color(0.055, 0.06, 0.075, 1.0)
const PANEL := Color(0.08, 0.09, 0.11, 0.92)
const PANEL_BORDER := Color(1, 1, 1, 0.08)
const TEXT := Color(0.95, 0.94, 0.92)
const TEXT_DIM := Color(0.68, 0.68, 0.7)
const ACCENT := Color(0.89, 0.2, 0.22)       ## Rojo de la camiseta de Sebastián.
const ACCENT_SOFT := Color(0.89, 0.2, 0.22, 0.18)
const OK := Color(0.4, 0.85, 0.55)
const WARN := Color(1.0, 0.78, 0.3)


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_width: float = 280.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 46)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.04), PANEL_BORDER))
	b.add_theme_stylebox_override("hover", _box(ACCENT_SOFT, ACCENT))
	b.add_theme_stylebox_override("focus", _box(ACCENT_SOFT, ACCENT))
	b.add_theme_stylebox_override("pressed", _box(Color(ACCENT, 0.35), ACCENT))
	b.add_theme_stylebox_override("disabled", _box(Color(1, 1, 1, 0.02), PANEL_BORDER))
	return b


## Ancla un control a su contenedor: anclas (0..1) y márgenes en píxeles.
static func place(c: Control, anchors: Vector4, offsets: Vector4) -> void:
	c.anchor_left = anchors.x
	c.anchor_top = anchors.y
	c.anchor_right = anchors.z
	c.anchor_bottom = anchors.w
	c.offset_left = offsets.x
	c.offset_top = offsets.y
	c.offset_right = offsets.z
	c.offset_bottom = offsets.w


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _box(PANEL, PANEL_BORDER)
	sb.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
