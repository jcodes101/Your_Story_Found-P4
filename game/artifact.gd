extends Node2D
## A pickup in the temple (Mechanic 3: Object Inspection) or a readable note.
##
## Rules (from the team's decisions):
##  - Player carries ONE object at a time. F picks up / drops.
##  - Inspect: walk near an object and its name + description show on the HUD.
##  - Blessed objects improve the flashlight or movement.
##  - Cursed objects hurt them. Most cursed objects have a red outline and "!".
##  - Some cursed objects are NOT marked: their effect only kicks in after being
##    carried for DELAY_TIME seconds (then they get the red outline).
##  - Dropping an object removes its effect immediately.

enum Kind { BLESSED, CURSED, NOTE }

const DELAY_TIME := 15.0

var item_name := "Artifact"
var description := ""
var kind: int = Kind.BLESSED
var hinted := false      # cursed items that show the warning outline from the start
var delayed := false     # effect only starts after DELAY_TIME seconds carried
var light_mult := 1.0
var speed_mult := 1.0
var color := Color(0.95, 0.8, 0.3)

var carried := false
var carry_time := 0.0
var revealed := false

var _t := 0.0


func setup(data: Dictionary) -> void:
	for key in data:
		set(key, data[key])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func is_effect_active() -> bool:
	if kind == Kind.NOTE:
		return false
	return (not delayed) or carry_time >= DELAY_TIME


func current_light_mult() -> float:
	return light_mult if is_effect_active() else 1.0


func current_speed_mult() -> float:
	return speed_mult if is_effect_active() else 1.0


func pick_up() -> void:
	carried = true


func drop(at: Vector2) -> void:
	carried = false
	carry_time = 0.0  # delayed effects restart the next time it's carried
	position = at + Vector2(0, 22)


## Returns true on the frame a hidden curse reveals itself.
func tick_carry(delta: float) -> bool:
	carry_time += delta
	if delayed and not revealed and carry_time >= DELAY_TIME:
		revealed = true
		return true
	return false


func _shows_warning() -> bool:
	return kind == Kind.CURSED and (hinted or revealed)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if kind == Kind.NOTE:
		var r := Rect2(-12, -15, 24, 30)
		draw_rect(r, Color(0.85, 0.78, 0.6))
		draw_rect(r, Color(0.35, 0.25, 0.12), false, 2.0)
		for i in 4:
			draw_line(Vector2(-7, -8 + i * 6), Vector2(7, -8 + i * 6), Color(0.35, 0.25, 0.12), 1.5)
		return

	var bob := sin(_t * 2.5) * 2.0
	var pts := PackedVector2Array([
		Vector2(0, -16 + bob), Vector2(13, 0 + bob), Vector2(0, 16 + bob), Vector2(-13, 0 + bob), Vector2(0, -16 + bob)
	])
	draw_colored_polygon(pts.slice(0, 4), color)
	if _shows_warning():
		draw_polyline(pts, Color(1.0, 0.15, 0.15), 3.0)
		draw_string(font, Vector2(-10, -22 + bob), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, Color(1.0, 0.2, 0.2))
	else:
		draw_polyline(pts, color.darkened(0.4), 2.0)
