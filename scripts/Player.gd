class_name Player
extends CharacterBody2D

signal health_changed(curr: float, max_hp: float)
signal exp_changed(curr: int, max_exp: int)
signal level_up_triggered(level: int)
signal player_died

@export var stats: CharacterStats

var level: int = 1
var current_exp: int = 0
var max_exp: int = 10

var skills = {
	"slash": 1,
	"orbit": 0,
	"lightning": 0,
	"arrows": 0,
	"speed": 0,
	"regen": 0,
	"shield": 1
}

var slash_timer: float = 0.0
var lightning_timer: float = 0.0
var arrows_timer: float = 0.0
var regen_timer: float = 0.0
var invincible_timer: float = 0.0
var orbit_angle: float = 0.0

var shield_timer: float = 0.0
var shield_cooldown_timer: float = 0.0
const SHIELD_COOLDOWN: float = 15.0
var shield_visual: Node2D = null

# 각성 특수 변수
var speed_trail_timer: float = 0.0
var has_revived: bool = false
var titan_awakened: bool = false
var health_awakening_level: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var slash_scene = preload("res://scenes/SlashProjectile.tscn")
var orbit_scene = preload("res://scenes/OrbitProjectile.tscn")
var arrow_scene = preload("res://scenes/ArrowProjectile.tscn")
var lightning_scene = load("res://scenes/LightningEffect.tscn")

var tex_idle = preload("res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Idle.png")
var tex_walk = preload("res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Walk.png")
var tex_attack = preload("res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Attack01.png")
var tex_death = preload("res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Death.png")
var tex_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Hurt.png")

var attack_anim_timer: float = 0.0
var hurt_anim_timer: float = 0.0
var active_orbits: Array[Node2D] = []

var last_move_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if not stats:
		stats = CharacterStats.new()
	stats.reset_health()
	emit_signal("health_changed", stats.current_health, stats.max_health)
	emit_signal("exp_changed", current_exp, max_exp)
	update_orbit_shields()
	setup_shield_barrier()

class ShieldCircleVisual extends Node2D:
	var is_awakened: bool = false
	
	func _draw() -> void:
		var center = Vector2(0, -2)
		if is_awakened:
			var radius = 34.0
			# 1. 황금 성역 내부 오라
			draw_circle(center, radius, Color(1.0, 0.85, 0.2, 0.25))
			draw_circle(center + Vector2(-3, -5), radius * 0.5, Color(1.0, 0.95, 0.5, 0.2))
			# 2. 황금 룬 문양 네온 라인
			draw_arc(center, radius, 0, TAU, 64, Color(1.0, 0.9, 0.3, 0.95), 2.8, true)
			# 3. 외부 광배 링
			draw_arc(center, radius + 3.0, 0, TAU, 64, Color(1.0, 0.7, 0.1, 0.5), 1.5, true)
			# 4. 상단 반사광 호
			draw_arc(center, radius - 3.0, -PI * 0.85, -PI * 0.25, 32, Color(1.0, 1.0, 1.0, 0.8), 2.0, true)
		else:
			var radius = 27.0
			# 1. 내부 반투명 푸른색 에너지 채우기
			draw_circle(center, radius, Color(0.25, 0.75, 1.0, 0.22))
			# 2. 내부 상단 밝은 구체 입체감
			draw_circle(center + Vector2(-3, -5), radius * 0.5, Color(0.65, 0.9, 1.0, 0.16))
			# 3. 외곽 원형 보호막 네온 라인
			draw_arc(center, radius, 0, TAU, 48, Color(0.4, 0.88, 1.0, 0.9), 2.2, true)
			# 4. 외부 미세 발광 링
			draw_arc(center, radius + 2.2, 0, TAU, 48, Color(0.7, 0.95, 1.0, 0.35), 1.0, true)
			# 5. 상단 반사광 호
			draw_arc(center, radius - 2.5, -PI * 0.85, -PI * 0.25, 24, Color(1.0, 1.0, 1.0, 0.65), 1.6, true)

