extends Control

const ItemDatabase := preload("res://scripts/data/item_database.gd")

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var item_image: TextureRect = $Panel/MarginContainer/Layout/ImageFrame/ItemImage
@onready var title_label: Label = $Panel/MarginContainer/Layout/TextColumn/TitleLabel
@onready var body_label: RichTextLabel = $Panel/MarginContainer/Layout/TextColumn/BodyLabel
@onready var read_button: Button = $Panel/MarginContainer/Layout/TextColumn/ButtonRow/ReadButton
@onready var close_button: Button = $Panel/MarginContainer/Layout/TextColumn/ButtonRow/CloseButton
@onready var page_overlay: Control = $PageOverlay
@onready var page_image: TextureRect = $PageOverlay/PageImage
@onready var back_to_item_button: Button = $PageOverlay/PageButtonRow/BackToItemButton
@onready var close_page_button: Button = $PageOverlay/PageButtonRow/ClosePageButton

var current_read_image_path := ""


func _ready() -> void:
	visible = false
	page_overlay.visible = false
	read_button.pressed.connect(_open_read_image)
	close_button.pressed.connect(close)
	back_to_item_button.pressed.connect(_close_read_image)
	close_page_button.pressed.connect(close)


func open_item(item_id: String) -> void:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return

	title_label.text = item_data.get("name", item_id)
	var body_text: String = item_data.get("text", "")
	if body_text.is_empty():
		body_text = item_data.get("description", "")
	body_label.text = body_text
	item_image.texture = ItemDatabase.get_item_texture(item_id)
	current_read_image_path = item_data.get("read_image", "")
	read_button.visible = current_read_image_path != ""
	page_overlay.visible = false
	visible = true
	AudioManager.play_sfx("paper_open")


func close() -> void:
	page_overlay.visible = false
	visible = false


func _open_read_image() -> void:
	if current_read_image_path == "":
		return

	page_image.texture = load(current_read_image_path)
	page_overlay.visible = true
	AudioManager.play_sfx("paper_open")


func _close_read_image() -> void:
	page_overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if page_overlay.visible:
			_close_read_image()
		else:
			close()
