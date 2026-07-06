extends Control

signal start_requested
signal resume_requested
signal main_menu_requested
signal quit_requested

@export_enum("main", "pause", "victory") var menu_mode := "main"

var button_style_normal: StyleBoxFlat
var button_style_hover: StyleBoxFlat
var button_style_pressed: StyleBoxFlat
var action_buttons: Dictionary = {}
var fade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_menu()
	visible = false


func open() -> void:
	if fade_tween != null:
		fade_tween.kill()
	visible = true
	modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	fade_tween.tween_callback(func() -> void:
		fade_tween = null
	)


func close() -> void:
	if fade_tween != null:
		fade_tween.kill()
		fade_tween = null
	modulate.a = 1.0
	visible = false


func fade_out() -> void:
	if not visible:
		return
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	await fade_tween.finished
	fade_tween = null
	visible = false
	modulate.a = 1.0


func set_resume_enabled(is_enabled: bool) -> void:
	if action_buttons.has("resume"):
		action_buttons["resume"].visible = is_enabled


func _build_menu() -> void:
	_build_button_styles()

	var background := TextureRect.new()
	background.texture = load("res://art/backgrounds/hall/hall.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shadow := ColorRect.new()
	shadow.color = Color(0.015, 0.011, 0.008, 0.68)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shadow)

	var side_shade := ColorRect.new()
	side_shade.color = Color(0.06, 0.041, 0.027, 0.50)
	side_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	side_shade.offset_right = -1020.0
	add_child(side_shade)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	content.anchor_left = 0.0
	content.anchor_right = 0.0
	content.offset_left = 150.0
	content.offset_top = -270.0
	content.offset_right = 620.0
	content.offset_bottom = 270.0
	content.add_theme_constant_override("separation", 18)
	add_child(content)

	var title := Label.new()
	title.text = _get_title_text()
	title.add_theme_color_override("font_color", Color(0.86, 0.72, 0.52, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 74 if menu_mode == "main" else 56)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.text = _get_subtitle_text()
	subtitle.add_theme_color_override("font_color", Color(0.70, 0.61, 0.48, 1.0))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.custom_minimum_size = Vector2(430, 82)
	content.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 18)
	content.add_child(spacer)

	for button_data in _get_buttons():
		content.add_child(_create_menu_button(button_data["label"], button_data["action"]))

	if menu_mode == "main":
		set_resume_enabled(false)


func _get_title_text() -> String:
	if menu_mode == "victory":
		return "PROVAS REUNIDAS"
	return "CONFISSAO"


func _build_button_styles() -> void:
	button_style_normal = _create_button_style(Color(0.052, 0.039, 0.030, 0.88), Color(0.37, 0.25, 0.13, 0.88))
	button_style_hover = _create_button_style(Color(0.105, 0.073, 0.043, 0.94), Color(0.76, 0.55, 0.26, 0.95))
	button_style_pressed = _create_button_style(Color(0.025, 0.020, 0.017, 0.96), Color(0.86, 0.72, 0.52, 1.0))


func _create_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style


func _create_menu_button(label_text: String, action: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(330, 58)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color(0.86, 0.72, 0.52, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.96, 0.86, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.64, 0.49, 0.31, 1.0))
	button.add_theme_stylebox_override("normal", button_style_normal)
	button.add_theme_stylebox_override("hover", button_style_hover)
	button.add_theme_stylebox_override("pressed", button_style_pressed)
	button.add_theme_stylebox_override("focus", button_style_hover)
	button.pressed.connect(_on_button_pressed.bind(action))
	action_buttons[action] = button
	return button


func _get_subtitle_text() -> String:
	if menu_mode == "victory":
		return "Parabens, todas as provas foram coletadas"
	if menu_mode == "pause":
		return "O silencio permanece. Respire antes de continuar."
	return "Uma casa antiga, cartas escondidas e portas que so cedem a verdade."


func _get_buttons() -> Array[Dictionary]:
	if menu_mode == "victory":
		return [
			{"label": "Voltar ao menu", "action": "main_menu"},
			{"label": "Sair do jogo", "action": "quit"},
		]

	if menu_mode == "pause":
		return [
			{"label": "Continuar", "action": "resume"},
			{"label": "Voltar ao menu", "action": "main_menu"},
			{"label": "Sair do jogo", "action": "quit"},
		]

	return [
		{"label": "Retomar", "action": "resume"},
		{"label": "Novo jogo", "action": "start"},
		{"label": "Sair do jogo", "action": "quit"},
	]


func _on_button_pressed(action: String) -> void:
	AudioManager.play_sfx("click")
	match action:
		"start":
			start_requested.emit()
		"resume":
			resume_requested.emit()
		"main_menu":
			main_menu_requested.emit()
		"quit":
			quit_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and menu_mode == "pause" and event.is_action_pressed("ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
