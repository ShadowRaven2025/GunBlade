extends Area2D

@export var speed: float = 620.0
@export var damage: int = 10
@export var max_distance: float = 540.0
@export var fall_acceleration: float = 760.0
@export var keep_flat_rotation: bool = false

var direction: float = 1.0
var travel_distance: float = 0.0
var velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func setup(arrow_direction: float, arrow_damage: int, launch_velocity: Vector2 = Vector2.ZERO, flat_flight: bool = false):
	direction = sign(arrow_direction)
	if direction == 0.0:
		direction = 1.0
	damage = arrow_damage
	sprite.flip_h = direction < 0.0
	keep_flat_rotation = flat_flight
	velocity = launch_velocity
	if velocity == Vector2.ZERO:
		velocity = Vector2(speed * direction, -110.0)
	_update_flight_rotation()

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not keep_flat_rotation:
		velocity.y += fall_acceleration * delta
	var movement: Vector2 = velocity * delta
	global_position += movement
	travel_distance += movement.length()
	_update_flight_rotation()
	if travel_distance >= max_distance:
		queue_free()

func _update_flight_rotation():
	if keep_flat_rotation:
		rotation = 0.0 if direction > 0.0 else PI
		return
	rotation = velocity.angle()
	if direction < 0.0:
		rotation += PI

func _on_body_entered(body: Node):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()
