extends Control
## Окно межзабеговой прогрессии: Сад растений и система Артефактов.

@onready var _essence_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderRow/EssenceLabel
@onready var _seeds_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderRow/SeedsLabel
@onready var _best_day_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderRow/BestDayLabel

@onready var _garden_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabRow/GardenTabButton
@onready var _artifacts_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabRow/ArtifactsTabButton
@onready var _garden_page: VBoxContainer = $CenterContainer/Panel/Margin/VBox/GardenPage
@onready var _artifacts_page: VBoxContainer = $CenterContainer/Panel/Margin/VBox/ArtifactsPage

@onready var _plots_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/GardenPage/PlotsGrid
@onready var _plot_status_label: Label = $CenterContainer/Panel/Margin/VBox/GardenPage/PlotDetailPanel/Margin/HBox/PlotStatusLabel
@onready var _unlock_plot_btn: Button = $CenterContainer/Panel/Margin/VBox/GardenPage/PlotDetailPanel/Margin/HBox/UnlockPlotButton
@onready var _upgrade_plot_btn: Button = $CenterContainer/Panel/Margin/VBox/GardenPage/PlotDetailPanel/Margin/HBox/UpgradePlotButton
@onready var _uproot_plot_btn: Button = $CenterContainer/Panel/Margin/VBox/GardenPage/PlotDetailPanel/Margin/HBox/UprootPlotButton
@onready var _plants_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/GardenPage/PlantsGrid
@onready var _plant_desc_label: Label = $CenterContainer/Panel/Margin/VBox/GardenPage/PlantActionPanel/Margin/HBox/PlantDescLabel
@onready var _plant_btn: Button = $CenterContainer/Panel/Margin/VBox/GardenPage/PlantActionPanel/Margin/HBox/PlantButton

@onready var _equipped_slots_row: HBoxContainer = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/EquippedSlotsRow
@onready var _artifacts_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/ArtifactsGrid
@onready var _art_title_label: Label = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/ArtifactDetailPanel/Margin/HBox/InfoVBox/ArtTitleLabel
@onready var _art_desc_label: Label = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/ArtifactDetailPanel/Margin/HBox/InfoVBox/ArtDescLabel
@onready var _equip_art_btn: Button = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/ArtifactDetailPanel/Margin/HBox/EquipArtButton
@onready var _craft_upgrade_art_btn: Button = $CenterContainer/Panel/Margin/VBox/ArtifactsPage/ArtifactDetailPanel/Margin/HBox/CraftUpgradeArtButton

@onready var _summary_label: Label = $CenterContainer/Panel/Margin/VBox/SummaryPanel/Margin/SummaryLabel
@onready var _close_button: Button = $CenterContainer/Panel/Margin/VBox/CloseButton

var _plot_buttons: Array[Button] = []
var _plant_buttons: Dictionary = {} # plant_id -> Button
var _slot_buttons: Array[Button] = []
var _artifact_buttons: Dictionary = {} # artifact_id -> Button

var _active_tab: int = 0 # 0 = Garden, 1 = Artifacts
var _selected_plot_idx: int = 0
var _selected_plant_id: String = "crystal_lotus"
var _selected_artifact_id: String = "core_shard"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_dynamic_grids()

	_garden_tab_btn.pressed.connect(func() -> void: _set_tab(0))
	_artifacts_tab_btn.pressed.connect(func() -> void: _set_tab(1))

	_unlock_plot_btn.pressed.connect(_on_unlock_plot_pressed)
	_upgrade_plot_btn.pressed.connect(_on_upgrade_plot_pressed)
	_uproot_plot_btn.pressed.connect(_on_uproot_plot_pressed)
	_plant_btn.pressed.connect(_on_plant_pressed)

	_equip_art_btn.pressed.connect(_on_equip_art_pressed)
	_craft_upgrade_art_btn.pressed.connect(_on_craft_upgrade_art_pressed)
	_close_button.pressed.connect(hide_modal)

	EventBus.meta_progression_changed.connect(_refresh_all)


