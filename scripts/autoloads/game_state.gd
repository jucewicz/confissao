extends Node

signal flag_changed(flag_name: String, value: bool)
signal value_changed(value_name: String, value: Variant)

var flags: Dictionary = {}
var values: Dictionary = {}


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)


func set_value(value_name: String, value: Variant) -> void:
	values[value_name] = value
	value_changed.emit(value_name, value)


func get_value(value_name: String, default_value: Variant = null) -> Variant:
	return values.get(value_name, default_value)


func reset() -> void:
	flags.clear()
	values.clear()
