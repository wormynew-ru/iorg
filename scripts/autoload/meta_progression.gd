extends Node
## Мета-прогрессия между забегами: награды после забега, Сад растений и система Артефактов (user://saves/meta.json).

const META_DIR: String = "user://saves"
const META_PATH: String = "user://saves/meta.json"
const META_VERSION: int = 1

const MAX_PLOTS: int = 6
const PLOT_UNLOCK_COSTS: Array[int] = [0, 0, 0, 65, 135, 240]
const MAX_ARTIFACT_SLOTS: int = 3
const ARTIFACT_SLOT_COSTS: Array[int] = [0, 0, 160]

const PLANT_ORDER: Array[String] = [
	"crystal_lotus", "sun_sprout", "thorn_briar",
	"iron_bamboo", "mercury_clover", "gold_fern",
]

const PLANT_DEFS: Dictionary = {
	"crystal_lotus": {
		"title": "Кристальный лотос",
		"short_title": "Лотос",
		"color": Color(0.937, 0.267, 0.267, 1.0),
		"plant_seeds": 1,
		"plant_essence": 10,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [35, 80],
		"max_level": 3,
		"levels_text": ["+35 старт. кр.", "+75 старт. кр.", "+125 старт. кр."],
		"description": "Даёт дополнительные кристаллы на старте каждого забега (эффекты грядок суммируются).",
	},
	"sun_sprout": {
		"title": "Солнечный росток",
		"short_title": "Росток",
		"color": Color(0.961, 0.62, 0.043, 1.0),
		"plant_seeds": 1,
		"plant_essence": 15,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [40, 90],
		"max_level": 3,
		"levels_text": ["+8% добыча/заводы", "+16% добыча/заводы", "+26% добыча/заводы"],
		"description": "Ускоряет добычу всех шахт и переработку на заводах.",
	},
	"thorn_briar": {
		"title": "Огненный шиповник",
		"short_title": "Шиповник",
		"color": Color(0.976, 0.451, 0.086, 1.0),
		"plant_seeds": 1,
		"plant_essence": 15,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [45, 95],
		"max_level": 3,
		"levels_text": ["+8% урон башен", "+16% урон башен", "+26% урон башен"],
		"description": "Увеличивает урон всех оборонительных башен (лук, пушка, молния).",
	},
	"iron_bamboo": {
		"title": "Железный бамбук",
		"short_title": "Бамбук",
		"color": Color(0.58, 0.639, 0.722, 1.0),
		"plant_seeds": 1,
		"plant_essence": 15,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [40, 90],
		"max_level": 3,
		"levels_text": ["+60 HP Базы, +10% стен", "+130 HP Базы, +20% стен", "+220 HP Базы, +32% стен"],
		"description": "Укрепляет Базу и стены, а также слегка усиливает дневную регенерацию Базы.",
	},
	"mercury_clover": {
		"title": "Ртутный клевер",
		"short_title": "Клевер",
		"color": Color(0.133, 0.827, 0.933, 1.0),
		"plant_seeds": 1,
		"plant_essence": 15,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [40, 90],
		"max_level": 3,
		"levels_text": ["+10% логистика, +1 склад", "+20% логистика, +2 склада", "+32% логистика, +4 склада"],
		"description": "Ускоряет транспорт грузов и расширяет вместимость складов, транспортёров и башен.",
	},
	"gold_fern": {
		"title": "Золотой папоротник",
		"short_title": "Папорот.",
		"color": Color(0.133, 0.773, 0.369, 1.0),
		"plant_seeds": 1,
		"plant_essence": 20,
		"upgrade_seeds": [1, 2],
		"upgrade_essence": [50, 105],
		"max_level": 3,
		"levels_text": ["+10% крист. волн, +15% эсс.", "+20% крист. волн, +30% эсс.", "+35% крист. волн, +50% эсс."],
		"description": "Повышает награду кристаллами за ночи и эссенцию после окончания забега.",
	},
}

const ARTIFACT_ORDER: Array[String] = [
	"core_shard", "chrono_gear", "logistics_magnet",
	"storm_capacitor", "greed_ruby", "engineer_seal",
]