func open_modal(initial_tab: int = 0) -> void:
	_active_tab = clampi(initial_tab, 0, 1)
	_refresh_all()
	visible = true


func hide_modal() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		hide_modal()
		get_viewport().set_input_as_handled()


func _build_dynamic_grids() -> void:
	for i in range(MetaProgression.MAX_PLOTS):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(248, 74)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		var captured_idx: int = i
		btn.pressed.connect(func() -> void: _on_plot_pressed(captured_idx))
		_plots_grid.add_child(btn)
		_plot_buttons.append(btn)

	for pid in MetaProgression.PLANT_ORDER:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(248, 66)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		var captured_pid: String = pid
		btn.pressed.connect(func() -> void: _on_plant_card_pressed(captured_pid))
		_plants_grid.add_child(btn)
		_plant_buttons[pid] = btn

	for i in range(MetaProgression.MAX_ARTIFACT_SLOTS):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		var captured_slot: int = i
		btn.pressed.connect(func() -> void: _on_slot_pressed(captured_slot))
		_equipped_slots_row.add_child(btn)
		_slot_buttons.append(btn)

	for aid in MetaProgression.ARTIFACT_ORDER:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(248, 86)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		var captured_aid: String = aid
		btn.pressed.connect(func() -> void: _on_artifact_card_pressed(captured_aid))
		_artifacts_grid.add_child(btn)
		_artifact_buttons[aid] = btn


func _set_tab(tab_idx: int) -> void:
	_active_tab = tab_idx
	_refresh_all()


func _on_plot_pressed(idx: int) -> void:
	_selected_plot_idx = idx
	_refresh_all()


func _on_plant_card_pressed(pid: String) -> void:
	if _selected_plant_id == pid:
		_try_plant_selected()
	else:
		_selected_plant_id = pid
		_refresh_all()


func _on_plant_pressed() -> void:
	_try_plant_selected()


func _try_plant_selected() -> void:
	if _selected_plot_idx >= MetaProgression.unlocked_plot_count or not str(MetaProgression.garden_plots[_selected_plot_idx].get("plant_id", "")).is_empty():
		# Автовыбор первой свободной грядки, если текущая занята/закрыта
		for i in range(MetaProgression.unlocked_plot_count):
			if str(MetaProgression.garden_plots[i].get("plant_id", "")).is_empty():
				_selected_plot_idx = i
				break
	MetaProgression.plant_on_plot(_selected_plot_idx, _selected_plant_id)


func _on_unlock_plot_pressed() -> void:
	if MetaProgression.unlock_next_plot():
		_selected_plot_idx = MetaProgression.unlocked_plot_count - 1


func _on_upgrade_plot_pressed() -> void:
	MetaProgression.upgrade_plot(_selected_plot_idx)


func _on_uproot_plot_pressed() -> void:
	MetaProgression.uproot_plot(_selected_plot_idx)


func _on_slot_pressed(slot_idx: int) -> void:
	if slot_idx >= MetaProgression.unlocked_artifact_slots:
		MetaProgression.unlock_next_artifact_slot()
		return
	if slot_idx < MetaProgression.equipped_artifacts.size():
		var aid: String = MetaProgression.equipped_artifacts[slot_idx]
		MetaProgression.toggle_equip_artifact(aid)


func _on_artifact_card_pressed(aid: String) -> void:
	_selected_artifact_id = aid
	_refresh_all()


func _on_equip_art_pressed() -> void:
	MetaProgression.toggle_equip_artifact(_selected_artifact_id)


func _on_craft_upgrade_art_pressed() -> void:
	MetaProgression.craft_or_upgrade_artifact(_selected_artifact_id)


