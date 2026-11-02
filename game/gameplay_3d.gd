extends Node3D
## Compact 3D playtest chapter. The original 2D scene remains available as a fallback.

signal game_ended(victory: bool)

const DIG_TIME := 3.0
const BRUSH_TIME := 1.5
const DAMAGE_GRACE := 0.4
const RESTORE_TIME := 3.0
const MOVE_SPEED := 4.3

enum State { EXPLORING, RESTORING, WON, LOST }

var state: int = State.EXPLORING
var ending_text := ""
var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var sites: Array[Dictionary] = []
var artifacts: Array[Dictionary] = []
var carried: Dictionary = {}
var fragments := 0
var restore_progress := 0.0
var dig_site: Dictionary = {}
var dig_progress := 0.0
var brush_progress := 0.0
var damage_progress := 0.0
var message_timer := 0.0
var controls_blocked_until_release := true
var hud_label: Label
var prompt_label: Label
var message_label: Label
var progress_label: Label
var fragment_label: Label
var _mouse_captured := false
var _ended := false
var _scare_triggered := false
var _scare_active := false
var _inner_mural: Node3D
var _revealed_mural: Node3D
var _mural_light: OmniLight3D
var _mural_caption_shown := false
var _ghost: Node3D
var _scare_audio: AudioStreamPlayer
var _tool: Node3D
var _tool_tween: Tween
var _tool_cooldown := 0.0
var _journal: Node3D
var _restored_grail: Node3D
var _dark_pulse: MeshInstance3D
var _energy_scar: Node3D
var _energy_scar_light: OmniLight3D
var _journal_read := false
var _particle_cooldown := 0.0
var _dig_held := false
var _brush_held := false
var _restore_held := false
var _move_forward := false
var _move_back := false
var _move_left := false
var _move_right := false


func _ready() -> void:
	_build_environment()
	_build_architecture()
	_build_story_clues()
	_build_excavation_sites()
	_build_artifacts()
	_build_restoration_and_final_chamber()
	_build_player()
	_build_scare_figure()
	_build_hud()
	_update_hud()


func set_controls_blocked(blocked: bool) -> void:
	controls_blocked_until_release = blocked


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.22, 0.23)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58.0, -26.0, 0.0)
	key_light.light_color = Color(0.62, 0.70, 0.78)
	key_light.light_energy = 0.32
	add_child(key_light)


func _build_architecture() -> void:
	_add_box("Temple floor", Vector3(0, -0.42, 0), Vector3(22, 0.8, 46), Color(0.25, 0.23, 0.20))
	_add_box("Left boundary", Vector3(-11.2, 2.1, 0), Vector3(0.8, 4.2, 46), Color(0.35, 0.31, 0.26))
	_add_box("Right boundary", Vector3(11.2, 2.1, 0), Vector3(0.8, 4.2, 46), Color(0.35, 0.31, 0.26))
	_add_box("Entrance wall", Vector3(0, 2.1, 22.7), Vector3(22, 4.2, 0.8), Color(0.35, 0.31, 0.26))
	_add_box("Outer lintel", Vector3(0, 2.1, -22.7), Vector3(22, 4.2, 0.8), Color(0.35, 0.31, 0.26))
	_add_box("Ruins ceiling ribs", Vector3(0, 4.0, -3.0), Vector3(21.5, 0.55, 0.7), Color(0.30, 0.27, 0.23), false)
	for z in [-12.0, -2.0, 8.5]:
		for x in [-8.8, 8.8]:
			_add_box("Broken arch pier", Vector3(x, 1.9, z), Vector3(1.5, 3.8, 1.5), Color(0.40, 0.35, 0.29))
		_add_box("Arch lintel", Vector3(0, 3.55, z), Vector3(17.6, 0.7, 1.5), Color(0.42, 0.36, 0.29), false)
	for x in [-7.8, 7.8]:
		_add_box("Restoration chamber pillar", Vector3(x, 1.7, 15.5), Vector3(1.3, 3.4, 1.3), Color(0.43, 0.36, 0.28))
	for z in [-20.0, -15.5, -4.0, 2.0, 11.0, 19.0]:
		_add_box("Floor seam", Vector3(0, 0.012, z), Vector3(20.0, 0.025, 0.08), Color(0.17, 0.16, 0.15), false)
	_add_point_light(Vector3(0, 3.0, -18.0), Color(1.0, 0.70, 0.36), 1.6, 7.0)
	_add_point_light(Vector3(0, 3.2, -4.0), Color(0.74, 0.56, 0.34), 1.2, 6.0)
	_add_point_light(Vector3(0, 3.2, 15.0), Color(0.50, 0.70, 0.88), 1.0, 7.0)


