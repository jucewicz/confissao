extends Control

signal zoom_opened(zoom_id: String)
signal zoom_closed
signal zoom_interaction_requested(interaction_id: String)

@onready var zoom_root: Control = $ZoomRoot
@onready var close_button: Button = $CloseButton

var current_zoom: Node = null

var zoom_scenes := {
	"portrait_moon": preload("res://scenes/zooms/bedroom/zoom_portrait_moon.tscn"),
	"sofa_flower": preload("res://scenes/zooms/bedroom/zoom_sofa_flower.tscn"),
	"rug_crown": preload("res://scenes/zooms/bedroom/zoom_rug_crown.tscn"),
	"writing_desk_key_book": preload("res://scenes/zooms/bedroom/zoom_writing_desk_key_book.tscn"),
	"jewelry_box_closed": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_closed.tscn"),
	"jewelry_box_open": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_open.tscn"),
	"jewelry_box_only_letter": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_only_letter.tscn"),
	"jewelry_box_only_key": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_only_key.tscn"),
	"jewelry_box_empty": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_empty.tscn"),
	"wardrobe_open_with_note": preload("res://scenes/zooms/bedroom/zoom_wardrobe_open_with_note.tscn"),
	"wardrobe_open_without_note": preload("res://scenes/zooms/bedroom/zoom_wardrobe_open_without_note.tscn"),
	"chest_drawer_open": preload("res://scenes/zooms/bedroom/zoom_chest_drawer_open.tscn"),
	"nightstand_top_drawer_open": preload("res://scenes/zooms/bedroom/zoom_nightstand_top_drawer_open.tscn"),
	"nightstand_bottom_drawer_open": preload("res://scenes/zooms/bedroom/zoom_nightstand_bottom_drawer_open.tscn"),
}


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_zoom)


func open_zoom(zoom_id: String) -> void:
	if current_zoom != null:
		close_zoom(false)
	if not zoom_scenes.has(zoom_id):
		push_warning("Zoom nao encontrado: " + zoom_id)
		return

	_set_room_interactables_enabled(false)
	current_zoom = zoom_scenes[zoom_id].instantiate()
	zoom_root.add_child(current_zoom)
	if current_zoom.has_signal("interaction_requested"):
		current_zoom.interaction_requested.connect(_on_zoom_interaction_requested)

	visible = true
	current_zoom.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(current_zoom, "modulate:a", 1.0, 0.15)
	AudioManager.play_sfx("zoom_open")
	zoom_opened.emit(zoom_id)


func close_zoom(animated: bool = true) -> void:
	if current_zoom == null:
		return

	var zoom_to_close := current_zoom
	current_zoom = null

	if not animated:
		zoom_to_close.queue_free()
		visible = false
		_set_room_interactables_enabled(true)
		zoom_closed.emit()
		return

	var tween := create_tween()
	tween.tween_property(zoom_to_close, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		zoom_to_close.queue_free()
		visible = false
		_set_room_interactables_enabled(true)
		AudioManager.play_sfx("zoom_close")
		zoom_closed.emit()
	)


func _on_zoom_interaction_requested(interaction_id: String) -> void:
	zoom_interaction_requested.emit(interaction_id)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_zoom()


func _set_room_interactables_enabled(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("room_interactables"):
		if node is CollisionObject2D:
			node.input_pickable = enabled
		if node is Area2D:
			node.monitoring = enabled
