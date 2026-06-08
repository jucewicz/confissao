extends Node

const ItemDatabase := preload("res://scripts/data/item_database.gd")
const MESSAGE_VISIBLE_TIME := 2.4
const MESSAGE_FADE_TIME := 0.45
const FEEDBACK_NO_CHANGE := "Nada mudou."
const FEEDBACK_DOES_NOT_OPEN_HERE := "Não parece abrir daqui."
const FEEDBACK_WRONG_ITEM := "Isso não serve aqui."
const FEEDBACK_EMPTY_DRAWER := "A gaveta está vazia."
const FEEDBACK_EMPTY_JEWELRY_BOX := "Não há mais nada aqui."
const FEEDBACK_EMPTY_WARDROBE := "Só há roupas antigas."
const FEEDBACK_CLOCK_ALIGNED := "Os pêndulos permanecem alinhados."
const FEEDBACK_EMPTY_CLOCK_COMPARTMENT := "O compartimento está vazio."
const FEEDBACK_EMPTY_LIBRARY_SHELF := "O espaço do livro ficou vazio."
const BLOCKED_SHAKE_DISTANCE := 12.0
const BLOCKED_SHAKE_STEP_TIME := 0.04
const ROOM_FADE_TIME := 0.25
const EXIT_TO_HALL_IDLE_ALPHA := 0.92
const EXIT_TO_HALL_HOVER_ALPHA := 1.0
const EXIT_TO_HALL_BACKDROP_IDLE_ALPHA := 0.88
const EXIT_TO_HALL_BACKDROP_HOVER_ALPHA := 1.0
const EXIT_TO_HALL_BUTTON_RECT := Rect2(22.0, -198.0, 100.0, 176.0)
const EXIT_TO_HALL_BACKDROP_RECT := Rect2(10.0, -212.0, 126.0, 202.0)

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
var exit_to_hall_backdrop: Panel = null
var message_tween: Tween = null
var room_transition_tween: Tween = null
var blocked_room_shake_tween: Tween = null
var blocked_exit_shake_tween: Tween = null
var has_started_game := false
var has_won_game := false
var menu_transition_running := false
var cursor_shape_by_type := {
	"interact": Input.CURSOR_POINTING_HAND,
	"pickup": Input.CURSOR_CAN_DROP,
	"grab": Input.CURSOR_DRAG,
	"inspect": Input.CURSOR_HELP,
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
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_default.png"), Input.CURSOR_POINTING_HAND, Vector2(28, 10))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_inspect.png"), Input.CURSOR_HELP, Vector2(48, 48))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_grab.png"), Input.CURSOR_DRAG, Vector2(48, 48))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_pickup.png"), Input.CURSOR_CAN_DROP, Vector2(48, 48))
	Input.set_custom_mouse_cursor(load("res://art/cursors/cursor_blocked.png"), Input.CURSOR_FORBIDDEN, Vector2(48, 48))
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
	return cursor_shape_by_type[_get_active_cursor_type()]


func _get_active_cursor_type() -> String:
	if "pickup" in hovered_interactables.values():
		return "pickup"
	if "grab" in hovered_interactables.values():
		return "grab"
	if "blocked" in hovered_interactables.values():
		return "blocked"
	if "inspect" in hovered_interactables.values():
		return "inspect"
	return "interact"


func _get_hovered_ui_cursor_shape() -> int:
	var cursor_type := _get_hovered_ui_cursor_type()
	if cursor_type == "":
		return -1
	if cursor_type == "unavailable":
		return Input.CURSOR_ARROW
	return cursor_shape_by_type.get(cursor_type, Input.CURSOR_POINTING_HAND)


func _get_hovered_ui_cursor_type() -> String:
	var hovered_control := get_viewport().gui_get_hovered_control()
	while hovered_control != null:
		if hovered_control.has_method("is_available"):
			if hovered_control.is_available():
				var cursor_type_variant: Variant = hovered_control.get("cursor_type")
				if cursor_type_variant is String and cursor_shape_by_type.has(cursor_type_variant):
					return cursor_type_variant
				return "interact"
			return "unavailable"
		hovered_control = hovered_control.get_parent() as Control
	return ""


