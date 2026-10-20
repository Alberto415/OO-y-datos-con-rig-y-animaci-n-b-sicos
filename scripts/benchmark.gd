extends Node2D
const Simulation = preload("res://scripts/simulation.gd")
const ORDER := ["OO", "DATOS", "DATOS", "OO", "OO", "DATOS"]
var sim: Node
var visual := PackedVector2Array()
var rows: Array[PackedStringArray] = []
var run_index := 0
var started := 0
var previous := 0
var running := false
var automatic := false
var out_dir := "res://results"
var warmup := 5.0
var duration := 30.0
var current_block := 0.0
var next_hud := 0
var draw_count := 0
var label: Label
var session_id := ""
var demo := false
var demo_elapsed := 0.0
var screenshot_saved := false
var demo_total := 0.0

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	visual.resize(1000)
	session_id = Time.get_datetime_string_from_system().replace(":", "-")
	for arg in OS.get_cmdline_user_args():
		if arg == "--suite": automatic = true
		if arg == "--demo":
			automatic = true
			demo = true
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
		if arg == "--smoke":
			warmup = 0.2
			duration = 0.5
			automatic = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(70, 35)
	label.add_theme_font_size_override("font_size", 19)
	canvas.add_child(label)
	var button := Button.new()
	button.text = "Iniciar 6 corridas (5 s + 30 s cada una)"
	button.position = Vector2(70, 650)
	button.pressed.connect(func():
		if not running:
			automatic = true
			run_index = 0
			session_id = Time.get_datetime_string_from_system().replace(":", "-") + "-" + str(Time.get_ticks_msec())
			begin_run())
	canvas.add_child(button)
	var animation_button := Button.new()
	animation_button.text = "Laboratorio de animacion"
	animation_button.position = Vector2(690, 650)
	animation_button.pressed.connect(func():
		if not running: get_tree().change_scene_to_file("res://scenes/character.tscn"))
	canvas.add_child(animation_button)
	preview()
	if automatic: begin_run()

func preview() -> void:
	if is_instance_valid(sim):
		remove_child(sim)
		sim.free()
	sim = Simulation.new()
	add_child(sim)
	sim.setup(ORDER[run_index])
	sim.snapshot(visual)

func begin_run() -> void:
	preview()
	rows.clear()
	draw_count = 0
	running = true
	started = Time.get_ticks_usec()
	demo_elapsed = 0.0
	previous = started
	next_hud = 0
	print("RUN ", run_index + 1, " ", ORDER[run_index], " warmup=", warmup, " measure=", duration)

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := (now - previous) / 1000.0
	previous = now
	var elapsed := (now - started) / 1000000.0 if running else 0.0
	if demo:
		demo_total += delta
		if demo_total >= 40.0:
			get_tree().quit()
		demo_elapsed += delta
		elapsed = demo_elapsed
	if running and elapsed >= warmup + duration:
		finish_run()
		return
	var t0 := Time.get_ticks_usec()
	sim.advance(delta)
	var t1 := Time.get_ticks_usec()
	sim.snapshot(visual)
	var t2 := Time.get_ticks_usec()
	current_block = (t1 - t0) / 1000.0
	if running and elapsed >= warmup:
		rows.append(PackedStringArray([str(rows.size()), "%.6f" % (elapsed - warmup),
			"%.6f" % (delta * 1000), "%.6f" % frame_ms, "%.6f" % current_block,
			"%.6f" % ((t2 - t1) / 1000.0), str(draw_count)]))
	queue_redraw()
	if demo and elapsed >= 8.0 and not screenshot_saved:
		screenshot_saved = true
		capture.call_deferred()
	if now >= next_hud:
		next_hud = now + 250000
		var phase := "CALENTAMIENTO" if elapsed < warmup else "MEDICION"
		if not running: phase = "VISTA PREVIA - inicia la suite para guardar CSV"
		label.text = "LAB 02  /  OBJETOS Y DATOS\n1 000 entidades  |  %s  |  corrida %d/6\n%s  %.1f s  |  bloque %.3f ms\nMismo movimiento, semilla y dibujo. VSync OFF. 1280 x 720.%s" % [ORDER[run_index], run_index + 1, phase, elapsed, current_block, "\nVIDEO DEMOSTRATIVO - tiempos excluidos del analisis" if demo else ""]

func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/evidence/benchmark.png")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101b2b"))
	draw_rect(Rect2(70, 150, 1120, 480), Color("182b40"))
	for x in range(70, 1191, 80):
		draw_line(Vector2(x, 150), Vector2(x, 630), Color("20364d"))
	for i in visual.size():
		var color := Color("54ddbe") if i % 2 == 0 else Color("69adff")
		draw_circle(visual[i] + Vector2(70, 150), 2.4, color, true, -1, false)
	draw_count += 1

func finish_run() -> void:
	running = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var stem := "%s/%s_%02d_%s" % [out_dir, session_id, run_index + 1, ORDER[run_index]]
	var file := FileAccess.open(stem + ".csv", FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar CSV: " + stem)
		get_tree().quit(1)
		return
	file.store_csv_line(PackedStringArray(["frame", "elapsed_s", "delta_ms", "frame_wall_ms", "movement_block_ms", "snapshot_ms", "draw_count"]))
	for row in rows: file.store_csv_line(row)
	file.close()
	var meta := {
		"variant": ORDER[run_index], "run": run_index + 1, "seed": 20261016,
		"entities": 1000, "warmup_s": warmup, "measurement_s": duration,
		"wall_total_s": (Time.get_ticks_usec() - started) / 1000000.0,
		"engine": Engine.get_version_info(), "os": OS.get_name(),
		"cpu": OS.get_processor_name(), "logical_cpus": OS.get_processor_count(),
		"memory": OS.get_memory_info(), "gpu": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"viewport": str(get_viewport_rect().size), "vsync": DisplayServer.window_get_vsync_mode(),
		"debug_build": OS.is_debug_build(), "demo": demo,
		"samples": rows.size(), "draws": draw_count,
		"capture": "Time.get_ticks_usec; buffered per frame; CSV after run; no profiler CPU capture",
		"output": ProjectSettings.globalize_path(stem + ".csv")}
	var json := FileAccess.open(stem + ".json", FileAccess.WRITE)
	json.store_string(JSON.stringify(meta, "\t"))
	json.close()
	print("SAVED ", stem, " samples=", rows.size())
	run_index += 1
	if run_index < ORDER.size() and automatic:
		begin_run()
	else:
		run_index = 0
		if "--suite" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args():
			get_tree().quit()
