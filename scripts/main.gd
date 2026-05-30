extends Node

const ItemDatabase := preload("res://scripts/data/item_database.gd")
const MESSAGE_VISIBLE_TIME := 2.4
const MESSAGE_FADE_TIME := 0.45
const ROOM_FADE_TIME := 0.25

@onready var current_room_container: Node = $CurrentRoomContainer
@onready var zoom_manager: Control = $ZoomLayer/ZoomManager
@onready var inventory_ui: Control = $UILayer/InventoryUI
@onready var letter_popup: Control = $UILayer/ReadableLetterPopup
@onready var message_panel: PanelContainer = $UILayer/MessagePanel
@onready var message_label: Label = $UILayer/MessagePanel/MessageLabel
@onready var exit_to_hall_button: TextureButton = $UILayer/ExitToHallButton
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var puzzle: Control = $PuzzleLayer/SymbolSequencePuzzle

var room_scenes := {
	"hall": preload("res://scenes/rooms/hall/hall_main.tscn"),
	"bedroom": preload("res://scenes/rooms/bedroom/bedroom_main.tscn"),
	"office": preload("res://scenes/rooms/office/office_main.tscn"),
	"library": preload("res://scenes/rooms/library/library_main.tscn"),
	"dining_room": preload("res://scenes/rooms/dining_room/dining_room_main.tscn"),
}

var current_room_id := ""
var hovered_interactables: Dictionary = {}
var message_tween: Tween = null
var room_transition_tween: Tween = null
var cursor_shape_by_type := {
	"interact": Input.CURSOR_POINTING_HAND,
	"pickup": Input.CURSOR_CAN_DROP,
	"grab": Input.CURSOR_DRAG,
	"inspect": Input.CURSOR_POINTING_HAND,
	"blocked": Input.CURSOR_FORBIDDEN,
}


func _ready() -> void:
	add_to_group("cursor_listeners")
	_setup_custom_cursors()
	GameState.reset()
	Inventory.clear()
	_setup_room_navigation_ui()
	go_to_room("hall", false)
	zoom_manager.zoom_interaction_requested.connect(_on_zoom_interaction_requested)
	zoom_manager.zoom_opened.connect(_on_zoom_opened)
	zoom_manager.zoom_closed.connect(_on_zoom_visibility_changed)
	inventory_ui.item_selected.connect(_on_inventory_item_selected)
	puzzle.visible = false
	puzzle.puzzle_solved.connect(_on_jewelry_puzzle_solved)
	puzzle.puzzle_closed.connect(_close_puzzle)
	show_message("Escolha uma porta.")


func _process(_delta: float) -> void:
	var hovered_ui_cursor := _get_hovered_ui_cursor_shape()
	if hovered_ui_cursor != -1:
		Input.set_default_cursor_shape(hovered_ui_cursor)
		return

	_prune_hovered_interactables()
	if not hovered_interactables.is_empty():
		Input.set_default_cursor_shape(_get_active_cursor_shape())
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _setup_custom_cursors() -> void:
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_default.png"), Input.CURSOR_ARROW, Vector2(28, 10))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_interact.png"), Input.CURSOR_POINTING_HAND, Vector2(28, 10))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_grab.png"), Input.CURSOR_DRAG, Vector2(30, 16))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_pickup.png"), Input.CURSOR_CAN_DROP, Vector2(30, 16))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_blocked.png"), Input.CURSOR_FORBIDDEN, Vector2(28, 10))
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_interactable_hover_changed(interactable: Node, is_hovered: bool, cursor_type: String = "interact") -> void:
	if is_hovered:
		hovered_interactables[interactable] = cursor_type
	else:
		hovered_interactables.erase(interactable)


func _prune_hovered_interactables() -> void:
	for interactable in hovered_interactables.keys():
		if not is_instance_valid(interactable):
			hovered_interactables.erase(interactable)
			continue
		if interactable.has_method("is_available") and not interactable.is_available():
			hovered_interactables.erase(interactable)
			continue
		if interactable is CollisionObject2D and not interactable.input_pickable:
			hovered_interactables.erase(interactable)


