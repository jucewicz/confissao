extends Node2D

signal interaction_requested(interaction_id: String)


func _ready() -> void:
	refresh_state_visuals()
	_bind_interactables(self)


func refresh_state_visuals() -> void:
	_update_center_door_cursor()


func _bind_interactables(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("interacted"):
			child.add_to_group("room_interactables")
			child.interacted.connect(_on_interacted)
		_bind_interactables(child)


func _on_interacted(interaction_id: String) -> void:
	interaction_requested.emit(interaction_id)


func _update_center_door_cursor() -> void:
	var center_door_hotspot := get_node_or_null("Content/Hotspots/CenterDoorHotspot")
	if center_door_hotspot == null:
		return
	if GameState.get_flag("office_silver_key_collected"):
		center_door_hotspot.cursor_type = "interact"
	else:
		center_door_hotspot.cursor_type = "blocked"
