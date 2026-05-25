class_name UIInteractable
extends Button

signal interacted(interaction_id: String)

@export var interaction_id: String = ""
@export var enabled_flag: String = ""
@export var disabled_flag: String = ""
@export_enum("interact", "pickup", "grab", "inspect", "blocked") var cursor_type: String = "interact"


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


func _get_control_cursor_shape() -> Control.CursorShape:
	match cursor_type:
		"pickup":
			return Control.CURSOR_CAN_DROP
		"grab":
			return Control.CURSOR_DRAG
		"blocked":
			return Control.CURSOR_FORBIDDEN
		_:
			return Control.CURSOR_POINTING_HAND
