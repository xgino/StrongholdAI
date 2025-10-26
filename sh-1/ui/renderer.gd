extends RefCounted
class_name GameRenderer

var canvas: CanvasItem
var camera: CameraController

func _init(canvas_item: CanvasItem, cam: CameraController):
	canvas = canvas_item
	camera = cam

func draw_grid():
	# Only draw visible portion of grid
	var cam_rect = Rect2(camera.camera_position, Vector2(GameConfig.GAME_VIEWPORT_WIDTH, GameConfig.GAME_VIEWPORT_HEIGHT))
	
	var start_x = max(0, int(cam_rect.position.x / GameConfig.BIG_CELL_SIZE))
	var end_x = min(GameConfig.GRID_WIDTH, int((cam_rect.position.x + cam_rect.size.x) / GameConfig.BIG_CELL_SIZE) + 1)
	var start_y = max(0, int(cam_rect.position.y / GameConfig.BIG_CELL_SIZE))
	var end_y = min(GameConfig.GRID_HEIGHT, int((cam_rect.position.y + cam_rect.size.y) / GameConfig.BIG_CELL_SIZE) + 1)
	
	for x in range(start_x, end_x + 1):
		var world_x = x * GameConfig.BIG_CELL_SIZE
		var screen_x = camera.world_to_screen(Vector2(world_x, 0)).x
		var thickness = 4.0 if x % 8 == 0 else 2.0
		var color = Color(0.4, 0.4, 0.4) if x % 8 == 0 else Color(0.3, 0.3, 0.3)
		
		canvas.draw_line(
			Vector2(screen_x, 0),
			Vector2(screen_x, GameConfig.GAME_VIEWPORT_HEIGHT),
			color, thickness
		)
	
	for y in range(start_y, end_y + 1):
		var world_y = y * GameConfig.BIG_CELL_SIZE
		var screen_y = camera.world_to_screen(Vector2(0, world_y)).y
		var thickness = 4.0 if y % 8 == 0 else 2.0
		var color = Color(0.4, 0.4, 0.4) if y % 8 == 0 else Color(0.3, 0.3, 0.3)
		
		canvas.draw_line(
			Vector2(0, screen_y),
			Vector2(GameConfig.GAME_VIEWPORT_WIDTH, screen_y),
			color, thickness
		)

func draw_side_panel():
	var panel_rect = Rect2(
		Vector2(GameConfig.GAME_VIEWPORT_WIDTH, 0),
		Vector2(GameConfig.SIDE_PANEL_WIDTH, GameConfig.TOTAL_WINDOW_HEIGHT)
	)
	canvas.draw_rect(panel_rect, Color(0.08, 0.08, 0.08))
	canvas.draw_line(
		Vector2(GameConfig.GAME_VIEWPORT_WIDTH, 0),
		Vector2(GameConfig.GAME_VIEWPORT_WIDTH, GameConfig.TOTAL_WINDOW_HEIGHT),
		Color(0.5, 0.5, 0.5), 3.0
	)

func draw_checkpoints(checkpoints: Array):
	for cp in checkpoints:
		var world_pos = Vector2(cp.grid_x * GameConfig.BIG_CELL_SIZE, cp.grid_y * GameConfig.BIG_CELL_SIZE)
		
		if not camera.is_visible(world_pos):
			continue
		
		var screen_pos = camera.world_to_screen(world_pos)
		var size = GameConfig.BIG_CELL_SIZE - 12
		var rect = Rect2(screen_pos + Vector2(6, 6), Vector2(size, size))
		
		var bg_color = GameConfig.TEAM_COLORS[cp.controlled_by].darkened(0.5)
		canvas.draw_rect(rect, bg_color)
		
		if cp.is_healing_checkpoint():
			var cross_size = size * 0.5
			var center = screen_pos + Vector2(GameConfig.BIG_CELL_SIZE / 2.0, GameConfig.BIG_CELL_SIZE / 2.0)
			canvas.draw_rect(Rect2(center - Vector2(cross_size/2, 5), Vector2(cross_size, 10)), Color.GREEN)
			canvas.draw_rect(Rect2(center - Vector2(5, cross_size/2), Vector2(10, cross_size)), Color.GREEN)
		
		if cp.claiming_team != cp.controlled_by:
			var progress = cp.get_claim_progress()
			var progress_height = size * progress
			var progress_rect = Rect2(
				screen_pos + Vector2(6, 6 + size - progress_height),
				Vector2(size, progress_height)
			)
			canvas.draw_rect(progress_rect, GameConfig.TEAM_COLORS[cp.claiming_team].lightened(0.4))
		
		canvas.draw_rect(rect, Color.WHITE, false, 3.0)

