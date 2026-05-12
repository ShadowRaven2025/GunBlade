extends CharacterBody2D

signal defeated
signal died

const KNIFE_SCENE = preload("res://scenes/game/projectiles/DarkKnife.tscn")

@export var max_health: int = 360
@export var gravity: float = 980.0
@export var knife_damage: int = 12
@export var slash_damage: int = 9999
@export var arena_min_x: float = 150.0
@export var arena_max_x: float = 1130.0
@export var ground_y: float = 598.0

var current_health: int = 0
var attack_timer: float = 1.1
var slash_timer: float = 4.2
var is_casting_slash: bool = false
var defeated_started: bool = false
var target: Player = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("enemies")
	current_health = max_health
	sprite.texture = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png")
	sprite.hframes = 8
	sprite.vframes = 1
	sprite.modulate = Color(0.08, 0.08, 0.1, 1.0)
	_update_health_bar()
	if get_parent() != null and get_parent().has_method("register_enemy"):
		get_parent().register_enemy(self)

func _physics_process(delta: float):
	if defeated_started:
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if is_casting_slash:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	slash_timer = maxf(slash_timer - delta, 0.0)
	if slash_timer == 0.0:
		_cast_arena_slash()
		slash_timer = 6.2
		return
	if attack_timer == 0.0:
		_spawn_knife_barrage()
		attack_timer = 1.25

func take_damage(amount: int):
	if defeated_started:
		return
	current_health = max(current_health - amount, 0)
	_update_health_bar()
	if current_health <= 0:
		_die()

func apply_knockback(_force: Vector2, _duration: float = 0.18):
	pass

func _spawn_knife_barrage():
	var parent: Node = get_parent()
	if parent == null:
		return
	for index in range(4):
		var knife = KNIFE_SCENE.instantiate()
		parent.add_child(knife)
		var spawn_x: float = lerpf(arena_min_x, arena_max_x, float(index + 1) / 5.0)
		if is_instance_valid(target):
			spawn_x = clampf(target.global_position.x + float(index - 1.5) * 110.0, arena_min_x, arena_max_x)
		knife.global_position = Vector2(spawn_x, 155.0 + randf_range(-35.0, 35.0))
		var direction: Vector2 = Vector2.DOWN
		if is_instance_valid(target):
			direction = (target.global_position - knife.global_position).normalized()
		knife.setup(direction * 255.0, knife_damage, 0.55)

func _cast_arena_slash():
	is_casting_slash = true
	var overlay: ColorRect = _get_or_create_black_overlay()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.visible = true
	var fade_in: Tween = overlay.create_tween()
	fade_in.tween_property(overlay, "color:a", 1.0, 0.18)
	await get_tree().create_timer(1.0).timeout
	_damage_grounded_targets()
	_spawn_slash_visual()
	var fade_out: Tween = overlay.create_tween()
	fade_out.tween_property(overlay, "color:a", 0.0, 0.22)
	await fade_out.finished
	overlay.visible = false
	is_casting_slash = false

func _damage_grounded_targets():
	if is_instance_valid(target) and target.is_on_floor():
		target.take_damage(maxi(slash_damage, target.max_health))

func _spawn_slash_visual():
	var parent: Node = get_parent()
	if parent == null:
		return
	var slash: ColorRect = ColorRect.new()
	slash.color = Color(1.0, 1.0, 1.0, 0.86)
	slash.size = Vector2(arena_max_x - arena_min_x, 26.0)
	slash.position = Vector2(arena_min_x, ground_y - 32.0)
	parent.add_child(slash)
	var tween: Tween = slash.create_tween()
	tween.tween_property(slash, "color:a", 0.0, 0.28)
	tween.parallel().tween_property(slash, "size:y", 4.0, 0.28)
	tween.finished.connect(slash.queue_free)

func _get_or_create_black_overlay() -> ColorRect:
	var existing: ColorRect = get_node_or_null("/root/SecretBossRoom/CanvasLayer/DarkSlashOverlay") as ColorRect
	if existing != null:
		return existing
	var canvas: CanvasLayer = get_parent().get_node_or_null("CanvasLayer") as CanvasLayer
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DarkSlashOverlay"
	overlay.offset_right = 1280.0
	overlay.offset_bottom = 720.0
	overlay.color = Color(0, 0, 0, 0)
	overlay.visible = false
	if canvas != null:
		canvas.add_child(overlay)
	else:
		get_parent().add_child(overlay)
	return overlay

func _update_health_bar():
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health

func _die():
	defeated_started = true
	defeated.emit()
	died.emit()
	queue_free()
