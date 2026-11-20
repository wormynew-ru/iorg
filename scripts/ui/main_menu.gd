extends Control
## Логика главного меню: запуск новой игры, продолжение с сохранения и настройки.

@onready var _continue_button: Button = $CenterContainer/Panel/Margin/VBox/Buttons/ContinueButton
@onready var _new_game_button: Button = $CenterContainer/Panel/Margin/VBox/Buttons/NewGameButton
@onready var _settings_button: Button = $CenterContainer/Panel/Margin/VBox/Buttons/SettingsButton
@onready var _quit_button: Button = $CenterContainer/Panel/Margin/VBox/Buttons/QuitButton
@onready var _save_info_label: Label = $CenterContainer/Panel/Margin/VBox/SaveInfoLabel
@onready var _settings_modal: Control = $SettingsModal


func _ready() -> void:
	get_tree().paused = false
	_quit_button.visible = not SettingsManager.is_mobile_platform()

	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	EventBus.save_deleted.connect(_refresh_save_ui)

	_refresh_save_ui()


func _refresh_save_ui() -> void:
	var has_existing_save: bool = SaveManager.has_save()
	_continue_button.disabled = not has_existing_save
	if not has_existing_save:
		_save_info_label.text = "Нет сохранённого прогресса"
		return

	var save_data: Dictionary = SaveManager.load_game()
	if save_data.is_empty():
		_continue_button.disabled = true
		_save_info_label.text = "Сохранение повреждено или устарело"
		return

	var saved_score: int = int(save_data.get("score", 0))
	var collected: Variant = save_data.get("collected_ids", [])
	var collected_count: int = collected.size() if collected is Array else 0
	_save_info_label.text = "Сохранение: счёт %d • сфер собрано: %d" % [saved_score, collected_count]


func _on_continue_pressed() -> void:
	if SaveManager.load_into_state():
		GameState.should_load_from_save = true
		get_tree().change_scene_to_file("res://scenes/game/game_arena.tscn")


func _on_new_game_pressed() -> void:
	var arena_cfg: ArenaConfig = load("res://resources/balance/default_arena_config.tres") as ArenaConfig
	var spawn_pos: Vector2 = arena_cfg.default_spawn_position if arena_cfg != null else Vector2(960.0, 640.0)
	var target_arena: String = arena_cfg.arena_id if arena_cfg != null else "arena_01"
	GameState.reset_for_new_game(spawn_pos, target_arena)
	get_tree().change_scene_to_file("res://scenes/game/game_arena.tscn")


func _on_settings_pressed() -> void:
	_settings_modal.open_modal()


func _on_quit_pressed() -> void:
	get_tree().quit()