const ARTIFACT_DEFS: Dictionary = {
	"core_shard": {
		"title": "Осколок Ядра",
		"color": Color(0.133, 0.827, 0.933, 1.0),
		"craft_essence": 70,
		"upgrade_essence": [110, 200],
		"max_level": 3,
		"levels_text": ["+50 кр. старта, +10% HP Базы", "+110 кр. старта, +18% HP Базы", "+180 кр. старта, +28% HP Базы"],
		"description": "Древний фрагмент Базы: увеличивает стартовый запас кристаллов и броню Базы.",
	},
	"chrono_gear": {
		"title": "Шестерня Хроноса",
		"color": Color(0.961, 0.62, 0.043, 1.0),
		"craft_essence": 85,
		"upgrade_essence": [130, 230],
		"max_level": 3,
		"levels_text": ["+12% заводы, -8% кд башен", "+22% заводы, -15% кд башен", "+35% заводы, -22% кд башен"],
		"description": "Ускоряет циклы заводов и сокращает задержку между выстрелами всех башен.",
	},
	"logistics_magnet": {
		"title": "Магнит логиста",
		"color": Color(0.22, 0.741, 0.973, 1.0),
		"craft_essence": 80,
		"upgrade_essence": [125, 220],
		"max_level": 3,
		"levels_text": ["+15% грузы, +0.5 радиус связей", "+28% грузы, +1.0 радиус связей", "+45% грузы, +1.5 радиус связей"],
		"description": "Ускоряет переброску ресурсов и увеличивает дистанцию связи между зданиями.",
	},
	"storm_capacitor": {
		"title": "Грозовой конденсатор",
		"color": Color(0.655, 0.545, 0.98, 1.0),
		"craft_essence": 90,
		"upgrade_essence": [135, 240],
		"max_level": 3,
		"levels_text": ["+12% урон, +0.35 дальность", "+24% урон, +0.7 дальность", "+38% урон, +1.1 дальность"],
		"description": "Повышает огневую мощь и радиус атаки всех оборонительных башен.",
	},
	"greed_ruby": {
		"title": "Рубин жадности",
		"color": Color(0.937, 0.267, 0.267, 1.0),
		"craft_essence": 85,
		"upgrade_essence": [130, 230],
		"max_level": 3,
		"levels_text": ["+15% кр. за ночи/убийства", "+30% кр. за ночи/убийства", "+50% кр. за ночи/убийства"],
		"description": "Увеличивает приток кристаллов за пережитые волны и уничтожение зомби.",
	},
	"engineer_seal": {
		"title": "Печать инженера",
		"color": Color(0.133, 0.773, 0.369, 1.0),
		"craft_essence": 100,
		"upgrade_essence": [150, 260],
		"max_level": 3,
		"levels_text": ["-6% цена стройки и апгрейдов", "-12% цена стройки и апгрейдов", "-18% цена стройки и апгрейдов"],
		"description": "Снижает стоимость постройки и улучшения всех зданий в кристаллах.",
	},
}

var essence: int = 0
var seeds: int = 0
var best_day: int = 0
var total_runs: int = 0
var total_kills: int = 0
var unlocked_plot_count: int = 3
var garden_plots: Array[Dictionary] = []
var artifacts_owned: Dictionary = {} # artifact_id -> level (0..3)
var equipped_artifacts: Array[String] = []
var unlocked_artifact_slots: int = 2


func _ready() -> void:
	_init_defaults()
	load_meta()


func _init_defaults() -> void:
	essence = 0
	seeds = 0
	best_day = 0
	total_runs = 0
	total_kills = 0
	unlocked_plot_count = 3
	unlocked_artifact_slots = 2
	garden_plots.clear()
	for i in range(MAX_PLOTS):
		garden_plots.append({"plant_id": "", "level": 0})
	artifacts_owned.clear()
	for aid in ARTIFACT_ORDER:
		artifacts_owned[aid] = 0
	equipped_artifacts.clear()


