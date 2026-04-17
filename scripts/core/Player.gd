class_name Player extends CharacterBody2D

signal died

const ARROW_SCENE = preload("res://scenes/game/projectiles/Arrow.tscn")
const MAGIC_BOLT_SCENE = preload("res://scenes/game/projectiles/MagicBolt.tscn")

@export var speed: float = 260.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 980.0
@export var max_health: int = 100
@export var attack_damage: int = 12
@export var attack_range: float = 48.0
@export var attack_hit_radius: float = 28.0
@export var attack_cooldown: float = 0.45
@export var attack_anim_speed: float = 0.12
@export var attack_hit_frame: int = 2
@export var kick_damage: int = 8
@export var kick_range: float = 34.0
@export var kick_hit_radius: float = 34.0
@export var kick_cooldown: float = 0.52
@export var kick_hit_frame: int = 1
@export var kick_knockback_force: float = 340.0
@export var ranged_backstep_speed: float = 340.0
@export var ranged_backstep_duration: float = 0.18
@export var max_mana: float = 100.0
@export var magic_shot_interval: float = 0.09
@export var magic_mana_drain_per_second: float = 24.0
@export var magic_mana_regen_per_second: float = 16.0
@export var magic_bolt_damage: int = 7

var current_health: int
var can_attack: bool = true
var is_attacking: bool = false
var facing_direction: float = 1.0
var current_frame: int = 0
var current_frame_count: int = 8
var current_animation: String = "idle"
var is_moving: bool = false
var anim_timer: float = 0.0
var run_frame_count: int = 6
var idle_frame_count: int = 8
var attack_frame_count: int = 4
var jump_frame_count: int = 6
var idle_texture: Texture2D
var run_texture: Texture2D
var attack_texture: Texture2D
var attack_type: String = "melee"
var attack_pose_frame: int = -1
var current_attack_mode: String = "primary"
var can_double_jump: bool = false
var jumps_remaining: int = 1
var backstep_time_left: float = 0.0
var backstep_direction: float = 0.0
var current_mana: float = 0.0
var magic_shot_time_left: float = 0.0
var is_channeling_magic: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar = get_node_or_null("ManaBar")

func _ready():
	add_to_group("player")
	current_health = max_health
	set_character_visuals(
		"res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png",
		"res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png",
		"res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png",
		8,
		6,
		4,
		2,
		-1,
		"melee"
	)
	_reset_jump_state()
	_update_health_bar()
	current_mana = max_mana
	_update_mana_bar()

func set_character_visuals(idle_path: String, run_path: String, attack_path: String, idle_frames: int = 8, run_frames: int = 6, attack_frames: int = 4, hit_frame: int = 2, pose_frame: int = -1, next_attack_type: String = "melee", enable_double_jump: bool = false):
	idle_texture = load(idle_path)
	run_texture = load(run_path)
	attack_texture = load(attack_path)
	idle_frame_count = idle_frames
	run_frame_count = run_frames
	jump_frame_count = run_frames
	attack_frame_count = attack_frames
	attack_hit_frame = hit_frame
	attack_pose_frame = pose_frame
	attack_type = next_attack_type
	can_double_jump = enable_double_jump
	if attack_type != "magic":
		is_channeling_magic = false
	sprite.texture = idle_texture
	sprite.hframes = idle_frame_count
	sprite.vframes = 1
	sprite.frame = 0
	current_frame_count = idle_frame_count
	current_animation = "idle"
	current_mana = max_mana
	_reset_jump_state()
	_update_mana_bar()

