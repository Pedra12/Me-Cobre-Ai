extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const ZombieScript = preload("res://scripts/zombie.gd")
const HUDScript = preload("res://scripts/hud.gd")
const PickupScript = preload("res://scripts/pickup.gd")

var player
var hud
var zombies: Array = []
var pickups: Array = []
var wave := 0
var score := 0
var spawn_left := 0
var spawn_clock := 0.0
var rest_clock := 0.0
var game_started := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_environment()
	_build_city()
	player = PlayerScript.new()
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(18, 0.1, 18)
	hud = HUDScript.new()
	add_child(hud)
	hud.setup(player, self)
	hud.show_menu()
	set_process(true)

func start_game() -> void:
	for z in zombies:
		if is_instance_valid(z):
			z.queue_free()
	zombies.clear()
	wave = 0
	score = 0
	player.reset_player()
	player.global_position = Vector3(18, 0.1, 18)
	_spawn_pickups()
	game_started = true
	_next_wave()
	hud.set_game_visible(true)

func _process(delta: float) -> void:
	if not game_started:
		return
	if player.current_health <= 0.0:
		game_started = false
		hud.show_game_over()
		return
	zombies = zombies.filter(func(z): return is_instance_valid(z) and z.current_health > 0)
	if spawn_left > 0:
		spawn_clock -= delta
		if spawn_clock <= 0.0:
			_spawn_zombie()
			spawn_left -= 1
			spawn_clock = maxf(0.65, 2.0 - wave * 0.12)
	elif zombies.is_empty():
		rest_clock -= delta
		if rest_clock <= 0.0:
			_next_wave()
	hud.update_status(player.current_health, wave, score, zombies.size())

func _next_wave() -> void:
	wave += 1
	spawn_left = 4 + wave * 3
	rest_clock = 8.0
	spawn_clock = 0.5
	player.add_ammo(0, 8)
	player.add_ammo(1, 25)
	player.add_ammo(2, 4)
	hud.show_banner("HORDA %d" % wave)

func _spawn_pickups() -> void:
	for old in pickups:
		if is_instance_valid(old):
			old.queue_free()
	pickups.clear()
	var points := [
		[Vector3(-4, 0.15, 4), "ammo"], [Vector3(4, 0.15, 4), "med"],
		[Vector3(-18, 0.15, 30), "ammo"], [Vector3(18, 0.15, -30), "med"],
		[Vector3(-35, 0.15, 18), "ammo"], [Vector3(35, 0.15, -18), "ammo"],
		[Vector3(0, 0.15, 38), "med"]
	]
	for item in points:
		var pickup = PickupScript.new()
		pickup.pickup_type = item[1]
		pickup.target_player = player
		add_child(pickup)
		pickup.global_position = item[0]
		pickups.append(pickup)

func _spawn_zombie() -> void:
	var z = ZombieScript.new()
	z.name = "Zombie_%d" % (wave * 100 + spawn_left)
	var roll := rng.randf()
	if wave >= 4 and roll < 0.08 + wave * 0.01:
		z.zombie_type = "brute"
	elif wave >= 2 and roll < 0.25 + wave * 0.04:
		z.zombie_type = "runner"
	z.wave_level = wave
	z.target = player
	add_child(z)
	# A lógica original faz as hordas nascerem nas ruas, não dentro das casas.
	var lane := rng.randi_range(0, 3)
	var along := rng.randf_range(-47.0, 47.0)
	var offset := rng.randf_range(-2.0, 2.0)
	var spawn_point := Vector3.ZERO
	if lane == 0:
		spawn_point = Vector3(-18.0 + offset, 0.1, along)
	elif lane == 1:
		spawn_point = Vector3(18.0 + offset, 0.1, along)
	elif lane == 2:
		spawn_point = Vector3(along, 0.1, -18.0 + offset)
	else:
		spawn_point = Vector3(along, 0.1, 18.0 + offset)
	if spawn_point.distance_to(player.global_position) < 20.0:
		spawn_point = -spawn_point
	z.global_position = spawn_point
	z.died.connect(_on_zombie_killed)
	zombies.append(z)

