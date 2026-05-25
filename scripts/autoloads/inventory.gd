extends Node

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal inventory_changed

var items: Array[String] = []


func add_item(item_id: String) -> bool:
	if item_id in items:
		return false

	items.append(item_id)
	item_added.emit(item_id)
	inventory_changed.emit()
	AudioManager.play_sfx("item_pickup")
	return true


func remove_item(item_id: String) -> void:
	if item_id not in items:
		return

	items.erase(item_id)
	item_removed.emit(item_id)
	inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return item_id in items


func clear() -> void:
	items.clear()
	inventory_changed.emit()
