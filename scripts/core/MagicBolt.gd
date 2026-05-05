extends Area2D

@export var speed: float = 860.0
@export var damage: int = 8
@export var max_distance: float = 520.0

var direction: float = 1.0
var travel_distance: float = 0.0
var velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func setup(projectile_direction: float, projectile_damage: int, launch_velocity: Vector2 = Vector2.ZERO):
	direction = sign(projectile_direction)
	if direction == 0.0:
		direction = 1.0
	damage = projectile_damage
	sprite.flip_h = direction < 0.0
	velocity = launch_velocity
	if velocity == Vector2.ZERO:
		velocity = Vector2(speed * direction, 0.0)
	rotation = velocity.angle()

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var movement = velocity * delta
	global_position += movement
	travel_distance += movement.length()
	if travel_distance >= max_distance:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()
