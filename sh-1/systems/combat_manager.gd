extends RefCounted
class_name CombatManager

signal combat_started(unit, enemy)
signal combat_ended(winner, loser)

func update_combat_proximity(units: Array, _delta: float):
	# More aggressive combat detection - units engage multiple enemies eagerly
	for unit in units:
		if not unit.is_alive():
			continue
		
		var unit_pos = unit.get_world_position()
		var nearby_enemies = []
		
		# Find ALL nearby enemies
		for other in units:
			if other.team == unit.team or not other.is_alive():
				continue
			
			var other_pos = other.get_world_position()
			var distance = unit_pos.distance_to(other_pos)
			
			if distance <= GameConfig.COMBAT_COLLISION_DISTANCE:
				nearby_enemies.append(other)
		
		# Engage up to 4 enemies
		for enemy in nearby_enemies:
			if unit.can_fight_more_enemies() and enemy.can_fight_more_enemies():
				if enemy not in unit.enemies_in_combat:
					start_combat(unit, enemy)
		
		# Remove enemies that are too far
		for enemy in unit.enemies_in_combat.duplicate():
			if enemy not in nearby_enemies:
				end_combat(unit, enemy)

func start_combat(unit1: Unit, unit2: Unit):
	unit1.add_enemy_to_combat(unit2)
	unit2.add_enemy_to_combat(unit1)
	combat_started.emit(unit1, unit2)

func end_combat(unit1: Unit, unit2: Unit):
	unit1.remove_enemy_from_combat(unit2)
	unit2.remove_enemy_from_combat(unit1)

func process_combat(units: Array, delta: float):
	# All units in combat attack simultaneously - ARMY CHAOS!
	for unit in units:
		if not unit.is_alive() or not unit.in_battle:
			continue
		
		# Attack ALL enemies in combat at once
		for enemy in unit.enemies_in_combat.duplicate():
			if not enemy.is_alive():
				unit.remove_enemy_from_combat(enemy)
				continue
			
			# Deal damage - faster for more chaos
			var damage = unit.attack * delta * 0.5  # Increased from 0.3
			var enemy_died = enemy.take_damage(damage)
			
			if enemy_died:
				unit.remove_enemy_from_combat(enemy)
				
				var xp_gain = 40 + (enemy.level * 15)
				unit.gain_xp(xp_gain)
				
				print(unit.team, " ", unit.get_unit_type_name(), " defeated ", enemy.team, " ", enemy.get_unit_type_name(), "!")
				combat_ended.emit(unit, enemy)
				
				# Stop chasing if this was the target
				if unit.target_enemy == enemy:
					unit.target_enemy = null

func clear_unit_combat(unit: Unit):
	for enemy in unit.enemies_in_combat.duplicate():
		end_combat(unit, enemy)
