extends RefCounted
class_name BattleSystem

class Battle:
	var unit1: Unit
	var unit2: Unit
	var active: bool = true
	
	func _init(u1: Unit, u2: Unit):
		unit1 = u1
		unit2 = u2
		unit1.in_battle = true
		unit2.in_battle = true
		unit1.battle_target = unit2
		unit2.battle_target = unit1
	
	func update(delta: float) -> bool:
		if not active or unit1 == null or unit2 == null:
			return true
		
		if not unit1.is_alive() or not unit2.is_alive():
			return true
		
		# SLOWER DAMAGE - reduced multiplier
		var damage1 = unit1.attack * unit1.speed * delta * 0.5  # 50% damage rate
		var damage2 = unit2.attack * unit2.speed * delta * 0.5
		
		var u1_dead = unit1.take_damage(damage2)
		var u2_dead = unit2.take_damage(damage1)
		
		return u1_dead or u2_dead

var active_battles: Array[Battle] = []

signal battle_started(unit1, unit2)
signal battle_ended(winner, loser)

func start_battle(unit1: Unit, unit2: Unit):
	# Check if already fighting
	for battle in active_battles:
		if (battle.unit1 == unit1 and battle.unit2 == unit2) or \
		   (battle.unit1 == unit2 and battle.unit2 == unit1):
			return
	
	var battle = Battle.new(unit1, unit2)
	active_battles.append(battle)
	battle_started.emit(unit1, unit2)
	print("BATTLE: ", unit1.team, " Lv", unit1.level, " (", int(unit1.current_hp), " HP) vs ", 
		  unit2.team, " Lv", unit2.level, " (", int(unit2.current_hp), " HP)")

func update_battles(delta: float):
	var finished = []
	
	for battle in active_battles:
		if not battle.active:
			finished.append(battle)
			continue
		
		var is_over = battle.update(delta)
		
		if is_over:
			handle_battle_end(battle)
			finished.append(battle)
	
	for battle in finished:
		active_battles.erase(battle)

func handle_battle_end(battle: Battle):
	var winner: Unit = null
	var loser: Unit = null
	
	if battle.unit1 != null and battle.unit1.is_alive():
		winner = battle.unit1
		loser = battle.unit2
	elif battle.unit2 != null and battle.unit2.is_alive():
		winner = battle.unit2
		loser = battle.unit1
	
	if winner != null and loser != null:
		var xp_gain = 50 + (loser.level * 20)
		winner.gain_xp(xp_gain)
		winner.reset_target()
		print("  → ", winner.team, " Lv", winner.level, " WON! (", int(winner.current_hp), "/", int(winner.max_hp), " HP, +", xp_gain, " XP)")
		
		battle_ended.emit(winner, loser)

func get_battle_count() -> int:
	return active_battles.size()

func clear_battles_with_unit(unit: Unit):
	for battle in active_battles:
		if battle.unit1 == unit or battle.unit2 == unit:
			battle.active = false
