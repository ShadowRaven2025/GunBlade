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

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("enemies")
	current_health = max_health
	idle_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Purple Units/Pawn/Pawn_Idle.png")
	run_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Purple Units/Pawn/Pawn_Run.png")
	sprite.texture = idle_texture
	sprite.hframes = idle_frame_count
	sprite.vframes = 1
	sprite.frame = 0
	current_frame_count = idle_frame_count
	_update_health_bar()

func _physics_process(delta):
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	var move_direction := 0.0
	if is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		var horizontal_distance = absf(to_player.x)
		var vertical_distance = absf(to_player.y)
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
	
	anim_timer += delta
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		current_frame = (current_frame + 1) % current_frame_count
		sprite.frame = current_frame

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
	if current_health <= 0:
		die()

func die():
	died.emit()
	collision_shape.disabled = true
	queue_free()
