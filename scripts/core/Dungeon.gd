extends Node2D

const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"
const GAME_OVER_SCENE = "res://scenes/menus/GameOver.tscn"
const TEST_ROOM_SCENE = "res://scenes/game/levels/TestRoom.tscn"
const SECRET_FLASH_TEXT = "A violet covenant answers."
const PIT_DEATH_Y := 700.0
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
const BOSS_INTRO_LINES := [
	"Warden: Another prisoner reaches my throne.",
	"Hero: Open the gate, or I carve it open.",
	"Warden: Then break your chains against me."
]

@onready var player = $Player
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var gold_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/GoldValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel
@onready var hint_label: Label = $CanvasLayer/HUD/VBox/Hint
@onready var exit_area = get_node_or_null("ExitArea")
@onready var secret_flash_label: Label = get_node_or_null("CanvasLayer/SecretFlash")
@onready var darkness_switch: Area2D = get_node_or_null("DarknessSwitch")
@onready var darkness_switch_visual: ColorRect = get_node_or_null("DarknessSwitchVisual")
@onready var darkness_door: Area2D = get_node_or_null("DarknessDoor")
@onready var darkness_door_visual: ColorRect = get_node_or_null("DarknessDoorVisual")
@onready var boss_dialog_panel: PanelContainer = get_node_or_null("CanvasLayer/BossDialogPanel")
@onready var boss_dialog_label: Label = get_node_or_null("CanvasLayer/BossDialogPanel/VBox/DialogLabel")

var player_in_exit_area: bool = false
var room_reward_granted: bool = false
var secret_triggered: bool = false
var changing_scene: bool = false
var player_in_darkness_switch: bool = false
var player_in_darkness_door: bool = false
var darkness_door_open: bool = false
var boss_intro_active: bool = false
var boss_intro_done: bool = false

func _ready():
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	if exit_area != null:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
		exit_area.body_exited.connect(_on_exit_area_body_exited)
	_setup_darkness_gate()
	_setup_boss_intro()
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
	player.attack_hit_radius = config.get("attack_hit_radius", player.attack_hit_radius)
	player.attack_cooldown = config.get("attack_cooldown", 0.42) * relic_modifiers.get("attack_cooldown_multiplier", 1.0)
	player.attack_anim_speed = config.get("attack_anim_speed", player.attack_anim_speed)
	player.kick_attack_type = config.get("kick_attack_type", "melee")
	player.kick_damage = config.get("kick_damage", player.kick_damage)
	player.kick_range = config.get("kick_range", player.kick_range)
	player.kick_hit_radius = config.get("kick_hit_radius", player.kick_hit_radius)
	player.kick_cooldown = config.get("kick_cooldown", 0.52) * relic_modifiers.get("kick_cooldown_multiplier", 1.0)
	player.kick_hit_frame = config.get("kick_hit_frame", player.kick_hit_frame)
	player.ranged_backstep_speed = config.get("ranged_backstep_speed", player.ranged_backstep_speed)
	player.ranged_backstep_duration = config.get("ranged_backstep_duration", player.ranged_backstep_duration)
	player.parry_duration = config.get("parry_duration", player.parry_duration)
	player.special_ability = config.get("special_ability", "")
	player.special_heal_amount = config.get("special_heal_amount", player.special_heal_amount)
	player.special_cooldown = config.get("special_cooldown", player.special_cooldown)
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
	player.kick_knockback_force = config.get("kick_knockback_force", 340.0) + relic_modifiers.get("bonus_kick_force", 0.0)
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
	if changing_scene:
		return
	changing_scene = true
	state_label.text = "Run failed"
	room_status_label.text = "The prison took you. Press Esc to retreat."
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func _process(_delta):
	if changing_scene or get_tree() == null:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		changing_scene = true
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	if boss_intro_active:
		return

	if player_in_exit_area and _can_use_exit() and Input.is_action_just_pressed("interact"):
		_use_exit()
		return
	if scene_file_path == Game.get_floor_scene_path(1) and Input.is_action_just_pressed("interact"):
		if player_in_darkness_switch and _can_activate_darkness_switch():
			_activate_darkness_switch()
			return
		if player_in_darkness_door and darkness_door_open:
			changing_scene = true
			get_tree().change_scene_to_file(Game.DARKNESS_CHALLENGE_SCENE)
			return

	_check_pit_fall()
	
	_update_hud()

