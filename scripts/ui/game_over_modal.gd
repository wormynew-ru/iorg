extends Control
## Экран поражения при уничтожении Базы с отображением пост-забеговых наград.

signal sanctuary_requested
signal restart_requested
signal main_menu_requested

@onready var _summary_label: Label = $CenterContainer/Panel/Margin/VBox/SummaryLabel
@onready var _rewards_label: Label = $CenterContainer/Panel/Margin/VBox/RewardsLabel
@onready var _sanctuary_button: Button = $CenterContainer/Panel/Margin/VBox/SanctuaryButton
@onready var _restart_button: Button = $CenterContainer/Panel/Margin/VBox/RestartButton
@onready var _menu_button: Button = $CenterContainer/Panel/Margin/VBox/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_sanctuary_button.pressed.connect(func() -> void: sanctuary_requested.emit())
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func open_modal(days_survived: int, kills: int, rewards: Dictionary = {}) -> void:
	var rec_tag: String = "  [НОВЫЙ РЕКОРД!]" if bool(rewards.get("is_new_record", false)) else ""
	_summary_label.text = "База уничтожена на %d-й день%s\nУничтожено врагов: %d" % [days_survived, rec_tag, kills]

	var ess: int = int(rewards.get("essence_gained", 0))
	var sds: int = int(rewards.get("seeds_gained", 0))
	var lines: Array[String] = [
		"Трофеи забега: +%d Эссенции • +%d Семян" % [ess, sds],
	]
	var art_id: String = str(rewards.get("dropped_artifact_id", ""))
	if not art_id.is_empty() and MetaProgression.ARTIFACT_DEFS.has(art_id):
		var art_title: String = str((MetaProgression.ARTIFACT_DEFS[art_id] as Dictionary).get("title", art_id))
		lines.append("Найден артефакт: %s!" % art_title)
	_rewards_label.text = "\n".join(lines)
	visible = true
