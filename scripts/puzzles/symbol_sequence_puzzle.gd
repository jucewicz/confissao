extends Control

signal puzzle_solved
signal puzzle_closed

@onready var preview_label: Label = $Panel/MarginContainer/Layout/PreviewLabel
@onready var message_label: Label = $Panel/MarginContainer/Layout/MessageLabel
@onready var close_button: Button = $Panel/MarginContainer/Layout/TopRow/CloseButton
@onready var clear_button: Button = $Panel/MarginContainer/Layout/BottomRow/ClearButton

const CORRECT_SEQUENCE: Array[String] = ["moon", "flower", "crown", "key"]
const SYMBOL_LABELS := {
	"moon": "Lua",
	"flower": "Flor",
	"crown": "Coroa",
	"key": "Chave",
	"bird": "Pássaro",
	"star": "Estrela",
}

var current_sequence: Array[String] = []


func _ready() -> void:
	close_button.pressed.connect(func() -> void:
		puzzle_closed.emit()
	)
	clear_button.pressed.connect(clear_sequence)

	for symbol_id in SYMBOL_LABELS.keys():
		var button := get_node("Panel/MarginContainer/Layout/SymbolGrid/%sButton" % symbol_id.capitalize())
		button.mouse_default_cursor_shape = Control.CURSOR_DRAG
		button.pressed.connect(press_symbol.bind(symbol_id))

	_update_preview()


func press_symbol(symbol_id: String) -> void:
	if current_sequence.size() >= CORRECT_SEQUENCE.size():
		return

	current_sequence.append(symbol_id)
	AudioManager.play_sfx("symbol_press")
	_update_preview()

	if current_sequence.size() == CORRECT_SEQUENCE.size():
		_check_solution()


func clear_sequence() -> void:
	current_sequence.clear()
	message_label.text = ""
	_update_preview()


func _check_solution() -> void:
	if current_sequence == CORRECT_SEQUENCE:
		GameState.set_flag("bedroom_jewelry_box_solved", true)
		message_label.text = "Um clique seco rompe o silêncio. A caixa se abre."
		AudioManager.play_sfx("puzzle_correct")
		puzzle_solved.emit()
	else:
		message_label.text = "O mecanismo resiste."
		AudioManager.play_sfx("puzzle_wrong")
		current_sequence.clear()
		_update_preview()


func _update_preview() -> void:
	var labels: Array[String] = []
	for symbol_id in current_sequence:
		labels.append(SYMBOL_LABELS.get(symbol_id, symbol_id))

	while labels.size() < CORRECT_SEQUENCE.size():
		labels.append("_")

	preview_label.text = " -> ".join(labels)
