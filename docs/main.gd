extends Node2D
## THE LAST EXPEDITION - playtest build.
## Builds the whole level in code and wires the four mechanics together.
##
## Controls: WASD/arrows move | mouse aims flashlight | hold E dig | hold R brush
##           F pick up / drop / read | hold G restore the Grail (needs 4 fragments)
##           F1 toggle bright mode (debug) | Enter restart after win/lose

const DigSiteScript = preload("res://dig_site.gd")
const ArtifactScript = preload("res://artifact.gd")
const PlayerScript = preload("res://player.gd")
const HudScript = preload("res://hud.gd")
const DarknessShader = preload("res://darkness.gdshader")

const WORLD_SIZE := Vector2(1600, 1200)
const BASE_LIGHT_RANGE := 430.0
const BASE_CONE_HALF_ANGLE := 0.42
const AMBIENT_VISIBILITY_RADIUS := 95.0
const INTERACT_RANGE := 75.0
const FRAGMENTS_NEEDED := 4
const RESTORE_TIME := 3.0

enum GameState { PLAYING, WON, LOST }

var state: int = GameState.PLAYING
var player: Node2D
var hud: CanvasLayer
var darkness_mat: ShaderMaterial
var sites: Array = []
var artifacts: Array = []
var carried = null
var fragments_collected := 0
var restore_progress := 0.0
var debug_bright := false


func _ready() -> void:
	_build_world()
	_build_player()
	_build_darkness()
	hud = HudScript.new()
	add_child(hud)
	hud.show_message("Find the 4 fragments of the Holy Grail. Aim with the mouse and sweep your light over the ground markings. The beam fades with distance but never runs out.\nRead the journal near you first (F).", 9.0)


# ---------------------------------------------------------------- world setup

func _build_world() -> void:
	# Four buried fragments (Mechanic 2) + decoy dig sites.
	var fragment_spots := [Vector2(1350, 180), Vector2(300, 260), Vector2(820, 640), Vector2(1330, 980)]
	for i in fragment_spots.size():
		_add_site(fragment_spots[i], true, i + 1)
	for spot in [Vector2(720, 170), Vector2(1030, 1010), Vector2(520, 930)]:
		_add_site(spot, false, 0)

	# Artifacts (Mechanic 3).
	_add_artifact({
		"item_name": "Lantern Charm",
		"description": "A warm brass charm. Your light reaches farther and wider.",
		"kind": ArtifactScript.Kind.BLESSED, "light_mult": 1.4,
		"color": Color(0.95, 0.8, 0.3),
	}, Vector2(520, 800))
	_add_artifact({
		"item_name": "Swift Sandals",
		"description": "Light, well-oiled sandals. You move faster.",
		"kind": ArtifactScript.Kind.BLESSED, "speed_mult": 1.35,
		"color": Color(0.9, 0.75, 0.35),
	}, Vector2(920, 330))
	_add_artifact({
		"item_name": "Dim Idol",
		"description": "A soot-black idol. It drinks light. (Marked with a warning.)",
		"kind": ArtifactScript.Kind.CURSED, "hinted": true, "light_mult": 0.55,
		"color": Color(0.5, 0.35, 0.65),
	}, Vector2(640, 480))
	_add_artifact({
		"item_name": "Leaden Anklet",
		"description": "A heavy anklet. You'd move much slower. (Marked with a warning.)",
		"kind": ArtifactScript.Kind.CURSED, "hinted": true, "speed_mult": 0.55,
		"color": Color(0.55, 0.4, 0.6),
	}, Vector2(1120, 760))
	_add_artifact({
		"item_name": "Gilded Mask",
		"description": "A shining ceremonial mask. It feels oddly warm to the touch.",
		"kind": ArtifactScript.Kind.CURSED, "delayed": true, "light_mult": 0.4,
		"color": Color(0.93, 0.78, 0.32),
	}, Vector2(420, 560))

	# The explorer's journal: the story item near the start.
	_add_artifact({
		"item_name": "Explorer's Journal",
		"description": "\"Every crew before us failed the same way. They dug twice without brushing and the Grail crumbled in their hands. And they carried cursed relics without knowing. Dig. Brush. Never dig again until the dirt is cleared. Some gifts here look golden and still take something from you. -- Last Expedition, Day 12\"",
		"kind": ArtifactScript.Kind.NOTE,
	}, Vector2(260, 1060))


func _add_site(pos: Vector2, has_fragment: bool, id: int) -> void:
	var s = DigSiteScript.new()
	s.position = pos
	s.has_fragment = has_fragment
	s.fragment_id = id
	s.site_finished.connect(_on_site_finished)
	s.fragment_damaged.connect(_on_fragment_damaged)
	add_child(s)
	sites.append(s)


