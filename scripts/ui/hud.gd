extends CanvasLayer
## Игровой HUD стратегии YORG.io: день/ночь, кристаллы, База, панель постройки, инспектор и тач-зум.

signal build_button_pressed(building_id: String)
signal skip_day_pressed
signal sim_pause_toggled
signal skill_tree_requested
signal upgrade_selected_pressed
signal sell_selected_pressed

@onready var _phase_label: Label = $SafeMargin/RootVBox/TopBar/LeftStats/Margin/HBox/PhaseLabel
@onready var _crystals_label: Label = $SafeMargin/RootVBox/TopBar/LeftStats/Margin/HBox/CrystalsLabel
@onready var _base_label: Label = $SafeMargin/RootVBox/TopBar/LeftStats/Margin/HBox/BaseLabel
@onready var _skip_day_button: Button = $SafeMargin/RootVBox/TopBar/LeftActions/SkipDayButton
@onready var _sim_pause_button: Button = $SafeMargin/RootVBox/TopBar/LeftActions/SimPauseButton
@onready var _skills_button: Button = $SafeMargin/RootVBox/TopBar/RightActions/SkillsButton
@onready var _save_toast: Label = $SafeMargin/RootVBox/TopBar/RightActions/SaveToastLabel
@onready var _pause_button: Button = $SafeMargin/RootVBox/TopBar/RightActions/PauseButton
@onready var _sim_pause_banner: Label = $SafeMargin/RootVBox/SimPauseBanner

@onready var _inspector_panel: PanelContainer = $SafeMargin/RootVBox/MiddleRow/InspectorPanel
@onready var _insp_title: Label = $SafeMargin/RootVBox/MiddleRow/InspectorPanel/Margin/VBox/TitleLabel
@onready var _insp_stats: Label = $SafeMargin/RootVBox/MiddleRow/InspectorPanel/Margin/VBox/StatsLabel
@onready var _insp_desc: Label = $SafeMargin/RootVBox/MiddleRow/InspectorPanel/Margin/VBox/DescLabel
@onready var _insp_upgrade_btn: Button = $SafeMargin/RootVBox/MiddleRow/InspectorPanel/Margin/VBox/Actions/UpgradeButton
@onready var _insp_sell_btn: Button = $SafeMargin/RootVBox/MiddleRow/InspectorPanel/Margin/VBox/Actions/SellButton

@onready var _zoom_box: VBoxContainer = $SafeMargin/RootVBox/MiddleRow/TouchZoomBox
@onready var _zoom_in_btn: Button = $SafeMargin/RootVBox/MiddleRow/TouchZoomBox/ZoomInButton
@onready var _zoom_out_btn: Button = $SafeMargin/RootVBox/MiddleRow/TouchZoomBox/ZoomOutButton
@onready var _center_btn: Button = $SafeMargin/RootVBox/MiddleRow/TouchZoomBox/CenterButton

@onready var _build_scroll_hbox: HBoxContainer = $SafeMargin/RootVBox/BottomBuildPanel/Margin/Scroll/BuildButtons

var _build_buttons: Dictionary = {} # building_id -> Button
var _building_configs: Dictionary = {} # building_id -> BuildingConfig
var _active_build_id: String = ""
var _selected_building: BuildingEntity = null
var _toast_tween: Tween = null


func _ready() -> void:
	_save_toast.modulate.a = 0.0
	_inspector_panel.visible = false
	_sim_pause_banner.visible = false

	_skip_day_button.pressed.connect(func() -> void: skip_day_pressed.emit())
	_sim_pause_button.pressed.connect(func() -> void: sim_pause_toggled.emit())
	_skills_button.pressed.connect(func() -> void: skill_tree_requested.emit())
	_pause_button.pressed.connect(func() -> void: EventBus.game_pause_requested.emit(true))
	_insp_upgrade_btn.pressed.connect(func() -> void: upgrade_selected_pressed.emit())
	_insp_sell_btn.pressed.connect(func() -> void: sell_selected_pressed.emit())

	_zoom_in_btn.pressed.connect(func() -> void: EventBus.camera_zoom_requested.emit(1.18))
	_zoom_out_btn.pressed.connect(func() -> void: EventBus.camera_zoom_requested.emit(1.0 / 1.18))
	_center_btn.pressed.connect(func() -> void: EventBus.camera_center_requested.emit())

	EventBus.crystals_changed.connect(_on_crystals_changed)
	EventBus.day_phase_changed.connect(_on_day_phase_changed)
	EventBus.base_status_changed.connect(_on_base_status_changed)
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.build_tool_changed.connect(_on_build_tool_changed)
	EventBus.simulation_paused_changed.connect(_on_sim_paused_changed)
	EventBus.save_completed.connect(_on_save_completed)
	EventBus.touch_mode_changed.connect(func(_m: String) -> void: _update_touch_zoom_visibility())

	_update_touch_zoom_visibility()


