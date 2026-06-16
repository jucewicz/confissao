extends "res://scripts/core/scaled_zoom_view.gd"

const LETTERS_STACK_RECT := Rect2(290.0, 260.0, 390.0, 180.0)
const INVENTORY_BOX_RECT := Rect2(1230.0, 235.0, 335.0, 210.0)

@onready var letters_stack_hotspot: Button = $LettersStackHotspot
@onready var inventory_box_hotspot: Button = $InventoryBoxHotspot


func _update_scaled_layout() -> void:
	if letters_stack_hotspot != null:
		_set_control_art_rect(letters_stack_hotspot, LETTERS_STACK_RECT)
	if inventory_box_hotspot != null:
		_set_control_art_rect(inventory_box_hotspot, INVENTORY_BOX_RECT)
