class_name StrategicCamera
extends Camera2D
## Стратегическая камера для 2D-сетки (ПК: WASD, ПКМ/СКМ, колесо; Android: свайп и щипок).

signal world_tapped(world_position: Vector2)
signal secondary_tapped

@export var pan_speed: float = 640.0
@export var min_zoom: float = 0.55
@export var max_zoom: float = 1.85
@export var zoom_step: float = 0.14
@export var drag_threshold_px: float = 12.0

var _world_bounds: Rect2 = Rect2(0, 0, 1728, 1152)
var _mouse_panning: bool = false
var _active_touches: Dictionary = {}
var _primary_touch_id: int = -1
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_moved: bool = false
var _last_pinch_dist: float = 0.0
var _left_press_pos: Vector2 = Vector2.ZERO
var _left_pressing: bool = false


func _ready() -> void:
	EventBus.camera_zoom_requested.connect(_on_zoom_requested)
	EventBus.camera_center_requested.connect(_on_center_requested)


func configure_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds
	limit_left = int(bounds.position.x) - 160
	limit_top = int(bounds.position.y) - 140
	limit_right = int(bounds.end.x) + 160
	limit_bottom = int(bounds.end.y) + 180
	_clamp_position()


func center_on(world_pos: Vector2) -> void:
	global_position = world_pos
	_clamp_position()


func _process(delta: float) -> void:
	var move_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir.length_squared() > 0.001:
		global_position += move_dir * (pan_speed / zoom.x) * delta
		_clamp_position()

	if Input.is_action_just_pressed("zoom_in"):
		_apply_zoom(1.0 + zoom_step)
	elif Input.is_action_just_pressed("zoom_out"):
		_apply_zoom(1.0 / (1.0 + zoom_step))

	GameState.camera_position = global_position
	GameState.camera_zoom = zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(1.0 + zoom_step)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(1.0 / (1.0 + zoom_step))
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_mouse_panning = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_mouse_panning = true
				_left_press_pos = mb.position
			else:
				if _mouse_panning and _left_press_pos.distance_to(mb.position) < drag_threshold_px:
					secondary_tapped.emit()
				_mouse_panning = false
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_left_pressing = true
				_left_press_pos = mb.position
			elif _left_pressing:
				_left_pressing = false
				if _left_press_pos.distance_to(mb.position) < drag_threshold_px:
					world_tapped.emit(get_global_mouse_position())
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _mouse_panning:
			global_position -= mm.relative / zoom.x
			_clamp_position()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_active_touches[st.index] = st.position
			if _active_touches.size() == 1:
				_primary_touch_id = st.index
				_touch_start_pos = st.position
				_touch_moved = false
			elif _active_touches.size() == 2:
				_touch_moved = true
				var pts: Array = _active_touches.values()
				_last_pinch_dist = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
		else:
			if st.index == _primary_touch_id and not _touch_moved and _active_touches.size() == 1:
				var world_pos: Vector2 = get_canvas_transform().affine_inverse() * st.position
				world_tapped.emit(world_pos)
			_active_touches.erase(st.index)
			if _active_touches.is_empty():
				_primary_touch_id = -1
				_touch_moved = false

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		_active_touches[sd.index] = sd.position
		if _active_touches.size() == 1 and sd.index == _primary_touch_id:
			if _touch_start_pos.distance_to(sd.position) >= drag_threshold_px:
				_touch_moved = true
			if _touch_moved:
				global_position -= sd.relative / zoom.x
				_clamp_position()
		elif _active_touches.size() >= 2:
			_touch_moved = true
			var pts: Array = _active_touches.values()
			var current_dist: float = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
			if _last_pinch_dist > 10.0 and current_dist > 10.0:
				_apply_zoom(current_dist / _last_pinch_dist)
			_last_pinch_dist = current_dist


func _apply_zoom(factor: float) -> void:
	var new_zoom: float = clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	GameState.camera_zoom = new_zoom


func _clamp_position() -> void:
	global_position.x = clampf(global_position.x, _world_bounds.position.x, _world_bounds.end.x)
	global_position.y = clampf(global_position.y, _world_bounds.position.y, _world_bounds.end.y)


func _on_zoom_requested(factor: float) -> void:
	_apply_zoom(factor)


func _on_center_requested() -> void:
	center_on(_world_bounds.get_center())
