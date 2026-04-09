extends Control

const TEST_ROOM_SCENE := "res://scenes/game/levels/TestRoom.tscn"

func _ready():
	$Panel/VBox/Header/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/Cards/WarriorButton.pressed.connect(func(): _start_run("warrior"))
	$Panel/VBox/Cards/ArcherButton.pressed.connect(func(): _start_run("archer"))
	$Panel/VBox/Cards/MonkButton.pressed.connect(func(): _start_run("monk"))

func _start_run(character_id: String):
	Game.set_selected_character(character_id)
	Game.new_game()
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