func _get_active_cursor_shape() -> int:
	if "pickup" in hovered_interactables.values():
		return cursor_shape_by_type["pickup"]
	if "grab" in hovered_interactables.values():
		return cursor_shape_by_type["grab"]
	if "blocked" in hovered_interactables.values():
		return cursor_shape_by_type["blocked"]
	return cursor_shape_by_type["interact"]


func _get_hovered_ui_cursor_shape() -> int:
	var hovered_control := get_viewport().gui_get_hovered_control()
	while hovered_control != null:
		if hovered_control.has_method("is_available") and hovered_control.has_method("_get_control_cursor_shape"):
			if hovered_control.is_available():
				return hovered_control._get_control_cursor_shape()
			return Input.CURSOR_ARROW
		hovered_control = hovered_control.get_parent() as Control
	return -1


func _setup_room_navigation_ui() -> void:
	exit_to_hall_button.pressed.connect(_on_exit_to_hall_pressed)
	exit_to_hall_button.mouse_entered.connect(_on_exit_to_hall_hover_changed.bind(true))
	exit_to_hall_button.mouse_exited.connect(_on_exit_to_hall_hover_changed.bind(false))
	exit_to_hall_button.visible = false
	exit_to_hall_button.modulate.a = 0.62
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0


func go_to_room(room_id: String, animated: bool = true) -> void:
	if not room_scenes.has(room_id):
		push_warning("Cenario nao encontrado: " + room_id)
		return

	if room_transition_tween != null:
		room_transition_tween.kill()

	if animated:
		_set_exit_to_hall_visible(false)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		room_transition_tween = create_tween()
		room_transition_tween.tween_property(fade_rect, "modulate:a", 1.0, ROOM_FADE_TIME)
		room_transition_tween.tween_callback(_load_room.bind(room_id))
		room_transition_tween.tween_property(fade_rect, "modulate:a", 0.0, ROOM_FADE_TIME)
		room_transition_tween.tween_callback(func() -> void:
			room_transition_tween = null
			fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_update_exit_to_hall_visibility()
		)
	else:
		_load_room(room_id)
		_update_exit_to_hall_visibility()


func _load_room(room_id: String) -> void:
	for child in current_room_container.get_children():
		child.queue_free()

	current_room_id = room_id
	hovered_interactables.clear()
	var room: Node = room_scenes[room_id].instantiate()
	current_room_container.add_child(room)
	if room.has_signal("interaction_requested"):
		room.interaction_requested.connect(_on_room_interaction_requested)


func _set_exit_to_hall_visible(is_visible: bool) -> void:
	exit_to_hall_button.visible = is_visible
	exit_to_hall_button.disabled = not is_visible


func _update_exit_to_hall_visibility() -> void:
	_set_exit_to_hall_visible(current_room_id != "hall" and not zoom_manager.visible)


func _on_zoom_visibility_changed() -> void:
	_update_exit_to_hall_visibility()


func _on_zoom_opened(_zoom_id: String) -> void:
	_update_exit_to_hall_visibility()


func _on_exit_to_hall_pressed() -> void:
	clear_message()
	AudioManager.play_sfx("door")
	go_to_room("hall")


func _on_exit_to_hall_hover_changed(is_hovered: bool) -> void:
	exit_to_hall_button.modulate.a = 1.0 if is_hovered else 0.62


func _on_room_interaction_requested(interaction_id: String) -> void:
	clear_message()

	match interaction_id:
		"go_bedroom":
			go_to_room("bedroom")
		"go_office":
			go_to_room("office")
		"go_library":
			go_to_room("library")
		"go_dining_room":
			go_to_room("dining_room")
		"go_center_locked":
			show_message("Esta porta nao se abre por enquanto.")
		"portrait":
			zoom_manager.open_zoom("portrait_moon")
		"sofa_flower":
			zoom_manager.open_zoom("sofa_flower")
		"rug_crown":
			zoom_manager.open_zoom("rug_crown")
		"writing_desk_key_book":
			zoom_manager.open_zoom("writing_desk_key_book")
		"jewelry_box":
			_open_jewelry_box_zoom()
		"wardrobe":
			if GameState.get_flag("bedroom_jacket_note_collected"):
				zoom_manager.open_zoom("wardrobe_open_without_note")
			else:
				zoom_manager.open_zoom("wardrobe_open_with_note")
		"chest_drawer":
			zoom_manager.open_zoom("chest_drawer_open")
		"nightstand_top":
			zoom_manager.open_zoom("nightstand_top_drawer_open")
		"nightstand_bottom":
			zoom_manager.open_zoom("nightstand_bottom_drawer_open")
		"dining_room_clock":
			zoom_manager.open_zoom("dining_room_clock")


