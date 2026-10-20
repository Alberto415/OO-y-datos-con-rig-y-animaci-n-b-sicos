extends SceneTree
## Autoría reproducible de skin rígida sobre las mismas 30 piezas de Tarea 1.
var visual: Node3D
var skeleton: Skeleton3D
var mapping := {}

func _initialize() -> void:
	call_deferred("build")

func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = visual
		own(child)

func build() -> void:
	var source = load("res://assets/source/courier_original.tscn").instantiate()
	root.add_child(source)
	visual = Node3D.new()
	visual.name = "CourierRig"
	root.add_child(visual)
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	visual.add_child(skeleton)
	skeleton.add_bone("Root")
	skeleton.set_bone_rest(0, Transform3D.IDENTITY)
	var body = source.get_node("Body")
	for part in ["LeftArm", "RightArm", "LeftLeg", "RightLeg", "Scarf"]:
		var idx := skeleton.add_bone(part)
		skeleton.set_bone_parent(idx, 0)
		skeleton.set_bone_rest(idx, Transform3D(Basis.IDENTITY, body.get_node(part).position))
		mapping[part] = idx
	skeleton.reset_bone_poses()
	var skin := skeleton.create_skin_from_rest_transforms()
	for child in body.get_children():
		if child is MeshInstance3D:
			convert_mesh(child, 0, skin)
		else:
			for mesh in child.get_children():
				if mesh is MeshInstance3D: convert_mesh(mesh, mapping[child.name], skin)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	visual.add_child(player)
	var library := AnimationLibrary.new()
	for clip in ["Idle", "Walk", "Jump"]:
		library.add_animation(clip, make_clip(clip))
	player.add_animation_library("", library)
	player.playback_default_blend_time = 0.2
	own(visual)
	var scene := PackedScene.new()
	scene.pack(visual)
	ResourceSaver.save(scene, "res://assets/character/courier_rig.tscn")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(visual, state)
	if err == OK: err = doc.write_to_filesystem(state, "res://assets/character/courier_rig.glb")
	print("RIG: 6 bones, 30 rigid-skinned meshes, 3 clips; GLB export code=", err)
	quit(err)

func convert_mesh(source: MeshInstance3D, bone: int, skin: Skin) -> void:
	var mesh := ArrayMesh.new()
	for surface in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(vertices.size() * 4)
		weights.resize(vertices.size() * 4)
		var trans := source.global_transform
		for i in vertices.size():
			vertices[i] = trans * vertices[i]
			normals[i] = (trans.basis.inverse().transposed() * normals[i]).normalized()
			bones[i * 4] = bone
			weights[i * 4] = 1.0
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		# Tangentes de las primitivas dejan de ser válidas tras hornear escala.
		arrays[Mesh.ARRAY_TANGENT] = null
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(surface, source.mesh.surface_get_material(surface))
	var instance := MeshInstance3D.new()
	instance.name = source.name
	instance.mesh = mesh
	instance.skin = skin
	skeleton.add_child(instance)
	instance.skeleton = NodePath("..")

func make_clip(clip: String) -> Animation:
	var animation := Animation.new()
	animation.length = 1.2 if clip == "Jump" else 1.0
	animation.loop_mode = Animation.LOOP_LINEAR
	for bone in ["Root", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Scarf"]:
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Skeleton3D:" + bone))
		for i in 25:
			var t := i / 24.0
			var angle := 0.0
			if clip == "Idle":
				if bone == "Scarf": angle = sin(t * TAU) * 0.06
				if bone.ends_with("Arm"): angle = sin(t * TAU) * 0.025
			if clip == "Walk":
				var sign_value := -1.0 if bone in ["RightLeg", "LeftArm"] else 1.0
				if bone.ends_with("Arm") or bone.ends_with("Leg"): angle = sin(t * TAU) * 0.48 * sign_value
				if bone == "Scarf": angle = 0.18 + sin(t * TAU) * 0.07
			if clip == "Jump":
				var envelope := sin(t * PI)
				if bone.ends_with("Arm"): angle = -1.1 * envelope
				if bone == "LeftLeg": angle = -0.5 * envelope
				if bone == "RightLeg": angle = 0.4 * envelope
				if bone == "Scarf": angle = 0.25 * envelope
			animation.rotation_track_insert_key(track, t * animation.length, Quaternion(Vector3.RIGHT, angle))
	return animation
