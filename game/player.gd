extends Node2D
## The archaeologist. Movement is handled manually (no physics) to keep the
## playtest simple. main.gd calls move() each frame when the player is free.

const BASE_SPEED := 180.0
const BODY_RADIUS := 14.0

var aim := Vector2.RIGHT
var bounds := Rect2(40, 40, 1520, 1120)
var camera: Camera2D


func _ready() -> void:
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 1200
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()


func move(delta: float, speed_mult: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * BASE_SPEED * speed_mult * delta
		position = position.clamp(bounds.position, bounds.end)


func set_aim(new_aim: Vector2) -> void:
	aim = new_aim
	queue_redraw()


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.78, 0.66, 0.42))
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 24, Color(0.25, 0.18, 0.1), 2.0)
	# Hat brim
	draw_arc(Vector2(0, -2), BODY_RADIUS - 2.0, PI, TAU, 16, Color(0.4, 0.28, 0.14), 4.0)
	# Flashlight pointing toward the mouse
	draw_line(aim * 8.0, aim * 26.0, Color(0.95, 0.95, 0.7), 6.0)
	draw_line(aim * 24.0, aim * 28.0, Color(1.0, 1.0, 0.9), 6.0)
