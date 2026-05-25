extends Node

signal flag_changed(flag_name: String, value: bool)

var flags: Dictionary = {}


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)


func reset() -> void:
	flags.clear()
