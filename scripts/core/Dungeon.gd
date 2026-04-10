extends Node2D

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const TEST_ROOM_SCENE := "res://scenes/game/levels/TestRoom.tscn"

@onready var player: Player = $Player
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel

func _ready():
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)
	_update_hud()

func _apply_selected_character():
	var config := Game.get_selected_character_config()
	player.max_health = config.get("max_health", player.max_health)
	player.current_health = player.max_health
	player.speed = config.get("speed", player.speed)
	player.jump_velocity = config.get("jump_velocity", player.jump_velocity)
	player.attack_damage = config.get("attack_damage", player.attack_damage)
	player.attack_range = config.get("attack_range", player.attack_range)
	player.set_character_visuals(
		config.get("idle", ""),
		config.get("run", ""),
		config.get("attack", ""),
		config.get("idle_frames", 8),
		config.get("run_frames", 6),
		config.get("attack_frames", 4),
		config.get("attack_hit_frame", 2),
		config.get("attack_pose_frame", -1),
		config.get("attack_type", "melee")
	)
	player._update_health_bar()

func _on_enemy_died():
	_update_hud()

func _on_player_died():
	state_label.text = "Run failed"
	room_status_label.text = "The prison took you. Press Esc to retreat."

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	
	_update_hud()

func _update_hud():
	var enemies_left := _get_alive_enemy_count()
	var is_test_room := scene_file_path == TEST_ROOM_SCENE
	floor_value_label.text = "T1" if is_test_room else "01"
	enemies_value_label.text = str(enemies_left)
	if player == null or not is_instance_valid(player):
		state_label.text = "Run failed"
		room_status_label.text = "The prison took you. Press Esc to retreat."
		return
	
	if is_test_room:
		if enemies_left > 0:
			state_label.text = "Dummy enemy respawns after death"
			room_status_label.text = "Respawn dummy sandbox"
		else:
			state_label.text = "Respawn cycle pending"
			room_status_label.text = "Dummy enemy will return shortly"
		return
	
	if enemies_left > 0:
		state_label.text = "Combat room engaged"
		room_status_label.text = "Sweep the platform: %s hostiles remain" % enemies_left
	else:
		state_label.text = "Platform secured"
		room_status_label.text = "The route ahead is clear. Press Esc to retreat for now."

func _get_alive_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count
