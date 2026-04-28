extends CharacterBody2D

signal defeated
signal died

const CARD_SCENE = preload("res://scenes/game/projectiles/SecretCard.tscn")
const SCYTHE_SCENE = preload("res://scenes/game/projectiles/SecretScythe.tscn")

@export var max_health: int = 320
@export var gravity: float = 980.0

var current_health: int = 0
var attack_timer: float = 1.2
var pattern_timer: float = 0.0
var phase_two: bool = false
var final_phase: bool = false
var defeated_started: bool = false
var target: Player = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("enemies")
	current_health = max_health
	sprite.texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Monk/Idle.png")
	sprite.hframes = 6
	sprite.vframes = 1
	sprite.modulate = Color(0.68, 0.25, 1, 1)
	_update_health_bar()
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
	if final_phase:
		_update_final_phase(delta)
		return
	attack_timer = max(attack_timer - delta, 0.0)
	if attack_timer == 0.0:
		_cast_normal_pattern()
		attack_timer = 0.82 if phase_two else 1.25

func take_damage(amount: int):
	if final_phase or defeated_started:
		return
	current_health = max(current_health - amount, maxi(1, int(max_health * 0.01)))
	_update_health_bar()
	if not phase_two and current_health <= int(max_health * 0.5):
		phase_two = true
		sprite.modulate = Color(0.9, 0.18, 1, 1)
	if current_health <= maxi(1, int(max_health * 0.01)):
		_begin_final_phase()

func _cast_normal_pattern():
	_spawn_card_fan()
	if phase_two:
		_spawn_scythe_arc()

func _spawn_card_fan():
	var parent := get_parent()
	if parent == null:
		return
	var base_direction := Vector2.LEFT
	if is_instance_valid(target):
		base_direction = (target.global_position - global_position).normalized()
	for index in range(5):
		var card = CARD_SCENE.instantiate()
		parent.add_child(card)
		card.global_position = global_position + Vector2(0, -18)
		var angle_offset := deg_to_rad(-28.0 + index * 14.0)
		var direction := base_direction.rotated(angle_offset).normalized()
		var homing := 1.6 if index % 2 == 0 else 0.0
		card.setup(direction * 290.0, 9 if not phase_two else 12, homing)

func _spawn_scythe_arc():
	var parent := get_parent()
	if parent == null or not is_instance_valid(target):
		return
	var scythe = SCYTHE_SCENE.instantiate()
	parent.add_child(scythe)
	scythe.global_position = global_position + Vector2(0, -26)
	var direction := (target.global_position - scythe.global_position).normalized()
	scythe.setup(direction * 360.0, 16)

func _begin_final_phase():
	final_phase = true
	attack_timer = 0.0
	pattern_timer = 0.0
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if health_bar != null:
		health_bar.visible = false
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
			attack_timer = 0.42
		return
	_end_secret_fight()

func _spawn_falling_scythe_pattern():
	var parent := get_parent()
	if parent == null:
		return
	var wave := int(pattern_timer / 0.42)
	for index in range(4):
		var scythe = SCYTHE_SCENE.instantiate()
		parent.add_child(scythe)
		var x := 180.0 + fmod(float(wave * 137 + index * 260), 920.0)
		scythe.global_position = Vector2(x, -40.0 - index * 36.0)
		scythe.setup(Vector2(0.0, 390.0), 18)

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
