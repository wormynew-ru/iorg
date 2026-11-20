extends Control
## Модальное окно древа навыков за кристаллы (добыча, логистика/телепорт, склады, урон).

@onready var _crystals_label: Label = $CenterContainer/Panel/Margin/VBox/CrystalsLabel
@onready var _mining_btn: Button = $CenterContainer/Panel/Margin/VBox/MiningRow/UpgradeButton
@onready var _mining_lvl: Label = $CenterContainer/Panel/Margin/VBox/MiningRow/InfoLabel
@onready var _transport_btn: Button = $CenterContainer/Panel/Margin/VBox/TransportRow/UpgradeButton
@onready var _transport_lvl: Label = $CenterContainer/Panel/Margin/VBox/TransportRow/InfoLabel
@onready var _storage_btn: Button = $CenterContainer/Panel/Margin/VBox/StorageRow/UpgradeButton
@onready var _storage_lvl: Label = $CenterContainer/Panel/Margin/VBox/StorageRow/InfoLabel
@onready var _damage_btn: Button = $CenterContainer/Panel/Margin/VBox/DamageRow/UpgradeButton
@onready var _damage_lvl: Label = $CenterContainer/Panel/Margin/VBox/DamageRow/InfoLabel
@onready var _close_button: Button = $CenterContainer/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_mining_btn.pressed.connect(func() -> void: _buy("mining_speed"))
	_transport_btn.pressed.connect(func() -> void: _buy("transport_speed"))
	_storage_btn.pressed.connect(func() -> void: _buy("storage_capacity"))
	_damage_btn.pressed.connect(func() -> void: _buy("tower_damage"))
	_close_button.pressed.connect(hide_modal)


func open_modal() -> void:
	_refresh_ui()
	visible = true


func hide_modal() -> void:
	visible = false


func _buy(skill_id: String) -> void:
	if GameState.upgrade_skill(skill_id):
		_refresh_ui()


func _refresh_ui() -> void:
	_crystals_label.text = "Доступно кристаллов: %d" % GameState.crystals
	_update_row("mining_speed", "Добыча и заводы (+25%/ур.)", _mining_lvl, _mining_btn)
	_update_row("transport_speed", "Логистика (+30%/ур., L3 = Телепорт)", _transport_lvl, _transport_btn)
	_update_row("storage_capacity", "Склады и боезапас (+50%/ур.)", _storage_lvl, _storage_btn)
	_update_row("tower_damage", "Урон башен (+22%/ур.)", _damage_lvl, _damage_btn)


func _update_row(skill_id: String, title: String, label: Label, btn: Button) -> void:
	var lvl: int = GameState.get_skill_level(skill_id)
	label.text = "%s — L%d/%d" % [title, lvl, GameState.MAX_SKILL_LEVEL]
	if lvl >= GameState.MAX_SKILL_LEVEL:
		btn.text = "МАКС"
		btn.disabled = true
	else:
		var cost: int = GameState.get_skill_cost(skill_id)
		btn.text = "Изучить (%d)" % cost
		btn.disabled = not GameState.can_afford(cost)
