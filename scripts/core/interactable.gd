class_name Interactable
extends Area2D

signal interacted(interaction_id: String)

@export var interaction_id: String = ""
@export var enabled_flag: String = ""
@export var disabled_flag: String = ""
@export_enum("interact", "pickup", "grab", "inspect", "blocked") var cursor_type: String = "interact"


func _ready() -> void:
	add_to_group("interactables")
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	get_tree().call_group("cursor_listeners", "_on_interactable_hover_changed", self, true, cursor_type)


func _on_mouse_exited() -> void:
	get_tree().call_group("cursor_listeners", "_on_interactable_hover_changed", self, false, cursor_type)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_available():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			AudioManager.play_sfx("click")
			interacted.emit(interaction_id)


func is_available() -> bool:
	if enabled_flag != "" and not GameState.get_flag(enabled_flag):
		return false
	if disabled_flag != "" and GameState.get_flag(disabled_flag):
		return false
	return true
