extends "res://scripts/core/scaled_zoom_view.gd"

const SILVER_KEY_RECT := Rect2(595.0, 620.0, 315.0, 130.0)

@onready var silver_key_hotspot: Button = $SilverKeyHotspot


func _update_scaled_layout() -> void:
	if silver_key_hotspot != null:
		_set_control_art_rect(silver_key_hotspot, SILVER_KEY_RECT)
