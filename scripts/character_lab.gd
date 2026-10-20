extends Node3D
## Controlador independiente del GLB visual, reproducción in-place con crossfade.
var visual: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var label: Label
var elapsed := 0.0
var clip := ""
var auto_play := true
var testing := false
var evidence := {"clip_seconds": {"Idle": 0.0, "Walk": 0.0, "Jump": 0.0}, "transitions": [], "finite_poses": true, "root_drift_max": 0.0, "bone_count": 0, "source": "imported GLB"}
var captured := {}

func _ready() -> void:
	testing = "--test-animation" in OS.get_cmdline_user_args()
	visual = load("res://assets/character/courier_rig.glb").instantiate()
	add_child(visual)
	player = visual.find_child("AnimationPlayer", true, false)
	var found = visual.find_children("*", "Skeleton3D", true, false)
	skeleton = found[0]
	evidence.bone_count = skeleton.get_bone_count()
	player.playback_default_blend_time = 0.2
	for clip_name in ["Idle", "Walk", "Jump"]:
		player.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
	print("IMPORTED GLB clips=", player.get_animation_list(), " bones=", skeleton.get_bone_count())
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("101b2b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a3bad7")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 1.5
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.65
	cylinder.bottom_radius = 1.65
	cylinder.height = 0.12
	floor_mesh.mesh = cylinder
	floor_mesh.position.y = -0.10
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("26445e")
	floor_mesh.material_override = material
	add_child(floor_mesh)
	var camera := Camera3D.new()
	camera.fov = 42.0
	camera.position = Vector3(3.2, 2.0, -4.5)
	add_child(camera)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(45, 35)
	label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(label)
	set_clip("Idle")

func set_clip(next: String) -> void:
	if clip == next: return
	if not clip.is_empty(): evidence.transitions.append({"from": clip, "to": next, "at_s": elapsed, "blend_s": 0.2})
	clip = next
	player.play(clip, 0.2)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1, KEY_2, KEY_3]:
			auto_play = false
			set_clip(["Idle", "Walk", "Jump"][event.keycode - KEY_1])
		if event.keycode == KEY_A: auto_play = not auto_play
		if event.keycode == KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/benchmark.tscn")

func _process(delta: float) -> void:
	evidence.clip_seconds[clip] += delta
	elapsed += delta
	if auto_play: set_clip(["Idle", "Walk", "Jump"][int(elapsed / 10.0) % 3])
	evidence.root_drift_max = maxf(evidence.root_drift_max, visual.position.length())
	for i in skeleton.get_bone_count():
		var pose := skeleton.get_bone_global_pose(i)
		if not pose.origin.is_finite() or not pose.basis.is_finite(): evidence.finite_poses = false
	label.text = "LAB 02  /  RIG Y CLIPS\nMensajero de Tarea 1  |  %s\n%.1f s  |  GLB importado  |  6 huesos\nSkin rigida: peso 1 por pieza\nCrossfade 0.20 s  |  In-place\n\n1 Idle   2 Walk   3 Jump\nA automatico   Esc benchmark" % [clip, elapsed]
	if evidence.clip_seconds[clip] >= 5.25 and not captured.has(clip):
		captured[clip] = true
		capture.call_deferred(clip)
	if testing:
		if elapsed >= 60.1:
			evidence["pass"] = evidence.finite_poses and evidence.root_drift_max < 0.00001 and evidence.bone_count == 6
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/evidence"))
			var file := FileAccess.open("res://output/evidence/animation_checks.json", FileAccess.WRITE)
			file.store_string(JSON.stringify(evidence, "\t"))
			print("ANIMATION CHECKS ", JSON.stringify(evidence))
			get_tree().quit(0 if evidence["pass"] else 1)
	if "--animation-video" in OS.get_cmdline_user_args() and elapsed >= 70.0:
		get_tree().quit()

func capture(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/evidence/clip_" + name_value + ".png")
