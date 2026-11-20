class_name BuildingEntity
extends Node2D
## Постройка на 2D-сетке: База, шахта, транспортёр, завод, башня или стена.

var uid: int = 0
var grid_pos: Vector2i = Vector2i.ZERO
var config: BuildingConfig
var level: int = 1
var hp: float = 100.0
var max_hp: float = 100.0
var invested_crystals: int = 0
var input_storage: int = 0
var output_storage: int = 0
var transit_queue: Array[int] = []
var neighbors: Array[BuildingEntity] = []
var production_timer: float = 0.0
var transport_timer: float = 0.0
var attack_timer: float = 0.0
var turret_angle: float = 0.0
var is_selected: bool = false
var status_text: String = "Готово"
var cell_size: float = 48.0


func setup(p_uid: int, p_grid_pos: Vector2i, p_config: BuildingConfig, p_cell_size: float) -> void:
	uid = p_uid
	grid_pos = p_grid_pos
	config = p_config
	cell_size = p_cell_size
	level = 1
	max_hp = p_config.max_hp
	hp = max_hp
	invested_crystals = p_config.cost_crystals
	position = Vector2(
		(float(p_grid_pos.x) + 0.5) * cell_size,
		(float(p_grid_pos.y) + 0.5) * cell_size
	)
	queue_redraw()


func get_effective_storage_capacity() -> int:
	if config == null or config.storage_capacity <= 0:
		return 0
	var level_bonus: float = 1.0 + 0.25 * float(level - 1)
	return maxi(1, int(round(float(config.storage_capacity) * level_bonus * GameState.get_storage_multiplier())))


func get_effective_production_interval() -> float:
	if config == null:
		return 1.5
	var level_factor: float = 1.0 + 0.25 * float(level - 1)
	return maxf(0.2, config.production_interval / (level_factor * GameState.get_mining_multiplier()))


func get_effective_transport_interval() -> float:
	if config == null:
		return 0.45
	var level_factor: float = 1.0 + 0.28 * float(level - 1)
	return maxf(0.1, config.transport_interval / (level_factor * GameState.get_transport_multiplier()))


func get_effective_attack_damage() -> float:
	if config == null:
		return 0.0
	var level_factor: float = 1.0 + 0.35 * float(level - 1)
	return config.attack_damage * level_factor * GameState.get_damage_multiplier()


func get_effective_attack_range_px() -> float:
	if config == null:
		return 0.0
	return (config.attack_range_cells + 0.25 * float(level - 1)) * cell_size


func get_link_radius_px() -> float:
	if config == null:
		return 0.0
	return config.link_radius_cells * cell_size


func get_upgrade_cost() -> int:
	if config == null:
		return 999999
	return int(round(float(config.cost_crystals) * pow(1.65, level)))


func get_sell_refund() -> int:
	return int(floor(float(invested_crystals) * 0.5))


func apply_upgrade() -> void:
	var cost: int = get_upgrade_cost()
	invested_crystals += cost
	level += 1
	var hp_ratio: float = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	max_hp = config.max_hp * (1.0 + 0.35 * float(level - 1))
	hp = max_hp * maxf(hp_ratio, 0.85)
	queue_redraw()


func accept_incoming_resource(kind: int) -> bool:
	if config == null:
		return false
	if config.building_id == "base":
		if kind == BuildingConfig.ResourceKind.CRYSTAL:
			GameState.add_crystals(1)
			return true
		return false

	var cap: int = get_effective_storage_capacity()
	if config.category == BuildingConfig.Category.LOGISTICS:
		if transit_queue.size() >= cap:
			return false
		transit_queue.append(kind)
		queue_redraw()
		return true

	if kind == config.input_kind and input_storage < cap:
		input_storage += 1
		queue_redraw()
		return true
	return false


func take_damage(amount: float) -> bool:
	hp = maxf(0.0, hp - amount)
	queue_redraw()
	return hp <= 0.0


func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		queue_redraw()


func to_dict() -> Dictionary:
	return {
		"uid": uid,
		"building_id": config.building_id if config != null else "wall",
		"gx": grid_pos.x,
		"gy": grid_pos.y,
		"level": level,
		"hp": snappedf(hp, 0.1),
		"max_hp": snappedf(max_hp, 0.1),
		"invested": invested_crystals,
		"input": input_storage,
		"output": output_storage,
		"transit": transit_queue.duplicate(),
	}


