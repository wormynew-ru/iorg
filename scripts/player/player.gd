class_name Player
extends CharacterBody2D
## Контроллер 2D-персонажа с поддержкой клавиатуры/геймпада, сенсорного джойстика и рывка.

@export var config: PlayerConfig

@onready var _body_visual: Polygon2D = $BodyVisual
@onready var _direction_marker: Polygon2D = $DirectionMarker
@onready var _camera: Camera2D = $Camera2D

var _touch_move_vector: Vector2 = Vector2.ZERO
var _facing_direction: Vector2 = Vector2.RIGHT
var _dash_direction: Vector2 = Vector2.RIGHT
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()


func _physics_process(delta: float) -> void:
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)

	var input_vector: Vector2 = _get_combined_move_vector()
	if input_vector.length_squared() > 0.01:
		_facing_direction = input_vector.normalized()
		_direction_marker.rotation = _facing_direction.angle()

	if Input.is_action_just_pressed("dash"):
		trigger_dash()

	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)
		velocity = _dash_direction * config.dash_speed
		if _dash_timer <= 0.0:
			_body_visual.scale = Vector2.ONE
			_body_visual.color = Color(0.133, 0.827, 0.933, 1.0)
	else:
		if input_vector.length_squared() > 0.01:
			var target_velocity: Vector2 = input_vector * config.move_speed
			velocity = velocity.move_toward(target_velocity, config.acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, config.friction * delta)

	move_and_slide()
	GameState.player_position = global_position


func set_touch_move_vector(move_vector: Vector2) -> void:
	_touch_move_vector = move_vector.limit_length(1.0)


func trigger_dash() -> void:
	if _dash_timer > 0.0 or _dash_cooldown_timer > 0.0:
		return
	var input_vector: Vector2 = _get_combined_move_vector()
	_dash_direction = input_vector.normalized() if input_vector.length_squared() > 0.01 else _facing_direction
	_dash_timer = config.dash_duration
	_dash_cooldown_timer = config.dash_cooldown
	_body_visual.scale = Vector2(1.18, 0.86)
	_body_visual.color = Color(0.647, 0.953, 0.988, 1.0)
	EventBus.dash_triggered.emit(config.dash_cooldown)


func configure_camera_limits(arena_size: Vector2, smoothing_speed: float) -> void:
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = smoothing_speed
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(arena_size.x)
	_camera.limit_bottom = int(arena_size.y)


func _get_combined_move_vector() -> Vector2:
	var keyboard_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var combined: Vector2 = keyboard_vector + _touch_move_vector
	if combined.length() > 1.0:
		combined = combined.normalized()
	return combined
