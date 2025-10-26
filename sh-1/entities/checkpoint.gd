extends Entity
class_name Checkpoint

enum Type {
	NORMAL,
	HEALING
}

var checkpoint_type: Type = Type.NORMAL
var claiming_team: String = "neutral"
var claim_timer: float = 0.0
var controlled_by: String = "neutral"

signal claimed(new_team)

func _init(x: int, y: int, type: Type = Type.NORMAL):
	super(x, y, "neutral")
	checkpoint_type = type

func start_claiming(new_team: String):
	if claiming_team != new_team:
		claiming_team = new_team
		claim_timer = 0.0

func update(delta: float, unit_on_checkpoint: bool, occupying_team: String) -> bool:
	if not unit_on_checkpoint:
		claiming_team = controlled_by
		claim_timer = 0.0
		return false
	
	start_claiming(occupying_team)
	
	if claiming_team != "neutral" and claiming_team != controlled_by:
		claim_timer += delta
		if claim_timer >= GameConfig.CHECKPOINT_CLAIM_TIME:
			controlled_by = claiming_team
			team = claiming_team
			claim_timer = 0.0
			claimed.emit(claiming_team)
			return true
	
	return false

func heal_units(units_on_checkpoint: Array[Unit], delta: float):
	if checkpoint_type != Type.HEALING:
		return
	
	# Only heal units that control this checkpoint
	for unit in units_on_checkpoint:
		if unit.team == controlled_by:
			unit.heal(GameConfig.HEAL_PER_SECOND * delta)

func get_claim_progress() -> float:
	if claiming_team == controlled_by:
		return 1.0
	return claim_timer / GameConfig.CHECKPOINT_CLAIM_TIME

func is_healing_checkpoint() -> bool:
	return checkpoint_type == Type.HEALING
