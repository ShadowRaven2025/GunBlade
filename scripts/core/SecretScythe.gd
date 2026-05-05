extends Area2D

@export var damage: int = 14
@export var lifetime: float = 3.0
@export var creates_light_beam_on_ground: bool = false
@export var light_beam_lifetime: float = 0.38

var velocity: Vector2 = Vector2.ZERO
var spin_speed: float = 8.0

func setup(start_velocity: Vector2, scythe_damage: int):
	velocity = start_velocity
	damage = scythe_damage
	rotation = velocity.angle()

func setup_final_fall(start_velocity: Vector2, scythe_damage: int):
	setup(start_velocity, scythe_damage)
	creates_light_beam_on_ground = true

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
		if creates_light_beam_on_ground:
			_spawn_light_beam()
		queue_free()

func _spawn_light_beam():
	var parent: Node = get_parent()
	if parent == null:
		return
	var beam: ColorRect = ColorRect.new()
	beam.color = Color(1.0, 1.0, 1.0, 0.82)
	beam.size = Vector2(24.0, 720.0)
	beam.position = Vector2(global_position.x - beam.size.x * 0.5, global_position.y - beam.size.y)
	parent.add_child(beam)
	var tween: Tween = beam.create_tween()
	tween.tween_property(beam, "color:a", 0.0, light_beam_lifetime)
	tween.parallel().tween_property(beam, "size:x", 42.0, light_beam_lifetime)
	tween.finished.connect(beam.queue_free)
