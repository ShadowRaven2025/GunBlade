class_name Enemy
extends CharacterBody2D

signal died
signal took_damage(amount: int)

const ENEMY_SCENE = preload("res://scenes/game/characters/Enemy.tscn")

@export var max_health: int = 30
@export_enum("pawn", "rush", "guard", "brute", "ranged", "splitter", "blink") var enemy_type: String = "pawn"
@export var damage: int = 10
@export var speed: float = 90.0
@export var follow_range: float = 340.0
@export var attack_range: float = 48.0
@export var gravity: float = 980.0
@export var attack_cooldown: float = 1.0
@export var projectile_cooldown: float = 1.6
@export var projectile_damage: int = 8
@export var split_on_death: bool = false
@export var blink_cooldown: float = 2.4
@export var blink_distance: float = 150.0
@export var use_ai: bool = true
@export var movement_locked: bool = false
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
@export var boss_leap_telegraph_time: float = 0.38

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
var target_player = null
var facing_direction: float = -1.0
var spawn_position: Vector2
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var boss_leap_ready: bool = true
var boss_leap_time_left: float = 0.0
var boss_phase_two_active: bool = false
var boss_phase_two_summoned: bool = false
var projectile_ready: bool = true
var blink_ready: bool = true
var did_split: bool = false
var base_speed: float = 0.0
var base_damage: int = 0
var base_modulate: Color = Color(1, 1, 1, 1)
var base_boss_leap_cooldown: float = 0.0
var boss_telegraph_time_left: float = 0.0
var boss_pending_leap_direction: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_shape = $Hurtbox/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("enemies")
	_apply_enemy_type_defaults()
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
	if get_parent() != null and get_parent().has_method("register_enemy"):
		get_parent().register_enemy(self)

func _physics_process(delta):
	if movement_locked:
		_physics_process_dummy(delta)
		return
	if not use_ai:
		_physics_process_dummy(delta)
		return
	
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	
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

	if boss_telegraph_time_left > 0.0:
		boss_telegraph_time_left = max(boss_telegraph_time_left - delta, 0.0)
		velocity.x = 0.0
		modulate = base_modulate.lerp(Color(1, 0.9, 0.55, 1), 0.55)
		if boss_telegraph_time_left == 0.0:
			_start_boss_leap(boss_pending_leap_direction)
		move_and_slide()
		_flip_sprite()
		_set_animation("idle")
		_advance_animation(delta)
		return

	if boss_leap_time_left > 0.0:
		boss_leap_time_left = max(boss_leap_time_left - delta, 0.0)
		if boss_leap_time_left == 0.0:
			modulate = base_modulate if not boss_phase_two_active else base_modulate.lerp(Color(1, 0.25, 0.2, 1), 0.45)
		move_and_slide()
		_flip_sprite()
		_set_animation("run")
		_advance_animation(delta)
		return
	
	var move_direction = 0.0
	if is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		var horizontal_distance = absf(to_player.x)
		var vertical_distance = absf(to_player.y)
		if enemy_type == "blink" and _can_blink(horizontal_distance, vertical_distance):
			_blink_near_player(sign(to_player.x))
		if enemy_type == "ranged" and horizontal_distance <= follow_range and vertical_distance <= 130.0:
			_handle_ranged_enemy(to_player, horizontal_distance)
			move_and_slide()
			_flip_sprite()
			_set_animation("run" if absf(velocity.x) > 1.0 else "idle")
			_advance_animation(delta)
			return
		if is_boss and _can_start_boss_leap(horizontal_distance, vertical_distance):
			_begin_boss_telegraph(sign(to_player.x))
			move_and_slide()
			_flip_sprite()
			_set_animation("idle")
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

func attack(player):
	can_attack = false
	_spawn_attack_effect()
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage)
	var tree = get_tree()
	if tree != null:
		await tree.create_timer(attack_cooldown).timeout
	if is_instance_valid(self):
		can_attack = true

func _handle_ranged_enemy(to_player: Vector2, horizontal_distance: float):
	facing_direction = sign(to_player.x) if to_player.x != 0.0 else facing_direction
	var keep_distance := attack_range * 0.72
	if horizontal_distance < keep_distance:
		velocity.x = -facing_direction * speed * 0.65
	elif horizontal_distance > attack_range:
		velocity.x = facing_direction * speed * 0.45
	else:
		velocity.x = 0.0
	if projectile_ready and horizontal_distance <= attack_range:
		_fire_enemy_projectile(Vector2(facing_direction, -0.08).normalized())

