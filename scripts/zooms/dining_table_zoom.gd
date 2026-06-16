extends "res://scripts/core/scaled_zoom_view.gd"

const SCRIBBLED_NAPKIN_RECT := Rect2(525.0, 500.0, 145.0, 140.0)

@onready var scribbled_napkin_hotspot: Button = $ScribbledNapkinHotspot


func _update_scaled_layout() -> void:
	if scribbled_napkin_hotspot != null:
		_set_control_art_rect(scribbled_napkin_hotspot, SCRIBBLED_NAPKIN_RECT)
