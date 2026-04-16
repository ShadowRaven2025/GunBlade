class_name Enemy
extends CharacterBody2D

signal died
signal took_damage(amount: int)

@export var max_health: int = 30
@export var damage: int = 10
@export var speed: float = 90.0
@export var follow_range: float = 340.0
@export var attack_range: float = 48.0
@export var gravity: float = 980.0
@export var attack_cooldown: float = 1.0
@export var use_ai: bool = true
@export var respawn_on_death: bool = false
@export var respawn_delay: float = 1.5
@export var knockback_recovery: float = 1800.0
@export var is_boss: bool = false
@export var boss_phase_two_threshold: float = 0.45
@export var boss_phase_two_speed_bonus: float = 42.0
@export var boss_phase_two_damage_bonus: int = 8
@export var boss_leap_speed: float = 320.0
@export var boss_leap_vertical: float = -320.0
@export var boss_leap_cooldown: float = 2.6
@export var boss_leap_duration: float = 0.5

var current_health: int
var can_attack: bool = true
var idle_texture: Texture2D
var run_texture: Texture2D
var idle_frame_count: int = 8
var run_frame_count: int = 6
var current_frame: int = 0
var current_frame_count: int = 8
var anim_timer: float = 0.0
var anim_speed: float = 0.16
var current_animation: String = "idle"
var target_player: Player
var facing_direction: float = -1.0
var spawn_position: Vector2
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var boss_leap_ready: bool = true
var boss_leap_time_left: float = 0.0
var boss_phase_two_active: bool = false
var base_speed: float = 0.0
var base_damage: int = 0
var base_modulate: Color = Color(1, 1, 1, 1)
var base_boss_leap_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("enemies")
	spawn_position = global_position
	current_health = max_health
	base_speed = speed
	base_damage = damage
	base_modulate = modulate
	base_boss_leap_cooldown = boss_leap_cooldown
	idle_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Purple Units/Pawn/Pawn_Idle.png")
	run_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Purple Units/Pawn/Pawn_Run.png")
	sprite.texture = idle_texture
	sprite.hframes = idle_frame_count
	sprite.vframes = 1
	sprite.frame = 0
	current_frame_count = idle_frame_count
	_update_health_bar()

func _physics_process(delta):
	if not use_ai:
		_physics_process_dummy(delta)
		return
	
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if knockback_time_left > 0.0:
		_apply_knockback_motion(delta)
		move_and_slide()
		_flip_sprite()
		_set_animation("idle")
		_advance_animation(delta)
		return

	if boss_leap_time_left > 0.0:
		boss_leap_time_left = max(boss_leap_time_left - delta, 0.0)
		move_and_slide()
		_flip_sprite()
		_set_animation("run")
		_advance_animation(delta)
		return
	
	var move_direction := 0.0
	if is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		var horizontal_distance = absf(to_player.x)
		var vertical_distance = absf(to_player.y)
		if is_boss and _can_start_boss_leap(horizontal_distance, vertical_distance):
			_start_boss_leap(sign(to_player.x))
			move_and_slide()
			_flip_sprite()
			_set_animation("run")
			_advance_animation(delta)
			return
		if horizontal_distance <= follow_range and vertical_distance <= 96.0:
			if horizontal_distance > attack_range:
				move_direction = sign(to_player.x)
				velocity.x = move_direction * speed
			else:
				velocity.x = 0.0
				if can_attack:
					attack(target_player)
		else:
			velocity.x = 0.0
	else:
		velocity.x = 0.0
	
	if move_direction != 0.0:
		facing_direction = move_direction
	
	move_and_slide()
	_flip_sprite()
	_set_animation("run" if absf(velocity.x) > 1.0 else "idle")
	_advance_animation(delta)

func _physics_process_dummy(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	if knockback_time_left > 0.0:
		_apply_knockback_motion(delta)
	else:
		velocity.x = 0.0
	move_and_slide()
	_set_animation("idle")
	_advance_animation(delta)

func _advance_animation(delta):
	anim_timer += delta
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		current_frame = (current_frame + 1) % current_frame_count
		sprite.frame = current_frame

func _apply_knockback_motion(delta):
	knockback_time_left = max(knockback_time_left - delta, 0.0)
	velocity.x = knockback_velocity.x
	if knockback_velocity.y < 0.0:
		velocity.y = knockback_velocity.y
	knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, knockback_recovery * delta)
	knockback_velocity.y = move_toward(knockback_velocity.y, 0.0, knockback_recovery * delta)

func attack(player: Player):
	can_attack = false
	player.take_damage(damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _set_animation(animation_name: String):
	if current_animation == animation_name:
		return
	current_animation = animation_name
	current_frame = 0
	if animation_name == "run":
		current_frame_count = run_frame_count
		sprite.texture = run_texture
		sprite.hframes = run_frame_count
	else:
		current_frame_count = idle_frame_count
		sprite.texture = idle_texture
		sprite.hframes = idle_frame_count
	sprite.frame = current_frame

func _flip_sprite():
	sprite.flip_h = facing_direction > 0.0

func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health

func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	took_damage.emit(amount)
	_update_health_bar()
	if is_boss:
		_try_activate_boss_phase_two()
	if current_health <= 0:
		die()

func die():
	died.emit()
	if respawn_on_death:
		_respawn_after_delay()
		return
	collision_shape.disabled = true
	queue_free()

func apply_knockback(force: Vector2, duration: float = 0.18):
	knockback_velocity = force
	knockback_time_left = duration
	if force.x != 0.0:
		facing_direction = sign(force.x)

func _can_start_boss_leap(horizontal_distance: float, vertical_distance: float) -> bool:
	return boss_leap_ready and is_on_floor() and horizontal_distance >= 120.0 and horizontal_distance <= 380.0 and vertical_distance <= 120.0

func _start_boss_leap(direction: float):
	var leap_direction := direction
	if leap_direction == 0.0:
		leap_direction = facing_direction
	if leap_direction == 0.0:
		leap_direction = -1.0
	facing_direction = leap_direction
	velocity.x = boss_leap_speed * leap_direction
	velocity.y = boss_leap_vertical
	boss_leap_time_left = boss_leap_duration
	boss_leap_ready = false
	_call_reset_boss_leap()

func _call_reset_boss_leap():
	await get_tree().create_timer(boss_leap_cooldown).timeout
	boss_leap_ready = true

func _try_activate_boss_phase_two():
	if boss_phase_two_active:
		return
	if current_health > int(max_health * boss_phase_two_threshold):
		return
	boss_phase_two_active = true
	speed = base_speed + boss_phase_two_speed_bonus
	damage = base_damage + boss_phase_two_damage_bonus
	boss_leap_cooldown = max(boss_leap_cooldown - 0.8, 1.2)
	modulate = base_modulate.lerp(Color(1, 0.25, 0.2, 1), 0.45)

func _respawn_after_delay():
	set_physics_process(false)
	visible = false
	collision_shape.disabled = true
	await get_tree().create_timer(respawn_delay).timeout
	global_position = spawn_position
	current_health = max_health
	can_attack = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_time_left = 0.0
	boss_leap_time_left = 0.0
	boss_leap_ready = true
	boss_phase_two_active = false
	speed = base_speed
	damage = base_damage
	boss_leap_cooldown = base_boss_leap_cooldown
	modulate = base_modulate
	current_frame = 0
	current_animation = "idle"
	sprite.texture = idle_texture
	sprite.hframes = idle_frame_count
	sprite.frame = 0
	_update_health_bar()
	collision_shape.disabled = false
	visible = true
	set_physics_process(true)
