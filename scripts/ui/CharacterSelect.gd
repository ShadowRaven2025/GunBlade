extends Control

const TEST_ROOM_SCENE = "res://scenes/game/levels/TestRoom.tscn"

func _ready():
	$Panel/VBox/Header/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/Cards/WarriorButton.pressed.connect(_on_warrior_pressed)
	$Panel/VBox/Cards/ArcherButton.pressed.connect(_on_archer_pressed)
	$Panel/VBox/Cards/MonkButton.pressed.connect(_on_monk_pressed)
	_update_unlocks()

func _input(event: InputEvent):
	if event.is_action_pressed("secret_start"):
		var character_id := Game.selected_character
		if not Game.CHARACTER_CONFIGS.has(character_id):
			character_id = "warrior"
		_start_run(character_id, true)

func _on_warrior_pressed():
	_start_run("warrior")

func _on_archer_pressed():
	_start_run("archer")

func _on_monk_pressed():
	_start_run("monk")

func _start_run(character_id: String, secret_route: bool = false):
	Game.set_selected_character(character_id)
	Game.new_game(secret_route)
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)

func _update_unlocks():
	if Game.is_secret_priest_unlocked():
		$Panel/VBox/Cards/MonkButton.text = "Monk\nSecret priest skin unlocked\nC starts hidden route"
	else:
		$Panel/VBox/Cards/MonkButton.text = "Monk\nBalanced mobility\nPress C for hidden route"

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
