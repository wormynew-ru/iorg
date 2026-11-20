extends Node2D
## Основной игровой контроллер YORG.io-подобной стратегии (сетка, логистика, волны, сохранения).

@export var balance: WorldBalanceConfig

@onready var _camera: StrategicCamera = $World/StrategicCamera
@onready var _overlay: LogisticsOverlay = $World/LogisticsOverlay
@onready var _buildings_layer: Node2D = $World/BuildingsLayer
@onready var _enemies_layer: Node2D = $World/EnemiesLayer
@onready var _hud: CanvasLayer = $HUD
@onready var _pause_menu: Control = $PauseLayer/PauseMenu
@onready var _settings_modal: Control = $PauseLayer/SettingsModal
@onready var _skill_tree_modal: Control = $PauseLayer/SkillTreeModal
@onready var _game_over_modal: Control = $PauseLayer/GameOverModal

var _building_configs: Dictionary = {}
var _enemy_configs: Dictionary = {}
var _veins: Dictionary = {} # Vector2i -> int (BuildingConfig.VeinType)
var _grid_buildings: Dictionary = {} # Vector2i -> BuildingEntity
var _buildings_by_uid: Dictionary = {} # int -> BuildingEntity
var _buildings_list: Array[BuildingEntity] = []
var _enemies: Array[EnemyEntity] = []
var _base_building: BuildingEntity = null
var _base_cell: Vector2i = Vector2i(18, 12)
var _next_uid: int = 1

var _astar: AStarGrid2D = AStarGrid2D.new()
var _active_build_id: String = ""
var _selected_building: BuildingEntity = null

var _wave_spawn_queue: Array[String] = []
var _wave_spawn_timer: float = 0.0
var _wave_spawn_interval: float = 1.0


func _ready() -> void:
	add_to_group("game_arena")
	get_tree().paused = false
	if balance == null:
		balance = load("res://resources/balance/default_world_balance.tres") as WorldBalanceConfig
	if balance == null:
		balance = WorldBalanceConfig.new()

	_load_catalogs()
	_setup_astar()
	_setup_camera()
	_generate_veins(GameState.map_seed)

	if GameState.should_load_from_save and not GameState.saved_buildings.is_empty():
		_restore_buildings_from_state()
		if GameState.has_saved_camera:
			_camera.center_on(GameState.camera_position)
			_camera.zoom = Vector2(GameState.camera_zoom, GameState.camera_zoom)
	else:
		_place_initial_base()

	GameState.should_load_from_save = false
	_rebuild_network_and_paths()
	_connect_signals()
	_sync_overlay()
	_emit_hud_snapshots()


