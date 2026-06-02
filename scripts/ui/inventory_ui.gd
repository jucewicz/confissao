extends Control

signal item_selected(item_id: String)

const ItemDatabase := preload("res://scripts/data/item_database.gd")
const SLOT_COUNT := 8
const SLOT_SIZE := Vector2(88, 88)
const ICON_MARGIN := 14

@onready var slot_row: HBoxContainer = $SlotRow

var selected_slot := -1
var slot_empty_texture: Texture2D
var slot_hover_texture: Texture2D
var slot_selected_texture: Texture2D
var previous_items: Array[String] = []
var inventory_snapshot_ready := false


func _ready() -> void:
	slot_empty_texture = load("res://art/ui/inventory_slot_empty.png")
	slot_hover_texture = load("res://art/ui/inventory_slot_hover.png")
	slot_selected_texture = load("res://art/ui/inventory_slot_selected.png")
	Inventory.inventory_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var current_items: Array[String] = []
	current_items.assign(Inventory.items)
	var new_item_slots := _get_new_item_slots(current_items)

	if selected_slot >= Inventory.items.size():
		selected_slot = -1

	for child in slot_row.get_children():
		child.queue_free()

	for slot_index in range(SLOT_COUNT):
		var button := _create_slot_button(slot_index)
		slot_row.add_child(button)
		if slot_index in new_item_slots:
			_pulse_slot.call_deferred(button)

	previous_items = current_items
	inventory_snapshot_ready = true


func _create_slot_button(slot_index: int) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = SLOT_SIZE
	button.pivot_offset = SLOT_SIZE * 0.5
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = slot_selected_texture if slot_index == selected_slot else slot_empty_texture
	button.texture_hover = slot_selected_texture if slot_index == selected_slot else slot_hover_texture
	button.texture_pressed = slot_selected_texture
	button.texture_focused = slot_selected_texture

	if slot_index < Inventory.items.size():
		var item_id: String = Inventory.items[slot_index]
		var item_data := ItemDatabase.get_item(item_id)
		button.tooltip_text = item_data.get("name", item_id)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_slot_pressed.bind(slot_index, item_id))
		button.add_child(_create_item_icon(item_id))

	return button


func _get_new_item_slots(current_items: Array[String]) -> Array[int]:
	var new_item_slots: Array[int] = []
	if not inventory_snapshot_ready or current_items.size() <= previous_items.size():
		return new_item_slots

	var previous_counts := {}
	for item_id in previous_items:
		previous_counts[item_id] = previous_counts.get(item_id, 0) + 1

	for slot_index in range(min(current_items.size(), SLOT_COUNT)):
		var item_id := current_items[slot_index]
		var remaining_count: int = previous_counts.get(item_id, 0)
		if remaining_count > 0:
			previous_counts[item_id] = remaining_count - 1
		else:
			new_item_slots.append(slot_index)

	return new_item_slots


func _pulse_slot(button: TextureButton) -> void:
	if not is_instance_valid(button):
		return

	button.scale = Vector2.ONE
	button.modulate = Color.WHITE

	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.1)
	tween.parallel().tween_property(button, "modulate", Color(1.35, 1.35, 1.15, 1.0), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.16)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.16)


func _create_item_icon(item_id: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = ItemDatabase.get_item_texture(item_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.offset_left = ICON_MARGIN
	icon.offset_top = ICON_MARGIN
	icon.offset_right = -ICON_MARGIN
	icon.offset_bottom = -ICON_MARGIN
	return icon


func _on_slot_pressed(slot_index: int, item_id: String) -> void:
	selected_slot = slot_index
	refresh()
	item_selected.emit(item_id)
