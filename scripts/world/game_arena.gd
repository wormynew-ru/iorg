extends Node2D
## Основная игровая сцена 2D-арены с восстановлением прогресса и автосейвом.

@export var arena_config: ArenaConfig

@onready var _player: Player = $World/Player
@onready var _orbs_container: Node2D = $World/Orbs
@onready var _hud: CanvasLayer = $HUD
@onready var _pause_menu: Control = $PauseLayer/PauseMenu
@onready var _settings_modal: Control = $PauseLayer/SettingsModal


func _ready() -> void:
	get_tree().paused = false
	if arena_config == null:
		arena_config = ArenaConfig.new()

	GameState.arena_id = arena_config.arena_id
	GameState.total_orbs = _orbs_container.get_child_count()

	if GameState.should_load_from_save and GameState.has_custom_position:
		_player.global_position = GameState.player_position
	else:
		_player.global_position = arena_config.default_spawn_position
		GameState.player_position = _player.global_position

	GameState.should_load_from_save = false
	_player.configure_camera_limits(arena_config.arena_size, arena_config.camera_smoothing_speed)

	for orb_node in _orbs_container.get_children():
		if orb_node is EnergyOrb:
			var orb: EnergyOrb = orb_node as EnergyOrb
			orb.score_value = arena_config.orb_score_value

	_connect_hud_and_menus()
	EventBus.score_changed.emit(GameState.score, GameState.collected_ids.size(), GameState.total_orbs)


func _process(delta: float) -> void:
	if not get_tree().paused:
		GameState.elapsed_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _settings_modal.visible:
			_settings_modal.hide_modal()
		else:
			_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game()


func _connect_hud_and_menus() -> void:
	var touch_controls: Control = _hud.get_node_or_null("TouchControls")
	if touch_controls != null:
		if touch_controls.has_signal("move_vector_changed"):
			touch_controls.move_vector_changed.connect(_player.set_touch_move_vector)
		if touch_controls.has_signal("dash_pressed"):
			touch_controls.dash_pressed.connect(_player.trigger_dash)

	if not EventBus.game_pause_requested.is_connected(_on_game_pause_requested):
		EventBus.game_pause_requested.connect(_on_game_pause_requested)

	if _pause_menu.has_signal("resume_requested"):
		_pause_menu.resume_requested.connect(_on_resume_requested)
	if _pause_menu.has_signal("settings_requested"):
		_pause_menu.settings_requested.connect(_on_settings_requested)
	if _pause_menu.has_signal("main_menu_requested"):
		_pause_menu.main_menu_requested.connect(_on_main_menu_requested)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused
	if paused:
		SaveManager.save_game()


func _on_game_pause_requested(paused: bool) -> void:
	_set_paused(paused)


func _on_resume_requested() -> void:
	_set_paused(false)


func _on_settings_requested() -> void:
	_settings_modal.open_modal()


func _on_main_menu_requested() -> void:
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
