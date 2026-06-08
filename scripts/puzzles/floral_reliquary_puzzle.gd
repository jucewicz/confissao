extends Control

signal interaction_requested(interaction_id: String)

const STATE_KEY := "dining_room_floral_reliquary_state"
const SOLVED_FLAG := "dining_room_floral_reliquary_solved"
const FLOWER_SCALE := 0.23
const PLACED_FLOWER_SCALE := 0.20
const FLOWER_HOTSPOT_SIZE := Vector2(150.0, 150.0)
const DRAG_START_DISTANCE := 8.0
const ART_SIZE := Vector2(1672.0, 941.0)

const FLOWER_TEXTURES := {
	"lily": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_lily.png"),
	"rose": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_rose.png"),
	"violet": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_violet.png"),
	"carnation": preload("res://art/zoom_ins/dining_room/floral_reliquary/flower_carnation.png"),
}

const FLOWER_NAMES := {
	"lily": "Lírio",
	"rose": "Rosa",
	"violet": "Violeta",
	"carnation": "Cravo",
}

const FLOWER_START_POSITIONS := {
	"lily": Vector2(985.0, 875.0),
	"rose": Vector2(1125.0, 875.0),
	"violet": Vector2(1265.0, 875.0),
	"carnation": Vector2(1405.0, 875.0),
}

const SLOT_POSITIONS := {
	"sangue": Vector2(900.0, 276.0),
	"silencio": Vector2(1178.0, 276.0),
	"amor": Vector2(900.0, 542.0),
	"culpa": Vector2(1178.0, 542.0),
}

const SLOT_HITBOXES := {
	"sangue": Rect2(785.0, 185.0, 240.0, 220.0),
	"silencio": Rect2(1075.0, 185.0, 240.0, 220.0),
	"amor": Rect2(785.0, 455.0, 240.0, 220.0),
	"culpa": Rect2(1075.0, 455.0, 240.0, 220.0),
}

const FLOWER_ANCHORS := {
	"lily": Vector2(286.0, 205.0),
	"rose": Vector2(248.0, 158.0),
	"violet": Vector2(265.0, 180.0),
	"carnation": Vector2(250.0, 178.0),
}

const SOLUTION := {
	"culpa": "lily",
	"amor": "rose",
	"silencio": "violet",
	"sangue": "carnation",
}

@onready var flower_nodes := {
	"lily": $FlowerLily,
	"rose": $FlowerRose,
	"violet": $FlowerViolet,
	"carnation": $FlowerCarnation,
}

@onready var flower_buttons := {
	"lily": $FlowerLilyHotspot,
	"rose": $FlowerRoseHotspot,
	"violet": $FlowerVioletHotspot,
	"carnation": $FlowerCarnationHotspot,
}

@onready var slot_buttons := {
	"sangue": $SlotSangueHotspot,
	"silencio": $SlotSilencioHotspot,
	"amor": $SlotAmorHotspot,
	"culpa": $SlotCulpaHotspot,
}

var selected_flower := ""
var slot_assignments := {}
var drag_flower := ""
var drag_start_position := Vector2.ZERO
var drag_previous_slot := ""
var is_dragging := false
var suppress_next_flower_press := false
var suppress_next_slot_press := false
var hovered_flower := ""
var flower_tooltip: PanelContainer
var flower_tooltip_label: Label


func _ready() -> void:
	_create_flower_tooltip()
	_load_state()
	_bind_buttons()
	_update_visuals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_visuals()


func _load_state() -> void:
	if GameState.get_flag(SOLVED_FLAG):
		slot_assignments = SOLUTION.duplicate()
		return

	var saved_state: Variant = GameState.get_value(STATE_KEY, {})
	if saved_state is Dictionary:
		slot_assignments = saved_state.duplicate()
	else:
		slot_assignments = {}


func _bind_buttons() -> void:
	for flower_id in flower_buttons:
		var button: Button = flower_buttons[flower_id]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.mouse_entered.connect(_on_flower_hovered.bind(flower_id))
		button.mouse_exited.connect(_on_flower_unhovered.bind(flower_id))
		button.gui_input.connect(_on_flower_gui_input.bind(flower_id))
		button.pressed.connect(_on_flower_pressed.bind(flower_id))

	for slot_id in slot_buttons:
		var button: Button = slot_buttons[slot_id]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.z_index = 1
		button.gui_input.connect(_on_slot_gui_input.bind(slot_id))
		button.pressed.connect(_on_slot_pressed.bind(slot_id))


func _create_flower_tooltip() -> void:
	flower_tooltip = PanelContainer.new()
	flower_tooltip.visible = false
	flower_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flower_tooltip.z_index = 100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.035, 0.02, 0.76)
	style.border_color = Color(0.76, 0.55, 0.28, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	flower_tooltip.add_theme_stylebox_override("panel", style)

	flower_tooltip_label = Label.new()
	flower_tooltip_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.62, 0.94))
	flower_tooltip_label.add_theme_font_size_override("font_size", 16)
	flower_tooltip.add_child(flower_tooltip_label)
	add_child(flower_tooltip)


