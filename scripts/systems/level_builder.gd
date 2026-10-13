class_name LevelBuilder
extends RefCounted
## Convierte el mapa ASCII de data/levels/*.json en TileMapLayer y entidades.

const TILE := 16
const TILES_TEX := "res://assets/tilesets/tiles.png"
const THEMES := ["calles", "comercial", "cai", "parque", "barrio", "viaducto", "final"]
const SOLID := "#B"

const SCENES := {
	"o": "res://scenes/obstacles/collectible.tscn",
	"p": "res://scenes/obstacles/collectible.tscn",
	"h": "res://scenes/obstacles/collectible.tscn",
	"^": "res://scenes/obstacles/hazard.tscn",
	"n": "res://scenes/obstacles/hazard.tscn",
	"C": "res://scenes/obstacles/checkpoint.tscn",
	"X": "res://scenes/obstacles/level_exit.tscn",
	"M": "res://scenes/obstacles/moving_platform.tscn",
	"V": "res://scenes/obstacles/moving_platform.tscn",
	"|": "res://scenes/obstacles/barrier.tscn",
	"c": "res://scenes/obstacles/parked_car.tscn",
	"!": "res://scenes/obstacles/hint_sign.tscn",
	"d": "res://scenes/enemies/drone.tscn",
	"g": "res://scenes/enemies/dog.tscn",
	"F": "res://scenes/friends/friend.tscn",
}

const PROPS := {
	"L": "res://assets/sprites/lamp.png",
	"S": "res://assets/sprites/sign_stop.png",
	"b": "res://assets/sprites/bench.png",
	"K": "res://assets/sprites/cai.png",
	"k": "res://assets/sprites/patrol_car.png",
	"t": "res://assets/sprites/trash.png",
	"f": "res://assets/sprites/flowerpot.png",
}

var data: Dictionary
var rows: PackedStringArray
var width := 0
var height := 0
var theme_row := 0


func _init(level_data: Dictionary) -> void:
	data = level_data
	rows = PackedStringArray(data.get("map", []))
	height = rows.size()
	width = rows[0].length() if height > 0 else 0
	theme_row = maxi(0, THEMES.find(data.get("theme", "calles")))


func cell(x: int, y: int) -> String:
	if y < 0 or y >= height or x < 0 or x >= width:
		return "."
	return rows[y][x]


func is_solid(x: int, y: int) -> bool:
	return SOLID.contains(cell(x, y))


func pixel_size() -> Vector2:
	return Vector2(width * TILE, height * TILE)


static func bottom_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)


static func center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)


# ---------------------------------------------------------------------------
# Tiles
# ---------------------------------------------------------------------------
static func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load(TILES_TEX)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var h := TILE * 0.5
	var full := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var thin := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 5), Vector2(-h, -h + 5)])
	for row in THEMES.size():
		for col in 4:
			var coords := Vector2i(col, row)
			src.create_tile(coords)
			var td := src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			if col == 2:
				td.set_collision_polygon_points(0, 0, thin)
				td.set_collision_polygon_one_way(0, 0, true)
			else:
				td.set_collision_polygon_points(0, 0, full)
	return ts


func build_tiles() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = make_tileset()
	for y in height:
		for x in width:
			var ch := cell(x, y)
			var coords := Vector2i(-1, -1)
			if ch == "#":
				coords = Vector2i(0 if not is_solid(x, y - 1) else 1, theme_row)
			elif ch == "B":
				coords = Vector2i(3, theme_row)
			elif ch == "=":
				coords = Vector2i(2, theme_row)
			if coords.x >= 0:
				layer.set_cell(Vector2i(x, y), 0, coords)
	return layer


