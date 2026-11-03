extends Node3D
## Compact 3D playtest chapter. The original 2D scene remains available as a fallback.

signal game_ended(victory: bool)

const DIG_TIME := 3.0
const BRUSH_TIME := 1.5
const DAMAGE_GRACE := 0.4
const RESTORE_TIME := 3.0
const MOVE_SPEED := 4.3
const SANDSTONE_TEXTURE: Texture2D = preload("res://art_sandstone.png")
const RITUAL_FRESCO: Texture2D = preload("res://murals/ritual_fresco.png")
const CURSE_FRESCO: Texture2D = preload("res://murals/curse_fresco.png")
const DIVISION_FRESCO: Texture2D = preload("res://murals/division_fresco.png")
const REVEAL_FRESCO: Texture2D = preload("res://murals/reveal_fresco.png")

enum State { EXPLORING, RESTORING, WON, LOST }
enum StoryStage { INTRODUCTION, DISCOVERY, SUSPICION, TWIST, RESTORATION }

var state: int = State.EXPLORING
var story_stage: int = StoryStage.INTRODUCTION
var story_clues_seen := {"sanctuary": false, "curse": false, "division": false}
var story_clues: Array[Dictionary] = []
var ending_text := ""
var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var sites: Array[Dictionary] = []
var fragment_records: Array[Dictionary] = []
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
var _revealed_mural: Node3D
var _mural_light: OmniLight3D
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
var _fragment_popup: Control
var _fragment_popup_timer := 0.0
var _fragment_popup_open := false
var _fragment_pickup_active := false
var _journal_panel: Control
var _journal_open := false
var _journal_slots: Array[Label] = []
var _player_capsule: CapsuleShape3D
var _player_collision: CollisionShape3D
var _crouch_held := false
var _crouched := false
var _sanctuary_orb: Node3D
var _sanctuary_orb_light: OmniLight3D
var _sanctuary_door: StaticBody3D
var _sanctuary_door_collision: CollisionShape3D
var _sanctuary_sigil_lights: Array[OmniLight3D] = []
var _sanctuary_sigil_materials: Array[StandardMaterial3D] = []
var _door_audio: AudioStreamPlayer
var _crack_seal: StaticBody3D
var _crack_seal_collision: CollisionShape3D
var _crack_light: OmniLight3D
var _crack_open := false
var _door_open := false
var _division_mural: Node3D
var _division_mural_light: OmniLight3D
var _curse_mural: Node3D
var _restoration_audio: AudioStreamPlayer


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
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.27, 0.24, 0.20)
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.0
	world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58.0, -26.0, 0.0)
	key_light.light_color = Color(0.62, 0.70, 0.78)
	key_light.light_energy = 0.32
	add_child(key_light)


func _build_architecture() -> void:
	# Five legible chambers with broad, aligned thresholds and clear return routes.
	_room(Vector2(0, -18), Vector2(14, 12), "Camp", {"north": 0.0, "east": 0.0})
	_room(Vector2(14, -6), Vector2(12, 12), "Sanctuary", {"north": -5.0, "south": 0.0})
	_room(Vector2(0, 7), Vector2(12, 12), "Shattered hall", {"east": 0.0, "west": 4.0})
	_room(Vector2(-14, 18), Vector2(12, 18), "Dividing chamber", {"east": -7.0, "south": 0.0})
	_room(Vector2(-14, 36), Vector2(14, 14), "Restoration altar", {"north": 0.0})
	_hall_z(9.0, -18.0, -12.0)
	_hall_z(14.0, 0.0, 4.0)
	# One wide, easy-to-read turn connects the sanctuary to Room 3.
	_hall_x(6.0, 14.0, 7.0)
	# The hidden fissure is a short, deliberate crouch passage into Room 4.
	_hall_x(-8.0, -6.0, 11.0)
	_hall_z(-14.0, 27.0, 29.0)
	# Low rubble marks the fissure ceiling. Crouch (C) is required to pass safely.
	_add_box("Fissure low lintel", Vector3(-7.0, 1.31, 11.0), Vector3(2.2, 0.26, 3.45), Color(0.30, 0.27, 0.24))
	# Functional sliding threshold for the sanctuary mechanism.
	_sanctuary_door = StaticBody3D.new()
	_sanctuary_door.name = "Sanctuary sealed door"
	_sanctuary_door.position = Vector3(6.0, 1.65, 7.0)
	add_child(_sanctuary_door)
	var door_visual := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.7, 3.3, 3.35)
	door_visual.mesh = door_mesh
	var door_material := _stone_material(Color(0.30, 0.31, 0.30))
	door_material.emission_enabled = true
	door_material.emission = Color(0.38, 0.56, 0.56)
	door_material.emission_energy_multiplier = 0.12
	door_visual.material_override = door_material
	_sanctuary_door.add_child(door_visual)
	_sanctuary_door_collision = CollisionShape3D.new()
	var door_shape := BoxShape3D.new()
	door_shape.size = door_mesh.size
	_sanctuary_door_collision.shape = door_shape
	_sanctuary_door.add_child(_sanctuary_door_collision)
	# Hidden passage seal, disguised as a cracked wall slab until investigated.
	_crack_seal = StaticBody3D.new()
	_crack_seal.name = "Cracked wall seal"
	_crack_seal.position = Vector3(-6.0, 1.6, 11.0)
	add_child(_crack_seal)
	var seal_visual := MeshInstance3D.new()
	var seal_mesh := BoxMesh.new()
	seal_mesh.size = Vector3(0.55, 3.2, 3.35)
	seal_visual.mesh = seal_mesh
	seal_visual.material_override = _stone_material(Color(0.31, 0.29, 0.25))
	_crack_seal.add_child(seal_visual)
	_crack_seal_collision = CollisionShape3D.new()
	var seal_shape := BoxShape3D.new()
	seal_shape.size = seal_mesh.size
	_crack_seal_collision.shape = seal_shape
	_crack_seal.add_child(_crack_seal_collision)
	_crack_light = _add_point_light(Vector3(-5.4, 1.6, 11.0), Color(0.32, 0.74, 0.88), 0.0, 4.0)
	var crack_line := _add_box("Unnatural crack seam", Vector3(-5.55, 1.55, 11.0), Vector3(0.035, 2.8, 0.13), Color(0.31, 0.66, 0.79), false, Vector3(0, 0, 6))
	var crack_material := (crack_line.get_node("Visual") as MeshInstance3D).material_override as StandardMaterial3D
	crack_material.emission_enabled = true
	crack_material.emission = Color(0.25, 0.65, 0.85)
	crack_material.emission_energy_multiplier = 0.65
	_add_point_light(Vector3(0, 3, -18), Color(1.0, 0.70, 0.36), 1.0, 7.0)
	_add_point_light(Vector3(14, 3, -6), Color(0.88, 0.67, 0.36), 1.0, 7.0)
	_add_point_light(Vector3(0, 3, 7), Color(0.52, 0.68, 0.80), 0.6, 6.0)
	_add_point_light(Vector3(-14, 3, 18), Color(0.48, 0.66, 0.83), 0.55, 6.0)
	_add_point_light(Vector3(-14, 3, 36), Color(0.45, 0.68, 0.86), 0.35, 6.0)


