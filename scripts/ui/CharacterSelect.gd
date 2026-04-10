extends Control

const TEST_ROOM_SCENE = "res://scenes/game/levels/TestRoom.tscn"

func _ready():
	$Panel/VBox/Header/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/Cards/WarriorButton.pressed.connect(_on_warrior_pressed)
	$Panel/VBox/Cards/ArcherButton.pressed.connect(_on_archer_pressed)
	$Panel/VBox/Cards/MonkButton.pressed.connect(_on_monk_pressed)

func _on_warrior_pressed():
	_start_run("warrior")

func _on_archer_pressed():
	_start_run("archer")

func _on_monk_pressed():
	_start_run("monk")

func _start_run(character_id: String):
	Game.set_selected_character(character_id)
	Game.new_game()
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
