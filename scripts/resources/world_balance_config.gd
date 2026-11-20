class_name WorldBalanceConfig
extends Resource
## Общий баланс карты, цикла дня/ночи и наград за выживание.

@export var grid_width: int = 36
@export var grid_height: int = 24
@export var cell_size: float = 48.0
@export var starting_crystals: int = 180
@export var first_day_duration: float = 55.0
@export var day_duration: float = 28.0
@export var night_duration: float = 32.0
@export var night_reward_base: int = 40
@export var night_reward_per_day: int = 15
@export var crystal_vein_count: int = 8
@export var wood_vein_count: int = 10
@export var iron_vein_count: int = 8
@export var uranium_vein_count: int = 5

@export_group("Wave Complexity Scaling")
@export var wave_base_count: int = 5
@export var wave_linear_per_day: float = 3.0
@export var wave_superlinear_coeff: float = 0.65
@export var wave_superlinear_power: float = 1.32
@export var enemy_hp_linear_per_day: float = 0.14
@export var enemy_hp_superlinear_coeff: float = 0.018
@export var enemy_hp_superlinear_power: float = 1.35
@export var enemy_dmg_linear_per_day: float = 0.08
@export var enemy_dmg_superlinear_coeff: float = 0.008
@export var enemy_dmg_superlinear_power: float = 1.25
@export var enemy_speed_per_day: float = 0.015
@export var enemy_speed_max_mult: float = 1.45

