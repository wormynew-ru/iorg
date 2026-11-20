extends Control
## Контейнер сенсорного управления (левый джойстик + правая кнопка рывка).

signal move_vector_changed(move_vector: Vector2)
signal dash_pressed

@onready var _joystick: Control = $SafeMargin/HBox/LeftZone/VirtualJoystick
@onready var _dash_button: Button = $SafeMargin/HBox/RightZone/DashButton


func _ready() -> void:
	_joystick.joystick_moved.connect(_on_joystick_moved)
	_dash_button.button_down.connect(_on_dash_button_down)
	EventBus.touch_mode_changed.connect(_on_touch_mode_changed)
	_update_visibility()


func _update_visibility() -> void:
	visible = SettingsManager.is_touch_controls_visible()
	if not visible:
		move_vector_changed.emit(Vector2.ZERO)


func _on_touch_mode_changed(_mode: String) -> void:
	_update_visibility()


func _on_joystick_moved(move_vector: Vector2) -> void:
	move_vector_changed.emit(move_vector)


func _on_dash_button_down() -> void:
	dash_pressed.emit()
