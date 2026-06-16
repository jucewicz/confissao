extends Node2D

signal interaction_requested(interaction_id: String)

const BOX_OPEN_WITH_MEDALLION_BACKGROUND := preload("res://art/backgrounds/office/office_box_open_with_medallion.png")
const BOX_OPEN_WITHOUT_MEDALLION_BACKGROUND := preload("res://art/backgrounds/office/office_box_open_without_medallion.png")

@onready var background: Sprite2D = $Content/Background


func _ready() -> void:
	refresh_state_visuals()
	_bind_interactables(self)


func refresh_state_visuals() -> void:
	if GameState.get_flag("office_flame_medallion_collected"):
		background.texture = BOX_OPEN_WITHOUT_MEDALLION_BACKGROUND
	elif GameState.get_flag("office_box_opened"):
		background.texture = BOX_OPEN_WITH_MEDALLION_BACKGROUND
	_update_box_cursor()


func _bind_interactables(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("interacted"):
			child.add_to_group("room_interactables")
			child.interacted.connect(_on_interacted)
		_bind_interactables(child)


func _on_interacted(interaction_id: String) -> void:
	interaction_requested.emit(interaction_id)


func _update_box_cursor() -> void:
	var box_hotspot := get_node_or_null("Content/Hotspots/BoxHotspot")
	if box_hotspot == null:
		return
	if GameState.get_flag("office_box_opened") and not GameState.get_flag("office_flame_medallion_collected"):
		box_hotspot.cursor_type = "pickup"
	else:
		box_hotspot.cursor_type = "inspect"