func _process(delta: float) -> void:
	_update_hover_preview()
	_update_visual_fx(delta)

	if GameState.sim_paused or GameState.is_game_over:
		return

	_update_phase(delta)
	_update_buildings_simulation(delta)
	_update_packets(delta)
	_update_enemies(delta)
	_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _game_over_modal.visible:
			return
		if _settings_modal.visible:
			_settings_modal.hide_modal()
		elif _skill_tree_modal.visible:
			_skill_tree_modal.hide_modal()
		else:
			_set_pause_menu_open(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("sim_pause") and not get_tree().paused and not GameState.is_game_over:
		_toggle_sim_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel_build") and not get_tree().paused:
		_cancel_active_tool_or_selection()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if not GameState.is_game_over:
			SaveManager.save_game()


func sync_buildings_to_state() -> void:
	var serialized: Array = []
	for b in _buildings_list:
		if is_instance_valid(b):
			serialized.append(b.to_dict())
	GameState.saved_buildings = serialized


func get_building_configs_ordered() -> Array[BuildingConfig]:
	var ids: Array[String] = [
		"crystal_mine", "sawmill", "iron_mine", "uranium_mine",
		"transporter", "arrow_factory", "cannon_factory", "reactor",
		"arrow_tower", "cannon_tower", "lightning_tower", "wall"
	]
	var out: Array[BuildingConfig] = []
	for id in ids:
		if _building_configs.has(id):
			out.append(_building_configs[id] as BuildingConfig)
	return out


func set_build_tool(building_id: String) -> void:
	if _active_build_id == building_id:
		_active_build_id = ""
	else:
		_active_build_id = building_id
		_select_building(null)
	EventBus.build_tool_changed.emit(_active_build_id)
	_sync_overlay()


func skip_day_to_night() -> void:
	if GameState.is_night or GameState.sim_paused or GameState.is_game_over:
		return
	GameState.phase_timer = 0.0
	_start_night_phase()


func upgrade_selected_building() -> void:
	if not is_instance_valid(_selected_building) or GameState.sim_paused or GameState.is_game_over:
		return
	var b: BuildingEntity = _selected_building
	if b.config.building_id != "base" and b.level >= GameState.base_level:
		return
	var cost: int = b.get_upgrade_cost()
	if not GameState.spend_crystals(cost):
		return

	b.apply_upgrade()
	if b.config.building_id == "base":
		GameState.base_level = b.level
		GameState.base_max_hp = b.max_hp
		GameState.base_hp = b.hp
		EventBus.base_status_changed.emit(GameState.base_level, GameState.base_hp, GameState.base_max_hp)

	EventBus.building_selected.emit(b)
	_overlay.queue_redraw()


func sell_selected_building() -> void:
	if not is_instance_valid(_selected_building) or GameState.sim_paused or GameState.is_game_over:
		return
	var b: BuildingEntity = _selected_building
	if b.config.building_id == "base":
		return
	var refund: int = b.get_sell_refund()
	GameState.add_crystals(refund)
	_remove_building(b)
	_select_building(null)


func _load_catalogs() -> void:
	var b_paths: Array[String] = [
		"base", "crystal_mine", "sawmill", "iron_mine", "uranium_mine",
		"transporter", "arrow_factory", "cannon_factory", "reactor",
		"arrow_tower", "cannon_tower", "lightning_tower", "wall"
	]
	for id in b_paths:
		var res: BuildingConfig = load("res://resources/buildings/%s.tres" % id) as BuildingConfig
		if res != null:
			_building_configs[id] = res

	for eid in ["zombie_basic", "zombie_fast", "zombie_tank", "zombie_boss"]:
		var eres: EnemyConfig = load("res://resources/enemies/%s.tres" % eid) as EnemyConfig
		if eres != null:
			_enemy_configs[eid] = eres


func _setup_astar() -> void:
	_astar.region = Rect2i(0, 0, balance.grid_width, balance.grid_height)
	_astar.cell_size = Vector2(balance.cell_size, balance.cell_size)
	_astar.offset = Vector2(balance.cell_size * 0.5, balance.cell_size * 0.5)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()


func _setup_camera() -> void:
	var world_w: float = float(balance.grid_width) * balance.cell_size
	var world_h: float = float(balance.grid_height) * balance.cell_size
	_camera.configure_bounds(Rect2(0.0, 0.0, world_w, world_h))
	_camera.center_on((Vector2(_base_cell) + Vector2(0.5, 0.5)) * balance.cell_size)
	_camera.world_tapped.connect(_on_world_tapped)
	_camera.secondary_tapped.connect(_cancel_active_tool_or_selection)


func _generate_veins(seed_val: int) -> void:
	_veins.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Гарантированные стартовые жилы рядом с Базой
	var starter_offsets: Array[Array] = [
		[Vector2i(-3, -2), BuildingConfig.VeinType.CRYSTAL],
		[Vector2i(3, 2), BuildingConfig.VeinType.CRYSTAL],
		[Vector2i(-3, 2), BuildingConfig.VeinType.WOOD],
		[Vector2i(3, -2), BuildingConfig.VeinType.WOOD],
		[Vector2i(0, -5), BuildingConfig.VeinType.IRON],
		[Vector2i(0, 5), BuildingConfig.VeinType.IRON],
		[Vector2i(-6, 0), BuildingConfig.VeinType.URANIUM],
	]
	for entry in starter_offsets:
		var cell: Vector2i = _base_cell + (entry[0] as Vector2i)
		if _is_in_bounds(cell) and cell != _base_cell:
			_veins[cell] = int(entry[1])

	_scatter_veins(rng, BuildingConfig.VeinType.CRYSTAL, maxi(0, balance.crystal_vein_count - 2), 3, 14)
	_scatter_veins(rng, BuildingConfig.VeinType.WOOD, maxi(0, balance.wood_vein_count - 2), 3, 14)
	_scatter_veins(rng, BuildingConfig.VeinType.IRON, maxi(0, balance.iron_vein_count - 2), 5, 15)
	_scatter_veins(rng, BuildingConfig.VeinType.URANIUM, maxi(0, balance.uranium_vein_count - 1), 7, 16)


func _scatter_veins(rng: RandomNumberGenerator, vein_type: int, count: int, min_dist: int, max_dist: int) -> void:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < 400:
		attempts += 1
		var cell := Vector2i(rng.randi_range(2, balance.grid_width - 3), rng.randi_range(2, balance.grid_height - 3))
		if _veins.has(cell) or cell == _base_cell:
			continue
		var dist: int = absi(cell.x - _base_cell.x) + absi(cell.y - _base_cell.y)
		if dist < min_dist or dist > max_dist:
			continue
		var too_close: bool = false
		for existing in _veins.keys():
			if absi(cell.x - existing.x) + absi(cell.y - existing.y) <= 2:
				too_close = true
				break
		if too_close:
			continue
		_veins[cell] = vein_type
		placed += 1


func _place_initial_base() -> void:
	var base_cfg: BuildingConfig = _building_configs.get("base") as BuildingConfig
	if base_cfg != null:
		_base_building = _spawn_building(_base_cell, base_cfg)
		GameState.base_level = _base_building.level
		GameState.base_max_hp = _base_building.max_hp
		GameState.base_hp = _base_building.hp


func _restore_buildings_from_state() -> void:
	var max_uid: int = 0
	for item in GameState.saved_buildings:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		var b_id: String = str(d.get("building_id", ""))
		var cfg: BuildingConfig = _building_configs.get(b_id) as BuildingConfig
		if cfg == null:
			continue
		var cell := Vector2i(int(d.get("gx", 0)), int(d.get("gy", 0)))
		if not _is_in_bounds(cell) or _grid_buildings.has(cell):
			continue
		var saved_uid: int = int(d.get("uid", _next_uid))
		max_uid = maxi(max_uid, saved_uid)
		var b: BuildingEntity = _spawn_building(cell, cfg, saved_uid)
		b.apply_saved_state(d)
		if b_id == "base":
			_base_building = b
			_base_cell = cell
			GameState.base_level = b.level
			GameState.base_max_hp = b.max_hp
			GameState.base_hp = b.hp
	_next_uid = max_uid + 1
	if _base_building == null:
		_place_initial_base()


func _spawn_building(cell: Vector2i, cfg: BuildingConfig, forced_uid: int = -1) -> BuildingEntity:
	var b := BuildingEntity.new()
	var assigned_uid: int = forced_uid if forced_uid > 0 else _next_uid
	if forced_uid <= 0:
		_next_uid += 1
	b.setup(assigned_uid, cell, cfg, balance.cell_size)
	_buildings_layer.add_child(b)
	_grid_buildings[cell] = b
	_buildings_by_uid[b.uid] = b
	_buildings_list.append(b)
	return b


func _remove_building(b: BuildingEntity) -> void:
	if b == _selected_building:
		_selected_building = null
		EventBus.building_selected.emit(null)
	_grid_buildings.erase(b.grid_pos)
	_buildings_by_uid.erase(b.uid)
	_buildings_list.erase(b)
	b.queue_free()
	_rebuild_network_and_paths()
	_sync_overlay()


func _rebuild_network_and_paths() -> void:
	for b in _buildings_list:
		if is_instance_valid(b):
			b.neighbors.clear()

	for i in range(_buildings_list.size()):
		var a: BuildingEntity = _buildings_list[i]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, _buildings_list.size()):
			var b: BuildingEntity = _buildings_list[j]
			if not is_instance_valid(b):
				continue
			if _can_link(a, b):
				a.neighbors.append(b)
				b.neighbors.append(a)

	# Веса для AStarGrid2D: пустые клетки = 1, постройки = высокий вес чтобы зомби обходили стены при наличии прохода
	for x in range(balance.grid_width):
		for y in range(balance.grid_height):
			var cell := Vector2i(x, y)
			if _grid_buildings.has(cell):
				var b: BuildingEntity = _grid_buildings[cell]
				if b.config.building_id == "base":
					_astar.set_point_weight_scale(cell, 1.0)
				elif b.config.building_id == "wall":
					_astar.set_point_weight_scale(cell, 24.0)
				else:
					_astar.set_point_weight_scale(cell, 14.0)
			else:
				_astar.set_point_weight_scale(cell, 1.0)


