extends Node
## Глобальная шина сигналов для слабой связанности между миром, состоянием и UI.

@warning_ignore("unused_signal")
signal orb_collected(orb_id: String, points: int)

@warning_ignore("unused_signal")
signal score_changed(new_score: int, collected_count: int, total_orbs: int)

@warning_ignore("unused_signal")
signal dash_triggered(cooldown_duration: float)

@warning_ignore("unused_signal")
signal save_completed(success: bool, message: String)

@warning_ignore("unused_signal")
signal save_deleted

@warning_ignore("unused_signal")
signal touch_mode_changed(mode: String)

@warning_ignore("unused_signal")
signal game_pause_requested(paused: bool)