func _build_story_clues() -> void:
	# Corridor panels show the vessel in ceremony, then marked at four quarters.
	for i in 3:
		var z := -7.5 + float(i) * 4.2
		_add_box("Mural slab", Vector3(-10.55, 2.2, z), Vector3(0.12, 2.5, 3.5), Color(0.25, 0.20, 0.15), false)
		_add_box("Mural frame top", Vector3(-10.43, 3.43, z), Vector3(0.14, 0.12, 3.65), Color(0.70, 0.54, 0.31), false)
		_add_box("Mural frame base", Vector3(-10.43, 0.98, z), Vector3(0.14, 0.12, 3.65), Color(0.70, 0.54, 0.31), false)
		_add_box("Mural frame side A", Vector3(-10.43, 2.2, z - 1.77), Vector3(0.14, 2.5, 0.12), Color(0.70, 0.54, 0.31), false)
		_add_box("Mural frame side B", Vector3(-10.43, 2.2, z + 1.77), Vector3(0.14, 2.5, 0.12), Color(0.70, 0.54, 0.31), false)
		if i == 0:
			_add_sphere("Mural sun", Vector3(-10.3, 2.55, z), 0.48, Color(0.91, 0.67, 0.29), false)
			for j in 3:
				_add_box("Mural home", Vector3(-10.3, 1.55, z - 0.85 + float(j) * 0.85), Vector3(0.25, 0.55, 0.42), Color(0.73, 0.62, 0.43), false)
		elif i == 1:
			_add_sphere("Mural power", Vector3(-10.3, 2.4, z), 0.42, Color(0.38, 0.72, 0.91), false)
			for j in 3:
				_add_box("Mural worshipper", Vector3(-10.3, 1.5, z - 0.9 + float(j) * 0.9), Vector3(0.22, 0.7, 0.17), Color(0.76, 0.66, 0.49), false)
		else:
			_add_box("Mural fallen tower", Vector3(-10.3, 1.5, z - 0.5), Vector3(0.25, 1.1, 0.62), Color(0.50, 0.40, 0.29), false)
			_add_box("Mural broken tower", Vector3(-10.3, 1.35, z + 0.55), Vector3(0.25, 0.78, 0.48), Color(0.50, 0.40, 0.29), false)
			_add_box("Mural fracture", Vector3(-10.28, 2.1, z), Vector3(0.16, 0.08, 2.4), Color(0.40, 0.76, 0.94), false)
	# Broken Grail emblem over the abandoned entrance camp.
	for part in [Vector3(-0.55, 0.15, 0), Vector3(0.55, 0.15, 0), Vector3(-0.55, -0.42, 0), Vector3(0.55, -0.42, 0)]:
		_add_box("Broken emblem shard", Vector3(part.x, 2.5 + part.y, -22.15), Vector3(0.55, 0.48, 0.1), Color(0.75, 0.59, 0.31), false, Vector3(0, 0, part.x * 18.0))
	# Collapsed canvas, crates, abandoned journal, and the cursed relic by a pack.
	_add_box("Collapsed camp canvas", Vector3(-2.3, 0.72, -18.7), Vector3(3.2, 0.12, 2.3), Color(0.37, 0.31, 0.22), false, Vector3(0, 0, -28))
	_add_box("Camp crate", Vector3(-4.4, 0.35, -19.2), Vector3(0.9, 0.7, 0.8), Color(0.37, 0.27, 0.18))
	_add_box("Discarded trowel handle", Vector3(1.5, 0.15, -18.9), Vector3(0.08, 0.08, 1.2), Color(0.42, 0.30, 0.18), false, Vector3(0, 0, 35))
	_add_box("Trowel blade", Vector3(1.85, 0.11, -18.45), Vector3(0.33, 0.05, 0.3), Color(0.55, 0.56, 0.52), false, Vector3(0, 0, 35))
	_journal = _add_box("Explorer journal", Vector3(0.8, 0.12, -19.2), Vector3(0.52, 0.08, 0.72), Color(0.45, 0.31, 0.18), false, Vector3(0, 0, -15))
	_add_box("Abandoned pack", Vector3(8.9, 0.47, -16.5), Vector3(0.9, 0.95, 0.65), Color(0.34, 0.27, 0.20), false)
	# Scrape marks and a cracked, discarded pottery relic mark careless digging.
	for i in 3:
		_add_box("Excavation scrape", Vector3(-7.0 + i * 0.35, 0.035, -14.2 + i * 0.38), Vector3(1.2, 0.03, 0.06), Color(0.16, 0.13, 0.10), false, Vector3(0, 0, 18))
	_add_box("Cracked relic", Vector3(-5.7, 0.2, -13.7), Vector3(0.5, 0.32, 0.42), Color(0.48, 0.24, 0.18), false, Vector3(0, 0, 24))
	_add_sphere("Broken statue head", Vector3(6.0, 0.42, -2.3), 0.55, Color(0.37, 0.33, 0.28), false)
	_add_box("Broken statue torso", Vector3(7.0, 0.28, -2.6), Vector3(1.4, 0.55, 0.9), Color(0.34, 0.30, 0.25), false, Vector3(0, 0, 22))
	_energy_scar = _add_box("Energy scar", Vector3(-3.0, 0.03, 0.5), Vector3(0.08, 0.04, 5.0), Color(0.30, 0.62, 0.81), false, Vector3(0, 0, -31))
	_energy_scar_light = _add_point_light(Vector3(-3.0, 0.28, 0.5), Color(0.30, 0.68, 0.88), 0.0, 4.0)
	_build_inner_mural()


