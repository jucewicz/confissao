extends "res://scripts/core/scaled_zoom_view.gd"

const CLOSED_DESKTOP_TEXTURE := preload("res://art/zoom_ins/office/office_desktop.png")
const OPEN_WITH_MEDALLION_DESKTOP_TEXTURE := preload("res://art/backgrounds/office/office_box_open_with_medallion.png")
const OPEN_WITHOUT_MEDALLION_DESKTOP_TEXTURE := preload("res://art/backgrounds/office/office_box_open_without_medallion.png")
const LETTERS_STACK_RECT := Rect2(305.0, 250.0, 285.0, 150.0)
const INVENTORY_BOX_RECT := Rect2(1230.0, 235.0, 335.0, 210.0)

@onready var image: TextureRect = $Image
@onready var letters_stack_hotspot: Button = $LettersStackHotspot
@onready var inventory_box_hotspot: Button = $InventoryBoxHotspot


func _ready() -> void:
	super._ready()
	refresh_state_visuals()


func refresh_state_visuals() -> void:
	if GameState.get_flag("office_flame_medallion_collected"):
		image.texture = OPEN_WITHOUT_MEDALLION_DESKTOP_TEXTURE
	elif GameState.get_flag("office_box_opened"):
		image.texture = OPEN_WITH_MEDALLION_DESKTOP_TEXTURE
	else:
		image.texture = CLOSED_DESKTOP_TEXTURE


func _update_scaled_layout() -> void:
	if letters_stack_hotspot != null:
		_set_control_art_rect(letters_stack_hotspot, LETTERS_STACK_RECT)
	if inventory_box_hotspot != null:
		_set_control_art_rect(inventory_box_hotspot, INVENTORY_BOX_RECT)
