extends Control

signal zoom_opened(zoom_id: String)
signal zoom_closed
signal zoom_interaction_requested(interaction_id: String)

@onready var zoom_root: Control = $ZoomRoot
@onready var close_button: Button = $CloseButton

var current_zoom: Node = null
var current_zoom_id := ""
var parent_zoom_stack: Array = []

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
	"dining_room_clock": preload("res://scenes/zooms/dining_room/zoom_clock_and_drawer.tscn"),
	"dining_room_clock_open_with_eye_medallion": preload("res://scenes/zooms/dining_room/zoom_clock_open_with_eye_medallion.tscn"),
	"dining_room_clock_open_without_eye_medallion": preload("res://scenes/zooms/dining_room/zoom_clock_open_without_eye_medallion.tscn"),
	"dining_room_clock_pendulums": preload("res://scenes/zooms/dining_room/zoom_clock_pendulums.tscn"),
	"dining_room_clock_drawer_inscription": preload("res://scenes/zooms/dining_room/zoom_clock_drawer_inscription.tscn"),
	"dining_room_table_with_scribbled_napkin": preload("res://scenes/zooms/dining_room/zoom_dining_table_with_scribbled_napkin.tscn"),
	"dining_room_table_without_scribbled_napkin": preload("res://scenes/zooms/dining_room/zoom_dining_table_without_scribbled_napkin.tscn"),
	"dining_room_floral_reliquary_far": preload("res://scenes/zooms/dining_room/zoom_floral_reliquary_far.tscn"),
	"dining_room_floral_reliquary_close": preload("res://scenes/zooms/dining_room/zoom_floral_reliquary_close.tscn"),
	"library_bookshelf_with_botany_book": preload("res://scenes/zooms/library/zoom_bookshelf_with_botany_book.tscn"),
	"library_bookshelf_without_botany_book": preload("res://scenes/zooms/library/zoom_bookshelf_without_botany_book.tscn"),
	"office_desktop": preload("res://scenes/zooms/office/zoom_office_desktop.tscn"),
	"office_desktop_letters_stack": preload("res://scenes/zooms/office/zoom_office_desktop_letters_stack.tscn"),
	"office_inventory_box": preload("res://scenes/zooms/office/zoom_office_inventory_box.tscn"),
	"office_box_open_with_medallion": preload("res://scenes/zooms/office/zoom_office_box_open_with_medallion.tscn"),
	"office_box_open_without_medallion": preload("res://scenes/zooms/office/zoom_office_box_open_without_medallion.tscn"),
}


func _ready() -> void:
	visible = false
	_setup_close_button_style()
	close_button.pressed.connect(close_zoom)


func open_zoom(zoom_id: String, keep_current_as_parent: bool = false, preserve_parent_stack: bool = false) -> void:
	if not zoom_scenes.has(zoom_id):
		push_warning("Zoom nao encontrado: " + zoom_id)
		return

	var zooms_to_free_after_fade := []
	if current_zoom != null:
		if keep_current_as_parent:
			_push_current_zoom_as_parent()
		elif preserve_parent_stack:
			zooms_to_free_after_fade = _prepare_current_zoom_for_replacement()
		else:
			zooms_to_free_after_fade = _prepare_current_zoom_tree_for_replacement()

	_set_room_interactables_enabled(false)
	current_zoom = zoom_scenes[zoom_id].instantiate()
	current_zoom_id = zoom_id
	zoom_root.add_child(current_zoom)
	if current_zoom.has_signal("interaction_requested"):
		current_zoom.interaction_requested.connect(_on_zoom_interaction_requested)

	visible = true
	current_zoom.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(current_zoom, "modulate:a", 1.0, 0.15)
	if not zooms_to_free_after_fade.is_empty():
		tween.tween_callback(_free_zoom_nodes.bind(zooms_to_free_after_fade))
	AudioManager.play_sfx("zoom_open")
	zoom_opened.emit(zoom_id)


func close_zoom(animated: bool = true) -> void:
	if current_zoom == null:
		if not parent_zoom_stack.is_empty():
			_free_zoom_nodes(parent_zoom_stack.map(func(parent_zoom: Dictionary) -> Node:
				return parent_zoom["node"]
			))
			parent_zoom_stack.clear()
		visible = false
		_set_room_interactables_enabled(true)
		return

	var zoom_to_close := current_zoom
	var has_parent_zoom := not parent_zoom_stack.is_empty()
	current_zoom = null
	current_zoom_id = ""

	if not animated:
		zoom_to_close.queue_free()
		if has_parent_zoom:
			_restore_parent_zoom()
		else:
			visible = false
			_set_room_interactables_enabled(true)
		zoom_closed.emit()
		return

	if has_parent_zoom:
		_restore_parent_zoom()

	var tween := create_tween()
	tween.tween_property(zoom_to_close, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		zoom_to_close.queue_free()
		if not has_parent_zoom:
			visible = false
			_set_room_interactables_enabled(true)
		AudioManager.play_sfx("zoom_close")
		zoom_closed.emit()
	)


