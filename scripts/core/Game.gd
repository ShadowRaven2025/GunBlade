extends Node

const MAX_FLOOR := 3
const BOSS_REWARD_SCENE := "res://scenes/menus/BossReward.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const GRAPHICS_QUALITY_FACTORS := {
	"low": 0.75,
	"medium": 1.0,
	"high": 1.25
}
const FLOOR_SCENES := {
	1: "res://scenes/game/levels/Dungeon.tscn",
	2: "res://scenes/game/levels/IronFoundry.tscn",
	3: "res://scenes/game/levels/WardenThrone.tscn"
}
const SECRET_BOSS_SCENE := "res://scenes/game/levels/SecretBossRoom.tscn"
const BOSS_RELICS := [
	{
		"id": "ember_crown",
		"title": "Ember Crown",
		"description": "+35 gold and stronger primary attacks"
	},
	{
		"id": "iron_oath",
		"title": "Iron Oath",
		"description": "+20 max health and heavier kicks"
	},
	{
		"id": "moon_seal",
		"title": "Moon Seal",
		"description": "Faster cooldowns and sharper jumps"
	},
	{
		"id": "rampart_spur",
		"title": "Rampart Spur",
		"description": "+20 gold and faster movement"
	},
	{
		"id": "forgeblood_token",
		"title": "Forgeblood Token",
		"description": "+25 gold and a wider melee sweep"
	}
]

var current_floor: int = 1
var gold: int = 0
var current_run_data: Dictionary = {}
var is_paused: bool = false
var selected_character: String = "warrior"
var settings: Dictionary = {
	"fullscreen": false,
	"graphics_quality": "medium"
}

const CHARACTER_CONFIGS := {
	"warrior": {
		"label": "Warrior",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png",
		"idle_frames": 8,
		"run_frames": 6,
		"attack_frames": 4,
		"attack_hit_frame": 2,
		"attack_type": "melee",
		"max_health": 120,
		"speed": 265.0,
		"jump_velocity": -475.0,
		"attack_damage": 16,
		"attack_range": 54.0
	},
	"archer": {
		"label": "Archer",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Shoot.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 8,
		"attack_hit_frame": 3,
		"attack_pose_frame": 3,
		"attack_type": "ranged",
		"max_health": 90,
		"speed": 295.0,
		"jump_velocity": -500.0,
		"attack_damage": 18,
		"attack_range": 72.0,
		"double_jump": true
	},
	"monk": {
		"label": "Monk",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Heal.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 11,
		"attack_hit_frame": 4,
		"attack_pose_frame": -1,
		"attack_type": "magic",
		"max_health": 100,
		"speed": 280.0,
		"jump_velocity": -490.0,
		"attack_damage": 13,
		"attack_range": 50.0,
		"max_mana": 120.0,
		"magic_mana_drain_per_second": 20.0,
		"magic_mana_regen_per_second": 14.0,
		"magic_bolt_damage": 8,
		"starfall_max_charge_time": 2.3,
		"starfall_min_mana_cost": 8.0,
		"starfall_max_mana_cost": 28.0,
		"starfall_base_damage": 14,
		"starfall_extra_damage": 18,
		"starfall_base_count": 5,
		"starfall_extra_count": 7
	},
	"secret_priest": {
		"label": "Secret Priest",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Heal.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 11,
		"attack_hit_frame": 4,
		"attack_pose_frame": -1,
		"attack_type": "magic",
		"max_health": 115,
		"speed": 292.0,
		"jump_velocity": -505.0,
		"attack_damage": 16,
		"attack_range": 58.0,
		"max_mana": 140.0,
		"magic_mana_drain_per_second": 16.0,
		"magic_mana_regen_per_second": 18.0,
		"magic_bolt_damage": 12,
		"starfall_max_charge_time": 1.9,
		"starfall_min_mana_cost": 6.0,
		"starfall_max_mana_cost": 24.0,
		"starfall_base_damage": 16,
		"starfall_extra_damage": 22,
		"starfall_base_count": 6,
		"starfall_extra_count": 8,
		"modulate": Color(0.72, 0.38, 1, 1)
	},
	"secret_boss": {
		"label": "Secret Boss",
		"idle": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png",
		"run": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Run.png",
		"attack": "res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Heal.png",
		"idle_frames": 6,
		"run_frames": 4,
		"attack_frames": 11,
		"attack_hit_frame": 4,
		"attack_pose_frame": -1,
		"attack_type": "magic",
		"max_health": 150,
		"speed": 275.0,
		"jump_velocity": -485.0,
		"attack_damage": 18,
		"attack_range": 64.0,
		"max_mana": 170.0,
		"magic_mana_drain_per_second": 14.0,
		"magic_mana_regen_per_second": 22.0,
		"magic_bolt_damage": 15,
		"starfall_max_charge_time": 1.7,
		"starfall_min_mana_cost": 5.0,
		"starfall_max_mana_cost": 22.0,
		"starfall_base_damage": 18,
		"starfall_extra_damage": 26,
		"starfall_base_count": 7,
		"starfall_extra_count": 9,
		"modulate": Color(0.86, 0.25, 1, 1),
		"visual_scale": Vector2(1.18, 1.18)
	}
}

