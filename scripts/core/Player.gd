class_name Player extends CharacterBody2D

signal died

const ARROW_SCENE = preload("res://scenes/game/projectiles/Arrow.tscn")

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

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

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
	_update_health_bar()

func set_character_visuals(idle_path: String, run_path: String, attack_path: String, idle_frames: int = 8, run_frames: int = 6, attack_frames: int = 4, hit_frame: int = 2, pose_frame: int = -1, next_attack_type: String = "melee"):
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
	sprite.texture = idle_texture
	sprite.hframes = idle_frame_count
	sprite.vframes = 1
	sprite.frame = 0
	current_frame_count = idle_frame_count
	current_animation = "idle"

func _physics_process(delta):
	var input_axis = Input.get_axis("move_left", "move_right")
	is_moving = absf(input_axis) > 0.01
	if is_moving:
		facing_direction = sign(input_axis)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump") and not is_attacking:
		velocity.y = jump_velocity
	
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, speed * 0.15)
	else:
		velocity.x = input_axis * speed
	
	_flip_sprite()
	move_and_slide()
	_animate(delta)
	
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()

func _animate(delta):
	anim_timer += delta
	var current_anim_speed = attack_anim_speed if is_attacking else 0.14
	if anim_timer >= current_anim_speed:
		anim_timer = 0.0
		if is_attacking:
			if attack_type == "ranged" and attack_pose_frame >= 0:
				current_frame = mini(attack_pose_frame, current_frame_count - 1)
			else:
				current_frame = min(current_frame + 1, current_frame_count - 1)
		else:
			current_frame = (current_frame + 1) % current_frame_count
	
	if is_attacking:
		_set_animation("attack", attack_texture, attack_frame_count)
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

func attack():
	can_attack = false
	is_attacking = true
	anim_timer = 0.0
	current_frame = 0
	_set_animation("attack", attack_texture, attack_frame_count)
	sprite.frame = 0
	
	var hit_delay = attack_anim_speed * clampi(attack_hit_frame, 0, attack_frame_count - 1)
	if hit_delay > 0.0:
		await get_tree().create_timer(hit_delay).timeout
	
	_perform_attack_hit()
	
	var attack_animation_duration = attack_anim_speed * attack_frame_count
	var recovery_time = max(attack_animation_duration - hit_delay, 0.0)
	if recovery_time > 0.0:
		await get_tree().create_timer(recovery_time).timeout
	
	is_attacking = false
	var cooldown_delay = max(attack_cooldown - attack_animation_duration, 0.0)
	if cooldown_delay > 0.0:
		await get_tree().create_timer(cooldown_delay).timeout
	can_attack = true

func _perform_attack_hit():
	if attack_type == "ranged":
		_fire_arrow()
		return
	_damage_enemies_in_attack()

func _damage_enemies_in_attack():
	var attack_direction = Vector2.RIGHT * facing_direction
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

func _fire_arrow():
	var arrow = ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector2(22.0 * facing_direction, -12.0)
	arrow.setup(facing_direction, attack_damage)

func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health

func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	_update_health_bar()
	if current_health <= 0:
		die()

func die():
	died.emit()
	queue_free()
