extends Area2D

@export var damage: int = 14
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var spin_speed: float = 8.0

func setup(start_velocity: Vector2, scythe_damage: int):
	velocity = start_velocity
	damage = scythe_damage
	rotation = velocity.angle()

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float):
	global_position += velocity * delta
	rotation += spin_speed * delta
	lifetime = max(lifetime - delta, 0.0)
	if lifetime == 0.0:
		queue_free()

func _on_body_entered(body: Node):
	if body is Player:
		body.take_damage(damage)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
