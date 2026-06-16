extends "res://scripts/core/scaled_zoom_view.gd"

const FLAME_MEDALLION_RECT := Rect2(660.0, 275.0, 355.0, 205.0)

@onready var flame_medallion_hotspot: Button = $FlameMedallionHotspot


func _update_scaled_layout() -> void:
	if flame_medallion_hotspot != null:
		_set_control_art_rect(flame_medallion_hotspot, FLAME_MEDALLION_RECT)
