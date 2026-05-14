extends Control

const TEST_ROOM_SCENE = "res://scenes/game/levels/TestRoom.tscn"

var highlighted_character: String = "warrior"
var secret_boss_after_route: String = "priest"
var selected_skins: Dictionary = {
	"warrior": "warrior",
	"archer": "archer",
	"monk": "monk"
}
var default_card_icons: Dictionary = {}

func _ready():
	default_card_icons = {
		"warrior": $Panel/VBox/Cards/WarriorButton.icon,
		"archer": $Panel/VBox/Cards/ArcherButton.icon,
		"monk": $Panel/VBox/Cards/MonkButton.icon
	}
	$Panel/VBox/Header/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/Cards/WarriorButton.pressed.connect(_on_warrior_pressed)
	$Panel/VBox/Cards/ArcherButton.pressed.connect(_on_archer_pressed)
	$Panel/VBox/Cards/MonkButton.pressed.connect(_on_monk_pressed)
	$Panel/VBox/BossToggle.pressed.connect(_on_boss_toggle_pressed)
	$Panel/VBox/Cards/WarriorButton.mouse_entered.connect(_on_warrior_highlighted)
	$Panel/VBox/Cards/ArcherButton.mouse_entered.connect(_on_archer_highlighted)
	$Panel/VBox/Cards/MonkButton.mouse_entered.connect(_on_monk_highlighted)
	$Panel/VBox/Cards/WarriorButton.focus_entered.connect(_on_warrior_highlighted)
	$Panel/VBox/Cards/ArcherButton.focus_entered.connect(_on_archer_highlighted)
	$Panel/VBox/Cards/MonkButton.focus_entered.connect(_on_monk_highlighted)
	secret_boss_after_route = Game.get_selected_secret_boss()
	if secret_boss_after_route != "dark_knight":
		secret_boss_after_route = "priest"
	_update_boss_toggle()
	_update_unlocks()

func _input(event: InputEvent):
	if event.is_action_pressed("secret_start"):
		Game.set_selected_secret_boss(secret_boss_after_route)
		_start_run(_get_selected_skin(highlighted_character), true)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_G:
		_cycle_skin_for_highlighted_character()

func _on_warrior_pressed():
	highlighted_character = "warrior"
	_start_run(_get_selected_skin("warrior"))

func _on_archer_pressed():
	highlighted_character = "archer"
	_start_run(_get_selected_skin("archer"))

func _on_monk_pressed():
	highlighted_character = "monk"
	_start_run(_get_selected_skin("monk"))

func _on_warrior_highlighted():
	highlighted_character = "warrior"
	_update_skin_panel()

func _on_archer_highlighted():
	highlighted_character = "archer"
	_update_skin_panel()

func _on_monk_highlighted():
	highlighted_character = "monk"
	_update_skin_panel()

func _on_boss_toggle_pressed():
	secret_boss_after_route = "dark_knight" if secret_boss_after_route == "priest" else "priest"
	Game.set_selected_secret_boss(secret_boss_after_route)
	_update_boss_toggle()

func _update_boss_toggle():
	var boss_name := "Dark Knight" if secret_boss_after_route == "dark_knight" else "Secret Priest"
	$Panel/VBox/BossToggle.text = "Boss after secret route: %s" % boss_name

func _cycle_skin_for_highlighted_character():
	var options := Game.get_skin_options_for_character(highlighted_character)
	if options.is_empty():
		return
	var current_skin := _get_selected_skin(highlighted_character)
	var current_index := options.find(current_skin)
	if current_index < 0:
		current_index = 0
	var next_skin := options[(current_index + 1) % options.size()]
	selected_skins[highlighted_character] = next_skin
	_update_skin_panel()
	_update_unlocks()

func _get_selected_skin(character_id: String) -> String:
	return str(selected_skins.get(character_id, character_id))

func _update_skin_panel():
	var skin_id := _get_selected_skin(highlighted_character)
	var config: Dictionary = Game.CHARACTER_CONFIGS.get(skin_id, Game.CHARACTER_CONFIGS[highlighted_character])
	var skin_title := str(config.get("skin_title", config.get("label", skin_id)))
	var skin_description := str(config.get("skin_description", "Default loadout"))
	$Panel/VBox/SkinPanel/VBox/SkinLabel.text = "Skin for %s: %s" % [highlighted_character.capitalize(), skin_title]
	$Panel/VBox/SkinPanel/VBox/SkinDescription.text = skin_description

func _start_run(character_id: String, secret_route: bool = false):
	Game.set_selected_character(character_id)
	if secret_route:
		Game.set_selected_secret_boss(secret_boss_after_route)
	Game.new_game(secret_route)
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)

func _update_unlocks():
	var warrior_skin: String = str(Game.CHARACTER_CONFIGS.get(_get_selected_skin("warrior"), {}).get("skin_title", "Default"))
	var archer_skin: String = str(Game.CHARACTER_CONFIGS.get(_get_selected_skin("archer"), {}).get("skin_title", "Default"))
	var monk_skin: String = str(Game.CHARACTER_CONFIGS.get(_get_selected_skin("monk"), {}).get("skin_title", "Default"))
	$Panel/VBox/Cards/WarriorButton.text = "Warrior\nHeavy melee\nSkin: %s" % warrior_skin
	$Panel/VBox/Cards/ArcherButton.text = "Archer\nFast striker\nSkin: %s" % archer_skin
	_update_card_icon($Panel/VBox/Cards/WarriorButton, "warrior")
	_update_card_icon($Panel/VBox/Cards/ArcherButton, "archer")
	_update_card_icon($Panel/VBox/Cards/MonkButton, "monk")
	if Game.is_secret_priest_unlocked():
		$Panel/VBox/Cards/MonkButton.text = "Monk\nSecret rite unlocked\nSkin: %s" % monk_skin
	else:
		$Panel/VBox/Cards/MonkButton.text = "Monk\nBalanced mobility\nSkin: %s" % monk_skin
	$Panel/VBox/Hint.text = "G cycles skins for the highlighted hero. C starts the hidden route. Boss Toggle chooses the secret-route boss."
	_update_skin_panel()

func _update_card_icon(button: Button, character_id: String):
	var skin_id := _get_selected_skin(character_id)
	if skin_id == "warrior_spearman":
		button.icon = preload("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Lancer/Lancer_Idle.png")
		return
	button.icon = default_card_icons.get(character_id, button.icon)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
