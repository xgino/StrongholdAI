extends Entity
class_name HomeBase

var spawn_timer: float = 0.0

signal unit_spawned(position)

func _init(x: int, y: int, t: String):
	super(x, y, t)

func get_spawn_interval(checkpoint_count: int) -> float:
	var reduced_time = GameConfig.BASE_SPAWN_INTERVAL - (checkpoint_count * GameConfig.CHECKPOINT_SPAWN_BONUS)
	return max(GameConfig.MIN_SPAWN_INTERVAL, reduced_time)

func update(delta: float, checkpoint_count: int):
	var spawn_interval = get_spawn_interval(checkpoint_count)
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		unit_spawned.emit(Vector2i(grid_x, grid_y))

func get_base_cells() -> Array[Vector2i]:
	return [Vector2i(grid_x, grid_y)]