func _room(center: Vector2, size: Vector2, label: String, openings: Dictionary) -> void:
	var x0 := center.x - size.x / 2.0
	var x1 := center.x + size.x / 2.0
	var z0 := center.y - size.y / 2.0
	var z1 := center.y + size.y / 2.0
	var c := Color(0.36, 0.32, 0.27)
	_add_box(label + " floor", Vector3(center.x, -0.4, center.y), Vector3(size.x, 0.8, size.y), Color(0.25, 0.23, 0.20))
	_add_box(label + " ceiling", Vector3(center.x, 4, center.y), Vector3(size.x, 0.5, size.y), Color(0.19, 0.18, 0.17), false)
	# Every side is built from two blocks around a 3.6m real doorway.
	for side in ["north", "south", "east", "west"]:
		var open := openings.has(side)
		var opening_center := center.y + float(openings.get(side, 0.0)) if side == "east" or side == "west" else center.x + float(openings.get(side, 0.0))
		if side == "north" or side == "south":
			var z := z0 if side == "north" else z1
			if open:
				var left_len := maxf(0.1, opening_center - 1.8 - x0)
				var right_len := maxf(0.1, x1 - opening_center - 1.8)
				_add_box(label + " " + side + " wall", Vector3(x0 + left_len / 2.0, 2, z), Vector3(left_len, 4, 0.7), c)
				_add_box(label + " " + side + " wall", Vector3(opening_center + 1.8 + right_len / 2.0, 2, z), Vector3(right_len, 4, 0.7), c)
				_add_box(label + " portal lintel", Vector3(opening_center, 3.6, z), Vector3(3.6, 0.8, 0.7), c, false)
				_add_portal_frame(label, Vector3(opening_center, 0.0, z), side)
			else:
				_add_box(label + " " + side + " wall", Vector3(center.x, 2, z), Vector3(size.x, 4, 0.7), c)
		else:
			var x := x0 if side == "west" else x1
			if open:
				var near_len := maxf(0.1, opening_center - 1.8 - z0)
				var far_len := maxf(0.1, z1 - opening_center - 1.8)
				_add_box(label + " " + side + " wall", Vector3(x, 2, z0 + near_len / 2.0), Vector3(0.7, 4, near_len), c)
				_add_box(label + " " + side + " wall", Vector3(x, 2, opening_center + 1.8 + far_len / 2.0), Vector3(0.7, 4, far_len), c)
				_add_box(label + " portal lintel", Vector3(x, 3.6, opening_center), Vector3(0.7, 0.8, 3.6), c, false)
				_add_portal_frame(label, Vector3(x, 0.0, opening_center), side)
			else:
				_add_box(label + " " + side + " wall", Vector3(x, 2, center.y), Vector3(0.7, 4, size.y), c)
		# Rounded piers soften the broad room corners and help the spaces read as built architecture.
	for px in [x0 + 0.58, x1 - 0.58]:
		for pz in [z0 + 0.58, z1 - 0.58]:
			_add_cylinder(label + " rounded pier", Vector3(px, 1.88, pz), 0.31, 3.48, Color(0.43, 0.37, 0.29), false)
			_add_cylinder(label + " pier foot", Vector3(px, 0.22, pz), 0.39, 0.28, Color(0.53, 0.45, 0.34), false)
			_add_cylinder(label + " pier capital", Vector3(px, 3.47, pz), 0.40, 0.24, Color(0.54, 0.46, 0.35), false)


func _add_portal_frame(label: String, center: Vector3, side: String) -> void:
	var horizontal := side == "north" or side == "south"
	if horizontal:
		for x_offset in [-1.83, 1.83]:
			_add_cylinder(label + " rounded doorway pier", center + Vector3(x_offset, 1.8, 0), 0.18, 3.5, Color(0.49, 0.41, 0.31), false)
		_add_cylinder(label + " rounded doorway brow", center + Vector3(0, 3.02, 0), 0.16, 3.86, Color(0.57, 0.46, 0.32), false, Vector3(0, 0, 90))
	else:
		for z_offset in [-1.83, 1.83]:
			_add_cylinder(label + " rounded doorway pier", center + Vector3(0, 1.8, z_offset), 0.18, 3.5, Color(0.49, 0.41, 0.31), false)
		_add_cylinder(label + " rounded doorway brow", center + Vector3(0, 3.02, 0), 0.16, 3.86, Color(0.57, 0.46, 0.32), false, Vector3(90, 0, 0))


func _hall_z(x: float, a: float, b: float) -> void:
	var mid := (a + b) / 2.0
	var len := absf(b - a)
	# Generous floor overlap prevents hairline gaps at room thresholds from catching the player.
	_add_box("Dogleg passage floor", Vector3(x, -0.4, mid), Vector3(3.6, 0.8, len + 2.4), Color(0.23, 0.22, 0.20))
	if len > 3.5:
		for side in [-1.0, 1.0]:
			_add_box("Dogleg passage wall", Vector3(x + side * 2.05, 2, mid), Vector3(0.55, 4, len - 3.0), Color(0.33, 0.30, 0.26))


func _hall_x(a: float, b: float, z: float) -> void:
	var mid := (a + b) / 2.0
	var len := absf(b - a)
	_add_box("Turn passage floor", Vector3(mid, -0.4, z), Vector3(len + 2.4, 0.8, 3.6), Color(0.23, 0.22, 0.20))
	if len > 3.5:
		for side in [-1.0, 1.0]:
			_add_box("Turn passage wall", Vector3(mid, 2, z + side * 2.05), Vector3(len - 3.0, 4, 0.55), Color(0.33, 0.30, 0.26))


