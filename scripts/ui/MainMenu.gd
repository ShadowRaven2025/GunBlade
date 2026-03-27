extends Control

func _ready():
	$VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/Quit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/game/levels/Dungeon.tscn")

func _on_quit_pressed():
	get_tree().quit()
