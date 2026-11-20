extends Node
## Менеджер пользовательских настроек в ConfigFile (user://settings.cfg).

const SETTINGS_PATH: String = "user://settings.cfg"
const TOUCH_MODE_AUTO: String = "auto"
const TOUCH_MODE_ON: String = "always_on"
const TOUCH_MODE_OFF: String = "always_off"

var master_volume: float = 0.85
var sfx_volume: float = 0.85
var touch_mode: String = TOUCH_MODE_AUTO
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply_all_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	if err != OK:
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", 0.85)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 0.85)), 0.0, 1.0)
	var loaded_touch: String = str(config.get_value("controls", "touch_mode", TOUCH_MODE_AUTO))
	if loaded_touch in [TOUCH_MODE_AUTO, TOUCH_MODE_ON, TOUCH_MODE_OFF]:
		touch_mode = loaded_touch
	else:
		touch_mode = TOUCH_MODE_AUTO
	fullscreen = bool(config.get_value("display", "fullscreen", false))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("controls", "touch_mode", touch_mode)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func apply_all_settings() -> void:
	AudioManager.set_bus_volume("Master", master_volume)
	AudioManager.set_bus_volume("SFX", sfx_volume)
	_apply_display_mode()
	EventBus.touch_mode_changed.emit(touch_mode)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioManager.set_bus_volume("Master", master_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	AudioManager.set_bus_volume("SFX", sfx_volume)
	save_settings()


func set_touch_mode(mode: String) -> void:
	if not (mode in [TOUCH_MODE_AUTO, TOUCH_MODE_ON, TOUCH_MODE_OFF]):
		return
	touch_mode = mode
	EventBus.touch_mode_changed.emit(touch_mode)
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_display_mode()
	save_settings()


func is_touch_controls_visible() -> bool:
	match touch_mode:
		TOUCH_MODE_ON:
			return true
		TOUCH_MODE_OFF:
			return false
		_:
			return DisplayServer.is_touchscreen_available()


func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]


func _apply_display_mode() -> void:
	if is_mobile_platform():
		return
	var target_mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)
