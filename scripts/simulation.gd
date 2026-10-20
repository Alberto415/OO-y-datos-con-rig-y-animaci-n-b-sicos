extends Node
const Entity = preload("res://scripts/entity.gd")
const COUNT := 1000
var variant := "OO"
var entities: Array = []
var positions := PackedVector2Array()
var velocities := PackedVector2Array()

func setup(mode: String) -> void:
	variant = mode
	positions.resize(COUNT)
	velocities.resize(COUNT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261016
	for i in COUNT:
		var p := Vector2(rng.randf_range(0, 1120), rng.randf_range(0, 480))
		var v := Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(25, 80)
		positions[i] = p
		velocities[i] = v
		if variant == "OO":
			var entity = Entity.new()
			entity.pos = p
			entity.velocity = v
			add_child(entity)
			entities.append(entity)

func advance(dt: float) -> void:
	if variant == "OO":
		for entity in entities:
			entity.advance(dt)
	else:
		for i in COUNT:
			var p := positions[i] + velocities[i] * dt
			p.x = wrapf(p.x, 0.0, 1120.0)
			p.y = wrapf(p.y, 0.0, 480.0)
			positions[i] = p

func snapshot(target: PackedVector2Array) -> void:
	# Ambos caminos copian exactamente 1000 posiciones al mismo buffer visual.
	for i in COUNT:
		target[i] = entities[i].pos if variant == "OO" else positions[i]