func _fire_enemy_projectile(direction: Vector2):
	projectile_ready = false
	var bolt: ColorRect = ColorRect.new()
	bolt.color = Color(1.0, 0.36, 0.18, 0.9)
	bolt.size = Vector2(18.0, 7.0)
	bolt.global_position = global_position + Vector2(16.0 * facing_direction, -18.0)
	bolt.set_meta("velocity", direction * 360.0)
	bolt.set_meta("damage", projectile_damage)
	bolt.set_meta("life", 1.4)
	bolt.set_meta("enemy_projectile", true)
	get_parent().add_child(bolt)
	_animate_enemy_projectile(bolt)
	var tree = get_tree()
	if tree != null:
		await tree.create_timer(projectile_cooldown).timeout
	if is_instance_valid(self):
		projectile_ready = true

func _animate_enemy_projectile(bolt: ColorRect):
	while is_instance_valid(bolt):
		var delta := get_physics_process_delta_time()
		var life := float(bolt.get_meta("life", 0.0)) - delta
		if life <= 0.0:
			bolt.queue_free()
			return
		bolt.set_meta("life", life)
		bolt.global_position += bolt.get_meta("velocity", Vector2.ZERO) * delta
		var player = get_tree().get_first_node_in_group("player")
		if player != null and is_instance_valid(player) and player.global_position.distance_to(bolt.global_position) <= 28.0:
			if player.has_method("take_damage"):
				player.take_damage(int(bolt.get_meta("damage", projectile_damage)))
			bolt.queue_free()
			return
		await get_tree().physics_frame

func _can_blink(horizontal_distance: float, vertical_distance: float) -> bool:
	return blink_ready and is_on_floor() and horizontal_distance >= 170.0 and horizontal_distance <= follow_range and vertical_distance <= 120.0

func _blink_near_player(direction_to_player: float):
	if direction_to_player == 0.0:
		direction_to_player = facing_direction
	blink_ready = false
	_spawn_blink_effect(global_position)
	global_position.x += direction_to_player * minf(blink_distance, 180.0)
	facing_direction = direction_to_player
	_spawn_blink_effect(global_position)
	var tree = get_tree()
	if tree != null:
		await tree.create_timer(blink_cooldown).timeout
	if is_instance_valid(self):
		blink_ready = true

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
	if split_on_death and not did_split:
		did_split = true
		_spawn_split_children()
	if respawn_on_death:
		_respawn_after_delay()
		return
	collision_shape.set_deferred("disabled", true)
	hurtbox_shape.set_deferred("disabled", true)
	queue_free()

func _spawn_split_children():
	if get_parent() == null:
		return
	for offset_x in [-28.0, 28.0]:
		var child = ENEMY_SCENE.instantiate()
		get_parent().add_child(child)
		child.global_position = global_position + Vector2(offset_x, -8.0)
		child.enemy_type = "rush"
		child.max_health = maxi(12, int(max_health * 0.35))
		child.damage = maxi(4, int(damage * 0.55))
		child.speed = speed + 34.0
		child.projectile_damage = projectile_damage
		child.follow_range = follow_range
		child.attack_range = 38.0
		child.scale = Vector2(0.72, 0.72)
		child.modulate = Color(0.9, 0.45, 1.0, 1)

func apply_knockback(force: Vector2, duration: float = 0.18):
	knockback_velocity = force
	knockback_time_left = duration
	if force.x != 0.0:
		facing_direction = sign(force.x)

func _can_start_boss_leap(horizontal_distance: float, vertical_distance: float) -> bool:
	return boss_leap_ready and boss_telegraph_time_left <= 0.0 and is_on_floor() and horizontal_distance >= 120.0 and horizontal_distance <= 380.0 and vertical_distance <= 120.0

func _begin_boss_telegraph(direction: float):
	boss_pending_leap_direction = direction
	if boss_pending_leap_direction == 0.0:
		boss_pending_leap_direction = facing_direction
	boss_telegraph_time_left = boss_leap_telegraph_time
	boss_leap_ready = false

func _start_boss_leap(direction: float):
	var leap_direction = direction
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
	var tree = get_tree()
	if tree != null:
		await tree.create_timer(boss_leap_cooldown).timeout
	if is_instance_valid(self):
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
	if not boss_phase_two_summoned:
		boss_phase_two_summoned = true
		call_deferred("_summon_phase_two_reinforcements")

