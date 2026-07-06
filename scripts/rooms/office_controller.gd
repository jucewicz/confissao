extends Node2D

signal interaction_requested(interaction_id: String)

const DEFAULT_OFFICE_BACKGROUND := preload("res://art/backgrounds/office/office_new.png")

@onready var background: Sprite2D = $Content/Background


func _ready() -> void:
	refresh_state_visuals()
	_bind_interactables(self)


func refresh_state_visuals() -> void:
	background.texture = DEFAULT_OFFICE_BACKGROUND
	_update_box_cursor()
	_update_safe_cursor()


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


func _update_safe_cursor() -> void:
	var safe_hotspot := get_node_or_null("Content/Hotspots/SafeHotspot")
	if safe_hotspot == null:
		return
	if GameState.get_flag("office_safe_opened") and not GameState.get_flag("office_silver_key_collected"):
		safe_hotspot.cursor_type = "pickup"
	else:
		safe_hotspot.cursor_type = "inspect"
