extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")

func _initialize() -> void:
	var oo := Simulation.new()
	var data := Simulation.new()
	root.add_child(oo)
	root.add_child(data)
	oo.setup("OO")
	data.setup("DATOS")
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	a.resize(1000)
	b.resize(1000)
	var maximum := 0.0
	for step in 2100:
		oo.advance(1.0 / 60.0)
		data.advance(1.0 / 60.0)
		oo.snapshot(a)
		data.snapshot(b)
		for i in 1000:
			maximum = maxf(maximum, a[i].distance_to(b[i]))
			if maximum > 0.001 or not a[i].is_finite():
				push_error("Equivalence failed")
				quit(1)
				return
	print("PASS: 1000 entities x 2100 steps, max position error = ", maximum)
	quit()
