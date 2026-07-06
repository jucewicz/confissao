extends TextureButton

const ItemDatabase := preload("res://scripts/data/item_database.gd")

var item_id := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == "":
		return null

	var preview := TextureRect.new()
	preview.texture = ItemDatabase.get_item_texture(item_id)
	preview.custom_minimum_size = Vector2(72.0, 72.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"type": "inventory_item",
		"item_id": item_id,
	}
