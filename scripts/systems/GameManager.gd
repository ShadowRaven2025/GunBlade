extends Node2D

func _ready():
	_setup_player()
	_setup_enemies()

func _setup_player():
	var player = $Player
	player.set_script(load("res://scripts/core/Player.gd"))
	player.speed = 200.0
	player.max_health = 100
	player.max_mana = 50
	player.attack_damage = 10
	player.attack_range = 50.0
	player.attack_cooldown = 0.5
	
	var sprite = player.get_node("AnimatedSprite2D")
	sprite.sprite_frames = _create_player_sprites()
	sprite.play("idle")

func _create_player_sprites() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("run")
	frames.add_animation("attack")
	
	var idle_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Idle.png")
	var run_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Run.png")
	var attack_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Warrior/Warrior_Attack1.png")
	
	frames.add_frame("idle", idle_tex)
	frames.add_frame("run", run_tex)
	frames.add_frame("attack", attack_tex)
	
	return frames

func _setup_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		_setup_enemy(enemy)
	
	# Also setup by name
	var enemy_names = ["Enemy", "Enemy2", "Enemy3"]
	for name in enemy_names:
		var enemy = find_child(name, true, false)
		if enemy:
			_setup_enemy(enemy)

func _setup_enemy(enemy: CharacterBody2D):
	enemy.set_script(load("res://scripts/core/Enemy.gd"))
	enemy.max_health = 30
	enemy.damage = 10
	enemy.speed = 100.0
	enemy.attack_range = 40.0
	enemy.attack_cooldown = 1.0
	enemy.follow_range = 200.0
	
	var sprite = enemy.get_node("AnimatedSprite2D")
	sprite.sprite_frames = _create_enemy_sprites()
	sprite.play("idle")

func _create_enemy_sprites() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("run")
	frames.add_animation("attack")
	frames.add_animation("hurt")
	
	var idle_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Idle.png")
	var run_tex = load("res://assets/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Run.png")
	
	frames.add_frame("idle", idle_tex)
	frames.add_frame("run", run_tex)
	frames.add_frame("attack", idle_tex)
	frames.add_frame("hurt", idle_tex)
	
	return frames
