class_name Enemy
extends CharacterBody2D

signal boss_health_changed(current: float, max_val: float)
signal boss_died

@export var stats: CharacterStats
@export var frames_count: int = 6
@export var sprite_texture: Texture2D

@export var attack_texture: Texture2D
@export var attack_frames_count: int = 6
@export var attack_range: float = 0.0

@export var hurt_texture: Texture2D
@export var hurt_frames_count: int = 4

@export var death_texture: Texture2D
@export var death_frames_count: int = 4

var player_node: Node2D = null
var gem_scene = preload("res://scenes/ExpGem.tscn")
var magnet_scene = preload("res://scenes/MagnetItem.tscn")
var anim_timer: float = 0.0
var state: String = "walk"
var attack_timer: float = 0.0
var attack_cooldown: float = 0.0
var has_damaged: bool = false
var hurt_timer: float = 0.0
var death_timer: float = 0.0

var burn_timer: float = 0.0
var burn_damage: float = 0.0
var burn_tick_timer: float = 0.0
var stun_timer: float = 0.0
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0
var is_boss: bool = false

# Boss Skills System
var boss_charge_texture: Texture2D = null
var boss_cleave_texture: Texture2D = null
var boss_slam_texture: Texture2D = null
var boss_charge_cooldown: float = 5.0
var boss_cleave_cooldown: float = 4.0
var boss_slam_cooldown: float = 8.0

var skill_timer: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var charge_speed: float = 420.0
var has_skill_hit: bool = false

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

func apply_burn(dmg: float, duration: float) -> void:
	burn_timer = duration
	burn_damage = dmg
	burn_tick_timer = 0.0

func apply_stun(duration: float) -> void:
	if is_boss:
		stun_timer = max(stun_timer, duration * 0.4)
	else:
		stun_timer = max(stun_timer, duration)

func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = multiplier
	slow_timer = max(slow_timer, duration)