func setup_shield_barrier() -> void:
	shield_visual = ShieldCircleVisual.new()
	shield_visual.name = "ShieldBarrier"
	shield_visual.visible = false
	shield_visual.z_index = 3
	add_child(shield_visual)

func _physics_process(delta: float) -> void:
	if stats.current_health <= 0:
		return

	# 8-Directional Movement
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1.0
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1.0

	var speed_lvl = skills["speed"]
	var speed_mult = 1.75 if speed_lvl >= 5 else (1.0 + speed_lvl * 0.15)
	var current_speed = stats.move_speed * speed_mult

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		last_move_direction = input_vector
		velocity = input_vector * current_speed
		if input_vector.x > 0:
			sprite.flip_h = false
		elif input_vector.x < 0:
			sprite.flip_h = true
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 신속의 장화 각성: 이동 중 잔상 및 바람 칼날 생성
	if speed_lvl >= 5 and velocity != Vector2.ZERO:
		speed_trail_timer += delta
		if speed_trail_timer >= 0.08:
			speed_trail_timer = 0.0
			_spawn_speed_ghost_and_wind()

	# Animation & Sprite State Management
	if hurt_anim_timer > 0.0:
		hurt_anim_timer -= delta
		if sprite.texture != tex_hurt:
			sprite.texture = tex_hurt
			sprite.hframes = 4
			sprite.vframes = 1
		anim_player.play("hurt")
	elif attack_anim_timer > 0.0:
		attack_anim_timer -= delta
		if sprite.texture != tex_attack:
			sprite.texture = tex_attack
			sprite.hframes = 7
			sprite.vframes = 1
		anim_player.play("attack")
	else:
		if velocity != Vector2.ZERO:
			if sprite.texture != tex_walk:
				sprite.texture = tex_walk
				sprite.hframes = 8
				sprite.vframes = 1
			anim_player.play("walk")
		else:
			if sprite.texture != tex_idle:
				sprite.texture = tex_idle
				sprite.hframes = 6
				sprite.vframes = 1
			anim_player.play("idle")

	# Process Timers & Skills
	if invincible_timer > 0:
		invincible_timer -= delta
		modulate.a = 0.5 if int(invincible_timer * 15) % 2 == 0 else 1.0
	else:
		# 타이탄 각성 시 은은한 황금/강철 광채 유지
		if titan_awakened:
			modulate = Color(1.2, 1.15, 0.9, 1.0)
		else:
			modulate.a = 1.0

	# Auto Attack: Slash
	if skills["slash"] > 0:
		slash_timer += delta
		var is_awakened = skills["slash"] >= 5
		var base_interval = stats.attack_interval / (1.0 + (skills["slash"] - 1) * 0.18)
		var interval = base_interval * 0.85 if is_awakened else base_interval
		if slash_timer >= interval:
			slash_timer = 0.0
			fire_slash()

	# Auto Attack: Lightning
	if skills["lightning"] > 0:
		lightning_timer += delta
		var is_l_awakened = skills["lightning"] >= 5
		var l_interval = (max(0.6, 2.2 - skills["lightning"] * 0.3)) * (0.85 if is_l_awakened else 1.0)
		if lightning_timer >= l_interval:
			lightning_timer = 0.0
			cast_lightning()

	# Auto Attack: Arrows
	if skills["arrows"] > 0:
		arrows_timer += delta
		var is_arr_awakened = skills["arrows"] >= 5
		var a_interval = (max(0.7, 1.8 - skills["arrows"] * 0.22)) * (0.85 if is_arr_awakened else 1.0)
		if arrows_timer >= a_interval:
			arrows_timer = 0.0
			fire_arrows()

	# Passive Regen
	if skills["regen"] > 0:
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			var is_regen_awakened = skills["regen"] >= 5
			var heal_amt = 5.0 if is_regen_awakened else (skills["regen"] * 3.0)
			stats.heal(heal_amt)
			emit_signal("health_changed", stats.current_health, stats.max_health)
			if is_regen_awakened:
				_spawn_phoenix_heal_fx()

	# Process Shield Active Duration & Cooldown
	if shield_timer > 0.0:
		shield_timer -= delta
		if shield_visual:
			shield_visual.visible = true
			var pulse = 1.0 + sin(shield_timer * 14.0) * 0.06
			shield_visual.scale = Vector2(pulse, pulse)
		if shield_timer <= 0.0:
			shield_timer = 0.0
			if shield_visual:
				shield_visual.visible = false

	if shield_cooldown_timer > 0.0:
		shield_cooldown_timer -= delta
		if shield_cooldown_timer <= 0.0:
			shield_cooldown_timer = 0.0

	# Update Orbit Shields
	if skills["orbit"] > 0 and active_orbits.size() > 0:
		var is_orb_awakened = skills["orbit"] >= 5
		var orb_rot_speed = 5.7 if is_orb_awakened else 3.8
		var orb_radius = 95.0 if is_orb_awakened else 75.0
		orbit_angle += delta * orb_rot_speed
		for i in range(active_orbits.size()):
			var orb = active_orbits[i]
			if is_instance_valid(orb):
				var angle = orbit_angle + (i * TAU / active_orbits.size())
				orb.global_position = global_position + Vector2(cos(angle), sin(angle)) * orb_radius

