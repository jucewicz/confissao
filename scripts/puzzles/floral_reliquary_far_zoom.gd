extends "res://scripts/core/zoom_view.gd"

const STATE_KEY := "dining_room_floral_reliquary_state"
const SOLVED_FLAG := "dining_room_floral_reliquary_solved"
const FLOWER_SCALE := 0.125
const PLACED_FLOWER_SCALE := 0.115

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
	"amor": Vector2(942.0, 350.0),
	"culpa": Vector2(1112.0, 350.0),
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
		if placed_flowers.has(flower_id):
			center_position = SLOT_POSITIONS[placed_flowers[flower_id]]
			scale_factor = PLACED_FLOWER_SCALE
		else:
			center_position = FLOWER_START_POSITIONS[flower_id]

		var size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
		flower.texture = texture
		flower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flower.position = center_position - (size / 2.0)
		flower.size = size


func _get_slot_assignments() -> Dictionary:
	if GameState.get_flag(SOLVED_FLAG):
		return SOLUTION.duplicate()

	var saved_state: Variant = GameState.get_value(STATE_KEY, {})
	if saved_state is Dictionary:
		return saved_state.duplicate()
	return {}
