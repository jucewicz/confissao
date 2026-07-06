extends Node2D

signal interaction_requested(interaction_id: String)

const DEFAULT_LIBRARY_BACKGROUND := preload("res://art/backgrounds/library/library.png")
const OPEN_WITH_EMBLEM_BACKGROUND := preload("res://art/backgrounds/library/library_with_royal_emblem.png")
const OPEN_WITHOUT_EMBLEM_BACKGROUND := preload("res://art/backgrounds/library/library_without_royal_emblem.png")

@onready var background: Sprite2D = $Content/Background


func _ready() -> void:
	refresh_state_visuals()
	_bind_interactables(self)


func refresh_state_visuals() -> void:
	background.texture = DEFAULT_LIBRARY_BACKGROUND
	if GameState.get_flag("library_book_path_puzzle_solved"):
		if GameState.get_flag("library_royal_family_emblem_collected"):
			background.texture = OPEN_WITHOUT_EMBLEM_BACKGROUND
		else:
			background.texture = OPEN_WITH_EMBLEM_BACKGROUND
	_update_royal_emblem_cursor()


func _bind_interactables(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("interacted"):
			child.add_to_group("room_interactables")
			child.interacted.connect(_on_interacted)
		_bind_interactables(child)


func _on_interacted(interaction_id: String) -> void:
	interaction_requested.emit(interaction_id)


func _update_royal_emblem_cursor() -> void:
	var emblem_hotspot := get_node_or_null("Content/Hotspots/RoyalFamilyEmblemHotspot")
	if emblem_hotspot == null:
		return
	if (
		GameState.get_flag("library_book_path_puzzle_solved")
		and not GameState.get_flag("library_royal_family_emblem_collected")
	):
		emblem_hotspot.cursor_type = "pickup"
	else:
		emblem_hotspot.cursor_type = "inspect"