func _spawn_speed_ghost_and_wind() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	# 잔상 고스트 이펙트
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.modulate = Color(0.3, 0.9, 1.0, 0.5)
	parent_node.add_child(ghost)
	var tw = ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(ghost.queue_free)

	# 궤적 바람 칼날 피해 & 슬로우
	var enemies = get_tree().get_nodes_in_group("enemies")
	for en in enemies:
		if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
			if en.global_position.distance_to(global_position) <= 45.0:
				en.take_damage(stats.base_attack_power * 0.3)
				if en.has_method("apply_slow"):
					en.apply_slow(0.6, 1.2)

func _spawn_phoenix_heal_fx() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var cross = Line2D.new()
	cross.width = 3.0
	cross.default_color = Color(1.0, 0.4, 0.8, 0.9)
	cross.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(0, 0), Vector2(0, -10), Vector2(0, 6)])
	cross.global_position = global_position + Vector2(0, -32)
	parent_node.add_child(cross)
	var tw = cross.create_tween()
	tw.parallel().tween_property(cross, "position:y", cross.position.y - 18, 0.5)
	tw.parallel().tween_property(cross, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(cross.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Q or event.keycode == KEY_Q:
			try_activate_shield()

func try_activate_shield() -> void:
	var s_lvl = skills.get("shield", 0)
	if s_lvl <= 0:
		return
	if shield_cooldown_timer > 0.0 or shield_timer > 0.0 or stats.current_health <= 0:
		return
		
	var is_shield_awakened = s_lvl >= 5
	var dur = 6.5 if is_shield_awakened else (2.5 + (s_lvl - 1) * 1.0)
	var cd = 10.0 if is_shield_awakened else SHIELD_COOLDOWN
	
	shield_timer = dur
	shield_cooldown_timer = cd
	
	if shield_visual:
		shield_visual.is_awakened = is_shield_awakened
		shield_visual.queue_redraw()
		shield_visual.visible = true
		
	if is_shield_awakened:
		spawn_shield_popup("👑 절대성역 전개! (%.1f초)" % dur)
		# 화면 내 모든 탄환 즉시 소멸
		var enemy_bullets = get_tree().get_nodes_in_group("enemy_projectiles")
		for b in enemy_bullets:
			if is_instance_valid(b):
				b.queue_free()
	else:
		spawn_shield_popup("🛡️ 수호 방패 전개! (%.1f초)" % dur)

func spawn_shield_popup(txt: String) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var lbl = Label.new()
	lbl.text = txt
	lbl.global_position = global_position + Vector2(-65, -40)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if skills.get("shield", 0) >= 5 else Color(0.4, 0.9, 1.0))
	parent_node.add_child(lbl)
	var tw = lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 25, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

func spawn_shield_block_effect(enemy_attacker: Node = null, damage_blocked: float = 0.0) -> void:
	if shield_visual:
		var tw = create_tween()
		shield_visual.modulate = Color(3.0, 2.5, 1.2, 1.0) if skills.get("shield", 0) >= 5 else Color(2.5, 2.5, 1.5, 1.0)
		tw.tween_property(shield_visual, "modulate", Color(1, 1, 1, 1), 0.12)
		
	var parent_node = get_parent()
	if parent_node:
		var lbl = Label.new()
		var is_shield_awakened = skills.get("shield", 0) >= 5
		lbl.text = "👑 REFLECT!" if is_shield_awakened else "🛡️ BLOCK!"
		lbl.global_position = global_position + Vector2(-28, -32)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0) if is_shield_awakened else Color(1.0, 0.9, 0.4, 1.0))
		parent_node.add_child(lbl)
		var tw = lbl.create_tween()
		tw.tween_property(lbl, "position:y", lbl.position.y - 20, 0.5)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(lbl.queue_free)
		
	# 각성 특성: 피격 피해 100% 반사 리플렉트
	if skills.get("shield", 0) >= 5 and is_instance_valid(enemy_attacker) and enemy_attacker.has_method("take_damage"):
		var ref_dmg = max(damage_blocked, stats.base_attack_power * 1.5)
		enemy_attacker.take_damage(ref_dmg)

