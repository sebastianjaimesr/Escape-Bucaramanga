class_name PrototypeBody
extends Node3D
## Cuerpo PROVISIONAL de la Fase 2, hecho con primitivas para probar el
## movimiento y la cámara. Usa la paleta de Sebastián (camiseta roja, jeans,
## tenis blancos con rojo, mochila negra) para leerse bien en pantalla.
## Se reemplaza por el modelo animado de Sebastián en la Fase 3.

const SKIN := Color(0.72, 0.52, 0.4)
const HAIR := Color(0.09, 0.07, 0.06)
const SHIRT := Color(0.78, 0.09, 0.12)
const JEANS := Color(0.2, 0.3, 0.5)
const SHOE := Color(0.93, 0.93, 0.92)
const SHOE_ACCENT := Color(0.8, 0.1, 0.12)
const BAG := Color(0.06, 0.06, 0.07)

var _hips: Node3D
var _torso: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _phase := 0.0
var _crouch := 0.0
var _lean := 0.0


func _ready() -> void:
	_hips = _pivot(self, Vector3(0, 0.92, 0))
	_leg_l = _pivot(_hips, Vector3(-0.1, 0, 0))
	_leg_r = _pivot(_hips, Vector3(0.1, 0, 0))
	for leg: Node3D in [_leg_l, _leg_r]:
		_part(leg, _capsule(0.075, 0.86), Vector3(0, -0.43, 0), JEANS)
		_part(leg, _box(Vector3(0.12, 0.09, 0.27)), Vector3(0, -0.88, -0.04), SHOE)
		_part(leg, _box(Vector3(0.125, 0.03, 0.2)), Vector3(0, -0.85, -0.03), SHOE_ACCENT)
	_torso = _pivot(_hips, Vector3.ZERO)
	_part(_torso, _box(Vector3(0.38, 0.56, 0.22)), Vector3(0, 0.3, 0), SHIRT)
	_part(_torso, _sphere(0.115), Vector3(0, 0.7, 0), SKIN)  # cabeza
	_part(_torso, _box(Vector3(0.22, 0.07, 0.22)), Vector3(0, 0.79, 0.01), HAIR)
	_part(_torso, _box(Vector3(0.3, 0.38, 0.14)), Vector3(0, 0.33, 0.18), BAG)  # mochila (detrás: +Z)
	_arm_l = _pivot(_torso, Vector3(-0.235, 0.54, 0))
	_arm_r = _pivot(_torso, Vector3(0.235, 0.54, 0))
	for arm: Node3D in [_arm_l, _arm_r]:
		_part(arm, _capsule(0.055, 0.5), Vector3(0, -0.22, 0), SHIRT)
		_part(arm, _sphere(0.05), Vector3(0, -0.5, 0), SKIN)
	_part(_arm_r, _cylinder(0.058, 0.03), Vector3(0, -0.44, 0), Color(0.85, 0.65, 0.2))  # pulsera


func update_visual(p: PlayerController, delta: float) -> void:
	rotation.y = p.facing_yaw
	var speed := p.horizontal_speed()
	var on_floor := p.is_on_floor()
	var stride := 0.0
	if on_floor and speed > 0.1:
		_phase += delta * (4.0 + speed * 1.6)
		stride = clampf(speed / PlayerController.RUN_SPEED, 0.25, 1.0)
	else:
		stride = move_toward(stride, 0.0, delta * 4.0)
	var swing := sin(_phase) * 0.75 * stride
	_leg_l.rotation.x = swing if on_floor else -0.5
	_leg_r.rotation.x = -swing if on_floor else 0.3
	_arm_l.rotation.x = -swing * 0.9
	_arm_r.rotation.x = swing * 0.9
	_crouch = move_toward(_crouch, 1.0 if p.crouching else 0.0, delta * 6.0)
	_hips.position.y = lerpf(0.92, 0.55, _crouch) + absf(sin(_phase)) * 0.035 * stride
	_leg_l.rotation.x += -1.1 * _crouch
	_leg_r.rotation.x += -1.1 * _crouch
	var target_lean := 0.25 if p.is_running() else (0.08 if speed > 0.1 else 0.0)
	_lean = lerpf(_lean, target_lean + 0.35 * _crouch, clampf(delta * 8.0, 0.0, 1.0))
	_torso.rotation.x = -_lean


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 12
	m.rings = 4
	return m


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m


static func _cylinder(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 12
	return m
