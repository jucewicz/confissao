extends Control

signal interaction_requested(interaction_id: String)

const LEVELS := ["up", "middle", "down"]
const INITIAL_STATE := ["middle", "down", "middle"]
const SOLVED_STATE := ["down", "down", "down"]
const STATE_KEY := "dining_room_clock_pendulum_state"
const TEXTURE_PATH := "res://art/zoom_ins/dining_room/clock_pendulums/clock_pendulums_l_%s_c_%s_r_%s.png"

@onready var image: TextureRect = $Image
@onready var left_hotspot: UIInteractable = $LeftPendulumHotspot
@onready var center_hotspot: UIInteractable = $CenterPendulumHotspot
@onready var right_hotspot: UIInteractable = $RightPendulumHotspot

var state: Array = INITIAL_STATE.duplicate()


func _ready() -> void:
	state = _load_state()
	left_hotspot.interacted.connect(_on_pendulum_interacted)
	center_hotspot.interacted.connect(_on_pendulum_interacted)
	right_hotspot.interacted.connect(_on_pendulum_interacted)
	_update_texture()


func _load_state() -> Array:
	var saved_state: Variant = GameState.get_value(STATE_KEY, INITIAL_STATE)
	if saved_state is Array and saved_state.size() == 3:
		return saved_state.duplicate()
	return INITIAL_STATE.duplicate()


func _on_pendulum_interacted(interaction_id: String) -> void:
	if _is_solved():
		return

	var index := _interaction_id_to_index(interaction_id)
	if index == -1:
		return

	match index:
		0:
			_descend(0)
			_ascend(1)
		1:
			_ascend(0)
			_descend(1)
			_ascend(2)
		2:
			_ascend(1)
			_descend(2)

	_save_state()
	_update_texture()

	if _is_solved():
		GameState.set_flag("dining_room_clock_pendulums_solved", true)
		interaction_requested.emit("clock_pendulums_solved")


func _interaction_id_to_index(interaction_id: String) -> int:
	match interaction_id:
		"clock_pendulum_left":
			return 0
		"clock_pendulum_center":
			return 1
		"clock_pendulum_right":
			return 2
		_:
			return -1


func _descend(index: int) -> void:
	state[index] = LEVELS[(_level_index(state[index]) + 1) % LEVELS.size()]


func _ascend(index: int) -> void:
	state[index] = LEVELS[(_level_index(state[index]) - 1 + LEVELS.size()) % LEVELS.size()]


func _level_index(level: String) -> int:
	var index := LEVELS.find(level)
	if index == -1:
		return LEVELS.find("middle")
	return index


func _save_state() -> void:
	GameState.set_value(STATE_KEY, state.duplicate())


func _update_texture() -> void:
	var texture_path := TEXTURE_PATH % [state[0], state[1], state[2]]
	image.texture = load(texture_path)


func _is_solved() -> bool:
	return state == SOLVED_STATE
