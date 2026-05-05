extends CharacterBody2D

signal defeated
signal died

const CARD_SCENE = preload("res://scenes/game/projectiles/SecretCard.tscn")
const SCYTHE_SCENE = preload("res://scenes/game/projectiles/SecretScythe.tscn")

@export var max_health: int = 520
@export var gravity: float = 980.0
@export var max_fatigue: float = 100.0
@export var fatigue_from_hit: float = 9.0
@export var fatigue_from_attack: float = 4.0
@export var vulnerable_fatigue_drain_per_second: float = 5.0
@export var teleport_min_x: float = 160.0
@export var teleport_max_x: float = 1120.0
@export var teleport_ground_y: float = 598.0
@export var teleport_min_distance: float = 72.0
@export var teleport_iframe_duration: float = 0.45
@export var phase_transition_iframe_duration: float = 1.35
@export var final_phase_iframe_duration: float = 1.0
@export var field_attack_min_x: float = 170.0
@export var field_attack_max_x: float = 1110.0
@export var field_attack_min_y: float = 165.0
@export var field_attack_max_y: float = 430.0

var current_health: int = 0
var attack_timer: float = 1.7
var pattern_timer: float = 0.0
var phase_two: bool = false
var final_phase: bool = false
var defeated_started: bool = false
var fatigue: float = 0.0
var is_vulnerable: bool = false
var iframe_time_left: float = 0.0
var attack_pattern_index: int = 0
var target: Player = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var fatigue_bar: ProgressBar = $FatigueBar

func _ready():
	add_to_group("enemies")
	current_health = max_health
	sprite.texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png")
	sprite.hframes = 6
	sprite.vframes = 1
	sprite.modulate = Color(0.68, 0.25, 1, 1)
	_update_health_bar()
	_update_fatigue_bar()
	if get_parent() != null and get_parent().has_method("register_enemy"):
		get_parent().register_enemy(self)

func _physics_process(delta: float):
	if defeated_started:
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_update_iframes(delta)
	if final_phase:
		_update_final_phase(delta)
		return
	_update_vulnerable_fatigue(delta)
	attack_timer = max(attack_timer - delta, 0.0)
	if attack_timer == 0.0:
		_cast_normal_pattern()
		_add_fatigue(fatigue_from_attack)
		attack_timer = 1.35 if phase_two else 1.75

func take_damage(amount: int):
	if final_phase or defeated_started:
		return
	if iframe_time_left > 0.0:
		return
	if not is_vulnerable:
		_add_fatigue(fatigue_from_hit)
		if not is_vulnerable:
			_teleport_away()
		return
	current_health = max(current_health - amount, maxi(1, int(max_health * 0.01)))
	_update_health_bar()
	if not phase_two and current_health <= int(max_health * 0.5):
		phase_two = true
		_start_iframes(phase_transition_iframe_duration)
		_update_phase_visual()
	if current_health <= maxi(1, int(max_health * 0.01)):
		_begin_final_phase()

func apply_knockback(_force: Vector2, _duration: float = 0.18):
	pass

func _add_fatigue(amount: float):
	if final_phase or defeated_started or is_vulnerable:
		return
	fatigue = clampf(fatigue + amount, 0.0, max_fatigue)
	if fatigue >= max_fatigue:
		is_vulnerable = true
		fatigue = max_fatigue
		velocity = Vector2.ZERO
		sprite.modulate = Color(0.55, 0.9, 1.0, 1.0)
	_update_fatigue_bar()

func _update_vulnerable_fatigue(delta: float):
	if not is_vulnerable:
		return
	fatigue = maxf(fatigue - vulnerable_fatigue_drain_per_second * delta, 0.0)
	if fatigue == 0.0:
		is_vulnerable = false
		_update_phase_visual()
	_update_fatigue_bar()

func _teleport_away():
	var destination: Vector2 = _get_teleport_destination()
	global_position = destination
	velocity = Vector2.ZERO
	attack_timer = maxf(attack_timer, 0.4)
	_start_iframes(teleport_iframe_duration)
	sprite.modulate = Color(0.95, 0.55, 1.0, 0.78)
	call_deferred("_update_phase_visual")

func _get_teleport_destination() -> Vector2:
	var destination_x: float = clampf(global_position.x + randf_range(-teleport_min_distance, teleport_min_distance), teleport_min_x, teleport_max_x)
	if is_instance_valid(target):
		var away_direction: float = sign(global_position.x - target.global_position.x)
		if away_direction == 0.0:
			away_direction = -1.0 if target.global_position.x > (teleport_min_x + teleport_max_x) * 0.5 else 1.0
		destination_x = clampf(global_position.x + away_direction * teleport_min_distance, teleport_min_x, teleport_max_x)
	return Vector2(destination_x, teleport_ground_y)

func _update_phase_visual():
	if final_phase or defeated_started or is_vulnerable or iframe_time_left > 0.0:
		return
	if phase_two:
		sprite.modulate = Color(0.9, 0.18, 1, 1)
	else:
		sprite.modulate = Color(0.68, 0.25, 1, 1)

func _start_iframes(duration: float):
	iframe_time_left = maxf(iframe_time_left, duration)
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.58)

func _update_iframes(delta: float):
	if iframe_time_left <= 0.0:
		return
	iframe_time_left = maxf(iframe_time_left - delta, 0.0)
	if iframe_time_left == 0.0:
		if is_vulnerable:
			sprite.modulate = Color(0.55, 0.9, 1.0, 1.0)
		else:
			_update_phase_visual()