func _physics_process(delta: float) -> void:
	if is_dying:
		# 사망 모션 재생
		if death_texture and death_frames_count > 0:
			death_timer += delta
			var death_frame = int(death_timer * 9.0)
			if sprite:
				sprite.frame = min(death_frame, death_frames_count - 1)
			if death_frame >= death_frames_count:
				finish_death()
		return

	if stats.current_health <= 0:
		return

	# 화염 지속 데미지 (Burn DoT)
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= 0.35:
			burn_tick_timer = 0.0
			take_damage(burn_damage)
			# 화염 피격 플래시
			modulate = Color(2.5, 0.6, 0.2, 1.0)
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_boss:
		if boss_charge_cooldown > 0.0:
			boss_charge_cooldown -= delta
		if boss_cleave_cooldown > 0.0:
			boss_cleave_cooldown -= delta
		if boss_slam_cooldown > 0.0:
			boss_slam_cooldown -= delta

	# 피격 모션(hurt) 처리
	if state == "hurt":
		hurt_timer -= delta
		if hurt_texture and hurt_frames_count > 0 and sprite:
			var h_frame = int((0.2 - hurt_timer) * (hurt_frames_count / 0.2))
			sprite.frame = clamp(h_frame, 0, hurt_frames_count - 1)
		if hurt_timer <= 0.0:
			state = "walk"
			if sprite:
				sprite.texture = sprite_texture
				sprite.hframes = frames_count
				sprite.frame = 0
		return

	# ----------------- 보스 특수 스킬 실행 상태 -----------------
	if is_boss:
		if state == "charge":
			# 1. 맹렬한 돌진 스킬 (Charge)
			skill_timer += delta
			# 0.4초간 돌진 경로 붉은 예고선 표시 후 돌진 개시
			if skill_timer < 0.4:
				velocity = Vector2.ZERO
				return
			
			global_position += charge_direction * charge_speed * delta
			# 돌진 중 스프라이트 애니메이션
			if sprite and attack_frames_count > 0:
				sprite.frame = int((skill_timer - 0.4) * 12.0) % attack_frames_count
			# 돌진 경로 충돌 타격
			if not has_skill_hit and is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) <= 75.0:
				has_skill_hit = true
				player_node.take_damage(stats.base_attack_power * 0.9)
			# 1.1초 후 돌진 종료
			if skill_timer >= 1.1:
				state = "walk"
				modulate = Color(1, 1, 1, 1)
				if sprite:
					sprite.texture = sprite_texture
					sprite.hframes = frames_count
					sprite.frame = 0
			return

		elif state == "cleave":
			# 2. 전방 도끼 베기 스킬 (Cleave - 사거리 및 위력 대폭 하향 조정)
			skill_timer += delta
			velocity = Vector2.ZERO
			var c_frame = int(skill_timer * 7.0)
			if sprite and c_frame < 7:
				sprite.frame = c_frame
			# 4프레임 타격: 사거리 95px, 데미지 0.85배로 하향
			if c_frame >= 4 and not has_skill_hit:
				has_skill_hit = true
				var facing_dir = -1.0 if sprite and sprite.flip_h else 1.0
				if is_instance_valid(player_node):
					var diff = player_node.global_position - global_position
					# 전방 반원 95px 이내에 있을 때만 피격 판정
					if diff.length() <= 95.0 and (diff.x * facing_dir >= -15.0):
						player_node.take_damage(stats.base_attack_power * 0.85)
			# 모션 종료
			if skill_timer >= 0.85:
				state = "walk"
				modulate = Color(1, 1, 1, 1)
				if sprite:
					sprite.texture = sprite_texture
					sprite.hframes = frames_count
					sprite.frame = 0
			return

		elif state == "slam":
			# 3. 대지 강타 및 지진 충격파 (Earth Slam - 피해량 1.05배로 안정화)
			skill_timer += delta
			velocity = Vector2.ZERO
			var s_frame = int(skill_timer * 6.5)
			if sprite and s_frame < 7:
				sprite.frame = s_frame
			# 4번째 프레임 지면 강타 발생
			if s_frame >= 4 and not has_skill_hit:
				has_skill_hit = true
				_spawn_slam_shockwave()
				if is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) <= 150.0:
					player_node.take_damage(stats.base_attack_power * 1.05)
			if skill_timer >= 1.0:
				state = "walk"
				modulate = Color(1, 1, 1, 1)
				if sprite:
					sprite.texture = sprite_texture
					sprite.hframes = frames_count
					sprite.frame = 0
			return

	if is_instance_valid(player_node):
		var dir = (player_node.global_position - global_position).normalized()
		var dist = global_position.distance_to(player_node.global_position)

		# 보스 스킬 발동 AI 판정
		if is_boss and state == "walk":
			# 스킬 3: 지진 강타 (Earth Slam)
			if boss_slam_cooldown <= 0.0 and dist <= 170.0 and boss_slam_texture:
				state = "slam"
				skill_timer = 0.0
				has_skill_hit = false
				boss_slam_cooldown = 8.0
				modulate = Color(2.5, 1.2, 0.4, 1.0)
				_show_slam_telegraph(150.0, 0.6)
				if sprite:
					sprite.texture = boss_slam_texture
					sprite.hframes = 7
					sprite.frame = 0
					sprite.flip_h = (dir.x < 0)
				return

			# 스킬 2: 전방 도끼 베기 (Cleave) - 발동 거리 90px 이내
			if boss_cleave_cooldown <= 0.0 and dist <= 95.0 and boss_cleave_texture:
				state = "cleave"
				skill_timer = 0.0
				has_skill_hit = false
				boss_cleave_cooldown = 4.5
				modulate = Color(2.2, 0.5, 0.5, 1.0)
				var f_dir = Vector2.LEFT if (dir.x < 0) else Vector2.RIGHT
				_show_cleave_telegraph(f_dir, 95.0, 0.5)
				if sprite:
					sprite.texture = boss_cleave_texture
					sprite.hframes = 7
					sprite.frame = 0
					sprite.flip_h = (dir.x < 0)
				return

			# 스킬 1: 맹렬한 돌진 (Charge)
			if boss_charge_cooldown <= 0.0 and dist >= 140.0:
				state = "charge"
				skill_timer = 0.0
				has_skill_hit = false
				charge_direction = dir
				boss_charge_cooldown = 5.5
				modulate = Color(2.0, 0.3, 0.3, 1.0)
				_show_charge_telegraph(charge_direction, 360.0, 0.4)
				if sprite:
					sprite.texture = boss_charge_texture
					sprite.hframes = attack_frames_count
					sprite.frame = 0
					sprite.flip_h = (charge_direction.x < 0)
				return

		# 일반 기본 공격 모션 판정
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
					var hit_margin = 60.0 if is_boss else 25.0
					if is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) <= attack_range + hit_margin:
						player_node.take_damage(stats.base_attack_power)
		else:
			# 기본 걷기 및 추적 (캐릭터와 물리적으로 걸리거나 엉키지 않고 부드럽게 통과)
			var eff_speed = stats.move_speed * slow_multiplier
			global_position += dir * eff_speed * delta
			if dir.x > 0:
				sprite.flip_h = false
			elif dir.x < 0:
				sprite.flip_h = true

			anim_timer += delta
			if sprite and frames_count > 0:
				sprite.frame = int(anim_timer * 8.0) % frames_count

			# 접촉 데미지 (보스는 거대하므로 65px, 일반 몬스터는 28px)
			var contact_dist = 65.0 if is_boss else 28.0
			if is_instance_valid(player_node) and global_position.distance_to(player_node.global_position) <= contact_dist:
				player_node.take_damage(stats.base_attack_power)

