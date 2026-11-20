extends Control
## Меню паузы: продолжить, ручное сохранение, сброс прогресса, настройки и выход.

signal resume_requested
signal settings_requested
signal main_menu_requested

@onready var _resume_button: Button = $CenterContainer/Panel/Margin/VBox/ResumeButton
@onready var _save_button: Button = $CenterContainer/Panel/Margin/VBox/SaveButton
@onready var _reset_save_button: Button = $CenterContainer/Panel/Margin/VBox/ResetSaveButton
@onready var _settings_button: Button = $CenterContainer/Panel/Margin/VBox/SettingsButton
@onready var _main_menu_button: Button = $CenterContainer/Panel/Margin/VBox/MainMenuButton
@onready var _status_label: Label = $CenterContainer/Panel/Margin/VBox/StatusLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_status_label.text = ""

	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_save_button.pressed.connect(_on_save_pressed)
	_reset_save_button.pressed.connect(_on_reset_save_pressed)
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func _on_save_pressed() -> void:
	var ok: bool = SaveManager.save_game()
	_status_label.text = "Прогресс сохранён" if ok else "Ошибка сохранения"


func _on_reset_save_pressed() -> void:
	var ok: bool = SaveManager.delete_save()
	_status_label.text = "Сохранение сброшено" if ok else "Не удалось удалить сохранение"