func draw_bases(bases: Array):
	for base in bases:
		var world_pos = Vector2(base.grid_x * GameConfig.BIG_CELL_SIZE, base.grid_y * GameConfig.BIG_CELL_SIZE)
		
		if not camera.is_visible(world_pos):
			continue
		
		var screen_pos = camera.world_to_screen(world_pos)
		var size = GameConfig.BIG_CELL_SIZE
		var rect = Rect2(screen_pos, Vector2(size, size))
		
		var color = GameConfig.TEAM_COLORS[base.team]
		canvas.draw_rect(rect, color.darkened(0.15))
		canvas.draw_rect(rect, Color.GREEN.lightened(0.6), false, 4.0)
		canvas.draw_rect(rect, Color.WHITE, false, 5.0)
		
		var font = ThemeDB.fallback_font
		var center = screen_pos + Vector2(size / 2.0, size / 2.0)
		var letter = base.team.substr(0, 1).to_upper()
		canvas.draw_string(font, center - Vector2(22, -25), letter, 
			HORIZONTAL_ALIGNMENT_CENTER, -1, 64, Color.WHITE)

func draw_units(units: Array, selected_units: Array):
	for unit in units:
		var world_pos = unit.get_world_position()
		
		if not camera.is_visible(world_pos):
			continue
		
		var screen_pos = camera.world_to_screen(world_pos)
		draw_unit_shape(unit, screen_pos, selected_units)

func draw_unit_shape(unit: Unit, center: Vector2, selected_units: Array):
	var config = GameConfig.UNIT_CONFIGS[unit.unit_type]
	var size = config.size
	var corners = config.corners
	var color = GameConfig.TEAM_COLORS[unit.team]
	
	# Selection - GREEN DOT above head
	if unit in selected_units:
		canvas.draw_circle(center - Vector2(0, size + 10), 5, Color.GREEN)
		canvas.draw_circle(center, size + 6, Color(1, 1, 1, 0.6))
	
	# Combat glow
	if unit.in_battle:
		canvas.draw_circle(center, size + 4, Color(1, 0.2, 0.2, 0.4))
	
	# Polygon
	var points = generate_polygon_points(center, size, corners, unit.rotation)
	var colors = PackedColorArray()
	for i in range(corners):
		colors.append(color)
	
	canvas.draw_polygon(points, colors)
	
	var outline = points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, Color.WHITE, 2.5)
	
	# HP bar
	draw_hp_bar(center, size, unit.get_hp_percent())
	
	# Level
	var font = ThemeDB.fallback_font
	canvas.draw_string(font, center - Vector2(6, -5), str(unit.level), 
		HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
	
	# Combat count
	if unit.enemies_in_combat.size() > 1:
		canvas.draw_string(font, center + Vector2(size, -size - 5), 
			"×" + str(unit.enemies_in_combat.size()),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

func generate_polygon_points(center: Vector2, radius: float, corners: int, rotation: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_step = TAU / corners
	
	for i in range(corners):
		var angle = (i * angle_step) + rotation - (PI / 2)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	return points

func draw_hp_bar(center: Vector2, unit_size: float, hp_percent: float):
	var bar_width = unit_size * 2.8
	var bar_height = 5.0
	var bar_pos = center - Vector2(bar_width/2.0, unit_size + 14)
	
	canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.0, 0.0))
	
	var hp_color = Color.GREEN if hp_percent > 0.5 else (Color.YELLOW if hp_percent > 0.25 else Color.RED)
	canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_percent, bar_height)), hp_color)
	canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.WHITE, false, 1.5)

func draw_minimap(units: Array, bases: Array, checkpoints: Array):
	var minimap_pos = GameConfig.MINIMAP_POSITION
	var minimap_size = GameConfig.MINIMAP_SIZE
	
	var font = ThemeDB.fallback_font
	canvas.draw_string(font, minimap_pos - Vector2(0, 12), 
		"═══ BATTLEFIELD (64×64) ═══", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# Background
	canvas.draw_rect(Rect2(minimap_pos, Vector2(minimap_size, minimap_size)), Color(0.02, 0.02, 0.02))
	
	# Checkpoints
	for cp in checkpoints:
		var mini_pos = minimap_pos + Vector2(
			cp.grid_x * GameConfig.MINIMAP_CELL_SIZE,
			cp.grid_y * GameConfig.MINIMAP_CELL_SIZE
		)
		canvas.draw_rect(
			Rect2(mini_pos, Vector2(GameConfig.MINIMAP_CELL_SIZE, GameConfig.MINIMAP_CELL_SIZE)),
			GameConfig.TEAM_COLORS[cp.controlled_by].darkened(0.2)
		)
	
	# Bases
	for base in bases:
		var mini_pos = minimap_pos + Vector2(
			base.grid_x * GameConfig.MINIMAP_CELL_SIZE,
			base.grid_y * GameConfig.MINIMAP_CELL_SIZE
		)
		canvas.draw_rect(
			Rect2(mini_pos, Vector2(GameConfig.MINIMAP_CELL_SIZE * 2, GameConfig.MINIMAP_CELL_SIZE * 2)),
			GameConfig.TEAM_COLORS[base.team]
		)
	
	# Units
	for unit in units:
		var mini_pos = minimap_pos + Vector2(
			(unit.grid_x + 0.5) * GameConfig.MINIMAP_CELL_SIZE,
			(unit.grid_y + 0.5) * GameConfig.MINIMAP_CELL_SIZE
		)
		canvas.draw_circle(mini_pos, 1.5, GameConfig.TEAM_COLORS[unit.team])
	
	# CAMERA VIEWPORT RECTANGLE - Semi-transparent white box
	var camera_rect = camera.get_minimap_camera_rect()
	canvas.draw_rect(camera_rect, Color(1, 1, 1, 0.25))
	canvas.draw_rect(camera_rect, Color.WHITE, false, 2.5)
	
	# Border
	canvas.draw_rect(Rect2(minimap_pos, Vector2(minimap_size, minimap_size)), Color.WHITE, false, 3.0)
	
	# Hint
	canvas.draw_string(font, minimap_pos + Vector2(0, minimap_size + 18),
		"Click/drag to move camera",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))

