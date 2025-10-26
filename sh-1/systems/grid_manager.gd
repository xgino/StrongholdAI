extends RefCounted
class_name GridManager

var width: int
var height: int
var cells: Array  # [x][y] -> Array of entities (big cells)
var sub_grid_occupied: Array  # [sub_x][sub_y] -> Unit or null (for collision)

func _init(w: int, h: int):
	width = w
	height = h
	cells = []
	sub_grid_occupied = []
	
	# Big cell grid
	for x in range(width):
		cells.append([])
		for y in range(height):
			cells[x].append([])
	
	# Sub-grid for collision (64x64)
	for x in range(GameConfig.TOTAL_SUB_WIDTH):
		sub_grid_occupied.append([])
		for y in range(GameConfig.TOTAL_SUB_HEIGHT):
			sub_grid_occupied[x].append(null)

func is_valid(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func is_sub_valid(sub_x: int, sub_y: int) -> bool:
	return sub_x >= 0 and sub_x < GameConfig.TOTAL_SUB_WIDTH and \
		   sub_y >= 0 and sub_y < GameConfig.TOTAL_SUB_HEIGHT

func add_entity(entity: Entity) -> bool:
	if not is_valid(entity.grid_x, entity.grid_y):
		return false
	
	cells[entity.grid_x][entity.grid_y].append(entity)
	
	# For units, mark sub-grid occupied
	if entity is Unit:
		if is_sub_valid(entity.sub_grid_x, entity.sub_grid_y):
			if sub_grid_occupied[entity.sub_grid_x][entity.sub_grid_y] == null:
				sub_grid_occupied[entity.sub_grid_x][entity.sub_grid_y] = entity
				return true
			else:
				# Sub-cell occupied, remove from big cell
				cells[entity.grid_x][entity.grid_y].erase(entity)
				return false
	
	return true

func remove_entity(entity: Entity):
	if is_valid(entity.grid_x, entity.grid_y):
		cells[entity.grid_x][entity.grid_y].erase(entity)
	
	if entity is Unit and is_sub_valid(entity.sub_grid_x, entity.sub_grid_y):
		sub_grid_occupied[entity.sub_grid_x][entity.sub_grid_y] = null

func move_unit_sub_grid(unit: Unit, new_sub_x: int, new_sub_y: int) -> bool:
	if not is_sub_valid(new_sub_x, new_sub_y):
		return false
	
	# Check if destination sub-cell is free
	if sub_grid_occupied[new_sub_x][new_sub_y] != null:
		return false
	
	# Remove from old position
	remove_entity(unit)
	
	# Update position
	unit.move_to_sub_cell(new_sub_x, new_sub_y)
	
	# Add to new position
	add_entity(unit)
	
	return true

func get_entities_at(x: int, y: int) -> Array:
	if is_valid(x, y):
		return cells[x][y]
	return []

func get_units_at(x: int, y: int) -> Array[Unit]:
	var units: Array[Unit] = []
	for entity in get_entities_at(x, y):
		if entity is Unit:
			units.append(entity)
	return units

func find_enemy_near_sub_pos(sub_x: int, sub_y: int, team: String, range_in_sub_cells: int) -> Unit:
	for dx in range(-range_in_sub_cells, range_in_sub_cells + 1):
		for dy in range(-range_in_sub_cells, range_in_sub_cells + 1):
			if dx == 0 and dy == 0:
				continue
			
			var check_x = sub_x + dx
			var check_y = sub_y + dy
			
			if is_sub_valid(check_x, check_y):
				var entity = sub_grid_occupied[check_x][check_y]
				if entity and entity is Unit and entity.team != team:
					return entity
	
	return null

func can_fit_unit(x: int, y: int) -> bool:
	if not is_valid(x, y):
		return false
	return get_units_at(x, y).size() < GameConfig.MAX_UNITS_PER_CELL

func is_sub_cell_free(sub_x: int, sub_y: int) -> bool:
	if not is_sub_valid(sub_x, sub_y):
		return false
	return sub_grid_occupied[sub_x][sub_y] == null
