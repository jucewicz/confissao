extends "res://scripts/core/zoom_view.gd"

const ART_SIZE := Vector2(1672.0, 941.0)


func _ready() -> void:
	super._ready()
	_update_scaled_layout.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_scaled_layout()


func _update_scaled_layout() -> void:
	pass


func _set_control_art_rect(control: Control, art_rect: Rect2) -> void:
	control.position = _art_to_view_position(art_rect.position)
	control.size = _art_size_to_view_size(art_rect.size)


func _get_view_scale() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(size.x / ART_SIZE.x, size.y / ART_SIZE.y)


func _art_to_view_position(position: Vector2) -> Vector2:
	return position * _get_view_scale()


func _art_size_to_view_size(rect_size: Vector2) -> Vector2:
	return rect_size * _get_view_scale()
