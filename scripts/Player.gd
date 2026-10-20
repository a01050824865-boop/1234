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
	func _draw() -> void:
		var center = Vector2(0, -2)
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

	var current_speed = stats.move_speed * (1.0 + skills["speed"] * 0.15)

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
		var l_interval = max(0.6, 2.2 - skills["lightning"] * 0.3)
		if lightning_timer >= l_interval:
			lightning_timer = 0.0
			cast_lightning()

	# Auto Attack: Arrows
	if skills["arrows"] > 0:
		arrows_timer += delta
		var a_interval = max(0.7, 1.8 - skills["arrows"] * 0.22)
		if arrows_timer >= a_interval:
			arrows_timer = 0.0
			fire_arrows()

	# Passive Regen
	if skills["regen"] > 0:
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			stats.heal(skills["regen"] * 3.0)
			emit_signal("health_changed", stats.current_health, stats.max_health)

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
		orbit_angle += delta * 3.8
		for i in range(active_orbits.size()):
			var orb = active_orbits[i]
			if is_instance_valid(orb):
				var angle = orbit_angle + (i * TAU / active_orbits.size())
				orb.global_position = global_position + Vector2(cos(angle), sin(angle)) * 75.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Q or event.keycode == KEY_Q:
			try_activate_shield()

func try_activate_shield() -> void:
	if skills.get("shield", 0) <= 0:
		return
	if shield_cooldown_timer > 0.0 or shield_timer > 0.0 or stats.current_health <= 0:
		return
	var dur = 2.5 + (skills["shield"] - 1) * 1.0
	shield_timer = dur
	shield_cooldown_timer = SHIELD_COOLDOWN
	if shield_visual:
		shield_visual.visible = true
	spawn_shield_popup("🛡️ 수호 방패 전개! (%.1f초)" % dur)

func spawn_shield_popup(txt: String) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var lbl = Label.new()
	lbl.text = txt
	lbl.global_position = global_position + Vector2(-65, -40)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 1.0))
	parent_node.add_child(lbl)
	var tw = lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 25, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

func spawn_shield_block_effect() -> void:
	if shield_visual:
		var tw = create_tween()
		shield_visual.modulate = Color(2.5, 2.5, 1.5, 1.0)
		tw.tween_property(shield_visual, "modulate", Color(1, 1, 1, 1), 0.12)
	var parent_node = get_parent()
	if parent_node:
		var lbl = Label.new()
		lbl.text = "🛡️ BLOCK!"
		lbl.global_position = global_position + Vector2(-28, -32)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
		parent_node.add_child(lbl)
		var tw = lbl.create_tween()
		tw.tween_property(lbl, "position:y", lbl.position.y - 20, 0.5)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(lbl.queue_free)

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
	var targets = min(enemies.size(), skills["lightning"])
	for i in range(targets):
		var en = enemies[i]
		if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
			var dmg = stats.base_attack_power * 1.8 * (1.0 + skills["lightning"] * 0.3)
			en.take_damage(dmg)
			var l_effect = ObjectPool.spawn(lightning_scene, parent_node) as LightningEffect
			if l_effect:
				l_effect.init_lightning(en.global_position + Vector2(0, -10))

func fire_arrows() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return

	var count = 4 + skills["arrows"] * 2
	var dmg = stats.base_attack_power * 0.65 * (1.0 + skills["arrows"] * 0.2)
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2(cos(angle), sin(angle))
		var arr = ObjectPool.spawn(arrow_scene, parent_node) as ArrowProjectile
		if arr:
			arr.init_arrow(global_position, dir, dmg)

func update_orbit_shields() -> void:
	for orb in active_orbits:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbits.clear()

	if skills["orbit"] > 0:
		var count = skills["orbit"] + 1
		for i in range(count):
			var orb = orbit_scene.instantiate()
			orb.damage = stats.base_attack_power * 0.75 * (1.0 + skills["orbit"] * 0.25)
			get_parent().call_deferred("add_child", orb)
			active_orbits.append(orb)

func take_damage(amount: float) -> void:
	if stats.current_health <= 0:
		return
	if shield_timer > 0.0:
		spawn_shield_block_effect()
		return
	if invincible_timer > 0:
		return
	invincible_timer = 0.5
	hurt_anim_timer = 0.2
	var died = stats.take_damage(amount)
	emit_signal("health_changed", stats.current_health, stats.max_health)
	if died:
		sprite.texture = tex_death
		sprite.hframes = 4
		sprite.vframes = 1
		anim_player.play("death")
		emit_signal("player_died")

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
		stats.max_health += 25.0
		stats.heal(35.0)
		emit_signal("health_changed", stats.current_health, stats.max_health)