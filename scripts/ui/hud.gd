extends CanvasLayer
## Игровой HUD: счёт, количество сфер, индикатор сохранения, кнопка паузы.

@onready var _score_label: Label = $SafeMargin/TopBar/ScorePanel/Margin/HBox/ScoreLabel
@onready var _orbs_label: Label = $SafeMargin/TopBar/ScorePanel/Margin/HBox/OrbsLabel
@onready var _save_toast: Label = $SafeMargin/TopBar/RightActions/SaveToastLabel
@onready var _pause_button: Button = $SafeMargin/TopBar/RightActions/PauseButton
@onready var _controls_hint: Label = $SafeMargin/ControlsHintLabel

var _toast_tween: Tween = null


func _ready() -> void:
	_save_toast.modulate.a = 0.0
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.save_completed.connect(_on_save_completed)
	EventBus.touch_mode_changed.connect(_on_touch_mode_changed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_update_controls_hint()


func _update_controls_hint() -> void:
	if SettingsManager.is_touch_controls_visible():
		_controls_hint.text = "Джойстик: движение • Кнопка справа: рывок"
	else:
		_controls_hint.text = "WASD / Стрелки: движение • Space/Shift: рывок • Esc: пауза"


func _on_touch_mode_changed(_mode: String) -> void:
	_update_controls_hint()


func _on_score_changed(new_score: int, collected_count: int, total_orbs: int) -> void:
	_score_label.text = "Счёт: %d" % new_score
	_orbs_label.text = "Сферы: %d / %d" % [collected_count, total_orbs]


func _on_save_completed(success: bool, message: String) -> void:
	_save_toast.text = message if success else ("Ошибка: " + message)
	_save_toast.modulate = Color(0.133, 0.827, 0.933, 1.0) if success else Color(0.937, 0.267, 0.267, 1.0)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.2)
	_toast_tween.tween_property(_save_toast, "modulate:a", 0.0, 0.45)


func _on_pause_pressed() -> void:
	EventBus.game_pause_requested.emit(true)
