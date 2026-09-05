class_name SpaceView
extends Node3D
## Pure presentation. Effects and camera motion never advance mission state.
var sim: TrekSimulation
var fleet = Node3D.new()
var camera = Camera3D.new()
var player_ship: Node3D
var shield: MeshInstance3D
var clock = 0.0
var camera_base = Vector3(17, 20, 24)
var last_quadrant = Vector2i(-1, -1)
var fx_root = Node3D.new()
var cinematic = true

func _ready() -> void:
	add_child(fleet)
	add_child(fx_root)
	add_child(camera)
	camera.position = camera_base
	camera.look_at(Vector3.ZERO)
	camera.fov = 46
	camera.current = true
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var shader = ShaderMaterial.new()
	shader.shader = load("res://shaders/space.gdshader")
	sky.sky_material = shader
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6188b5")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.15
	environment.environment = env
	add_child(environment)
	var light = DirectionalLight3D.new()
	light.light_color = Color("c9e6ff")
	light.light_energy = 2.0
	light.rotation_degrees = Vector3(-35, -30, 0)
	add_child(light)
	var rim = DirectionalLight3D.new()
	rim.light_color = Color("537dff")
	rim.light_energy = 1.6
	rim.rotation_degrees = Vector3(25, 130, 0)
	add_child(rim)
	make_grid()

func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.35
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = mat
	instance.position = pos
	instance.scale = scale_value
	parent.add_child(instance)
	return instance

