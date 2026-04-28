extends Area2D

@export var speed: float = 250.0
@export var damage: int = 9
@export var lifetime: float = 4.0
@export var homing_strength: float = 0.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null

func setup(start_velocity: Vector2, card_damage: int, homing: float = 0.0):
	velocity = start_velocity
	damage = card_damage
	homing_strength = homing
	rotation = velocity.angle()

func _ready():
	body_entered.connect(_on_body_entered)
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float):
	if homing_strength > 0.0 and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized() * speed
		velocity = velocity.lerp(desired, clampf(homing_strength * delta, 0.0, 1.0))
	global_position += velocity * delta
	rotation = velocity.angle()
	lifetime = max(lifetime - delta, 0.0)
	if lifetime == 0.0:
		queue_free()

func _on_body_entered(body: Node):
	if body is Player:
		body.take_damage(damage)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
