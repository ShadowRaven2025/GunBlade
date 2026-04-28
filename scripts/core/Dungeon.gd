extends Node2D

const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"
const TEST_ROOM_SCENE = "res://scenes/game/levels/TestRoom.tscn"
const SECRET_FLASH_TEXT = "A violet covenant answers."
const ROOM_ALERT_TEXT = {
	"res://scenes/game/levels/Dungeon.tscn": "Sweep the broken ascent",
	"res://scenes/game/levels/IronFoundry.tscn": "Cut through the foundry watch",
	"res://scenes/game/levels/MoonCrypt.tscn": "Silence the crypt sentries",
	"res://scenes/game/levels/BrokenRampart.tscn": "Retake the shattered rampart"
}
const ROOM_CLEAR_TEXT = {
	"res://scenes/game/levels/Dungeon.tscn": "Claim the next floor at the orange gate",
	"res://scenes/game/levels/IronFoundry.tscn": "The forge is yours. Reach the orange gate",
	"res://scenes/game/levels/MoonCrypt.tscn": "The crypt is clear. Reach the orange gate",
	"res://scenes/game/levels/BrokenRampart.tscn": "The wall is reclaimed. Reach the orange gate"
}

@onready var player = $Player
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var gold_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/GoldValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel
@onready var hint_label: Label = $CanvasLayer/HUD/VBox/Hint
@onready var exit_area = get_node_or_null("ExitArea")
@onready var secret_flash_label: Label = get_node_or_null("CanvasLayer/SecretFlash")

var player_in_exit_area: bool = false
var room_reward_granted: bool = false
var secret_triggered: bool = false

func _ready():
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	if exit_area != null:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
		exit_area.body_exited.connect(_on_exit_area_body_exited)
	if secret_flash_label != null:
		secret_flash_label.visible = false
	_update_hud()

func register_enemy(enemy):
	if enemy == null or not is_instance_valid(enemy):
		return
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

func _apply_selected_character():
	var config = Game.get_selected_character_config()
	var relic_modifiers = Game.get_player_relic_modifiers()
	player.max_health = config.get("max_health", player.max_health)
	player.max_health += relic_modifiers.get("bonus_health", 0)
	player.current_health = player.max_health
	player.speed = config.get("speed", player.speed)
	player.speed += relic_modifiers.get("bonus_speed", 0.0)
	player.jump_velocity = config.get("jump_velocity", player.jump_velocity)
	player.jump_velocity += relic_modifiers.get("bonus_jump", 0.0)
	player.attack_damage = config.get("attack_damage", player.attack_damage)
	player.attack_damage += relic_modifiers.get("bonus_damage", 0)
	player.attack_range = config.get("attack_range", player.attack_range)
	player.attack_range += relic_modifiers.get("bonus_attack_range", 0.0)
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
	player.kick_knockback_force = 340.0 + relic_modifiers.get("bonus_kick_force", 0.0)
	player.attack_cooldown = 0.42 * relic_modifiers.get("attack_cooldown_multiplier", 1.0)
	player.kick_cooldown = 0.52 * relic_modifiers.get("kick_cooldown_multiplier", 1.0)
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

func _on_enemy_died():
	Game.record_enemy_kill()
	_grant_room_reward_if_ready()
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

	_check_secret_fall()
	
	_update_hud()

func _update_hud():
	var enemies_left = _get_alive_enemy_count()
	var is_test_room = scene_file_path == TEST_ROOM_SCENE
	var is_boss_room = not is_test_room and Game.is_boss_floor()
	floor_value_label.text = "T%s" % Game.current_floor if is_test_room else "%02d" % Game.current_floor
	enemies_value_label.text = str(enemies_left)
	gold_value_label.text = str(Game.gold)
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

	_grant_room_reward_if_ready()

	if is_boss_room:
		if enemies_left > 0:
			state_label.text = "Boss encounter"
			room_status_label.text = "Break the warden before he corners you"
		else:
			state_label.text = "Warden fallen"
			room_status_label.text = "Boss reward claimed. Press E at the crimson gate to finish the run"
		return
	
	if enemies_left > 0:
		state_label.text = "Combat room engaged"
		room_status_label.text = "%s: %s hostiles remain" % [_get_room_alert_text(), enemies_left]
	else:
		state_label.text = "Depth secured"
		room_status_label.text = _get_room_clear_text()

	if not is_test_room and not Game.get_relic_ids().is_empty():
		state_label.text = Game.get_relic_summary_text()