func ball(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var sphere = SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	return mesh(parent, sphere, pos, scale_value, mat)

func box(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	return mesh(parent, BoxMesh.new(), pos, scale_value, mat)

func ring(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var torus = TorusMesh.new()
	torus.inner_radius = radius * 0.94
	torus.outer_radius = radius
	return mesh(parent, torus, pos, Vector3.ONE, mat)

func make_ship(enemy: bool = false, kind: String = "cruiser") -> Node3D:
	var ship = Node3D.new()
	var hull = material(Color("6b8398") if not enemy else Color("493f51"), 0.8)
	var armor = material(Color("c8d8df") if not enemy else Color("827783"), 0.6)
	var dark = material(Color("172431"), 0.7)
	var glow = material(Color("59d9ff") if not enemy else Color("ff5e57"), 0.3, 3)
	var warm = material(Color("ffd5a2"), 0.0, 1.8)
	if not enemy:
		ball(ship, Vector3(0, 0.25, -0.7), Vector3(1.3, 0.17, 1.1), armor)
		ball(ship, Vector3(0, 0.30, -0.7), Vector3(1.05, 0.14, 0.90), hull)
		ring(ship, Vector3(0, 0.28, -0.7), 1.19, dark)
		ring(ship, Vector3(0, 0.36, -0.7), 0.88, armor)
		ball(ship, Vector3(0, 0.43, -0.65), Vector3(0.3, 0.13, 0.38), armor)
		ball(ship, Vector3(0, -0.05, 0.45), Vector3(0.42, 0.32, 1.2), hull)
		box(ship, Vector3(0, 0.08, 0), Vector3(0.25, 0.35, 1), armor)
		for side in [-1, 1]:
			var pylon = box(ship, Vector3(side * 0.7, 0.05, 0.55), Vector3(1.2, 0.1, 0.25), hull)
			pylon.rotation.z = side * 0.25
			ball(ship, Vector3(side * 1.35, 0.15, 0.8), Vector3(0.19, 0.2, 1.30), armor)
			box(ship, Vector3(side * 1.35, 0.28, 0.95), Vector3(0.09, 0.04, 1.8), glow)
			ball(ship, Vector3(side * 1.35, 0.15, -0.35), Vector3(0.15, 0.16, 0.2), material(Color("ff8e60"), 0.1, 2.0))
			ball(ship, Vector3(side * 1.35, 0.15, 2.0), Vector3(0.12, 0.12, 0.16), glow)
		for i in 24:
			var angle = TAU * i / 24.0
			ball(ship, Vector3(cos(angle) * 1.16, 0.26, -0.7 + sin(angle) * 0.95), Vector3(0.027, 0.018, 0.022), warm)
	else:
		ball(ship, Vector3.ZERO, Vector3(0.38, 0.20, 1.2), hull)
		ball(ship, Vector3(0, 0.08, -0.9), Vector3(0.42, 0.18, 0.4), armor)
		for side in [-1, 1]:
			var wing = box(ship, Vector3(side * 0.65, -0.08, 0.1), Vector3(1.3, 0.12, 0.7), armor)
			wing.rotation.z = side * -0.16
			wing.rotation.y = side * -0.45
			ball(ship, Vector3(side * 1.2, -0.14, 0.25), Vector3(0.14, 0.16, 0.7), hull)
			box(ship, Vector3(side * 1.2, -0.11, -0.15), Vector3(0.07, 0.06, 0.65), glow)
		ball(ship, Vector3(0, 0.1, 0.95), Vector3(0.2, 0.10, 0.1), glow)
		if kind == "command": ship.scale *= 1.2
		if kind == "scout": ship.scale *= 0.7
	return ship

func world_pos(pos: Vector2i) -> Vector3:
	return Vector3((pos.y - 3.5) * 3.5, 0, (pos.x - 3.5) * 3.5)

func make_grid() -> void:
	var lines = ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 9:
		var v = (i - 4) * 3.5
		lines.surface_add_vertex(Vector3(v, -0.7, -14))
		lines.surface_add_vertex(Vector3(v, -0.7, 14))
		lines.surface_add_vertex(Vector3(-14, -0.7, v))
		lines.surface_add_vertex(Vector3(14, -0.7, v))
	lines.surface_end()
	mesh(self, lines, Vector3.ZERO, Vector3.ONE, material(Color("123144"), 0, 0.4))

func refresh() -> void:
	if sim == null: return
	for child in fleet.get_children():
		fleet.remove_child(child)
		child.queue_free()
	player_ship = make_ship()
	fleet.add_child(player_ship)
	player_ship.position = world_pos(sim.sector)
	player_ship.rotation.y = -0.35
	var shield_mat = ShaderMaterial.new()
	shield_mat.shader = load("res://shaders/shield.gdshader")
	shield = ball(player_ship, Vector3.ZERO, Vector3(1.8, 0.65, 2.5), shield_mat)
	shield.visible = sim.shields_up
	for obj in sim.visible_objects():
		var node = Node3D.new()
		match obj.kind:
			"cruiser", "scout", "command", "supply":
				node.free()
				node = make_ship(true, obj.kind)
				node.rotation.y = 2.6
			"star":
				ball(node, Vector3.ZERO, Vector3.ONE * 0.48, material(Color("ffbd72"), 0, 3.5))
				var corona = ShaderMaterial.new()
				corona.shader = load("res://shaders/shield.gdshader")
				corona.set_shader_parameter("tint", Color(1.0, 0.4, 0.12, 0.45))
				ball(node, Vector3.ZERO, Vector3.ONE * 0.7, corona)
			"planet":
				ball(node, Vector3.ZERO, Vector3.ONE * 0.85, material(Color("347581"), 0.25))
				var rings = ring(node, Vector3.ZERO, 1.5, material(Color("8eacac"), 0.4))
				rings.rotation.z = 0.3
			"base":
				var metal = material(Color("8d9eaf"), 0.8)
				ball(node, Vector3.ZERO, Vector3(0.35, 0.85, 0.35), metal)
				ring(node, Vector3.ZERO, 1.0, metal)
				ring(node, Vector3(0, 0.08, 0), 0.95, material(Color("64e6d0"), 0.0, 2))
				for angle in [0, 2.094, 4.189]:
					var arm = box(node, Vector3.ZERO, Vector3(1.9, 0.12, 0.15), metal)
					arm.rotation.y = angle
		fleet.add_child(node)
		node.position = world_pos(sim.position_of(obj))
	last_quadrant = sim.quadrant

func play_effect(kind: String, origin: Vector2i, target: Vector2i) -> void:
	if kind == "warp":
		camera.fov = 70
		create_tween().tween_property(camera, "fov", 46.0, 1.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		return
	if kind == "move": return
	var from = world_pos(origin) + Vector3.UP * 0.3
	var to = world_pos(target) + Vector3.UP * 0.3
	if kind == "explosion":
		var explosion = ball(fx_root, to, Vector3.ONE * 0.15, material(Color("ff944b"), 0, 5))
		var tween = create_tween()
		tween.tween_property(explosion, "scale", Vector3.ONE * 1.8, 0.35)
		tween.tween_property(explosion, "scale", Vector3.ONE * 0.001, 0.55)
		tween.tween_callback(explosion.queue_free)
	elif kind == "torpedo":
		var torp = ball(fx_root, from, Vector3.ONE * 0.16, material(Color("ffb459"), 0, 5))
		var tween = create_tween()
		tween.tween_property(torp, "position", to, 0.5)
		tween.tween_callback(torp.queue_free)
	else:
		var beam = CylinderMesh.new()
		beam.top_radius = 0.025
		beam.bottom_radius = 0.025
		beam.height = from.distance_to(to)
		var instance = mesh(fx_root, beam, (from + to) / 2, Vector3.ONE, material(Color("ff5e63") if kind == "enemy_laser" else Color("65dcff"), 0, 4))
		instance.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
		var tween = create_tween()
		tween.tween_interval(0.3)
		tween.tween_property(instance, "scale", Vector3(0.01, 1, 0.01), 0.3)
		tween.tween_callback(instance.queue_free)

func _process(delta: float) -> void:
	clock += delta
	if cinematic:
		var focus = world_pos(sim.sector) if sim != null else Vector3.ZERO
		camera.position = focus + Vector3(6.5 + sin(clock * 0.06) * 0.5, 4.5, 8.5)
		camera.look_at(focus + Vector3(0, 0, -1.5))
	else:
		camera.position = camera_base
		camera.look_at(Vector3.ZERO)
	if is_instance_valid(player_ship): player_ship.position.y = sin(clock * 0.7) * 0.08
