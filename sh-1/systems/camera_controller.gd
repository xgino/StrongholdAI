extends RefCounted
class_name CameraController

var camera_position: Vector2 = Vector2.ZERO  # Top-left of viewport in world coords
var is_dragging_minimap: bool = false

signal camera_moved(new_position)

func _init():
	# Start camera centered on player base (blue - bottom-left)
	var player_base_world = Vector2(
		GameConfig.HOME_BASE_POSITIONS[GameConfig.PLAYER_TEAM].x * GameConfig.BIG_CELL_SIZE,
		GameConfig.HOME_BASE_POSITIONS[GameConfig.PLAYER_TEAM].y * GameConfig.BIG_CELL_SIZE
	)
	center_camera_on(player_base_world)

func center_camera_on(world_pos: Vector2):
	camera_position = world_pos - Vector2(
		GameConfig.GAME_VIEWPORT_WIDTH / 2.0,
		GameConfig.GAME_VIEWPORT_HEIGHT / 2.0
	)
	clamp_camera()
	camera_moved.emit(camera_position)

func clamp_camera():
	camera_position.x = clamp(camera_position.x, 0, GameConfig.WORLD_WIDTH - GameConfig.GAME_VIEWPORT_WIDTH)
	camera_position.y = clamp(camera_position.y, 0, GameConfig.WORLD_HEIGHT - GameConfig.GAME_VIEWPORT_HEIGHT)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos + camera_position

func world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos - camera_position

func is_visible(world_pos: Vector2) -> bool:
	var screen_pos = world_to_screen(world_pos)
	return screen_pos.x >= -100 and screen_pos.x < GameConfig.GAME_VIEWPORT_WIDTH + 100 and \
		   screen_pos.y >= -100 and screen_pos.y < GameConfig.GAME_VIEWPORT_HEIGHT + 100

func handle_minimap_click(click_pos: Vector2) -> bool:
	var minimap_rect = Rect2(
		GameConfig.MINIMAP_POSITION,
		Vector2(GameConfig.MINIMAP_SIZE, GameConfig.MINIMAP_SIZE)
	)
	
	if minimap_rect.has_point(click_pos):
		var relative_pos = click_pos - GameConfig.MINIMAP_POSITION
		var world_pos = Vector2(
			(relative_pos.x / GameConfig.MINIMAP_SIZE) * GameConfig.WORLD_WIDTH,
			(relative_pos.y / GameConfig.MINIMAP_SIZE) * GameConfig.WORLD_HEIGHT
		)
		center_camera_on(world_pos)
		return true
	
	return false

func handle_minimap_drag(click_pos: Vector2):
	var minimap_rect = Rect2(
		GameConfig.MINIMAP_POSITION,
		Vector2(GameConfig.MINIMAP_SIZE, GameConfig.MINIMAP_SIZE)
	)
	
	if minimap_rect.has_point(click_pos):
		is_dragging_minimap = true
		handle_minimap_click(click_pos)

func get_minimap_camera_rect() -> Rect2:
	# Calculate where the camera viewport is on the minimap
	var minimap_x = (camera_position.x / GameConfig.WORLD_WIDTH) * GameConfig.MINIMAP_SIZE
	var minimap_y = (camera_position.y / GameConfig.WORLD_HEIGHT) * GameConfig.MINIMAP_SIZE
	var minimap_w = (float(GameConfig.GAME_VIEWPORT_WIDTH) / GameConfig.WORLD_WIDTH) * GameConfig.MINIMAP_SIZE
	var minimap_h = (float(GameConfig.GAME_VIEWPORT_HEIGHT) / GameConfig.WORLD_HEIGHT) * GameConfig.MINIMAP_SIZE
	
	return Rect2(
		GameConfig.MINIMAP_POSITION + Vector2(minimap_x, minimap_y),
		Vector2(minimap_w, minimap_h)
	)