func _process(_delta: float) -> void:
	if flower_tooltip != null and flower_tooltip.visible:
		_position_flower_tooltip()


func _on_flower_hovered(flower_id: String) -> void:
	if is_dragging:
		return

	hovered_flower = flower_id
	flower_tooltip_label.text = FLOWER_NAMES[flower_id]
	flower_tooltip.visible = true
	flower_tooltip.reset_size()
	_position_flower_tooltip()


func _on_flower_unhovered(flower_id: String) -> void:
	if hovered_flower != flower_id:
		return

	hovered_flower = ""
	flower_tooltip.visible = false


func _position_flower_tooltip() -> void:
	var tooltip_size := flower_tooltip.get_combined_minimum_size()
	var target_position := get_local_mouse_position() + Vector2(14.0, -34.0)
	target_position.x = clamp(target_position.x, 8.0, max(8.0, size.x - tooltip_size.x - 8.0))
	target_position.y = clamp(target_position.y, 8.0, max(8.0, size.y - tooltip_size.y - 8.0))
	flower_tooltip.position = target_position


func _on_flower_pressed(flower_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG) or suppress_next_flower_press:
		suppress_next_flower_press = false
		return

	AudioManager.play_sfx("click")

	var current_slot := _get_slot_for_flower(flower_id)
	if current_slot != "":
		slot_assignments.erase(current_slot)
		selected_flower = ""
		_save_state()
	else:
		selected_flower = flower_id

	_update_visuals()


