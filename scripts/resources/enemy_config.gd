class_name EnemyConfig
extends Resource
## Конфигурация типа врага (ночные волны и боссы).

@export var enemy_id: String = "zombie_basic"
@export var display_name: String = "Зомби"
@export var max_hp: float = 45.0
@export var move_speed: float = 78.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.9
@export var reward_crystals: int = 3
@export var radius_px: float = 12.0
@export var body_color: Color = Color(0.518, 0.8, 0.086, 1.0)
@export var is_boss: bool = false
