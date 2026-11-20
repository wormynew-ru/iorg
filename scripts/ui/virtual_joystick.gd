extends Control
## Виртуальный аналоговый джойстик с поддержкой мультитача (Android) и мыши (тест на ПК).

signal joystick_moved(move_vector: Vector2)

@export var max_radius: float = 58.0
@export var knob_radius: float = 24.0
@export var deadzone_ratio: float = 0.14

var _touch_index: int = -1
var _mouse_dragging: bool = false
var _stick_offset: Vector2 = Vector2.ZERO
var _output_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _exit_tree() -> void:
	_reset_stick()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if _touch_index != -1 or _mouse_dragging:
			_reset_stick()
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			if _touch_index == -1 and get_global_rect().has_point(touch_event.position):
				_touch_index = touch_event.index
				_update_stick_from_global_pos(touch_event.position)
				get_viewport().set_input_as_handled()
		elif touch_event.index == _touch_index:
			_reset_stick()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		if drag_event.index == _touch_index:
			_update_stick_from_global_pos(drag_event.position)
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if DisplayServer.is_touchscreen_available():
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_dragging = true
				_update_stick_from_local_pos(mb.position)
			else:
				_reset_stick()
			accept_event()
	elif event is InputEventMouseMotion and _mouse_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_update_stick_from_local_pos(mm.position)
		accept_event()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, max_radius, Color(0.059, 0.09, 0.165, 0.55))
	draw_arc(center, max_radius, 0.0, TAU, 48, Color(0.133, 0.827, 0.933, 0.65), 2.5, true)
	draw_circle(center + _stick_offset, knob_radius, Color(0.133, 0.827, 0.933, 0.85))
	draw_arc(center + _stick_offset, knob_radius, 0.0, TAU, 32, Color(0.973, 0.98, 0.988, 0.9), 2.0, true)


func _update_stick_from_global_pos(global_pos: Vector2) -> void:
	var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * global_pos
	_update_stick_from_local_pos(local_pos)


func _update_stick_from_local_pos(local_pos: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var delta: Vector2 = local_pos - center
	_stick_offset = delta.limit_length(max_radius)

	var normalized: Vector2 = _stick_offset / maxf(max_radius, 1.0)
	if normalized.length() < deadzone_ratio:
		_output_vector = Vector2.ZERO
	else:
		_output_vector = normalized

	joystick_moved.emit(_output_vector)
	queue_redraw()


func _reset_stick() -> void:
	_touch_index = -1
	_mouse_dragging = false
	_stick_offset = Vector2.ZERO
	if _output_vector != Vector2.ZERO:
		_output_vector = Vector2.ZERO
		joystick_moved.emit(Vector2.ZERO)
	queue_redraw()
