extends Control
## Lightweight procedural Grail / shattered-fragment illustration for the UI.

var shattered := false
var _time := 0.0


func set_shattered(value: bool) -> void:
	shattered = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side < 1.0:
		return
	var center := size * 0.5
	var scale_factor := side / 100.0
	var glow := 0.13 + 0.05 * (0.5 + 0.5 * sin(_time * 1.4))
	draw_circle(center, side * 0.43, Color(0.9, 0.62, 0.22, glow))
	draw_arc(center, side * 0.43, 0.0, TAU, 56, Color(0.83, 0.62, 0.32, 0.52), maxf(1.0, side * 0.012))

	if shattered:
		var shard := PackedVector2Array([
			center + Vector2(-24, -30) * scale_factor,
			center + Vector2(17, -25) * scale_factor,
			center + Vector2(26, 4) * scale_factor,
			center + Vector2(6, 30) * scale_factor,
			center + Vector2(-26, 18) * scale_factor,
		])
		draw_colored_polygon(shard, Color(0.77, 0.57, 0.31))
		draw_polyline(PackedVector2Array([
			center + Vector2(-5, -23) * scale_factor,
			center + Vector2(2, -5) * scale_factor,
			center + Vector2(-9, 4) * scale_factor,
			center + Vector2(9, 28) * scale_factor,
		]), Color(0.28, 0.12, 0.1), maxf(2.0, side * 0.025), true)
		return

	var gold := Color(0.96, 0.77, 0.39)
	var cup := PackedVector2Array([
		center + Vector2(-25, -24) * scale_factor,
		center + Vector2(25, -24) * scale_factor,
		center + Vector2(17, 2) * scale_factor,
		center + Vector2(-17, 2) * scale_factor,
	])
	draw_colored_polygon(cup, gold)
	draw_polyline(PackedVector2Array([
		center + Vector2(-25, -24) * scale_factor,
		center + Vector2(-17, 2) * scale_factor,
		center + Vector2(17, 2) * scale_factor,
		center + Vector2(25, -24) * scale_factor,
	]), Color(1.0, 0.9, 0.65), maxf(1.0, side * 0.014), true)
	draw_arc(center + Vector2(-22, -12) * scale_factor, 13.0 * scale_factor, -PI * 0.5, PI * 0.5, 24, gold, maxf(2.0, side * 0.035))
	draw_arc(center + Vector2(22, -12) * scale_factor, 13.0 * scale_factor, PI * 0.5, PI * 1.5, 24, gold, maxf(2.0, side * 0.035))
	draw_rect(Rect2(center + Vector2(-4, 2) * scale_factor, Vector2(8, 23) * scale_factor), gold)
	draw_rect(Rect2(center + Vector2(-21, 25) * scale_factor, Vector2(42, 6) * scale_factor), gold)
	draw_line(center + Vector2(-29, 34) * scale_factor, center + Vector2(29, 34) * scale_factor, Color(0.96, 0.77, 0.39, 0.62), maxf(1.0, side * 0.012))