var persistent_unlocks: Dictionary = {
	"secret_priest_unlocked": false
}

func _ready():
	load_settings()
	apply_display_settings()
	load_game()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		return
	settings["fullscreen"] = bool(config.get_value("display", "fullscreen", settings["fullscreen"]))
	var graphics_quality = str(config.get_value("display", "graphics_quality", settings["graphics_quality"]))
	if not GRAPHICS_QUALITY_FACTORS.has(graphics_quality):
		graphics_quality = "medium"
	settings["graphics_quality"] = graphics_quality

func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "fullscreen", settings["fullscreen"])
	config.set_value("display", "graphics_quality", settings["graphics_quality"])
	config.save(SETTINGS_PATH)

func apply_display_settings():
	var fullscreen_enabled = bool(settings.get("fullscreen", false))
	var window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(window_mode)
	var graphics_quality = str(settings.get("graphics_quality", "medium"))
	var scale_factor = GRAPHICS_QUALITY_FACTORS.get(graphics_quality, GRAPHICS_QUALITY_FACTORS["medium"])
	get_window().content_scale_factor = scale_factor

func set_fullscreen_enabled(enabled: bool):
	settings["fullscreen"] = enabled
	apply_display_settings()
	save_settings()

func is_fullscreen_enabled() -> bool:
	return bool(settings.get("fullscreen", false))

func set_graphics_quality(quality: String):
	if not GRAPHICS_QUALITY_FACTORS.has(quality):
		return
	settings["graphics_quality"] = quality
	apply_display_settings()
	save_settings()

func get_graphics_quality() -> String:
	return str(settings.get("graphics_quality", "medium"))

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

func new_game(secret_route: bool = false):
	var secret_priest_was_unlocked := is_secret_priest_unlocked()
	current_floor = 1
	gold = 0
	current_run_data = {
		"floor": 1,
		"character": selected_character,
		"gold": 0,
		"rooms_cleared": 0,
		"pending_boss_rewards": [],
		"runes": [],
		"curses": [],
		"relics": [],
		"enemies_killed": 0,
		"damage_dealt": 0,
		"items_collected": 0,
		"secret_route": secret_route,
		"secret_step": 0,
		"secret_priest_unlocked": secret_priest_was_unlocked
	}
	save_game()

func set_selected_character(character_id: String):
	if (character_id == "secret_priest" or character_id == "secret_boss") and not is_secret_priest_unlocked():
		return
	if CHARACTER_CONFIGS.has(character_id):
		selected_character = character_id
		current_run_data["character"] = character_id
		save_game()

func get_selected_character_config() -> Dictionary:
	return CHARACTER_CONFIGS.get(selected_character, CHARACTER_CONFIGS["warrior"])

func is_secret_route_active() -> bool:
	return bool(current_run_data.get("secret_route", false))

func get_secret_step() -> int:
	return int(current_run_data.get("secret_step", 0))

func set_secret_step(step: int):
	current_run_data["secret_step"] = step
	save_game()

func unlock_secret_priest():
	persistent_unlocks["secret_priest_unlocked"] = true
	current_run_data["secret_priest_unlocked"] = true
	save_game()

func is_secret_priest_unlocked() -> bool:
	return bool(persistent_unlocks.get("secret_priest_unlocked", false)) or bool(current_run_data.get("secret_priest_unlocked", false))

func next_floor():
	current_floor = mini(current_floor + 1, MAX_FLOOR)
	current_run_data["floor"] = current_floor
	save_game()

func get_floor_scene_path(floor_number: int = current_floor) -> String:
	var normalized_floor := clampi(floor_number, 1, MAX_FLOOR)
	return FLOOR_SCENES.get(normalized_floor, FLOOR_SCENES[1])

func is_boss_floor(floor_number: int = current_floor) -> bool:
	return floor_number >= MAX_FLOOR