func _refresh_all() -> void:
	if not is_node_ready():
		return

	_essence_label.text = "Эссенция: %d" % MetaProgression.essence
	_seeds_label.text = "Семена: %d" % MetaProgression.seeds
	_best_day_label.text = "Рекорд: %d дн." % MetaProgression.best_day

	var planted_count: int = 0
	for i in range(MetaProgression.unlocked_plot_count):
		if not str(MetaProgression.garden_plots[i].get("plant_id", "")).is_empty():
			planted_count += 1
	_garden_tab_btn.text = "Сад (%d/%d)" % [planted_count, MetaProgression.unlocked_plot_count]
	_artifacts_tab_btn.text = "Артефакты (%d/%d)" % [MetaProgression.equipped_artifacts.size(), MetaProgression.unlocked_artifact_slots]

	_garden_page.visible = (_active_tab == 0)
	_artifacts_page.visible = (_active_tab == 1)
	_garden_tab_btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if _active_tab == 0 else Color(0.78, 0.82, 0.88, 0.9)
	_artifacts_tab_btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if _active_tab == 1 else Color(0.78, 0.82, 0.88, 0.9)

	_refresh_garden()
	_refresh_artifacts()
	_summary_label.text = "Бонусы забега: " + " • ".join(MetaProgression.get_active_bonuses_summary())


