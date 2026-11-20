class_name EnemyEntity
extends Node2D
## Враг ночной волны (зомби / босс) с отрисовкой и полоской HP.

var config: EnemyConfig
var hp: float = 40.0
var max_hp: float = 40.0
var attack_damage: float = 10.0
var move_speed: float = 55.0
var attack_timer: float = 0.0
var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var repath_timer: float = 0.0


func setup(p_config: EnemyConfig, hp_scale: float, dmg_scale: float, speed_scale: float, spawn_pos: Vector2) -> void:
	config = p_config
	max_hp = p_config.max_hp * hp_scale
	hp = max_hp
	attack_damage = p_config.attack_damage * dmg_scale
	move_speed = p_config.move_speed * speed_scale
	position = spawn_pos
	queue_redraw()


func take_damage(amount: float) -> bool:
	hp = maxf(0.0, hp - amount)
	queue_redraw()
	return hp <= 0.0


func _draw() -> void:
	if config == null:
		return

	var r: float = config.radius_px
	draw_circle(Vector2.ZERO, r, config.body_color)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(0.059, 0.09, 0.165, 0.95), 2.0, true)

	if config.is_boss:
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 24, Color(0.961, 0.62, 0.043, 0.95), 2.5, true)

	if hp < max_hp or config.is_boss:
		var ratio: float = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
		var bar_w: float = r * 2.2
		draw_rect(Rect2(-bar_w * 0.5, -r - 8.0, bar_w, 3.5), Color(0.15, 0.05, 0.05, 0.9), true)
		draw_rect(Rect2(-bar_w * 0.5, -r - 8.0, bar_w * ratio, 3.5), Color(0.937, 0.267, 0.267, 1.0), true)