func draw_selection_box(input_handler: InputHandler):
	if input_handler.is_selecting():
		var rect = input_handler.get_selection_rect()
		if rect.size.length() > 15:
			canvas.draw_rect(rect, Color(0.5, 0.8, 1.0, 0.3))
			canvas.draw_rect(rect, Color(0.5, 0.8, 1.0), false, 3.0)

func draw_team_stats(team_stats: Dictionary, selected_units: Array):
	var font = ThemeDB.fallback_font
	var x_base = GameConfig.GAME_VIEWPORT_WIDTH + 25
	var y_pos = GameConfig.MINIMAP_POSITION.y + GameConfig.MINIMAP_SIZE + 55
	
	canvas.draw_string(font, Vector2(x_base, y_pos), 
		"═══ TEAM STATS ═══", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	
	y_pos += 35
	
	for team in GameConfig.TEAMS:
		var stats = team_stats[team]
		var color = GameConfig.TEAM_COLORS[team]
		
		if team == GameConfig.PLAYER_TEAM:
			canvas.draw_string(font, Vector2(x_base, y_pos),
				"★ " + team.to_upper() + " (YOU) ★",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color.lightened(0.5))
		else:
			canvas.draw_string(font, Vector2(x_base, y_pos),
				team.to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
		
		y_pos += 25
		
		var lines = [
			"  Units: %d/%d" % [stats.units, GameConfig.MAX_UNITS_PER_TEAM],
			"  Checkpoints: %d" % stats.checkpoints,
			"  Avg Level: %.1f" % stats.avg_level,
			"  In Combat: %d" % stats.in_combat
		]
		
		for line in lines:
			canvas.draw_string(font, Vector2(x_base, y_pos),
				line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.9, 0.9))
			y_pos += 18
		
		y_pos += 15
	
	# Selected
	if selected_units.size() > 0:
		y_pos += 10
		canvas.draw_string(font, Vector2(x_base, y_pos),
			"═ SELECTED ═", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.CYAN)
		y_pos += 28
		
		canvas.draw_string(font, Vector2(x_base, y_pos),
			str(selected_units.size()) + " units",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
		y_pos += 22
		
		if selected_units.size() == 1:
			var u = selected_units[0]
			var info = [
				u.get_unit_type_name() + " (Lv" + str(u.level) + ")",
				"XP: %d/%d" % [u.xp, u.xp_to_next_level],
				"HP: %d/%d" % [int(u.current_hp), int(u.max_hp)],
				"Fighting: %d" % u.enemies_in_combat.size()
			]
			
			for line in info:
				canvas.draw_string(font, Vector2(x_base, y_pos),
					line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
				y_pos += 16
		
		y_pos += 15
		canvas.draw_string(font, Vector2(x_base, y_pos),
			"Right-click to cancel",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))

func draw_game_over(winner: String):
	canvas.draw_rect(
		Rect2(Vector2.ZERO, Vector2(GameConfig.GAME_VIEWPORT_WIDTH, GameConfig.GAME_VIEWPORT_HEIGHT)),
		Color(0, 0, 0, 0.85)
	)
	
	var center = Vector2(GameConfig.GAME_VIEWPORT_WIDTH / 2.0, GameConfig.GAME_VIEWPORT_HEIGHT / 2.0)
	canvas.draw_rect(Rect2(center - Vector2(350, 140), Vector2(700, 280)), Color(0.05, 0.05, 0.05, 0.98))
	canvas.draw_rect(Rect2(center - Vector2(350, 140), Vector2(700, 280)), Color.WHITE, false, 5.0)
	
	var win_color = GameConfig.TEAM_COLORS[winner]
	var win_text = "★ VICTORY! ★" if winner == GameConfig.PLAYER_TEAM else winner.to_upper() + " WINS!"
	
	var font = ThemeDB.fallback_font
	canvas.draw_string(font, center - Vector2(220, -30), 
		win_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, win_color)
