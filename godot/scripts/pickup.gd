extends Area3D

var pickup_type := "ammo"
var target_player

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.25
	shape.shape = sphere
	add_child(shape)
	var crate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.55, 0.65)
	crate.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.42, 0.13) if pickup_type == "ammo" else Color(0.72, 0.12, 0.10)
	material.metallic = 0.25
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.35
	crate.material_override = material
	crate.position.y = 0.45
	add_child(crate)
	var mark := MeshInstance3D.new()
	var mark_mesh := BoxMesh.new()
	mark_mesh.size = Vector3(0.14, 0.04, 0.48) if pickup_type == "med" else Vector3(0.48, 0.04, 0.14)
	mark.mesh = mark_mesh
	mark.position.y = 0.76
	mark.material_override = StandardMaterial3D.new()
	mark.material_override.albedo_color = Color(1.0, 0.92, 0.70)
	add_child(mark)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(delta * 0.7)

func _on_body_entered(body: Node3D) -> void:
	if body != target_player:
		return
	if pickup_type == "ammo":
		body.add_ammo(0, 24)
		body.add_ammo(1, 60)
		body.add_ammo(2, 12)
	else:
		body.heal(40.0)
	queue_free()
