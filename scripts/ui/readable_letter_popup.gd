extends Control

const ItemDatabase := preload("res://scripts/data/item_database.gd")

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var item_image: TextureRect = $Panel/MarginContainer/Layout/ItemImage
@onready var title_label: Label = $Panel/MarginContainer/Layout/TextColumn/TitleLabel
@onready var body_label: RichTextLabel = $Panel/MarginContainer/Layout/TextColumn/BodyLabel
@onready var close_button: Button = $Panel/MarginContainer/Layout/TextColumn/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)


func open_item(item_id: String) -> void:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return

	title_label.text = item_data.get("name", item_id)
	body_label.text = item_data.get("text", item_data.get("description", ""))
	item_image.texture = ItemDatabase.get_item_texture(item_id)
	visible = true
	AudioManager.play_sfx("paper_open")


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
