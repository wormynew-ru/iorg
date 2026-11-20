extends Control
## Модальное окно настроек (громкость, режим сенсорного управления, экран).

@onready var _master_slider: HSlider = $CenterContainer/Panel/Margin/VBox/MasterRow/MasterSlider
@onready var _master_value_label: Label = $CenterContainer/Panel/Margin/VBox/MasterRow/MasterValue
@onready var _sfx_slider: HSlider = $CenterContainer/Panel/Margin/VBox/SfxRow/SfxSlider
@onready var _sfx_value_label: Label = $CenterContainer/Panel/Margin/VBox/SfxRow/SfxValue
@onready var _touch_mode_option: OptionButton = $CenterContainer/Panel/Margin/VBox/TouchRow/TouchModeOption
@onready var _fullscreen_row: HBoxContainer = $CenterContainer/Panel/Margin/VBox/FullscreenRow
@onready var _fullscreen_check: CheckButton = $CenterContainer/Panel/Margin/VBox/FullscreenRow/FullscreenCheck
@onready var _close_button: Button = $CenterContainer/Panel/Margin/VBox/CloseButton

var _syncing_ui: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_touch_mode_option.clear()
	_touch_mode_option.add_item("Авто (экран)", 0)
	_touch_mode_option.add_item("Всегда вкл.", 1)
	_touch_mode_option.add_item("Выключено", 2)

	_fullscreen_row.visible = not SettingsManager.is_mobile_platform()

	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_touch_mode_option.item_selected.connect(_on_touch_mode_selected)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_close_button.pressed.connect(hide_modal)


func open_modal() -> void:
	_sync_from_manager()
	visible = true


func hide_modal() -> void:
	visible = false


func _sync_from_manager() -> void:
	_syncing_ui = true
	_master_slider.value = SettingsManager.master_volume * 100.0
	_sfx_slider.value = SettingsManager.sfx_volume * 100.0
	_update_volume_labels()

	match SettingsManager.touch_mode:
		SettingsManager.TOUCH_MODE_ON:
			_touch_mode_option.select(1)
		SettingsManager.TOUCH_MODE_OFF:
			_touch_mode_option.select(2)
		_:
			_touch_mode_option.select(0)

	_fullscreen_check.button_pressed = SettingsManager.fullscreen
	_syncing_ui = false


func _update_volume_labels() -> void:
	_master_value_label.text = "%d%%" % int(round(_master_slider.value))
	_sfx_value_label.text = "%d%%" % int(round(_sfx_slider.value))


func _on_master_changed(value: float) -> void:
	_update_volume_labels()
	if _syncing_ui:
		return
	SettingsManager.set_master_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	_update_volume_labels()
	if _syncing_ui:
		return
	SettingsManager.set_sfx_volume(value / 100.0)


func _on_touch_mode_selected(index: int) -> void:
	if _syncing_ui:
		return
	match index:
		1:
			SettingsManager.set_touch_mode(SettingsManager.TOUCH_MODE_ON)
		2:
			SettingsManager.set_touch_mode(SettingsManager.TOUCH_MODE_OFF)
		_:
			SettingsManager.set_touch_mode(SettingsManager.TOUCH_MODE_AUTO)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if _syncing_ui:
		return
	SettingsManager.set_fullscreen(toggled_on)
