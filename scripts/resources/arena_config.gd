class_name ArenaConfig
extends Resource
## Конфигурация параметров 2D-арены и начисления очков.

@export var arena_id: String = "arena_01"
@export var arena_size: Vector2 = Vector2(1920.0, 1280.0)
@export var default_spawn_position: Vector2 = Vector2(960.0, 640.0)
@export var orb_score_value: int = 10
@export var camera_smoothing_speed: float = 8.0
