extends Node
## Менеджер локальных сохранений игрового прогресса в формате JSON (user://saves/save.json).

const SAVE_DIR: String = "user://saves"
const SAVE_PATH: String = "user://saves/save.json"
const SAVE_VERSION: int = 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if dir_err != OK:
		EventBus.save_completed.emit(false, "Ошибка создания папки сохранений")
		return false

	var payload: Dictionary = GameState.to_save_dict()
	payload["save_version"] = SAVE_VERSION

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		EventBus.save_completed.emit(false, "Не удалось записать сохранение")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	EventBus.save_completed.emit(true, "Сохранено")
	return true


func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err: Error = json.parse(raw_text)
	if parse_err != OK or not (json.data is Dictionary):
		return {}

	var data: Dictionary = json.data
	var version: int = int(data.get("save_version", 0))
	if version <= 0:
		return {}

	return data


func load_into_state() -> bool:
	var data: Dictionary = load_game()
	if data.is_empty():
		return false
	GameState.apply_save_dict(data)
	return true


func delete_save() -> bool:
	if not has_save():
		EventBus.save_deleted.emit()
		return true

	var err: Error = DirAccess.remove_absolute(SAVE_PATH)
	if err != OK:
		return false

	EventBus.save_deleted.emit()
	return true
