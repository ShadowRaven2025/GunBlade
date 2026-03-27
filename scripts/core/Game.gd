extends Node

var current_floor: int = 1
var gold: int = 0
var current_run_data: Dictionary = {}
var is_paused: bool = false

func _ready():
	load_game()

func _process(delta):
	if Input.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

func new_game():
	current_floor = 1
	gold = 0
	current_run_data = {
		"floor": 1,
		"gold": 0,
		"runes": [],
		"curses": [],
		"relics": [],
		"enemies_killed": 0,
		"damage_dealt": 0,
		"items_collected": 0
	}
	save_game()

func next_floor():
	current_floor += 1
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
		save_file.close()

func game_over():
	lose_gold()
	current_run_data = {}
	save_game()
