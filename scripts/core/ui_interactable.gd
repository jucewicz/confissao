class_name UIInteractable
extends Button

signal interacted(interaction_id: String)

@export var interaction_id: String = ""
@export var enabled_flag: String = ""
@export var disabled_flag: String = ""
@export_enum("interact", "pickup", "grab", "inspect", "blocked") var cursor_type: String = "interact"
@export var accepted_drop_item_ids: PackedStringArray = []


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = _get_control_cursor_shape()
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_pressed() -> void:
	if not is_available():
		return

	AudioManager.play_sfx("click")
	interacted.emit(interaction_id)


func _on_mouse_entered() -> void:
	if is_available():
		get_tree().call_group("cursor_listeners", "_on_interactable_hover_changed", self, true, cursor_type)


func _on_mouse_exited() -> void:
	get_tree().call_group("cursor_listeners", "_on_interactable_hover_changed", self, false, cursor_type)


func is_available() -> bool:
	if enabled_flag != "" and not GameState.get_flag(enabled_flag):
		return false
	if disabled_flag != "" and GameState.get_flag(disabled_flag):
		return false
	return true


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return _get_dropped_inventory_item_id(data) in accepted_drop_item_ids and is_available()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var dropped_item_id := _get_dropped_inventory_item_id(data)
	if dropped_item_id == "" or dropped_item_id not in accepted_drop_item_ids or not is_available():
		return

	GameState.set_value("_dropped_inventory_item_id", dropped_item_id)
	AudioManager.play_sfx("click")
	interacted.emit(interaction_id)


func _get_dropped_inventory_item_id(data: Variant) -> String:
	if not (data is Dictionary):
		return ""
	if data.get("type", "") != "inventory_item":
		return ""

	var item_id_variant: Variant = data.get("item_id", "")
	if not (item_id_variant is String):
		return ""
	return item_id_variant


func _get_control_cursor_shape() -> Control.CursorShape:
	match cursor_type:
		"pickup":
			return Control.CURSOR_CAN_DROP
		"grab":
			return Control.CURSOR_DRAG
		"inspect":
			return Control.CURSOR_HELP
		"blocked":
			return Control.CURSOR_FORBIDDEN
		_:
			return Control.CURSOR_POINTING_HAND