func _setup_room_navigation_ui() -> void:
	_setup_exit_to_hall_visuals()
	exit_to_hall_button.pressed.connect(_on_exit_to_hall_pressed)
	exit_to_hall_button.mouse_entered.connect(_on_exit_to_hall_hover_changed.bind(true))
	exit_to_hall_button.mouse_exited.connect(_on_exit_to_hall_hover_changed.bind(false))
	exit_to_hall_button.visible = false
	exit_to_hall_button.modulate.a = EXIT_TO_HALL_IDLE_ALPHA
	exit_to_hall_backdrop.visible = false
	exit_to_hall_backdrop.modulate.a = EXIT_TO_HALL_BACKDROP_IDLE_ALPHA
	door_hover_panel.visible = false
	door_hover_panel.modulate.a = 0.0
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0


func _setup_exit_to_hall_visuals() -> void:
	exit_to_hall_button.offset_left = EXIT_TO_HALL_BUTTON_RECT.position.x
	exit_to_hall_button.offset_top = EXIT_TO_HALL_BUTTON_RECT.position.y
	exit_to_hall_button.offset_right = EXIT_TO_HALL_BUTTON_RECT.position.x + EXIT_TO_HALL_BUTTON_RECT.size.x
	exit_to_hall_button.offset_bottom = EXIT_TO_HALL_BUTTON_RECT.position.y + EXIT_TO_HALL_BUTTON_RECT.size.y

	exit_to_hall_backdrop = Panel.new()
	exit_to_hall_backdrop.name = "ExitToHallBackdrop"
	exit_to_hall_backdrop.visible = false
	exit_to_hall_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exit_to_hall_backdrop.anchors_preset = Control.PRESET_BOTTOM_LEFT
	exit_to_hall_backdrop.anchor_top = 1.0
	exit_to_hall_backdrop.anchor_bottom = 1.0
	exit_to_hall_backdrop.offset_left = EXIT_TO_HALL_BACKDROP_RECT.position.x
	exit_to_hall_backdrop.offset_top = EXIT_TO_HALL_BACKDROP_RECT.position.y
	exit_to_hall_backdrop.offset_right = EXIT_TO_HALL_BACKDROP_RECT.position.x + EXIT_TO_HALL_BACKDROP_RECT.size.x
	exit_to_hall_backdrop.offset_bottom = EXIT_TO_HALL_BACKDROP_RECT.position.y + EXIT_TO_HALL_BACKDROP_RECT.size.y

	var backdrop_style := StyleBoxFlat.new()
	backdrop_style.bg_color = Color(0.045, 0.034, 0.026, 0.66)
	backdrop_style.border_color = Color(0.9, 0.58, 0.2, 0.9)
	backdrop_style.border_width_left = 2
	backdrop_style.border_width_top = 2
	backdrop_style.border_width_right = 2
	backdrop_style.border_width_bottom = 2
	backdrop_style.corner_radius_top_left = 7
	backdrop_style.corner_radius_top_right = 7
	backdrop_style.corner_radius_bottom_right = 7
	backdrop_style.corner_radius_bottom_left = 7
	backdrop_style.shadow_color = Color(0, 0, 0, 0.62)
	backdrop_style.shadow_size = 14
	exit_to_hall_backdrop.add_theme_stylebox_override("panel", backdrop_style)

	var ui_layer := exit_to_hall_button.get_parent()
	ui_layer.add_child(exit_to_hall_backdrop)
	ui_layer.move_child(exit_to_hall_backdrop, exit_to_hall_button.get_index())


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
	if has_won_game:
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
	if exit_to_hall_backdrop != null:
		exit_to_hall_backdrop.visible = is_visible
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
			AudioManager.play_sfx("blocked")
			_play_exit_to_hall_blocked_shake()
			return
		if _has_selected_inventory_item() and _get_selected_inventory_item_id() != "item_small_victorian_key":
			_show_wrong_selected_item_feedback()
			_play_exit_to_hall_blocked_shake()
			return

		Inventory.remove_item("item_small_victorian_key")
		GameState.set_flag("bedroom_door_unlocked", true)
		show_message("A chave gira na fechadura.")

	AudioManager.play_sfx("door")
	go_to_room("hall")


