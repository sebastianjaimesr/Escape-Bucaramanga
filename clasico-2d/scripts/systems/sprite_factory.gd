class_name SpriteFactory
extends RefCounted
## Construye SpriteFrames a partir de spritesheets con cuadros separados.

const FRAME := 32
## [nombre, cuadros, fps, bucle] en el mismo orden que las filas del spritesheet.
const CHARACTER_ANIMS := [
	["idle", 4, 5.0, true],
	["walk", 6, 10.0, true],
	["run", 6, 14.0, true],
	["jump", 2, 8.0, false],
	["fall", 2, 8.0, true],
	["hurt", 2, 10.0, true],
	["interact", 4, 8.0, true],
]

static var _cache: Dictionary = {}


static func character_frames(sheet_path: String) -> SpriteFrames:
	if _cache.has(sheet_path):
		return _cache[sheet_path]
	var tex: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in CHARACTER_ANIMS.size():
		var def: Array = CHARACTER_ANIMS[row]
		var anim := StringName(def[0])
		frames.add_animation(anim)
		frames.set_animation_speed(anim, def[2])
		frames.set_animation_loop(anim, def[3])
		for i in int(def[1]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FRAME, row * FRAME, FRAME, FRAME)
			frames.add_frame(anim, at)
	_cache[sheet_path] = frames
	return frames


## Tira horizontal de cuadros del mismo tamaño (enemigos, objetos animados).
static func strip_frames(sheet_path: String, frame_size: Vector2i, fps: float = 8.0, loop: bool = true) -> SpriteFrames:
	var key := "%s:%s" % [sheet_path, frame_size]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", fps)
	frames.set_animation_loop(&"default", loop)
	var count := int(tex.get_width() / frame_size.x)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(&"default", at)
	_cache[key] = frames
	return frames


static func atlas(sheet_path: String, region: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = load(sheet_path)
	at.region = region
	return at
