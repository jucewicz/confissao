extends Node

const MIX_RATE := 22050
const DEFAULT_VOLUME_DB := -18.0
const SFX_SETTINGS := {
	"blocked": {
		"frequencies": [150.0, 118.0],
		"duration": 0.11,
		"volume_db": -23.0,
	},
	"invalid": {
		"frequencies": [160.0, 126.0],
		"duration": 0.09,
		"volume_db": -24.0,
	},
	"wrong_item": {
		"frequencies": [190.0, 135.0],
		"duration": 0.12,
		"volume_db": -23.0,
	},
	"puzzle_wrong": {
		"frequencies": [210.0, 155.0, 115.0],
		"duration": 0.14,
		"volume_db": -22.0,
	},
	"click": {
		"frequencies": [760.0],
		"duration": 0.035,
		"volume_db": -29.0,
	},
	"door": {
		"frequencies": [105.0, 82.0],
		"duration": 0.13,
		"volume_db": -24.0,
	},
	"zoom_open": {
		"frequencies": [360.0, 460.0],
		"duration": 0.08,
		"volume_db": -27.0,
	},
	"zoom_close": {
		"frequencies": [420.0, 300.0],
		"duration": 0.08,
		"volume_db": -27.0,
	},
	"paper_open": {
		"frequencies": [520.0, 680.0],
		"duration": 0.055,
		"volume_db": -30.0,
	},
	"symbol_press": {
		"frequencies": [520.0],
		"duration": 0.04,
		"volume_db": -28.0,
	},
	"puzzle_correct": {
		"frequencies": [330.0, 495.0, 660.0],
		"duration": 0.16,
		"volume_db": -25.0,
	},
	"item_pickup": {
		"frequencies": [440.0, 660.0],
		"duration": 0.09,
		"volume_db": -27.0,
	},
}

var _players: Array[AudioStreamPlayer] = []


func play_sfx(sfx_id: String) -> void:
	var settings: Dictionary = SFX_SETTINGS.get(sfx_id, {})
	if settings.is_empty():
		return

	var player := _get_available_player()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = maxf(float(settings.get("duration", 0.08)) + 0.04, 0.12)
	player.stream = stream
	player.volume_db = float(settings.get("volume_db", DEFAULT_VOLUME_DB))
	player.play()

	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frequencies: Array = settings.get("frequencies", [])
	var duration := float(settings.get("duration", 0.08))
	var frames := int(MIX_RATE * duration)
	for frame_index in range(frames):
		var time := float(frame_index) / MIX_RATE
		var progress := float(frame_index) / maxf(float(frames - 1), 1.0)
		var frequency := _frequency_at_progress(frequencies, progress)
		var envelope := _short_sfx_envelope(progress)
		var sample := sin(TAU * frequency * time) * envelope * 0.45
		playback.push_frame(Vector2(sample, sample))


func play_ambience(_ambience_id: String) -> void:
	pass


func stop_ambience() -> void:
	pass


func _get_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player

	var player := AudioStreamPlayer.new()
	add_child(player)
	_players.append(player)
	return player


func _frequency_at_progress(frequencies: Array, progress: float) -> float:
	if frequencies.is_empty():
		return 220.0

	var index := mini(int(progress * frequencies.size()), frequencies.size() - 1)
	return float(frequencies[index])


func _short_sfx_envelope(progress: float) -> float:
	if progress < 0.15:
		return progress / 0.15
	return pow(1.0 - progress, 1.8)
