extends Node
## Менеджер аудиошин и воспроизведения звуковых эффектов.

var _buses_initialized: bool = false


func _ready() -> void:
	_ensure_buses()


func _ensure_buses() -> void:
	if _buses_initialized:
		return
	if AudioServer.get_bus_index("SFX") == -1:
		var sfx_index: int = AudioServer.bus_count
		AudioServer.add_bus(sfx_index)
		AudioServer.set_bus_name(sfx_index, "SFX")
		AudioServer.set_bus_send(sfx_index, "Master")
	if AudioServer.get_bus_index("Music") == -1:
		var music_index: int = AudioServer.bus_count
		AudioServer.add_bus(music_index)
		AudioServer.set_bus_name(music_index, "Music")
		AudioServer.set_bus_send(music_index, "Master")
	_buses_initialized = true


func set_bus_volume(bus_name: String, linear_value: float) -> void:
	_ensure_buses()
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped <= 0.001)
	if clamped > 0.001:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped))


func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	_ensure_buses()
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
