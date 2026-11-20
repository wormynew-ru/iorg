class_name ObstacleBlock
extends StaticBody2D
## Базовое твёрдое препятствие на 2D-арене с настраиваемым размером.

@export var block_size: Vector2 = Vector2(160.0, 48.0)
@export var fill_color: Color = Color(0.937, 0.267, 0.267, 1.0)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _fill: ColorRect = $Fill


func _ready() -> void:
	if _collision.shape is RectangleShape2D:
		var duplicated_shape: RectangleShape2D = _collision.shape.duplicate() as RectangleShape2D
		duplicated_shape.size = block_size
		_collision.shape = duplicated_shape

	_fill.size = block_size
	_fill.position = -block_size * 0.5
	_fill.color = fill_color
