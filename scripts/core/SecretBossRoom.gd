extends Node2D

const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"

@onready var player: Player = $Player
@onready var boss = $SecretBoss
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var gold_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/GoldValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel
@onready var hint_label: Label = $CanvasLayer/HUD/VBox/Hint
@onready var message_label: Label = $CanvasLayer/SecretMessage

var reward_given: bool = false

func _ready():
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	boss.defeated.connect(_on_secret_boss_defeated)
	_update_hud()

func register_enemy(enemy):
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	_update_hud()

func _apply_selected_character():
	var config = Game.get_selected_character_config()
	player.max_health = config.get("max_health", player.max_health)
	player.current_health = player.max_health
	player.speed = config.get("speed", player.speed)
	player.jump_velocity = config.get("jump_velocity", player.jump_velocity)
	player.attack_damage = config.get("attack_damage", player.attack_damage)
	player.attack_range = config.get("attack_range", player.attack_range)
	player.max_mana = config.get("max_mana", player.max_mana)
	player.magic_mana_drain_per_second = config.get("magic_mana_drain_per_second", player.magic_mana_drain_per_second)
	player.magic_mana_regen_per_second = config.get("magic_mana_regen_per_second", player.magic_mana_regen_per_second)
	player.magic_bolt_damage = config.get("magic_bolt_damage", player.magic_bolt_damage)
	player.starfall_max_charge_time = config.get("starfall_max_charge_time", player.starfall_max_charge_time)
	player.starfall_min_mana_cost = config.get("starfall_min_mana_cost", player.starfall_min_mana_cost)
	player.starfall_max_mana_cost = config.get("starfall_max_mana_cost", player.starfall_max_mana_cost)
	player.starfall_base_damage = config.get("starfall_base_damage", player.starfall_base_damage)
	player.starfall_extra_damage = config.get("starfall_extra_damage", player.starfall_extra_damage)
	player.starfall_base_count = config.get("starfall_base_count", player.starfall_base_count)
	player.starfall_extra_count = config.get("starfall_extra_count", player.starfall_extra_count)
	player.set_character_visuals(
		config.get("idle", ""),
		config.get("run", ""),
		config.get("attack", ""),
		config.get("idle_frames", 8),
		config.get("run_frames", 6),
		config.get("attack_frames", 4),
		config.get("attack_hit_frame", 2),
		config.get("attack_pose_frame", -1),
		config.get("attack_type", "melee"),
		bool(config.get("double_jump", false))
	)
	player.modulate = config.get("modulate", Color(1, 1, 1, 1))
	player.current_mana = player.max_mana
	player._update_mana_bar()
	player._update_health_bar()

func _update_hud():
	var enemies_left := _get_alive_enemy_count()
	floor_value_label.text = "??"
	enemies_value_label.text = str(enemies_left)
	gold_value_label.text = str(Game.gold)
	if reward_given:
		state_label.text = "Secret covenant sealed"
		room_status_label.text = "The priest skin has awakened"
		hint_label.text = "Esc retreat to menu"
	else:
		state_label.text = "Hidden boss"
		room_status_label.text = "Survive the violet priest"
		hint_label.text = "Cards home in  |  Scythes fall  |  Bring him to 1%"

func _on_secret_boss_defeated():
	if reward_given:
		return
	reward_given = true
	Game.unlock_secret_priest()
	Game.set_secret_step(3)
	message_label.text = "You won. Carry my violet rite."
	message_label.visible = true
	_update_hud()

func _on_enemy_died():
	_update_hud()

func _on_player_died():
	state_label.text = "The secret rite failed"
	room_status_label.text = "Press Esc to retreat."

func _get_alive_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count
