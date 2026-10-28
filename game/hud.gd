extends CanvasLayer
## Anchored, high-contrast gameplay HUD.

const GOLD := Color(0.92, 0.7, 0.34)
const PALE_GOLD := Color(1.0, 0.86, 0.58)
const TEXT_COLOR := Color(0.91, 0.9, 0.84)
const PANEL_COLOR := Color(0.025, 0.035, 0.034, 0.88)
const DirectionCueScript := preload("res://direction_cue.gd")

var root: Control
var objective_panel: PanelContainer
var carry_panel: PanelContainer
var carry_label: Label
var message_label: Label
var guide_cue
var prompt_panel: PanelContainer
var prompt_label: Label
var bar_panel: PanelContainer
var bar_label: Label
var progress_bar: ProgressBar
var fragment_label: Label
var fragment_segments: Array[PanelContainer] = []
var _message_timer := 0.0
var _fragment_count := -1
var _prompt_danger := false
var _progress_fill_color := GOLD


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_objective()
	_build_carry_status()
	_build_message()
	_build_guide()
	_build_progress()
	_build_prompt()
	_layout_ui()
	get_viewport().size_changed.connect(_layout_ui)
	set_fragment_count(0)
	set_carry_status("")


func _build_objective() -> void:
	objective_panel = _make_panel()
	objective_panel.anchor_left = 0.0
	objective_panel.anchor_right = 0.0
	objective_panel.anchor_top = 0.0
	objective_panel.anchor_bottom = 0.0
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(objective_panel)
	var margin := _make_margin(objective_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	box.add_child(_make_label("RECOVER GRAIL", 17, PALE_GOLD))
	fragment_label = _make_label("0/4", 14, TEXT_COLOR)
	box.add_child(fragment_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	box.add_child(row)
	for i in 4:
		var segment := _make_panel()
		segment.custom_minimum_size = Vector2(38.0, 13.0)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(segment)
		fragment_segments.append(segment)


func _build_carry_status() -> void:
	carry_panel = _make_panel()
	carry_panel.anchor_left = 1.0
	carry_panel.anchor_right = 1.0
	carry_panel.anchor_top = 0.0
	carry_panel.anchor_bottom = 0.0
	carry_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(carry_panel)
	var margin := _make_margin(carry_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	carry_label = _make_label("", 15, TEXT_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
	box.add_child(carry_label)
	carry_panel.visible = false


func _build_message() -> void:
	message_label = _make_label("", 17, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.visible = false
	root.add_child(message_label)


func _build_progress() -> void:
	bar_panel = _make_panel()
	bar_panel.anchor_left = 0.5
	bar_panel.anchor_right = 0.5
	bar_panel.anchor_top = 1.0
	bar_panel.anchor_bottom = 1.0
	bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar_panel)
	var margin := _make_margin(bar_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	bar_label = _make_label("", 14, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(bar_label)
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 17.0)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.add_theme_stylebox_override("background", _progress_style(Color(0.1, 0.11, 0.1)))
	progress_bar.add_theme_stylebox_override("fill", _progress_style(GOLD))
	box.add_child(progress_bar)
	bar_panel.visible = false


func _build_guide() -> void:
	guide_cue = DirectionCueScript.new()
	guide_cue.custom_minimum_size = Vector2(44.0, 44.0)
	guide_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_cue.visible = false
	root.add_child(guide_cue)


func _build_prompt() -> void:
	prompt_panel = _make_panel()
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt_panel)
	var margin := _make_margin(prompt_panel)
	prompt_label = _make_label("", 17, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.custom_minimum_size = Vector2(0.0, 38.0)
	margin.add_child(prompt_label)
	prompt_panel.visible = false


func _layout_ui() -> void:
	if root == null:
		return
	var view_size := get_viewport().get_visible_rect().size
	var side_width := minf(300.0, maxf(130.0, view_size.x * 0.43))
	objective_panel.position = Vector2(16.0, 16.0)
	objective_panel.custom_minimum_size = Vector2(side_width, 112.0)
	var segment_width := minf(38.0, maxf(18.0, (side_width - 50.0) / 4.0))
	for segment in fragment_segments:
		segment.custom_minimum_size = Vector2(segment_width, 13.0)
	carry_panel.offset_left = -side_width - 16.0
	carry_panel.offset_right = -16.0
	carry_panel.offset_top = 16.0
	carry_panel.offset_bottom = 90.0
	message_label.anchor_left = 0.5
	message_label.anchor_right = 0.5
	message_label.anchor_top = 0.0
	message_label.anchor_bottom = 0.0
	var message_half_width := minf(350.0, maxf(140.0, view_size.x * 0.43))
	message_label.offset_left = -message_half_width
	message_label.offset_right = message_half_width
	message_label.offset_top = 142.0
	message_label.offset_bottom = 192.0
	guide_cue.position = Vector2(view_size.x * 0.5 - 22.0, 88.0)
	bar_panel.offset_left = -minf(300.0, maxf(140.0, view_size.x * 0.38))
	bar_panel.offset_right = -bar_panel.offset_left
	bar_panel.offset_top = -184.0
	bar_panel.offset_bottom = -136.0
	var center_half_width := minf(410.0, maxf(140.0, view_size.x * 0.46))
	prompt_panel.offset_left = -center_half_width
	prompt_panel.offset_right = center_half_width
	prompt_panel.offset_top = -130.0
	prompt_panel.offset_bottom = -18.0


func set_fragment_count(count: int) -> void:
	var safe_count := clampi(count, 0, 4)
	if fragment_label == null:
		return
	if safe_count == _fragment_count:
		return
	fragment_label.text = "%d/4" % safe_count
	for i in fragment_segments.size():
		var segment := fragment_segments[i]
		var active := i < safe_count
		segment.add_theme_stylebox_override("panel", _segment_style(active))
		if active and i >= _fragment_count:
			segment.pivot_offset = segment.custom_minimum_size * 0.5
			var tween := create_tween()
			tween.tween_property(segment, "scale", Vector2(1.28, 1.28), 0.11)
			tween.tween_property(segment, "scale", Vector2.ONE, 0.16)
	_fragment_count = safe_count


func set_carry_status(item_name: String) -> void:
	if item_name.is_empty():
		carry_panel.visible = false
		carry_label.text = ""
		return
	carry_panel.visible = true
	var next_text := item_name
	var next_color := PALE_GOLD
	if carry_label.text != next_text:
		carry_label.text = next_text
	if carry_label.get_theme_color("font_color") != next_color:
		carry_label.add_theme_color_override("font_color", next_color)


func set_prompt(text: String, dangerous: bool = false) -> void:
	if prompt_label.text != text:
		prompt_label.text = text
	prompt_panel.visible = not text.is_empty()
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.67, 0.53) if dangerous else PALE_GOLD)
	if _prompt_danger != dangerous:
		prompt_panel.add_theme_stylebox_override("panel", _panel_style(dangerous))
		_prompt_danger = dangerous


func set_guide_direction(direction: Vector2) -> void:
	guide_cue.set_direction(direction)


func show_message(text: String, seconds: float = 2.5, dangerous: bool = false) -> void:
	message_label.text = text
	message_label.visible = not text.is_empty()
	message_label.add_theme_color_override("font_color", Color(1.0, 0.61, 0.46) if dangerous else PALE_GOLD)
	_message_timer = seconds


func set_bar(label: String, value: float, color: Color = GOLD) -> void:
	bar_panel.visible = value >= 0.0
	if value < 0.0:
		return
	bar_label.text = label
	progress_bar.value = clampf(value, 0.0, 1.0)
	if _progress_fill_color != color:
		progress_bar.add_theme_stylebox_override("fill", _progress_style(color))
		_progress_fill_color = color


func _process(delta: float) -> void:
	if _message_timer <= 0.0:
		return
	_message_timer -= delta
	if _message_timer <= 0.0:
		message_label.text = ""
		message_label.visible = false


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel


func _make_margin(parent: Control) -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 11)
	parent.add_child(margin)
	return margin


func _make_label(copy: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(dangerous: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color(0.72, 0.34, 0.23, 0.9) if dangerous else Color(0.66, 0.5, 0.27, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style


func _segment_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD if active else Color(0.11, 0.12, 0.11)
	style.border_color = PALE_GOLD if active else Color(0.48, 0.42, 0.31, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
