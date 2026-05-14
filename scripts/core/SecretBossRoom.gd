extends Node2D

const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"
const GAME_OVER_SCENE = "res://scenes/menus/GameOver.tscn"
const DARK_KNIGHT_BOSS_SCENE = preload("res://scenes/game/characters/DarkKnightBoss.tscn")
const PRIEST_INTRO_LINES := [
	"Secret Priest: You heard the rite beneath the prison.",
	"Hero: I came for the truth behind it.",
	"Secret Priest: Then survive the violet answer."
]
const DARK_KNIGHT_INTRO_LINES := [
	"Dark Knight: The dark remembers every oath.",
	"Hero: Then remember this blade.",
	"Dark Knight: Step forward, prisoner."
]

@onready var player: Player = $Player
@onready var boss = $SecretBoss
@onready var room_status_label: Label = $CanvasLayer/HUD/VBox/TopRow/RoomStatus
@onready var floor_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/FloorValue
@onready var enemies_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/EnemiesValue
@onready var gold_value_label: Label = $CanvasLayer/HUD/VBox/StatsRow/GoldValue
@onready var state_label: Label = $CanvasLayer/HUD/VBox/StatePanel/StateLabel
@onready var hint_label: Label = $CanvasLayer/HUD/VBox/Hint
@onready var message_label: Label = $CanvasLayer/SecretMessage
@onready var boss_name_label: Label = $CanvasLayer/BossHealthPanel/VBox/BossName
@onready var boss_health_bar: ProgressBar = $CanvasLayer/BossHealthPanel/VBox/BossHealthBar
@onready var boss_dialog_panel: PanelContainer = $CanvasLayer/BossDialogPanel
@onready var boss_dialog_label: Label = $CanvasLayer/BossDialogPanel/VBox/DialogLabel

var reward_given: bool = false
var changing_scene: bool = false
var boss_intro_active: bool = false
var boss_intro_done: bool = false

func _ready():
	_setup_selected_secret_boss()
	_apply_selected_character()
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	boss.defeated.connect(_on_secret_boss_defeated)
	_setup_boss_intro()
	_update_hud()

func _setup_selected_secret_boss():
	if Game.get_selected_secret_boss() != "dark_knight":
		return
	var old_position: Vector2 = boss.global_position
	boss.queue_free()
	boss = DARK_KNIGHT_BOSS_SCENE.instantiate()
	add_child(boss)
	boss.global_position = old_position

func register_enemy(enemy):
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

func _process(_delta):
	if changing_scene or get_tree() == null:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		changing_scene = true
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	if boss_intro_active:
		return
	_update_hud()
	_update_boss_health_bar()

func _apply_selected_character():
	var config = Game.get_selected_character_config()
	player.max_health = config.get("max_health", player.max_health)
	player.current_health = player.max_health
	player.speed = config.get("speed", player.speed)
	player.jump_velocity = config.get("jump_velocity", player.jump_velocity)
	player.attack_damage = config.get("attack_damage", player.attack_damage)
	player.attack_range = config.get("attack_range", player.attack_range)
	player.attack_hit_radius = config.get("attack_hit_radius", player.attack_hit_radius)
	player.attack_cooldown = config.get("attack_cooldown", player.attack_cooldown)
	player.attack_anim_speed = config.get("attack_anim_speed", player.attack_anim_speed)
	player.kick_attack_type = config.get("kick_attack_type", "melee")
	player.kick_damage = config.get("kick_damage", player.kick_damage)
	player.kick_range = config.get("kick_range", player.kick_range)
	player.kick_hit_radius = config.get("kick_hit_radius", player.kick_hit_radius)
	player.kick_cooldown = config.get("kick_cooldown", player.kick_cooldown)
	player.kick_hit_frame = config.get("kick_hit_frame", player.kick_hit_frame)
	player.kick_knockback_force = config.get("kick_knockback_force", player.kick_knockback_force)
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
		if boss_intro_active:
			state_label.text = "The hidden boss speaks"
			room_status_label.text = "The duel begins after the warning"
			return
		state_label.text = "Hidden boss"
		if Game.get_selected_secret_boss() == "dark_knight":
			room_status_label.text = "Survive the dark knight"
			hint_label.text = "Black knives home in  |  Jump before the arena slash"
		else:
			room_status_label.text = "Survive the violet priest"
			hint_label.text = "Cards home in  |  Scythes fall  |  Bring him to 1%"
	_update_boss_health_bar()

func _update_boss_health_bar():
	if boss_health_bar == null or boss_name_label == null:
		return
	if boss == null or not is_instance_valid(boss) or reward_given:
		boss_health_bar.visible = false
		boss_name_label.visible = false
		return
	boss_health_bar.visible = true
	boss_name_label.visible = true
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.current_health
	boss_name_label.text = "Dark Knight" if Game.get_selected_secret_boss() == "dark_knight" else "Secret Priest"

func _setup_boss_intro():
	if boss_intro_done:
		return
	boss_intro_active = true
	_set_boss_enabled(false)
	_run_boss_intro()

func _run_boss_intro():
	var lines := DARK_KNIGHT_INTRO_LINES if Game.get_selected_secret_boss() == "dark_knight" else PRIEST_INTRO_LINES
	boss_dialog_panel.visible = true
	for line in lines:
		boss_dialog_label.text = line
		await get_tree().create_timer(1.45).timeout
	boss_dialog_panel.visible = false
	boss_intro_active = false
	boss_intro_done = true
	_set_boss_enabled(true)
	_update_hud()

func _set_boss_enabled(enabled: bool):
	if boss == null or not is_instance_valid(boss):
		return
	boss.set_physics_process(enabled)
	boss.set_process(enabled)
	boss.velocity = Vector2.ZERO

func _on_secret_boss_defeated():
	if reward_given:
		return
	reward_given = true
	Game.mark_secret_boss_defeated()
	if Game.get_selected_secret_boss() != "dark_knight":
		Game.unlock_secret_priest()
	Game.set_secret_step(3)
	message_label.text = "You won. The dark blade is silent." if Game.get_selected_secret_boss() == "dark_knight" else "You won. Carry my violet rite."
	message_label.visible = true
	_update_hud()

func _on_enemy_died():
	_update_hud()

func _on_player_died():
	if changing_scene:
		return
	changing_scene = true
	state_label.text = "The secret rite failed"
	room_status_label.text = "Press Esc to retreat."
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func _get_alive_enemy_count() -> int:
	var tree: SceneTree = get_tree()
	if tree == null:
		return 0
	var count := 0
	for enemy in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			count += 1
	return count