func _on_zoom_interaction_requested(interaction_id: String) -> void:
	zoom_interaction_requested.emit(interaction_id)


func _setup_close_button_style() -> void:
	close_button.text = "← Voltar"
	close_button.tooltip_text = "Sair do zoom (Esc)"
	close_button.custom_minimum_size = Vector2(156.0, 52.0)
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_size_override("font_size", 21)
	close_button.add_theme_color_override("font_color", Color(0.86, 0.74, 0.57, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(0.98, 0.86, 0.66, 1.0))
	close_button.add_theme_color_override("font_pressed_color", Color(0.72, 0.57, 0.40, 1.0))

	var normal_style := StyleBoxFlat.new()
	normal_style.content_margin_left = 16.0
	normal_style.content_margin_right = 16.0
	normal_style.content_margin_top = 9.0
	normal_style.content_margin_bottom = 9.0
	normal_style.bg_color = Color(0.055, 0.043, 0.035, 0.78)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.45, 0.31, 0.17, 0.72)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.corner_radius_bottom_left = 4

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.075, 0.058, 0.044, 0.92)
	hover_style.border_color = Color(0.74, 0.52, 0.25, 0.9)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.035, 0.028, 0.023, 0.95)
	pressed_style.border_color = Color(0.35, 0.23, 0.12, 0.9)

	close_button.add_theme_stylebox_override("normal", normal_style)
	close_button.add_theme_stylebox_override("hover", hover_style)
	close_button.add_theme_stylebox_override("pressed", pressed_style)
	close_button.add_theme_stylebox_override("focus", hover_style)


func _push_current_zoom_as_parent() -> void:
	parent_zoom_stack.append({
		"id": current_zoom_id,
		"mouse_filter": current_zoom.mouse_filter,
		"node": current_zoom,
	})
	current_zoom.mouse_filter = Control.MOUSE_FILTER_STOP
	current_zoom = null
	current_zoom_id = ""


func _restore_parent_zoom() -> void:
	var parent_zoom: Dictionary = parent_zoom_stack.pop_back()
	current_zoom = parent_zoom["node"]
	current_zoom_id = parent_zoom["id"]
	if current_zoom.has_method("refresh_state_visuals"):
		current_zoom.refresh_state_visuals()
	current_zoom.visible = true
	current_zoom.modulate.a = 1.0
	current_zoom.mouse_filter = parent_zoom["mouse_filter"]
	visible = true


func close_all_zooms() -> void:
	var zooms_to_free := []
	if current_zoom != null:
		zooms_to_free.append(current_zoom)
	for parent_zoom in parent_zoom_stack:
		zooms_to_free.append(parent_zoom["node"])

	current_zoom = null
	current_zoom_id = ""
	parent_zoom_stack.clear()
	_free_zoom_nodes(zooms_to_free)
	visible = false
	_set_room_interactables_enabled(true)


func _prepare_current_zoom_tree_for_replacement() -> Array:
	var zooms_to_free := []
	zooms_to_free.append_array(_prepare_current_zoom_for_replacement())
	for parent_zoom in parent_zoom_stack:
		_disable_zoom_input(parent_zoom["node"])
		zooms_to_free.append(parent_zoom["node"])
	parent_zoom_stack.clear()
	return zooms_to_free


func _prepare_current_zoom_for_replacement() -> Array:
	var zooms_to_free := []
	_disable_zoom_input(current_zoom)
	zooms_to_free.append(current_zoom)
	current_zoom = null
	current_zoom_id = ""
	return zooms_to_free


func _free_zoom_nodes(zoom_nodes: Array) -> void:
	for zoom_node in zoom_nodes:
		if is_instance_valid(zoom_node):
			zoom_node.queue_free()


func _disable_zoom_input(zoom_node: Node) -> void:
	if zoom_node is Control:
		zoom_node.mouse_filter = Control.MOUSE_FILTER_STOP


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_zoom()


func _set_room_interactables_enabled(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("room_interactables"):
		if node is CollisionObject2D:
			node.input_pickable = enabled
		if node is Area2D:
			node.monitoring = enabled
