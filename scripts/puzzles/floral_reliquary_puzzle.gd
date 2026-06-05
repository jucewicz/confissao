extends Control

signal interaction_requested(interaction_id: String)

const STATE_KEY := "dining_room_floral_reliquary_state"
const SOLVED_FLAG := "dining_room_floral_reliquary_solved"
const FLOWER_SCALE := 0.23
const PLACED_FLOWER_SCALE := 0.24
const FLOWER_HOTSPOT_SIZE := Vector2(150.0, 150.0)

const FLOWER_TEXTURES := {
	"lily": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_lily.png"),
	"rose": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_rose.png"),
	"violet": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_violet.png"),
	"carnation": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_carnation.png"),
}

const FLOWER_START_POSITIONS := {
	"lily": Vector2(985.0, 875.0),
	"rose": Vector2(1125.0, 875.0),
	"violet": Vector2(1265.0, 875.0),
	"carnation": Vector2(1405.0, 875.0),
}

const SLOT_POSITIONS := {
	"sangue": Vector2(900.0, 278.0),
	"silencio": Vector2(1192.0, 278.0),
	"amor": Vector2(900.0, 555.0),
	"culpa": Vector2(1192.0, 555.0),
}

const SOLUTION := {
	"culpa": "lily",
	"amor": "rose",
	"silencio": "violet",
	"sangue": "carnation",
}

@onready var flower_nodes := {
	"lily": $FlowerLily,
	"rose": $FlowerRose,
	"violet": $FlowerViolet,
	"carnation": $FlowerCarnation,
}

@onready var flower_buttons := {
	"lily": $FlowerLilyHotspot,
	"rose": $FlowerRoseHotspot,
	"violet": $FlowerVioletHotspot,
	"carnation": $FlowerCarnationHotspot,
}

@onready var slot_buttons := {
	"sangue": $SlotSangueHotspot,
	"silencio": $SlotSilencioHotspot,
	"amor": $SlotAmorHotspot,
	"culpa": $SlotCulpaHotspot,
}

var selected_flower := ""
var slot_assignments := {}


func _ready() -> void:
	_load_state()
	_bind_buttons()
	_update_visuals()


func _load_state() -> void:
	if GameState.get_flag(SOLVED_FLAG):
		slot_assignments = SOLUTION.duplicate()
		return

	var saved_state: Variant = GameState.get_value(STATE_KEY, {})
	if saved_state is Dictionary:
		slot_assignments = saved_state.duplicate()
	else:
		slot_assignments = {}


func _bind_buttons() -> void:
	for flower_id in flower_buttons:
		var button: Button = flower_buttons[flower_id]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_flower_pressed.bind(flower_id))

	for slot_id in slot_buttons:
		var button: Button = slot_buttons[slot_id]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_slot_pressed.bind(slot_id))


func _on_flower_pressed(flower_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG):
		return

	AudioManager.play_sfx("click")
	selected_flower = flower_id

	var current_slot := _get_slot_for_flower(flower_id)
	if current_slot != "":
		slot_assignments.erase(current_slot)
		_save_state()

	_update_visuals()


func _on_slot_pressed(slot_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG) or selected_flower == "":
		return

	AudioManager.play_sfx("click")
	var previous_slot := _get_slot_for_flower(selected_flower)
	if previous_slot != "":
		slot_assignments.erase(previous_slot)

	slot_assignments[slot_id] = selected_flower
	selected_flower = ""
	_save_state()
	_update_visuals()

	if _is_filled() and _is_solved():
		GameState.set_flag(SOLVED_FLAG, true)
		interaction_requested.emit("floral_reliquary_solved")


func _get_slot_for_flower(flower_id: String) -> String:
	for slot_id in slot_assignments:
		if slot_assignments[slot_id] == flower_id:
			return slot_id
	return ""


func _save_state() -> void:
	GameState.set_value(STATE_KEY, slot_assignments.duplicate())


func _update_visuals() -> void:
	var placed_flowers := {}
	for slot_id in slot_assignments:
		placed_flowers[slot_assignments[slot_id]] = slot_id

	for flower_id in flower_nodes:
		var flower: TextureRect = flower_nodes[flower_id]
		flower.texture = FLOWER_TEXTURES[flower_id]
		flower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		var target_position: Vector2
		var target_scale := FLOWER_SCALE
		if placed_flowers.has(flower_id):
			target_position = SLOT_POSITIONS[placed_flowers[flower_id]]
			target_scale = PLACED_FLOWER_SCALE
		else:
			target_position = FLOWER_START_POSITIONS[flower_id]

		_set_flower_rect(flower, target_position, target_scale)
		_set_button_rect(flower_buttons[flower_id], target_position, FLOWER_HOTSPOT_SIZE)
		flower.modulate = Color(1.18, 1.12, 1.0, 1.0) if flower_id == selected_flower else Color.WHITE


func _set_flower_rect(flower: TextureRect, center_position: Vector2, scale_factor: float) -> void:
	var texture: Texture2D = FLOWER_TEXTURES[_get_flower_id_for_node(flower)]
	var size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
	flower.position = center_position - (size / 2.0)
	flower.size = size


func _set_button_rect(button: Button, center_position: Vector2, size: Vector2) -> void:
	button.position = center_position - (size / 2.0)
	button.size = size


func _get_flower_id_for_node(node: TextureRect) -> String:
	for flower_id in flower_nodes:
		if flower_nodes[flower_id] == node:
			return flower_id
	return ""


func _is_filled() -> bool:
	return slot_assignments.size() == SLOT_POSITIONS.size()


func _is_solved() -> bool:
	for slot_id in SOLUTION:
		if slot_assignments.get(slot_id, "") != SOLUTION[slot_id]:
			return false
	return true