func _build_story_clues() -> void:
	# Distinct narrative beats are depicted in original painted-style SVG relief art.
	_add_mural("Ritual mural", "res://murals/ritual_fresco.png", Vector3(14, 2.2, -0.35), PI)
	_curse_mural = _add_mural("Curse mural", "res://murals/curse_fresco.png", Vector3(-5.65, 2.15, 7), PI / 2.0)
	_division_mural = _add_mural("Deliberate separation mural", "res://murals/division_fresco.png", Vector3(-14, 2.25, 26.5), PI)
	_revealed_mural = _add_mural("Completed story mural", "res://murals/reveal_fresco.png", Vector3(-14, 2.3, 42.55), PI)
	_revealed_mural.visible = false
	_mural_light = _add_point_light(Vector3(-14, 3.2, 41.8), Color(0.43, 0.71, 0.90), 0.0, 8.0)
	# The sanctuary's orb is an actual door control, framed as a carved mechanism.
	_add_cylinder("Orb mechanism plinth", Vector3(14, 0.18, -1.7), 0.62, 0.36, Color(0.43, 0.36, 0.27), false)
	_add_cylinder("Orb mechanism ring", Vector3(14, 0.42, -1.7), 0.40, 0.09, Color(0.73, 0.58, 0.32), false)
	_sanctuary_orb = Node3D.new()
	_sanctuary_orb.name = "Sanctuary door orb"
	_sanctuary_orb.position = Vector3(14, 1.24, -1.7)
	add_child(_sanctuary_orb)
	var orb_visual := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.28
	orb_mesh.height = 0.56
	orb_visual.mesh = orb_mesh
	var orb_material := _stone_material(Color(0.76, 0.50, 0.22))
	orb_material.emission_enabled = true
	orb_material.emission = Color(0.96, 0.58, 0.22)
	orb_material.emission_energy_multiplier = 0.65
	orb_visual.material_override = orb_material
	_sanctuary_orb.add_child(orb_visual)
	_sanctuary_orb_light = OmniLight3D.new()
	_sanctuary_orb_light.light_color = Color(1.0, 0.58, 0.24)
	_sanctuary_orb_light.light_energy = 0.65
	_sanctuary_orb_light.omni_range = 3.5
	_sanctuary_orb.add_child(_sanctuary_orb_light)
	for mark_data in [[10.8, 1.2], [11.5, 2.0], [16.5, 1.2], [17.2, 2.0]]:
		var mark_x: float = mark_data[0]
		var mark_y: float = mark_data[1]
		for segment in [[Vector3(mark_x, mark_y, -0.04), Vector3(0.07, 0.54, 0.045)], [Vector3(mark_x + 0.11, mark_y, -0.04), Vector3(0.25, 0.065, 0.045)]]:
			var segment_position: Vector3 = segment[0]
			var segment_size: Vector3 = segment[1]
			var mark_mesh := _add_box("Dormant door glyph", segment_position, segment_size, Color(0.25, 0.47, 0.49), false)
			var mark_material := mark_mesh.get_node("Visual").material_override as StandardMaterial3D
			mark_material.emission_enabled = true
			mark_material.emission = Color(0.20, 0.74, 0.82)
			mark_material.emission_energy_multiplier = 0.0
			_sanctuary_sigil_materials.append(mark_material)
		_sanctuary_sigil_lights.append(_add_point_light(Vector3(mark_x, mark_y, -0.8), Color(0.31, 0.75, 0.82), 0.0, 2.0))
	_division_mural_light = _add_point_light(Vector3(-14, 3.0, 25.8), Color(0.57, 0.77, 0.84), 0.16, 5.5)
	_door_audio = AudioStreamPlayer.new()
	_door_audio.volume_db = -10.0
	_door_audio.stream = _make_stone_sound()
	add_child(_door_audio)
	_restoration_audio = AudioStreamPlayer.new()
	_restoration_audio.volume_db = -12.0
	_restoration_audio.stream = _make_low_rumble(2.4)
	add_child(_restoration_audio)
	# The division mural is the room's investigation point; the other story orb was removed.
	# The sanctuary's surviving columns form a deliberate ring around its vessel mural.
	for p in [Vector3(10.0, 1.8, -10.0), Vector3(18.0, 1.8, -10.0), Vector3(10.0, 1.8, -2.0), Vector3(18.0, 1.8, -2.0)]:
		_add_cylinder("Sanctuary carved column", p, 0.34, 3.6, Color(0.47, 0.40, 0.31), false)
	# Four toppled cut stones echo the separation depicted in the next chamber.
	for i in 4:
		var angle := float(i) * PI / 2.0
		_add_box("Separated Grail stone", Vector3(-14.0 + cos(angle) * 2.4, 0.18, 18.0 + sin(angle) * 2.4), Vector3(0.78, 0.34, 0.44), Color(0.39, 0.37, 0.32), false, Vector3(0, rad_to_deg(angle), 16.0))
	story_clues = [
		{"id":"curse", "node":_curse_mural, "text":"The vessel's light became a wound."},
		{"id":"division", "node":_division_mural, "text":"They broke it to protect the living."}
	]
	# Broken Grail emblem over the abandoned entrance camp.
	for part in [Vector3(-0.55, 0.15, 0), Vector3(0.55, 0.15, 0), Vector3(-0.55, -0.42, 0), Vector3(0.55, -0.42, 0)]:
		_add_box("Broken emblem shard", Vector3(part.x, 2.5 + part.y, -22.15), Vector3(0.55, 0.48, 0.1), Color(0.75, 0.59, 0.31), false, Vector3(0, 0, part.x * 18.0))
	# Collapsed canvas, crates, abandoned journal, and the cursed relic by a pack.
	_add_box("Collapsed camp canvas", Vector3(-2.3, 0.72, -18.7), Vector3(3.2, 0.12, 2.3), Color(0.37, 0.31, 0.22), false, Vector3(0, 0, -28))
	_add_box("Camp crate", Vector3(-4.4, 0.35, -19.2), Vector3(0.9, 0.7, 0.8), Color(0.37, 0.27, 0.18))
	_add_box("Discarded trowel handle", Vector3(1.5, 0.15, -18.9), Vector3(0.08, 0.08, 1.2), Color(0.42, 0.30, 0.18), false, Vector3(0, 0, 35))
	_add_box("Trowel blade", Vector3(1.85, 0.11, -18.45), Vector3(0.33, 0.05, 0.3), Color(0.55, 0.56, 0.52), false, Vector3(0, 0, 35))
	_journal = _add_box("Explorer journal", Vector3(0.8, 0.12, -19.2), Vector3(0.52, 0.08, 0.72), Color(0.45, 0.31, 0.18), false, Vector3(0, 0, -15))
	_add_box("Abandoned pack", Vector3(4.4, 0.47, 9.5), Vector3(0.9, 0.95, 0.65), Color(0.34, 0.27, 0.20), false)
	# Scrape marks and a cracked, discarded pottery relic mark careless digging.
	_add_sphere("Broken statue head", Vector3(-3.7, 0.42, 4.1), 0.55, Color(0.37, 0.33, 0.28), false)
	_add_box("Fallen statue", Vector3(-3.4, 0.28, 4.8), Vector3(1.4, 0.55, 0.9), Color(0.34, 0.30, 0.25), false, Vector3(0, 0, 22))
	_energy_scar = _add_box("Energy scar", Vector3(-2.4, 0.03, 8.5), Vector3(0.08, 0.04, 4.0), Color(0.30, 0.62, 0.81), false, Vector3(0, 0, -31))
	_energy_scar_light = _add_point_light(Vector3(-2.4, 0.28, 8.5), Color(0.30, 0.68, 0.88), 0.0, 4.0)
	# Collapsed stone and fleeing silhouettes in the curse room communicate consequence.
	for i in 3:
		_add_box("Ruptured floor vein", Vector3(-3.0 + i * 0.55, 0.045, 6.0 + i * 0.8), Vector3(1.35, 0.04, 0.07), Color(0.14, 0.39, 0.50), false, Vector3(0, 0, 22))
	# The original camp keeps the failed-expedition introduction intact.
	_add_box("Broken emblem left", Vector3(-0.55, 2.5, -23.15), Vector3(0.55, 0.5, 0.1), Color(0.75, 0.59, 0.31), false, Vector3(0, 0, -18))
	_add_box("Broken emblem right", Vector3(0.55, 2.1, -23.15), Vector3(0.55, 0.5, 0.1), Color(0.75, 0.59, 0.31), false, Vector3(0, 0, 18))
	# Short wall inscriptions support the pictures without explaining the whole mystery.
	_add_wall_inscription("FOUR PIECES. ONE WARNING.", Vector3(-6.55, 2.65, -18.0), PI / 2.0)
	_add_wall_inscription("A VESSEL HELD IN TRUST.", Vector3(14.0, 2.25, -11.55), 0.0)
	_add_wall_inscription("ITS LIGHT BECAME A WOUND.", Vector3(-5.55, 2.7, 4.6), PI / 2.0)
	_add_wall_inscription("DIVIDED TO SHELTER THE LIVING.", Vector3(-8.48, 2.25, 18.0), -PI / 2.0)