func fire_slash() -> void:
	attack_anim_timer = 0.35
	var parent_node = get_parent()
	if not parent_node:
		return

	var mouse_pos = get_global_mouse_position()
	var attack_dir = (mouse_pos - global_position).normalized()
	if attack_dir == Vector2.ZERO:
		attack_dir = last_move_direction if last_move_direction != Vector2.ZERO else Vector2.RIGHT

	var slash = ObjectPool.spawn(slash_scene, parent_node) as SlashProjectile
	if slash:
		var lvl = skills["slash"]
		var is_awakened = lvl >= 5
		var spd = 580.0 if is_awakened else 420.0
		var life = 1.3 if is_awakened else 0.75
		var dmg = stats.base_attack_power * (1.0 + (lvl - 1) * 0.45) * 1.85 if is_awakened else stats.base_attack_power * (1.0 + (lvl - 1) * 0.35)
		var pierce_count = 20 if is_awakened else (5 + lvl * 2)
		slash.init_slash(global_position, attack_dir, dmg, pierce_count, spd, life, is_awakened)

func cast_lightning() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var parent_node = get_parent()
	if not parent_node:
		return

	enemies.shuffle()
	var is_awakened = skills["lightning"] >= 5
	var targets_count = 8 if is_awakened else min(enemies.size(), skills["lightning"])
	var targets = min(enemies.size(), targets_count)
	
	var base_dmg = stats.base_attack_power * 1.8 * (1.0 + skills["lightning"] * 0.3)
	var dmg = base_dmg * 2.2 if is_awakened else base_dmg

	for i in range(targets):
		var en = enemies[i]
		if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
			en.take_damage(dmg)
			var l_effect = ObjectPool.spawn(lightning_scene, parent_node)
			if l_effect and l_effect.has_method("init_lightning"):
				l_effect.init_lightning(en.global_position + Vector2(0, -10), is_awakened, dmg)

func fire_arrows() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return

	var is_awakened = skills["arrows"] >= 5
	var count = 24 if is_awakened else (4 + skills["arrows"] * 2)
	var dmg = stats.base_attack_power * 0.65 * (1.0 + skills["arrows"] * 0.2)
	if is_awakened:
		dmg *= 1.6

	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2(cos(angle), sin(angle))
		var arr = ObjectPool.spawn(arrow_scene, parent_node) as ArrowProjectile
		if arr:
			arr.init_arrow(global_position, dir, dmg, 520.0 if is_awakened else 460.0, 1.4 if is_awakened else 1.2, is_awakened)

