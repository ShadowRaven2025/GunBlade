class_name Player extends CharacterBody2D

signal died

@export var speed: float = 200.0
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var attack_duration: float = 0.3

var current_health: int
var can_attack: bool = true
var current_direction: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

var idle_texture: Texture2D
var run_texture: Texture2D
var attack_texture: Texture2D
var frame_count: int = 8
var current_frame: int = 0

func _ready():
	current_health = max_health
	idle_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png")
	run_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png")
	attack_texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png")
	
	sprite.texture = idle_texture
	sprite.hframes = 8
	sprite.vframes = 1
	sprite.frame = 0

var is_moving: bool = false
var anim_timer: float = 0.0
var anim_speed: float = 0.15

func _physics_process(_delta):
	var direction = _get_input_direction()
	is_moving = direction.length() > 0
	
	_flip_sprite(direction)
	
	velocity = direction * speed
	move_and_slide()
	
	_animate(_delta)
	
	if Input.is_action_just_pressed("attack"):
		attack()

func _animate(_delta):
	anim_timer += _delta
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		current_frame = (current_frame + 1) % frame_count
	
	if is_moving:
		sprite.texture = run_texture
		sprite.frame = current_frame
	else:
		sprite.texture = idle_texture
		sprite.frame = current_frame

func _get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized()

func _flip_sprite(direction: Vector2):
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

func attack():
	if can_attack:
		can_attack = false
		sprite.texture = attack_texture
		
		var enemies = hitbox.get_overlapping_bodies()
		for e in enemies:
			if e.has_method("take_damage"):
				e.take_damage(attack_damage)
		
		await get_tree().create_timer(attack_duration).timeout
		sprite.texture = idle_texture
		
		await get_tree().create_timer(attack_cooldown - attack_duration).timeout
		can_attack = true

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	died.emit()
	queue_free()
