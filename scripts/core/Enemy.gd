class_name Enemy extends CharacterBody2D

signal died
signal took_damage(amount: int)

@export var max_health: int = 30
@export var damage: int = 10
@export var move_speed: float = 100.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
@export var follow_range: float = 200.0

var current_health: int
var can_attack: bool = true
var target_player: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	current_health = max_health
	_load_sprites()
	_connect_detection()

func _load_sprites():
	var idle_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Idle.png")
	var run_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Run.png")
	
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("run")
	frames.add_animation("attack")
	frames.add_animation("hurt")
	frames.add_frame("idle", idle_tex)
	frames.add_frame("run", run_tex)
	frames.add_frame("attack", idle_tex)
	frames.add_frame("hurt", idle_tex)
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")

func _connect_detection():
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		target_player = body

func _on_body_exited(body):
	if body.name == "Player":
		target_player = null

func _physics_process(_delta):
	if is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.global_position)
		
		if distance <= follow_range:
			var direction = (target_player.global_position - global_position).normalized()
			
			if distance > attack_range:
				velocity = direction * move_speed
				animated_sprite.play("run")
			else:
				velocity = Vector2.ZERO
				if can_attack:
					attack()
			
			_flip_sprite(direction)
		else:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
		
		move_and_slide()

func _flip_sprite(direction: Vector2):
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false

func attack():
	can_attack = false
	animated_sprite.play("attack")
	
	if is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= attack_range:
		target_player.take_damage(damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	current_health -= amount
	took_damage.emit(amount)
	
	if current_health <= 0:
		die()
	else:
		animated_sprite.play("hurt")
		await get_tree().create_timer(0.2).timeout
		animated_sprite.play("idle")

func die():
	died.emit()
	queue_free()