func update_orbit_shields() -> void:
	for orb in active_orbits:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbits.clear()

	if skills["orbit"] > 0:
		var is_awakened = skills["orbit"] >= 5
		var count = 6 if is_awakened else (skills["orbit"] + 1)
		for i in range(count):
			var orb = orbit_scene.instantiate()
			orb.damage = stats.base_attack_power * 0.75 * (1.0 + skills["orbit"] * 0.25) * (1.8 if is_awakened else 1.0)
			if orb.has_method("set_awakened"):
				orb.set_awakened(is_awakened)
			get_parent().call_deferred("add_child", orb)
			active_orbits.append(orb)

func take_damage(amount: float) -> void:
	if stats.current_health <= 0:
		return
	if shield_timer > 0.0:
		spawn_shield_block_effect(null, amount)
		return
	if invincible_timer > 0:
		return
		
	# 신속의 장화 각성: 25% 확률 완전 회피
	if skills["speed"] >= 5 and randf() < 0.25:
		_spawn_dodge_text()
		return

	# 거인의 심장 각성: 고정 데미지 10 감소 방어막
	var final_amount = amount
	if titan_awakened:
		final_amount = max(1.0, final_amount - 10.0)

	invincible_timer = 0.5
	hurt_anim_timer = 0.2
	var died = stats.take_damage(final_amount)
	emit_signal("health_changed", stats.current_health, stats.max_health)
	
	if died:
		# 성스러운 재생 각성: 1회 불사조 부활 기믹
		if skills["regen"] >= 5 and not has_revived:
			has_revived = true
			_trigger_phoenix_revive()
			return

		sprite.texture = tex_death
		sprite.hframes = 4
		sprite.vframes = 1
		anim_player.play("death")
		emit_signal("player_died")

func _spawn_dodge_text() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var lbl = Label.new()
	lbl.text = "💨 MISS!"
	lbl.global_position = global_position + Vector2(-25, -30)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))
	parent_node.add_child(lbl)
	var tw = lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 20, 0.45)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(lbl.queue_free)

func _trigger_phoenix_revive() -> void:
	stats.current_health = stats.max_health * 0.5
	invincible_timer = 2.5
	emit_signal("health_changed", stats.current_health, stats.max_health)
	
	var parent_node = get_parent()
	if parent_node:
		var lbl = Label.new()
		lbl.text = "💖 불사조의 가호로 부활!"
		lbl.global_position = global_position + Vector2(-80, -45)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.7, 1.0))
		parent_node.add_child(lbl)
		var tw = lbl.create_tween()
		tw.tween_property(lbl, "position:y", lbl.position.y - 30, 1.0)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.5)
		tw.chain().tween_callback(lbl.queue_free)

		# 주변 적 넉백 & 광역 화염 피해
		var enemies = get_tree().get_nodes_in_group("enemies")
		for en in enemies:
			if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
				var dist = en.global_position.distance_to(global_position)
				if dist <= 160.0:
					en.take_damage(stats.base_attack_power * 2.0)
					var push_dir = (en.global_position - global_position).normalized()
					en.global_position += push_dir * 80.0

func gain_exp(amount: int) -> void:
	current_exp += amount
	if current_exp >= max_exp:
		current_exp -= max_exp
		level += 1
		max_exp = int(max_exp * 1.45 + 5)
		emit_signal("level_up_triggered", level)
	emit_signal("exp_changed", current_exp, max_exp)

func upgrade_skill(skill_id: String) -> void:
	if skills.has(skill_id):
		skills[skill_id] += 1
		if skill_id == "orbit":
			update_orbit_shields()
	elif skill_id == "health":
		health_awakening_level += 1
		if health_awakening_level == 5:
			titan_awakened = true
			stats.max_health += 150.0
			stats.heal(stats.max_health)
		else:
			stats.max_health += 25.0
			stats.heal(35.0)
		emit_signal("health_changed", stats.current_health, stats.max_health)
