extends RefCounted

class_name Entity

var grid_x: int

var grid_y: int

var team: String

func _init(x: int, y: int, t: String):

	grid_x = x

	grid_y = y

	team = t

func get_position() -> Vector2i:

	return Vector2i(grid_x, grid_y)

func set_position(x: int, y: int):

	grid_x = x

	grid_y = y
