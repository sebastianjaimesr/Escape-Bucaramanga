class_name MissionSystem
extends Node
## Objetivos del nivel definidos en data/levels/*.json ("mission").
## Tipos: reach_exit, collect (granizados), pistas, friend.

signal updated(text: String)
signal objective_completed(text: String)

var objectives: Array = []
var friend_found := false
var _done: Dictionary = {}


func setup(defs: Array) -> void:
	objectives = defs.duplicate(true)
	GameState.granizados_changed.connect(_on_count_changed)
	GameState.pistas_changed.connect(_on_count_changed)
	refresh()


func _on_count_changed(_count: int) -> void:
	refresh()


func mark_friend_found() -> void:
	friend_found = true
	refresh()


func is_done(obj: Dictionary) -> bool:
	match String(obj.get("type", "")):
		"collect":
			return GameState.level_granizados >= int(obj.get("count", 0))
		"pistas":
			return GameState.level_pistas >= int(obj.get("count", 0))
		"friend":
			return friend_found
		"reach_exit":
			return false
	return true


## Verdadero cuando todo, excepto llegar a la meta, está cumplido.
func can_finish() -> bool:
	for obj: Dictionary in objectives:
		if obj.get("type") != "reach_exit" and not is_done(obj):
			return false
	return true


func pending_text() -> String:
	for obj: Dictionary in objectives:
		if obj.get("type") != "reach_exit" and not is_done(obj):
			return describe(obj)
	return ""


func describe(obj: Dictionary) -> String:
	var text: String = obj.get("text", "")
	match String(obj.get("type", "")):
		"collect":
			text += " (%d/%d)" % [mini(GameState.level_granizados, int(obj["count"])), int(obj["count"])]
		"pistas":
			text += " (%d/%d)" % [mini(GameState.level_pistas, int(obj["count"])), int(obj["count"])]
	return text


func current_text() -> String:
	for obj: Dictionary in objectives:
		if not is_done(obj):
			return describe(obj)
	return "¡Objetivos cumplidos!"


func refresh() -> void:
	for i in objectives.size():
		var obj: Dictionary = objectives[i]
		if is_done(obj) and not _done.has(i):
			_done[i] = true
			objective_completed.emit(String(obj.get("text", "")))
	updated.emit(current_text())