func _add_artifact(data: Dictionary, pos: Vector2) -> void:
	var a = ArtifactScript.new()
	a.setup(data)
	a.position = pos
	add_child(a)
	artifacts.append(a)


func _build_player() -> void:
	player = PlayerScript.new()
	player.position = Vector2(200, 1020)
	add_child(player)


func _build_darkness() -> void:
	var rect := ColorRect.new()
	rect.position = Vector2(-200, -200)
	rect.size = WORLD_SIZE + Vector2(400, 400)
	rect.z_index = 50
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness_mat = ShaderMaterial.new()
	darkness_mat.shader = DarknessShader
	rect.material = darkness_mat
	add_child(rect)


# ------------------------------------------------------------------- drawing

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.17, 0.14, 0.11))
	var grid := Color(0.22, 0.18, 0.14)
	for x in range(0, 1601, 100):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), grid, 2.0)
	for y in range(0, 1201, 100):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), grid, 2.0)
	# Temple walls
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.45, 0.38, 0.3), false, 40.0)
	# Decorative pillars (no collision in the playtest build)
	for p in [Vector2(400, 400), Vector2(1200, 400), Vector2(400, 850), Vector2(1200, 850), Vector2(800, 300), Vector2(800, 900)]:
		draw_circle(p, 26.0, Color(0.4, 0.34, 0.27))
		draw_arc(p, 26.0, 0.0, TAU, 24, Color(0.25, 0.2, 0.15), 3.0)


# ---------------------------------------------------------------- game loop

func _process(delta: float) -> void:
	_update_light()
	if state != GameState.PLAYING:
		return

	var busy := _handle_actions(delta)
	var speed_mult := 1.0
	if carried != null:
		speed_mult = carried.current_speed_mult()
		if carried.tick_carry(delta):
			hud.show_message("The %s was cursed! Something feels wrong... (F to drop it)" % carried.item_name, 6.0)
		carried.position = player.position + Vector2(0, -32)
	if not busy:
		player.move(delta, speed_mult)
	_update_hud()


## Handles E / R / G holds. Returns true if the player must stay still.
func _handle_actions(delta: float) -> bool:
	var e_held := Input.is_key_pressed(KEY_E)
	var r_held := Input.is_key_pressed(KEY_R)
	var g_held := Input.is_key_pressed(KEY_G)

	# Mechanic 2: restoration (hold G 3s, only with all four fragments).
	if g_held and fragments_collected >= FRAGMENTS_NEEDED:
		restore_progress += delta
		if restore_progress >= RESTORE_TIME:
			_win()
		return true
	restore_progress = 0.0

	var site = _nearest_site()
	if site == null:
		return false
	# Mechanic 4: digging freezes the player, brushing doesn't.
	if r_held:
		site.brush(delta)
	elif e_held:
		return site.dig(delta)
	return false


func _nearest_site():
	var best = null
	var best_d := INTERACT_RANGE
	for s in sites:
		var d: float = s.position.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = s
	return best


func _nearest_artifact():
	var best = null
	var best_d := INTERACT_RANGE
	for a in artifacts:
		if a.carried:
			continue
		var d: float = a.position.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = a
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F:
			_interact()
		KEY_F1:
			debug_bright = not debug_bright
		KEY_ENTER, KEY_KP_ENTER:
			if state != GameState.PLAYING:
				get_tree().reload_current_scene()


## Mechanic 3: pick up / drop one object at a time; notes are just read.
func _interact() -> void:
	if state != GameState.PLAYING:
		return
	if carried != null:
		hud.show_message("Dropped the %s. Its effect is gone." % carried.item_name, 3.0)
		carried.drop(player.position)
		carried = null
		return
	var a = _nearest_artifact()
	if a == null:
		return
	if a.kind == ArtifactScript.Kind.NOTE:
		hud.show_message(a.description, 14.0)
		return
	a.pick_up()
	carried = a
	hud.show_message("Picked up the %s." % a.item_name, 3.0)


# ------------------------------------------------------------ mechanic events

func _on_site_finished(site) -> void:
	if site.has_fragment:
		fragments_collected += 1
		if fragments_collected >= FRAGMENTS_NEEDED:
			hud.show_message("All four fragments recovered! Hold G to restore the Holy Grail.", 6.0)
		else:
			hud.show_message("Grail fragment %d recovered, undamaged! (%d/%d)" % [site.fragment_id, fragments_collected, FRAGMENTS_NEEDED], 4.0)
	else:
		hud.show_message("Nothing here but old pottery. Keep looking.", 3.0)


