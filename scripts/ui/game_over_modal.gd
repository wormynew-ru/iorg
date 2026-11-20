extends Control
## Экран поражения при уничтожении Базы.

signal restart_requested
signal main_menu_requested

@onready var _summary_label: Label = $CenterContainer/Panel/Margin/VBox/SummaryLabel
@onready var _restart_button: Button = $CenterContainer/Panel/Margin/VBox/RestartButton
@onready var _menu_button: Button = $CenterContainer/Panel/Margin/VBox/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func open_modal(days_survived: int, kills: int) -> void:
	_summary_label.text = "База уничтожена на %d-й день\nУничтожено врагов: %d" % [days_survived, kills]
	visible = true