func _can_link(a: BuildingEntity, b: BuildingEntity) -> bool:
	if a.config.building_id == "wall" or b.config.building_id == "wall":
		return false
	var dist_px: float = a.position.distance_to(b.position)
	var direct_adj: bool = dist_px <= balance.cell_size * 1.48
	var max_radius: float = maxf(a.get_link_radius_px(), b.get_link_radius_px())
	return direct_adj or dist_px <= max_radius


func _can_place_building_at(cell: Vector2i, cfg: BuildingConfig) -> bool:
	if cfg == null or not _is_in_bounds(cell) or _grid_buildings.has(cell):
		return false
	var vein_at_cell: int = int(_veins.get(cell, BuildingConfig.VeinType.NONE))
	if cfg.required_vein != BuildingConfig.VeinType.NONE:
		return vein_at_cell == cfg.required_vein
	return vein_at_cell == BuildingConfig.VeinType.NONE


func _on_world_tapped(world_pos: Vector2) -> void:
	if get_tree().paused or GameState.is_game_over:
		return
	var cell: Vector2i = _world_to_cell(world_pos)
	if not _is_in_bounds(cell):
		return

	if not _active_build_id.is_empty():
		if GameState.sim_paused:
			return
		var cfg: BuildingConfig = _building_configs.get(_active_build_id) as BuildingConfig
		if cfg != null and _can_place_building_at(cell, cfg) and GameState.spend_crystals(cfg.cost_crystals):
			var new_b: BuildingEntity = _spawn_building(cell, cfg)
			_rebuild_network_and_paths()
			_select_building(new_b)
			_sync_overlay()
		return

	var tapped_building: BuildingEntity = _grid_buildings.get(cell, null) as BuildingEntity
	_select_building(tapped_building)