func _get_hint_text(is_test_room: bool, is_boss_room: bool, enemies_left: int) -> String:
	if enemies_left <= 0 and player_in_exit_area:
		return "E use gate  |  LMB attack  |  RMB skill  |  Esc retreat" if player.attack_type == "magic" else "E use gate  |  LMB attack  |  RMB kick  |  Esc retreat"
	if is_test_room:
		return "Clear the guard, then press E at the blue gate"
	if is_boss_room:
		return "LMB cast bolts  |  Hold RMB call stars  |  Space jump" if player.attack_type == "magic" else "LMB attack  |  RMB kick for knockback  |  Space jump"
	if enemies_left > 0:
		return "A D move  |  Space jump  |  LMB cast  |  Hold RMB starfall" if player.attack_type == "magic" else "A D move  |  Space jump  |  LMB attack  |  RMB kick"
	return "Room clear: reach the orange gate and press E"

func _get_room_alert_text() -> String:
	return ROOM_ALERT_TEXT.get(scene_file_path, "Sweep the cells")

func _get_room_clear_text() -> String:
	var clear_text = str(ROOM_CLEAR_TEXT.get(scene_file_path, "Press E at the orange gate to claim the next floor"))
	return "%s" % clear_text

func _grant_room_reward_if_ready():
	if room_reward_granted:
		return
	if scene_file_path == TEST_ROOM_SCENE:
		return
	if _get_alive_enemy_count() > 0:
		return
	var reward = _get_room_reward_amount()
	Game.add_gold(reward)
	Game.record_room_clear()
	room_reward_granted = true

func _get_room_reward_amount() -> int:
	if Game.is_boss_floor():
		return 90
	return 12 + Game.current_floor * 8

func _can_use_exit() -> bool:
	return _get_alive_enemy_count() == 0

func _use_exit():
	if scene_file_path == TEST_ROOM_SCENE:
		get_tree().change_scene_to_file(Game.get_floor_scene_path())
		return
	if Game.is_boss_floor():
		Game.prepare_boss_rewards()
		get_tree().change_scene_to_file(Game.BOSS_REWARD_SCENE)
		return
	Game.next_floor()
	get_tree().change_scene_to_file(Game.get_floor_scene_path())

func _check_secret_fall():
	if secret_triggered or player == null or not is_instance_valid(player):
		return
	if _get_alive_enemy_count() > 0:
		return
	if player.global_position.y < 700.0:
		return
	if Game.is_secret_route_active() and scene_file_path == Game.get_floor_scene_path(1) and Game.get_secret_step() == 0 and player.global_position.x < 260.0:
		secret_triggered = true
		Game.set_secret_step(1)
		await _show_secret_flash()
		Game.next_floor()
		get_tree().change_scene_to_file(Game.get_floor_scene_path())
		return
	if Game.is_secret_route_active() and scene_file_path == Game.get_floor_scene_path(3) and Game.get_secret_step() == 1 and player.global_position.x > 1020.0:
		secret_triggered = true
		Game.set_secret_step(2)
		get_tree().change_scene_to_file(Game.SECRET_BOSS_SCENE)
		return
	secret_triggered = true
	player.take_damage(player.current_health)

func _show_secret_flash():
	if secret_flash_label == null:
		return
	secret_flash_label.text = SECRET_FLASH_TEXT
	secret_flash_label.visible = true
	await get_tree().create_timer(0.1).timeout
	if secret_flash_label != null:
		secret_flash_label.visible = false

func _on_exit_area_body_entered(body: Node):
	if body == player:
		player_in_exit_area = true
		_update_hud()

func _on_exit_area_body_exited(body: Node):
	if body == player:
		player_in_exit_area = false
		_update_hud()

func _get_alive_enemy_count() -> int:
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count