func _on_exit_to_hall_hover_changed(is_hovered: bool) -> void:
	exit_to_hall_button.modulate.a = EXIT_TO_HALL_HOVER_ALPHA if is_hovered else EXIT_TO_HALL_IDLE_ALPHA
	if exit_to_hall_backdrop != null:
		exit_to_hall_backdrop.modulate.a = EXIT_TO_HALL_BACKDROP_HOVER_ALPHA if is_hovered else EXIT_TO_HALL_BACKDROP_IDLE_ALPHA


func _update_exit_to_hall_tooltip() -> void:
	if current_room_id == "bedroom" and not GameState.get_flag("bedroom_door_unlocked"):
		exit_to_hall_button.tooltip_text = "Porta trancada"
	else:
		exit_to_hall_button.tooltip_text = "Voltar ao corredor"


func _on_room_interaction_requested(interaction_id: String) -> void:
	clear_message()

	if _has_selected_inventory_item() and not _can_selected_item_handle_room_interaction(interaction_id):
		_show_wrong_selected_item_feedback()
		return

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
			show_message(FEEDBACK_DOES_NOT_OPEN_HERE)
			AudioManager.play_sfx("blocked")
			_play_current_room_blocked_shake()
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
				show_message(FEEDBACK_EMPTY_WARDROBE)
				zoom_manager.open_zoom("wardrobe_open_without_note")
			else:
				zoom_manager.open_zoom("wardrobe_open_with_note")
		"chest_drawer":
			show_message(FEEDBACK_EMPTY_DRAWER)
			zoom_manager.open_zoom("chest_drawer_open")
		"nightstand_top":
			show_message(FEEDBACK_EMPTY_DRAWER)
			zoom_manager.open_zoom("nightstand_top_drawer_open")
		"nightstand_bottom":
			show_message(FEEDBACK_EMPTY_DRAWER)
			zoom_manager.open_zoom("nightstand_bottom_drawer_open")
		"dining_room_clock":
			_open_dining_room_clock_zoom()
		"dining_room_floral_reliquary":
			zoom_manager.open_zoom("dining_room_floral_reliquary_far")
		"library_bookshelf":
			_open_library_bookshelf_zoom()
		_:
			show_message(FEEDBACK_NO_CHANGE)
			AudioManager.play_sfx("invalid")


func _on_zoom_interaction_requested(interaction_id: String) -> void:
	if _has_selected_inventory_item() and not _can_selected_item_handle_zoom_interaction(interaction_id):
		_show_wrong_selected_item_feedback()
		return

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
		"open_floral_reliquary_close":
			zoom_manager.open_zoom("dining_room_floral_reliquary_close", true)
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
			_refresh_current_room_state_visuals()
			_open_dining_room_clock_zoom(false)
		"pickup_eye_medallion":
			if Inventory.add_item("item_eye_medallion"):
				GameState.set_flag("dining_room_eye_medallion_collected", true)
				show_message("Você pegou o medalhão do olho fechado.")
				_refresh_current_room_state_visuals()
				if _check_victory_condition():
					return
			_open_dining_room_clock_zoom(false)
		"pickup_botany_book":
			if Inventory.add_item("item_botany_book"):
				GameState.set_flag("library_botany_book_collected", true)
				show_message("Você pegou um livro de botânica.")
			_open_library_bookshelf_zoom(false)
		"floral_reliquary_solved":
			show_message("O relicário se destravou.")
			if _check_victory_condition():
				return
		_:
			show_message(FEEDBACK_NO_CHANGE)
			AudioManager.play_sfx("invalid")