func init_enemy(p_stats: CharacterStats, p_tex: Texture2D, p_frames: int, p_atk_tex: Texture2D = null, p_atk_frames: int = 6, p_atk_range: float = 0.0, p_hurt_tex: Texture2D = null, p_hurt_frames: int = 4, p_death_tex: Texture2D = null, p_death_frames: int = 4, p_is_boss: bool = false, p_cleave_tex: Texture2D = null, p_slam_tex: Texture2D = null) -> void:
	stats = p_stats.duplicate()
	stats.reset_health()
	frames_count = p_frames
	sprite_texture = p_tex
	attack_texture = p_atk_tex
	attack_frames_count = p_atk_frames
	attack_range = p_atk_range
	hurt_texture = p_hurt_tex
	hurt_frames_count = p_hurt_frames
	death_texture = p_death_tex
	death_frames_count = p_death_frames
	state = "walk"
	attack_timer = 0.0
	attack_cooldown = 0.0
	has_damaged = false
	anim_timer = 0.0
	hurt_timer = 0.0
	death_timer = 0.0
	is_dying = false
	is_boss = p_is_boss
	boss_cleave_texture = p_cleave_tex
	boss_slam_texture = p_slam_tex
	boss_charge_texture = p_atk_tex
	boss_charge_cooldown = 3.5
	boss_cleave_cooldown = 2.0
	boss_slam_cooldown = 7.0
	skill_timer = 0.0
	stun_timer = 0.0
	slow_timer = 0.0
	slow_multiplier = 1.0
	modulate = Color(1, 1, 1, 1)
	if is_boss:
		scale = Vector2(3.0, 3.0)
		boss_health_changed.emit(stats.current_health, stats.max_health)
	else:
		scale = Vector2(1.8, 1.8)

	if sprite:
		sprite.texture = sprite_texture
		sprite.hframes = frames_count
		sprite.vframes = 1
		sprite.frame = 0

var is_dying: bool = false

func take_damage(amount: float) -> void:
	if is_dying:
		return
	var died = stats.take_damage(amount)
	if is_boss:
		boss_health_changed.emit(stats.current_health, stats.max_health)
	# Flash white
	modulate = Color(3.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)

	if died:
		is_dying = true
		call_deferred("start_death")
	else:
		# 피격 모션 (설정되어 있는 경우)
		# 보스는 공격/스킬 시전 중 피격 모션으로 캔슬되지 않도록 슈퍼아머(Super Armor) 적용
		if hurt_texture and sprite:
			if not is_boss or (state != "attack" and state != "cleave" and state != "charge" and state != "slam"):
				state = "hurt"
				hurt_timer = 0.2
				sprite.texture = hurt_texture
				sprite.hframes = hurt_frames_count
				sprite.frame = 0

