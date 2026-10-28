extends Control
## Quiet screen-space pointer used only during the opening search.

var direction := Vector2.UP


func set_direction(world_direction: Vector2) -> void:
	if world_direction.length_squared() < 0.001:
		visible = false
		return
	visible = true
	direction = world_direction.normalized()
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 18.0, Color(0.04, 0.05, 0.045, 0.74))
	draw_arc(center, 18.0, 0.0, TAU, 32, Color(0.85, 0.65, 0.32, 0.76), 1.5)
	var side := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		center + direction * 13.0,
		center - direction * 6.0 + side * 7.0,
		center - direction * 1.0,
		center - direction * 6.0 - side * 7.0,
	])
	draw_colored_polygon(arrow, Color(1.0, 0.82, 0.49))
