class_name Enemy
extends CharacterBody2D

@export var stats: CharacterStats
@export var frames_count: int = 6
@export var sprite_texture: Texture2D

@export var attack_texture: Texture2D
@export var attack_frames_count: int = 6
@export var attack_range: float = 0.0

var player_node: Node2D = null
var gem_scene = preload("res://scenes/ExpGem.tscn")
var anim_timer: float = 0.0
var state: String = "walk"
var attack_timer: float = 0.0
var attack_cooldown: float = 0.0
var has_damaged: bool = false

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

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_instance_valid(player_node):
		var dir = (player_node.global_position - global_position).normalized()
		var dist = global_position.distance_to(player_node.global_position)

		# 공격 모션이 설정된 몬스터의 공격 진입 판정
		if attack_texture and dist <= attack_range and attack_cooldown <= 0.0 and state == "walk":
			state = "attack"
			attack_timer = 0.0
			has_damaged = false
			if sprite:
				sprite.texture = attack_texture
				sprite.hframes = attack_frames_count
				sprite.frame = 0

		if state == "attack":
			velocity = Vector2.ZERO
			if dir.x > 0:
				sprite.flip_h = false
			elif dir.x < 0:
				sprite.flip_h = true

			attack_timer += delta
			var cur_frame = int(attack_timer * 9.0)
			if cur_frame >= attack_frames_count:
				# 공격 애니메이션 완료 후 걷기 모드로 복귀
				state = "walk"
				attack_cooldown = max(0.6, stats.attack_interval)
				if sprite:
					sprite.texture = sprite_texture
					sprite.hframes = frames_count
					sprite.frame = 0
			else:
				if sprite:
					sprite.frame = cur_frame
				# 3번째 프레임 타격 시점에 데미지 적용
				if cur_frame >= 3 and not has_damaged:
					has_damaged = true
					if is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) <= attack_range + 25.0:
						player_node.take_damage(stats.base_attack_power)
		else:
			# 기본 걷기 및 추적
			velocity = dir * stats.move_speed
			if dir.x > 0:
				sprite.flip_h = false
			elif dir.x < 0:
				sprite.flip_h = true

			anim_timer += delta
			if sprite and frames_count > 0:
				sprite.frame = int(anim_timer * 8.0) % frames_count

			var collision = move_and_collide(velocity * delta)
			if collision:
				var collider = collision.get_collider()
				if collider is Player:
					collider.take_damage(stats.base_attack_power)

func init_enemy(p_stats: CharacterStats, p_tex: Texture2D, p_frames: int, p_atk_tex: Texture2D = null, p_atk_frames: int = 6, p_atk_range: float = 0.0) -> void:
	stats = p_stats.duplicate()
	stats.reset_health()
	frames_count = p_frames
	sprite_texture = p_tex
	attack_texture = p_atk_tex
	attack_frames_count = p_atk_frames
	attack_range = p_atk_range
	state = "walk"
	attack_timer = 0.0
	attack_cooldown = 0.0
	has_damaged = false
	anim_timer = 0.0
	modulate = Color(1, 1, 1, 1)

	if sprite:
		sprite.texture = sprite_texture
		sprite.hframes = frames_count
		sprite.vframes = 1
		sprite.frame = 0

func take_damage(amount: float) -> void:
	var died = stats.take_damage(amount)
	# Flash white
	modulate = Color(3.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)

	if died:
		die()

func die() -> void:
	var parent_node = get_parent()
	if parent_node:
		var gem = ObjectPool.spawn(gem_scene, parent_node) as ExpGem
		if gem:
			gem.init_gem(stats.exp_reward, global_position)
		if parent_node.has_method("add_score"):
			parent_node.add_score(stats.score_reward)

	ObjectPool.recycle(self)