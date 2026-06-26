extends "res://scripts/core/scaled_zoom_view.gd"

const SPIRAL_MEDALLION_RECT := Rect2(930.0, 300.0, 205.0, 205.0)

@onready var spiral_medallion_hotspot: Button = $SpiralMedallionHotspot


func _update_scaled_layout() -> void:
	if spiral_medallion_hotspot != null:
		_set_control_art_rect(spiral_medallion_hotspot, SPIRAL_MEDALLION_RECT)
