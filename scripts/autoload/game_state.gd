extends Node
## Хранилище глобального состояния игровой сессии (ресурсы, волны, древо талантов, постройки).

const TALENT_ORDER: Array[String] = [
	"mining_speed", "factory_yield", "crystal_interest",
	"storage_capacity", "transport_speed", "teleport_logistics",
	"tower_damage", "tower_fire_rate", "base_fortification",
]

const TALENT_DEFS: Dictionary = {
	"mining_speed": {
		"title": "Интенсивная добыча",
		"short_title": "Добыча+",
		"branch": 0,
		"tier": 0,
		"max_level": 3,
		"costs": [45, 85, 140],
		"requires_id": "",
		"requires_level": 0,
		"color": Color(0.961, 0.62, 0.043, 1.0),
		"description": "+25% к скорости добычи шахт и производства заводов за каждый уровень.",
	},
	"factory_yield": {
		"title": "Эффективные заводы",
		"short_title": "Выход заводов",
		"branch": 0,
		"tier": 1,
		"max_level": 2,
		"costs": [110, 210],
		"requires_id": "mining_speed",
		"requires_level": 1,
		"color": Color(0.961, 0.62, 0.043, 1.0),
		"description": "+1 снаряд за цикл переработки заводов. На 2-м ур.: +20% скорости заводов.",
	},
	"crystal_interest": {
		"title": "Кристальный синтез",
		"short_title": "Синтез +25%",
		"branch": 0,
		"tier": 2,
		"max_level": 1,
		"costs": [280],
		"requires_id": "factory_yield",
		"requires_level": 1,
		"color": Color(0.961, 0.62, 0.043, 1.0),
		"description": "+25% кристаллов при доставке с шахт на Базу и в награду за пережитую ночь.",
	},
	"storage_capacity": {
		"title": "Расширенные склады",
		"short_title": "Склады+",
		"branch": 1,
		"tier": 0,
		"max_level": 3,
		"costs": [45, 85, 140],
		"requires_id": "",
		"requires_level": 0,
		"color": Color(0.133, 0.827, 0.933, 1.0),
		"description": "+50% к вместимости складов, транспортёров и боезапаса башен за уровень.",
	},
	"transport_speed": {
		"title": "Скоростные линии",
		"short_title": "Логистика+",
		"branch": 1,
		"tier": 1,
		"max_level": 3,
		"costs": [65, 130, 240],
		"requires_id": "storage_capacity",
		"requires_level": 1,
		"color": Color(0.133, 0.827, 0.933, 1.0),
		"description": "+30% к скорости полёта грузов и пропускной способности транспортёров за уровень.",
	},
	"teleport_logistics": {
		"title": "Телепортация грузов",
		"short_title": "Телепорт",
		"branch": 1,
		"tier": 2,
		"max_level": 1,
		"costs": [350],
		"requires_id": "transport_speed",
		"requires_level": 2,
		"color": Color(0.133, 0.827, 0.933, 1.0),
		"description": "Финальный перк: мгновенная телепортация всех ресурсов и снарядов напрямую к цели.",
	},
	"tower_damage": {
		"title": "Усиленные снаряды",
		"short_title": "Урон башен",
		"branch": 2,
		"tier": 0,
		"max_level": 3,
		"costs": [50, 95, 160],
		"requires_id": "",
		"requires_level": 0,
		"color": Color(0.937, 0.267, 0.267, 1.0),
		"description": "+22% к урону всех оборонительных башен за каждый уровень.",
	},
	"tower_fire_rate": {
		"title": "Скорострельность",
		"short_title": "Темп огня",
		"branch": 2,
		"tier": 1,
		"max_level": 2,
		"costs": [110, 220],
		"requires_id": "tower_damage",
		"requires_level": 1,
		"color": Color(0.937, 0.267, 0.267, 1.0),
		"description": "-15% к задержке между выстрелами за уровень. На 2-м ур.: +0.4 к дальности башен.",
	},
	"base_fortification": {
		"title": "Броня и регенерация",
		"short_title": "Фортификация",
		"branch": 2,
		"tier": 2,
		"max_level": 2,
		"costs": [180, 320],
		"requires_id": "tower_fire_rate",
		"requires_level": 1,
		"color": Color(0.937, 0.267, 0.267, 1.0),
		"description": "+35% к прочности Базы и всех стен за уровень; ускоряет дневную регенерацию Базы.",
	},
}

var map_seed: int = 0
var day: int = 1
var is_night: bool = false
var phase_timer: float = 55.0
var crystals: int = 180
var kills: int = 0
var base_level: int = 1
var base_hp: float = 500.0
var base_max_hp: float = 500.0
var sim_paused: bool = false
var is_game_over: bool = false
var skills: Dictionary = {}
var saved_buildings: Array = []
var camera_position: Vector2 = Vector2.ZERO
var camera_zoom: float = 1.0
var has_saved_camera: bool = false
var should_load_from_save: bool = false
var _crystal_bonus_counter: int = 0
var _kill_bonus_accum: float = 0.0


func _ready() -> void:
	_reset_skills()


func _reset_skills() -> void:
	skills.clear()
	for id in TALENT_ORDER:
		skills[id] = 0
	_crystal_bonus_counter = 0
	_kill_bonus_accum = 0.0


func reset_for_new_game(starting_crystals: int = 180, day_duration: float = 55.0) -> void:
	randomize()
	map_seed = randi()
	day = 1
	is_night = false
	phase_timer = day_duration
	crystals = starting_crystals + MetaProgression.get_bonus_starting_crystals()
	kills = 0
	base_level = 1
	_reset_skills()
	base_max_hp = (500.0 + MetaProgression.get_base_bonus_hp()) * MetaProgression.get_base_hp_mult() * get_fortification_hp_multiplier()
	base_hp = base_max_hp
	sim_paused = false
	is_game_over = false
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


