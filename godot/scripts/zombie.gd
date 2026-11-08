extends CharacterBody3D

signal died(points: int)

var target
var current_health := 50.0
var move_speed := 1.6
var attack_damage := 8.0
var attack_timer := 0.0
var stagger_timer := 0.0
var zombie_type := "walker"
var dead := false
var visual_root: Node3D

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
	_build_model()
	if randf() < 0.20:
		zombie_type = "runner"
		current_health = 30.0
		move_speed = 4.2
		attack_damage = 6.0
	elif randf() < 0.08:
		zombie_type = "brute"
		current_health = 320.0
		move_speed = 1.2
		attack_damage = 25.0
		scale = Vector3.ONE * 1.35

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
	_part(visual_root, leg, Vector3(-0.16, 0.43, 0), pants)
	_part(visual_root, leg, Vector3(0.16, 0.43, 0), pants)
	var arm := CapsuleMesh.new()
	arm.radius = 0.09
	arm.height = 0.72
	var left := _part(visual_root, arm, Vector3(-0.40, 1.05, -0.06), skin)
	left.rotation.z = -0.32
	var right := _part(visual_root, arm, Vector3(0.40, 1.05, -0.06), skin)
	right.rotation.z = 0.32
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
		queue_free()

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	var to_target := target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()
	if distance > 1.25:
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