func _select_building(building: BuildingEntity) -> void:
	if is_instance_valid(_selected_building):
		_selected_building.set_selected(false)
	_selected_building = building
	if is_instance_valid(_selected_building):
		_selected_building.set_selected(true)
	_overlay.selected_building = _selected_building
	_overlay.queue_redraw()
	EventBus.building_selected.emit(_selected_building)


func _cancel_active_tool_or_selection() -> void:
	if not _active_build_id.is_empty():
		_active_build_id = ""
		EventBus.build_tool_changed.emit("")
		_sync_overlay()
	elif is_instance_valid(_selected_building):
		_select_building(null)


func _toggle_sim_pause() -> void:
	GameState.sim_paused = not GameState.sim_paused
	EventBus.simulation_paused_changed.emit(GameState.sim_paused)
	if is_instance_valid(_selected_building):
		EventBus.building_selected.emit(_selected_building)


func _update_hover_preview() -> void:
	if _active_build_id.is_empty() or SettingsManager.is_touch_controls_visible():
		if _overlay.hovered_cell != Vector2i(-1, -1):
			_overlay.hovered_cell = Vector2i(-1, -1)
			_overlay.hover_neighbors.clear()
			_overlay.queue_redraw()
		return

	var cfg: BuildingConfig = _building_configs.get(_active_build_id) as BuildingConfig
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = _world_to_cell(mouse_world)
	if not _is_in_bounds(cell):
		_overlay.hovered_cell = Vector2i(-1, -1)
		_overlay.hover_neighbors.clear()
		_overlay.queue_redraw()
		return

	_overlay.hovered_cell = cell
	_overlay.active_build_config = cfg
	_overlay.can_place_at_hover = _can_place_building_at(cell, cfg) and GameState.can_afford(cfg.cost_crystals) and not GameState.sim_paused
	_overlay.hover_neighbors.clear()
	if cfg != null and cfg.building_id != "wall":
		var center: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * balance.cell_size
		var r_px: float = cfg.link_radius_cells * balance.cell_size
		for b in _buildings_list:
			if is_instance_valid(b) and b.config.building_id != "wall":
				var d: float = center.distance_to(b.position)
				if d <= maxf(r_px, b.get_link_radius_px()) or d <= balance.cell_size * 1.48:
					_overlay.hover_neighbors.append(b)
	_overlay.queue_redraw()


func _update_phase(delta: float) -> void:
	if not GameState.is_night:
		GameState.phase_timer -= delta
		# Небольшая регенерация Базы днём
		if is_instance_valid(_base_building) and _base_building.hp < _base_building.max_hp:
			_base_building.hp = minf(_base_building.max_hp, _base_building.hp + 6.0 * delta)
			GameState.base_hp = _base_building.hp
			EventBus.base_status_changed.emit(GameState.base_level, GameState.base_hp, GameState.base_max_hp)
		EventBus.day_phase_changed.emit(GameState.day, false, maxf(0.0, GameState.phase_timer), 0)
		if GameState.phase_timer <= 0.0:
			_start_night_phase()
	else:
		if not _wave_spawn_queue.is_empty():
			_wave_spawn_timer -= delta
			if _wave_spawn_timer <= 0.0:
				_wave_spawn_timer = _wave_spawn_interval
				_spawn_enemy(_wave_spawn_queue.pop_front())
		EventBus.day_phase_changed.emit(GameState.day, true, 0.0, _enemies.size() + _wave_spawn_queue.size())
		if _wave_spawn_queue.is_empty() and _enemies.is_empty():
			_complete_night_phase()


func _start_night_phase() -> void:
	GameState.is_night = true
	_wave_spawn_queue.clear()

	var total_count: int = 5 + GameState.day * 3
	for i in range(total_count):
		if GameState.day >= 4 and i % 6 == 5:
			_wave_spawn_queue.append("zombie_tank")
		elif GameState.day >= 2 and i % 3 == 2:
			_wave_spawn_queue.append("zombie_fast")
		else:
			_wave_spawn_queue.append("zombie_basic")

	if GameState.day % 10 == 0:
		_wave_spawn_queue.append("zombie_boss")

	_wave_spawn_interval = clampf(15.0 / float(maxi(1, _wave_spawn_queue.size())), 0.25, 1.1)
	_wave_spawn_timer = 0.4
	_overlay.queue_redraw()
	EventBus.day_phase_changed.emit(GameState.day, true, 0.0, _wave_spawn_queue.size())


