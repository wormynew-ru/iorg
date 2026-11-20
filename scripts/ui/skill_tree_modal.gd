extends Control
## Модальное окно ветвящегося древа талантов в духе YORG.io (Экономика, Логистика, Оборона).

@onready var _points_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderRow/PointsLabel
@onready var _crystals_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderRow/CrystalsLabel
@onready var _tree_canvas: Control = $CenterContainer/Panel/Margin/VBox/TreeCanvas
@onready var _branch_boxes: Array[VBoxContainer] = [
	$CenterContainer/Panel/Margin/VBox/TreeCanvas/Columns/Branch0,
	$CenterContainer/Panel/Margin/VBox/TreeCanvas/Columns/Branch1,
	$CenterContainer/Panel/Margin/VBox/TreeCanvas/Columns/Branch2,
]
@onready var _detail_title: Label = $CenterContainer/Panel/Margin/VBox/DetailPanel/Margin/HBox/InfoVBox/DetailTitle
@onready var _detail_desc: Label = $CenterContainer/Panel/Margin/VBox/DetailPanel/Margin/HBox/InfoVBox/DetailDesc
@onready var _detail_req: Label = $CenterContainer/Panel/Margin/VBox/DetailPanel/Margin/HBox/InfoVBox/DetailReq
@onready var _buy_button: Button = $CenterContainer/Panel/Margin/VBox/DetailPanel/Margin/HBox/BuyButton
@onready var _close_button: Button = $CenterContainer/Panel/Margin/VBox/CloseButton

var _node_buttons: Dictionary = {} # skill_id -> Button
var _selected_skill_id: String = "mining_speed"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_tree_nodes()
	_buy_button.pressed.connect(_on_buy_pressed)
	_close_button.pressed.connect(hide_modal)


func open_modal() -> void:
	_refresh_ui()
	visible = true
	await get_tree().process_frame
	_tree_canvas.queue_redraw()


func hide_modal() -> void:
	visible = false


func _build_tree_nodes() -> void:
	for box in _branch_boxes:
		for child in box.get_children():
			child.queue_free()
	_node_buttons.clear()

	for skill_id in GameState.TALENT_ORDER:
		var def: Dictionary = GameState.get_talent_def(skill_id)
		var branch_idx: int = clampi(int(def.get("branch", 0)), 0, _branch_boxes.size() - 1)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 66)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		var captured_id: String = skill_id
		btn.pressed.connect(func() -> void: _on_node_pressed(captured_id))
		_branch_boxes[branch_idx].add_child(btn)
		_node_buttons[skill_id] = btn

	_tree_canvas.node_buttons = _node_buttons


func _on_node_pressed(skill_id: String) -> void:
	if _selected_skill_id == skill_id:
		_try_upgrade_selected()
	else:
		_selected_skill_id = skill_id
		_refresh_ui()


func _on_buy_pressed() -> void:
	_try_upgrade_selected()


func _try_upgrade_selected() -> void:
	if GameState.upgrade_skill(_selected_skill_id):
		_refresh_ui()


func _refresh_ui() -> void:
	_points_label.text = "Таланты: %d / %d" % [GameState.get_total_talent_points(), GameState.get_max_talent_points()]
	_crystals_label.text = "Кристаллы: %d" % GameState.crystals

	for skill_id in GameState.TALENT_ORDER:
		var btn: Button = _node_buttons.get(skill_id) as Button
		if btn == null:
			continue
		var def: Dictionary = GameState.get_talent_def(skill_id)
		var lvl: int = GameState.get_skill_level(skill_id)
		var max_lvl: int = GameState.get_talent_max_level(skill_id)
		var unlocked: bool = GameState.is_talent_unlocked(skill_id)
		var short_title: String = str(def.get("short_title", skill_id))
		var branch_color: Color = def.get("color", Color.WHITE) as Color

		var state_line: String = ""
		if lvl >= max_lvl:
			state_line = "МАКС (%d/%d)" % [lvl, max_lvl]
		elif not unlocked:
			state_line = "ЗАКРЫТО (0/%d)" % max_lvl
		else:
			state_line = "%d/%d • %d кр." % [lvl, max_lvl, GameState.get_skill_cost(skill_id)]

		var prefix: String = "> " if skill_id == _selected_skill_id else ""
		btn.text = "%s%s\n%s" % [prefix, short_title, state_line]

		if not unlocked:
			btn.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 0.78))
			btn.modulate = Color(0.75, 0.78, 0.85, 0.85)
		elif lvl >= max_lvl:
			btn.add_theme_color_override("font_color", Color(0.973, 0.98, 0.988, 1.0))
			btn.modulate = branch_color.lightened(0.2)
		else:
			btn.add_theme_color_override("font_color", branch_color)
			btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if skill_id == _selected_skill_id else Color.WHITE

	_refresh_detail_panel()
	_tree_canvas.queue_redraw()


func _refresh_detail_panel() -> void:
	var def: Dictionary = GameState.get_talent_def(_selected_skill_id)
	if def.is_empty():
		return

	var lvl: int = GameState.get_skill_level(_selected_skill_id)
	var max_lvl: int = GameState.get_talent_max_level(_selected_skill_id)
	var unlocked: bool = GameState.is_talent_unlocked(_selected_skill_id)
	var branch_color: Color = def.get("color", Color.WHITE) as Color

	_detail_title.text = "%s (Уровень %d / %d)" % [str(def.get("title", "")), lvl, max_lvl]
	_detail_title.add_theme_color_override("font_color", branch_color)
	_detail_desc.text = str(def.get("description", ""))

	var req_id: String = str(def.get("requires_id", ""))
	if req_id.is_empty():
		_detail_req.text = "Базовый талант ветки"
		_detail_req.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.9))
	else:
		var req_def: Dictionary = GameState.get_talent_def(req_id)
		var req_lvl: int = int(def.get("requires_level", 1))
		var req_name: String = str(req_def.get("title", req_id))
		if unlocked:
			_detail_req.text = "Требование выполнено: %s L%d" % [req_name, req_lvl]
			_detail_req.add_theme_color_override("font_color", Color(0.133, 0.773, 0.369, 1.0))
		else:
			_detail_req.text = "Требуется: %s (Ур. %d)" % [req_name, req_lvl]
			_detail_req.add_theme_color_override("font_color", Color(0.937, 0.267, 0.267, 1.0))

	if lvl >= max_lvl:
		_buy_button.text = "МАКС"
		_buy_button.disabled = true
	elif not unlocked:
		_buy_button.text = "Закрыто"
		_buy_button.disabled = true
	else:
		var cost: int = GameState.get_skill_cost(_selected_skill_id)
		_buy_button.text = "Изучить (%d)" % cost
		_buy_button.disabled = not GameState.can_afford(cost)
