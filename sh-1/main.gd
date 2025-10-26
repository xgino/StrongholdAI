extends Node2D

var grid_manager: GridManager
var combat_manager: CombatManager
var camera: CameraController
var input_handler: InputHandler
var renderer: GameRenderer

var units: Array[Unit] = []
var bases: Array[HomeBase] = []
var checkpoints: Array[Checkpoint] = []
var game_over: bool = false
var winner: String = ""

func _ready():
	get_window().size = Vector2i(GameConfig.TOTAL_WINDOW_WIDTH, GameConfig.TOTAL_WINDOW_HEIGHT)
	
	print("=== SCHOOL WARS ===")
	print("Window: ", GameConfig.TOTAL_WINDOW_WIDTH, "x", GameConfig.TOTAL_WINDOW_HEIGHT)
	print("Game: ", GameConfig.GAME_VIEWPORT_WIDTH, "x", GameConfig.GAME_VIEWPORT_HEIGHT)
	print("Sub-grid: 64x64 (units move on sub-cells)")
	
	initialize_systems()
	setup_game()

func initialize_systems():
	grid_manager = GridManager.new(GameConfig.GRID_WIDTH, GameConfig.GRID_HEIGHT)
	combat_manager = CombatManager.new()
	camera = CameraController.new()  # ADD THIS LINE
	input_handler = InputHandler.new(grid_manager, camera)  # Pass camera
	renderer = GameRenderer.new(self, camera)  # Pass camera
	
	input_handler.move_command.connect(_on_move_command)
	input_handler.attack_command.connect(_on_attack_command)
	combat_manager.combat_ended.connect(_on_combat_ended)

func setup_game():
	for team in GameConfig.TEAMS:
		var pos = GameConfig.HOME_BASE_POSITIONS[team]
		create_home_base(pos.x, pos.y, team)
	
	for base in bases:
		for i in range(GameConfig.STARTING_UNITS):
			var random_type = randi() % GameConfig.UnitType.size()
			create_unit(base.grid_x, base.grid_y, base.team, random_type)
	
	create_strategic_checkpoints()
	print("Ready! You control BLUE (bottom-left)")

func create_strategic_checkpoints():
	var created_normal = 0
	var created_healing = 0
	var checkpoint_groups = []
	
	while created_normal < GameConfig.MAX_NORMAL_CHECKPOINTS or created_healing < GameConfig.MAX_HEALING_CHECKPOINTS:
		var group_center = find_checkpoint_location(checkpoint_groups)
		if group_center == Vector2i(-1, -1):
			break
		
		checkpoint_groups.append(group_center)
		var group_size = randi() % GameConfig.MAX_CHECKPOINTS_CLOSE_TOGETHER + 1
		
		for i in range(group_size):
			var offset = Vector2i(randi() % 3 - 1, randi() % 3 - 1)
			var pos = group_center + offset
			
			if not is_valid_checkpoint_pos(pos):
				continue
			
			var is_healing = randf() < 0.33
			
			if is_healing and created_healing < GameConfig.MAX_HEALING_CHECKPOINTS:
				create_checkpoint(pos.x, pos.y, Checkpoint.Type.HEALING)
				created_healing += 1
			elif not is_healing and created_normal < GameConfig.MAX_NORMAL_CHECKPOINTS:
				create_checkpoint(pos.x, pos.y, Checkpoint.Type.NORMAL)
				created_normal += 1
	
	print("Checkpoints: ", created_normal, " normal, ", created_healing, " healing")

func find_checkpoint_location(existing: Array) -> Vector2i:
	for attempt in range(50):
		var x = randi() % (GameConfig.GRID_WIDTH - 4) + 2
		var y = randi() % (GameConfig.GRID_HEIGHT - 4) + 2
		var pos = Vector2i(x, y)
		
		var valid = true
		for group in existing:
			if abs(pos.x - group.x) + abs(pos.y - group.y) < GameConfig.MIN_CHECKPOINT_DISTANCE:
				valid = false
				break
		
		for base in bases:
			if abs(pos.x - base.grid_x) + abs(pos.y - base.grid_y) < 4:
				valid = false
				break
		
		if valid:
			return pos
	
	return Vector2i(-1, -1)

func is_valid_checkpoint_pos(pos: Vector2i) -> bool:
	if not grid_manager.is_valid(pos.x, pos.y):
		return false
	
	var entities = grid_manager.get_entities_at(pos.x, pos.y)
	for entity in entities:
		if entity is Checkpoint or entity is HomeBase:
			return false
	
	return true

func create_unit(x: int, y: int, team: String, type: int = -1) -> Unit:
	if count_team_units(team) >= GameConfig.MAX_UNITS_PER_TEAM:
		return null
	
	if type < 0:
		type = randi() % GameConfig.UnitType.size()
	
	var unit = Unit.new(x, y, team, type)
	if grid_manager.add_entity(unit):
		units.append(unit)
		return unit
	return null