func _on_zombie_killed(value: int) -> void:
	score += value
	hud.update_status(player.current_health, wave, score, zombies.size())

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.012, 0.025, 0.045)
	sky_mat.sky_horizon_color = Color(0.13, 0.16, 0.16)
	sky_mat.ground_bottom_color = Color(0.018, 0.025, 0.022)
	sky_mat.ground_horizon_color = Color(0.08, 0.09, 0.075)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.38, 0.48)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.13, 0.12)
	env.fog_density = 0.008
	world.environment = env
	add_child(world)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -32, 0)
	moon.light_color = Color(0.54, 0.66, 0.82)
	moon.light_energy = 0.72
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 85.0
	add_child(moon)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_color = Color(1.0, 0.42, 0.20)
	fill.light_energy = 0.18
	add_child(fill)

func _mat(color: Color, roughness := 0.9, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, solid := true) -> Node3D:
	var holder: Node3D
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		holder = body
	else:
		holder = Node3D.new()
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	holder.add_child(mesh)
	holder.position = pos
	parent.add_child(holder)
	return holder

func _build_city() -> void:
	var asphalt := _mat(Color(0.105, 0.115, 0.12))
	var road := _mat(Color(0.075, 0.083, 0.09))
	var concrete := _mat(Color(0.24, 0.25, 0.23))
	var grass := _mat(Color(0.075, 0.13, 0.065))
	var brick_a := _mat(Color(0.29, 0.19, 0.15))
	var brick_b := _mat(Color(0.22, 0.25, 0.24))
	var roof_mat := _mat(Color(0.10, 0.12, 0.12))
	var wood := _mat(Color(0.25, 0.16, 0.095))
	var metal := _mat(Color(0.12, 0.15, 0.16), 0.38, 0.72)
	_box(self, Vector3(170, 0.5, 170), Vector3(0, -0.3, 0), asphalt)
	_box(self, Vector3(112, 0.04, 10), Vector3(0, -0.015, -18), road, false)
	_box(self, Vector3(112, 0.04, 10), Vector3(0, -0.012, 18), road, false)
	_box(self, Vector3(10, 0.04, 112), Vector3(-18, -0.009, 0), road, false)
	_box(self, Vector3(10, 0.04, 112), Vector3(18, -0.006, 0), road, false)
	_box(self, Vector3(26, 0.08, 26), Vector3(0, 0.0, 0), grass, false)
	_build_fountain(concrete)
	for k in range(6):
		var a := float(k) * TAU / 6.0
		_build_tree(Vector3(cos(a) * 9.5, 0, sin(a) * 9.5))
	for x in [-18.0, 18.0]:
		for z in [-18.0, 18.0]:
			_build_lamp(Vector3(x, 0, z), metal)
	for gx in [-1, 0, 1]:
		for gz in [-1, 0, 1]:
			if gx == 0 and gz == 0:
				continue
			var center := Vector3(float(gx) * 36.0, 0, float(gz) * 36.0)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var p := center + Vector3(sx * 7.25, 0, sz * 7.25)
					_build_house(p, brick_a if (gx + gz) % 2 == 0 else brick_b, roof_mat, wood, metal)
			_build_block_debris(center, concrete, wood, metal)
	_build_boundary(concrete)
	_build_distant_blocks(brick_b)

func _build_house(p: Vector3, wall_mat: Material, roof_mat: Material, wood: Material, metal: Material) -> void:
	var w := 10.0
	var d := 9.0
	var h := 3.2
	_box(self, Vector3(w, 0.16, d), p + Vector3(0, 0.08, 0), _mat(Color(0.27, 0.25, 0.21)))
	var t := 0.28
	_box(self, Vector3(w, h, t), p + Vector3(0, h / 2.0, -d / 2.0), wall_mat)
	_box(self, Vector3(t, h, d), p + Vector3(-w / 2.0, h / 2.0, 0), wall_mat)
	_box(self, Vector3(t, h, d), p + Vector3(w / 2.0, h / 2.0, 0), wall_mat)
	# Parede frontal com abertura de porta para entrar no interior.
	_box(self, Vector3(3.7, h, t), p + Vector3(-3.15, h / 2.0, d / 2.0), wall_mat)
	_box(self, Vector3(3.7, h, t), p + Vector3(3.15, h / 2.0, d / 2.0), wall_mat)
	_box(self, Vector3(2.6, 0.7, t), p + Vector3(0, h - 0.35, d / 2.0), wall_mat)
	# Caixilhos e móveis: o interior permanece navegável.
	_box(self, Vector3(2.1, 0.08, 0.9), p + Vector3(-2.8, 0.75, -2.4), wood)
	_box(self, Vector3(0.12, 0.72, 0.12), p + Vector3(-3.65, 0.36, -2.75), wood)
	_box(self, Vector3(0.12, 0.72, 0.12), p + Vector3(-1.95, 0.36, -2.75), wood)
	_box(self, Vector3(2.2, 0.55, 0.95), p + Vector3(2.7, 0.35, -2.7), _mat(Color(0.22, 0.16, 0.12)))
	_box(self, Vector3(1.3, 1.6, 0.55), p + Vector3(3.8, 0.8, 1.2), metal)
	_box(self, Vector3(1.5, 0.7, 0.8), p + Vector3(-3.1, 0.35, 1.0), wood)
	# Beiral parcial: sem teto fechado para manter visibilidade em dispositivos móveis.
	_box(self, Vector3(w + 0.5, 0.18, 0.55), p + Vector3(0, h + 0.05, -d / 2.0), roof_mat, false)