func _summon_phase_two_reinforcements():
	if get_parent() == null:
		return
	var summon_offsets = [Vector2(-170, -24), Vector2(170, -24)]
	for offset in summon_offsets:
		var summon = ENEMY_SCENE.instantiate()
		get_parent().add_child(summon)
		summon.global_position = global_position + offset
		summon.max_health = 48
		summon.damage = 14
		summon.speed = 108.0
		summon.projectile_damage = 8
		summon.follow_range = 880.0
		summon.attack_range = 46.0
		summon.gravity = gravity
		summon.modulate = Color(1, 0.42, 0.34, 1)

func _apply_enemy_type_defaults():
	match enemy_type:
		"rush":
			max_health = max_health if max_health != 30 else 24
			damage = damage if damage != 10 else 9
			speed = speed if speed != 90.0 else 142.0
			attack_cooldown = 0.72
			modulate = Color(1.0, 0.35, 0.28, 1)
			scale *= 0.88
		"guard":
			max_health = max_health if max_health != 30 else 58
			damage = damage if damage != 10 else 13
			speed = speed if speed != 90.0 else 62.0
			attack_range = maxf(attack_range, 56.0)
			modulate = Color(0.45, 0.66, 1.0, 1)
			scale *= 1.15
		"brute":
			max_health = max_health if max_health != 30 else 82
			damage = damage if damage != 10 else 22
			speed = speed if speed != 90.0 else 52.0
			attack_range = maxf(attack_range, 64.0)
			attack_cooldown = 1.45
			modulate = Color(0.62, 0.38, 0.24, 1)
			scale *= 1.42
		"ranged":
			max_health = max_health if max_health != 30 else 26
			damage = damage if damage != 10 else 7
			speed = speed if speed != 90.0 else 78.0
			attack_range = maxf(attack_range, 280.0)
			follow_range = maxf(follow_range, 520.0)
			modulate = Color(1.0, 0.58, 0.2, 1)
			scale *= 0.95
		"splitter":
			max_health = max_health if max_health != 30 else 42
			damage = damage if damage != 10 else 11
			speed = speed if speed != 90.0 else 76.0
			split_on_death = true
			modulate = Color(0.82, 0.32, 1.0, 1)
			scale *= 1.08
		"blink":
			max_health = max_health if max_health != 30 else 34
			damage = damage if damage != 10 else 14
			speed = speed if speed != 90.0 else 112.0
			follow_range = maxf(follow_range, 560.0)
			modulate = Color(0.36, 1.0, 0.82, 1)
			scale *= 0.92

func _spawn_attack_effect():
	var parent: Node = get_parent()
	if parent == null:
		return
	var flash: ColorRect = ColorRect.new()
	flash.color = base_modulate.lerp(Color(1, 1, 1, 1), 0.35)
	flash.size = Vector2(34.0, 20.0) * scale.abs()
	flash.global_position = global_position + Vector2(attack_range * 0.45 * facing_direction, -18.0)
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.16)
	tween.parallel().tween_property(flash, "scale", Vector2(1.5, 0.4), 0.16)
	tween.finished.connect(flash.queue_free)

func _spawn_blink_effect(effect_position: Vector2):
	var parent: Node = get_parent()
	if parent == null:
		return
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(0.3, 1.0, 0.86, 0.46)
	flash.size = Vector2(46.0, 58.0) * scale.abs()
	flash.global_position = effect_position + Vector2(-23.0, -52.0)
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.28)
	tween.parallel().tween_property(flash, "scale", Vector2(1.35, 1.35), 0.28)
	tween.finished.connect(flash.queue_free)

func _respawn_after_delay():
	set_physics_process(false)
	visible = false
	collision_shape.set_deferred("disabled", true)
	hurtbox_shape.set_deferred("disabled", true)
	var tree = get_tree()
	if tree == null:
		return
	await tree.create_timer(respawn_delay).timeout
	if not is_instance_valid(self):
		return
	global_position = spawn_position
	current_health = max_health
	can_attack = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_time_left = 0.0
	boss_telegraph_time_left = 0.0
	boss_pending_leap_direction = 0.0
	boss_leap_time_left = 0.0
	boss_leap_ready = true
	boss_phase_two_active = false
	boss_phase_two_summoned = false
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
	collision_shape.set_deferred("disabled", false)
	hurtbox_shape.set_deferred("disabled", false)
	visible = true
	set_physics_process(true)
