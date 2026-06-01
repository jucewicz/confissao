extends Node2D

signal interaction_requested(interaction_id: String)

const CLOCK_OPEN_BACKGROUND := preload("res://art/backgrounds/dining_room/dining_room_clock_open.png")
const CLOCK_OPEN_WITH_MEDALLION_BACKGROUND := preload("res://art/backgrounds/dining_room/dining_room_clock_open_with_medallion.png")

@onready var background: Sprite2D = $Content/Background


func _ready() -> void:
	refresh_state_visuals()
	_bind_interactables(self)


func refresh_state_visuals() -> void:
	if GameState.get_flag("dining_room_clock_pendulums_solved"):
		if GameState.get_flag("dining_room_eye_medallion_collected"):
			background.texture = CLOCK_OPEN_BACKGROUND
		else:
			background.texture = CLOCK_OPEN_WITH_MEDALLION_BACKGROUND


func _bind_interactables(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("interacted"):
			child.add_to_group("room_interactables")
			child.interacted.connect(_on_interacted)
		_bind_interactables(child)


func _on_interacted(interaction_id: String) -> void:
	interaction_requested.emit(interaction_id)
