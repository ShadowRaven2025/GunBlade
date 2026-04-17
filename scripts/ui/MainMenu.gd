extends Control

func _ready():
	$Panel/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$Panel/VBoxContainer/TestRoom.pressed.connect(_on_test_room_pressed)
	$Panel/VBoxContainer/SettingsCard/GraphicsRow/GraphicsOption.item_selected.connect(_on_graphics_selected)
	$Panel/VBoxContainer/SettingsCard/FullscreenToggle.toggled.connect(_on_fullscreen_toggled)
	$Panel/VBoxContainer/Quit.pressed.connect(_on_quit_pressed)
	_setup_settings_ui()

func _setup_settings_ui():
	var graphics_option = $Panel/VBoxContainer/SettingsCard/GraphicsRow/GraphicsOption
	graphics_option.clear()
	graphics_option.add_item("Low")
	graphics_option.add_item("Medium")
	graphics_option.add_item("High")
	match Game.get_graphics_quality():
		"low":
			graphics_option.select(0)
		"high":
			graphics_option.select(2)
		_:
			graphics_option.select(1)
	$Panel/VBoxContainer/SettingsCard/FullscreenToggle.button_pressed = Game.is_fullscreen_enabled()

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/CharacterSelect.tscn")

func _on_test_room_pressed():
	Game.set_selected_character("warrior")
	Game.new_game()
	get_tree().change_scene_to_file("res://scenes/game/levels/TestRoom.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_graphics_selected(index: int):
	var quality = "medium"
	if index == 0:
		quality = "low"
	elif index == 2:
		quality = "high"
	Game.set_graphics_quality(quality)

func _on_fullscreen_toggled(enabled: bool):
	Game.set_fullscreen_enabled(enabled)
