extends Node
## Глобальная шина сигналов для слабой связанности между сеткой мира, логистикой, волнами и UI.

@warning_ignore("unused_signal")
signal crystals_changed(new_crystals: int)

@warning_ignore("unused_signal")
signal day_phase_changed(day: int, is_night: bool, time_left: float, enemies_alive: int)

@warning_ignore("unused_signal")
signal base_status_changed(level: int, hp: float, max_hp: float)

@warning_ignore("unused_signal")
signal building_selected(building: Node2D)

@warning_ignore("unused_signal")
signal build_tool_changed(building_id: String)

@warning_ignore("unused_signal")
signal simulation_paused_changed(paused: bool)

@warning_ignore("unused_signal")
signal skill_upgraded(skill_id: String, new_level: int)

@warning_ignore("unused_signal")
signal game_over(days_survived: int, kills: int)

@warning_ignore("unused_signal")
signal save_completed(success: bool, message: String)

@warning_ignore("unused_signal")
signal save_deleted

@warning_ignore("unused_signal")
signal touch_mode_changed(mode: String)

@warning_ignore("unused_signal")
signal game_pause_requested(paused: bool)

@warning_ignore("unused_signal")
signal camera_zoom_requested(factor: float)

@warning_ignore("unused_signal")
signal camera_center_requested

@warning_ignore("unused_signal")
signal meta_progression_changed

