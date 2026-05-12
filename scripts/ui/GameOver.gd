extends Control

const CHARACTER_SELECT_SCENE = "res://scenes/menus/CharacterSelect.tscn"
const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"

func _ready():
	$Panel/VBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/VBox/MenuButton.pressed.connect(_on_menu_pressed)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$Panel/VBox/StatsLabel.text = "Gold lost: %d\nFloor reached: %d" % [Game.gold, Game.current_floor]
	Game.game_over()

func _on_retry_pressed():
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_menu_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_quit_pressed():
	get_tree().quit()