func _physics_process(delta):
	var input_axis = Input.get_axis("move_left", "move_right")
	is_moving = absf(input_axis) > 0.01
	if is_moving:
		facing_direction = sign(input_axis)

	if is_on_floor():
		_reset_jump_state()
	
	if Input.is_action_just_pressed("jump") and not is_attacking:
		if is_on_floor():
			velocity.y = jump_velocity
			jumps_remaining = max(jumps_remaining - 1, 0)
		elif can_double_jump and jumps_remaining > 0:
			velocity.y = jump_velocity
			jumps_remaining -= 1
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	_update_magic_attack(delta)

	if backstep_time_left > 0.0:
		backstep_time_left = max(backstep_time_left - delta, 0.0)
		velocity.x = backstep_direction * ranged_backstep_speed
	elif is_attacking or is_channeling_magic:
		velocity.x = move_toward(velocity.x, 0.0, speed * 0.15)
	else:
		velocity.x = input_axis * speed
	
	_flip_sprite()
	move_and_slide()
	_animate(delta)
	
	if Input.is_action_just_pressed("kick") and can_attack and not is_channeling_magic:
		attack("kick")
	elif attack_type != "magic" and Input.is_action_just_pressed("attack") and can_attack:
		attack("primary")

func _update_magic_attack(delta):
	if attack_type != "magic":
		return
	if is_attacking:
		is_channeling_magic = false
		magic_shot_time_left = 0.0
		_regen_mana(delta)
		_update_mana_bar()
		return
	var wants_magic = Input.is_action_pressed("attack") and current_mana > 0.0
	if wants_magic:
		is_channeling_magic = true
		magic_shot_time_left = max(magic_shot_time_left - delta, 0.0)
		current_mana = max(current_mana - magic_mana_drain_per_second * delta, 0.0)
		if magic_shot_time_left == 0.0 and current_mana > 0.0:
			_fire_magic_bolt()
			magic_shot_time_left = magic_shot_interval
	else:
		is_channeling_magic = false
		magic_shot_time_left = 0.0
		_regen_mana(delta)
	if current_mana <= 0.0:
		is_channeling_magic = false
	_update_mana_bar()

func _regen_mana(delta):
	current_mana = min(current_mana + magic_mana_regen_per_second * delta, max_mana)

func _animate(delta):
	anim_timer += delta
	var current_anim_speed = attack_anim_speed if is_attacking else 0.14
	if anim_timer >= current_anim_speed:
		anim_timer = 0.0
		if is_attacking:
			if current_attack_mode == "primary" and attack_type == "ranged" and attack_pose_frame >= 0:
				current_frame = mini(attack_pose_frame, current_frame_count - 1)
			elif current_attack_mode == "kick" and attack_type == "ranged" and attack_pose_frame >= 0:
				current_frame = mini(attack_pose_frame, current_frame_count - 1)
			else:
				current_frame = min(current_frame + 1, current_frame_count - 1)
		else:
			current_frame = (current_frame + 1) % current_frame_count
	
	if is_attacking or is_channeling_magic:
		_set_animation("attack", attack_texture, _get_attack_texture_frame_count())
	elif not is_on_floor():
		_set_animation("jump", run_texture, jump_frame_count)
	elif is_moving:
		_set_animation("run", run_texture, run_frame_count)
	else:
		_set_animation("idle", idle_texture, idle_frame_count)
	
	sprite.frame = current_frame

func _set_animation(animation_name: String, texture: Texture2D, frame_count: int):
	if current_animation != animation_name:
		current_animation = animation_name
		current_frame_count = frame_count
		current_frame = min(current_frame, current_frame_count - 1)
		sprite.texture = texture
		sprite.hframes = frame_count
		return
	
	if sprite.texture != texture:
		sprite.texture = texture
	
	if sprite.hframes != frame_count:
		sprite.hframes = frame_count

func _flip_sprite():
	sprite.flip_h = facing_direction < 0.0

func attack(mode: String = "primary"):
	can_attack = false
	is_attacking = true
	current_attack_mode = mode
	anim_timer = 0.0
	current_frame = 0
	var animation_frames := _get_attack_frame_count()
	_set_animation("attack", attack_texture, _get_attack_texture_frame_count())
	sprite.frame = 0
	
	var hit_frame := attack_hit_frame if current_attack_mode == "primary" else kick_hit_frame
	var hit_delay = attack_anim_speed * clampi(hit_frame, 0, animation_frames - 1)
	if hit_delay > 0.0:
		await get_tree().create_timer(hit_delay).timeout
	
	_perform_attack_hit()
	
	var attack_animation_duration = attack_anim_speed * current_frame_count
	var recovery_time = max(attack_animation_duration - hit_delay, 0.0)
	if recovery_time > 0.0:
		await get_tree().create_timer(recovery_time).timeout
	
	is_attacking = false
	var total_cooldown := attack_cooldown if current_attack_mode == "primary" else kick_cooldown
	var cooldown_delay = max(total_cooldown - attack_animation_duration, 0.0)
	current_attack_mode = "primary"
	if cooldown_delay > 0.0:
		await get_tree().create_timer(cooldown_delay).timeout
	can_attack = true