func _build_fountain(mat: Material) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 2.6
	base.bottom_radius = 2.8
	base.height = 0.5
	var a := MeshInstance3D.new()
	a.mesh = base
	a.material_override = mat
	a.position = Vector3(0, 0.3, 0)
	add_child(a)
	var water := CylinderMesh.new()
	water.top_radius = 2.25
	water.bottom_radius = 2.25
	water.height = 0.08
	var b := MeshInstance3D.new()
	b.mesh = water
	b.material_override = _mat(Color(0.035, 0.16, 0.22), 0.18, 0.45)
	b.position = Vector3(0, 0.58, 0)
	add_child(b)
	_box(self, Vector3(0.55, 1.6, 0.55), Vector3(0, 1.35, 0), mat)

func _build_tree(p: Vector3) -> void:
	var trunk := _mat(Color(0.19, 0.12, 0.075))
	_box(self, Vector3(0.42, 3.6, 0.42), p + Vector3(0, 1.8, 0), trunk)
	for i in range(3):
		var crown := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.7 - i * 0.18
		mesh.height = 3.2 - i * 0.25
		crown.mesh = mesh
		crown.position = p + Vector3(0, 3.5 + i * 0.55, 0)
		crown.material_override = _mat(Color(0.075 + i * 0.01, 0.15 + i * 0.015, 0.065))
		add_child(crown)

func _build_lamp(p: Vector3, mat: Material) -> void:
	_box(self, Vector3(0.16, 5.0, 0.16), p + Vector3(0, 2.5, 0), mat)
	_box(self, Vector3(1.0, 0.12, 0.12), p + Vector3(0.45, 4.8, 0), mat, false)
	var light := OmniLight3D.new()
	light.position = p + Vector3(0.8, 4.55, 0)
	light.light_color = Color(1.0, 0.66, 0.35)
	light.light_energy = 1.6
	light.omni_range = 13.0
	add_child(light)

func _build_block_debris(p: Vector3, concrete: Material, wood: Material, metal: Material) -> void:
	for i in range(5):
		var x := rng.randf_range(-13, 13)
		var z := rng.randf_range(-13, 13)
		if absf(x) < 6 and absf(z) < 6:
			continue
		if i % 2 == 0:
			_box(self, Vector3(1.5, 0.8, 0.8), p + Vector3(x, 0.4, z), concrete)
		else:
			_box(self, Vector3(0.8, 0.9, 0.8), p + Vector3(x, 0.45, z), wood)
	for i in range(2):
		var barrel := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.36
		cylinder.bottom_radius = 0.36
		cylinder.height = 0.95
		barrel.mesh = cylinder
		barrel.position = p + Vector3(rng.randf_range(-11, 11), 0.48, rng.randf_range(-11, 11))
		barrel.material_override = metal
		add_child(barrel)

func _build_boundary(mat: Material) -> void:
	for item in [
		[Vector3(104, 4, 0.7), Vector3(0, 2, -51.5)],
		[Vector3(104, 4, 0.7), Vector3(0, 2, 51.5)],
		[Vector3(0.7, 4, 104), Vector3(-51.5, 2, 0)],
		[Vector3(0.7, 4, 104), Vector3(51.5, 2, 0)]
	]:
		_box(self, item[0], item[1], mat)

func _build_distant_blocks(mat: Material) -> void:
	for i in range(24):
		var angle := float(i) * TAU / 24.0
		var dist := 63.0
		var size := Vector3(12.0, rng.randf_range(18.0, 35.0), 12.0)
		var p := Vector3(cos(angle) * dist, size.y / 2.0, sin(angle) * dist)
		_box(self, size, p, mat, false)
