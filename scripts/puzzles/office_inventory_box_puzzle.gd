extends "res://scripts/core/scaled_zoom_view.gd"

const CORRECT_X := "6"
const CORRECT_Y := "12"
const CORRECT_Z := "22"
const X_INPUT_RECT := Rect2(540.0, 515.0, 160.0, 92.0)
const Y_INPUT_RECT := Rect2(790.0, 515.0, 160.0, 92.0)
const Z_INPUT_RECT := Rect2(1040.0, 515.0, 160.0, 92.0)
const SUBMIT_BUTTON_RECT := Rect2(706.0, 745.0, 260.0, 62.0)
const MESSAGE_LABEL_RECT := Rect2(595.0, 812.0, 520.0, 46.0)

@onready var x_input: LineEdit = $XInput
@onready var y_input: LineEdit = $YInput
@onready var z_input: LineEdit = $ZInput
@onready var submit_button: Button = $SubmitButton
@onready var message_label: Label = $MessageLabel

var is_shaking := false


func _ready() -> void:
	super._ready()
	for input in [x_input, y_input, z_input]:
		input.text_changed.connect(_on_input_text_changed.bind(input))
		input.text_submitted.connect(func(_text: String) -> void:
			_check_solution()
		)
	submit_button.pressed.connect(_check_solution)
	x_input.grab_focus.call_deferred()


func _update_scaled_layout() -> void:
	if x_input == null:
		return
	_set_control_art_rect(x_input, X_INPUT_RECT)
	_set_control_art_rect(y_input, Y_INPUT_RECT)
	_set_control_art_rect(z_input, Z_INPUT_RECT)
	_set_control_art_rect(submit_button, SUBMIT_BUTTON_RECT)
	_set_control_art_rect(message_label, MESSAGE_LABEL_RECT)


func _on_input_text_changed(new_text: String, input: LineEdit) -> void:
	var digits_only := ""
	for character in new_text:
		if character.is_valid_int():
			digits_only += character
	input.text = digits_only.substr(0, 2)
	input.caret_column = input.text.length()


func _check_solution() -> void:
	if is_shaking:
		return

	if x_input.text == CORRECT_X and y_input.text == CORRECT_Y and z_input.text == CORRECT_Z:
		GameState.set_flag("office_box_opened", true)
		AudioManager.play_sfx("puzzle_correct")
		interaction_requested.emit("office_inventory_box_solved")
		return

	message_label.text = "O mecanismo resiste."
	AudioManager.play_sfx("puzzle_wrong")
	_play_error_shake()


func _play_error_shake() -> void:
	is_shaking = true
	var base_position := position

	var tween := create_tween()
	for offset in [12.0, -12.0, 8.0, -5.0, 0.0]:
		tween.tween_property(self, "position", base_position + Vector2(offset, 0.0), 0.04)
	await tween.finished
	position = base_position
	is_shaking = false