func _get_attack_frame_count() -> int:
	if current_attack_mode == "kick":
		return mini(4, attack_frame_count)
	return attack_frame_count

func _get_attack_texture_frame_count() -> int:
	if current_attack_mode == "kick" and attack_type == "ranged":
		return attack_frame_count
	return _get_attack_frame_count()

func _perform_attack_hit():
	if current_attack_mode == "kick":
		if attack_type == "ranged":
			_perform_ranged_backstep()
			return
		_kick_enemies_in_attack()
		return
	if attack_type == "magic":
		return
	if attack_type == "ranged":
		_fire_arrow()
		return
	_damage_enemies_in_attack()

func _damage_enemies_in_attack():
	var attack_center = global_position + Vector2(attack_range * facing_direction, -10.0)
	for node in get_parent().get_children():
		if not (node is Enemy):
			continue
		var enemy := node as Enemy
		if not is_instance_valid(enemy):
			continue
		var to_enemy = enemy.global_position - global_position
		var is_in_front = sign(to_enemy.x) == sign(facing_direction) or absf(to_enemy.x) < 4.0
		var is_in_range = enemy.global_position.distance_to(attack_center) <= attack_hit_radius
		if is_in_front and is_in_range:
			enemy.take_damage(attack_damage)

func _kick_enemies_in_attack():
	var attack_center = global_position + Vector2(kick_range * facing_direction, -6.0)
	for node in get_parent().get_children():
		if not (node is Enemy):
			continue
		var enemy := node as Enemy
		if not is_instance_valid(enemy):
			continue
		var to_enemy = enemy.global_position - global_position
		var is_in_front = sign(to_enemy.x) == sign(facing_direction) or absf(to_enemy.x) < 6.0
		var is_in_range = enemy.global_position.distance_to(attack_center) <= kick_hit_radius
		if is_in_front and is_in_range:
			enemy.take_damage(kick_damage)
			enemy.apply_knockback(Vector2(kick_knockback_force * facing_direction, -120.0))

func _fire_arrow(flat_flight: bool = false):
	var arrow = ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	var spawn_offset: Vector2 = Vector2(20.0 * facing_direction, -28.0)
	if flat_flight:
		spawn_offset.y = -6.0
	var launch_velocity: Vector2 = Vector2(720.0 * facing_direction, 0.0)
	if not flat_flight:
		launch_velocity.y = -110.0
	arrow.global_position = sprite.global_position + spawn_offset
	arrow.setup(facing_direction, attack_damage, launch_velocity, flat_flight)

func _perform_ranged_backstep():
	backstep_direction = -facing_direction
	if backstep_direction == 0.0:
		backstep_direction = -1.0
	backstep_time_left = ranged_backstep_duration
	velocity.x = backstep_direction * ranged_backstep_speed
	velocity.y = 0.0
	_fire_arrow(true)

func _fire_magic_bolt():
	var bolt = MAGIC_BOLT_SCENE.instantiate()
	get_parent().add_child(bolt)
	var spawn_offset = Vector2(18.0 * facing_direction, -16.0)
	var launch_velocity = Vector2(760.0 * facing_direction, randf_range(-55.0, 55.0))
	bolt.global_position = sprite.global_position + spawn_offset
	bolt.setup(facing_direction, magic_bolt_damage + int(attack_damage * 0.35), launch_velocity)

func _reset_jump_state():
	jumps_remaining = 2 if can_double_jump else 1

func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health

func _update_mana_bar():
	if mana_bar == null:
		return
	mana_bar.visible = attack_type == "magic"
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	_update_health_bar()
	if current_health <= 0:
		die()

func die():
	died.emit()
	queue_free()