func _complete_night_phase() -> void:
	var reward: int = balance.night_reward_base + GameState.day * balance.night_reward_per_day
	GameState.add_crystals(reward)
	GameState.day += 1
	GameState.is_night = false
	GameState.phase_timer = balance.day_duration
	_overlay.queue_redraw()
	EventBus.day_phase_changed.emit(GameState.day, false, GameState.phase_timer, 0)
	SaveManager.save_game()


func _spawn_enemy(enemy_id: String) -> void:
	var cfg: EnemyConfig = _enemy_configs.get(enemy_id) as EnemyConfig
	if cfg == null:
		return
	var edge: int = randi() % 4
	var cell := Vector2i.ZERO
	match edge:
		0:
			cell = Vector2i(randi_range(0, balance.grid_width - 1), 0)
		1:
			cell = Vector2i(randi_range(0, balance.grid_width - 1), balance.grid_height - 1)
		2:
			cell = Vector2i(0, randi_range(0, balance.grid_height - 1))
		_:
			cell = Vector2i(balance.grid_width - 1, randi_range(0, balance.grid_height - 1))

	var world_pos: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * balance.cell_size
	var day_scale: float = 1.0 + 0.14 * float(GameState.day - 1)
	var enemy := EnemyEntity.new()
	enemy.setup(cfg, day_scale, world_pos)
	_enemies_layer.add_child(enemy)
	_enemies.append(enemy)
	_recompute_enemy_path(enemy)


func _recompute_enemy_path(enemy: EnemyEntity) -> void:
	var start_cell: Vector2i = _world_to_cell(enemy.position)
	start_cell.x = clampi(start_cell.x, 0, balance.grid_width - 1)
	start_cell.y = clampi(start_cell.y, 0, balance.grid_height - 1)
	enemy.path_points = _astar.get_point_path(start_cell, _base_cell)
	enemy.path_index = 0


func _update_enemies(delta: float) -> void:
	var to_remove: Array[EnemyEntity] = []
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.attack_timer > 0.0:
			enemy.attack_timer = maxf(0.0, enemy.attack_timer - delta)

		enemy.repath_timer -= delta
		if enemy.repath_timer <= 0.0:
			enemy.repath_timer = 0.85
			_recompute_enemy_path(enemy)

		# Проверяем, стоит ли перед врагом постройка на пути или он рядом с Базой
		var target_building: BuildingEntity = _find_blocking_building(enemy)
		if target_building != null:
			if enemy.attack_timer <= 0.0:
				enemy.attack_timer = enemy.config.attack_cooldown
				_damage_building(target_building, enemy.config.attack_damage)
			continue

		if enemy.path_points.is_empty():
			continue

		if enemy.path_index >= enemy.path_points.size():
			enemy.path_index = enemy.path_points.size() - 1
		var target_pt: Vector2 = enemy.path_points[enemy.path_index]
		var to_pt: Vector2 = target_pt - enemy.position
		var step_dist: float = enemy.config.move_speed * delta
		if to_pt.length() <= step_dist:
			enemy.position = target_pt
			if enemy.path_index < enemy.path_points.size() - 1:
				enemy.path_index += 1
		else:
			enemy.position += to_pt.normalized() * step_dist

	for dead in to_remove:
		_enemies.erase(dead)


func _find_blocking_building(enemy: EnemyEntity) -> BuildingEntity:
	var reach: float = enemy.config.radius_px + balance.cell_size * 0.45
	var current_cell: Vector2i = _world_to_cell(enemy.position)
	if _grid_buildings.has(current_cell):
		return _grid_buildings[current_cell] as BuildingEntity

	if enemy.path_index < enemy.path_points.size():
		var next_cell: Vector2i = _world_to_cell(enemy.path_points[enemy.path_index])
		if _grid_buildings.has(next_cell):
			var candidate: BuildingEntity = _grid_buildings[next_cell] as BuildingEntity
			if enemy.position.distance_to(candidate.position) <= reach:
				return candidate

	if is_instance_valid(_base_building) and enemy.position.distance_to(_base_building.position) <= reach:
		return _base_building
	return null


func _damage_building(b: BuildingEntity, dmg: float) -> void:
	if not is_instance_valid(b):
		return
	var destroyed: bool = b.take_damage(dmg)
	if b == _base_building:
		GameState.base_hp = b.hp
		EventBus.base_status_changed.emit(GameState.base_level, GameState.base_hp, GameState.base_max_hp)
		if destroyed:
			_trigger_game_over()
	elif destroyed:
		_remove_building(b)


func _trigger_game_over() -> void:
	GameState.is_game_over = true
	SaveManager.delete_save()
	_game_over_modal.open_modal(GameState.day, GameState.kills)
	EventBus.game_over.emit(GameState.day, GameState.kills)


