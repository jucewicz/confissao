extends Control

signal interaction_requested(interaction_id: String)

const STATE_KEY := "library_book_path_puzzle_state"
const SOLVED_FLAG := "library_book_path_puzzle_solved"
const ART_SIZE := Vector2(1672.0, 941.0)
const DRAG_START_DISTANCE := 8.0
const BOOK_DRAW_SIZE := Vector2(250.0, 375.0)
const BOOK_HITBOX_SIZE := Vector2(78.0, 365.0)
const PATH_HALF_WIDTH := 41.0
const PATH_CORE_WIDTH := 8.0
const PATH_BORDER_WIDTH := 13.0
const PATH_BORDER_COLOR := Color(0.74, 0.49, 0.18, 1.0)
const PATH_CORE_COLOR := Color(0.015, 0.012, 0.01, 1.0)

const SOLUTION := ["book_1", "book_2", "book_3", "book_4", "book_5", "book_6"]
const INITIAL_ORDER := ["book_2", "book_4", "book_6", "book_5", "book_3", "book_1"]
const PATH_START_LEVEL := 0.0
const PATH_END_LEVEL := -84.0
const PATH_LEVELS := {
	"low": 84.0,
	"middle": 0.0,
	"high": -84.0,
}

const BOOK_TEXTURE := preload("res://art/zoom_ins/library/book_path_blank.png")
const PATH_SEGMENTS := {
	"book_1": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["middle"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["middle"]),
	],
	"book_2": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["middle"]),
		Vector2(-12.0, PATH_LEVELS["middle"]),
		Vector2(-12.0, PATH_LEVELS["low"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["low"]),
	],
	"book_3": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["low"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["low"]),
	],
	"book_4": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["low"]),
		Vector2(-12.0, PATH_LEVELS["low"]),
		Vector2(-12.0, PATH_LEVELS["middle"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["middle"]),
	],
	"book_5": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["middle"]),
		Vector2(-12.0, PATH_LEVELS["middle"]),
		Vector2(-12.0, PATH_LEVELS["high"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["high"]),
	],
	"book_6": [
		Vector2(-PATH_HALF_WIDTH, PATH_LEVELS["high"]),
		Vector2(PATH_HALF_WIDTH, PATH_LEVELS["high"]),
	],
}

const SLOT_POSITIONS := [
	Vector2(632.0, 516.0),
	Vector2(714.0, 516.0),
	Vector2(796.0, 516.0),
	Vector2(878.0, 516.0),
	Vector2(960.0, 516.0),
	Vector2(1042.0, 516.0),
]

@onready var book_nodes := {
	"book_1": $Book1,
	"book_2": $Book2,
	"book_3": $Book3,
	"book_4": $Book4,
	"book_5": $Book5,
	"book_6": $Book6,
}

@onready var slot_buttons := [
	$Slot1Hotspot,
	$Slot2Hotspot,
	$Slot3Hotspot,
	$Slot4Hotspot,
	$Slot5Hotspot,
	$Slot6Hotspot,
]

var slot_books: Array[String] = []
var drag_book := ""
var drag_origin_slot := -1
var drag_start_position := Vector2.ZERO
var is_dragging := false
var suppress_next_slot_press := false
var path_lines := {}


func _ready() -> void:
	_create_path_lines()
	_load_state()
	_bind_slots()
	_update_visuals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_visuals()


func _load_state() -> void:
	var saved_state: Variant = GameState.get_value(STATE_KEY, [])
	if saved_state is Array and saved_state.size() == SLOT_POSITIONS.size():
		slot_books.assign(saved_state)
	else:
		slot_books.assign(SOLUTION if GameState.get_flag(SOLVED_FLAG) else INITIAL_ORDER)


