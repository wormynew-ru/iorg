class_name BuildingConfig
extends Resource
## Конфигурация типа здания для сетки и логистики в духе YORG.io.

enum Category { CORE, HARVESTER, LOGISTICS, FACTORY, DEFENSE }
enum VeinType { NONE, CRYSTAL, WOOD, IRON, URANIUM }
enum ResourceKind { NONE, CRYSTAL, WOOD, IRON, URANIUM, ARROWS, CANNONBALLS, ENERGY }

@export var building_id: String = "building"
@export var display_name: String = "Здание"
@export var short_label: String = "Зд."
@export var category: Category = Category.LOGISTICS
@export var cost_crystals: int = 20
@export var max_hp: float = 120.0
@export var required_vein: VeinType = VeinType.NONE
@export var input_kind: ResourceKind = ResourceKind.NONE
@export var output_kind: ResourceKind = ResourceKind.NONE
@export var production_interval: float = 1.5
@export var output_per_cycle: int = 1
@export var storage_capacity: int = 12
@export var link_radius_cells: float = 3.6
@export var transport_interval: float = 0.45
@export var attack_range_cells: float = 0.0
@export var attack_cooldown: float = 0.8
@export var attack_damage: float = 0.0
@export var splash_radius_px: float = 0.0
@export var chain_count: int = 1
@export var accent_color: Color = Color(0.133, 0.827, 0.933, 1.0)
@export var description: String = ""