func _update_buildings_simulation(delta: float) -> void:
	var teleport_enabled: bool = GameState.has_teleport_logistics()

	for b in _buildings_list:
		if not is_instance_valid(b) or b.config == null:
			continue

		var cfg: BuildingConfig = b.config
		var cap: int = b.get_effective_storage_capacity()

		# 1. Добыча и переработка
		if cfg.category == BuildingConfig.Category.HARVESTER:
			if b.output_storage < cap:
				b.production_timer += delta
				var interval: float = b.get_effective_production_interval()
				if b.production_timer >= interval:
					b.production_timer -= interval
					b.output_storage = mini(cap, b.output_storage + cfg.output_per_cycle)
					b.status_text = "Добыча (%d/%d)" % [b.output_storage, cap]
					b.queue_redraw()
			else:
				b.status_text = "Склад заполнен (затор)"

		elif cfg.category == BuildingConfig.Category.FACTORY:
			if b.input_storage > 0 and b.output_storage < cap:
				b.production_timer += delta
				var f_interval: float = b.get_effective_production_interval()
				if b.production_timer >= f_interval:
					b.production_timer -= f_interval
					b.input_storage -= 1
					b.output_storage = mini(cap, b.output_storage + cfg.output_per_cycle)
					b.status_text = "Производство (%d/%d)" % [b.output_storage, cap]
					b.queue_redraw()
			elif b.input_storage == 0:
				b.status_text = "Ожидание сырья"
			else:
				b.status_text = "Выход полон"

		# 2. Отправка ресурсов / боеприпасов по логистической сети
		if cfg.output_kind != BuildingConfig.ResourceKind.NONE and b.output_storage > 0:
			b.transport_timer += delta
			var t_interval: float = b.get_effective_transport_interval()
			if b.transport_timer >= t_interval:
				b.transport_timer = 0.0
				if _dispatch_resource(b, cfg.output_kind, teleport_enabled):
					b.output_storage -= 1
					b.queue_redraw()
				elif cfg.category == BuildingConfig.Category.HARVESTER or cfg.category == BuildingConfig.Category.FACTORY:
					b.status_text = "Нет пути к потребителю"

		elif cfg.category == BuildingConfig.Category.LOGISTICS and not b.transit_queue.is_empty():
			b.transport_timer += delta
			var l_interval: float = b.get_effective_transport_interval()
			if b.transport_timer >= l_interval:
				b.transport_timer = 0.0
				var res_kind: int = b.transit_queue[0]
				if _dispatch_resource(b, res_kind, teleport_enabled):
					b.transit_queue.pop_front()
					b.status_text = "Транзит (%d/%d)" % [b.transit_queue.size(), cap]
					b.queue_redraw()
				else:
					b.status_text = "Затор на узле"

		# 3. Оборона (башни стреляют только при наличии патронов!)
		if cfg.category == BuildingConfig.Category.DEFENSE and cfg.attack_damage > 0.0:
			if b.attack_timer > 0.0:
				b.attack_timer = maxf(0.0, b.attack_timer - delta)
			if b.input_storage <= 0:
				b.status_text = "Нет боеприпасов!"
			else:
				b.status_text = "Боеприпасы: %d/%d" % [b.input_storage, cap]
				if b.attack_timer <= 0.0 and not _enemies.is_empty():
					_try_fire_tower(b)


func _dispatch_resource(source: BuildingEntity, res_kind: int, teleport: bool) -> bool:
	var route: Array[BuildingEntity] = _find_bfs_route(source, res_kind, teleport)
	if route.is_empty():
		return false

	var target: BuildingEntity = route[-1]
	if teleport:
		return target.accept_incoming_resource(res_kind)

	var next_hop: BuildingEntity = route[0]
	var pkt_color: Color = _get_resource_color(res_kind)
	_overlay.packets.append({
		"from": source.position,
		"to": next_hop.position,
		"target_uid": target.uid if next_hop == target else next_hop.uid,
		"resource_kind": res_kind,
		"progress": 0.0,
		"speed": 2.4 * GameState.get_transport_multiplier(),
		"color": pkt_color,
	})
	return true


