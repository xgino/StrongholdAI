extends Entity
class_name Unit

# Type and stats
var unit_type: GameConfig.UnitType
var level: int = 1
var max_hp: float
var current_hp: float
var attack: float
var defense: float
var speed: float
var spin_speed: float
var unit_size: int

# XP
var xp: int = 0
var xp_to_next_level: int = GameConfig.BASE_XP_REQUIREMENT

# Movement
var sub_grid_x: int = 0
var sub_grid_y: int = 0
var target_sub_pos: Vector2i = Vector2i(-1, -1)
var target_enemy: Unit = null  # NEW - Track enemy to chase
var move_cooldown: float = 0.0

# Combat
var enemies_in_combat: Array[Unit] = []
var in_battle: bool = false

# Animation
var rotation: float = 0.0
var is_spinning: bool = false

signal leveled_up(new_level)
signal died()

func _init(x: int, y: int, t: String, type: GameConfig.UnitType = GameConfig.UnitType.ATTACKER):
	super(x, y, t)
	unit_type = type
	
	sub_grid_x = x * GameConfig.SUB_CELLS_PER_BIG_CELL + 2
	sub_grid_y = y * GameConfig.SUB_CELLS_PER_BIG_CELL + 2
	
	apply_unit_config()

func apply_unit_config():
	var config = GameConfig.UNIT_CONFIGS[unit_type]
	max_hp = config.max_hp
	attack = config.attack
	defense = config.defense
	speed = config.speed
	spin_speed = config.spin_speed
	unit_size = config.size
	current_hp = max_hp

func get_world_position() -> Vector2:
	return Vector2(
		sub_grid_x * GameConfig.SUB_CELL_SIZE + GameConfig.SUB_CELL_SIZE / 2.0,
		sub_grid_y * GameConfig.SUB_CELL_SIZE + GameConfig.SUB_CELL_SIZE / 2.0
	)

func update_big_cell_position():
	grid_x = int(sub_grid_x / GameConfig.SUB_CELLS_PER_BIG_CELL)
	grid_y = int(sub_grid_y / GameConfig.SUB_CELLS_PER_BIG_CELL)

func move_to_sub_cell(new_sub_x: int, new_sub_y: int):
	sub_grid_x = new_sub_x
	sub_grid_y = new_sub_y
	update_big_cell_position()

func can_fight_more_enemies() -> bool:
	return enemies_in_combat.size() < GameConfig.MAX_SIMULTANEOUS_FIGHTS

func add_enemy_to_combat(enemy: Unit):
	if enemy not in enemies_in_combat and can_fight_more_enemies():
		enemies_in_combat.append(enemy)
		in_battle = true

func remove_enemy_from_combat(enemy: Unit):
	enemies_in_combat.erase(enemy)
	if enemies_in_combat.size() == 0:
		in_battle = false

func gain_xp(amount: int):
	xp += amount
	while xp >= xp_to_next_level:
		level_up()

func level_up():
	xp -= xp_to_next_level
	level += 1
	xp_to_next_level = int(GameConfig.BASE_XP_REQUIREMENT * pow(GameConfig.XP_MULTIPLIER, level - 1))
	
	# Calculate stat increases
	var increase = randf_range(GameConfig.STAT_INCREASE_MIN, GameConfig.STAT_INCREASE_MAX)
	
	# Store old max HP to calculate proportional current HP increase
	var old_max_hp = max_hp
	var hp_percent_before = current_hp / old_max_hp
	
	# Increase stats
	max_hp += max_hp * increase
	attack += attack * increase
	defense += defense * increase
	speed += speed * increase * 0.5
	
	# Increase current HP proportionally (NOT full heal!)
	current_hp = max_hp * hp_percent_before + (max_hp - old_max_hp) * increase
	current_hp = min(current_hp, max_hp)
	
	leveled_up.emit(level)
	print(team, " ", get_unit_type_name(), " → Lv", level, " (+", int(increase * 100), "% stats, HP: ", int(current_hp), "/", int(max_hp), ")")

func take_damage(damage: float) -> bool:
	var actual_damage = max(1.0, damage - defense)
	current_hp -= actual_damage
	
	if current_hp <= 0:
		died.emit()
		return true
	return false

func heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)

func update_battle_animation(delta: float):
	if in_battle:
		is_spinning = true
		rotation += spin_speed * delta
	else:
		is_spinning = false
		rotation = lerp(rotation, 0.0, delta * 5.0)

func get_hp_percent() -> float:
	return current_hp / max_hp

func is_alive() -> bool:
	return current_hp > 0

func reset_target():
	target_sub_pos = Vector2i(-1, -1)
	target_enemy = null

func set_target_enemy(enemy: Unit):
	target_enemy = enemy
	target_sub_pos = Vector2i(enemy.sub_grid_x, enemy.sub_grid_y)

func update_enemy_target():
	# If chasing an enemy, update target position
	if target_enemy and target_enemy.is_alive():
		target_sub_pos = Vector2i(target_enemy.sub_grid_x, target_enemy.sub_grid_y)
	elif target_enemy:
		# Enemy died, stop chasing
		target_enemy = null
		target_sub_pos = Vector2i(-1, -1)

func get_unit_type_name() -> String:
	return GameConfig.UNIT_CONFIGS[unit_type].name

func get_corners() -> int:
	return GameConfig.UNIT_CONFIGS[unit_type].corners
