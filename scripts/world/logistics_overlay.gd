class_name LogisticsOverlay
extends Node2D
## Отрисовка сетки, месторождений ресурсов, логистических связей, пакетов грузов и выстрелов.

var grid_width: int = 36
var grid_height: int = 24
var cell_size: float = 48.0
var veins: Dictionary = {} # Vector2i -> int (BuildingConfig.VeinType)
var buildings_ref: Array[BuildingEntity] = []
var selected_building: BuildingEntity = null
var hovered_cell: Vector2i = Vector2i(-1, -1)
var active_build_config: BuildingConfig = null
var can_place_at_hover: bool = false
var hover_neighbors: Array[BuildingEntity] = []
var packets: Array[Dictionary] = [] # {from, to, progress, color}
var beams: Array[Dictionary] = [] # {from, to, ttl, max_ttl, color, width}
var splashes: Array[Dictionary] = [] # {pos, radius, ttl, max_ttl, color}


func _draw() -> void:
	var total_w: float = float(grid_width) * cell_size
	var total_h: float = float(grid_height) * cell_size

	# Фон карты и ночное затемнение при смене фазы
	var bg_color: Color = Color(0.039, 0.058, 0.114, 1.0) if GameState.is_night else Color(0.059, 0.09, 0.165, 1.0)
	draw_rect(Rect2(0.0, 0.0, total_w, total_h), bg_color, true)

	# Сетка
	var grid_color := Color(0.118, 0.161, 0.231, 0.45)
	for x in range(grid_width + 1):
		var px: float = float(x) * cell_size
		draw_line(Vector2(px, 0.0), Vector2(px, total_h), grid_color, 1.0)
	for y in range(grid_height + 1):
		var py: float = float(y) * cell_size
		draw_line(Vector2(0.0, py), Vector2(total_w, py), grid_color, 1.0)

	# Граница карты
	draw_rect(Rect2(0.0, 0.0, total_w, total_h), Color(0.2, 0.27, 0.38, 0.9), false, 3.0)

	# Месторождения (4 ресурса)
	for cell in veins.keys():
		var vein_type: int = int(veins[cell])
		var center: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
		var col: Color = _get_vein_color(vein_type)
		draw_rect(Rect2(center - Vector2(cell_size * 0.42, cell_size * 0.42), Vector2.ONE * cell_size * 0.84), Color(col.r, col.g, col.b, 0.22), true)
		var pts := PackedVector2Array([
			center + Vector2(0, -13),
			center + Vector2(13, 0),
			center + Vector2(0, 13),
			center + Vector2(-13, 0),
		])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85))

	# Базовые связи логистики
	var subtle_link := Color(0.219, 0.741, 0.973, 0.16)
	for b in buildings_ref:
		if not is_instance_valid(b):
			continue
		for nb in b.neighbors:
			if is_instance_valid(nb) and b.uid < nb.uid:
				draw_line(b.position, nb.position, subtle_link, 1.5, true)

	# Выделенное здание: радиусы и яркие связи
	if is_instance_valid(selected_building):
		var link_r: float = selected_building.get_link_radius_px()
		if link_r > 0.0:
			draw_arc(selected_building.position, link_r, 0.0, TAU, 48, Color(0.219, 0.741, 0.973, 0.35), 1.5, true)
		var atk_r: float = selected_building.get_effective_attack_range_px()
		if atk_r > 0.0:
			draw_arc(selected_building.position, atk_r, 0.0, TAU, 48, Color(0.961, 0.62, 0.043, 0.45), 1.5, true)
		for nb in selected_building.neighbors:
			if is_instance_valid(nb):
				draw_line(selected_building.position, nb.position, Color(0.133, 0.827, 0.933, 0.8), 2.5, true)

	# Призрак размещения постройки (на ПК при наведении)
	if active_build_config != null and hovered_cell.x >= 0 and hovered_cell.y >= 0:
		var hover_center: Vector2 = (Vector2(hovered_cell) + Vector2(0.5, 0.5)) * cell_size
		var ghost_col: Color = Color(0.133, 0.773, 0.369, 0.4) if can_place_at_hover else Color(0.937, 0.267, 0.267, 0.45)
		draw_rect(Rect2(Vector2(hovered_cell) * cell_size + Vector2(3, 3), Vector2.ONE * (cell_size - 6)), ghost_col, true)
		if active_build_config.link_radius_cells > 0.0:
			draw_arc(hover_center, active_build_config.link_radius_cells * cell_size, 0.0, TAU, 48, Color(0.219, 0.741, 0.973, 0.35), 1.5, true)
		if active_build_config.attack_range_cells > 0.0:
			draw_arc(hover_center, active_build_config.attack_range_cells * cell_size, 0.0, TAU, 48, Color(0.961, 0.62, 0.043, 0.4), 1.5, true)
		for nb in hover_neighbors:
			if is_instance_valid(nb):
				draw_line(hover_center, nb.position, Color(0.133, 0.827, 0.933, 0.75), 2.0, true)

	# Летящие ресурсы по сети
	for pkt in packets:
		var p_from: Vector2 = pkt["from"]
		var p_to: Vector2 = pkt["to"]
		var t: float = clampf(float(pkt["progress"]), 0.0, 1.0)
		var pos: Vector2 = p_from.lerp(p_to, t)
		var p_col: Color = pkt["color"]
		draw_circle(pos, 5.0, p_col)
		draw_circle(pos, 2.2, Color(0.973, 0.98, 0.988, 0.95))

	# Взрывы от пушек
	for sp in splashes:
		var alpha: float = clampf(float(sp["ttl"]) / maxf(float(sp["max_ttl"]), 0.01), 0.0, 1.0)
		var sp_col: Color = sp["color"]
		draw_circle(sp["pos"], float(sp["radius"]) * (1.15 - alpha * 0.35), Color(sp_col.r, sp_col.g, sp_col.b, alpha * 0.35))

	# Лучи/выстрелы башен
	for bm in beams:
		var b_alpha: float = clampf(float(bm["ttl"]) / maxf(float(bm["max_ttl"]), 0.01), 0.0, 1.0)
		var b_col: Color = bm["color"]
		draw_line(bm["from"], bm["to"], Color(b_col.r, b_col.g, b_col.b, b_alpha), float(bm["width"]), true)


func _get_vein_color(vein_type: int) -> Color:
	match vein_type:
		BuildingConfig.VeinType.CRYSTAL:
			return Color(0.937, 0.267, 0.267, 1.0)
		BuildingConfig.VeinType.WOOD:
			return Color(0.961, 0.62, 0.043, 1.0)
		BuildingConfig.VeinType.IRON:
			return Color(0.58, 0.639, 0.722, 1.0)
		BuildingConfig.VeinType.URANIUM:
			return Color(0.133, 0.773, 0.369, 1.0)
		_:
			return Color.WHITE
