extends Node2D
## A buried spot marked on the ground (Mechanic 4: Digging and Brushing).
##
## Rules (from the team's decisions):
##  - Hold E for 3 seconds to dig a layer. Player can't move while digging.
##  - After each dig the site NEEDS a brushing pass (hold R).
##  - Digging again while brushing is required damages the fragment -> lose.
##  - Brushing when it isn't needed just wastes time.
##  - A fragment site has LAYERS dig+brush cycles; the last brush recovers it.
##  - Decoy sites (has_fragment = false) contain nothing and can't hurt anything.

signal site_finished(site)
signal fragment_damaged(site)

enum State { BURIED, NEEDS_BRUSH, DONE, DAMAGED }

const DIG_TIME := 3.0
const BRUSH_TIME := 1.5
const DAMAGE_GRACE := 0.4  # seconds of holding E while brushing is required
const LAYERS := 2

var state: int = State.BURIED
var has_fragment := true
var fragment_id := 0
var layers_left := LAYERS
var dig_progress := 0.0
var brush_progress := 0.0
var damage_timer := 0.0

var _dig_held := false
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if not _dig_held:
		damage_timer = 0.0
	_dig_held = false
	queue_redraw()


## Called every frame while the player holds E near this site.
## Returns true if the player is actually digging (so they should be frozen).
func dig(delta: float) -> bool:
	_dig_held = true
	match state:
		State.BURIED:
			dig_progress += delta
			if dig_progress >= DIG_TIME:
				dig_progress = 0.0
				layers_left -= 1
				brush_progress = 0.0
				state = State.NEEDS_BRUSH
			return true
		State.NEEDS_BRUSH:
			if not has_fragment:
				return false
			damage_timer += delta
			if damage_timer >= DAMAGE_GRACE:
				state = State.DAMAGED
				fragment_damaged.emit(self)
			return true
	return false


## Called every frame while the player holds R near this site.
func brush(delta: float) -> void:
	if state != State.NEEDS_BRUSH:
		return  # brushing when not needed only wastes time
	brush_progress += delta
	if brush_progress >= BRUSH_TIME:
		brush_progress = 0.0
		if layers_left <= 0:
			state = State.DONE
			site_finished.emit(self)
		else:
			state = State.BURIED


func _draw() -> void:
	var font := ThemeDB.fallback_font
	match state:
		State.BURIED:
			draw_circle(Vector2.ZERO, 30.0, Color(0.30, 0.20, 0.12))
			draw_circle(Vector2(-5, -4), 22.0, Color(0.38, 0.26, 0.16))
			# Marking on the ground (pulses so it's easier to spot with the light)
			var m := Color(0.9, 0.75, 0.4, 0.55 + 0.3 * sin(_t * 3.0))
			draw_line(Vector2(-10, -10), Vector2(10, 10), m, 3.0)
			draw_line(Vector2(10, -10), Vector2(-10, 10), m, 3.0)
			if dig_progress > 0.0:
				draw_arc(Vector2.ZERO, 36.0, -PI / 2.0, -PI / 2.0 + TAU * (dig_progress / DIG_TIME), 32, Color(1, 0.9, 0.4), 4.0)
		State.NEEDS_BRUSH:
			draw_circle(Vector2.ZERO, 30.0, Color(0.55, 0.45, 0.32))
			draw_circle(Vector2(-6, 3), 5.0, Color(0.75, 0.68, 0.55))
			draw_circle(Vector2(8, -6), 4.0, Color(0.75, 0.68, 0.55))
			draw_circle(Vector2(4, 9), 3.0, Color(0.75, 0.68, 0.55))
			var pulse := 0.6 + 0.4 * sin(_t * 8.0)
			draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32, Color(1.0, 0.55, 0.15, pulse), 3.0)
			draw_string(font, Vector2(-50, -46), "BRUSH (R)", HORIZONTAL_ALIGNMENT_CENTER, 100, 16, Color(1.0, 0.6, 0.2))
			if brush_progress > 0.0:
				draw_arc(Vector2.ZERO, 44.0, -PI / 2.0, -PI / 2.0 + TAU * (brush_progress / BRUSH_TIME), 32, Color(0.9, 0.9, 0.7), 4.0)
		State.DONE:
			draw_circle(Vector2.ZERO, 26.0, Color(0.12, 0.09, 0.07))
			draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color(0.3, 0.22, 0.15), 2.0)
		State.DAMAGED:
			draw_circle(Vector2.ZERO, 26.0, Color(0.12, 0.09, 0.07))
			draw_line(Vector2(-14, -10), Vector2(0, 2), Color(0.9, 0.2, 0.2), 3.0)
			draw_line(Vector2(0, 2), Vector2(14, -12), Color(0.9, 0.2, 0.2), 3.0)
			draw_line(Vector2(-8, 12), Vector2(10, 8), Color(0.9, 0.2, 0.2), 3.0)
