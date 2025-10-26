extends RefCounted
class_name InputHandler

var grid_manager: GridManager
var camera: CameraController
var selected_units: Array[Unit] = []

var is_dragging: bool = false
var drag_start_screen: Vector2 = Vector2.ZERO  # Keep in screen coords
var drag_current_screen: Vector2 = Vector2.ZERO

signal units_selected(units)
signal move_command(units, target_pos)
signal attack_command(units, target_enemy)
signal selection_cleared()

func _init(grid: GridManager, cam: CameraController):
	grid_manager = grid
	camera = cam

func handle_mouse_button(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Minimap click
			if camera.handle_minimap_click(event.position):
				camera.is_dragging_minimap = true
				return
			
			# Side panel - ignore
			if event.position.x > GameConfig.GAME_VIEWPORT_WIDTH:
				return
			
			# Start dragging
			is_dragging = true
			drag_start_screen = event.position
			drag_current_screen = event.position
		else:
			camera.is_dragging_minimap = false
			if is_dragging:
				handle_selection_end()
			is_dragging = false
	
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		clear_selection()

func handle_mouse_motion(event: InputEventMouseMotion):
	if camera.is_dragging_minimap:
		camera.handle_minimap_drag(event.position)
		return
	
	if is_dragging:
		drag_current_screen = event.position

func handle_selection_end():
	# Convert screen to world to grid
	var start_world = camera.screen_to_world(drag_start_screen)
	var end_world = camera.screen_to_world(drag_current_screen)
	
	var start_grid = world_to_grid(start_world)
	var end_grid = world_to_grid(end_world)
	
	if start_grid.x < 0 or end_grid.x < 0:
		return
	
	var is_click = drag_start_screen.distance_to(drag_current_screen) < 20
	
	if is_click:
		handle_click(start_grid.x, start_grid.y)
	else:
		handle_drag_selection(start_grid, end_grid)

func handle_click(x: int, y: int):
	var units_here = grid_manager.get_units_at(x, y)
	
	# Check for enemy
	var enemy_unit: Unit = null
	for unit in units_here:
		if unit.team != GameConfig.PLAYER_TEAM:
			enemy_unit = unit
			break
	
	# Attack
	if selected_units.size() > 0 and enemy_unit:
		attack_command.emit(selected_units, enemy_unit)
		return
	
	# Move
	if selected_units.size() > 0:
		move_command.emit(selected_units, Vector2i(x, y))
		return
	
	# Select
	for unit in units_here:
		if unit.team == GameConfig.PLAYER_TEAM:
			selected_units = [unit]
			units_selected.emit(selected_units)
			print("Selected: Lv", unit.level, " ", unit.get_unit_type_name())
			return

func handle_drag_selection(start: Vector2i, end: Vector2i):
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_y = min(start.y, end.y)
	var max_y = max(start.y, end.y)
	
	selected_units.clear()
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if not grid_manager.is_valid(x, y):
				continue
			
			var units_here = grid_manager.get_units_at(x, y)
			for unit in units_here:
				if unit.team == GameConfig.PLAYER_TEAM and unit not in selected_units:
					selected_units.append(unit)
	
	units_selected.emit(selected_units)
	print("Selected ", selected_units.size(), " units")

func clear_selection():
	for unit in selected_units:
		unit.reset_target()
	selected_units.clear()
	selection_cleared.emit()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var x = int(world_pos.x / GameConfig.BIG_CELL_SIZE)
	var y = int(world_pos.y / GameConfig.BIG_CELL_SIZE)
	
	if x >= 0 and x < GameConfig.GRID_WIDTH and y >= 0 and y < GameConfig.GRID_HEIGHT:
		return Vector2i(x, y)
	return Vector2i(-1, -1)

func get_selected_units() -> Array[Unit]:
	return selected_units

func is_selecting() -> bool:
	return is_dragging

func get_selection_rect() -> Rect2:
	# Return in SCREEN coordinates
	return Rect2(drag_start_screen, drag_current_screen - drag_start_screen)
