extends Node

const MAX_FLOOR := 5
const FLOOR_SCENES := {
	1: "res://scenes/game/levels/Dungeon.tscn",
	2: "res://scenes/game/levels/IronFoundry.tscn",
	3: "res://scenes/game/levels/MoonCrypt.tscn",
	4: "res://scenes/game/levels/BrokenRampart.tscn",
	5: "res://scenes/game/levels/WardenThrone.tscn"
}

var current_floor: int = 1
var gold: int = 0
var current_run_data: Dictionary = {}
var is_paused: bool = false
var selected_character: String = "warrior"

const CHARACTER_CONFIGS := {
	"warrior": {
		"label": "Warrior",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png",
		"idle_frames": 8,
		"run_frames": 6,
		"attack_frames": 4,
		"attack_hit_frame": 2,
		"attack_type": "melee",
		"max_health": 120,
		"speed": 265.0,
		"jump_velocity": -455.0,
		"attack_damage": 16,
		"attack_range": 54.0
	},
	"archer": {
		"label": "Archer",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Shoot.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 8,
		"attack_hit_frame": 3,
		"attack_pose_frame": 3,
		"attack_type": "ranged",
		"max_health": 90,
		"speed": 295.0,
		"jump_velocity": -480.0,
		"attack_damage": 11,
		"attack_range": 62.0
	},
	"monk": {
		"label": "Monk",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Heal.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 11,
		"attack_hit_frame": 4,
		"attack_pose_frame": -1,
		"attack_type": "melee",
		"max_health": 100,
		"speed": 280.0,
		"jump_velocity": -470.0,
		"attack_damage": 13,
		"attack_range": 50.0
	}
}

func _ready():
	load_game()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

func new_game():
	current_floor = 1
	gold = 0
	current_run_data = {
		"floor": 1,
		"character": selected_character,
		"gold": 0,
		"runes": [],
		"curses": [],
		"relics": [],
		"enemies_killed": 0,
		"damage_dealt": 0,
		"items_collected": 0
	}
	save_game()

func set_selected_character(character_id: String):
	if CHARACTER_CONFIGS.has(character_id):
		selected_character = character_id
		current_run_data["character"] = character_id
		save_game()

func get_selected_character_config() -> Dictionary:
	return CHARACTER_CONFIGS.get(selected_character, CHARACTER_CONFIGS["warrior"])

func next_floor():
	current_floor = mini(current_floor + 1, MAX_FLOOR)
	current_run_data["floor"] = current_floor
	save_game()

func get_floor_scene_path(floor: int = current_floor) -> String:
	var normalized_floor := clampi(floor, 1, MAX_FLOOR)
	return FLOOR_SCENES.get(normalized_floor, FLOOR_SCENES[1])

func is_boss_floor(floor: int = current_floor) -> bool:
	return floor >= MAX_FLOOR

func complete_run():
	current_run_data["last_completed_floor"] = MAX_FLOOR
	current_floor = 1
	current_run_data["floor"] = current_floor
	save_game()

func add_gold(amount: int):
	gold += amount
	current_run_data["gold"] = gold
	save_game()

func lose_gold():
	var lost = gold
	gold = 0
	current_run_data["gold"] = 0
	save_game()
	return lost

func save_game():
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	var json_string = JSON.stringify(current_run_data)
	save_file.store_line(json_string)
	save_file.close()

func load_game():
	if FileAccess.file_exists("user://savegame.dat"):
		var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var json_string = save_file.get_line()
		current_run_data = JSON.parse_string(json_string)
		current_floor = current_run_data.get("floor", 1)
		gold = current_run_data.get("gold", 0)
		selected_character = current_run_data.get("character", selected_character)
		save_file.close()

func game_over():
	lose_gold()
	current_run_data = {}
	save_game()
