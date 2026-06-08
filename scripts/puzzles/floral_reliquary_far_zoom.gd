extends "res://scripts/core/zoom_view.gd"

const STATE_KEY := "dining_room_floral_reliquary_state"
const SOLVED_FLAG := "dining_room_floral_reliquary_solved"
const FLOWER_SCALE := 0.125
const PLACED_FLOWER_SCALE := 0.095
const ART_SIZE := Vector2(1672.0, 941.0)

const FLOWER_TEXTURES := {
	"lily": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_lily.png"),
	"rose": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_rose.png"),
	"violet": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_violet.png"),
	"carnation": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_carnation.png"),
}

const FLOWER_START_POSITIONS := {
	"lily": Vector2(1055.0, 520.0),
	"rose": Vector2(1145.0, 520.0), 
	"violet": Vector2(1235.0, 520.0), 
	"carnation": Vector2(1325.0, 520.0), 
}

const SLOT_POSITIONS := {
	"sangue": Vector2(942.0, 196.0),
	"silencio": Vector2(1112.0, 196.0),
	"amor": Vector2(942.0, 316.0),
	"culpa": Vector2(1112.0, 316.0),
}

const FLOWER_ANCHORS := {
	"lily": Vector2(286.0, 205.0),
	"rose": Vector2(248.0, 158.0),
	"violet": Vector2(265.0, 180.0),
	"carnation": Vector2(250.0, 178.0),
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


func _ready() -> void:
	super._ready()
	GameState.value_changed.connect(_on_game_state_changed)
	GameState.flag_changed.connect(_on_game_state_changed)
	_update_visuals()


func _on_game_state_changed(_state_name: String, _value: Variant) -> void:
	_update_visuals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_visuals()


func _update_visuals() -> void:
	var slot_assignments := _get_slot_assignments()
	var placed_flowers := {}
	for slot_id in slot_assignments:
		placed_flowers[slot_assignments[slot_id]] = slot_id

	for flower_id in flower_nodes:
		var flower: TextureRect = flower_nodes[flower_id]
		var texture: Texture2D = FLOWER_TEXTURES[flower_id]
		var center_position: Vector2
		var scale_factor := FLOWER_SCALE
		var is_placed := false
		if placed_flowers.has(flower_id):
			center_position = SLOT_POSITIONS[placed_flowers[flower_id]]
			scale_factor = PLACED_FLOWER_SCALE
			is_placed = true
		else:
			center_position = FLOWER_START_POSITIONS[flower_id]

		var size := _get_flower_size(texture, scale_factor, is_placed)
		flower.texture = texture
		flower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flower.position = _get_flower_position(flower_id, center_position, scale_factor, is_placed)
		flower.size = size


func _get_slot_assignments() -> Dictionary:
	if GameState.get_flag(SOLVED_FLAG):
		return SOLUTION.duplicate()

	var saved_state: Variant = GameState.get_value(STATE_KEY, {})
	if saved_state is Dictionary:
		return saved_state.duplicate()
	return {}


func _get_view_scale() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(size.x / ART_SIZE.x, size.y / ART_SIZE.y)


func _art_to_view_position(position: Vector2) -> Vector2:
	return position * _get_view_scale()


func _art_size_to_view_size(rect_size: Vector2) -> Vector2:
	return rect_size * _get_view_scale()


func _get_flower_position(flower_id: String, center_position: Vector2, scale_factor: float, is_placed: bool) -> Vector2:
	if is_placed:
		var anchor_position := _art_size_to_view_size(FLOWER_ANCHORS[flower_id] * scale_factor)
		return _art_to_view_position(center_position) - anchor_position

	var texture: Texture2D = FLOWER_TEXTURES[flower_id]
	var size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
	return center_position - (size / 2.0)


func _get_flower_size(texture: Texture2D, scale_factor: float, is_placed: bool) -> Vector2:
	var base_size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
	return _art_size_to_view_size(base_size) if is_placed else base_size
