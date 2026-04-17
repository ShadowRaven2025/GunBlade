extends Control

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"

@onready var title_label: Label = $Panel/VBox/Title
@onready var subtitle_label: Label = $Panel/VBox/Subtitle
@onready var reward_a: Button = $Panel/VBox/Rewards/RewardA
@onready var reward_b: Button = $Panel/VBox/Rewards/RewardB
@onready var reward_c: Button = $Panel/VBox/Rewards/RewardC
@onready var hint_label: Label = $Panel/VBox/Hint

var reward_buttons: Array[Button] = []
var reward_options: Array = []

func _ready():
	reward_buttons = [reward_a, reward_b, reward_c]
	reward_options = Game.get_pending_boss_rewards()
	if reward_options.is_empty():
		Game.prepare_boss_rewards()
		reward_options = Game.get_pending_boss_rewards()
	title_label.text = "Choose A Relic"
	subtitle_label.text = "The warden is down. Take one relic before ending the run."
	hint_label.text = "Each relic is stored in the run record. Some also add bonus gold immediately."
	for i in range(reward_buttons.size()):
		var button: Button = reward_buttons[i]
		if i >= reward_options.size():
			button.disabled = true
			button.text = "Unavailable"
			continue
		var relic: Dictionary = reward_options[i]
		var relic_title: String = str(relic.get("title", "Unknown Relic"))
		var relic_description: String = str(relic.get("description", ""))
		var relic_id: String = str(relic.get("id", ""))
		button.text = "%s\n%s" % [relic_title, relic_description]
		button.pressed.connect(_on_reward_selected.bind(relic_id))

func _on_reward_selected(relic_id: String):
	if relic_id == "":
		return
	Game.claim_boss_reward(relic_id)
	Game.complete_run()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