func _find_bfs_route(source: BuildingEntity, res_kind: int, allow_global: bool) -> Array[BuildingEntity]:
	if allow_global:
		var best_target: BuildingEntity = null
		var best_dist: float = INF
		for candidate in _buildings_list:
			if not is_instance_valid(candidate) or candidate == source:
				continue
			if _accepts_final_resource(candidate, res_kind):
				var d: float = source.position.distance_squared_to(candidate.position)
				if d < best_dist:
					best_dist = d
					best_target = candidate
		return [best_target] if best_target != null else []

	var queue: Array[BuildingEntity] = []
	var came_from: Dictionary = {source.uid: null}

	for nb in source.neighbors:
		if not is_instance_valid(nb) or came_from.has(nb.uid):
			continue
		came_from[nb.uid] = source
		if _accepts_final_resource(nb, res_kind):
			return [nb]
		if nb.config.category == BuildingConfig.Category.LOGISTICS and nb.transit_queue.size() < nb.get_effective_storage_capacity():
			queue.append(nb)

	var head: int = 0
	while head < queue.size():
		var current: BuildingEntity = queue[head]
		head += 1
		for nb in current.neighbors:
			if not is_instance_valid(nb) or came_from.has(nb.uid):
				continue
			came_from[nb.uid] = current
			if _accepts_final_resource(nb, res_kind):
				var path: Array[BuildingEntity] = []
				var step: BuildingEntity = nb
				while step != null and step != source:
					path.push_front(step)
					step = came_from[step.uid] as BuildingEntity
				return path
			if nb.config.category == BuildingConfig.Category.LOGISTICS and nb.transit_queue.size() < nb.get_effective_storage_capacity():
				queue.append(nb)

	return []


func _accepts_final_resource(b: BuildingEntity, res_kind: int) -> bool:
	if b.config.building_id == "base":
		return res_kind == BuildingConfig.ResourceKind.CRYSTAL
	if b.config.category == BuildingConfig.Category.LOGISTICS:
		return false
	return b.config.input_kind == res_kind and b.input_storage < b.get_effective_storage_capacity()