func _add_mural(label: String, path: String, pos: Vector3, yaw: float) -> MeshInstance3D:
	var image := MeshInstance3D.new()
	image.name = label
	var quad := QuadMesh.new()
	var texture := load(path) as Texture2D
	var mural_width := 7.5
	var mural_height := 3.65
	if texture != null and texture.get_width() > 0:
		var aspect := float(texture.get_width()) / float(texture.get_height())
		if aspect > mural_width / mural_height:
			mural_height = mural_width / aspect
		else:
			mural_width = mural_height * aspect
	quad.size = Vector2(mural_width, mural_height)
	image.mesh = quad
	image.position = pos
	image.rotation.y = yaw
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.material_override = mat
	add_child(image)
	return image


func _add_wall_inscription(words: String, pos: Vector3, yaw: float) -> void:
	var inscription := Label3D.new()
	inscription.name = "Carved wall inscription"
	inscription.text = words
	inscription.font_size = 30
	inscription.pixel_size = 0.004
	inscription.modulate = Color(0.77, 0.64, 0.40)
	inscription.outline_size = 5
	inscription.outline_modulate = Color(0.10, 0.085, 0.065, 0.85)
	inscription.position = pos
	inscription.rotation.y = yaw
	add_child(inscription)


func _build_excavation_sites() -> void:
	var positions := [Vector3(-0.6, 0.0, -19.0), Vector3(15.7, 0.0, -6.0), Vector3(-1.0, 0.0, 8.0), Vector3(-17.0, 0.0, 18.0)]
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
		var record := {"id": i + 1, "visual": fragment, "inscription": inscriptions[i], "color": fragment_colors[i], "collected": false, "status": "undiscovered"}
		fragment_records.append(record)
		sites.append({"id": i + 1, "node": root, "fragment": fragment, "mound": mound, "layers": 2, "state": "buried", "damage": 0.0, "pulse": 0.0, "inscription": inscriptions[i], "particles": dirt_particles})


func _build_artifacts() -> void:
	_add_artifact("Sun Charm", "This relic brightens the path. Its weight feels strange.", Vector3(18.2, 0.25, -4.0), Color(0.91, 0.69, 0.32), 1.35, 1.0, false)
	_add_artifact("Pilgrim Sandals", "Worn leather, threaded with gold.", Vector3(10.2, 0.25, -4.0), Color(0.81, 0.61, 0.29), 1.0, 1.3, false)
	_add_artifact("Obsidian Idol", "The stone drinks the light around it.", Vector3(3.9, 0.25, 5.1), Color(0.47, 0.36, 0.67), 0.58, 0.82, true)
	_add_artifact("Lead Anklet", "Tiny footprints circle its cold surface.", Vector3(-4.0, 0.25, 9.6), Color(0.53, 0.42, 0.63), 1.0, 0.58, true)
	_add_artifact("Gilded Mask", "The face is warm. Something stirs within.", Vector3(3.3, 0.25, 9.5), Color(0.86, 0.68, 0.29), 1.0, 0.55, true)


