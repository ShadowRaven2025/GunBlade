extends Control

func _ready():
	$Panel/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$Panel/VBoxContainer/Quit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/CharacterSelect.tscn")

func _on_quit_pressed():
	get_tree().quit()
