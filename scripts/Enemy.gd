class_name Enemy
extends CharacterBody2D

@export var stats: CharacterStats
@export var frames_count: int = 6
@export var sprite_texture: Texture2D

var player_node: Node2D = null
var gem_scene = preload("res://scenes/ExpGem.tscn")
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("enemies")
	if not stats:
		stats = CharacterStats.new()
	stats.reset_health()
	player_node = get_tree().get_first_node_in_group("player")
	
	if sprite_texture and sprite:
		sprite.texture = sprite_texture
		sprite.hframes = frames_count
		sprite.vframes = 1
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if stats.current_health <= 0:
		return

	if is_instance_valid(player_node):
		var dir = (player_node.global_position - global_position).normalized()
		velocity = dir * stats.move_speed
		if dir.x > 0:
			sprite.flip_h = false
		elif dir.x < 0:
			sprite.flip_h = true

		anim_timer += delta
		if sprite and frames_count > 0:
			sprite.frame = int(anim_timer * 8.0) % frames_count

		# Use delta for smooth collision sliding
		var collision = move_and_collide(velocity * delta)
		if collision:
			var collider = collision.get_collider()
			if collider is Player:
				collider.take_damage(stats.base_attack_power)

func take_damage(amount: float) -> void:
	var died = stats.take_damage(amount)
	# Flash white
	modulate = Color(3.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)

	if died:
		die()

func die() -> void:
	var gem = gem_scene.instantiate()
	gem.global_position = global_position
	gem.exp_amount = stats.exp_reward
	get_parent().call_deferred("add_child", gem)
	var parent_node = get_parent()
	if parent_node and parent_node.has_method("add_score"):
		parent_node.add_score(stats.score_reward)
	queue_free()