func apply_saved_state(data: Dictionary) -> void:
	level = maxi(1, int(data.get("level", 1)))
	max_hp = maxf(10.0, float(data.get("max_hp", config.max_hp)))
	hp = clampf(float(data.get("hp", max_hp)), 1.0, max_hp)
	invested_crystals = maxi(config.cost_crystals, int(data.get("invested", config.cost_crystals)))
	input_storage = maxi(0, int(data.get("input", 0)))
	output_storage = maxi(0, int(data.get("output", 0)))
	transit_queue.clear()
	var raw_transit: Variant = data.get("transit", [])
	if raw_transit is Array:
		for item in raw_transit:
			transit_queue.append(int(item))
	queue_redraw()


func _draw() -> void:
	if config == null:
		return

	var half: float = cell_size * 0.42
	var rect := Rect2(-half, -half, half * 2.0, half * 2.0)

	# Подложка здания
	draw_rect(rect, Color(0.094, 0.133, 0.212, 0.96), true)
	var border_color: Color = Color(0.973, 0.98, 0.988, 1.0) if is_selected else config.accent_color
	var border_w: float = 3.0 if is_selected else 2.0
	draw_rect(rect, border_color, false, border_w)

	# Уникальная геометрия по категории
	match config.category:
		BuildingConfig.Category.CORE:
			draw_circle(Vector2.ZERO, half * 0.56, config.accent_color)
			draw_circle(Vector2.ZERO, half * 0.26, Color(0.973, 0.98, 0.988, 1.0))
		BuildingConfig.Category.HARVESTER:
			var pts := PackedVector2Array([
				Vector2(0, -half * 0.55),
				Vector2(half * 0.55, 0),
				Vector2(0, half * 0.55),
				Vector2(-half * 0.55, 0),
			])
			draw_colored_polygon(pts, config.accent_color)
		BuildingConfig.Category.LOGISTICS:
			draw_circle(Vector2.ZERO, half * 0.34, config.accent_color)
			draw_arc(Vector2.ZERO, half * 0.54, 0.0, TAU, 16, config.accent_color, 1.5, true)
		BuildingConfig.Category.FACTORY:
			var inner := Rect2(-half * 0.45, -half * 0.45, half * 0.9, half * 0.9)
			draw_rect(inner, config.accent_color, true)
			draw_circle(Vector2.ZERO, half * 0.2, Color(0.059, 0.09, 0.165, 1.0))
		BuildingConfig.Category.DEFENSE:
			if config.building_id == "wall":
				draw_rect(Rect2(-half * 0.72, -half * 0.72, half * 1.44, half * 1.44), config.accent_color, true)
			else:
				draw_circle(Vector2.ZERO, half * 0.38, config.accent_color)
				var barrel_dir := Vector2.from_angle(turret_angle)
				draw_line(Vector2.ZERO, barrel_dir * (half * 0.85), Color(0.973, 0.98, 0.988, 1.0), 4.0, true)

	# Полоска боеприпасов / склада
	var cap: int = get_effective_storage_capacity()
	if cap > 0 and config.building_id != "base":
		var fill_count: int = 0
		if config.category == BuildingConfig.Category.DEFENSE:
			fill_count = input_storage
		elif config.category == BuildingConfig.Category.LOGISTICS:
			fill_count = transit_queue.size()
		elif config.category == BuildingConfig.Category.FACTORY:
			fill_count = output_storage if output_storage > 0 else input_storage
		else:
			fill_count = output_storage
		var ratio: float = clampf(float(fill_count) / float(cap), 0.0, 1.0)
		var bar_w: float = half * 1.7
		draw_rect(Rect2(-bar_w * 0.5, half - 5.0, bar_w, 3.0), Color(0.05, 0.07, 0.12, 0.9), true)
		if ratio > 0.0:
			draw_rect(Rect2(-bar_w * 0.5, half - 5.0, bar_w * ratio, 3.0), config.accent_color, true)

	# Полоска HP (при повреждении или у Базы)
	if hp < max_hp or config.building_id == "base":
		var hp_ratio: float = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
		var hp_w: float = half * 1.8
		draw_rect(Rect2(-hp_w * 0.5, -half - 6.0, hp_w, 3.5), Color(0.15, 0.05, 0.05, 0.9), true)
		var hp_col: Color = Color(0.133, 0.773, 0.369, 1.0) if hp_ratio > 0.45 else Color(0.937, 0.267, 0.267, 1.0)
		draw_rect(Rect2(-hp_w * 0.5, -half - 6.0, hp_w * hp_ratio, 3.5), hp_col, true)

	# Бейдж уровня
	if level > 1 or config.building_id == "base":
		var font: Font = ThemeDB.fallback_font
		if font != null:
			draw_string(font, Vector2(-half + 2.0, -half + 11.0), "L%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.973, 0.98, 0.988, 0.95))