# ---------------------------------------------------------------------------
# Entidades
# ---------------------------------------------------------------------------
## Recorre el mapa y crea las entidades. Devuelve información útil para el nivel.
func spawn_entities(world: Node2D, props_root: Node2D, entities_root: Node2D) -> Dictionary:
	var info := {"player_start": Vector2(64, 200), "exit": null, "friend": null, "hints": [],
		"total_bocadillos": 0, "total_pistas": 0}
	var hints: Array = data.get("hints", [])
	var hint_index := 0
	var packed_cache := {}
	for x in width:
		for y in height:
			var ch := cell(x, y)
			if ch == "." or ch == "#" or ch == "=" or ch == "B":
				continue
			if ch == "P":
				info["player_start"] = bottom_center(x, y)
				continue
			if PROPS.has(ch) or ch == "T" or ch == "w":
				_spawn_prop(ch, x, y, props_root)
				continue
			if not SCENES.has(ch):
				push_warning("Símbolo desconocido '%s' en (%d, %d)" % [ch, x, y])
				continue
			var path: String = SCENES[ch]
			if not packed_cache.has(path):
				packed_cache[path] = load(path)
			var node = packed_cache[path].instantiate()  # sin tipo: cada escena expone propiedades propias
			match ch:
				"o", "p", "h":
					node.kind = {"o": "bocadillo", "p": "pista", "h": "heart"}[ch]
					node.position = center(x, y)
					if ch == "o":
						info["total_bocadillos"] += 1
					elif ch == "p":
						info["total_pistas"] += 1
				"^", "n":
					node.kind = "glass" if ch == "^" else "cone"
					node.position = bottom_center(x, y)
				"M", "V":
					node.vertical = ch == "V"
					node.position = center(x, y)
					node.phase = float(x) * 0.37
				"|":
					node.position = bottom_center(x, y)
					node.phase = float(x) * 0.21
				"c":
					node.variant = x % 4
					node.position = bottom_center(x, y)
				"!":
					node.text = hints[hint_index] if hint_index < hints.size() else ""
					hint_index += 1
					node.position = bottom_center(x, y)
				"d":
					node.position = center(x, y)
				"g":
					node.position = bottom_center(x, y)
					node.patrol_bounds = _ground_bounds(x, y)
				"F":
					var fdata: Dictionary = data.get("friend", {}) if data.get("friend") is Dictionary else {}
					node.friend_id = fdata.get("id", "gorra")
					node.dialogue_id = fdata.get("dialogue", "")
					node.position = bottom_center(x, y)
					info["friend"] = node
				"X":
					node.position = bottom_center(x, y)
					info["exit"] = node
				_:
					node.position = bottom_center(x, y)
			entities_root.add_child(node)
	return info


func _ground_bounds(x: int, y: int) -> Vector2:
	var left := x
	var right := x
	while left > x - 7 and is_solid(left - 1, y + 1) and not is_solid(left - 1, y):
		left -= 1
	while right < x + 7 and is_solid(right + 1, y + 1) and not is_solid(right + 1, y):
		right += 1
	return Vector2(left * TILE + 6, (right + 1) * TILE - 6)


func _spawn_prop(ch: String, x: int, y: int, root: Node2D) -> void:
	var tex_path := ""
	var theme: String = data.get("theme", "calles")
	if ch == "T":
		tex_path = "res://assets/sprites/tree.png" if theme in ["parque", "barrio"] else "res://assets/sprites/palm.png"
	elif ch == "w":
		tex_path = "res://assets/sprites/shop_%d.png" % (1 + (x * 7) % 4)
	else:
		tex_path = PROPS[ch]
	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.centered = false
	var size := spr.texture.get_size()
	var base := bottom_center(x, y)
	spr.position = Vector2(round(base.x - size.x * 0.5), base.y - size.y)
	spr.z_index = -5 if ch in ["K", "w", "T"] else -3
	root.add_child(spr)
	if ch == "L":
		var light := PointLight2D.new()
		light.texture = load("res://assets/sprites/light.png")
		light.color = Color(1.0, 0.85, 0.55)
		light.energy = 1.1
		light.texture_scale = 1.6
		light.position = Vector2(18, 10)
		spr.add_child(light)
	elif ch == "k":
		var flasher := PatrolLights.new()
		flasher.position = Vector2(size.x * 0.5, 4)
		spr.add_child(flasher)
	elif ch == "w":
		var glow := PointLight2D.new()
		glow.texture = load("res://assets/sprites/light.png")
		glow.color = Color(1.0, 0.5, 0.8) if x % 2 == 0 else Color(0.5, 0.9, 1.0)
		glow.energy = 0.6
		glow.texture_scale = 1.2
		glow.position = Vector2(size.x * 0.5, size.y * 0.6)
		spr.add_child(glow)
