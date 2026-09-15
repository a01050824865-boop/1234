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
	"regen": 0
}

var slash_timer: float = 0.0
var lightning_timer: float = 0.0
var arrows_timer: float = 0.0
var regen_timer: float = 0.0
var invincible_timer: float = 0.0
var orbit_angle: float = 0.0

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
		var interval = stats.attack_interval / (1.0 + (skills["slash"] - 1) * 0.18)
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

	# Update Orbit Shields
	if skills["orbit"] > 0 and active_orbits.size() > 0:
		orbit_angle += delta * 3.8
		for i in range(active_orbits.size()):
			var orb = active_orbits[i]
			if is_instance_valid(orb):
				var angle = orbit_angle + (i * TAU / active_orbits.size())
				orb.global_position = global_position + Vector2(cos(angle), sin(angle)) * 75.0

func fire_slash() -> void:
	attack_anim_timer = 0.35
	var slash = slash_scene.instantiate()
	slash.global_position = global_position
	
	var mouse_pos = get_global_mouse_position()
	var attack_dir = (mouse_pos - global_position).normalized()
	if attack_dir == Vector2.ZERO:
		attack_dir = last_move_direction if last_move_direction != Vector2.ZERO else Vector2.RIGHT
	
	slash.direction_vector = attack_dir
	slash.damage = stats.base_attack_power * (1.0 + (skills["slash"] - 1) * 0.35)
	slash.pierce = 2 + skills["slash"]
	get_parent().add_child(slash)

func cast_lightning() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	enemies.shuffle()
	var targets = min(enemies.size(), skills["lightning"])
	for i in range(targets):
		var en = enemies[i]
		if is_instance_valid(en) and en.has_method("take_damage"):
			var dmg = stats.base_attack_power * 1.8 * (1.0 + skills["lightning"] * 0.3)
			en.take_damage(dmg)
			var l_effect = lightning_scene.instantiate()
			l_effect.global_position = en.global_position + Vector2(0, -10)
			get_parent().add_child(l_effect)

func fire_arrows() -> void:
	var count = 4 + skills["arrows"] * 2
	var dmg = stats.base_attack_power * 0.65 * (1.0 + skills["arrows"] * 0.2)
	for i in range(count):
		var angle = (TAU / count) * i
		var arr = arrow_scene.instantiate()
		arr.global_position = global_position
		arr.direction_vector = Vector2(cos(angle), sin(angle))
		arr.damage = dmg
		get_parent().add_child(arr)

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
	if invincible_timer > 0 or stats.current_health <= 0:
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