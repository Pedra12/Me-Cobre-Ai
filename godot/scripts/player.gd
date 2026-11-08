extends CharacterBody3D

signal zombie_killed(points: int)

const WEAPONS := [
	{"name":"Pistola", "damage":25.0, "range":40.0, "rate":0.30, "mag":12, "reserve":60, "reload":1.5, "pellets":1},
	{"name":"Rifle", "damage":20.0, "range":50.0, "rate":0.10, "mag":30, "reserve":120, "reload":2.0, "pellets":1},
	{"name":"Espingarda", "damage":14.0, "range":16.0, "rate":0.90, "mag":6, "reserve":30, "reload":2.6, "pellets":8}
]
var ammo: Array[Dictionary] = []
var weapon_index := 1
var current_health := 100.0
var yaw := 0.0
var pitch := 0.0
var sensitivity := 0.0028
var move_input := Vector2.ZERO
var look_input := Vector2.ZERO
var shooting := false
var aiming := false
var reload_timer := 0.0
var fire_timer := 0.0
var jump_requested := false
var camera: Camera3D
var gun_root: Node3D
var muzzle_flash: OmniLight3D
var recoil := 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	var body_mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.34
	body.height = 1.75
	body_mesh.mesh = body
	body_mesh.position.y = 0.9
	body_mesh.material_override = _material(Color(0.20, 0.26, 0.18))
	add_child(body_mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.position.y = 1.82
	head.material_override = _material(Color(0.48, 0.37, 0.29))
	add_child(head)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.58, 0)
	camera.current = true
	camera.fov = 75.0
	add_child(camera)
	_build_weapon()
	_setup_input()
	ammo = [
		{"mag":12, "reserve":60},
		{"mag":30, "reserve":120},
		{"mag":6, "reserve":30}
	]
	_update_weapon_visibility()

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.78
	return m

func _build_weapon() -> void:
	gun_root = Node3D.new()
	gun_root.position = Vector3(0.28, -0.23, -0.48)
	camera.add_child(gun_root)
	var receiver := MeshInstance3D.new()
	var receiver_mesh := BoxMesh.new()
	receiver_mesh.size = Vector3(0.13, 0.13, 0.52)
	receiver.mesh = receiver_mesh
	receiver.material_override = _material(Color(0.09, 0.10, 0.105))
	gun_root.add_child(receiver)
	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.035
	barrel_mesh.bottom_radius = 0.035
	barrel_mesh.height = 0.42
	barrel_mesh.radial_segments = 12
	barrel.mesh = barrel_mesh
	barrel.rotation.x = PI / 2.0
	barrel.position.z = -0.42
	barrel.material_override = _material(Color(0.055, 0.06, 0.065))
	gun_root.add_child(barrel)
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.11, 0.24, 0.13)
	grip.mesh = grip_mesh
	grip.position = Vector3(0, -0.15, 0.12)
	grip.material_override = _material(Color(0.16, 0.12, 0.08))
	gun_root.add_child(grip)
	muzzle_flash = OmniLight3D.new()
	muzzle_flash.light_color = Color(1.0, 0.52, 0.12)
	muzzle_flash.light_energy = 0.0
	muzzle_flash.omni_range = 4.0
	muzzle_flash.position.z = -0.68
	camera.add_child(muzzle_flash)

func _setup_input() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("jump", KEY_SPACE)
	_bind_key("reload", KEY_R)
	_bind_key("fire", KEY_F)
	_bind_key("aim", KEY_SHIFT)

func _bind_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		add_look(event.relative)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: select_weapon(0)
		if event.keycode == KEY_2: select_weapon(1)
		if event.keycode == KEY_3: select_weapon(2)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: shooting = event.pressed
		if event.button_index == MOUSE_BUTTON_RIGHT: aiming = event.pressed

func add_look(delta: Vector2) -> void:
	yaw -= delta.x * sensitivity
	pitch = clampf(pitch - delta.y * sensitivity, -1.35, 1.35)
	rotation.y = yaw
	camera.rotation.x = pitch

func set_move_input(value: Vector2) -> void:
	move_input = value.limit_length(1.0)

func set_shooting(value: bool) -> void:
	shooting = value

func set_aiming(value: bool) -> void:
	aiming = value
	camera.fov = 48.0 if aiming else 75.0

func request_jump() -> void:
	jump_requested = true

func select_weapon(index: int) -> void:
	if index < 0 or index >= WEAPONS.size():
		return
	weapon_index = index
	_update_weapon_visibility()

func _update_weapon_visibility() -> void:
	if not is_inside_tree() or gun_root == null:
		return
	gun_root.scale = Vector3.ONE * (1.0 + weapon_index * 0.04)
	gun_root.position.y = -0.23 - weapon_index * 0.015

func request_reload() -> void:
	if reload_timer > 0.0:
		return
	var data: Dictionary = WEAPONS[weapon_index]
	if ammo[weapon_index].mag >= data.mag or ammo[weapon_index].reserve <= 0:
		return
	reload_timer = data.reload
	shooting = false

func add_ammo(index: int, amount: int) -> void:
	if index >= 0 and index < ammo.size():
		ammo[index].reserve += amount

func reset_player() -> void:
	current_health = 100.0
	for i in range(3):
		ammo[i].mag = int(WEAPONS[i].mag)
		ammo[i].reserve = int(WEAPONS[i].reserve)
	weapon_index = 1
	reload_timer = 0.0
	fire_timer = 0.0
	_update_weapon_visibility()

func take_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move := move_input if move_input.length() > 0.05 else keyboard
	var direction := (transform.basis * Vector3(move.x, 0, move.y)).normalized()
	var speed := 3.0 if aiming else 5.5
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif jump_requested or Input.is_action_just_pressed("jump"):
		velocity.y = 7.0
	jump_requested = false
	move_and_slide()
	fire_timer = maxf(0.0, fire_timer - delta)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var data: Dictionary = WEAPONS[weapon_index]
			var needed: int = int(data.mag) - int(ammo[weapon_index].mag)
			var loaded: int = mini(needed, int(ammo[weapon_index].reserve))
			ammo[weapon_index].mag += loaded
			ammo[weapon_index].reserve -= loaded
	if shooting and fire_timer <= 0.0 and reload_timer <= 0.0:
		_fire_weapon()
	recoil = move_toward(recoil, 0.0, delta * 3.5)
	gun_root.position.y = (-0.23 if not aiming else -0.16) - recoil * 0.045
	muzzle_flash.light_energy = move_toward(muzzle_flash.light_energy, 0.0, delta * 18.0)

func _fire_weapon() -> void:
	var data: Dictionary = WEAPONS[weapon_index]
	if ammo[weapon_index].mag <= 0:
		request_reload()
		return
	ammo[weapon_index].mag -= 1
	fire_timer = float(data.rate)
	recoil = 1.0
	muzzle_flash.light_energy = 2.8
	var pellets: int = int(data.pellets)
	for i in range(pellets):
		var spread := 0.0 if pellets == 1 else 0.075
		var direction := -camera.global_transform.basis.z
		direction += camera.global_transform.basis.x * randf_range(-spread, spread)
		direction += camera.global_transform.basis.y * randf_range(-spread, spread)
		direction = direction.normalized()
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * float(data.range))
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider = hit.collider
			if collider.has_method("take_damage"):
				var dealt := float(data.damage)
				collider.take_damage(dealt)
				if collider.current_health <= 0.0:
					zombie_killed.emit(100)