func _on_fragment_damaged(_site) -> void:
	state = GameState.LOST
	hud.set_bar("", -1.0)
	hud.set_prompt("")
	hud.show_end("EXPEDITION FAILED", "You dug again before brushing and the fragment shattered.\nThe Grail can never be restored.\n\nPress Enter to try again.")


func _win() -> void:
	state = GameState.WON
	hud.set_bar("", -1.0)
	hud.set_prompt("")
	hud.show_end("THE GRAIL IS RESTORED", "All four fragments joined, undamaged.\nThe Last Expedition is a success!\n\nPress Enter to play again.")


# --------------------------------------------------------- light + HUD update

func _current_light_mult() -> float:
	return carried.current_light_mult() if carried != null else 1.0


func _update_light() -> void:
	var to_mouse := get_global_mouse_position() - player.global_position
	if to_mouse.length() > 4.0:
		player.set_aim(to_mouse.normalized())
	var lm := _current_light_mult()
	darkness_mat.set_shader_parameter("player_pos", player.global_position)
	darkness_mat.set_shader_parameter("aim_dir", player.aim)
	darkness_mat.set_shader_parameter("light_range", BASE_LIGHT_RANGE * lm)
	darkness_mat.set_shader_parameter("cone_half_angle", BASE_CONE_HALF_ANGLE * clampf(lm, 0.55, 1.35))
	darkness_mat.set_shader_parameter("ambient_radius", AMBIENT_VISIBILITY_RADIUS)
	darkness_mat.set_shader_parameter("darkness", 0.12 if debug_bright else 0.97)
	# Ground marks are visible in the flashlight beam; the buried fragments remain hidden.
	for site in sites:
		var offset: Vector2 = site.global_position - player.global_position
		var distance := offset.length()
		var exposure := 0.0
		if distance <= BASE_LIGHT_RANGE * lm and distance > 0.001:
			var angle := absf(player.aim.angle_to(offset.normalized()))
			var half_angle := BASE_CONE_HALF_ANGLE * clampf(lm, 0.55, 1.35)
			var angular_exposure := 1.0 - smoothstep(half_angle * 0.7, half_angle, angle)
			var distance_exposure := 1.0 - smoothstep(BASE_LIGHT_RANGE * lm * 0.45, BASE_LIGHT_RANGE * lm, distance)
			exposure = angular_exposure * distance_exposure
		site.set_flashlight_exposure(exposure)


func _update_hud() -> void:
	var carry_text := "nothing"
	var fx := ""
	if carried != null:
		carry_text = carried.item_name
		fx = "  (light x%.2f, speed x%.2f)" % [carried.current_light_mult(), carried.current_speed_mult()]
	hud.set_status("Fragments: %d / %d\nCarrying: %s%s" % [fragments_collected, FRAGMENTS_NEEDED, carry_text, fx])

	var lines: Array = []
	if fragments_collected >= FRAGMENTS_NEEDED:
		lines.append("Hold G to restore the Holy Grail")
	var site = _nearest_site()
	if site != null:
		if site.state == DigSiteScript.State.BURIED:
			lines.append("Hold E to dig (you can't move while digging)")
		elif site.state == DigSiteScript.State.NEEDS_BRUSH:
			lines.append("Brush it! Hold R. Digging again now would damage a fragment!")
	var a = _nearest_artifact()
	if a != null:
		if a.kind == ArtifactScript.Kind.NOTE:
			lines.append("[F] Read the %s" % a.item_name)
		elif carried == null:
			lines.append("%s: %s  [F] pick up" % [a.item_name, a.description])
	if carried != null:
		lines.append("[F] Drop the %s" % carried.item_name)
	hud.set_prompt("\n".join(lines))

	# Progress bar
	if restore_progress > 0.0:
		hud.set_bar("Restoring the Holy Grail...", restore_progress / RESTORE_TIME, Color(0.6, 0.9, 1.0))
	elif site != null and site.state == DigSiteScript.State.BURIED and site.dig_progress > 0.0:
		hud.set_bar("Digging...", site.dig_progress / DigSiteScript.DIG_TIME)
	elif site != null and site.state == DigSiteScript.State.NEEDS_BRUSH and site.brush_progress > 0.0:
		hud.set_bar("Brushing...", site.brush_progress / DigSiteScript.BRUSH_TIME, Color(0.85, 0.85, 0.7))
	else:
		hud.set_bar("", -1.0)
