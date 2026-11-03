class_name MaterialLibrary
extends RefCounted
## Materiales PBR compartidos (uno por tipo, reutilizados por todas las mallas
## para reducir cambios de estado al dibujar).
##
## En la Fase 2 las superficies usan ruido procedural para la variación de color
## y rugosidad. En la Fase 5 se reemplazan por texturas PBR con licencia CC0.

static var _cache: Dictionary = {}

const FACADE_COLORS := [
	Color(0.93, 0.9, 0.82),   # blanco cal
	Color(0.86, 0.72, 0.5),   # ocre
	Color(0.78, 0.48, 0.36),  # terracota
	Color(0.68, 0.76, 0.72),  # verde pálido
	Color(0.84, 0.8, 0.66),   # arena
	Color(0.62, 0.66, 0.74),  # azul gris
	Color(0.9, 0.82, 0.7),    # crema
]


static func get_material(id: String) -> StandardMaterial3D:
	if _cache.has(id):
		return _cache[id]
	var m: StandardMaterial3D
	match id:
		"asphalt":
			m = _surface(Color(0.11, 0.11, 0.12), 0.92, 0.08, 0.35)
		"sidewalk":
			m = _surface(Color(0.44, 0.43, 0.41), 0.86, 0.12, 0.5)
		"curb":
			m = _surface(Color(0.55, 0.53, 0.5), 0.8, 0.08, 1.0)
		"plaza":
			m = _surface(Color(0.62, 0.52, 0.44), 0.82, 0.1, 0.6)
		"concrete":
			m = _surface(Color(0.5, 0.5, 0.49), 0.88, 0.1, 0.4)
		"grass":
			m = _surface(Color(0.2, 0.33, 0.14), 0.95, 0.2, 0.7)
		"paint_white":
			m = _flat(Color(0.88, 0.88, 0.85), 0.6)
		"paint_yellow":
			m = _flat(Color(0.92, 0.72, 0.15), 0.6)
		"glass":
			m = _flat(Color(0.12, 0.16, 0.2), 0.08)
			m.metallic = 0.2
			m.metallic_specular = 0.8
		"storefront":
			m = _flat(Color(0.16, 0.15, 0.14), 0.5)
		"awning":
			m = _flat(Color(0.7, 0.14, 0.14), 0.7)
		"metal":
			m = _flat(Color(0.2, 0.21, 0.22), 0.45)
			m.metallic = 0.85
		"wood":
			m = _surface(Color(0.42, 0.28, 0.17), 0.8, 0.15, 2.0)
		"bark":
			m = _surface(Color(0.3, 0.22, 0.15), 0.95, 0.2, 2.0)
		"leaves":
			m = _surface(Color(0.17, 0.36, 0.13), 0.9, 0.25, 1.5)
		"test_orange":
			m = _flat(Color(0.95, 0.45, 0.12), 0.6)
		_:
			if id.begins_with("facade_"):
				var i := int(id.trim_prefix("facade_")) % FACADE_COLORS.size()
				m = _surface(FACADE_COLORS[i], 0.88, 0.07, 0.4)
			else:
				push_error("Material desconocido: %s" % id)
				m = _flat(Color.MAGENTA, 0.5)
	_cache[id] = m
	return m


## Superficie con variación procedural de color (proyección triplanar en
## coordenadas del mundo, así no hay que preparar UV en la geometría de prueba).
static func _surface(color: Color, roughness: float, variation: float, scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0 - variation, 1.0 - variation, 1.0 - variation))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	tex.color_ramp = ramp
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale * 0.25
	return m


static func _flat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
