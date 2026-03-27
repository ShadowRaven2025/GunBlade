extends Camera2D

@export var follow_speed: float = 5.0
@export var target: Node2D = null
@export var camera_offset: Vector2 = Vector2.ZERO

func _physics_process(delta):
	if target:
		var target_position = target.global_position + camera_offset
		global_position = global_position.lerp(target_position, follow_speed * delta)