func _update_hud():
	var enemies_left = _get_alive_enemy_count()
	var is_test_room = scene_file_path == TEST_ROOM_SCENE
	var is_boss_room = not is_test_room and Game.is_boss_floor()
	floor_value_label.text = "T%s" % Game.current_floor if is_test_room else "%02d" % Game.current_floor
	enemies_value_label.text = str(enemies_left)
	gold_value_label.text = str(Game.gold)
	if player == null or not is_instance_valid(player):
		state_label.text = "Run failed"
		room_status_label.text = "The prison took you. Press Esc to retreat."
		hint_label.text = "Esc retreat to menu"
		return
	hint_label.text = _get_hint_text(is_test_room, is_boss_room, enemies_left)
	
	if is_test_room:
		if enemies_left > 0:
			state_label.text = "Antechamber contested"
			room_status_label.text = "Defeat the guard to reopen the descent gate"
		else:
			state_label.text = "Descent gate open"
			room_status_label.text = "Press E at the blue gate to descend"
		return

	_grant_room_reward_if_ready()

	if boss_intro_active:
		state_label.text = "The warden speaks"
		room_status_label.text = "Boss encounter begins after the warning"
		return

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
	if scene_file_path == Game.get_floor_scene_path(1) and player_in_darkness_switch and _can_activate_darkness_switch():
		return "E activate the hidden switch"
	if scene_file_path == Game.get_floor_scene_path(1) and player_in_darkness_door and darkness_door_open:
		return "E enter the room of complete darkness"
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
	if Game.is_secret_route_active() and scene_file_path == Game.get_floor_scene_path(1) and Game.get_secret_step() == 0:
		_go_to_next_floor_from_secret_exit()
		return
	if Game.is_boss_floor():
		if Game.is_secret_route_active() and Game.get_secret_step() == 1:
			_go_to_secret_boss_from_exit()
			return
		Game.prepare_boss_rewards()
		get_tree().change_scene_to_file(Game.BOSS_REWARD_SCENE)
		return
	Game.next_floor()
	get_tree().change_scene_to_file(Game.get_floor_scene_path())

func _check_pit_fall():
	if secret_triggered or player == null or not is_instance_valid(player):
		return
	if player.global_position.y < PIT_DEATH_Y:
		return
	secret_triggered = true
	_kill_player_in_pit()

func _go_to_next_floor_from_secret_exit():
	Game.set_secret_step(1)
	await _show_secret_flash()
	Game.next_floor()
	get_tree().change_scene_to_file(Game.get_floor_scene_path())

func _go_to_secret_boss_from_exit():
	Game.set_secret_step(2)
	get_tree().change_scene_to_file(Game.SECRET_BOSS_SCENE)

func _kill_player_in_pit():
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
	var tree: SceneTree = get_tree()
	if tree == null:
		return 0
	var count = 0
	for enemy in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count

func _setup_darkness_gate():
	if scene_file_path != Game.get_floor_scene_path(1):
		return
	if darkness_switch_visual != null:
		darkness_switch_visual.visible = true
	if darkness_switch != null:
		darkness_switch.visible = true
		darkness_switch.monitoring = true
		darkness_switch.monitorable = true
		darkness_switch.body_entered.connect(_on_darkness_switch_body_entered)
		darkness_switch.body_exited.connect(_on_darkness_switch_body_exited)
	if darkness_door_visual != null:
		darkness_door_visual.visible = false
	if darkness_door != null:
		darkness_door.visible = true
		darkness_door.monitoring = false
		darkness_door.monitorable = false
		darkness_door.body_entered.connect(_on_darkness_door_body_entered)
		darkness_door.body_exited.connect(_on_darkness_door_body_exited)

func _setup_boss_intro():
	if not Game.is_boss_floor() or scene_file_path == TEST_ROOM_SCENE:
		_hide_boss_dialog()
		return
	if boss_intro_done:
		return
	boss_intro_active = true
	_set_boss_enemies_enabled(false)
	_run_boss_intro()

func _run_boss_intro():
	if boss_dialog_panel != null:
		boss_dialog_panel.visible = true
	for line in BOSS_INTRO_LINES:
		if boss_dialog_label != null:
			boss_dialog_label.text = line
		await get_tree().create_timer(1.45).timeout
	_hide_boss_dialog()
	boss_intro_active = false
	boss_intro_done = true
	_set_boss_enemies_enabled(true)
	_update_hud()

func _hide_boss_dialog():
	if boss_dialog_panel != null:
		boss_dialog_panel.visible = false

func _set_boss_enemies_enabled(enabled: bool):
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.is_boss:
			enemy.movement_locked = not enabled
			enemy.velocity = Vector2.ZERO

func _can_activate_darkness_switch() -> bool:
	return not darkness_door_open and _get_alive_enemy_count() == 0

func _activate_darkness_switch():
	darkness_door_open = true
	if darkness_switch_visual != null:
		darkness_switch_visual.color = Color(0.55, 0.28, 1, 0.92)
	if darkness_door != null:
		darkness_door.visible = true
		darkness_door.monitoring = true
		darkness_door.monitorable = true
	if darkness_door_visual != null:
		darkness_door_visual.visible = true
	if secret_flash_label != null:
		secret_flash_label.text = "A door opens into absolute dark."
		secret_flash_label.visible = true

func _on_darkness_switch_body_entered(body: Node):
	if body == player:
		player_in_darkness_switch = true
		_update_hud()

func _on_darkness_switch_body_exited(body: Node):
	if body == player:
		player_in_darkness_switch = false
		_update_hud()

func _on_darkness_door_body_entered(body: Node):
	if body == player:
		player_in_darkness_door = true
		_update_hud()

func _on_darkness_door_body_exited(body: Node):
	if body == player:
		player_in_darkness_door = false
		_update_hud()
