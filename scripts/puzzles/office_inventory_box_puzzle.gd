extends "res://scripts/core/scaled_zoom_view.gd"

const CORRECT_X := "6"
const CORRECT_Y := "12"
const CORRECT_Z := "22"
const STATE_KEY := "office_inventory_box_state"
const REPEAT_INITIAL_DELAY := 0.35
const REPEAT_INTERVAL := 0.08
const X_DISPLAY_RECT := Rect2(546.0, 506.0, 120.0, 88.0)
const Y_DISPLAY_RECT := Rect2(774.0, 506.0, 120.0, 88.0)
const Z_DISPLAY_RECT := Rect2(998.0, 506.0, 120.0, 88.0)
const X_HITBOX_RECT := Rect2(520.0, 482.0, 170.0, 135.0)
const Y_HITBOX_RECT := Rect2(748.0, 482.0, 170.0, 135.0)
const Z_HITBOX_RECT := Rect2(972.0, 482.0, 170.0, 135.0)
const SUBMIT_BUTTON_RECT := Rect2(706.0, 745.0, 260.0, 62.0)
const MESSAGE_LABEL_RECT := Rect2(595.0, 812.0, 520.0, 46.0)

@onready var x_label: Label = $XValueLabel
@onready var y_label: Label = $YValueLabel
@onready var z_label: Label = $ZValueLabel
@onready var x_slot: Button = $XSlot
@onready var y_slot: Button = $YSlot
@onready var z_slot: Button = $ZSlot
@onready var submit_button: Button = $SubmitButton
@onready var message_label: Label = $MessageLabel

var slot_values := {
	"x": 0,
	"y": 0,
	"z": 0,
}
var is_shaking := false
var repeat_timer: Timer
var repeat_slot_id := ""
var repeat_direction := 0
var repeat_started := false


func _ready() -> void:
	super._ready()
	_load_state()
	_create_repeat_timer()
	for slot in [x_slot, y_slot, z_slot]:
		slot.flat = true
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	x_slot.gui_input.connect(_on_slot_gui_input.bind("x"))
	y_slot.gui_input.connect(_on_slot_gui_input.bind("y"))
	z_slot.gui_input.connect(_on_slot_gui_input.bind("z"))
	submit_button.pressed.connect(_check_solution)
	_update_slot_labels()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_stop_repeat()


func _update_scaled_layout() -> void:
	if x_label == null:
		return
	_set_control_art_rect(x_label, X_DISPLAY_RECT)
	_set_control_art_rect(y_label, Y_DISPLAY_RECT)
	_set_control_art_rect(z_label, Z_DISPLAY_RECT)
	_set_control_art_rect(x_slot, X_HITBOX_RECT)
	_set_control_art_rect(y_slot, Y_HITBOX_RECT)
	_set_control_art_rect(z_slot, Z_HITBOX_RECT)
	_set_control_art_rect(submit_button, SUBMIT_BUTTON_RECT)
	_set_control_art_rect(message_label, MESSAGE_LABEL_RECT)


func _on_slot_gui_input(event: InputEvent, slot_id: String) -> void:
	if is_shaking:
		return

	if event is InputEventMouseButton:
		if not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
				_stop_repeat()
				accept_event()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			_change_slot_value(slot_id, 1)
			_start_repeat(slot_id, 1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_change_slot_value(slot_id, -1)
			_start_repeat(slot_id, -1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_slot_value(slot_id, 1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_slot_value(slot_id, -1)
			accept_event()


func _load_state() -> void:
	var saved_state: Variant = GameState.get_value(STATE_KEY, {})
	if not (saved_state is Dictionary):
		return

	for slot_id in slot_values:
		if saved_state.has(slot_id):
			slot_values[slot_id] = clampi(int(saved_state[slot_id]), 0, 99)


func _save_state() -> void:
	GameState.set_value(STATE_KEY, slot_values.duplicate())


func _create_repeat_timer() -> void:
	repeat_timer = Timer.new()
	repeat_timer.one_shot = false
	repeat_timer.timeout.connect(_on_repeat_timer_timeout)
	add_child(repeat_timer)


func _start_repeat(slot_id: String, direction: int) -> void:
	repeat_slot_id = slot_id
	repeat_direction = direction
	repeat_started = false
	repeat_timer.start(REPEAT_INITIAL_DELAY)


func _stop_repeat() -> void:
	repeat_slot_id = ""
	repeat_direction = 0
	repeat_started = false
	if repeat_timer != null:
		repeat_timer.stop()


func _on_repeat_timer_timeout() -> void:
	if repeat_slot_id == "" or repeat_direction == 0 or is_shaking:
		_stop_repeat()
		return

	_change_slot_value(repeat_slot_id, repeat_direction)
	if not repeat_started:
		repeat_started = true
		repeat_timer.start(REPEAT_INTERVAL)


func _change_slot_value(slot_id: String, direction: int) -> void:
	var next_value := int(slot_values[slot_id]) + direction
	if next_value < 0:
		next_value = 99
	elif next_value > 99:
		next_value = 0

	slot_values[slot_id] = next_value
	message_label.text = ""
	AudioManager.play_sfx("click")
	_save_state()
	_update_slot_labels()


func _update_slot_labels() -> void:
	x_label.text = str(slot_values["x"])
	y_label.text = str(slot_values["y"])
	z_label.text = str(slot_values["z"])


func _check_solution() -> void:
	if is_shaking:
		return

	if str(slot_values["x"]) == CORRECT_X and str(slot_values["y"]) == CORRECT_Y and str(slot_values["z"]) == CORRECT_Z:
		_stop_repeat()
		GameState.set_flag("office_box_opened", true)
		AudioManager.play_sfx("puzzle_correct")
		interaction_requested.emit("office_inventory_box_solved")
		return

	message_label.text = "O mecanismo resiste."
	AudioManager.play_sfx("puzzle_wrong")
	_play_error_shake()


func _play_error_shake() -> void:
	_stop_repeat()
	is_shaking = true
	var base_position := position

	var tween := create_tween()
	for offset in [12.0, -12.0, 8.0, -5.0, 0.0]:
		tween.tween_property(self, "position", base_position + Vector2(offset, 0.0), 0.04)
	await tween.finished
	position = base_position
	is_shaking = false
