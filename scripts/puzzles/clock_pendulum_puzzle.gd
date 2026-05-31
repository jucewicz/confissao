extends Control

signal interaction_requested(interaction_id: String)

const LEVELS := ["up", "middle", "down"]
const INITIAL_STATE := ["middle", "down", "middle"]
const STATE_KEY := "dining_room_clock_pendulum_state"
const PENDULUM_SCALE := 0.42
const PENDULUM_LAYOUTS := [
	{"anchor_x": 760.0, "top": 12.0},
	{"anchor_x": 960.0, "top": 12.0},
	{"anchor_x": 1125.0, "top": 12.0},
]
const PENDULUM_TEXTURES := [
	{
		"up": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_left_up.png"),
		"middle": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_left_middle.png"),
		"down": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_left_down.png"),
	},
	{
		"up": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_center_up.png"),
		"middle": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_center_middle.png"),
		"down": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_center_down.png"),
	},
	{
		"up": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_right_up.png"),
		"middle": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_right_middle.png"),
		"down": preload("res://art/zoom_ins/dining_room/clock_pendulum_parts/pendulum_right_down.png"),
	},
]

@onready var pendulum_sprites := [
	$PendulumLeft,
	$PendulumCenter,
	$PendulumRight,
]
@onready var left_hotspot: UIInteractable = $LeftPendulumHotspot
@onready var center_hotspot: UIInteractable = $CenterPendulumHotspot
@onready var right_hotspot: UIInteractable = $RightPendulumHotspot

var state: Array = INITIAL_STATE.duplicate()


func _ready() -> void:
	state = _load_state()
	left_hotspot.interacted.connect(_on_pendulum_interacted)
	center_hotspot.interacted.connect(_on_pendulum_interacted)
	right_hotspot.interacted.connect(_on_pendulum_interacted)
	_update_pendulum_visuals()


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
	_update_pendulum_visuals()

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


func _update_pendulum_visuals() -> void:
	for index in range(pendulum_sprites.size()):
		var level: String = state[index]
		var texture: Texture2D = PENDULUM_TEXTURES[index][level]
		var layout: Dictionary = PENDULUM_LAYOUTS[index]
		var size := Vector2(texture.get_width(), texture.get_height()) * PENDULUM_SCALE
		var sprite: TextureRect = pendulum_sprites[index]
		sprite.texture = texture
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.position = Vector2(layout["anchor_x"] - (size.x / 2.0), layout["top"])
		sprite.size = size


func _is_solved() -> bool:
	return state[0] == state[1] and state[1] == state[2]
