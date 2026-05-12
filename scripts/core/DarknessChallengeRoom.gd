extends Control

const GAME_OVER_SCENE = "res://scenes/menus/GameOver.tscn"
const MAIN_MENU_SCENE = "res://scenes/menus/MainMenu.tscn"

const DIRECTIONS: Array[String] = ["up", "down", "left", "right"]

@export var warning_time: float = 1.1
@export var attack_interval: float = 1.45
@export var intuition_attack_after: int = 27

var shield_direction: String = "up"
var attack_count: int = 0
var active_attack_direction: String = ""
var resolving_attack: bool = false
var challenge_over: bool = false

@onready var top_warning: ColorRect = $TopWarning
@onready var bottom_warning: ColorRect = $BottomWarning
@onready var left_warning: ColorRect = $LeftWarning
@onready var right_warning: ColorRect = $RightWarning
@onready var shield_label: Label = $CenterPanel/VBox/ShieldLabel
@onready var counter_label: Label = $CenterPanel/VBox/CounterLabel
@onready var message_label: Label = $CenterPanel/VBox/MessageLabel

func _ready():
	_clear_warnings()
	_update_shield_label()
	_start_next_attack()

func _process(_delta: float):
	if challenge_over:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return
	_update_shield_direction()

func _update_shield_direction():
	var new_direction: String = shield_direction
	if Input.is_key_pressed(KEY_W):
		new_direction = "up"
	elif Input.is_key_pressed(KEY_S):
		new_direction = "down"
	elif Input.is_key_pressed(KEY_A):
		new_direction = "left"
	elif Input.is_key_pressed(KEY_D):
		new_direction = "right"
	if new_direction != shield_direction:
		shield_direction = new_direction
		_update_shield_label()

func _start_next_attack():
	if challenge_over:
		return
	if attack_count >= intuition_attack_after:
		_start_intuition_attack()
		return
	attack_count += 1
	active_attack_direction = DIRECTIONS[randi_range(0, DIRECTIONS.size() - 1)]
	resolving_attack = true
	message_label.text = "Listen to the dark."
	counter_label.text = "Attack %d / %d" % [attack_count, intuition_attack_after]
	_show_warning(active_attack_direction, Color(1, 1, 1, 0.78))
	await get_tree().create_timer(warning_time).timeout
	_resolve_directional_attack()

func _resolve_directional_attack():
	if challenge_over:
		return
	_clear_warnings()
	if shield_direction != active_attack_direction:
		_fail_challenge()
		return
	message_label.text = "Blocked."
	resolving_attack = false
	await get_tree().create_timer(attack_interval - warning_time).timeout
	_start_next_attack()

func _start_intuition_attack():
	challenge_over = true
	message_label.text = "Intuition attack. No warning is true."
	counter_label.text = "FINAL"
	_flash_all_edges(Color(1, 0, 0, 0.9))
	await get_tree().create_timer(1.1).timeout
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func _fail_challenge():
	challenge_over = true
	message_label.text = "Wrong shield."
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func _update_shield_label():
	shield_label.text = "Shield: %s" % shield_direction.to_upper()

func _show_warning(direction: String, color: Color):
	_clear_warnings()
	_get_warning_rect(direction).color = color

func _flash_all_edges(color: Color):
	top_warning.color = color
	bottom_warning.color = color
	left_warning.color = color
	right_warning.color = color

func _clear_warnings():
	top_warning.color = Color(1, 1, 1, 0)
	bottom_warning.color = Color(1, 1, 1, 0)
	left_warning.color = Color(1, 1, 1, 0)
	right_warning.color = Color(1, 1, 1, 0)

func _get_warning_rect(direction: String) -> ColorRect:
	match direction:
		"up":
			return top_warning
		"down":
			return bottom_warning
		"left":
			return left_warning
		_:
			return right_warning