func _refresh_garden() -> void:
	for i in range(MetaProgression.MAX_PLOTS):
		var btn: Button = _plot_buttons[i]
		var prefix: String = "> " if i == _selected_plot_idx else ""
		if i >= MetaProgression.unlocked_plot_count:
			var unlock_cost: int = MetaProgression.PLOT_UNLOCK_COSTS[i]
			btn.text = "%sГрядка #%d [ЗАКРЫТО]\nОткрытие: %d эсс." % [prefix, i + 1, unlock_cost]
			btn.add_theme_color_override("font_color", Color(0.58, 0.64, 0.72, 0.8))
			btn.modulate = Color(0.8, 0.82, 0.88, 0.85)
		else:
			var p: Dictionary = MetaProgression.garden_plots[i]
			var pid: String = str(p.get("plant_id", ""))
			var lvl: int = int(p.get("level", 0))
			if pid.is_empty():
				btn.text = "%sГрядка #%d\nПусто (выберите ниже)" % [prefix, i + 1]
				btn.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98, 0.95))
				btn.modulate = Color(1.15, 1.15, 1.15, 1.0) if i == _selected_plot_idx else Color.WHITE
			else:
				var def: Dictionary = MetaProgression.PLANT_DEFS[pid] as Dictionary
				var lvls: Array = def.get("levels_text", []) as Array
				var eff: String = str(lvls[clampi(lvl - 1, 0, lvls.size() - 1)])
				btn.text = "%s%s (Ур.%d)\n%s" % [prefix, str(def.get("title", pid)), lvl, eff]
				var col: Color = def.get("color", Color.WHITE) as Color
				btn.add_theme_color_override("font_color", col)
				btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if i == _selected_plot_idx else Color.WHITE

	var next_unlock_cost: int = MetaProgression.get_next_plot_unlock_cost()
	if next_unlock_cost > 0:
		_unlock_plot_btn.visible = true
		_unlock_plot_btn.text = "Открыть грядку (%d эсс.)" % next_unlock_cost
		_unlock_plot_btn.disabled = MetaProgression.essence < next_unlock_cost
	else:
		_unlock_plot_btn.visible = false

	if _selected_plot_idx >= MetaProgression.unlocked_plot_count:
		_plot_status_label.text = "Грядка #%d закрыта. Откройте новую грядку за эссенцию, чтобы суммировать больше растений." % (_selected_plot_idx + 1)
		_upgrade_plot_btn.visible = false
		_uproot_plot_btn.visible = false
	else:
		var sp: Dictionary = MetaProgression.garden_plots[_selected_plot_idx]
		var spid: String = str(sp.get("plant_id", ""))
		var slvl: int = int(sp.get("level", 0))
		if spid.is_empty():
			_plot_status_label.text = "Грядка #%d свободна — выберите растение ниже и нажмите «Посадить»." % (_selected_plot_idx + 1)
			_upgrade_plot_btn.visible = false
			_uproot_plot_btn.visible = false
		else:
			var sdef: Dictionary = MetaProgression.PLANT_DEFS[spid] as Dictionary
			var lvls_t: Array = sdef.get("levels_text", []) as Array
			var cur_eff: String = str(lvls_t[clampi(slvl - 1, 0, lvls_t.size() - 1)])
			_plot_status_label.text = "Грядка #%d: %s Ур.%d (%s)" % [_selected_plot_idx + 1, str(sdef.get("title", "")), slvl, cur_eff]
			_uproot_plot_btn.visible = true
			_upgrade_plot_btn.visible = true
			var upg: Dictionary = MetaProgression.get_plot_upgrade_cost(_selected_plot_idx)
			if not bool(upg.get("valid", false)):
				_upgrade_plot_btn.text = "Макс. уровень"
				_upgrade_plot_btn.disabled = true
			else:
				var rs: int = int(upg.get("seeds", 0))
				var re: int = int(upg.get("essence", 0))
				_upgrade_plot_btn.text = "Улучшить (%d сем., %d эсс.)" % [rs, re]
				_upgrade_plot_btn.disabled = MetaProgression.seeds < rs or MetaProgression.essence < re

	for pid in MetaProgression.PLANT_ORDER:
		var pbtn: Button = _plant_buttons[pid] as Button
		var pdef: Dictionary = MetaProgression.PLANT_DEFS[pid] as Dictionary
		var ps: int = int(pdef.get("plant_seeds", 1))
		var pe: int = int(pdef.get("plant_essence", 10))
		var lvls_arr: Array = pdef.get("levels_text", []) as Array
		var l1_txt: String = str(lvls_arr[0]) if not lvls_arr.is_empty() else ""
		var sel_pref: String = "> " if pid == _selected_plant_id else ""
		pbtn.text = "%s%s (%d сем., %d эсс.)\n%s" % [sel_pref, str(pdef.get("title", pid)), ps, pe, l1_txt]
		pbtn.add_theme_color_override("font_color", pdef.get("color", Color.WHITE) as Color)
		pbtn.modulate = Color(1.2, 1.2, 1.2, 1.0) if pid == _selected_plant_id else Color.WHITE

	var sel_def: Dictionary = MetaProgression.PLANT_DEFS.get(_selected_plant_id, {}) as Dictionary
	if not sel_def.is_empty():
		var lvls_list: Array = sel_def.get("levels_text", []) as Array
		var tiers_str: String = " → ".join(lvls_list)
		_plant_desc_label.text = "%s: %s\nУровни 1→3: %s" % [str(sel_def.get("title", "")), str(sel_def.get("description", "")), tiers_str]
		var req_s: int = int(sel_def.get("plant_seeds", 1))
		var req_e: int = int(sel_def.get("plant_essence", 10))
		var has_empty_plot: bool = false
		for i in range(MetaProgression.unlocked_plot_count):
			if str(MetaProgression.garden_plots[i].get("plant_id", "")).is_empty():
				has_empty_plot = true
				break
		_plant_btn.text = "Посадить (%d сем., %d эсс.)" % [req_s, req_e]
		_plant_btn.disabled = (not has_empty_plot) or MetaProgression.seeds < req_s or MetaProgression.essence < req_e