func _build_restoration_and_final_chamber() -> void:
	_add_cylinder("Restoration dais", Vector3(-14, 0.18, 36.0), 2.4, 0.36, Color(0.40, 0.34, 0.27), false)
	_add_cylinder("Dais inlay", Vector3(-14, 0.39, 36.0), 1.65, 0.08, Color(0.79, 0.63, 0.34), false)
	_add_cylinder("Empty grail socket", Vector3(-14, 0.52, 36.0), 0.62, 0.18, Color(0.21, 0.24, 0.24), false)
	_add_point_light(Vector3(-14, 2.4, 36.0), Color(0.44, 0.70, 0.88), 0.3, 4.0)
	_restored_grail = _make_grail_mesh()
	_restored_grail.position = Vector3(-14, 0.7, 36.0)
	_restored_grail.scale = Vector3.ZERO
	_restored_grail.visible = false
	add_child(_restored_grail)
	var pulse_mesh := SphereMesh.new()
	pulse_mesh.radius = 0.5
	pulse_mesh.height = 1.0
	_dark_pulse = MeshInstance3D.new()
	_dark_pulse.name = "Ominous restoration pulse"
	_dark_pulse.mesh = pulse_mesh
	_dark_pulse.position = Vector3(-14, 1.0, 36.0)
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
	player.position = Vector3(0, 0.08, -20.3)
	# Face from the open entrance into camp and toward the first marked site.
	player.rotation.y = PI
	add_child(player)
	_player_collision = CollisionShape3D.new()
	_player_capsule = CapsuleShape3D.new()
	_player_capsule.radius = 0.38
	_player_capsule.height = 1.75
	_player_collision.shape = _player_capsule
	_player_collision.position.y = 0.88
	player.add_child(_player_collision)
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
	_fragment_popup = Control.new()
	_fragment_popup.name = "Fragment inspection"
	_fragment_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fragment_popup.visible = false
	_fragment_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fragment_popup)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.022, 0.028, 0.88)
	_fragment_popup.add_child(shade)
	var card := PanelContainer.new()
	card.name = "PanelContainer"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-320, -190)
	card.size = Vector2(640, 380)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.12, 0.98)
	style.border_color = Color(0.73, 0.60, 0.37)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	_fragment_popup.add_child(card)
	var stack := VBoxContainer.new()
	stack.name = "VBoxContainer"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 10)
	card.add_child(stack)
	var symbol := _label("◈", 64, Color(0.68, 0.83, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	symbol.name = "Fragment symbol"
	symbol.custom_minimum_size.y = 90
	stack.add_child(symbol)
	stack.add_child(_label("GRAIL FRAGMENT RECOVERED", 19, Color(0.91, 0.77, 0.49), HORIZONTAL_ALIGNMENT_CENTER))
	var inscription := _label("", 24, Color(0.96, 0.93, 0.84), HORIZONTAL_ALIGNMENT_CENTER)
	inscription.name = "Inscription"
	inscription.custom_minimum_size.y = 70
	stack.add_child(inscription)
	stack.add_child(_label("Press Enter to continue", 15, Color(0.66, 0.69, 0.66), HORIZONTAL_ALIGNMENT_CENTER))
	_journal_panel = Control.new()
	_journal_panel.name = "Fragment journal"
	_journal_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_journal_panel.visible = false
	_journal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_journal_panel)
	var journal_shade := ColorRect.new()
	journal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal_shade.color = Color(0.015, 0.022, 0.028, 0.9)
	_journal_panel.add_child(journal_shade)
	var journal_card := PanelContainer.new()
	journal_card.set_anchors_preset(Control.PRESET_CENTER)
	journal_card.position = Vector2(-390, -280)
	journal_card.size = Vector2(780, 560)
	var journal_style := StyleBoxFlat.new()
	journal_style.bg_color = Color(0.10, 0.12, 0.12, 0.99)
	journal_style.border_color = Color(0.73, 0.60, 0.37)
	journal_style.set_border_width_all(2)
	journal_style.set_corner_radius_all(8)
	journal_card.add_theme_stylebox_override("panel", journal_style)
	_journal_panel.add_child(journal_card)
	var journal_stack := VBoxContainer.new()
	journal_stack.add_theme_constant_override("separation", 9)
	journal_card.add_child(journal_stack)
	journal_stack.add_child(_label("FIELD JOURNAL  •  GRAIL FRAGMENTS", 23, Color(0.91, 0.77, 0.49), HORIZONTAL_ALIGNMENT_CENTER))
	for i in 4:
		var slot := _label("", 18, Color(0.82, 0.81, 0.74))
		slot.custom_minimum_size.y = 80
		_journal_slots.append(slot)
		journal_stack.add_child(slot)
	var journal_close := Button.new()
	journal_close.text = "CLOSE  (J)"
	journal_close.custom_minimum_size.y = 44
	journal_close.pressed.connect(_close_journal)
	journal_stack.add_child(journal_close)
	_refresh_journal()


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
	if _fragment_popup_open:
		_fragment_popup_timer -= delta
		if _fragment_popup_timer <= 0.0:
			_fragment_popup.visible = false
			_fragment_popup_open = false
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
	if _fragment_pickup_active:
		return
	if _fragment_popup_open:
		return
	if _journal_open:
		return
	if state == State.RESTORING:
		return
	if controls_blocked_until_release:
		if _gameplay_controls_held():
			return
		controls_blocked_until_release = false
	_set_crouched(_crouch_held)
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
	if _fragment_pickup_active:
		return
	if _journal_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_J, KEY_ESCAPE]:
			_close_journal()
			get_viewport().set_input_as_handled()
		return
	if _fragment_popup_open:
		if event is InputEventKey and event.pressed and [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE].has(event.keycode):
			_fragment_popup.visible = false
			_fragment_popup_open = false
			_fragment_popup_timer = 0.0
		return
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
		elif event.keycode == KEY_C:
			_crouch_held = event.pressed
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
		elif event.keycode == KEY_J:
			_toggle_journal()