func create_home_base(x: int, y: int, team: String) -> HomeBase:
	var base = HomeBase.new(x, y, team)
	bases.append(base)
	base.unit_spawned.connect(_on_base_spawn_unit)
	return base

func create_checkpoint(x: int, y: int, type: Checkpoint.Type) -> Checkpoint:
	var cp = Checkpoint.new(x, y, type)
	grid_manager.add_entity(cp)
	checkpoints.append(cp)
	cp.claimed.connect(_on_checkpoint_claimed)
	return cp

func _input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton:
		input_handler.handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		input_handler.handle_mouse_motion(event)

func _process(delta):
	if game_over:
		return
	
	update_units(delta)
	combat_manager.update_combat_proximity(units, delta)
	combat_manager.process_combat(units, delta)
	update_checkpoints(delta)
	update_bases(delta)
	check_win_condition()
	queue_redraw()

func update_units(delta: float):
	for unit in units:
		unit.update_battle_animation(delta)
		
		# Update enemy target position if chasing
		if unit.target_enemy:
			unit.update_enemy_target()
		
		# Can't move while in combat
		if unit.in_battle:
			continue
		
		# AI for non-player units
		if unit.team != GameConfig.PLAYER_TEAM and unit.target_sub_pos.x < 0:
			set_ai_target(unit)
		
		# Movement
		if unit.target_sub_pos.x >= 0:
			unit.move_cooldown -= delta
			if unit.move_cooldown <= 0:
				unit.move_cooldown = 0.5 / unit.speed
				move_unit_toward_target(unit)

func move_unit_toward_target(unit: Unit):
	var current = Vector2i(unit.sub_grid_x, unit.sub_grid_y)
	var target = unit.target_sub_pos
	
	var dx = sign(target.x - current.x)
	var dy = sign(target.y - current.y)
	
	var next_sub_x = current.x
	var next_sub_y = current.y
	
	# Move on sub-grid
	if abs(target.x - current.x) > abs(target.y - current.y):
		next_sub_x += dx
	else:
		next_sub_y += dy
	
	# Try to move
	if grid_manager.is_sub_cell_free(next_sub_x, next_sub_y):
		grid_manager.move_unit_sub_grid(unit, next_sub_x, next_sub_y)
	
	# Reached target
	if unit.sub_grid_x == target.x and unit.sub_grid_y == target.y:
		unit.target_sub_pos = Vector2i(-1, -1)

func set_ai_target(unit: Unit):
	var unit_pos = unit.get_world_position()
	
	# AGGRESSIVE AI - Look for enemies in wider range
	var nearest_enemy: Unit = null
	var min_dist = GameConfig.AGGRO_RANGE * 1.5
	
	for other in units:
		if other.team != unit.team and other.is_alive():
			var other_pos = other.get_world_position()
			var dist = unit_pos.distance_to(other_pos)
			
			if other.in_battle and dist < min_dist * 1.5:
				nearest_enemy = other
				min_dist = dist
				break
			elif dist < min_dist:
				min_dist = dist
				nearest_enemy = other
	
	if nearest_enemy:
		unit.set_target_enemy(nearest_enemy)
		return
	
	# No enemies, claim checkpoints
	var nearest_cp = find_nearest_unclaimed_checkpoint(unit)
	if nearest_cp:
		var cp_center_sub = Vector2i(
			nearest_cp.grid_x * GameConfig.SUB_CELLS_PER_BIG_CELL + 2,  # FIXED: cp → nearest_cp
			nearest_cp.grid_y * GameConfig.SUB_CELLS_PER_BIG_CELL + 2   # FIXED: cp → nearest_cp
		)
		unit.target_sub_pos = cp_center_sub
		return
	
	# Default: center
	unit.target_sub_pos = Vector2i(GameConfig.TOTAL_SUB_WIDTH / 2, GameConfig.TOTAL_SUB_HEIGHT / 2)
	
func find_nearest_unclaimed_checkpoint(unit: Unit) -> Checkpoint:
	var nearest: Checkpoint = null
	var min_dist = 999999
	for cp in checkpoints:
		if cp.controlled_by != unit.team:
			var dist = abs(cp.grid_x - unit.grid_x) + abs(cp.grid_y - unit.grid_y)
			if dist < min_dist:
				min_dist = dist
				nearest = cp
	return nearest

