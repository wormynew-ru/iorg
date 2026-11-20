extends Node
## Хранилище глобального состояния игровой сессии (ресурсы, волны, навыки, постройки).

const MAX_SKILL_LEVEL: int = 3

var map_seed: int = 0
var day: int = 1
var is_night: bool = false
var phase_timer: float = 28.0
var crystals: int = 180
var kills: int = 0
var base_level: int = 1
var base_hp: float = 500.0
var base_max_hp: float = 500.0
var sim_paused: bool = false
var is_game_over: bool = false
var skills: Dictionary = {
	"mining_speed": 0,
	"transport_speed": 0,
	"storage_capacity": 0,
	"tower_damage": 0,
}
var saved_buildings: Array = []
var camera_position: Vector2 = Vector2.ZERO
var camera_zoom: float = 1.0
var has_saved_camera: bool = false
var should_load_from_save: bool = false


func reset_for_new_game(starting_crystals: int = 180, day_duration: float = 28.0) -> void:
	randomize()
	map_seed = randi()
	day = 1
	is_night = false
	phase_timer = day_duration
	crystals = starting_crystals
	kills = 0
	base_level = 1
	base_hp = 500.0
	base_max_hp = 500.0
	sim_paused = false
	is_game_over = false
	skills = {
		"mining_speed": 0,
		"transport_speed": 0,
		"storage_capacity": 0,
		"tower_damage": 0,
	}
	saved_buildings.clear()
	camera_position = Vector2.ZERO
	camera_zoom = 1.0
	has_saved_camera = false
	should_load_from_save = false


func can_afford(amount: int) -> bool:
	return crystals >= amount


func spend_crystals(amount: int) -> bool:
	if amount < 0 or crystals < amount:
		return false
	crystals -= amount
	EventBus.crystals_changed.emit(crystals)
	return true


func add_crystals(amount: int) -> void:
	if amount <= 0:
		return
	crystals += amount
	EventBus.crystals_changed.emit(crystals)


func get_skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, 0))


func get_skill_cost(skill_id: String) -> int:
	var lvl: int = get_skill_level(skill_id)
	match skill_id:
		"transport_speed":
			return int(round(65.0 * pow(2.1, lvl)))
		_:
			return int(round(50.0 * pow(1.9, lvl)))


func upgrade_skill(skill_id: String) -> bool:
	var current: int = get_skill_level(skill_id)
	if current >= MAX_SKILL_LEVEL:
		return false
	var cost: int = get_skill_cost(skill_id)
	if not spend_crystals(cost):
		return false
	skills[skill_id] = current + 1
	EventBus.skill_upgraded.emit(skill_id, current + 1)
	return true


func get_mining_multiplier() -> float:
	return 1.0 + 0.25 * float(get_skill_level("mining_speed"))


func get_transport_multiplier() -> float:
	return 1.0 + 0.3 * float(get_skill_level("transport_speed"))


func has_teleport_logistics() -> bool:
	return get_skill_level("transport_speed") >= MAX_SKILL_LEVEL


func get_storage_multiplier() -> float:
	return 1.0 + 0.5 * float(get_skill_level("storage_capacity"))


func get_damage_multiplier() -> float:
	return 1.0 + 0.22 * float(get_skill_level("tower_damage"))


func to_save_dict() -> Dictionary:
	return {
		"map_seed": map_seed,
		"day": day,
		"is_night": is_night,
		"phase_timer": snappedf(phase_timer, 0.1),
		"crystals": crystals,
		"kills": kills,
		"base_level": base_level,
		"base_hp": snappedf(base_hp, 0.1),
		"base_max_hp": snappedf(base_max_hp, 0.1),
		"skills": skills.duplicate(true),
		"buildings": saved_buildings.duplicate(true),
		"camera_position": {
			"x": snappedf(camera_position.x, 0.1),
			"y": snappedf(camera_position.y, 0.1),
		},
		"camera_zoom": snappedf(camera_zoom, 0.01),
	}


func apply_save_dict(data: Dictionary) -> void:
	map_seed = int(data.get("map_seed", 1))
	day = maxi(1, int(data.get("day", 1)))
	is_night = bool(data.get("is_night", false))
	phase_timer = maxf(1.0, float(data.get("phase_timer", 28.0)))
	crystals = maxi(0, int(data.get("crystals", 180)))
	kills = maxi(0, int(data.get("kills", 0)))
	base_level = maxi(1, int(data.get("base_level", 1)))
	base_max_hp = maxf(100.0, float(data.get("base_max_hp", 500.0)))
	base_hp = clampf(float(data.get("base_hp", base_max_hp)), 1.0, base_max_hp)
	sim_paused = false
	is_game_over = false

	var raw_skills: Variant = data.get("skills", {})
	if raw_skills is Dictionary:
		var sd: Dictionary = raw_skills
		for key in ["mining_speed", "transport_speed", "storage_capacity", "tower_damage"]:
			skills[key] = clampi(int(sd.get(key, 0)), 0, MAX_SKILL_LEVEL)

	saved_buildings.clear()
	var raw_buildings: Variant = data.get("buildings", [])
	if raw_buildings is Array:
		saved_buildings = (raw_buildings as Array).duplicate(true)

	var raw_cam: Variant = data.get("camera_position", {})
	if raw_cam is Dictionary:
		var cam_dict: Dictionary = raw_cam
		camera_position = Vector2(float(cam_dict.get("x", 0.0)), float(cam_dict.get("y", 0.0)))
		camera_zoom = clampf(float(data.get("camera_zoom", 1.0)), 0.45, 2.0)
		has_saved_camera = true
	else:
		has_saved_camera = false
