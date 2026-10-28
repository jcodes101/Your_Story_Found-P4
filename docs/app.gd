extends Control
## App shell for the menu, briefing, pause flow, and gameplay lifecycle.

const GAMEPLAY_SCENE := preload("res://gameplay.tscn")
const GrailEmblemScript := preload("res://grail_emblem.gd")

enum View { MAIN_MENU, BRIEFING, CONTROLS, SETTINGS, CREDITS, PLAYING, PAUSED, ENDING }

const GOLD := Color(0.91, 0.69, 0.32)
const PALE_GOLD := Color(1.0, 0.86, 0.57)
const SAND := Color(0.84, 0.79, 0.68)
const PANEL_COLOR := Color(0.055, 0.064, 0.061, 0.97)

var _ui_layer: CanvasLayer
var _screen: Control
var _game = null
var _view: int = View.MAIN_MENU
var _return_to_pause := false
var _last_victory := false
var _time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_show_main_menu()


func _process(delta: float) -> void:
	if _game == null:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if _game != null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.034))
	var center := Vector2(size.x * 0.5, size.y * 0.31)
	var radius := minf(size.x, size.y) * 0.46
	var halo := 0.035 + 0.015 * sin(_time * 1.2)
	draw_circle(center, radius, Color(0.74, 0.43, 0.16, halo))
	draw_arc(center, radius * 0.92, PI, TAU, 96, Color(0.62, 0.48, 0.28, 0.24), 2.0)
	draw_arc(center, radius * 1.05, PI, TAU, 96, Color(0.62, 0.48, 0.28, 0.12), 1.0)
	for i in 7:
		var x := size.x * (0.12 + float(i) * 0.127)
		var drift := sin(_time * 0.32 + float(i) * 1.7) * 4.0
		draw_line(Vector2(x, size.y * 0.08 + drift), Vector2(x + 22.0, size.y * 0.95), Color(0.7, 0.58, 0.34, 0.045), 1.0)
	draw_line(Vector2(size.x * 0.08, size.y * 0.88), Vector2(size.x * 0.92, size.y * 0.88), Color(0.76, 0.59, 0.3, 0.17), 1.0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_handle_escape()
		get_viewport().set_input_as_handled()


func _handle_escape() -> void:
	if _game != null:
		match _view:
			View.PLAYING:
				_show_pause_menu()
			View.PAUSED:
				_resume_game()
			View.CONTROLS, View.SETTINGS:
				if _return_to_pause:
					_show_pause_menu()
				else:
					_show_main_menu()
			View.ENDING:
				_show_main_menu()
	else:
		if _view != View.MAIN_MENU:
			_show_main_menu()


func _on_viewport_size_changed() -> void:
	queue_redraw()
	match _view:
		View.MAIN_MENU:
			_show_main_menu()
		View.BRIEFING:
			_show_briefing()
		View.CONTROLS:
			_show_controls(_return_to_pause)
		View.SETTINGS:
			_show_settings(_return_to_pause)
		View.CREDITS:
			_show_credits()
		View.PAUSED:
			_show_pause_menu()
		View.ENDING:
			_show_ending(_last_victory)


func _show_main_menu() -> void:
	get_tree().paused = false
	_remove_game()
	_view = View.MAIN_MENU
	var viewport_width := get_viewport_rect().size.x
	var screen := _new_screen(View.MAIN_MENU)
	var content := _make_panel(screen, 570.0, 600.0)
	content.add_theme_constant_override("separation", 12)

	var brand := HBoxContainer.new()
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	brand.add_theme_constant_override("separation", 14 if viewport_width >= 560.0 else 8)
	var emblem := _make_emblem(minf(88.0, maxf(56.0, viewport_width * 0.18)))
	brand.add_child(emblem)
	var title := _make_label("THE LAST\nEXPEDITION", 36 if viewport_width >= 560.0 else 28, PALE_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(minf(330.0, maxf(160.0, viewport_width * 0.48)), 90.0)
	brand.add_child(title)
	content.add_child(brand)
	_add_spacer(content, 12.0)

	var begin := _make_button("BEGIN EXPEDITION", _show_briefing, true)
	content.add_child(begin)
	content.add_child(_make_button("HOW TO PLAY", _show_controls.bind(false)))
	content.add_child(_make_button("SETTINGS", _show_settings.bind(false)))
	content.add_child(_make_button("CREDITS", _show_credits))
	begin.grab_focus()


func _show_briefing() -> void:
	_view = View.BRIEFING
	var screen := _new_screen(View.BRIEFING)
	var content := _make_panel(screen, 1040.0, 650.0)
	content.add_theme_constant_override("separation", 9)
	content.add_child(_make_label("MISSION", 26, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))

	var intro := HBoxContainer.new()
	intro.alignment = BoxContainer.ALIGNMENT_CENTER
	intro.add_theme_constant_override("separation", 16)
	intro.add_child(_make_emblem(74.0))
	var mission := _make_label("Archaeologist: recover four Grail fragments in the abandoned temple.", 19, SAND)
	mission.custom_minimum_size = Vector2(0.0, 56.0)
	intro.add_child(mission)
	content.add_child(intro)

	_add_rule(content, "Light reveals marks.")
	_add_rule(content, "Dig, then brush. Digging twice shatters a fragment.")
	_add_rule(content, "Inspect relics: blessings or curses.")
	_add_rule(content, "Four intact: hold G 3s to restore. Damage one; fail.")

	_add_spacer(content, 2.0)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	var enter := _make_button("ENTER TEMPLE", _enter_game, true)
	var back := _make_button("BACK", _show_main_menu)
	enter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(enter)
	actions.add_child(back)
	content.add_child(actions)
	enter.grab_focus()


func _show_controls(return_to_pause: bool) -> void:
	_return_to_pause = return_to_pause
	_view = View.CONTROLS
	var screen := _new_screen(View.CONTROLS, return_to_pause)
	var content := _make_panel(screen, 710.0, 560.0)
	content.add_theme_constant_override("separation", 6)
	var rows := [
		["WASD / ARROWS", "MOVE"],
		["MOUSE", "AIM / SWEEP LIGHT"],
		["E • HOLD 3S", "DIG ONE LAYER"],
		["R • HOLD 1.5S", "BRUSH"],
		["F", "READ / TAKE / DROP"],
		["G • HOLD 3S", "RESTORE (4/4)"],
		["ESC", "PAUSE"],
		["ENTER / SPACE", "SELECT"],
	]
	for row in rows:
		content.add_child(_make_control_row(row[0], row[1]))
	_add_spacer(content, 8.0)
	var back := _make_button("BACK", _back_from_subscreen.bind(return_to_pause))
	content.add_child(back)
	back.grab_focus()


func _show_settings(return_to_pause: bool) -> void:
	_return_to_pause = return_to_pause
	_view = View.SETTINGS
	var screen := _new_screen(View.SETTINGS, return_to_pause)
	var content := _make_panel(screen, 650.0, 410.0)
	content.add_theme_constant_override("separation", 14)
	content.add_child(_make_label("SETTINGS", 26, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var mode := DisplayServer.window_get_mode()
	var mode_text := "FULLSCREEN: ON" if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else "FULLSCREEN: OFF"
	var toggle := _make_button(mode_text, _toggle_fullscreen.bind(return_to_pause), true)
	content.add_child(toggle)
	var back := _make_button("BACK", _back_from_subscreen.bind(return_to_pause))
	content.add_child(back)
	toggle.grab_focus()


func _toggle_fullscreen(return_to_pause: bool) -> void:
	var mode := DisplayServer.window_get_mode()
	var next_mode := DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(next_mode)
	_show_settings(return_to_pause)


func _show_credits() -> void:
	_view = View.CREDITS
	var screen := _new_screen(View.CREDITS)
	var content := _make_panel(screen, 650.0, 470.0)
	content.add_theme_constant_override("separation", 12)
	content.add_child(_make_label("CREDITS", 26, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_make_label("Jadin  •  Hali  •  Jeremiah  •  Naomi", 19, SAND, HORIZONTAL_ALIGNMENT_CENTER))
	_add_spacer(content, 10.0)
	var back := _make_button("BACK", _show_main_menu)
	content.add_child(back)
	back.grab_focus()


func _show_pause_menu() -> void:
	if _game == null:
		return
	_view = View.PAUSED
	get_tree().paused = true
	var screen := _new_screen(View.PAUSED, true)
	var content := _make_panel(screen, 610.0, 590.0)
	content.add_theme_constant_override("separation", 9)
	content.add_child(_make_label("PAUSED", 30, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := _make_button("RESUME EXPEDITION", _resume_game, true)
	content.add_child(resume)
	content.add_child(_make_button("HOW TO PLAY", _show_controls.bind(true)))
	content.add_child(_make_button("SETTINGS", _show_settings.bind(true)))
	content.add_child(_make_button("RESTART EXPEDITION", _restart_game))
	content.add_child(_make_button("RETURN TO MAIN MENU", _show_main_menu))
	resume.grab_focus()


func _show_ending(victory: bool) -> void:
	_view = View.ENDING
	_last_victory = victory
	get_tree().paused = true
	var screen := _new_screen(View.ENDING, true)
	var content := _make_panel(screen, 690.0, 560.0)
	content.add_theme_constant_override("separation", 12)
	var emblem := _make_emblem(150.0, not victory)
	content.add_child(emblem)
	if victory:
		content.add_child(_make_label("GRAIL RESTORED", 30, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		content.add_child(_make_label("FRAGMENT SHATTERED", 30, Color(0.96, 0.57, 0.43), HORIZONTAL_ALIGNMENT_CENTER))
	var restart := _make_button("RESTART EXPEDITION", _restart_game, true)
	content.add_child(restart)
	content.add_child(_make_button("RETURN TO MAIN MENU", _show_main_menu))
	restart.grab_focus()


func _enter_game() -> void:
	get_tree().paused = false
	_clear_screen()
	_view = View.PLAYING
	_game = GAMEPLAY_SCENE.instantiate()
	_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	_game.game_ended.connect(_on_game_ended)
	_game.set_controls_blocked(true)


func _on_game_ended(victory: bool) -> void:
	_show_ending(victory)


func _resume_game() -> void:
	_clear_screen()
	get_tree().paused = false
	_view = View.PLAYING
	if _game != null:
		_game.set_controls_blocked(true)


func _restart_game() -> void:
	get_tree().paused = false
	_remove_game()
	_enter_game()


func _back_from_subscreen(return_to_pause: bool) -> void:
	if return_to_pause and _game != null:
		_show_pause_menu()
	else:
		_show_main_menu()


func _remove_game() -> void:
	if _game == null:
		return
	var old_game = _game
	_game = null
	if old_game.get_parent() != null:
		old_game.get_parent().remove_child(old_game)
	old_game.queue_free()


func _new_screen(view: int, dim_game: bool = false) -> Control:
	_clear_screen()
	_view = view
	_screen = Control.new()
	_screen.name = "ModalUI"
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_layer.add_child(_screen)
	if dim_game:
		var shade := ColorRect.new()
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.color = Color(0.012, 0.018, 0.019, 0.84)
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
		_screen.add_child(shade)
	return _screen


func _clear_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.visible = false
		_screen.queue_free()
	_screen = null


func _make_panel(screen: Control, target_width: float, target_height: float) -> VBoxContainer:
	var viewport_size := get_viewport_rect().size
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(target_width, maxf(320.0, viewport_size.x - 28.0)), minf(target_height, maxf(280.0, viewport_size.y - 28.0)))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var margins := MarginContainer.new()
	var margin := clampi(int(minf(viewport_size.x, viewport_size.y) * 0.045), 18, 42)
	for side in ["left", "top", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, margin)
	panel.add_child(margins)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_child(content)
	return content


func _add_rule(parent: VBoxContainer, copy: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var text := _make_label(copy, 17, SAND)
	text.custom_minimum_size = Vector2(0.0, 42.0)
	row.add_child(text)
	parent.add_child(row)


func _make_control_row(key_text: String, action_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var key_label := _make_label(key_text, 16, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	key_label.custom_minimum_size = Vector2(minf(210.0, maxf(120.0, get_viewport_rect().size.x * 0.34)), 36.0)
	row.add_child(key_label)
	var action_label := _make_label(action_text, 16, SAND)
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(action_label)
	return row


func _make_label(copy: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.02, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_button(copy: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16)
	var normal := _button_style(Color(0.1, 0.115, 0.105, 0.98), Color(0.49, 0.39, 0.23, 0.85), 1)
	var hover := _button_style(Color(0.2, 0.17, 0.11, 1.0), GOLD, 2)
	var pressed := _button_style(Color(0.27, 0.2, 0.11, 1.0), PALE_GOLD, 2)
	var focus := _button_style(Color(0.17, 0.15, 0.11, 1.0), PALE_GOLD, 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", PALE_GOLD if primary else SAND)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.pressed.connect(action)
	return button


func _button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color(0.65, 0.49, 0.25, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 7.0)
	return style


func _make_emblem(side: float, shattered: bool = false) -> Control:
	var emblem = GrailEmblemScript.new()
	emblem.custom_minimum_size = Vector2(side, side)
	emblem.set_shattered(shattered)
	return emblem


func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	parent.add_child(spacer)
