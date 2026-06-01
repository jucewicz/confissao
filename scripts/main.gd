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
@onready var door_hover_panel: PanelContainer = $UILayer/DoorHoverPanel
@onready var door_hover_label: Label = $UILayer/DoorHoverPanel/DoorHoverLabel
@onready var exit_to_hall_button: TextureButton = $UILayer/ExitToHallButton
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var puzzle: Control = $PuzzleLayer/SymbolSequencePuzzle
@onready var main_menu: Control = $MenuLayer/MainMenu
@onready var pause_menu: Control = $MenuLayer/PauseMenu
@onready var victory_menu: Control = $MenuLayer/VictoryMenu

var room_scenes := {
	"hall": preload("res://scenes/rooms/hall/hall_main.tscn"),
	"bedroom": preload("res://scenes/rooms/bedroom/bedroom_main.tscn"),
	"office": preload("res://scenes/rooms/office/office_main.tscn"),
	"library": preload("res://scenes/rooms/library/library_main.tscn"),
	"dining_room": preload("res://scenes/rooms/dining_room/dining_room_main.tscn"),
}

var current_room_id := ""
var hovered_interactables: Dictionary = {}
var hovered_door_interactable: Node = null
var message_tween: Tween = null
var room_transition_tween: Tween = null
var has_started_game := false
var has_won_game := false
var menu_transition_running := false
var cursor_shape_by_type := {
	"interact": Input.CURSOR_POINTING_HAND,
	"pickup": Input.CURSOR_CAN_DROP,
	"grab": Input.CURSOR_DRAG,
	"inspect": Input.CURSOR_POINTING_HAND,
	"blocked": Input.CURSOR_FORBIDDEN,
}
var hall_door_names := {
	"go_bedroom": "Quarto",
	"go_office": "Escritório",
	"go_library": "Biblioteca",
	"go_dining_room": "Sala de jantar",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("cursor_listeners")
	_setup_custom_cursors()
	GameState.reset()
	Inventory.clear()
	_setup_room_navigation_ui()
	_setup_menus()
	go_to_room("bedroom", false)
	zoom_manager.zoom_interaction_requested.connect(_on_zoom_interaction_requested)
	zoom_manager.zoom_opened.connect(_on_zoom_opened)
	zoom_manager.zoom_closed.connect(_on_zoom_visibility_changed)
	inventory_ui.item_selected.connect(_on_inventory_item_selected)
	puzzle.visible = false
	puzzle.puzzle_solved.connect(_on_jewelry_puzzle_solved)
	puzzle.puzzle_closed.connect(_close_puzzle)
	_show_main_menu()


func _process(_delta: float) -> void:
	if main_menu.visible or pause_menu.visible or victory_menu.visible:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	var hovered_ui_cursor := _get_hovered_ui_cursor_shape()
	if hovered_ui_cursor != -1:
		Input.set_default_cursor_shape(hovered_ui_cursor)
		return

	_prune_hovered_interactables()
	if not hovered_interactables.is_empty():
		Input.set_default_cursor_shape(_get_active_cursor_shape())
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	_update_door_hover_position()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if menu_transition_running:
		get_viewport().set_input_as_handled()
		return
	if main_menu.visible:
		get_viewport().set_input_as_handled()
		return
	if victory_menu.visible:
		get_viewport().set_input_as_handled()
		return
	if pause_menu.visible:
		_resume_game()
	else:
		_open_pause_menu()
	get_viewport().set_input_as_handled()


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

	_update_door_hover(interactable, is_hovered)


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
	door_hover_panel.visible = false
	door_hover_panel.modulate.a = 0.0
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0


func _setup_menus() -> void:
	main_menu.start_requested.connect(_start_new_game)
	main_menu.resume_requested.connect(_resume_game)
	main_menu.quit_requested.connect(_quit_game)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.main_menu_requested.connect(_return_to_main_menu)
	pause_menu.quit_requested.connect(_quit_game)
	victory_menu.main_menu_requested.connect(_return_to_main_menu)
	victory_menu.quit_requested.connect(_quit_game)


func _show_main_menu() -> void:
	clear_message()
	get_tree().paused = true
	main_menu.set_resume_enabled(has_started_game)
	main_menu.open()
	pause_menu.close()
	victory_menu.close()


func _start_new_game() -> void:
	if menu_transition_running:
		return
	menu_transition_running = true
	has_started_game = true
	has_won_game = false
	pause_menu.close()
	victory_menu.close()
	GameState.reset()
	Inventory.clear()
	letter_popup.close()
	_close_puzzle()
	zoom_manager.close_zoom(false)
	go_to_room("bedroom", false)
	await main_menu.fade_out()
	get_tree().paused = false
	menu_transition_running = false
	show_message("A porta está trancada.")


func _open_pause_menu() -> void:
	if menu_transition_running or has_won_game:
		return
	clear_message()
	get_tree().paused = true
	pause_menu.open()


func _resume_game() -> void:
	if menu_transition_running:
		return
	menu_transition_running = true
	if main_menu.visible:
		await main_menu.fade_out()
	if pause_menu.visible:
		await pause_menu.fade_out()
	if victory_menu.visible:
		await victory_menu.fade_out()
	get_tree().paused = false
	menu_transition_running = false


func _return_to_main_menu() -> void:
	if menu_transition_running:
		return
	has_started_game = false
	_show_main_menu()


func _quit_game() -> void:
	get_tree().quit()


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
	_hide_door_hover()
	var room: Node = room_scenes[room_id].instantiate()
	current_room_container.add_child(room)
	if room.has_signal("interaction_requested"):
		room.interaction_requested.connect(_on_room_interaction_requested)


func _update_door_hover(interactable: Node, is_hovered: bool) -> void:
	if current_room_id != "hall":
		_hide_door_hover()
		return
	if not interactable.has_method("is_available") or not interactable.is_available():
		_hide_door_hover()
		return
	var interaction_id_variant: Variant = interactable.get("interaction_id")
	if not interaction_id_variant is String:
		return

	var interaction_id: String = interaction_id_variant
	if not hall_door_names.has(interaction_id):
		if hovered_door_interactable == interactable:
			_hide_door_hover()
		return

	if is_hovered:
		hovered_door_interactable = interactable
		door_hover_label.text = hall_door_names[interaction_id]
		door_hover_panel.visible = true
		door_hover_panel.modulate.a = 1.0
		_update_door_hover_position()
	elif hovered_door_interactable == interactable:
		_hide_door_hover()


func _update_door_hover_position() -> void:
	if not door_hover_panel.visible:
		return

	var mouse_position := get_viewport().get_mouse_position()
	var panel_size := door_hover_panel.size
	var viewport_size := get_viewport().get_visible_rect().size
	var position := mouse_position + Vector2(-(panel_size.x / 2.0), -panel_size.y - 24.0)
	position.x = clamp(position.x, 12.0, viewport_size.x - panel_size.x - 12.0)
	position.y = clamp(position.y, 12.0, viewport_size.y - panel_size.y - 12.0)
	door_hover_panel.position = position


func _hide_door_hover() -> void:
	hovered_door_interactable = null
	if door_hover_panel != null:
		door_hover_panel.visible = false


func _set_exit_to_hall_visible(is_visible: bool) -> void:
	exit_to_hall_button.visible = is_visible
	exit_to_hall_button.disabled = not is_visible
	_update_exit_to_hall_tooltip()


func _update_exit_to_hall_visibility() -> void:
	_set_exit_to_hall_visible(current_room_id != "hall" and not zoom_manager.visible)


func _on_zoom_visibility_changed() -> void:
	_update_exit_to_hall_visibility()


func _on_zoom_opened(_zoom_id: String) -> void:
	_update_exit_to_hall_visibility()


func _on_exit_to_hall_pressed() -> void:
	clear_message()

	if current_room_id == "bedroom" and not GameState.get_flag("bedroom_door_unlocked"):
		if not GameState.get_flag("bedroom_small_key_collected"):
			show_message("A porta está trancada.")
			return

		Inventory.remove_item("item_small_victorian_key")
		GameState.set_flag("bedroom_door_unlocked", true)
		show_message("A chave gira na fechadura.")

	AudioManager.play_sfx("door")
	go_to_room("hall")


func _on_exit_to_hall_hover_changed(is_hovered: bool) -> void:
	exit_to_hall_button.modulate.a = 1.0 if is_hovered else 0.62


func _update_exit_to_hall_tooltip() -> void:
	if current_room_id == "bedroom" and not GameState.get_flag("bedroom_door_unlocked"):
		exit_to_hall_button.tooltip_text = "Porta trancada"
	else:
		exit_to_hall_button.tooltip_text = "Voltar ao corredor"


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
			_open_dining_room_clock_zoom()


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
			zoom_manager.open_zoom("dining_room_clock_pendulums", true)
		"open_clock_drawer_inscription":
			zoom_manager.open_zoom("dining_room_clock_drawer_inscription", true)
		"pickup_small_key":
			if Inventory.add_item("item_small_victorian_key"):
				GameState.set_flag("bedroom_small_key_collected", true)
				show_message("Você pegou uma pequena chave.")
				if _check_victory_condition():
					return
			_refresh_jewelry_box_after_pickup()
		"pickup_box_letter":
			if Inventory.add_item("item_box_letter"):
				GameState.set_flag("bedroom_box_letter_collected", true)
				show_message("Você pegou uma carta selada.")
				if _check_victory_condition():
					return
			_refresh_jewelry_box_after_pickup()
		"clock_pendulums_solved":
			show_message("Os pêndulos se alinharam.")
			_open_dining_room_clock_zoom()
		"pickup_eye_medallion":
			if Inventory.add_item("item_eye_medallion"):
				GameState.set_flag("dining_room_eye_medallion_collected", true)
				show_message("Você pegou o medalhão do olho fechado.")
				if _check_victory_condition():
					return
			_open_dining_room_clock_zoom()


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


func _open_dining_room_clock_zoom() -> void:
	if not GameState.get_flag("dining_room_clock_pendulums_solved"):
		zoom_manager.open_zoom("dining_room_clock")
		return

	if GameState.get_flag("dining_room_eye_medallion_collected"):
		zoom_manager.open_zoom("dining_room_clock_open_without_eye_medallion")
	else:
		zoom_manager.open_zoom("dining_room_clock_open_with_eye_medallion")


func _is_jewelry_box_empty() -> bool:
	return (
		GameState.get_flag("bedroom_jewelry_box_solved")
		and GameState.get_flag("bedroom_small_key_collected")
		and GameState.get_flag("bedroom_box_letter_collected")
	)


func _check_victory_condition() -> bool:
	if has_won_game:
		return true

	if (
		GameState.get_flag("bedroom_small_key_collected")
		and GameState.get_flag("bedroom_box_letter_collected")
		and GameState.get_flag("dining_room_eye_medallion_collected")
	):
		_show_victory_screen()
		return true

	return false


func _show_victory_screen() -> void:
	has_won_game = true
	has_started_game = false
	clear_message()
	_close_puzzle()
	letter_popup.close()
	zoom_manager.close_zoom(false)
	get_tree().paused = true
	main_menu.close()
	pause_menu.close()
	victory_menu.open()


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
