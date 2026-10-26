extends CanvasLayer
## All on-screen text and bars. Built in code so there's no scene to maintain.
## API used by main.gd: set_status, set_prompt, show_message, set_bar, show_end.

const BAR_W := 400.0

var status_label: Label
var prompt_label: Label
var message_label: Label
var bar_bg: ColorRect
var bar_fill: ColorRect
var bar_label: Label
var end_panel: ColorRect
var end_title: Label
var end_body: Label
var _message_timer := 0.0


func _ready() -> void:
	layer = 10

	status_label = _make_label(Vector2(16, 12), Vector2(700, 90), 18, HORIZONTAL_ALIGNMENT_LEFT)
	message_label = _make_label(Vector2(190, 70), Vector2(900, 120), 20, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	prompt_label = _make_label(Vector2(190, 590), Vector2(900, 100), 18, HORIZONTAL_ALIGNMENT_CENTER)

	bar_bg = ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.7)
	bar_bg.position = Vector2(440, 540)
	bar_bg.size = Vector2(BAR_W, 20)
	bar_bg.visible = false
	add_child(bar_bg)

	bar_fill = ColorRect.new()
	bar_fill.color = Color(1.0, 0.85, 0.3)
	bar_fill.position = Vector2(2, 2)
	bar_fill.size = Vector2(0, 16)
	bar_bg.add_child(bar_fill)

	bar_label = _make_label(Vector2(440, 512), Vector2(BAR_W, 24), 16, HORIZONTAL_ALIGNMENT_CENTER)
	bar_label.visible = false

	end_panel = ColorRect.new()
	end_panel.color = Color(0, 0, 0, 0.82)
	end_panel.position = Vector2.ZERO
	end_panel.size = Vector2(1280, 720)
	end_panel.visible = false
	add_child(end_panel)

	end_title = _make_label(Vector2(140, 220), Vector2(1000, 80), 48, HORIZONTAL_ALIGNMENT_CENTER, end_panel)
	end_body = _make_label(Vector2(240, 330), Vector2(800, 160), 22, HORIZONTAL_ALIGNMENT_CENTER, end_panel)


func _make_label(pos: Vector2, sz: Vector2, font_size: int, align: int, parent: Node = null) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align as HorizontalAlignment
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	if parent == null:
		add_child(l)
	else:
		parent.add_child(l)
	return l


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			message_label.text = ""


func set_status(text: String) -> void:
	status_label.text = text


func set_prompt(text: String) -> void:
	prompt_label.text = text


func show_message(text: String, seconds: float = 4.0) -> void:
	message_label.text = text
	_message_timer = seconds


## value in 0..1 shows the bar; a negative value hides it.
func set_bar(label: String, value: float, color: Color = Color(1.0, 0.85, 0.3)) -> void:
	var bar_on := value >= 0.0
	bar_bg.visible = bar_on
	bar_label.visible = bar_on
	if bar_on:
		bar_label.text = label
		bar_fill.color = color
		bar_fill.size.x = (BAR_W - 4.0) * clampf(value, 0.0, 1.0)


func show_end(title: String, body: String) -> void:
	end_title.text = title
	end_body.text = body
	end_panel.visible = true