func _build_inner_mural() -> void:
	_inner_mural = Node3D.new()
	_inner_mural.name = "Damaged Grail mural"
	_inner_mural.position = Vector3(0, 2.5, 9.7)
	add_child(_inner_mural)
	_add_box("Mural panel", Vector3.ZERO, Vector3(9.0, 3.1, 0.18), Color(0.24, 0.20, 0.16), false, Vector3.ZERO, _inner_mural)
	_add_box("Mural caption band", Vector3(0, -1.18, -0.12), Vector3(8.6, 0.34, 0.08), Color(0.37, 0.30, 0.22), false, Vector3.ZERO, _inner_mural)
	# Vessel, four separate shards, and four hands pulling outward.
	_add_cylinder("Mural vessel bowl", Vector3(0, 0.1, -0.14), 0.62, 0.48, Color(0.79, 0.60, 0.31), false, Vector3.ZERO, _inner_mural)
	_add_cylinder("Mural vessel stem", Vector3(0, -0.38, -0.14), 0.11, 0.42, Color(0.79, 0.60, 0.31), false, Vector3.ZERO, _inner_mural)
	_add_cylinder("Mural vessel foot", Vector3(0, -0.63, -0.14), 0.38, 0.12, Color(0.79, 0.60, 0.31), false, Vector3.ZERO, _inner_mural)
	for side in [-1.0, 1.0]:
		_add_box("Mural separating figure", Vector3(side * 2.3, -0.25, -0.14), Vector3(0.28, 0.9, 0.08), Color(0.69, 0.61, 0.47), false, Vector3(0, 0, side * -10.0), _inner_mural)
		_add_box("Mural outstretched arm", Vector3(side * 1.35, 0.08, -0.15), Vector3(1.2, 0.11, 0.07), Color(0.69, 0.61, 0.47), false, Vector3(0, 0, side * -16.0), _inner_mural)
	for shard in [Vector3(-0.95, 0.42, -0.2), Vector3(0.95, 0.42, -0.2), Vector3(-0.82, -0.48, -0.2), Vector3(0.82, -0.48, -0.2)]:
		_add_box("Mural separated shard", shard, Vector3(0.28, 0.34, 0.07), Color(0.57, 0.48, 0.35), false, Vector3(0, 0, 28), _inner_mural)
	_revealed_mural = Node3D.new()
	_revealed_mural.name = "Mural protection reveal"
	_revealed_mural.position = _inner_mural.position
	_revealed_mural.visible = false
	add_child(_revealed_mural)
	_add_box("Protective mural circle left", Vector3(-3.25, -0.05, -0.25), Vector3(0.12, 2.25, 0.08), Color(0.45, 0.78, 0.86), false, Vector3(0, 0, -24), _revealed_mural)
	_add_box("Protective mural circle right", Vector3(3.25, -0.05, -0.25), Vector3(0.12, 2.25, 0.08), Color(0.45, 0.78, 0.86), false, Vector3(0, 0, 24), _revealed_mural)
	_add_box("Protective mural base", Vector3(0, -1.12, -0.25), Vector3(6.2, 0.12, 0.08), Color(0.45, 0.78, 0.86), false, Vector3.ZERO, _revealed_mural)
	_mural_light = _add_point_light(Vector3(0, 3.1, 9.0), Color(0.43, 0.71, 0.90), 0.0, 8.0)


func _build_excavation_sites() -> void:
	var positions := [Vector3(-7.0, 0.0, -14.5), Vector3(6.5, 0.0, -7.5), Vector3(-6.0, 0.0, 0.5), Vector3(5.5, 0.0, 6.5)]
	var inscriptions := ["Four pieces. One forgotten warning.", "They feared what the vessel held.", "To protect them, it was divided.", "The seal was never meant to break."]
	var fragment_colors := [Color(0.35, 0.76, 0.85), Color(0.82, 0.61, 0.32), Color(0.61, 0.51, 0.79), Color(0.42, 0.80, 0.66)]
	for i in positions.size():
		var root := Node3D.new()
		root.name = "Fragment dig site %d" % (i + 1)
		root.position = positions[i]
		add_child(root)
		var mound := _add_cylinder("Soil mound", Vector3(0, 0.06, 0), 0.74, 0.14, Color(0.28, 0.20, 0.13), false, Vector3.ZERO, root)
		_add_box("Burial mark", Vector3(0, 0.15, 0), Vector3(0.75, 0.035, 0.06), Color(0.85, 0.68, 0.33), false, Vector3(0, 0, 45), root)
		_add_box("Burial mark cross", Vector3(0, 0.16, 0), Vector3(0.75, 0.035, 0.06), Color(0.85, 0.68, 0.33), false, Vector3(0, 90, 45), root)
		var fragment := _make_fragment_mesh(fragment_colors[i], i + 1)
		fragment.position = Vector3(0, 0.6, 0)
		fragment.visible = false
		root.add_child(fragment)
		var dirt_particles := _make_dirt_particles()
		root.add_child(dirt_particles)
		sites.append({"id": i + 1, "node": root, "fragment": fragment, "mound": mound, "layers": 2, "state": "buried", "damage": 0.0, "pulse": 0.0, "inscription": inscriptions[i], "particles": dirt_particles})