func _on_zoom_interaction_requested(interaction_id: String) -> void:
	match interaction_id:
		"pickup_jacket_note":
			if Inventory.add_item("item_jacket_note"):
				GameState.set_flag("bedroom_jacket_note_collected", true)
				show_message("Você pegou uma carta dobrada.")
			zoom_manager.open_zoom("wardrobe_open_without_note")
		"open_jewelry_puzzle":
			puzzle.visible = true
			clear_message()
		"open_clock_pendulums":
			zoom_manager.open_zoom("dining_room_clock_pendulums")
		"pickup_small_key":
			if Inventory.add_item("item_small_victorian_key"):
				GameState.set_flag("bedroom_small_key_collected", true)
				show_message("Você pegou uma pequena chave.")
			_refresh_jewelry_box_after_pickup()
		"pickup_box_letter":
			if Inventory.add_item("item_box_letter"):
				GameState.set_flag("bedroom_box_letter_collected", true)
				show_message("Você pegou uma carta selada.")
			_refresh_jewelry_box_after_pickup()
		"clock_pendulums_solved":
			show_message("Os pêndulos se alinharam.")


func _on_inventory_item_selected(item_id: String) -> void:
	var item_data := ItemDatabase.get_item(item_id)
	var item_type: String = item_data.get("type", "")
	if item_type == "readable" or item_type == "inspectable":
		if item_id == "item_jacket_note":
			GameState.set_flag("bedroom_jacket_note_read", true)
		if item_id == "item_box_letter":
			GameState.set_flag("bedroom_box_letter_read", true)
		letter_popup.open_item(item_id)
	else:
		show_message(item_data.get("description", item_data.get("name", item_id)))


func _on_jewelry_puzzle_solved() -> void:
	await get_tree().create_timer(0.4).timeout
	_close_puzzle()
	_open_jewelry_box_zoom()
	show_message("A caixa se abriu.")


func _close_puzzle() -> void:
	puzzle.visible = false


func _open_jewelry_box_zoom() -> void:
	if not GameState.get_flag("bedroom_jewelry_box_solved"):
		zoom_manager.open_zoom("jewelry_box_closed")
		return

	var has_key := GameState.get_flag("bedroom_small_key_collected")
	var has_letter := GameState.get_flag("bedroom_box_letter_collected")

	if has_key and has_letter:
		zoom_manager.open_zoom("jewelry_box_empty")
	elif has_key:
		zoom_manager.open_zoom("jewelry_box_only_letter")
	elif has_letter:
		zoom_manager.open_zoom("jewelry_box_only_key")
	else:
		zoom_manager.open_zoom("jewelry_box_open")


func _refresh_jewelry_box_after_pickup() -> void:
	_open_jewelry_box_zoom()


func _is_jewelry_box_empty() -> bool:
	return (
		GameState.get_flag("bedroom_jewelry_box_solved")
		and GameState.get_flag("bedroom_small_key_collected")
		and GameState.get_flag("bedroom_box_letter_collected")
	)


func show_message(text: String) -> void:
	if message_tween != null:
		message_tween.kill()

	message_label.text = text
	message_panel.visible = true
	message_panel.modulate.a = 1.0

	message_tween = create_tween()
	message_tween.tween_interval(MESSAGE_VISIBLE_TIME)
	message_tween.tween_property(message_panel, "modulate:a", 0.0, MESSAGE_FADE_TIME)
	message_tween.tween_callback(_on_message_faded)


func clear_message() -> void:
	if message_tween != null:
		message_tween.kill()
		message_tween = null

	message_label.text = ""
	message_panel.modulate.a = 0.0
	message_panel.visible = false


func _on_message_faded() -> void:
	message_tween = null
	message_label.text = ""
	message_panel.visible = false
