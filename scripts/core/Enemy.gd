extends CharacterBody2D
class_name Enemy

signal died
signal took_damage(amount: int)

@export var max_health: int = 30
@export var damage: int = 10
@export var speed: float = 100.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
@export var follow_range: float = 200.0

var current_health: int
var can_attack: bool = true
var player: Node2D = null

var sprite_idle: Texture2D
var sprite_run: Texture2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	current_health = max_health
	_load_sprites()
	_detection_setup()

func _load_sprites():
	sprite_idle = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Idle.png")
	sprite_run = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Run.png")
	
	animated_sprite.sprite_frames = SpriteFrames.new()
	animated_sprite.sprite_frames.add_animation("idle")
	animated_sprite.sprite_frames.add_frame("idle", sprite_idle)
	animated_sprite.sprite_frames.add_animation("run")
	animated_sprite.sprite_frames.add_frame("run", sprite_run)
	animated_sprite.play("idle")

func _physics_process(delta):
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= follow_range:
			var direction = (player.global_position - global_position).normalized()
			
			if distance > attack_range:
				velocity = direction * speed
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

func _detection_setup():
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)

func _on_player_detected(body):
	if body is Player:
		player = body

func _on_player_lost(body):
	if body is Player:
		if player == body:
			player = null

func attack():
	can_attack = false
	animated_sprite.play("attack")
	
	if player and global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(damage)
	
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
	if player and player.has_method("add_gold"):
		player.add_gold(10)
	queue_free()