func setup_build_bar(configs: Array[BuildingConfig]) -> void:
	for child in _build_scroll_hbox.get_children():
		child.queue_free()
	_build_buttons.clear()
	_building_configs.clear()

	for cfg in configs:
		_building_configs[cfg.building_id] = cfg
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(92, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "%s\n%d кр." % [cfg.short_label, cfg.cost_crystals]
		btn.tooltip_text = "%s (%d кр.) — %s" % [cfg.display_name, cfg.cost_crystals, cfg.description]
		btn.add_theme_color_override("font_color", cfg.accent_color)
		btn.add_theme_font_size_override("font_size", 12)
		var b_id: String = cfg.building_id
		btn.pressed.connect(func() -> void: build_button_pressed.emit(b_id))
		_build_scroll_hbox.add_child(btn)
		_build_buttons[b_id] = btn

	_refresh_build_buttons()


func _refresh_build_buttons() -> void:
	for b_id in _build_buttons.keys():
		var btn: Button = _build_buttons[b_id]
		var cfg: BuildingConfig = _building_configs[b_id]
		var affordable: bool = GameState.can_afford(cfg.cost_crystals) and not GameState.sim_paused
		btn.disabled = not affordable
		if b_id == _active_build_id:
			btn.modulate = Color(1.25, 1.25, 1.25, 1.0)
			btn.text = "[%s]\n%d кр." % [cfg.short_label, cfg.cost_crystals]
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.text = "%s\n%d кр." % [cfg.short_label, cfg.cost_crystals]


func _refresh_inspector() -> void:
	if not is_instance_valid(_selected_building) or _selected_building.config == null:
		_inspector_panel.visible = false
		return

	_inspector_panel.visible = true
	var b: BuildingEntity = _selected_building
	var cfg: BuildingConfig = b.config
	_insp_title.text = "%s (L%d)" % [cfg.display_name, b.level]
	_insp_title.add_theme_color_override("font_color", cfg.accent_color)

	var stats_lines: Array[String] = [
		"HP: %d / %d" % [int(round(b.hp)), int(round(b.max_hp))],
		"Статус: %s" % b.status_text,
	]
	if cfg.attack_damage > 0.0:
		stats_lines.append("Урон: %d • Дальность: %.1f" % [int(round(b.get_effective_attack_damage())), cfg.attack_range_cells + 0.25 * float(b.level - 1)])
	_insp_stats.text = "\n".join(stats_lines)
	_insp_desc.text = cfg.description

	var upg_cost: int = b.get_upgrade_cost()
	var is_base: bool = cfg.building_id == "base"
	var capped_by_base: bool = (not is_base) and (b.level >= GameState.base_level)
	if capped_by_base:
		_insp_upgrade_btn.text = "Нужна База L%d" % (b.level + 1)
		_insp_upgrade_btn.disabled = true
	else:
		_insp_upgrade_btn.text = "Улучшить (%d)" % upg_cost
		_insp_upgrade_btn.disabled = GameState.sim_paused or not GameState.can_afford(upg_cost)

	if is_base:
		_insp_sell_btn.visible = false
	else:
		_insp_sell_btn.visible = true
		_insp_sell_btn.text = "Продать (+%d)" % b.get_sell_refund()
		_insp_sell_btn.disabled = GameState.sim_paused


func _update_touch_zoom_visibility() -> void:
	_zoom_box.visible = SettingsManager.is_touch_controls_visible()


func _on_crystals_changed(new_crystals: int) -> void:
	_crystals_label.text = "Кристаллы: %d" % new_crystals
	_refresh_build_buttons()
	_refresh_inspector()


func _on_day_phase_changed(day: int, is_night: bool, time_left: float, enemies_alive: int) -> void:
	if is_night:
		_phase_label.text = "Ночь %d • Враги: %d" % [day, enemies_alive]
		_phase_label.add_theme_color_override("font_color", Color(0.937, 0.267, 0.267, 1.0))
		_skip_day_button.visible = false
	else:
		_phase_label.text = "День %d • %dс" % [day, int(ceil(time_left))]
		_phase_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.082, 1.0))
		_skip_day_button.visible = true
		_skip_day_button.disabled = GameState.sim_paused


func _on_base_status_changed(level: int, hp: float, max_hp: float) -> void:
	_base_label.text = "База L%d • %d/%d" % [level, int(round(hp)), int(round(max_hp))]
	_refresh_inspector()


func _on_building_selected(building: Node2D) -> void:
	_selected_building = building as BuildingEntity
	_refresh_inspector()


func _on_build_tool_changed(building_id: String) -> void:
	_active_build_id = building_id
	_refresh_build_buttons()


func _on_sim_paused_changed(paused: bool) -> void:
	_sim_pause_banner.visible = paused
	_sim_pause_button.text = "Пуск" if paused else "Пауза"
	_skip_day_button.disabled = paused
	_refresh_build_buttons()
	_refresh_inspector()


func _on_save_completed(success: bool, message: String) -> void:
	_save_toast.text = message if success else ("Ошибка: " + message)
	_save_toast.modulate = Color(0.133, 0.827, 0.933, 1.0) if success else Color(0.937, 0.267, 0.267, 1.0)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.2)
	_toast_tween.tween_property(_save_toast, "modulate:a", 0.0, 0.45)