func save_meta() -> bool:
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(META_DIR)
	if dir_err != OK:
		return false
	var payload: Dictionary = {
		"meta_version": META_VERSION,
		"essence": essence,
		"seeds": seeds,
		"best_day": best_day,
		"total_runs": total_runs,
		"total_kills": total_kills,
		"unlocked_plot_count": unlocked_plot_count,
		"garden_plots": garden_plots.duplicate(true),
		"artifacts_owned": artifacts_owned.duplicate(true),
		"equipped_artifacts": equipped_artifacts.duplicate(),
		"unlocked_artifact_slots": unlocked_artifact_slots,
	}
	var file: FileAccess = FileAccess.open(META_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_meta() -> void:
	_init_defaults()
	if not FileAccess.file_exists(META_PATH):
		return
	var file: FileAccess = FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		return
	var raw: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(raw) != OK or not (json.data is Dictionary):
		return
	var data: Dictionary = json.data
	if int(data.get("meta_version", 0)) != META_VERSION:
		return

	essence = maxi(0, int(data.get("essence", 0)))
	seeds = maxi(0, int(data.get("seeds", 0)))
	best_day = maxi(0, int(data.get("best_day", 0)))
	total_runs = maxi(0, int(data.get("total_runs", 0)))
	total_kills = maxi(0, int(data.get("total_kills", 0)))
	unlocked_plot_count = clampi(int(data.get("unlocked_plot_count", 3)), 3, MAX_PLOTS)
	unlocked_artifact_slots = clampi(int(data.get("unlocked_artifact_slots", 2)), 2, MAX_ARTIFACT_SLOTS)

	var raw_plots: Variant = data.get("garden_plots", [])
	if raw_plots is Array:
		var arr: Array = raw_plots
		for i in range(mini(MAX_PLOTS, arr.size())):
			if arr[i] is Dictionary:
				var pd: Dictionary = arr[i]
				var pid: String = str(pd.get("plant_id", ""))
				var lvl: int = int(pd.get("level", 0))
				if PLANT_DEFS.has(pid) and lvl > 0:
					garden_plots[i] = {"plant_id": pid, "level": clampi(lvl, 1, 3)}
				else:
					garden_plots[i] = {"plant_id": "", "level": 0}

	var raw_art: Variant = data.get("artifacts_owned", {})
	if raw_art is Dictionary:
		var ad: Dictionary = raw_art
		for aid in ARTIFACT_ORDER:
			artifacts_owned[aid] = clampi(int(ad.get(aid, 0)), 0, 3)

	equipped_artifacts.clear()
	var raw_eq: Variant = data.get("equipped_artifacts", [])
	if raw_eq is Array:
		for item in raw_eq:
			var aid: String = str(item)
			if is_artifact_owned(aid) and not equipped_artifacts.has(aid) and equipped_artifacts.size() < unlocked_artifact_slots:
				equipped_artifacts.append(aid)


func process_run_finished(days_survived: int, kills: int) -> Dictionary:
	total_runs += 1
	total_kills += maxi(0, kills)
	var is_new_record: bool = days_survived > best_day
	if is_new_record:
		best_day = days_survived

	var bosses_cleared: int = int(days_survived / 10)
	var base_essence: float = float(days_survived * 10) + float(kills) * 0.4 + float(bosses_cleared * 30)
	var gained_essence: int = maxi(8, int(round(base_essence * get_meta_essence_mult())))
	var gained_seeds: int = 1 + int(days_survived / 3)

	var dropped_artifact_id: String = ""
	var unowned: Array[String] = []
	for aid in ARTIFACT_ORDER:
		if not is_artifact_owned(aid):
			unowned.append(aid)

	if not unowned.is_empty() and days_survived >= 2:
		var first_artifact_bonus: bool = (unowned.size() == ARTIFACT_ORDER.size() and days_survived >= 2)
		var boss_guaranteed: bool = (days_survived >= 10)
		var drop_chance: float = clampf(0.28 + float(days_survived) * 0.08, 0.28, 0.95)
		if first_artifact_bonus or boss_guaranteed or randf() <= drop_chance:
			dropped_artifact_id = unowned[randi() % unowned.size()]
			artifacts_owned[dropped_artifact_id] = 1
			if equipped_artifacts.size() < unlocked_artifact_slots and not equipped_artifacts.has(dropped_artifact_id):
				equipped_artifacts.append(dropped_artifact_id)
	elif unowned.is_empty() and days_survived >= 5:
		gained_essence += 20

	essence += gained_essence
	seeds += gained_seeds
	save_meta()
	EventBus.meta_progression_changed.emit()

	return {
		"essence_gained": gained_essence,
		"seeds_gained": gained_seeds,
		"dropped_artifact_id": dropped_artifact_id,
		"is_new_record": is_new_record,
		"best_day": best_day,
	}


# --- Сад (Garden) ---

func get_next_plot_unlock_cost() -> int:
	if unlocked_plot_count >= MAX_PLOTS:
		return -1
	return PLOT_UNLOCK_COSTS[unlocked_plot_count]


func unlock_next_plot() -> bool:
	var cost: int = get_next_plot_unlock_cost()
	if cost < 0 or essence < cost:
		return false
	essence -= cost
	unlocked_plot_count += 1
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


func plant_on_plot(plot_idx: int, plant_id: String) -> bool:
	if plot_idx < 0 or plot_idx >= unlocked_plot_count:
		return false
	if not PLANT_DEFS.has(plant_id):
		return false
	var current: Dictionary = garden_plots[plot_idx]
	if not str(current.get("plant_id", "")).is_empty():
		return false
	var def: Dictionary = PLANT_DEFS[plant_id] as Dictionary
	var req_seeds: int = int(def.get("plant_seeds", 1))
	var req_ess: int = int(def.get("plant_essence", 10))
	if seeds < req_seeds or essence < req_ess:
		return false
	seeds -= req_seeds
	essence -= req_ess
	garden_plots[plot_idx] = {"plant_id": plant_id, "level": 1}
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


func get_plot_upgrade_cost(plot_idx: int) -> Dictionary:
	if plot_idx < 0 or plot_idx >= unlocked_plot_count:
		return {"valid": false, "seeds": 0, "essence": 0}
	var current: Dictionary = garden_plots[plot_idx]
	var pid: String = str(current.get("plant_id", ""))
	var lvl: int = int(current.get("level", 0))
	if pid.is_empty() or not PLANT_DEFS.has(pid):
		return {"valid": false, "seeds": 0, "essence": 0}
	var def: Dictionary = PLANT_DEFS[pid] as Dictionary
	var max_lvl: int = int(def.get("max_level", 3))
	if lvl >= max_lvl:
		return {"valid": false, "seeds": 0, "essence": 0}
	var idx: int = lvl - 1
	var u_seeds: Array = def.get("upgrade_seeds", []) as Array
	var u_ess: Array = def.get("upgrade_essence", []) as Array
	if idx < 0 or idx >= u_seeds.size() or idx >= u_ess.size():
		return {"valid": false, "seeds": 0, "essence": 0}
	return {"valid": true, "seeds": int(u_seeds[idx]), "essence": int(u_ess[idx])}


func upgrade_plot(plot_idx: int) -> bool:
	var cost: Dictionary = get_plot_upgrade_cost(plot_idx)
	if not bool(cost.get("valid", false)):
		return false
	var req_seeds: int = int(cost.get("seeds", 0))
	var req_ess: int = int(cost.get("essence", 0))
	if seeds < req_seeds or essence < req_ess:
		return false
	seeds -= req_seeds
	essence -= req_ess
	garden_plots[plot_idx]["level"] = int(garden_plots[plot_idx]["level"]) + 1
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


func uproot_plot(plot_idx: int) -> bool:
	if plot_idx < 0 or plot_idx >= unlocked_plot_count:
		return false
	var current: Dictionary = garden_plots[plot_idx]
	if str(current.get("plant_id", "")).is_empty():
		return false
	garden_plots[plot_idx] = {"plant_id": "", "level": 0}
	seeds += 1
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


# --- Артефакты (Artifacts) ---

func is_artifact_owned(artifact_id: String) -> bool:
	return get_artifact_level(artifact_id) > 0


func get_artifact_level(artifact_id: String) -> int:
	return int(artifacts_owned.get(artifact_id, 0))


func is_artifact_equipped(artifact_id: String) -> bool:
	return equipped_artifacts.has(artifact_id)


func get_next_artifact_slot_cost() -> int:
	if unlocked_artifact_slots >= MAX_ARTIFACT_SLOTS:
		return -1
	return ARTIFACT_SLOT_COSTS[unlocked_artifact_slots]


func unlock_next_artifact_slot() -> bool:
	var cost: int = get_next_artifact_slot_cost()
	if cost < 0 or essence < cost:
		return false
	essence -= cost
	unlocked_artifact_slots += 1
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


func get_artifact_action_cost(artifact_id: String) -> int:
	if not ARTIFACT_DEFS.has(artifact_id):
		return -1
	var def: Dictionary = ARTIFACT_DEFS[artifact_id] as Dictionary
	var lvl: int = get_artifact_level(artifact_id)
	var max_lvl: int = int(def.get("max_level", 3))
	if lvl <= 0:
		return int(def.get("craft_essence", 80))
	if lvl >= max_lvl:
		return -1
	var u_ess: Array = def.get("upgrade_essence", []) as Array
	var idx: int = lvl - 1
	if idx < 0 or idx >= u_ess.size():
		return -1
	return int(u_ess[idx])


func craft_or_upgrade_artifact(artifact_id: String) -> bool:
	var cost: int = get_artifact_action_cost(artifact_id)
	if cost < 0 or essence < cost:
		return false
	essence -= cost
	var next_lvl: int = get_artifact_level(artifact_id) + 1
	artifacts_owned[artifact_id] = next_lvl
	if next_lvl == 1 and equipped_artifacts.size() < unlocked_artifact_slots and not equipped_artifacts.has(artifact_id):
		equipped_artifacts.append(artifact_id)
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


func toggle_equip_artifact(artifact_id: String) -> bool:
	if not is_artifact_owned(artifact_id):
		return false
	if equipped_artifacts.has(artifact_id):
		equipped_artifacts.erase(artifact_id)
	else:
		if equipped_artifacts.size() >= unlocked_artifact_slots:
			return false
		equipped_artifacts.append(artifact_id)
	save_meta()
	EventBus.meta_progression_changed.emit()
	return true


# --- Суммарные бонусы для забега ---

func _sum_plant_levels(target_plant_id: String, table: Array[float]) -> float:
	var total: float = 0.0
	for i in range(unlocked_plot_count):
		var p: Dictionary = garden_plots[i]
		if str(p.get("plant_id", "")) == target_plant_id:
			var lvl: int = clampi(int(p.get("level", 0)), 1, table.size())
			total += table[lvl - 1]
	return total


func _get_equipped_artifact_value(artifact_id: String, table: Array[float]) -> float:
	if not is_artifact_equipped(artifact_id):
		return 0.0
	var lvl: int = get_artifact_level(artifact_id)
	if lvl <= 0:
		return 0.0
	return table[clampi(lvl, 1, table.size()) - 1]


func get_bonus_starting_crystals() -> int:
	var from_garden: float = _sum_plant_levels("crystal_lotus", [35.0, 75.0, 125.0])
	var from_art: float = _get_equipped_artifact_value("core_shard", [50.0, 110.0, 180.0])
	return int(round(from_garden + from_art))


func get_mining_speed_mult() -> float:
	return 1.0 + _sum_plant_levels("sun_sprout", [0.08, 0.16, 0.26])


func get_factory_speed_mult() -> float:
	return 1.0 + _sum_plant_levels("sun_sprout", [0.08, 0.16, 0.26]) + _get_equipped_artifact_value("chrono_gear", [0.12, 0.22, 0.35])


func get_tower_damage_mult() -> float:
	return 1.0 + _sum_plant_levels("thorn_briar", [0.08, 0.16, 0.26]) + _get_equipped_artifact_value("storm_capacitor", [0.12, 0.24, 0.38])


func get_tower_cooldown_mult() -> float:
	return maxf(0.65, 1.0 - _get_equipped_artifact_value("chrono_gear", [0.08, 0.15, 0.22]))


func get_tower_bonus_range_cells() -> float:
	return _get_equipped_artifact_value("storm_capacitor", [0.35, 0.7, 1.1])


func get_base_bonus_hp() -> float:
	return _sum_plant_levels("iron_bamboo", [60.0, 130.0, 220.0])


func get_base_hp_mult() -> float:
	return 1.0 + _get_equipped_artifact_value("core_shard", [0.10, 0.18, 0.28])


func get_wall_hp_mult() -> float:
	return 1.0 + _sum_plant_levels("iron_bamboo", [0.10, 0.20, 0.32])


func get_base_day_regen_bonus() -> float:
	return _sum_plant_levels("iron_bamboo", [1.5, 3.0, 5.0])


func get_transport_speed_mult() -> float:
	return 1.0 + _sum_plant_levels("mercury_clover", [0.10, 0.20, 0.32]) + _get_equipped_artifact_value("logistics_magnet", [0.15, 0.28, 0.45])


func get_bonus_storage_slots() -> int:
	return int(round(_sum_plant_levels("mercury_clover", [1.0, 2.0, 4.0])))


func get_bonus_link_radius_cells() -> float:
	return _get_equipped_artifact_value("logistics_magnet", [0.5, 1.0, 1.5])


func get_crystal_reward_mult() -> float:
	return 1.0 + _sum_plant_levels("gold_fern", [0.10, 0.20, 0.35]) + _get_equipped_artifact_value("greed_ruby", [0.15, 0.30, 0.50])


func get_building_cost_mult() -> float:
	return maxf(0.7, 1.0 - _get_equipped_artifact_value("engineer_seal", [0.06, 0.12, 0.18]))


func get_meta_essence_mult() -> float:
	return 1.0 + _sum_plant_levels("gold_fern", [0.15, 0.30, 0.50])


func get_active_bonuses_summary() -> Array[String]:
	var lines: Array[String] = []
	var start_cr: int = get_bonus_starting_crystals()
	if start_cr > 0:
		lines.append("+%d старт. кр." % start_cr)
	var mine_pct: int = int(round((get_mining_speed_mult() - 1.0) * 100.0))
	if mine_pct > 0:
		lines.append("+%d%% добыча" % mine_pct)
	var fac_pct: int = int(round((get_factory_speed_mult() - 1.0) * 100.0))
	if fac_pct > 0:
		lines.append("+%d%% заводы" % fac_pct)
	var dmg_pct: int = int(round((get_tower_damage_mult() - 1.0) * 100.0))
	if dmg_pct > 0:
		lines.append("+%d%% урон башен" % dmg_pct)
	var cd_pct: int = int(round((1.0 - get_tower_cooldown_mult()) * 100.0))
	if cd_pct > 0:
		lines.append("+%d%% темп огня" % cd_pct)
	var rng: float = get_tower_bonus_range_cells()
	if rng > 0.01:
		lines.append("+%.2f дальность" % rng)
	var base_hp: int = int(round(get_base_bonus_hp()))
	var base_pct: int = int(round((get_base_hp_mult() - 1.0) * 100.0))
	if base_hp > 0 or base_pct > 0:
		lines.append("База +%d HP / +%d%%" % [base_hp, base_pct])
	var log_pct: int = int(round((get_transport_speed_mult() - 1.0) * 100.0))
	if log_pct > 0:
		lines.append("+%d%% логистика" % log_pct)
	var slots: int = get_bonus_storage_slots()
	if slots > 0:
		lines.append("+%d склад" % slots)
	var link_r: float = get_bonus_link_radius_cells()
	if link_r > 0.01:
		lines.append("+%.1f связь" % link_r)
	var rew_pct: int = int(round((get_crystal_reward_mult() - 1.0) * 100.0))
	if rew_pct > 0:
		lines.append("+%d%% крист. волн" % rew_pct)
	var disc_pct: int = int(round((1.0 - get_building_cost_mult()) * 100.0))
	if disc_pct > 0:
		lines.append("-%d%% цена зданий" % disc_pct)
	var ess_pct: int = int(round((get_meta_essence_mult() - 1.0) * 100.0))
	if ess_pct > 0:
		lines.append("+%d%% эссенции" % ess_pct)
	if lines.is_empty():
		lines.append("Бонусы ещё не активны — посадите растения или наденьте артефакты")
	return lines