func _build_artifacts() -> void:
	_add_artifact("Sun Charm", "This relic brightens the path. Its weight feels strange.", Vector3(8.9, 0.25, -12.8), Color(0.91, 0.69, 0.32), 1.35, 1.0, false)
	_add_artifact("Pilgrim Sandals", "Worn leather, threaded with gold.", Vector3(-9.0, 0.25, -5.7), Color(0.81, 0.61, 0.29), 1.0, 1.3, false)
	_add_artifact("Obsidian Idol", "The stone drinks the light around it.", Vector3(8.9, 0.25, -1.8), Color(0.47, 0.36, 0.67), 0.58, 0.82, true)
	_add_artifact("Lead Anklet", "Tiny footprints circle its cold surface.", Vector3(-9.5, 0.25, 3.4), Color(0.53, 0.42, 0.63), 1.0, 0.58, true)
	_add_artifact("Gilded Mask", "The face is warm. Something stirs within.", Vector3(8.9, 0.25, -16.1), Color(0.86, 0.68, 0.29), 1.0, 0.55, true)


func _build_restoration_and_final_chamber() -> void:
	_add_cylinder("Restoration dais", Vector3(0, 0.18, 15.0), 2.4, 0.36, Color(0.40, 0.34, 0.27), false)
	_add_cylinder("Dais inlay", Vector3(0, 0.39, 15.0), 1.65, 0.08, Color(0.79, 0.63, 0.34), false)
	_add_cylinder("Empty grail socket", Vector3(0, 0.52, 15.0), 0.62, 0.18, Color(0.21, 0.24, 0.24), false)
	_add_point_light(Vector3(0, 2.4, 15.0), Color(0.44, 0.70, 0.88), 0.3, 4.0)
	_restored_grail = _make_grail_mesh()
	_restored_grail.position = Vector3(0, 0.7, 15.0)
	_restored_grail.scale = Vector3.ZERO
	_restored_grail.visible = false
	add_child(_restored_grail)
	var pulse_mesh := SphereMesh.new()
	pulse_mesh.radius = 0.5
	pulse_mesh.height = 1.0
	_dark_pulse = MeshInstance3D.new()
	_dark_pulse.name = "Ominous restoration pulse"
	_dark_pulse.mesh = pulse_mesh
	_dark_pulse.position = Vector3(0, 1.0, 15.0)
	var pulse_material := StandardMaterial3D.new()
	pulse_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse_material.albedo_color = Color(0.035, 0.025, 0.055, 0.45)
	pulse_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dark_pulse.material_override = pulse_material
	_dark_pulse.visible = false
	add_child(_dark_pulse)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Explorer"
	player.position = Vector3(0, 0.08, -20.0)
	player.rotation.y = PI
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.88
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 0)
	camera.current = true
	player.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0, 0, -0.15)
	flashlight.light_color = Color(0.86, 0.91, 1.0)
	flashlight.light_energy = 4.0
	flashlight.spot_range = 22.0
	flashlight.spot_angle = 52.0
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	_build_trowel()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud_label = _label("RECOVER THE FOUR FRAGMENTS", 19, Color(1.0, 0.84, 0.54))
	hud_label.position = Vector2(24, 20)
	hud_label.size = Vector2(410, 66)
	root.add_child(hud_label)
	fragment_label = _label("FRAGMENTS  0 / 4", 15, Color(0.91, 0.9, 0.84))
	fragment_label.position = Vector2(24, 88)
	fragment_label.size = Vector2(310, 34)
	root.add_child(fragment_label)
	message_label = _label("", 19, Color(0.93, 0.85, 0.64), HORIZONTAL_ALIGNMENT_CENTER)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-380, 120)
	message_label.size = Vector2(760, 54)
	message_label.visible = false
	root.add_child(message_label)
	progress_label = _label("", 16, Color(0.80, 0.91, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	progress_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	progress_label.position = Vector2(-300, -100)
	progress_label.size = Vector2(600, 36)
	root.add_child(progress_label)
	prompt_label = _label("", 17, Color(1.0, 0.87, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-450, -58)
	prompt_label.size = Vector2(900, 48)
	root.add_child(prompt_label)
	var crosshair := _label("+", 28, Color(1.0, 0.94, 0.77), HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -19)
	crosshair.size = Vector2(24, 36)
	root.add_child(crosshair)


func _label(copy: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = copy
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.02, 0.95))
	result.add_theme_constant_override("outline_size", 4)
	return result


func _process(delta: float) -> void:
	_tool_cooldown = maxf(0.0, _tool_cooldown - delta)
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_label.visible = false
	if _ended:
		return
	_update_hud()
	for site in sites:
		if site["state"] == "buried":
			site["pulse"] = fposmod(site["pulse"] + delta, TAU)
			var mark: MeshInstance3D = site["node"].get_node("Burial mark/Visual")
			var material: StandardMaterial3D = mark.material_override
			material.emission_energy_multiplier = 0.25 + 0.3 * (0.5 + 0.5 * sin(site["pulse"]))
	for artifact in artifacts:
		var node: Node3D = artifact["node"]
		if artifact != carried:
			node.position.y = 0.25 + sin(Time.get_ticks_msec() * 0.002 + artifact["phase"]) * 0.08
			node.rotate_y(delta * 0.45)


func _physics_process(delta: float) -> void:
	if _ended:
		return
	if state == State.RESTORING:
		return
	if controls_blocked_until_release:
		if _gameplay_controls_held():
			return
		controls_blocked_until_release = false
	var axes := Vector2.ZERO
	if _move_right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axes.x += 1.0
	if _move_left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axes.x -= 1.0
	if _move_back or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		axes.y += 1.0
	if _move_forward or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		axes.y -= 1.0
	var forward := -player.global_basis.z
	var right := player.global_basis.x
	var movement := (right * axes.x - forward * axes.y).normalized()
	var carried_speed := float(carried.get("speed", 1.0)) if not carried.is_empty() and (not carried.get("delayed", false) or carried.get("active", false)) else 1.0
	var speed := MOVE_SPEED * carried_speed
	player.velocity.x = movement.x * speed
	player.velocity.z = movement.z * speed
	if _dig_held and not _nearest_site().is_empty():
		player.velocity.x = 0.0
		player.velocity.z = 0.0
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	else:
		player.velocity.y = -0.1
	player.move_and_slide()
	_handle_excavation(delta)
	_handle_restoration(delta)
	_check_story_proximity()
	if carried.is_empty() == false:
		carried["node"].global_position = camera.global_position + (-camera.global_basis.z * 0.7) + Vector3(0, -0.25, 0)
		if carried.get("delayed", false):
			carried["carry_time"] += delta
			if carried["carry_time"] >= 15.0 and not carried["active"]:
				carried["active"] = true
				carried["speed"] = carried["base_speed"]
				carried["light"] = carried["base_light"]
				flashlight.light_energy = 4.0 * float(carried["light"])
				_show_message("The relic slows your steps.", 2.5, true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			_move_forward = event.pressed
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			_move_back = event.pressed
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			_move_left = event.pressed
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			_move_right = event.pressed
		elif event.keycode == KEY_E:
			_dig_held = event.pressed
		elif event.keycode == KEY_R:
			_brush_held = event.pressed
		elif event.keycode == KEY_G:
			_restore_held = event.pressed
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true
	elif event is InputEventMouseMotion and _mouse_captured and not _ended:
		player.rotation.y -= event.relative.x * 0.0025
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.002, deg_to_rad(-42.0), deg_to_rad(18.0))
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
		elif event.keycode == KEY_F:
			_interact()


func _handle_excavation(delta: float) -> void:
	var nearby := _nearest_site()
	var e_held := _dig_held
	var r_held := _brush_held
	if nearby.is_empty() or nearby["state"] == "done":
		dig_site = {}
		dig_progress = 0.0
		brush_progress = 0.0
		damage_progress = 0.0
		return
	if r_held and nearby["state"] == "brush":
		_animate_trowel(true)
		brush_progress += delta
		if brush_progress >= BRUSH_TIME:
			brush_progress = 0.0
			if nearby["layers"] <= 0:
				_collect_fragment(nearby)
			else:
				nearby["state"] = "buried"
		return
	if e_held and nearby["state"] == "brush":
		damage_progress += delta
		if damage_progress >= DAMAGE_GRACE:
			nearby["state"] = "damaged"
			state = State.LOST
			_ended = true
			ending_text = "A fragment is broken. The Grail cannot be restored."
			game_ended.emit(false)
		return
	if e_held and nearby["state"] == "buried":
		if dig_site != nearby:
			dig_site = nearby
			dig_progress = 0.0
		dig_progress += delta
		_animate_trowel(false)
		_particle_cooldown -= delta
		if _particle_cooldown <= 0.0:
			_spawn_dirt(nearby)
			_particle_cooldown = 0.16
		var mound_base := 1.0 if int(nearby["layers"]) >= 2 else 0.55
		nearby["mound"].scale.y = maxf(0.18, mound_base - (dig_progress / DIG_TIME) * 0.45)
		if dig_progress >= DIG_TIME:
			dig_progress = 0.0
			nearby["layers"] -= 1
			nearby["state"] = "brush"
			nearby["mound"].scale.y = 0.55 if nearby["layers"] > 0 else 0.3
			_show_message("Brush before digging deeper.", 1.8)
	else:
		dig_progress = 0.0
		damage_progress = 0.0
		if nearby["state"] == "buried":
			nearby["mound"].scale.y = 1.0 if int(nearby["layers"]) >= 2 else 0.55


func _handle_restoration(delta: float) -> void:
	if state != State.EXPLORING:
		return
	if fragments == 4 and _near_plinth() and _restore_held:
		restore_progress += delta
		if restore_progress >= RESTORE_TIME:
			_restore_grail()
	else:
		restore_progress = 0.0


func _collect_fragment(site: Dictionary) -> void:
	if site["state"] != "brush" or site["layers"] > 0:
		return
	site["state"] = "done"
	site["fragment"].visible = true
	var fragment_tween := create_tween()
	fragment_tween.tween_property(site["fragment"], "position:y", 0.32, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	site["node"].get_node("Soil mound").visible = false
	fragments += 1
	fragment_label.text = "Fragments: %d/4" % fragments
	var scar_material := (_energy_scar.get_node("Visual") as MeshInstance3D).material_override as StandardMaterial3D
	scar_material.emission_enabled = true
	scar_material.emission = Color(0.30, 0.68, 0.88)
	scar_material.emission_energy_multiplier = 0.35 + float(fragments) * 0.3
	_energy_scar_light.light_energy = 0.2 + float(fragments) * 0.25
	_show_message(site["inscription"], 3.0)
	site["node"].get_node("Burial mark").visible = false
	site["node"].get_node("Burial mark cross").visible = false


func _restore_grail() -> void:
	if state != State.EXPLORING or fragments != 4:
		return
	state = State.RESTORING
	_restored_grail.visible = true
	_revealed_mural.visible = true
	_mural_light.light_energy = 2.8
	_dark_pulse.visible = true
	_dark_pulse.scale = Vector3(0.1, 0.1, 0.1)
	var reveal := create_tween()
	reveal.set_parallel(true)
	reveal.tween_property(_restored_grail, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(_dark_pulse, "scale", Vector3(5.0, 5.0, 5.0), 0.75)
	var pulse_material := _dark_pulse.material_override as StandardMaterial3D
	reveal.tween_property(pulse_material, "albedo_color:a", 0.0, 0.9)
	for site in sites:
		site["fragment"].visible = false
	await get_tree().create_timer(1.8).timeout
	world_environment.environment.ambient_light_color = Color(0.30, 0.37, 0.36)
	key_light.light_energy = 0.22
	_dark_pulse.visible = false
	state = State.WON
	_ended = true
	ending_text = "The Grail is whole. The expedition succeeds."
	game_ended.emit(true)


func _interact() -> void:
	if _ended:
		return
	if not carried.is_empty():
		carried["node"].global_position = player.global_position + Vector3(1.0, 0.12, -0.2)
		carried["node"].visible = true
		carried["light"] = carried["base_light"]
		carried["speed"] = carried["base_speed"]
		carried["active"] = not carried["delayed"]
		carried["carry_time"] = 0.0
		carried = {}
		flashlight.light_energy = 4.0
		_show_message("Relic dropped.", 1.5)
		return
	if not _journal_read and player.global_position.distance_to(_journal.global_position) < 1.8:
		_journal_read = true
		_show_message("We came for the Grail. Four pieces remain beneath this temple. Dig carefully.", 3.6)
		return
	var artifact := _nearest_artifact()
	if artifact.is_empty():
		return
	carried = artifact
	artifact["node"].visible = false
	artifact["carry_time"] = 0.0
	if artifact["light"] > 1.0:
		flashlight.light_energy = 5.0
		_show_message("THE CHARM WARMS — YOUR LIGHT REACHES FARTHER", 2.7)
	elif artifact["speed"] > 1.0:
		_show_message("THE THREAD LIGHTENS YOUR STEP", 2.7)
	elif artifact["delayed"]:
		_show_message("THE MASK IS WARM. SOMETHING STIRS WITHIN.", 2.7)
	else:
		flashlight.light_energy = 2.3
		_show_message("THE RELIC DRAWS THE LIGHT INWARD", 2.7, true)


func _update_hud() -> void:
	if state == State.RESTORING:
		hud_label.text = "THE VESSEL REMEMBERS"
		prompt_label.text = ""
	elif fragments == 4:
		hud_label.text = "RETURN TO THE RESTORATION ALTAR"
		prompt_label.text = "Hold G to restore the Grail." if _near_plinth() else ""
	elif state == State.LOST:
		hud_label.text = "FRAGMENT SHATTERED"
		prompt_label.text = ""
	else:
		hud_label.text = "RECOVER THE FOUR FRAGMENTS"
		var site := _nearest_site()
		if not site.is_empty():
			if site["state"] == "buried":
				prompt_label.text = "Hold E to dig"
			elif site["state"] == "brush":
				prompt_label.text = "Hold R to brush"
			elif site["state"] == "damaged":
				prompt_label.text = "FRAGMENT SHATTERED"
			else:
				prompt_label.text = ""
		else:
			var artifact := _nearest_artifact()
			if not artifact.is_empty() and carried.is_empty():
				prompt_label.text = "F • Take relic"
			elif not carried.is_empty():
				prompt_label.text = "F • Drop relic"
			elif not _journal_read and player.global_position.distance_to(_journal.global_position) < 1.8:
				prompt_label.text = "F • Read journal"
			else:
				prompt_label.text = ""
	var step := ""
	if dig_progress > 0.0:
		step = "DIG  %d%%" % int(dig_progress / DIG_TIME * 100.0)
	elif brush_progress > 0.0:
		step = "BRUSH  %d%%" % int(brush_progress / BRUSH_TIME * 100.0)
	elif restore_progress > 0.0:
		step = "RESTORE  %d%%" % int(restore_progress / RESTORE_TIME * 100.0)
	progress_label.text = step
	if fragment_label != null:
		fragment_label.text = "Fragments: %d/4" % fragments


func _nearest_site() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 1.8
	for site in sites:
		if site["state"] == "done" or site["state"] == "damaged":
			continue
		var distance: float = player.global_position.distance_to(site["node"].global_position)
		if distance < best_distance:
			best_distance = distance
			best = site
	return best


func _nearest_artifact() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 1.7
	for artifact in artifacts:
		if artifact == carried or not artifact["node"].visible:
			continue
		var distance: float = player.global_position.distance_to(artifact["node"].global_position)
		if distance < best_distance:
			best_distance = distance
			best = artifact
	return best


func _nearest_plinth() -> bool:
	return player.global_position.distance_to(Vector3(0, 0, 15.0)) < 2.8


func _near_plinth() -> bool:
	return _nearest_plinth()


func _gameplay_controls_held() -> bool:
	for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_E, KEY_R, KEY_G, KEY_F]:
		if Input.is_key_pressed(key):
			return true
	return false


func _show_message(copy: String, duration: float = 2.5, danger: bool = false) -> void:
	message_label.text = copy
	message_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.48) if danger else Color(0.97, 0.85, 0.61))
	message_label.visible = true
	message_timer = duration


func _add_box(label: String, pos: Vector3, dimensions: Vector3, color: Color, solid: bool = true, rotation_degrees: Vector3 = Vector3.ZERO, parent: Node = self) -> Node3D:
	var holder: Node3D
	if solid:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	holder.name = label
	holder.position = pos
	holder.rotation_degrees = rotation_degrees
	parent.add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _stone_material(color)
	holder.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		holder.add_child(collision)
	return holder


func _add_cylinder(label: String, pos: Vector3, radius: float, height: float, color: Color, solid: bool = true, rotation_degrees: Vector3 = Vector3.ZERO, parent: Node = self) -> Node3D:
	var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
	holder.name = label
	holder.position = pos
	holder.rotation_degrees = rotation_degrees
	parent.add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.88
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _stone_material(color)
	holder.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		holder.add_child(collision)
	return holder


func _add_sphere(label: String, pos: Vector3, radius: float, color: Color, solid: bool = true) -> Node3D:
	var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
	holder.name = label
	holder.position = pos
	add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _stone_material(color)
	holder.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = radius
		collision.shape = shape
		holder.add_child(collision)
	return holder


func _add_point_light(pos: Vector3, tint: Color, energy: float, range: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = range
	light.shadow_enabled = true
	add_child(light)
	return light


func _add_artifact(item_name: String, description: String, pos: Vector3, tint: Color, light_mult: float, speed_mult: float, delayed: bool) -> void:
	var root := Node3D.new()
	root.name = item_name
	root.position = pos
	add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.72, 0.9, 0.55)
	mesh_instance.mesh = mesh
	var material := _stone_material(tint)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.55
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = 0.38
	light.omni_range = 2.8
	root.add_child(light)
	artifacts.append({"name": item_name, "description": description, "node": root, "light": light_mult, "speed": speed_mult, "base_light": light_mult, "base_speed": speed_mult, "delayed": delayed, "active": not delayed, "carry_time": 0.0, "phase": randf() * TAU})


func _make_fragment_mesh(tint: Color, fragment_id: int) -> Node3D:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh: Mesh = PrismMesh.new() if fragment_id % 2 == 1 else BoxMesh.new()
	if mesh is PrismMesh:
		(mesh as PrismMesh).size = Vector3(0.85, 0.4, 0.72)
	else:
		(mesh as BoxMesh).size = Vector3(0.68, 0.48, 0.62)
	if fragment_id == 2 or fragment_id == 4:
		mesh_instance.rotation_degrees.y = 45.0
	mesh_instance.mesh = mesh
	var material := _stone_material(tint)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 1.0
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	var light := OmniLight3D.new()
	light.position.y = 0.3
	light.light_color = tint
	light.light_energy = 0.8
	light.omni_range = 3.0
	root.add_child(light)
	return root


func _build_trowel() -> void:
	_tool = Node3D.new()
	_tool.name = "First person trowel"
	_tool.position = Vector3(0.38, -0.34, -0.65)
	_tool.rotation_degrees = Vector3(-18, 8, -24)
	camera.add_child(_tool)
	var handle := _add_box("Wooden grip", Vector3(0, -0.10, 0.12), Vector3(0.09, 0.34, 0.10), Color(0.37, 0.22, 0.13), false, Vector3(-12, 0, 0), _tool)
	_add_box("Trowel shaft", Vector3(0, 0.10, 0.0), Vector3(0.055, 0.28, 0.055), Color(0.55, 0.40, 0.23), false, Vector3(-20, 0, 0), _tool)
	_add_box("Trowel blade", Vector3(0, 0.27, -0.03), Vector3(0.24, 0.26, 0.035), Color(0.55, 0.61, 0.60), false, Vector3(-20, 0, 0), _tool)
	_tool.set_meta("rest_position", _tool.position)


func _animate_trowel(brush: bool) -> void:
	if _tool == null or _tool_cooldown > 0.0:
		return
	_tool_cooldown = 0.28
	if _tool_tween and _tool_tween.is_running():
		_tool_tween.kill()
	_tool.position = _tool.get_meta("rest_position")
	_tool_tween = create_tween()
	_tool_tween.tween_property(_tool, "position:y", -0.56 if brush else -0.49, 0.11)
	_tool_tween.tween_property(_tool, "position:y", -0.34, 0.16)


func _make_dirt_particles() -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "Dirt particles"
	particles.position.y = 0.24
	particles.amount = 14
	particles.lifetime = 0.42
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 0.9
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 55.0
	particles.gravity = Vector3(0, -3.5, 0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.6
	particles.scale_amount_min = 0.035
	particles.scale_amount_max = 0.09
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var dust_material := StandardMaterial3D.new()
	dust_material.albedo_color = Color(0.46, 0.32, 0.20)
	mesh.surface_set_material(0, dust_material)
	particles.mesh = mesh
	return particles


func _make_grail_mesh() -> Node3D:
	var root := Node3D.new()
	root.name = "Restored Holy Grail"
	var gold := Color(0.91, 0.69, 0.32)
	_add_cylinder("Grail cup", Vector3(0, 0.46, 0), 0.44, 0.42, gold, false, Vector3.ZERO, root)
	_add_cylinder("Grail stem", Vector3(0, 0.16, 0), 0.09, 0.35, gold, false, Vector3.ZERO, root)
	_add_cylinder("Grail foot", Vector3(0, -0.02, 0), 0.3, 0.12, gold, false, Vector3.ZERO, root)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.92, 0.68, 0.34)
	glow.light_energy = 1.8
	glow.omni_range = 5.0
	root.add_child(glow)
	return root


func _spawn_dirt(site: Dictionary) -> void:
	var particles: CPUParticles3D = site["particles"]
	particles.restart()
	particles.emitting = true


func _build_scare_figure() -> void:
	_ghost = Node3D.new()
	_ghost.name = "Brief apparition"
	_ghost.visible = false
	add_child(_ghost)
	var shadow_material := StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0.018, 0.014, 0.026, 0.94)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for data in [[Vector3(0, 1.05, 0), Vector3(0.48, 1.25, 0.18)], [Vector3(0, 1.93, 0), Vector3(0.35, 0.38, 0.3)], [Vector3(-0.42, 0.9, 0), Vector3(0.18, 0.9, 0.16)], [Vector3(0.42, 0.9, 0), Vector3(0.18, 0.9, 0.16)]]:
		var part := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = data[1]
		part.mesh = mesh
		part.position = data[0]
		part.material_override = shadow_material
		_ghost.add_child(part)
	_scare_audio = AudioStreamPlayer.new()
	_scare_audio.volume_db = -12.0
	_scare_audio.stream = _make_scare_sound()
	add_child(_scare_audio)