func _on_flower_gui_input(event: InputEvent, flower_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_flower = flower_id
			drag_start_position = get_local_mouse_position()
			drag_previous_slot = _get_slot_for_flower(flower_id)
			is_dragging = false
		return


func _on_slot_gui_input(event: InputEvent, slot_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG) or not slot_assignments.has(slot_id):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_flower = slot_assignments[slot_id]
			drag_start_position = get_local_mouse_position()
			drag_previous_slot = slot_id
			is_dragging = false
		return


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if drag_flower == "":
			return
		var mouse_position := get_local_mouse_position()
		if not is_dragging and mouse_position.distance_to(drag_start_position) >= DRAG_START_DISTANCE:
			_start_drag()
		if is_dragging:
			_move_dragged_flower(mouse_position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or event.pressed:
			return
		if is_dragging:
			_finish_drag(get_local_mouse_position())
			get_viewport().set_input_as_handled()
		elif selected_flower != "":
			var slot_id := _get_slot_at_position(get_local_mouse_position())
			if slot_id != "":
				AudioManager.play_sfx("click")
				_place_selected_flower_in_slot(slot_id)
				get_viewport().set_input_as_handled()
			_reset_drag_state()
		else:
			_reset_drag_state()


func _start_drag() -> void:
	is_dragging = true
	suppress_next_flower_press = true
	suppress_next_slot_press = true
	hovered_flower = ""
	flower_tooltip.visible = false
	selected_flower = drag_flower
	if drag_previous_slot != "":
		slot_assignments.erase(drag_previous_slot)
		_save_state()
	_update_visuals()
	flower_nodes[drag_flower].z_index = 10


func _move_dragged_flower(center_position: Vector2) -> void:
	_set_flower_rect_view(flower_nodes[drag_flower], center_position, FLOWER_SCALE)
	_set_button_rect_view(flower_buttons[drag_flower], center_position, FLOWER_HOTSPOT_SIZE)


func _finish_drag(drop_position: Vector2) -> void:
	var slot_id := _get_slot_at_position(drop_position)
	if slot_id != "":
		slot_assignments[slot_id] = drag_flower

	flower_nodes[drag_flower].z_index = 0
	selected_flower = ""
	_save_state()
	_reset_drag_state()
	_update_visuals()
	call_deferred("_clear_suppress_next_flower_press")

	_check_solution()


func _reset_drag_state() -> void:
	drag_flower = ""
	drag_start_position = Vector2.ZERO
	drag_previous_slot = ""
	is_dragging = false


func _clear_suppress_next_flower_press() -> void:
	suppress_next_flower_press = false
	suppress_next_slot_press = false


func _on_slot_pressed(slot_id: String) -> void:
	if GameState.get_flag(SOLVED_FLAG):
		return

	if suppress_next_slot_press:
		suppress_next_slot_press = false
		return

	if selected_flower == "":
		if slot_assignments.has(slot_id):
			AudioManager.play_sfx("click")
			slot_assignments.erase(slot_id)
			_save_state()
			_update_visuals()
		return

	AudioManager.play_sfx("click")
	_place_selected_flower_in_slot(slot_id)


func _place_selected_flower_in_slot(slot_id: String) -> void:
	var previous_slot := _get_slot_for_flower(selected_flower)
	if previous_slot != "":
		slot_assignments.erase(previous_slot)

	slot_assignments[slot_id] = selected_flower
	selected_flower = ""
	_save_state()
	_update_visuals()
	_check_solution()


func _get_slot_for_flower(flower_id: String) -> String:
	for slot_id in slot_assignments:
		if slot_assignments[slot_id] == flower_id:
			return slot_id
	return ""


func _get_slot_at_position(position: Vector2) -> String:
	var art_position := _view_to_art_position(position)
	for slot_id in SLOT_HITBOXES:
		if SLOT_HITBOXES[slot_id].has_point(art_position):
			return slot_id
	return ""


func _save_state() -> void:
	GameState.set_value(STATE_KEY, slot_assignments.duplicate())


func _update_visuals() -> void:
	var placed_flowers := {}
	for slot_id in slot_assignments:
		placed_flowers[slot_assignments[slot_id]] = slot_id

	for flower_id in flower_nodes:
		var flower: TextureRect = flower_nodes[flower_id]
		flower.texture = FLOWER_TEXTURES[flower_id]
		flower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		var target_position: Vector2
		var target_scale := FLOWER_SCALE
		var is_placed := false
		if placed_flowers.has(flower_id):
			target_position = SLOT_POSITIONS[placed_flowers[flower_id]]
			target_scale = PLACED_FLOWER_SCALE
			is_placed = true
		else:
			target_position = FLOWER_START_POSITIONS[flower_id]

		if is_placed:
			_set_flower_rect_art(flower, target_position, target_scale)
			_set_button_rect_art(flower_buttons[flower_id], target_position, FLOWER_HOTSPOT_SIZE)
			flower_buttons[flower_id].z_index = 20
		else:
			_set_flower_rect_view(flower, target_position, target_scale)
			_set_button_rect_view(flower_buttons[flower_id], target_position, FLOWER_HOTSPOT_SIZE)
			flower_buttons[flower_id].z_index = 10
		flower.modulate = Color(1.18, 1.12, 1.0, 1.0) if flower_id == selected_flower else Color.WHITE

	for slot_id in slot_buttons:
		_set_button_from_art_rect(slot_buttons[slot_id], SLOT_HITBOXES[slot_id])


func _set_flower_rect_art(flower: TextureRect, center_position: Vector2, scale_factor: float) -> void:
	var flower_id := _get_flower_id_for_node(flower)
	var texture: Texture2D = FLOWER_TEXTURES[flower_id]
	var rect_size := _art_size_to_view_size(Vector2(texture.get_width(), texture.get_height()) * scale_factor)
	var view_position := _art_to_view_position(center_position)
	var anchor_position := _art_size_to_view_size(FLOWER_ANCHORS[flower_id] * scale_factor)
	flower.position = view_position - anchor_position
	flower.size = rect_size


func _set_flower_rect_view(flower: TextureRect, center_position: Vector2, scale_factor: float) -> void:
	var texture: Texture2D = FLOWER_TEXTURES[_get_flower_id_for_node(flower)]
	var rect_size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
	flower.position = center_position - (rect_size / 2.0)
	flower.size = rect_size


func _set_button_rect_art(button: Button, center_position: Vector2, rect_size: Vector2) -> void:
	var view_position := _art_to_view_position(center_position)
	var view_size := _art_size_to_view_size(rect_size)
	button.position = view_position - (view_size / 2.0)
	button.size = view_size


func _set_button_rect_view(button: Button, center_position: Vector2, rect_size: Vector2) -> void:
	button.position = center_position - (rect_size / 2.0)
	button.size = rect_size


func _set_button_from_art_rect(button: Button, art_rect: Rect2) -> void:
	button.position = _art_to_view_position(art_rect.position)
	button.size = _art_size_to_view_size(art_rect.size)


func _get_view_scale() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(size.x / ART_SIZE.x, size.y / ART_SIZE.y)


func _art_to_view_position(position: Vector2) -> Vector2:
	return position * _get_view_scale()


func _art_size_to_view_size(rect_size: Vector2) -> Vector2:
	return rect_size * _get_view_scale()


func _view_to_art_position(position: Vector2) -> Vector2:
	var view_scale := _get_view_scale()
	return Vector2(position.x / view_scale.x, position.y / view_scale.y)


func _get_flower_id_for_node(node: TextureRect) -> String:
	for flower_id in flower_nodes:
		if flower_nodes[flower_id] == node:
			return flower_id
	return ""


func _is_filled() -> bool:
	return slot_assignments.size() == SLOT_POSITIONS.size()


func _is_solved() -> bool:
	for slot_id in SOLUTION:
		if slot_assignments.get(slot_id, "") != SOLUTION[slot_id]:
			return false
	return true


func _check_solution() -> void:
	if _is_filled() and _is_solved():
		GameState.set_flag(SOLVED_FLAG, true)
		interaction_requested.emit("floral_reliquary_solved")
