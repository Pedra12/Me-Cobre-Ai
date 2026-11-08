extends CharacterBody3D

signal died(points: int)

var target
var current_health := 50.0
var move_speed := 1.6
var attack_damage := 8.0
var attack_timer := 0.0
var stagger_timer := 0.0
var zombie_type := "walker"
var wave_level := 1
var dead := false
var visual_root: Node3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var walk_phase := 0.0
var animation_player: AnimationPlayer
var idle_animation: StringName = &""
var walk_animation: StringName = &""
var attack_animation: StringName = &""
var hit_animation: StringName = &""
var death_animation: StringName = &""

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)

	if zombie_type == "runner":
		current_health = 30.0
		move_speed = 4.2
		attack_damage = 6.0
		scale = Vector3.ONE * 0.90
	elif zombie_type == "brute":
		current_health = 320.0
		move_speed = 1.2
		attack_damage = 25.0
		scale = Vector3.ONE * 1.35
	current_health *= 1.0 + float(wave_level) * 0.12
	move_speed *= minf(1.0 + float(wave_level) * 0.04, 1.8)
	_build_model()

func _mat(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

func _build_model() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	var model_file := "Zombie_Basic.gltf"
	if zombie_type == "runner":
		model_file = "Zombie_Arm.gltf"
	elif zombie_type == "brute":
		model_file = "Zombie_Chubby.gltf"
	elif randf() < 0.35:
		model_file = "Zombie_Ribcage.gltf"
	var model_path := "res://assets/zombies/" + model_file
	if ResourceLoader.exists(model_path):
		var packed := load(model_path) as PackedScene
		if packed != null:
			var model := packed.instantiate() as Node3D
			if model != null:
				visual_root.add_child(model)
				animation_player = _find_animation_player(model)
				if animation_player != null:
					idle_animation = _find_animation(["idle", "stand"])
					walk_animation = _find_animation(["walk", "run", "move"])
					attack_animation = _find_animation(["attack", "punch", "bite"])
					hit_animation = _find_animation(["hit", "damage", "hurt"])
					death_animation = _find_animation(["death", "die", "dead"])
					_play_animation(idle_animation)
				return
	_build_procedural_model()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_animation(keywords: Array[String]) -> StringName:
	if animation_player == null:
		return &""
	for clip in animation_player.get_animation_list():
		var lower := String(clip).to_lower()
		for keyword in keywords:
			if lower.contains(keyword):
				return StringName(clip)
	return &""

func _play_animation(clip: StringName) -> void:
	if animation_player == null or clip == &"":
		return
	if animation_player.current_animation != clip:
		animation_player.play(clip)

func _build_procedural_model() -> void:
	var skin := _mat(Color(0.42, 0.49, 0.37))
	var clothes := _mat(Color(0.22, 0.28, 0.20))
	var pants := _mat(Color(0.12, 0.14, 0.13))
	var dark := _mat(Color(0.035, 0.025, 0.022))
	var eyes := _mat(Color(0.8, 0.025, 0.012), 0.3)
	var torso := CapsuleMesh.new()
	torso.radius = 0.32
	torso.height = 0.88
	_part(visual_root, torso, Vector3(0, 1.12, 0), clothes)
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.43
	_part(visual_root, head, Vector3(0, 1.78, -0.015), skin)
	var jaw := BoxMesh.new()
	jaw.size = Vector3(0.26, 0.10, 0.20)
	_part(visual_root, jaw, Vector3(0, 1.58, -0.10), dark)
	var eye := SphereMesh.new()
	eye.radius = 0.035
	eye.height = 0.07
	_part(visual_root, eye, Vector3(-0.085, 1.80, -0.205), eyes)
	_part(visual_root, eye, Vector3(0.085, 1.80, -0.205), eyes)
	var leg := CapsuleMesh.new()
	leg.radius = 0.105
	leg.height = 0.78
	left_leg = _part(visual_root, leg, Vector3(-0.16, 0.43, 0), pants)
	right_leg = _part(visual_root, leg, Vector3(0.16, 0.43, 0), pants)
	var arm := CapsuleMesh.new()
	arm.radius = 0.09
	arm.height = 0.72
	left_arm = _part(visual_root, arm, Vector3(-0.40, 1.05, -0.06), skin)
	left_arm.rotation.z = -0.32
	right_arm = _part(visual_root, arm, Vector3(0.40, 1.05, -0.06), skin)
	right_arm.rotation.z = 0.32
	var blood := _mat(Color(0.18, 0.015, 0.012))
	var stain := SphereMesh.new()
	stain.radius = 0.12
	stain.height = 0.08
	_part(visual_root, stain, Vector3(0.17, 1.34, -0.24), blood)

func take_damage(amount: float) -> void:
	if dead:
		return
	current_health -= amount
	stagger_timer = 0.12
	if current_health <= 0.0:
		dead = true
		died.emit(100)
		collision_layer = 0
		collision_mask = 0
		if death_animation != &"":
			_play_animation(death_animation)
			get_tree().create_timer(1.25).timeout.connect(queue_free)
		else:
			queue_free()
	elif hit_animation != &"":
		_play_animation(hit_animation)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	var to_target := target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()
	var moving := distance > 1.25
	if moving:
		var dir := to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		rotation.y = atan2(-dir.x, -dir.z)
	else:
		velocity.x = 0
		velocity.z = 0
		if attack_timer <= 0.0 and target.has_method("take_damage"):
			target.take_damage(attack_damage)
			attack_timer = 1.0
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.1
	if stagger_timer > 0.0:
		velocity.x *= 0.25
		velocity.z *= 0.25
	move_and_slide()
	if animation_player != null:
		if stagger_timer > 0.0:
			_play_animation(hit_animation)
		elif not moving:
			_play_animation(attack_animation if attack_timer > 0.0 else idle_animation)
		elif moving:
			_play_animation(walk_animation if walk_animation != &"" else idle_animation)
	else:
		walk_phase += delta * (move_speed * 2.6 if moving and is_on_floor() else 1.4)
		var swing := sin(walk_phase) * (0.62 if moving else 0.045)
		if left_leg != null:
			left_leg.rotation.x = swing
			right_leg.rotation.x = -swing
			left_arm.rotation.x = -swing * 0.72 - (0.75 if not moving else 0.0)
			right_arm.rotation.x = swing * 0.72 - (0.75 if not moving else 0.0)