func _make_scare_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	for i in 4200:
		var t := float(i) / 22050.0
		var envelope := (1.0 - float(i) / 4200.0) * 0.35
		var sample := int(clampf(sin(TAU * (150.0 - 95.0 * t) * t) * envelope, -1.0, 1.0) * 32767.0)
		samples.append(sample & 0xff)
		samples.append((sample >> 8) & 0xff)
	stream.data = samples
	return stream


func _check_story_proximity() -> void:
	if _scare_triggered or _ended:
		return
	var at_mural := player.global_position.distance_to(Vector3(0, 0, 9.7)) < 2.8
	var at_relic := player.global_position.distance_to(Vector3(8.9, 0, -16.1)) < 2.0
	if not at_mural and not at_relic:
		return
	_scare_triggered = true
	_scare_active = true
	flashlight.visible = false
	_ghost.global_position = camera.global_position + (-camera.global_basis.z * 1.5)
	_ghost.look_at(camera.global_position, Vector3.UP)
	_ghost.visible = true
	_scare_audio.play()
	await get_tree().create_timer(0.10).timeout
	flashlight.visible = true
	await get_tree().create_timer(0.07).timeout
	flashlight.visible = false
	await get_tree().create_timer(0.10).timeout
	flashlight.visible = true
	await get_tree().create_timer(0.43).timeout
	_ghost.visible = false
	_scare_active = false


func _stone_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.92
	return material