func _cast_normal_pattern():
	var pattern_count: int = 3 if phase_two else 2
	var pattern: int = attack_pattern_index % pattern_count
	attack_pattern_index += 1
	match pattern:
		0:
			_spawn_suit_fan()
		1:
			_spawn_suit_rain()
		2:
			_spawn_scythe_arc()
			_spawn_suit_crossfire()

func _spawn_suit_fan():
	var parent: Node = get_parent()
	if parent == null:
		return
	for index in range(3):
		var card = CARD_SCENE.instantiate()
		parent.add_child(card)
		card.global_position = _get_field_card_spawn_position(index)
		var base_direction: Vector2 = Vector2.DOWN
		if is_instance_valid(target):
			base_direction = (target.global_position - card.global_position).normalized()
		var angle_offset: float = deg_to_rad(-24.0 + index * 24.0)
		var direction: Vector2 = base_direction.rotated(angle_offset).normalized()
		var homing: float = 0.65 if index == 1 else 0.0
		card.setup(direction * 215.0, 7 if not phase_two else 9, homing)

func _spawn_suit_rain():
	var parent: Node = get_parent()
	if parent == null:
		return
	var suit_count: int = 4 if phase_two else 3
	for index in range(suit_count):
		var suit = CARD_SCENE.instantiate()
		parent.add_child(suit)
		var x: float = lerpf(field_attack_min_x, field_attack_max_x, float(index + 1) / float(suit_count + 1))
		if is_instance_valid(target):
			var center_offset: float = float(index) - (float(suit_count - 1) * 0.5)
			x = clampf(target.global_position.x + center_offset * 145.0 + randf_range(-45.0, 45.0), field_attack_min_x, field_attack_max_x)
		suit.global_position = Vector2(x, field_attack_min_y - 55.0)
		var drift: float = randf_range(-45.0, 45.0)
		suit.setup(Vector2(drift, 245.0 if phase_two else 215.0), 7 if not phase_two else 9, 0.0)

func _spawn_suit_crossfire():
	var parent: Node = get_parent()
	if parent == null:
		return
	var center_y: float = 250.0
	if is_instance_valid(target):
		center_y = clampf(target.global_position.y - 20.0, field_attack_min_y, field_attack_max_y)
	for side in [-1, 1]:
		for index in range(2):
			var suit = CARD_SCENE.instantiate()
			parent.add_child(suit)
			var spawn_x: float = field_attack_min_x if side > 0 else field_attack_max_x
			suit.global_position = Vector2(spawn_x, center_y + float(index * 54 - 27))
			var direction: Vector2 = Vector2(float(side), randf_range(-0.16, 0.16)).normalized()
			suit.setup(direction * 235.0, 9, 0.25)

func _get_field_card_spawn_position(index: int) -> Vector2:
	var x: float = lerpf(field_attack_min_x, field_attack_max_x, float(index + 1) / 4.0)
	var y: float = randf_range(field_attack_min_y, field_attack_max_y)
	if is_instance_valid(target):
		x = clampf(target.global_position.x + float(index - 1) * 190.0 + randf_range(-55.0, 55.0), field_attack_min_x, field_attack_max_x)
	return Vector2(x, y)

func _spawn_scythe_arc():
	var parent: Node = get_parent()
	if parent == null or not is_instance_valid(target):
		return
	var scythe = SCYTHE_SCENE.instantiate()
	parent.add_child(scythe)
	scythe.global_position = global_position + Vector2(0, -26)
	var direction: Vector2 = (target.global_position - scythe.global_position).normalized()
	scythe.setup(direction * 250.0, 12)

func _begin_final_phase():
	final_phase = true
	_start_iframes(final_phase_iframe_duration)
	attack_timer = 0.0
	pattern_timer = 0.0
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if health_bar != null:
		health_bar.visible = false
	if fatigue_bar != null:
		fatigue_bar.visible = false
	sprite.texture = load("res://assets/scythe.png")
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.scale = Vector2(0.16, 0.16)
	sprite.modulate = Color(0.86, 0.25, 1, 1)

func _update_final_phase(delta: float):
	pattern_timer += delta
	sprite.rotation += delta * 6.0
	if pattern_timer < 5.2:
		attack_timer = max(attack_timer - delta, 0.0)
		if attack_timer == 0.0:
			_spawn_falling_scythe_pattern()
			attack_timer = 0.68
		return
	_end_secret_fight()

func _spawn_falling_scythe_pattern():
	var parent: Node = get_parent()
	if parent == null:
		return
	var wave: int = int(pattern_timer / 0.42)
	for index in range(3):
		var scythe = SCYTHE_SCENE.instantiate()
		parent.add_child(scythe)
		var x: float = 180.0 + fmod(float(wave * 137 + index * 260), 920.0)
		scythe.global_position = Vector2(x, -40.0 - index * 36.0)
		scythe.setup_final_fall(Vector2(0.0, 285.0), 14)

func _end_secret_fight():
	if defeated_started:
		return
	defeated_started = true
	defeated.emit()
	queue_free()

func _update_health_bar():
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health

func _update_fatigue_bar():
	if fatigue_bar == null:
		return
	fatigue_bar.max_value = max_fatigue
	fatigue_bar.value = fatigue
