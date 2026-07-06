extends "res://scripts/core/scaled_zoom_view.gd"

const SAFE_EMBLEM_SLOT_STATE_KEY := "office_safe_emblem_slots"
const SLOT_RECTS := [
	Rect2(500.0, 138.0, 225.0, 225.0),
	Rect2(947.0, 138.0, 225.0, 225.0),
	Rect2(500.0, 579.0, 225.0, 225.0),
	Rect2(947.0, 579.0, 225.0, 225.0),
]
const ICON_RECTS := [
	Rect2(535.0, 173.0, 155.0, 155.0),
	Rect2(982.0, 173.0, 155.0, 155.0),
	Rect2(535.0, 614.0, 155.0, 155.0),
	Rect2(982.0, 614.0, 155.0, 155.0),
]
const EMBLEM_TEXTURES := {
	"item_eye_medallion": preload("res://art/items/dining_room/item_eye_medallion.png"),
	"item_flame_medallion": preload("res://art/items/office/item_flame_medallion.png"),
	"item_spiral_medallion": preload("res://art/items/dining_room/item_spiral_medallion.png"),
	"item_royal_family_emblem": preload("res://art/items/library/item_royal_family_emblem.png"),
}

@onready var slot_hotspots := [
	$Slot0Hotspot,
	$Slot1Hotspot,
	$Slot2Hotspot,
	$Slot3Hotspot,
]
@onready var slot_icons := [
	$Slot0Icon,
	$Slot1Icon,
	$Slot2Icon,
	$Slot3Icon,
]


func _ready() -> void:
	super._ready()
	refresh_state_visuals()


func refresh_state_visuals() -> void:
	var slot_state: Variant = GameState.get_value(SAFE_EMBLEM_SLOT_STATE_KEY, {})
	if not (slot_state is Dictionary):
		slot_state = {}

	for slot_index in range(slot_icons.size()):
		var icon: TextureRect = slot_icons[slot_index]
		var item_id: String = slot_state.get(str(slot_index), "")
		icon.visible = item_id != "" and EMBLEM_TEXTURES.has(item_id)
		if icon.visible:
			icon.texture = EMBLEM_TEXTURES[item_id]


func _update_scaled_layout() -> void:
	if slot_hotspots == null:
		return

	for slot_index in range(slot_hotspots.size()):
		_set_control_art_rect(slot_hotspots[slot_index], SLOT_RECTS[slot_index])
		_set_control_art_rect(slot_icons[slot_index], ICON_RECTS[slot_index])