func update_checkpoints(delta: float):
	for cp in checkpoints:
		var units_here = grid_manager.get_units_at(cp.grid_x, cp.grid_y)
		var unit_on_cp = units_here.size() > 0
		var dominant_team = "neutral"
		
		if unit_on_cp:
			var team_counts = {}
			for u in units_here:
				team_counts[u.team] = team_counts.get(u.team, 0) + 1
			
			var max_count = 0
			for team in team_counts:
				if team_counts[team] > max_count:
					max_count = team_counts[team]
					dominant_team = team
		
		cp.update(delta, unit_on_cp, dominant_team)
		
		if cp.is_healing_checkpoint() and cp.controlled_by != "neutral":
			for u in units_here:
				if u.team == cp.controlled_by:
					u.heal(GameConfig.HEAL_PER_SECOND * delta)

func update_bases(delta: float):
	for base in bases:
		var units_here = grid_manager.get_units_at(base.grid_x, base.grid_y)
		for u in units_here:
			if u.team == base.team:
				u.heal(GameConfig.HEAL_PER_SECOND * delta)
		
		var cp_count = count_team_checkpoints(base.team)
		base.update(delta, cp_count)

func count_team_units(team: String) -> int:
	var count = 0
	for unit in units:
		if unit.team == team:
			count += 1
	return count

func count_team_checkpoints(team: String) -> int:
	var count = 0
	for cp in checkpoints:
		if cp.controlled_by == team:
			count += 1
	return count

func count_units_in_combat(team: String) -> int:
	var count = 0
	for unit in units:
		if unit.team == team and unit.in_battle:
			count += 1
	return count

func get_team_stats(team: String) -> Dictionary:
	var team_units = []
	var total_hp = 0
	var total_level = 0
	
	for unit in units:
		if unit.team == team:
			team_units.append(unit)
			total_hp += int(unit.current_hp)
			total_level += unit.level
	
	var count = max(1, team_units.size())
	
	return {
		"units": team_units.size(),
		"checkpoints": count_team_checkpoints(team),
		"avg_level": float(total_level) / count,
		"total_hp": total_hp,
		"in_combat": count_units_in_combat(team)
	}

func check_win_condition():
	var teams_alive = []
	for team in GameConfig.TEAMS:
		if count_team_units(team) > 0:
			teams_alive.append(team)
	
	if teams_alive.size() == 1:
		end_game(teams_alive[0])

func end_game(winning_team: String):
	game_over = true
	winner = winning_team
	print("\n=== ", winning_team.to_upper(), " WINS! ===")

func _draw():
	renderer.draw_side_panel()
	renderer.draw_grid()
	renderer.draw_checkpoints(checkpoints)
	renderer.draw_bases(bases)
	renderer.draw_units(units, input_handler.get_selected_units())
	renderer.draw_selection_box(input_handler)
	renderer.draw_minimap(units, bases, checkpoints)
	
	var team_stats = {}
	for team in GameConfig.TEAMS:
		team_stats[team] = get_team_stats(team)
	
	renderer.draw_team_stats(team_stats, input_handler.get_selected_units())
	
	if game_over:
		renderer.draw_game_over(winner)

func _on_move_command(units_to_move: Array, target_pos: Vector2i):
	# Convert big cell click to sub-grid target (center of clicked cell)
	var target_sub_x = target_pos.x * GameConfig.SUB_CELLS_PER_BIG_CELL + 2
	var target_sub_y = target_pos.y * GameConfig.SUB_CELLS_PER_BIG_CELL + 2
	
	for unit in units_to_move:
		if unit.team == GameConfig.PLAYER_TEAM:
			unit.target_sub_pos = Vector2i(target_sub_x, target_sub_y)

func _on_base_spawn_unit(position: Vector2i):
	for base in bases:
		if base.grid_x == position.x and base.grid_y == position.y:
			var random_type = randi() % GameConfig.UnitType.size()
			
			# Try to spawn ON the base first
			if create_unit(base.grid_x, base.grid_y, base.team, random_type):
				return
			
			# If base cell is full (16 units), try adjacent
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue  # Already tried base itself
					if create_unit(base.grid_x + dx, base.grid_y + dy, base.team, random_type):
						return
			
			print(base.team, " base is FULL! Can't spawn unit")
			return

func _on_combat_ended(winner_unit: Unit, loser: Unit):
	remove_unit(loser)

func _on_checkpoint_claimed(new_team: String):
	print("★ ", new_team.to_upper(), " claimed checkpoint!")

func remove_unit(unit: Unit):
	grid_manager.remove_entity(unit)
	combat_manager.clear_unit_combat(unit)
	units.erase(unit)

func _on_attack_command(units_to_command: Array, target_enemy: Unit):
	# Command all selected units to attack the target enemy
	for unit in units_to_command:
		if unit.team == GameConfig.PLAYER_TEAM:
			unit.set_target_enemy(target_enemy)
	
	print("→ ", units_to_command.size(), " units attacking ", target_enemy.get_unit_type_name())