func _on_inventory_item_selected(item_id: String) -> void:
	var item_data := ItemDatabase.get_item(item_id)
	var item_type: String = item_data.get("type", "")
	if item_type == "readable" or item_type == "inspectable":
		if item_id == "item_jacket_note":
			GameState.set_flag("bedroom_jacket_note_read", true)
		if item_id == "item_box_letter":
			GameState.set_flag("bedroom_box_letter_read", true)
		letter_popup.open_item(item_id)
		_clear_selected_inventory_item()
	else:
		show_message(item_data.get("description", item_data.get("name", item_id)))


func _on_jewelry_puzzle_solved() -> void:
	await get_tree().create_timer(0.4).timeout
	_close_puzzle()
	_open_jewelry_box_zoom()
	show_message("A caixa se abriu.")


func _close_puzzle() -> void:
	puzzle.visible = false


func _open_jewelry_box_zoom(show_empty_feedback: bool = true) -> void:
	if not GameState.get_flag("bedroom_jewelry_box_solved"):
		zoom_manager.open_zoom("jewelry_box_closed")
		return

	var has_key := GameState.get_flag("bedroom_small_key_collected")
	var has_letter := GameState.get_flag("bedroom_box_letter_collected")

	if has_key and has_letter:
		if show_empty_feedback:
			show_message(FEEDBACK_EMPTY_JEWELRY_BOX)
		zoom_manager.open_zoom("jewelry_box_empty")
	elif has_key:
		zoom_manager.open_zoom("jewelry_box_only_letter")
	elif has_letter:
		zoom_manager.open_zoom("jewelry_box_only_key")
	else:
		zoom_manager.open_zoom("jewelry_box_open")


func _refresh_jewelry_box_after_pickup() -> void:
	_open_jewelry_box_zoom(false)


func _refresh_current_room_state_visuals() -> void:
	for child in current_room_container.get_children():
		if child.has_method("refresh_state_visuals"):
			child.refresh_state_visuals()


func _open_dining_room_clock_zoom(show_state_feedback: bool = true) -> void:
	if not GameState.get_flag("dining_room_clock_pendulums_solved"):
		zoom_manager.open_zoom("dining_room_clock")
		return

	if GameState.get_flag("dining_room_eye_medallion_collected"):
		if show_state_feedback:
			show_message(FEEDBACK_EMPTY_CLOCK_COMPARTMENT)
		zoom_manager.open_zoom("dining_room_clock_open_without_eye_medallion")
	else:
		if show_state_feedback:
			show_message(FEEDBACK_CLOCK_ALIGNED)
		zoom_manager.open_zoom("dining_room_clock_open_with_eye_medallion")


func _open_library_bookshelf_zoom(show_empty_feedback: bool = true) -> void:
	if GameState.get_flag("library_botany_book_collected"):
		if show_empty_feedback:
			show_message(FEEDBACK_EMPTY_LIBRARY_SHELF)
		zoom_manager.open_zoom("library_bookshelf_without_botany_book")
	else:
		zoom_manager.open_zoom("library_bookshelf_with_botany_book")


func _is_jewelry_box_empty() -> bool:
	return (
		GameState.get_flag("bedroom_jewelry_box_solved")
		and GameState.get_flag("bedroom_small_key_collected")
		and GameState.get_flag("bedroom_box_letter_collected")
	)


func _has_selected_inventory_item() -> bool:
	return _get_selected_inventory_item_id() != ""


func _get_selected_inventory_item_id() -> String:
	if inventory_ui == null:
		return ""

	var selected_slot_variant: Variant = inventory_ui.get("selected_slot")
	if not selected_slot_variant is int:
		return ""

	var selected_slot: int = selected_slot_variant
	if selected_slot < 0 or selected_slot >= Inventory.items.size():
		return ""

	return Inventory.items[selected_slot]


