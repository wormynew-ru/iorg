extends Control
## Отрисовка соединительных линий между узлами древа талантов.

var node_buttons: Dictionary = {} # skill_id -> Button


func _draw() -> void:
	if node_buttons.is_empty():
		return

	var canvas_origin: Vector2 = global_position
	for skill_id in GameState.TALENT_ORDER:
		var def: Dictionary = GameState.get_talent_def(skill_id)
		var req_id: String = str(def.get("requires_id", ""))
		if req_id.is_empty():
			continue
		if not node_buttons.has(skill_id) or not node_buttons.has(req_id):
			continue

		var child_btn: Button = node_buttons[skill_id] as Button
		var parent_btn: Button = node_buttons[req_id] as Button
		if not is_instance_valid(child_btn) or not is_instance_valid(parent_btn):
			continue

		var p_start: Vector2 = parent_btn.get_global_rect().get_center() - canvas_origin
		var p_end: Vector2 = child_btn.get_global_rect().get_center() - canvas_origin

		var unlocked: bool = GameState.is_talent_unlocked(skill_id)
		var child_lvl: int = GameState.get_skill_level(skill_id)
		var branch_color: Color = def.get("color", Color.WHITE) as Color

		var line_color: Color = Color(0.28, 0.34, 0.45, 0.55)
		var line_w: float = 3.0
		if child_lvl > 0:
			line_color = branch_color
			line_w = 4.5
		elif unlocked:
			line_color = Color(branch_color.r, branch_color.g, branch_color.b, 0.65)
			line_w = 3.5

		draw_line(p_start, p_end, line_color, line_w, true)
