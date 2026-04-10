extends Area2D

@export var speed: float = 620.0
@export var damage: int = 10
@export var max_distance: float = 540.0

var direction: float = 1.0
var travel_distance: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func setup(arrow_direction: float, arrow_damage: int):
	direction = sign(arrow_direction)
	if direction == 0.0:
		direction = 1.0
	damage = arrow_damage
	rotation = 0.0 if direction > 0.0 else PI
	sprite.flip_h = direction < 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var distance_step = speed * delta
	global_position.x += direction * distance_step
	travel_distance += distance_step
	if travel_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node):
	if body is Enemy:
		body.take_damage(damage)
		queue_free()
		return
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()