func _can_selected_item_handle_room_interaction(interaction_id: String) -> bool:
	match interaction_id:
		"go_center_locked":
			return true
		"go_bedroom", "go_office", "go_library", "go_dining_room":
			return false
		_:
			return false


func _can_selected_item_handle_zoom_interaction(interaction_id: String) -> bool:
	match interaction_id:
		_:
			return false


func _show_wrong_selected_item_feedback() -> void:
	show_message(FEEDBACK_WRONG_ITEM)
	AudioManager.play_sfx("wrong_item")
	_clear_selected_inventory_item()


func _play_current_room_blocked_shake() -> void:
	var target := _get_current_room_visual_root()
	if target == null:
		return

	if blocked_room_shake_tween != null:
		blocked_room_shake_tween.kill()
		blocked_room_shake_tween = null

	var base_position := target.position
	blocked_room_shake_tween = create_tween()
	_add_node2d_shake_track(blocked_room_shake_tween, target, base_position)
	blocked_room_shake_tween.tween_callback(func() -> void:
		target.position = base_position
		blocked_room_shake_tween = null
	)


func _get_current_room_visual_root() -> Node2D:
	if current_room_container.get_child_count() == 0:
		return null

	var room := current_room_container.get_child(0)
	var content := room.get_node_or_null("Content") as Node2D
	if content != null:
		return content
	return room as Node2D


func _play_exit_to_hall_blocked_shake() -> void:
	if blocked_exit_shake_tween != null:
		blocked_exit_shake_tween.kill()
		blocked_exit_shake_tween = null

	var base_button_position := exit_to_hall_button.position

	blocked_exit_shake_tween = create_tween()
	_add_control_shake_track(blocked_exit_shake_tween, exit_to_hall_button, base_button_position)
	blocked_exit_shake_tween.tween_callback(func() -> void:
		exit_to_hall_button.position = base_button_position
		blocked_exit_shake_tween = null
	)


func _add_node2d_shake_track(tween: Tween, target: Node2D, base_position: Vector2) -> void:
	tween.tween_property(target, "position", base_position + Vector2(BLOCKED_SHAKE_DISTANCE, 0.0), BLOCKED_SHAKE_STEP_TIME)
	tween.tween_property(target, "position", base_position + Vector2(-BLOCKED_SHAKE_DISTANCE, 0.0), BLOCKED_SHAKE_STEP_TIME * 1.5)
	tween.tween_property(target, "position", base_position + Vector2(BLOCKED_SHAKE_DISTANCE * 0.5, 0.0), BLOCKED_SHAKE_STEP_TIME)
	tween.tween_property(target, "position", base_position, BLOCKED_SHAKE_STEP_TIME)


func _add_control_shake_track(tween: Tween, target: Control, base_position: Vector2) -> void:
	tween.tween_property(target, "position", base_position + Vector2(BLOCKED_SHAKE_DISTANCE, 0.0), BLOCKED_SHAKE_STEP_TIME)
	tween.tween_property(target, "position", base_position + Vector2(-BLOCKED_SHAKE_DISTANCE, 0.0), BLOCKED_SHAKE_STEP_TIME * 1.5)
	tween.tween_property(target, "position", base_position + Vector2(BLOCKED_SHAKE_DISTANCE * 0.5, 0.0), BLOCKED_SHAKE_STEP_TIME)
	tween.tween_property(target, "position", base_position, BLOCKED_SHAKE_STEP_TIME)


func _clear_selected_inventory_item() -> void:
	if inventory_ui == null:
		return

	var selected_slot_variant: Variant = inventory_ui.get("selected_slot")
	if not selected_slot_variant is int:
		return

	inventory_ui.set("selected_slot", -1)
	if inventory_ui.has_method("refresh"):
		inventory_ui.refresh()


func _check_victory_condition() -> bool:
	if has_won_game:
		return true

	if (
		GameState.get_flag("bedroom_small_key_collected")
		and GameState.get_flag("dining_room_eye_medallion_collected")
		and GameState.get_flag("dining_room_floral_reliquary_solved")
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
