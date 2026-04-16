extends Node2D

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const TEST_ROOM_SCENE := "res://scenes/game/levels/TestRoom.tscn"
const ROOM_ALERT_TEXT := {
	"res://scenes/game/levels/Dungeon.tscn": "Sweep the broken ascent",
	"res://scenes/game/levels/IronFoundry.tscn": "Cut through the foundry watch",
	"res://scenes/game/levels/MoonCrypt.tscn": "Silence the crypt sentries",
	"res://scenes/game/levels/BrokenRampart.tscn": "Retake the shattered rampart"
}
const ROOM_CLEAR_TEXT := {
	"res://scenes/game/levels/Dungeon.tscn": "Claim the next floor at the orange gate",
	"res://scenes/game/levels/IronFoundry.tscn": "The forge is yours. Reach the orange gate",
	"res://scenes/game/levels/MoonCrypt.tscn": "The crypt is clear. Reach the orange gate",
	"res://scenes/game/levels/BrokenRampart.tscn": "The wall is reclaimed. Reach the orange gate"
}

@onready var player: Player = $Player
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel
@onready var hint_label: Label = $CanvasLayer/HUD/VBox/Hint
@onready var exit_area: Area2D = get_node_or_null("ExitArea")

var player_in_exit_area: bool = false

func _ready():
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)
	if exit_area != null:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
		exit_area.body_exited.connect(_on_exit_area_body_exited)
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

	if player_in_exit_area and _can_use_exit() and Input.is_action_just_pressed("interact"):
		_use_exit()
		return
	
	_update_hud()

func _update_hud():
	var enemies_left := _get_alive_enemy_count()
	var is_test_room := scene_file_path == TEST_ROOM_SCENE
	var is_boss_room := not is_test_room and Game.is_boss_floor()
	floor_value_label.text = "T%s" % Game.current_floor if is_test_room else "%02d" % Game.current_floor
	enemies_value_label.text = str(enemies_left)
	hint_label.text = _get_hint_text(is_test_room, is_boss_room, enemies_left)
	if player == null or not is_instance_valid(player):
		state_label.text = "Run failed"
		room_status_label.text = "The prison took you. Press Esc to retreat."
		hint_label.text = "Esc retreat to menu"
		return
	
	if is_test_room:
		if enemies_left > 0:
			state_label.text = "Antechamber contested"
			room_status_label.text = "Defeat the guard to reopen the descent gate"
		else:
			state_label.text = "Descent gate open"
			room_status_label.text = "Press E at the blue gate to descend"
		return

	if is_boss_room:
		if enemies_left > 0:
			state_label.text = "Boss encounter"
			room_status_label.text = "Break the warden before he corners you"
		else:
			state_label.text = "Warden fallen"
			room_status_label.text = "Press E at the crimson gate to finish the run"
		return
	
	if enemies_left > 0:
		state_label.text = "Combat room engaged"
		room_status_label.text = "%s: %s hostiles remain" % [_get_room_alert_text(), enemies_left]
	else:
		state_label.text = "Depth secured"
		room_status_label.text = _get_room_clear_text()

func _get_hint_text(is_test_room: bool, is_boss_room: bool, enemies_left: int) -> String:
	if enemies_left <= 0 and player_in_exit_area:
		return "E use gate  |  LMB attack  |  RMB kick  |  Esc retreat"
	if is_test_room:
		return "Clear the guard, then press E at the blue gate"
	if is_boss_room:
		return "LMB attack  |  RMB kick for knockback  |  Space jump"
	if enemies_left > 0:
		return "A D move  |  Space jump  |  LMB attack  |  RMB kick"
	return "Room clear: reach the orange gate and press E"

func _get_room_alert_text() -> String:
	return ROOM_ALERT_TEXT.get(scene_file_path, "Sweep the cells")

func _get_room_clear_text() -> String:
	var clear_text := ROOM_CLEAR_TEXT.get(scene_file_path, "Press E at the orange gate to claim the next floor")
	return "%s" % clear_text

func _can_use_exit() -> bool:
	return _get_alive_enemy_count() == 0

func _use_exit():
	if scene_file_path == TEST_ROOM_SCENE:
		get_tree().change_scene_to_file(Game.get_floor_scene_path())
		return
	if Game.is_boss_floor():
		Game.complete_run()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	Game.next_floor()
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)

func _on_exit_area_body_entered(body: Node):
	if body == player:
		player_in_exit_area = true
		_update_hud()

func _on_exit_area_body_exited(body: Node):
	if body == player:
		player_in_exit_area = false
		_update_hud()

func _get_alive_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count
