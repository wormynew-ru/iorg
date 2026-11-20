extends Node
## Хранилище текущего состояния игровой сессии.

var arena_id: String = "arena_01"
var score: int = 0
var collected_ids: Array[String] = []
var total_orbs: int = 0
var player_position: Vector2 = Vector2(960.0, 640.0)
var has_custom_position: bool = false
var elapsed_time: float = 0.0
var should_load_from_save: bool = false


func reset_for_new_game(spawn_position: Vector2, target_arena_id: String = "arena_01") -> void:
	arena_id = target_arena_id
	score = 0
	collected_ids.clear()
	total_orbs = 0
	player_position = spawn_position
	has_custom_position = false
	elapsed_time = 0.0
	should_load_from_save = false


func is_orb_collected(orb_id: String) -> bool:
	return collected_ids.has(orb_id)


func register_orb_collected(orb_id: String, points: int) -> void:
	if orb_id.is_empty():
		return
	if not collected_ids.has(orb_id):
		collected_ids.append(orb_id)
		score += points
		EventBus.orb_collected.emit(orb_id, points)
		EventBus.score_changed.emit(score, collected_ids.size(), total_orbs)


func to_save_dict() -> Dictionary:
	return {
		"arena_id": arena_id,
		"score": score,
		"collected_ids": collected_ids.duplicate(),
		"elapsed_time": snappedf(elapsed_time, 0.01),
		"player_position": {
			"x": snappedf(player_position.x, 0.01),
			"y": snappedf(player_position.y, 0.01),
		},
	}


func apply_save_dict(data: Dictionary) -> void:
	arena_id = str(data.get("arena_id", "arena_01"))
	score = int(data.get("score", 0))
	elapsed_time = float(data.get("elapsed_time", 0.0))

	collected_ids.clear()
	var raw_ids: Variant = data.get("collected_ids", [])
	if raw_ids is Array:
		for item in raw_ids:
			collected_ids.append(str(item))

	var raw_pos: Variant = data.get("player_position", {})
	if raw_pos is Dictionary:
		var pos_dict: Dictionary = raw_pos
		player_position = Vector2(
			float(pos_dict.get("x", 960.0)),
			float(pos_dict.get("y", 640.0))
		)
		has_custom_position = true
	else:
		has_custom_position = false
