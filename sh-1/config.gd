extends Node
class_name GameConfig

# MASSIVE GRID - 64x64 big cells (4x bigger!)
const GRID_WIDTH = 64
const GRID_HEIGHT = 64
const SUB_CELLS_PER_BIG_CELL = 4
const BIG_CELL_SIZE = 128
const SUB_CELL_SIZE = BIG_CELL_SIZE / SUB_CELLS_PER_BIG_CELL  # 32 pixels

# Total sub-grid (256×256 sub-cells!)
const TOTAL_SUB_WIDTH = GRID_WIDTH * SUB_CELLS_PER_BIG_CELL  # 256
const TOTAL_SUB_HEIGHT = GRID_HEIGHT * SUB_CELLS_PER_BIG_CELL  # 256

# Total world size
const WORLD_WIDTH = GRID_WIDTH * BIG_CELL_SIZE  # 8192 pixels!
const WORLD_HEIGHT = GRID_HEIGHT * BIG_CELL_SIZE  # 8192 pixels!

# Camera viewport - Shows only 16×16 cells at once
const VIEWPORT_GRID_SIZE = 16  # See 16×16 cells
const GAME_VIEWPORT_WIDTH = VIEWPORT_GRID_SIZE * BIG_CELL_SIZE  # 2048 pixels
const GAME_VIEWPORT_HEIGHT = VIEWPORT_GRID_SIZE * BIG_CELL_SIZE  # 2048 pixels

# Side panel
const SIDE_PANEL_WIDTH = 450
const TOTAL_WINDOW_WIDTH = GAME_VIEWPORT_WIDTH + SIDE_PANEL_WIDTH  # 2498
const TOTAL_WINDOW_HEIGHT = GAME_VIEWPORT_HEIGHT  # 2048

# Minimap - Shows full 64×64 grid
const MINIMAP_SIZE = 400  # Bigger minimap for 64×64 grid
const MINIMAP_POSITION = Vector2(GAME_VIEWPORT_WIDTH + 25, 25)
const MINIMAP_CELL_SIZE = float(MINIMAP_SIZE) / float(GRID_WIDTH)  # ~6.25 pixels per cell

# Units
const MAX_UNITS_PER_CELL = 16
const UNITS_PER_ROW = 4

# Game balance
const MAX_UNITS_PER_TEAM = 16  # More units for bigger map
const BASE_SPAWN_INTERVAL = 12.0
const CHECKPOINT_CLAIM_TIME = 8.0
const STARTING_UNITS = 6

# Checkpoints - More for bigger map
const MAX_NORMAL_CHECKPOINTS = 40
const MAX_HEALING_CHECKPOINTS = 20
const MAX_CHECKPOINTS_CLOSE_TOGETHER = 3
const MIN_CHECKPOINT_DISTANCE = 5

const CHECKPOINT_SPAWN_BONUS = 1.0
const MIN_SPAWN_INTERVAL = 3.0
const HEAL_PER_SECOND = 25.0

# Combat
const COMBAT_COLLISION_DISTANCE = SUB_CELL_SIZE * 2.5
const MAX_SIMULTANEOUS_FIGHTS = 8
const AGGRO_RANGE = SUB_CELL_SIZE * 12.0

# XP
const BASE_XP_REQUIREMENT = 30
const XP_MULTIPLIER = 2.0
const STAT_INCREASE_MIN = 0.15
const STAT_INCREASE_MAX = 0.25

# Unit types
enum UnitType {
	ATTACKER,
	TANK,
	DEFENDER,
	SPEEDSTER,
	BRUISER
}

const UNIT_CONFIGS = {
	UnitType.ATTACKER: {
		"name": "Attacker",
		"corners": 8,
		"max_hp": 160.0,
		"attack": 55.0,
		"defense": 5.0,
		"speed": 1.7,
		"spin_speed": 20.0,
		"size": 20
	},
	UnitType.TANK: {
		"name": "Tank",
		"corners": 4,
		"max_hp": 500.0,
		"attack": 15.0,
		"defense": 50.0,
		"speed": 0.5,
		"spin_speed": 5.0,
		"size": 25
	},
	UnitType.DEFENDER: {
		"name": "Defender",
		"corners": 6,
		"max_hp": 300.0,
		"attack": 25.0,
		"defense": 45.0,
		"speed": 1.2,
		"spin_speed": 12.0,
		"size": 22
	},
	UnitType.SPEEDSTER: {
		"name": "Speedster",
		"corners": 12,
		"max_hp": 120.0,
		"attack": 18.0,
		"defense": 8.0,
		"speed": 2.5,
		"spin_speed": 30.0,
		"size": 18
	},
	UnitType.BRUISER: {
		"name": "Bruiser",
		"corners": 5,
		"max_hp": 450.0,
		"attack": 40.0,
		"defense": 25.0,
		"speed": 0.6,
		"spin_speed": 7.0,
		"size": 24
	}
}

# Colors
const TEAM_COLORS = {
	"red": Color(1.0, 0.2, 0.2),
	"green": Color(0.2, 1.0, 0.2),
	"blue": Color(0.3, 0.6, 1.0),
	"yellow": Color(1.0, 0.9, 0.2),
	"neutral": Color(0.5, 0.5, 0.5)
}

const TEAMS = ["red", "green", "blue", "yellow"]

# Home bases in corners of 64×64 grid
const HOME_BASE_POSITIONS = {
	"red": Vector2i(2, 2),
	"green": Vector2i(61, 2),
	"blue": Vector2i(2, 61),
	"yellow": Vector2i(61, 61)
}

const PLAYER_TEAM = "blue"
