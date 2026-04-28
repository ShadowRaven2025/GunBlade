extends Area2D

const SKY_STAR_SCENE = preload("res://scenes/game/projectiles/SkyStar.tscn")

@export var fall_gravity: float = 980.0
@export var max_lifetime: float = 2.2
@export var splash_radius: float = 42.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 12
var direction: float = 1.0
var can_split: bool = true
var split_count: int = 4
var split_damage: int = 5
var split_speed: float = 250.0
var direct_hit_damage_multiplier: float = 1.0
var star_scale: float = 1.0
var lifetime_left: float = 0.0
var has_exploded: bool = false
var direct_hit_enemy: Enemy = null
var uses_gravity: bool = true
var exploded_on_ground: bool = false

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(config: Dictionary):
	direction = sign(float(config.get("direction", 1.0)))
	if direction == 0.0:
		direction = 1.0
	velocity = config.get("velocity", Vector2(0.0, 280.0))
	damage = int(config.get("damage", damage))
	can_split = bool(config.get("can_split", can_split))
	split_count = int(config.get("split_count", split_count))
	split_damage = int(config.get("split_damage", split_damage))
	split_speed = float(config.get("split_speed", split_speed))
	direct_hit_damage_multiplier = float(config.get("direct_hit_damage_multiplier", direct_hit_damage_multiplier))
	star_scale = float(config.get("scale", star_scale))
	splash_radius = float(config.get("splash_radius", splash_radius))
	max_lifetime = float(config.get("max_lifetime", max_lifetime))
	uses_gravity = bool(config.get("uses_gravity", uses_gravity))
	lifetime_left = max_lifetime
	_apply_visual_scale()

func _ready():
	body_entered.connect(_on_body_entered)
	if max_lifetime > 0.0 and lifetime_left <= 0.0:
		lifetime_left = max_lifetime

func _physics_process(delta: float):
	if uses_gravity:
		velocity.y += fall_gravity * delta
	var movement := velocity * delta
	global_position += movement
	rotation += delta * 4.8 * direction
	if max_lifetime <= 0.0:
		return
	lifetime_left = max(lifetime_left - delta, 0.0)
	if lifetime_left == 0.0:
		exploded_on_ground = true
		explode()

func _on_body_entered(body: Node):
	if body is Enemy:
		direct_hit_enemy = body
		body.take_damage(maxi(1, int(round(damage * direct_hit_damage_multiplier))))
		explode()
		return
	if body is TileMapLayer or body is StaticBody2D:
		exploded_on_ground = true
		explode()

func explode():
	if has_exploded:
		return
	has_exploded = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)
	_damage_nearby_enemies()
	if can_split and exploded_on_ground:
		call_deferred("_spawn_split_stars")
	call_deferred("queue_free")

func _damage_nearby_enemies():
	if get_parent() == null:
		return
	for node in get_parent().get_children():
		if not (node is Enemy):
			continue
		var enemy := node as Enemy
		if not is_instance_valid(enemy):
			continue
		if enemy == direct_hit_enemy:
			continue
		if enemy.global_position.distance_to(global_position) > splash_radius:
			continue
		enemy.take_damage(damage)

func _spawn_split_stars():
	if get_parent() == null:
		return
	for index in range(max(split_count, 0)):
		var child_star = SKY_STAR_SCENE.instantiate()
		get_parent().add_child(child_star)
		child_star.global_position = global_position
		var ratio := 0.5 if split_count <= 1 else float(index) / float(split_count - 1)
		var spread_angle := lerpf(-1.15, 1.15, ratio)
		var launch_direction := Vector2(cos(spread_angle), sin(spread_angle) - 0.35).normalized()
		child_star.setup({
			"direction": sign(launch_direction.x),
			"velocity": launch_direction * split_speed,
			"damage": split_damage,
			"can_split": false,
			"split_count": 0,
			"split_damage": 0,
			"split_speed": split_speed * 0.55,
			"scale": maxf(star_scale * 0.35, 0.3),
			"splash_radius": maxf(splash_radius * 0.32, 12.0),
			"max_lifetime": 0.9,
			"uses_gravity": false
		})

func _apply_visual_scale():
	if visual != null:
		visual.scale = Vector2.ONE * star_scale
	if collision_shape != null:
		collision_shape.scale = Vector2.ONE * maxf(star_scale, 0.6)