func _update_packets(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for pkt in _overlay.packets:
		pkt["progress"] = float(pkt["progress"]) + float(pkt["speed"]) * delta
		if float(pkt["progress"]) >= 1.0:
			var target: BuildingEntity = _buildings_by_uid.get(int(pkt["target_uid"]), null) as BuildingEntity
			if is_instance_valid(target):
				target.accept_incoming_resource(int(pkt["resource_kind"]))
		else:
			remaining.append(pkt)
	_overlay.packets = remaining


func _try_fire_tower(tower: BuildingEntity) -> void:
	var range_px: float = tower.get_effective_attack_range_px()
	var best_enemy: EnemyEntity = null
	var best_dist: float = range_px * range_px
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var d2: float = tower.position.distance_squared_to(enemy.position)
		if d2 <= best_dist:
			best_dist = d2
			best_enemy = enemy

	if best_enemy == null:
		return

	tower.input_storage -= 1
	tower.attack_timer = tower.config.attack_cooldown
	tower.turret_angle = (best_enemy.position - tower.position).angle()
	tower.queue_redraw()

	var dmg: float = tower.get_effective_attack_damage()
	if tower.config.splash_radius_px > 0.0:
		_overlay.beams.append({
			"from": tower.position,
			"to": best_enemy.position,
			"ttl": 0.14,
			"max_ttl": 0.14,
			"color": tower.config.accent_color,
			"width": 3.5,
		})
		_overlay.splashes.append({
			"pos": best_enemy.position,
			"radius": tower.config.splash_radius_px,
			"ttl": 0.22,
			"max_ttl": 0.22,
			"color": tower.config.accent_color,
		})
		_apply_aoe_damage(best_enemy.position, tower.config.splash_radius_px, dmg)
	elif tower.config.chain_count > 1:
		_apply_chain_lightning(tower.position, best_enemy, dmg, tower.config.chain_count, tower.config.accent_color)
	else:
		_overlay.beams.append({
			"from": tower.position,
			"to": best_enemy.position,
			"ttl": 0.1,
			"max_ttl": 0.1,
			"color": tower.config.accent_color,
			"width": 2.2,
		})
		_damage_enemy(best_enemy, dmg)


func _apply_aoe_damage(center: Vector2, radius: float, dmg: float) -> void:
	var r2: float = radius * radius
	var targets: Array[EnemyEntity] = []
	for enemy in _enemies:
		if is_instance_valid(enemy) and center.distance_squared_to(enemy.position) <= r2:
			targets.append(enemy)
	for t in targets:
		_damage_enemy(t, dmg)


func _apply_chain_lightning(origin: Vector2, first_target: EnemyEntity, dmg: float, jumps: int, color: Color) -> void:
	var hit_list: Array[EnemyEntity] = []
	var prev_pos: Vector2 = origin
	var current: EnemyEntity = first_target
	for step in range(jumps):
		if not is_instance_valid(current):
			break
		_overlay.beams.append({
			"from": prev_pos,
			"to": current.position,
			"ttl": 0.15,
			"max_ttl": 0.15,
			"color": color,
			"width": 2.8,
		})
		hit_list.append(current)
		prev_pos = current.position
		_damage_enemy(current, dmg * pow(0.8, step))

		var next_enemy: EnemyEntity = null
		var best_d2: float = pow(balance.cell_size * 3.5, 2.0)
		for cand in _enemies:
			if is_instance_valid(cand) and not hit_list.has(cand):
				var d2: float = prev_pos.distance_squared_to(cand.position)
				if d2 < best_d2:
					best_d2 = d2
					next_enemy = cand
		current = next_enemy


func _damage_enemy(enemy: EnemyEntity, dmg: float) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.take_damage(dmg):
		GameState.kills += 1
		GameState.add_crystals(enemy.config.reward_crystals)
		_enemies.erase(enemy)
		enemy.queue_free()


func _update_visual_fx(delta: float) -> void:
	var next_beams: Array[Dictionary] = []
	for bm in _overlay.beams:
		bm["ttl"] = float(bm["ttl"]) - delta
		if float(bm["ttl"]) > 0.0:
			next_beams.append(bm)
	_overlay.beams = next_beams

	var next_splashes: Array[Dictionary] = []
	for sp in _overlay.splashes:
		sp["ttl"] = float(sp["ttl"]) - delta
		if float(sp["ttl"]) > 0.0:
			next_splashes.append(sp)
	_overlay.splashes = next_splashes


func _sync_overlay() -> void:
	_overlay.grid_width = balance.grid_width
	_overlay.grid_height = balance.grid_height
	_overlay.cell_size = balance.cell_size
	_overlay.veins = _veins
	_overlay.buildings_ref = _buildings_list
	_overlay.selected_building = _selected_building
	_overlay.queue_redraw()


func _emit_hud_snapshots() -> void:
	EventBus.crystals_changed.emit(GameState.crystals)
	EventBus.base_status_changed.emit(GameState.base_level, GameState.base_hp, GameState.base_max_hp)
	EventBus.day_phase_changed.emit(GameState.day, GameState.is_night, GameState.phase_timer, _enemies.size() + _wave_spawn_queue.size())
	EventBus.simulation_paused_changed.emit(GameState.sim_paused)


func _connect_signals() -> void:
	EventBus.game_pause_requested.connect(_set_pause_menu_open)

	if _hud.has_method("setup_build_bar"):
		_hud.setup_build_bar(get_building_configs_ordered())
	if _hud.has_signal("build_button_pressed"):
		_hud.build_button_pressed.connect(set_build_tool)
	if _hud.has_signal("skip_day_pressed"):
		_hud.skip_day_pressed.connect(skip_day_to_night)
	if _hud.has_signal("sim_pause_toggled"):
		_hud.sim_pause_toggled.connect(_toggle_sim_pause)
	if _hud.has_signal("skill_tree_requested"):
		_hud.skill_tree_requested.connect(_on_skill_tree_requested)
	if _hud.has_signal("upgrade_selected_pressed"):
		_hud.upgrade_selected_pressed.connect(upgrade_selected_building)
	if _hud.has_signal("sell_selected_pressed"):
		_hud.sell_selected_pressed.connect(sell_selected_building)

	_pause_menu.resume_requested.connect(func() -> void: _set_pause_menu_open(false))
	_pause_menu.settings_requested.connect(func() -> void: _settings_modal.open_modal())
	_pause_menu.main_menu_requested.connect(_on_main_menu_requested)

	_game_over_modal.restart_requested.connect(_on_restart_requested)
	_game_over_modal.main_menu_requested.connect(_on_main_menu_requested)


func _set_pause_menu_open(open: bool) -> void:
	get_tree().paused = open
	_pause_menu.visible = open
	if open:
		SaveManager.save_game()


func _on_skill_tree_requested() -> void:
	_skill_tree_modal.open_modal()


func _on_restart_requested() -> void:
	get_tree().paused = false
	GameState.reset_for_new_game(balance.starting_crystals, balance.day_duration)
	get_tree().change_scene_to_file("res://scenes/game/game_arena.tscn")


func _on_main_menu_requested() -> void:
	if not GameState.is_game_over:
		SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _get_resource_color(kind: int) -> Color:
	match kind:
		BuildingConfig.ResourceKind.CRYSTAL:
			return Color(0.937, 0.267, 0.267, 1.0)
		BuildingConfig.ResourceKind.WOOD:
			return Color(0.961, 0.62, 0.043, 1.0)
		BuildingConfig.ResourceKind.IRON:
			return Color(0.796, 0.835, 0.882, 1.0)
		BuildingConfig.ResourceKind.URANIUM:
			return Color(0.133, 0.773, 0.369, 1.0)
		BuildingConfig.ResourceKind.ARROWS:
			return Color(0.984, 0.749, 0.141, 1.0)
		BuildingConfig.ResourceKind.CANNONBALLS:
			return Color(0.976, 0.451, 0.086, 1.0)
		BuildingConfig.ResourceKind.ENERGY:
			return Color(0.655, 0.545, 0.98, 1.0)
		_:
			return Color.WHITE


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / balance.cell_size)), int(floor(world_pos.y / balance.cell_size)))


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < balance.grid_width and cell.y < balance.grid_height
