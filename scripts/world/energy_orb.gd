class_name EnergyOrb
extends Area2D
## Собираемая энергетическая сфера с сохранением статуса сбора по уникальному ID.

@export var orb_id: String = ""
@export var score_value: int = 10

@onready var _visual: Polygon2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _collected: bool = false
var _idle_tween: Tween = null


func _ready() -> void:
	if orb_id.is_empty():
		orb_id = name

	if GameState.is_orb_collected(orb_id):
		queue_free()
		return

	body_entered.connect(_on_body_entered)
	_start_idle_animation()


func _start_idle_animation() -> void:
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.tween_property(_visual, "scale", Vector2(1.12, 1.12), 0.7).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_visual, "scale", Vector2(0.95, 0.95), 0.7).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return

	_collected = true
	_collision.set_deferred("disabled", true)
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()

	GameState.register_orb_collected(orb_id, score_value)
	SaveManager.save_game()

	var collect_tween: Tween = create_tween()
	collect_tween.set_parallel(true)
	collect_tween.tween_property(_visual, "scale", Vector2(1.7, 1.7), 0.18).set_trans(Tween.TRANS_QUAD)
	collect_tween.tween_property(_visual, "modulate:a", 0.0, 0.18)
	collect_tween.chain().tween_callback(queue_free)
