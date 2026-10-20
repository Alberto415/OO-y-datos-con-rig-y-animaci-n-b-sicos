extends Node
## Una entidad OO: estado y comportamiento encapsulados, sin callback individual.
var pos := Vector2.ZERO
var velocity := Vector2.ZERO

func advance(dt: float) -> void:
	pos += velocity * dt
	pos.x = wrapf(pos.x, 0.0, 1120.0)
	pos.y = wrapf(pos.y, 0.0, 480.0)