func register_base_crystal_delivered() -> void:
	var gained: int = 1
	if get_skill_level("crystal_interest") >= 1:
		_crystal_bonus_counter += 1
		if _crystal_bonus_counter >= 4:
			_crystal_bonus_counter = 0
			gained += 1
	add_crystals(gained)


func get_talent_def(skill_id: String) -> Dictionary:
	return TALENT_DEFS.get(skill_id, {}) as Dictionary


func get_skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, 0))


func get_talent_max_level(skill_id: String) -> int:
	var def: Dictionary = get_talent_def(skill_id)
	return int(def.get("max_level", 1))


func is_talent_unlocked(skill_id: String) -> bool:
	var def: Dictionary = get_talent_def(skill_id)
	if def.is_empty():
		return false
	var req_id: String = str(def.get("requires_id", ""))
	if req_id.is_empty():
		return true
	var req_lvl: int = int(def.get("requires_level", 1))
	return get_skill_level(req_id) >= req_lvl


func get_skill_cost(skill_id: String) -> int:
	var def: Dictionary = get_talent_def(skill_id)
	if def.is_empty():
		return 999999
	var lvl: int = get_skill_level(skill_id)
	var costs: Array = def.get("costs", []) as Array
	if lvl < 0 or lvl >= costs.size():
		return 999999
	return int(costs[lvl])


func upgrade_skill(skill_id: String) -> bool:
	if not is_talent_unlocked(skill_id):
		return false
	var current: int = get_skill_level(skill_id)
	var max_lvl: int = get_talent_max_level(skill_id)
	if current >= max_lvl:
		return false
	var cost: int = get_skill_cost(skill_id)
	if not spend_crystals(cost):
		return false
	skills[skill_id] = current + 1
	EventBus.skill_upgraded.emit(skill_id, current + 1)
	return true


func get_total_talent_points() -> int:
	var total: int = 0
	for id in TALENT_ORDER:
		total += get_skill_level(id)
	return total


func get_max_talent_points() -> int:
	var total: int = 0
	for id in TALENT_ORDER:
		total += get_talent_max_level(id)
	return total


func get_mining_multiplier() -> float:
	return (1.0 + 0.25 * float(get_skill_level("mining_speed"))) * MetaProgression.get_mining_speed_mult()


func get_factory_speed_multiplier() -> float:
	var talent_mult: float = 1.2 if get_skill_level("factory_yield") >= 2 else 1.0
	return talent_mult * MetaProgression.get_factory_speed_mult()


func get_factory_bonus_output() -> int:
	return 1 if get_skill_level("factory_yield") >= 1 else 0


func get_crystal_bonus_multiplier() -> float:
	var talent_mult: float = 1.25 if get_skill_level("crystal_interest") >= 1 else 1.0
	return talent_mult * MetaProgression.get_crystal_reward_mult()


func get_kill_crystal_reward(base_reward: int) -> int:
	if base_reward <= 0:
		return 0
	var exact: float = float(base_reward) * MetaProgression.get_crystal_reward_mult()
	var whole: int = int(floor(exact))
	_kill_bonus_accum += exact - float(whole)
	if _kill_bonus_accum >= 0.999:
		_kill_bonus_accum -= 1.0
		whole += 1
	return whole


func get_transport_multiplier() -> float:
	return (1.0 + 0.3 * float(get_skill_level("transport_speed"))) * MetaProgression.get_transport_speed_mult()


func has_teleport_logistics() -> bool:
	return get_skill_level("teleport_logistics") >= 1


func get_storage_multiplier() -> float:
	return 1.0 + 0.5 * float(get_skill_level("storage_capacity"))


func get_bonus_storage_slots() -> int:
	return MetaProgression.get_bonus_storage_slots()


func get_bonus_link_radius_cells() -> float:
	return MetaProgression.get_bonus_link_radius_cells()


func get_effective_building_cost(base_cost: int) -> int:
	if base_cost <= 0:
		return 0
	return maxi(1, int(round(float(base_cost) * MetaProgression.get_building_cost_mult())))


func get_damage_multiplier() -> float:
	return (1.0 + 0.22 * float(get_skill_level("tower_damage"))) * MetaProgression.get_tower_damage_mult()


func get_tower_cooldown_multiplier() -> float:
	var talent_cd: float = maxf(0.55, 1.0 - 0.15 * float(get_skill_level("tower_fire_rate")))
	return maxf(0.4, talent_cd * MetaProgression.get_tower_cooldown_mult())


func get_tower_bonus_range_cells() -> float:
	var talent_rng: float = 0.4 if get_skill_level("tower_fire_rate") >= 2 else 0.0
	return talent_rng + MetaProgression.get_tower_bonus_range_cells()


func get_fortification_hp_multiplier() -> float:
	return 1.0 + 0.35 * float(get_skill_level("base_fortification"))


func get_base_day_regen_rate() -> float:
	return 6.0 * (1.0 + float(get_skill_level("base_fortification"))) + MetaProgression.get_base_day_regen_bonus()


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

	_reset_skills()
	var raw_skills: Variant = data.get("skills", {})
	if raw_skills is Dictionary:
		var sd: Dictionary = raw_skills
		for key in TALENT_ORDER:
			skills[key] = clampi(int(sd.get(key, 0)), 0, get_talent_max_level(key))

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