func _refresh_artifacts() -> void:
	for i in range(MetaProgression.MAX_ARTIFACT_SLOTS):
		var sbtn: Button = _slot_buttons[i]
		if i >= MetaProgression.unlocked_artifact_slots:
			var slot_cost: int = MetaProgression.ARTIFACT_SLOT_COSTS[i]
			sbtn.text = "Слот #%d [ЗАКРЫТ]\nОткрыть (%d эсс.)" % [i + 1, slot_cost]
			sbtn.disabled = MetaProgression.essence < slot_cost
			sbtn.add_theme_color_override("font_color", Color(0.961, 0.62, 0.043, 1.0))
		elif i < MetaProgression.equipped_artifacts.size():
			var aid: String = MetaProgression.equipped_artifacts[i]
			var adef: Dictionary = MetaProgression.ARTIFACT_DEFS[aid] as Dictionary
			var alvl: int = MetaProgression.get_artifact_level(aid)
			sbtn.text = "Слот #%d: %s (L%d)\n[Нажмите, чтобы снять]" % [i + 1, str(adef.get("title", aid)), alvl]
			sbtn.disabled = false
			sbtn.add_theme_color_override("font_color", adef.get("color", Color.WHITE) as Color)
		else:
			sbtn.text = "Слот #%d: Пусто\nВыберите артефакт ниже" % (i + 1)
			sbtn.disabled = true
			sbtn.add_theme_color_override("font_color", Color(0.7, 0.78, 0.88, 0.8))

	for aid in MetaProgression.ARTIFACT_ORDER:
		var abtn: Button = _artifact_buttons[aid] as Button
		var adef: Dictionary = MetaProgression.ARTIFACT_DEFS[aid] as Dictionary
		var lvl: int = MetaProgression.get_artifact_level(aid)
		var equipped: bool = MetaProgression.is_artifact_equipped(aid)
		var lvls: Array = adef.get("levels_text", []) as Array
		var stat_txt: String = str(lvls[clampi(lvl - 1, 0, lvls.size() - 1)]) if lvl > 0 else str(lvls[0])
		var tag: String = "[НАДЕТ L%d]" % lvl if equipped else ("L%d" % lvl if lvl > 0 else "НЕ ОТКРЫТ")
		var pref: String = "> " if aid == _selected_artifact_id else ""
		abtn.text = "%s%s (%s)\n%s" % [pref, str(adef.get("title", aid)), tag, stat_txt]
		if lvl <= 0:
			abtn.add_theme_color_override("font_color", Color(0.58, 0.64, 0.72, 0.85))
			abtn.modulate = Color(0.85, 0.88, 0.92, 0.9)
		else:
			abtn.add_theme_color_override("font_color", adef.get("color", Color.WHITE) as Color)
			abtn.modulate = Color(1.2, 1.2, 1.2, 1.0) if aid == _selected_artifact_id else Color.WHITE

	var sdef: Dictionary = MetaProgression.ARTIFACT_DEFS.get(_selected_artifact_id, {}) as Dictionary
	if not sdef.is_empty():
		var slvl: int = MetaProgression.get_artifact_level(_selected_artifact_id)
		var smax: int = int(sdef.get("max_level", 3))
		var slvls: Array = sdef.get("levels_text", []) as Array
		_art_title_label.text = "%s (%s)" % [str(sdef.get("title", "")), ("Ур. %d / %d" % [slvl, smax]) if slvl > 0 else "Не открыт"]
		_art_title_label.add_theme_color_override("font_color", sdef.get("color", Color.WHITE) as Color)
		_art_desc_label.text = "%s\nУровни 1→3: %s" % [str(sdef.get("description", "")), " → ".join(slvls)]

		var is_eq: bool = MetaProgression.is_artifact_equipped(_selected_artifact_id)
		if slvl <= 0:
			_equip_art_btn.text = "Не открыт"
			_equip_art_btn.disabled = true
		elif is_eq:
			_equip_art_btn.text = "Снять"
			_equip_art_btn.disabled = false
		else:
			var free_slot: bool = MetaProgression.equipped_artifacts.size() < MetaProgression.unlocked_artifact_slots
			_equip_art_btn.text = "Надеть" if free_slot else "Слоты заняты"
			_equip_art_btn.disabled = not free_slot

		var action_cost: int = MetaProgression.get_artifact_action_cost(_selected_artifact_id)
		if action_cost < 0:
			_craft_upgrade_art_btn.text = "МАКС"
			_craft_upgrade_art_btn.disabled = true
		elif slvl <= 0:
			_craft_upgrade_art_btn.text = "Создать (%d эсс.)" % action_cost
			_craft_upgrade_art_btn.disabled = MetaProgression.essence < action_cost
		else:
			_craft_upgrade_art_btn.text = "Улучшить (%d эсс.)" % action_cost
			_craft_upgrade_art_btn.disabled = MetaProgression.essence < action_cost