func complete_run():
	current_run_data["last_completed_floor"] = MAX_FLOOR
	current_run_data["pending_boss_rewards"] = []
	current_floor = 1
	current_run_data["floor"] = current_floor
	save_game()

func add_gold(amount: int):
	gold += amount
	current_run_data["gold"] = gold
	save_game()

func record_enemy_kill(amount: int = 1):
	current_run_data["enemies_killed"] = int(current_run_data.get("enemies_killed", 0)) + amount
	save_game()

func record_room_clear():
	current_run_data["rooms_cleared"] = int(current_run_data.get("rooms_cleared", 0)) + 1
	save_game()

func prepare_boss_rewards():
	var options: Array = []
	var start_index: int = int(current_run_data.get("rooms_cleared", 0)) + gold + current_floor
	start_index = start_index % BOSS_RELICS.size()
	for i in range(3):
		var relic = BOSS_RELICS[(start_index + i) % BOSS_RELICS.size()].duplicate(true)
		options.append(relic)
	current_run_data["pending_boss_rewards"] = options
	save_game()

func get_pending_boss_rewards() -> Array:
	return current_run_data.get("pending_boss_rewards", [])

func claim_boss_reward(relic_id: String):
	var options: Array = get_pending_boss_rewards()
	for relic in options:
		if relic.get("id", "") != relic_id:
			continue
		var relics: Array = current_run_data.get("relics", [])
		relics.append(relic)
		current_run_data["relics"] = relics
		current_run_data["last_boss_reward"] = relic
		if relic_id == "ember_crown":
			add_gold(35)
		elif relic_id == "rampart_spur":
			add_gold(20)
		elif relic_id == "forgeblood_token":
			add_gold(25)
		break
	current_run_data["pending_boss_rewards"] = []
	save_game()

func get_relic_ids() -> Array[String]:
	var relic_ids: Array[String] = []
	for relic in current_run_data.get("relics", []):
		var relic_id := str(relic.get("id", ""))
		if relic_id != "":
			relic_ids.append(relic_id)
	return relic_ids

func get_player_relic_modifiers() -> Dictionary:
	var modifiers := {
		"bonus_health": 0,
		"bonus_damage": 0,
		"bonus_speed": 0.0,
		"bonus_jump": 0.0,
		"bonus_attack_range": 0.0,
		"bonus_kick_force": 0.0,
		"attack_cooldown_multiplier": 1.0,
		"kick_cooldown_multiplier": 1.0,
		"summary": []
	}
	for relic_id in get_relic_ids():
		match relic_id:
			"ember_crown":
				modifiers["bonus_damage"] += 5
				(modifiers["summary"] as Array).append("Ember Crown: +5 attack")
			"iron_oath":
				modifiers["bonus_health"] += 20
				modifiers["bonus_kick_force"] += 120.0
				(modifiers["summary"] as Array).append("Iron Oath: +20 HP, stronger kick")
			"moon_seal":
				modifiers["bonus_jump"] += -28.0
				modifiers["attack_cooldown_multiplier"] *= 0.9
				modifiers["kick_cooldown_multiplier"] *= 0.9
				(modifiers["summary"] as Array).append("Moon Seal: faster cooldowns")
			"rampart_spur":
				modifiers["bonus_speed"] += 24.0
				(modifiers["summary"] as Array).append("Rampart Spur: +24 speed")
			"forgeblood_token":
				modifiers["bonus_attack_range"] += 14.0
				(modifiers["summary"] as Array).append("Forgeblood Token: wider melee")
	return modifiers

func get_relic_summary_text() -> String:
	var summary: Array = get_player_relic_modifiers().get("summary", [])
	if summary.is_empty():
		return "No relic blessings yet"
	return " | ".join(summary)

func lose_gold():
	var lost = gold
	gold = 0
	current_run_data["gold"] = 0
	save_game()
	return lost

func save_game():
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	var json_string = JSON.stringify(current_run_data)
	save_file.store_line(json_string)
	save_file.close()

func load_game():
	if FileAccess.file_exists("user://savegame.dat"):
		var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var json_string = save_file.get_line()
		current_run_data = JSON.parse_string(json_string)
		current_floor = int(current_run_data.get("floor", 1))
		gold = int(current_run_data.get("gold", 0))
		selected_character = current_run_data.get("character", selected_character)
		persistent_unlocks["secret_priest_unlocked"] = bool(current_run_data.get("secret_priest_unlocked", false))
		save_file.close()

func game_over():
	lose_gold()
	current_run_data = {}
	save_game()
