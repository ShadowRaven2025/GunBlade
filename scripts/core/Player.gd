class_name Player extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal mana_changed(current_mana: int, max_mana: int)
signal died

@export var speed: float = 200.0
@export var max_health: int = 100
@export var max_mana: int = 50
@export var attack_damage: int = 10
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 0.5

var current_health: int
var current_mana: int
var is_attacking: bool = false
var can_attack: bool = true
var current_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready():
	current_health = max_health
	current_mana = max_mana
	_load_sprites()

func _load_sprites():
	var idle_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png")
	var run_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png")
	var attack_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png")
	
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("run")
	frames.add_animation("attack")
	frames.add_frame("idle", idle_tex)
	frames.add_frame("run", run_tex)
	frames.add_frame("attack", attack_tex)
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")

func _physics_process(_delta):
	var direction = _get_input_direction()
	print("Input: ", direction, " Pos: ", global_position)
	if direction.length() > 0:
		current_direction = direction
	velocity = direction * speed
	move_and_slide()
	print("After move: ", global_position)
	_update_animation(direction)
	_flip_sprite(direction)
	
	if Input.is_action_just_pressed("attack"):
		attack()

func _get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized()

func _move(direction: Vector2):
	if direction != Vector2.ZERO:
		current_direction = direction
	velocity = direction * speed
	move_and_slide()
	
	if direction.length() > 0:
		_flip_sprite(direction)

func _flip_sprite(direction: Vector2):
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false

func _update_animation(direction: Vector2):
	if direction != Vector2.ZERO:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func attack():
	if can_attack:
		can_attack = false
		is_attacking = true
		animated_sprite.play("attack")
		
		var enemies = hitbox.get_overlapping_bodies()
		for e in enemies:
			if e.has_method("take_damage"):
				e.take_damage(attack_damage)
		
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
		is_attacking = false

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func die():
	died.emit()
	queue_free()