func start_death() -> void:
	if death_texture and sprite:
		state = "death"
		death_timer = 0.0
		sprite.texture = death_texture
		sprite.hframes = death_frames_count
		sprite.frame = 0
	else:
		finish_death()

func finish_death() -> void:
	if is_boss:
		boss_died.emit()
	var parent_node = get_parent()
	if parent_node:
		var gem = ObjectPool.spawn(gem_scene, parent_node) as ExpGem
		if gem:
			gem.init_gem(stats.exp_reward, global_position)
		if parent_node.has_method("add_score"):
			parent_node.add_score(stats.score_reward)

		# 자석 아이템 드랍: 스켈레톤 이상 몬스터만 0.5% 확률로 드랍 (후반 대량 스폰 시 과도한 드랍 방지)
		# 슬라임(1 EXP), 박쥐(2 EXP)는 드랍하지 않으며, 스켈레톤(4 EXP) 이상부터 드랍
		if stats.exp_reward >= 4 and randf() < 0.005:
			var magnet = ObjectPool.spawn(magnet_scene, parent_node)
			if magnet and magnet.has_method("init_item"):
				magnet.init_item(global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12)))

	ObjectPool.recycle(self)

func _spawn_slam_shockwave() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	# 지면 강타 충격파 원형 링 이펙트
	var ring = Line2D.new()
	ring.width = 6.0
	ring.default_color = Color(2.5, 0.8, 0.2, 0.9)
	var pts: PackedVector2Array = []
	for i in range(25):
		var th = i * TAU / 24.0
		pts.append(Vector2(cos(th), sin(th)))
	ring.points = pts
	ring.global_position = global_position + Vector2(0, 15)
	ring.scale = Vector2(10, 10)
	parent_node.add_child(ring)
	var tw = ring.create_tween()
	tw.parallel().tween_property(ring, "scale", Vector2(195, 195), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(ring.queue_free)

# ---------------- 보스 스킬 장판(피격 예고 범위) 표시 함수 ----------------
func _show_charge_telegraph(dir_vec: Vector2, length: float, dur: float) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var line = Line2D.new()
	line.width = 45.0
	line.default_color = Color(1.0, 0.15, 0.15, 0.35)
	line.add_point(Vector2.ZERO)
	line.add_point(dir_vec * length)
	line.global_position = global_position
	parent_node.add_child(line)
	var tw = line.create_tween()
	tw.tween_property(line, "default_color:a", 0.75, dur)
	tw.chain().tween_callback(line.queue_free)

func _show_cleave_telegraph(f_dir: Vector2, radius: float, dur: float) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	# 전방 부채꼴 예고선
	var fan = Line2D.new()
	fan.width = 4.0
	fan.default_color = Color(1.0, 0.2, 0.2, 0.8)
	var base_angle = f_dir.angle()
	var pts: PackedVector2Array = [Vector2.ZERO]
	for i in range(13):
		var ang = base_angle - PI/2.2 + (i / 12.0) * (PI * 0.9)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	pts.append(Vector2.ZERO)
	fan.points = pts
	fan.global_position = global_position
	parent_node.add_child(fan)
	var tw = fan.create_tween()
	tw.tween_property(fan, "modulate:a", 1.0, dur * 0.5)
	tw.tween_property(fan, "modulate:a", 0.0, dur * 0.5)
	tw.chain().tween_callback(fan.queue_free)

func _show_slam_telegraph(radius: float, dur: float) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	# 지면 강타 붉은 원형 위험 장판
	var circle = Line2D.new()
	circle.width = 5.0
	circle.default_color = Color(1.0, 0.25, 0.1, 0.85)
	var pts: PackedVector2Array = []
	for i in range(25):
		var ang = i * TAU / 24.0
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	circle.points = pts
	circle.global_position = global_position + Vector2(0, 15)
	circle.scale = Vector2(0.2, 0.2)
	parent_node.add_child(circle)
	var tw = circle.create_tween()
	tw.parallel().tween_property(circle, "scale", Vector2(1.0, 1.0), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(circle, "modulate:a", 0.2, dur * 0.4)
	tw.tween_property(circle, "modulate:a", 1.0, dur * 0.6)
	tw.chain().tween_callback(circle.queue_free)