func _bind_slots() -> void:
	for slot_index in range(slot_buttons.size()):
		var button: Button = slot_buttons[slot_index]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_DRAG
		button.gui_input.connect(_on_slot_gui_input.bind(slot_index))


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if GameState.get_flag(SOLVED_FLAG):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_book = slot_books[slot_index]
			drag_origin_slot = slot_index
			drag_start_position = get_local_mouse_position()
			is_dragging = false
			suppress_next_slot_press = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if drag_book == "":
			return

		var mouse_position := get_local_mouse_position()
		if not is_dragging and mouse_position.distance_to(drag_start_position) >= DRAG_START_DISTANCE:
			_start_drag()
		if is_dragging:
			_move_dragged_book(mouse_position)
			var hovered_slot := _get_slot_at_position(mouse_position)
			if hovered_slot != -1 and hovered_slot != drag_origin_slot:
				_swap_dragged_book_into_slot(hovered_slot)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or event.pressed:
			return

		if is_dragging:
			_finish_drag()
			get_viewport().set_input_as_handled()
		else:
			_reset_drag_state()


func _start_drag() -> void:
	is_dragging = true
	suppress_next_slot_press = true
	book_nodes[drag_book].z_index = 20
	_move_dragged_book(get_local_mouse_position())


func _move_dragged_book(center_position: Vector2) -> void:
	_set_book_rect_view(book_nodes[drag_book], center_position)
	_update_path_line_for_book(drag_book, center_position, false)


func _swap_dragged_book_into_slot(target_slot_index: int) -> void:
	var displaced_book := slot_books[target_slot_index]
	slot_books[target_slot_index] = drag_book
	slot_books[drag_origin_slot] = displaced_book
	drag_origin_slot = target_slot_index
	_save_state()
	_update_visuals(false)
	_move_dragged_book(get_local_mouse_position())
	AudioManager.play_sfx("click")


func _finish_drag() -> void:
	book_nodes[drag_book].z_index = 0
	_save_state()
	_reset_drag_state()
	_update_visuals()
	call_deferred("_clear_suppress_next_slot_press")
	_check_solution()


func _reset_drag_state() -> void:
	drag_book = ""
	drag_origin_slot = -1
	drag_start_position = Vector2.ZERO
	is_dragging = false


func _clear_suppress_next_slot_press() -> void:
	suppress_next_slot_press = false


func _save_state() -> void:
	GameState.set_value(STATE_KEY, slot_books.duplicate())


func _update_visuals(include_dragged_book: bool = true) -> void:
	for slot_index in range(slot_books.size()):
		var book_id := slot_books[slot_index]
		var book: TextureRect = book_nodes[book_id]
		book.texture = BOOK_TEXTURE
		book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if include_dragged_book or book_id != drag_book:
			_set_book_rect_art(book, SLOT_POSITIONS[slot_index])
			_update_path_line_for_book(book_id, SLOT_POSITIONS[slot_index], true)
			book.z_index = 0

	for slot_index in range(slot_buttons.size()):
		_set_slot_button_rect(slot_buttons[slot_index], SLOT_POSITIONS[slot_index])


func _create_path_lines() -> void:
	for book_id in SOLUTION:
		var border_line := Line2D.new()
		border_line.name = book_id.capitalize().replace("_", "") + "PathBorder"
		border_line.default_color = PATH_BORDER_COLOR
		border_line.width = PATH_BORDER_WIDTH
		border_line.z_index = 10
		add_child(border_line)

		var core_line := Line2D.new()
		core_line.name = book_id.capitalize().replace("_", "") + "PathCore"
		core_line.default_color = PATH_CORE_COLOR
		core_line.width = PATH_CORE_WIDTH
		core_line.z_index = 11
		add_child(core_line)

		path_lines[book_id] = {
			"border": border_line,
			"core": core_line,
		}


func _update_path_lines() -> void:
	for slot_index in range(slot_books.size()):
		_update_path_line_for_book(slot_books[slot_index], SLOT_POSITIONS[slot_index], true)