func _handle_excavation(delta: float) -> void:
	var nearby := _nearest_site()
	var e_held := _dig_held
	var r_held := _brush_held
	if nearby.is_empty() or nearby["state"] in ["done", "collecting", "revealed"]:
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
	site["state"] = "revealed"
	site["fragment"].visible = true
	var fragment_tween := create_tween()
	fragment_tween.tween_property(site["fragment"], "position:y", 0.42, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	site["node"].get_node("Soil mound").visible = false
	var scar_material := (_energy_scar.get_node("Visual") as MeshInstance3D).material_override as StandardMaterial3D
	scar_material.emission_enabled = true
	scar_material.emission = Color(0.30, 0.68, 0.88)
	scar_material.emission_energy_multiplier = 0.6 + float(fragments + 1) * 0.3
	_energy_scar_light.light_energy = 0.45 + float(fragments + 1) * 0.25
	_show_message("The fragment is exposed. F to collect.", 2.2)
	site["node"].get_node("Burial mark").visible = false
	site["node"].get_node("Burial mark cross").visible = false


func _pick_up_fragment(site: Dictionary) -> void:
	if site["state"] != "revealed":
		return
	var fragment_id := int(site["id"])
	var record_index := fragment_id - 1
	if record_index < 0 or record_index >= fragment_records.size() or fragment_records[record_index]["collected"]:
		return
	site["state"] = "collecting"
	_fragment_pickup_active = true
	var fragment: Node3D = site["fragment"]
	var pickup := create_tween()
	pickup.tween_property(fragment, "global_position", camera.global_position + (-camera.global_basis.z * 0.8) + Vector3(0, -0.15, 0), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	pickup.parallel().tween_property(fragment, "scale", Vector3(0.08, 0.08, 0.08), 0.6)
	await pickup.finished
	_fragment_pickup_active = false
	fragment.visible = false
	fragment_records[record_index]["collected"] = true
	fragment_records[record_index]["status"] = "discovered"
	site["state"] = "done"
	fragments = 0
	for record in fragment_records:
		if record["collected"]:
			fragments += 1
	_division_mural_light.light_energy = 0.16 + float(fragments) * 0.22
	var scar_material := (_energy_scar.get_node("Visual") as MeshInstance3D).material_override as StandardMaterial3D
	scar_material.emission_energy_multiplier = 0.45 + float(fragments) * 0.34
	_energy_scar_light.light_energy = 0.3 + float(fragments) * 0.3
	fragment_label.text = "FRAGMENTS  %d / 4" % fragments
	_refresh_journal()
	_show_fragment_popup(site)


func _restore_grail() -> void:
	if state != State.EXPLORING or fragments != 4:
		return
	state = State.RESTORING
	story_stage = StoryStage.RESTORATION
	_restored_grail.visible = false
	_revealed_mural.visible = false
	_mural_light.light_energy = 0.0
	# Pull the four recovered pieces from the player's held collection into the altar.
	for index in fragment_records.size():
		var piece: Node3D = fragment_records[index]["visual"]
		var start := piece.global_position
		var target := Vector3(-14.0 + (float(index) - 1.5) * 0.14, 1.0 + float(index % 2) * 0.12, 36.0)
		piece.visible = true
		piece.scale = Vector3(0.18, 0.18, 0.18)
		piece.global_position = camera.global_position + (-camera.global_basis.z * 0.75) + (camera.global_basis.x * (float(index) - 1.5) * 0.16)
		var assembly := create_tween()
		assembly.tween_property(piece, "global_position", target, 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		assembly.parallel().tween_property(piece, "scale", Vector3(0.38, 0.38, 0.38), 1.05)
		piece.set_meta("assembly_start", start)
	world_environment.environment.ambient_light_color = Color(0.48, 0.37, 0.20)
	key_light.light_color = Color(1.0, 0.72, 0.36)
	key_light.light_energy = 0.68
	await get_tree().create_timer(1.35).timeout
	for record in fragment_records:
		var piece: Node3D = record["visual"]
		piece.visible = false
		piece.scale = Vector3.ONE
	_restored_grail.scale = Vector3.ZERO
	_restored_grail.visible = true
	var grail_appearance := create_tween()
	grail_appearance.tween_property(_restored_grail, "scale", Vector3.ONE, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await grail_appearance.finished
	await get_tree().create_timer(0.24).timeout
	# The warm success glow falters; the original curse marks wake across the ruins.
	_restoration_audio.play()
	_dark_pulse.visible = true
	_dark_pulse.scale = Vector3(0.1, 0.1, 0.1)
	var pulse_material := _dark_pulse.material_override as StandardMaterial3D
	pulse_material.albedo_color.a = 0.42
	var pulse_tween := create_tween()
	pulse_tween.tween_property(_dark_pulse, "scale", Vector3(4.5, 4.5, 4.5), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var pulse_fade := create_tween()
	pulse_fade.tween_property(pulse_material, "albedo_color:a", 0.0, 1.25)
	_energy_scar_light.light_energy = 1.8
	_crack_light.light_energy = 1.4
	_sanctuary_orb_light.light_energy = 1.8
	for sigil_light in _sanctuary_sigil_lights:
		sigil_light.light_energy = 1.1
	for flicker in 8:
		flashlight.light_energy = 0.35 if flicker % 2 == 0 else 1.1
		key_light.light_energy = 0.15 if flicker % 2 == 0 else 0.43
		camera.position.y = 1.62 + (0.035 if flicker % 2 == 0 else -0.025)
		await get_tree().create_timer(0.11).timeout
	camera.position.y = 1.62
	flashlight.light_energy = 0.65
	key_light.light_energy = 0.18
	# The fully lit inner mural now connects the fragment symbols to the deliberate sealing.
	_revealed_mural.visible = true
	_mural_light.light_energy = 3.4
	var division_material := _division_mural.material_override as StandardMaterial3D
	division_material.emission_enabled = true
	division_material.emission = Color(0.23, 0.31, 0.29)
	division_material.emission_energy_multiplier = 0.7
	_division_mural_light.light_energy = 3.2
	_ghost.global_position = Vector3(-14.0, 0.0, 39.2)
	_ghost.look_at(Vector3(-14.0, 1.4, 36.0), Vector3.UP)
	_ghost.visible = true
	await get_tree().create_timer(0.7).timeout
	_ghost.visible = false
	await get_tree().create_timer(1.05).timeout
	_restoration_audio.stop()
	_dark_pulse.visible = false
	flashlight.light_energy = 1.5
	key_light.light_color = Color(0.62, 0.70, 0.78)
	key_light.light_energy = 0.24
	world_environment.environment.ambient_light_color = Color(0.30, 0.37, 0.36)
	state = State.WON
	_ended = true
	ending_text = "The Grail is whole. The expedition succeeds."
	game_ended.emit(true)


func _interact() -> void:
	if _ended:
		return
	var site := _nearest_site()
	if not site.is_empty() and site["state"] == "revealed":
		_pick_up_fragment(site)
		return
	if not _door_open and _distance_xz(player.global_position, _sanctuary_orb.global_position) < 1.65:
		_activate_sanctuary_mechanism()
		return
	if not _crack_open and _door_open and _distance_xz(player.global_position, Vector3(-5.8, 0.0, 11.0)) < 2.1:
		_open_cracked_passage()
		return
	if not _journal_read and player.global_position.distance_to(_journal.global_position) < 1.8:
		_journal_read = true
		_show_message("We came for the Grail. Four pieces remain beneath this temple. Dig carefully.", 3.6)
		return
	for clue in story_clues:
		if _distance_xz(player.global_position, clue["node"].global_position) < 4.0:
			var clue_id: String = clue["id"]
			if not story_clues_seen[clue_id]:
				story_clues_seen[clue_id] = true
				if clue_id == "curse":
					story_stage = StoryStage.SUSPICION
				elif clue_id == "division":
					story_stage = StoryStage.TWIST
			_show_message(clue["text"], 3.4)
			if clue_id == "division":
				_trigger_jump_scare()
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


func _activate_sanctuary_mechanism() -> void:
	if _door_open:
		return
	_door_open = true
	story_clues_seen["sanctuary"] = true
	story_stage = StoryStage.DISCOVERY
	_show_message("The vessel mural stirs. A stone door answers below.", 2.8)
	_sanctuary_orb_light.light_energy = 2.6
	var orb_visual := _sanctuary_orb.get_child(0) as MeshInstance3D
	var orb_material := orb_visual.material_override as StandardMaterial3D
	orb_material.emission_energy_multiplier = 2.8
	_door_audio.play()
	for sigil_light in _sanctuary_sigil_lights:
		sigil_light.light_energy = 1.4
	for sigil_material in _sanctuary_sigil_materials:
		sigil_material.emission_energy_multiplier = 1.65
	for i in 6:
		key_light.light_energy = 0.24 if i % 2 == 0 else 0.42
		await get_tree().create_timer(0.09).timeout
	var door_tween := create_tween()
	door_tween.tween_property(_sanctuary_door, "position:y", 5.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await door_tween.finished
	_sanctuary_door_collision.disabled = true
	_show_message("The passage is open.", 1.7)


func _open_cracked_passage() -> void:
	if _crack_open:
		return
	_crack_open = true
	story_clues_seen["curse"] = true
	story_stage = StoryStage.SUSPICION
	_crack_light.light_energy = 1.55
	_door_audio.play()
	_show_message("The crack widens. C to crouch through.", 2.6, true)
	var seal_tween := create_tween()
	seal_tween.tween_property(_crack_seal, "position:y", 4.7, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await seal_tween.finished
	_crack_seal_collision.disabled = true


func _distance_xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _set_crouched(crouch: bool) -> void:
	if crouch == _crouched:
		return
	_crouched = crouch
	_player_capsule.height = 0.92 if crouch else 1.75
	_player_collision.position.y = 0.46 if crouch else 0.88
	camera.position.y = 0.82 if crouch else 1.62


func _toggle_journal() -> void:
	_journal_open = not _journal_open
	_journal_panel.visible = _journal_open
	if _journal_open:
		_mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_journal()
	else:
		_mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _close_journal() -> void:
	_journal_open = false
	_journal_panel.visible = false
	_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_journal() -> void:
	if _journal_slots.size() != 4:
		return
	var symbols := ["◈", "◉", "✦", "◌"]
	for index in 4:
		var record := fragment_records[index]
		var slot: Label = _journal_slots[index]
		if record["collected"]:
			slot.text = "%s   FRAGMENT %d\n%s" % [symbols[index], index + 1, record["inscription"]]
			slot.add_theme_color_override("font_color", record["color"])
		else:
			slot.text = "◇   FRAGMENT %d\nUndiscovered" % (index + 1)
			slot.add_theme_color_override("font_color", Color(0.49, 0.51, 0.49))


func _update_hud() -> void:
	if state == State.RESTORING:
		hud_label.text = "THE VESSEL REMEMBERS"
		prompt_label.text = ""
	elif state == State.LOST:
		hud_label.text = "FRAGMENT SHATTERED"
		prompt_label.text = ""
	elif fragments == 4:
		hud_label.text = "RETURN TO THE RESTORATION ALTAR"
		prompt_label.text = "Hold G to restore the Grail." if _near_plinth() else ""
	else:
		if player.global_position.z < -12.0 and player.global_position.x < 7.0:
			hud_label.text = "THE ABANDONED EXPEDITION"
		elif player.global_position.x > 7.0:
			hud_label.text = "THE GRAIL SANCTUARY"
		elif player.global_position.x > -7.0:
			hud_label.text = "THE SHATTERED HALL"
		elif player.global_position.z < 29.0:
			hud_label.text = "THE INNER CHAMBER"
		else:
			hud_label.text = "THE RESTORATION ALTAR"
		var site := _nearest_site()
		if not site.is_empty() and site["state"] == "buried":
			prompt_label.text = "Hold E to dig"
		elif not site.is_empty() and site["state"] == "brush":
			prompt_label.text = "Hold R to brush"
		elif not site.is_empty() and site["state"] == "revealed":
			prompt_label.text = "F  •  Pick up fragment"
		elif not site.is_empty() and site["state"] == "damaged":
			prompt_label.text = "FRAGMENT SHATTERED"
		elif not _door_open and _distance_xz(player.global_position, _sanctuary_orb.global_position) < 2.2:
			prompt_label.text = "F  •  Activate door mechanism"
		elif _door_open and not _crack_open and _distance_xz(player.global_position, Vector3(-5.8, 0.0, 11.0)) < 2.8:
			prompt_label.text = "F  •  Investigate the glowing crack"
		elif not story_clues_seen["curse"] and _distance_xz(player.global_position, _curse_mural.global_position) < 4.0:
			prompt_label.text = "F  •  Examine the damaged mural"
		elif not story_clues_seen["division"] and _distance_xz(player.global_position, _division_mural.global_position) < 4.0:
			prompt_label.text = "F  •  Examine the broken mural"
		elif _crack_open and _distance_xz(player.global_position, Vector3(-7.0, 0.0, 11.0)) < 3.0 and not _crouched:
			prompt_label.text = "C  •  Crouch through the fissure"
		elif not _nearest_artifact().is_empty() and carried.is_empty():
			prompt_label.text = "F  •  Take relic"
		elif not carried.is_empty():
			prompt_label.text = "F  •  Drop relic"
		elif not _journal_read and player.global_position.distance_to(_journal.global_position) < 1.8:
			prompt_label.text = "F  •  Read journal"
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
		fragment_label.text = "FRAGMENTS  %d / 4   •   J JOURNAL" % fragments

func _nearest_site() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 1.8
	for site in sites:
		if site["state"] in ["done", "damaged", "collecting"]:
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
	return player.global_position.distance_to(Vector3(-14, 0, 36.0)) < 2.8


func _near_plinth() -> bool:
	return _nearest_plinth()


func _gameplay_controls_held() -> bool:
	for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_E, KEY_R, KEY_G, KEY_F, KEY_C]:
		if Input.is_key_pressed(key):
			return true
	return false


func _show_message(copy: String, duration: float = 2.5, danger: bool = false) -> void:
	message_label.text = copy
	message_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.48) if danger else Color(0.97, 0.85, 0.61))
	message_label.visible = true
	message_timer = duration


func _show_fragment_popup(site: Dictionary) -> void:
	var symbols := ["◈", "◉", "✦", "◌"]
	var colors := [Color(0.35, 0.76, 0.85), Color(0.82, 0.61, 0.32), Color(0.61, 0.51, 0.79), Color(0.42, 0.80, 0.66)]
	var symbol: Label = _fragment_popup.get_node("PanelContainer/VBoxContainer/Fragment symbol")
	var inscription: Label = _fragment_popup.get_node("PanelContainer/VBoxContainer/Inscription")
	var index := int(site["id"]) - 1
	symbol.text = symbols[index]
	symbol.add_theme_color_override("font_color", colors[index])
	inscription.text = str(site["inscription"])
	_fragment_popup.visible = true
	_fragment_popup_open = true
	_fragment_popup_timer = 8.0


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
	var material := _stone_material(color)
	if label.contains("wall") or label.contains("floor") or label.contains("ceiling") or label.contains("passage") or label.contains("portal lintel"):
		material.albedo_texture = SANDSTONE_TEXTURE
		material.albedo_color = Color(0.78, 0.70, 0.57)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.uv1_scale = Vector3(maxf(dimensions.x / 3.0, 1.0), maxf(dimensions.y / 3.0, 1.0), maxf(dimensions.z / 3.0, 1.0))
		material.roughness = 1.0
	mesh_instance.material_override = material
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
	var mesh: Mesh
	match fragment_id:
		1:
			var shard := PrismMesh.new()
			shard.size = Vector3(0.85, 0.4, 0.72)
			mesh = shard
		2:
			var wedge := BoxMesh.new()
			wedge.size = Vector3(0.68, 0.48, 0.62)
			mesh = wedge
			mesh_instance.rotation_degrees = Vector3(9, 45, 12)
		3:
			var cup_base := CylinderMesh.new()
			cup_base.top_radius = 0.19
			cup_base.bottom_radius = 0.42
			cup_base.height = 0.34
			cup_base.radial_segments = 5
			mesh = cup_base
		4:
			var fractured_cap := SphereMesh.new()
			fractured_cap.radius = 0.39
			fractured_cap.height = 0.5
			fractured_cap.radial_segments = 7
			fractured_cap.rings = 4
			mesh = fractured_cap
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
	var shroud := MeshInstance3D.new()
	var shroud_mesh := CylinderMesh.new()
	shroud_mesh.top_radius = 0.18
	shroud_mesh.bottom_radius = 0.53
	shroud_mesh.height = 1.65
	shroud_mesh.radial_segments = 12
	shroud.mesh = shroud_mesh
	shroud.position.y = 0.95
	shroud.material_override = shadow_material
	_ghost.add_child(shroud)
	var hood := MeshInstance3D.new()
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 0.25
	hood_mesh.height = 0.52
	hood_mesh.radial_segments = 12
	hood.mesh = hood_mesh
	hood.position.y = 1.88
	hood.material_override = shadow_material
	_ghost.add_child(hood)
	for side in [-1.0, 1.0]:
		var sleeve := MeshInstance3D.new()
		var sleeve_mesh := CapsuleMesh.new()
		sleeve_mesh.radius = 0.10
		sleeve_mesh.height = 1.08
		sleeve.mesh = sleeve_mesh
		sleeve.position = Vector3(side * 0.39, 0.95, 0)
		sleeve.rotation.z = deg_to_rad(side * -18.0)
		sleeve.material_override = shadow_material
		_ghost.add_child(sleeve)
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


func _make_stone_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	var count := int(stream.mix_rate * 1.55)
	for i in count:
		var t := float(i) / float(stream.mix_rate)
		var envelope := minf(t / 0.12, 1.0) * clampf((1.55 - t) / 0.22, 0.0, 1.0)
		var frequency := 92.0 - 34.0 * (t / 1.55)
		var sample := int((sin(TAU * frequency * t) * 0.23 + sin(TAU * (frequency * 0.47) * t) * 0.12) * envelope * 32767.0)
		samples.append(sample & 0xff)
		samples.append((sample >> 8) & 0xff)
	stream.data = samples
	return stream


func _make_low_rumble(duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	var count := int(float(stream.mix_rate) * duration)
	for i in count:
		var t := float(i) / float(stream.mix_rate)
		var envelope := minf(t / 0.18, 1.0) * clampf((duration - t) / 0.32, 0.0, 1.0)
		var swell := 0.62 + 0.38 * sin(PI * t / duration)
		var frequency := 48.0 + 11.0 * sin(t * 2.0)
		var sample := int((sin(TAU * frequency * t) * 0.22 + sin(TAU * 83.0 * t) * 0.08) * envelope * swell * 32767.0)
		samples.append(sample & 0xff)
		samples.append((sample >> 8) & 0xff)
	stream.data = samples
	return stream


func _trigger_jump_scare() -> void:
	if _scare_triggered or _ended:
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