func _update_path_line_for_book(book_id: String, center_position: Vector2, center_is_art_position: bool) -> void:
	if not path_lines.has(book_id):
		return

	var center_view_position := _art_to_view_position(center_position) if center_is_art_position else center_position
	var points := PackedVector2Array()
	for point in PATH_SEGMENTS[book_id]:
		points.append(center_view_position + _art_size_to_view_size(point))

	var view_scale := _get_average_view_scale()
	for line: Line2D in path_lines[book_id].values():
		line.points = points
		line.width = (PATH_BORDER_WIDTH if line.name.ends_with("Border") else PATH_CORE_WIDTH) * view_scale


func _set_book_rect_art(book: TextureRect, center_position: Vector2) -> void:
	var rect_size := _art_size_to_view_size(BOOK_DRAW_SIZE)
	book.position = _art_to_view_position(center_position) - (rect_size / 2.0)
	book.size = rect_size


func _set_book_rect_view(book: TextureRect, center_position: Vector2) -> void:
	var rect_size := _art_size_to_view_size(BOOK_DRAW_SIZE)
	book.position = center_position - (rect_size / 2.0)
	book.size = rect_size


func _set_slot_button_rect(button: Button, center_position: Vector2) -> void:
	var rect_size := _art_size_to_view_size(BOOK_HITBOX_SIZE)
	button.position = _art_to_view_position(center_position) - (rect_size / 2.0)
	button.size = rect_size


func _get_slot_at_position(position: Vector2) -> int:
	var art_position := _view_to_art_position(position)
	for slot_index in range(SLOT_POSITIONS.size()):
		var slot_rect := Rect2(SLOT_POSITIONS[slot_index] - (BOOK_HITBOX_SIZE / 2.0), BOOK_HITBOX_SIZE)
		if slot_rect.has_point(art_position):
			return slot_index
	return -1


func _get_view_scale() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(size.x / ART_SIZE.x, size.y / ART_SIZE.y)


func _get_average_view_scale() -> float:
	var view_scale := _get_view_scale()
	return (view_scale.x + view_scale.y) / 2.0


func _art_to_view_position(position: Vector2) -> Vector2:
	return position * _get_view_scale()


func _art_size_to_view_size(rect_size: Vector2) -> Vector2:
	return rect_size * _get_view_scale()


func _view_to_art_position(position: Vector2) -> Vector2:
	var view_scale := _get_view_scale()
	return Vector2(position.x / view_scale.x, position.y / view_scale.y)


func _is_solved() -> bool:
	return _has_all_books_once() and _is_continuous_path()


func _has_all_books_once() -> bool:
	if slot_books.size() != SOLUTION.size():
		return false

	var remaining_books := SOLUTION.duplicate()
	for book_id in slot_books:
		if book_id not in remaining_books:
			return false
		remaining_books.erase(book_id)
	return remaining_books.is_empty()


func _is_continuous_path() -> bool:
	if slot_books.is_empty():
		return false
	if not is_equal_approx(_get_path_start_level(slot_books[0]), PATH_START_LEVEL):
		return false
	if not is_equal_approx(_get_path_end_level(slot_books[-1]), PATH_END_LEVEL):
		return false

	for index in range(slot_books.size() - 1):
		if not is_equal_approx(_get_path_end_level(slot_books[index]), _get_path_start_level(slot_books[index + 1])):
			return false
	return true


func _get_path_start_level(book_id: String) -> float:
	var points: Array = PATH_SEGMENTS.get(book_id, [])
	if points.is_empty():
		return INF
	return points.front().y


func _get_path_end_level(book_id: String) -> float:
	var points: Array = PATH_SEGMENTS.get(book_id, [])
	if points.is_empty():
		return INF
	return points.back().y


func _check_solution() -> void:
	if _is_solved():
		GameState.set_flag(SOLVED_FLAG, true)
		interaction_requested.emit("library_book_path_puzzle_solved")
