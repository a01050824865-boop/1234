import os

svg_content = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" rx="20" fill="#3b82f6"/><polygon points="64,25 105,95 23,95" fill="#ffffff"/></svg>'
with open("icon.svg", "w", encoding="utf-8") as f:
    f.write(svg_content)
print("icon.svg created successfully")

def create_godot_project():
    os.makedirs("scripts", exist_ok=True)
    os.makedirs("scenes", exist_ok=True)
    os.makedirs("resources", exist_ok=True)

    # 1. project.godot
    project_godot = """config_version=5

[application]

config/name="Survivor Knight"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.3", "4.4", "4.5", "4.6", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":87,"key_label":0,"unicode":119,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194320,"physical_keycode":4194320,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":83,"key_label":0,"unicode":115,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194322,"physical_keycode":4194322,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":65,"key_label":0,"unicode":97,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":4194319,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":68,"key_label":0,"unicode":100,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":4194321,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}

[layer_names]

2d_physics/layer_1="Player"
2d_physics/layer_2="Enemy"
2d_physics/layer_3="PlayerAttack"
2d_physics/layer_4="Gem"
"""
    with open("project.godot", "w", encoding="utf-8") as f:
        f.write(project_godot.strip())

    # 2. CharacterStats.gd (Custom Resource for friendly & enemy stat management)
    char_stats_gd = """class_name CharacterStats
extends Resource

@export var character_name: String = "Knight"
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var move_speed: float = 180.0
@export var base_attack_power: float = 25.0
@export var attack_interval: float = 0.8
@export var exp_reward: int = 1
@export var magnet_radius: float = 120.0

func reset_health() -> void:
	current_health = max_health

func take_damage(amount: float) -> bool:
	current_health = max(0.0, current_health - amount)
	return current_health <= 0.0

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
"""
    with open("scripts/CharacterStats.gd", "w", encoding="utf-8") as f:
        f.write(char_stats_gd.strip())

    # 3. Player.gd (WASD movement, Sprite Animation, Health, Exp & Level up)
    player_gd = """class_name Player
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
@onready var magnet_area: Area2D = $MagnetArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var slash_scene = preload("res://scenes/SlashProjectile.tscn")
var orbit_scene = preload("res://scenes/OrbitProjectile.tscn")
var arrow_scene = preload("res://scenes/ArrowProjectile.tscn")

var active_orbits: Array[Node2D] = []

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

	# WASD Movement
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
		velocity = input_vector * current_speed
		if input_vector.x > 0:
			sprite.flip_h = false
		elif input_vector.x < 0:
			sprite.flip_h = true
		anim_player.play("walk")
	else:
		velocity = Vector2.ZERO
		anim_player.play("idle")

	move_and_slide()

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
	var slash = slash_scene.instantiate()
	slash.global_position = global_position
	slash.direction = -1.0 if sprite.flip_h else 1.0
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
	var died = stats.take_damage(amount)
	emit_signal("health_changed", stats.current_health, stats.max_health)
	if died:
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
"""
    with open("scripts/Player.gd", "w", encoding="utf-8") as f:
        f.write(player_gd.strip())

    # 4. Enemy.gd (Monster AI, chasing Knight, damage & EXP Gem dropping)
    enemy_gd = """class_name Enemy
extends CharacterBody2D

@export var stats: CharacterStats
@export var frames_count: int = 8

var player_node: Node2D = null
var gem_scene = preload("res://scenes/ExpGem.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("enemies")
	if not stats:
		stats = CharacterStats.new()
	stats.reset_health()
	player_node = get_tree().get_first_node_in_group("player")
	if anim_player and anim_player.has_animation("walk"):
		anim_player.play("walk")

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

		move_and_slide()

		# Attack Player on contact
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
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
	queue_free()
"""
    with open("scripts/Enemy.gd", "w", encoding="utf-8") as f:
        f.write(enemy_gd.strip())

    # 5. ExpGem.gd
    gem_gd = """class_name ExpGem
extends Area2D

@export var exp_amount: int = 1
var player: Player = null
var is_attracted: bool = false
var speed: float = 400.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player

	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= player.stats.magnet_radius or is_attracted:
			is_attracted = true
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.gain_exp(exp_amount)
		queue_free()
"""
    with open("scripts/ExpGem.gd", "w", encoding="utf-8") as f:
        f.write(gem_gd.strip())

    # 6. SlashProjectile.gd, OrbitProjectile.gd, ArrowProjectile.gd
    slash_proj_gd = """class_name SlashProjectile
extends Area2D

var direction: float = 1.0
var damage: float = 25.0
var pierce: int = 3
var speed: float = 420.0
var life_time: float = 0.75

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if direction < 0:
		scale.x = -1.0

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		pierce -= 1
		if pierce <= 0:
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		pierce -= 1
		if pierce <= 0:
			queue_free()
"""
    with open("scripts/SlashProjectile.gd", "w", encoding="utf-8") as f:
        f.write(slash_proj_gd.strip())

    orbit_proj_gd = """class_name OrbitProjectile
extends Area2D

var damage: float = 20.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
"""
    with open("scripts/OrbitProjectile.gd", "w", encoding="utf-8") as f:
        f.write(orbit_proj_gd.strip())

    arrow_proj_gd = """class_name ArrowProjectile
extends Area2D

var direction_vector: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var speed: float = 460.0
var life_time: float = 1.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction_vector.angle()

func _physics_process(delta: float) -> void:
	global_position += direction_vector * speed * delta
	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
"""
    with open("scripts/ArrowProjectile.gd", "w", encoding="utf-8") as f:
        f.write(arrow_proj_gd.strip())

    # 7. GameManager.gd (Spawner, UI Controller, Level up modal, Restart)
    game_manager_gd = """class_name GameManager
extends Node2D

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var exp_bar: ProgressBar = $HUD/ExpBar
@onready var exp_label: Label = $HUD/ExpLabel
@onready var hp_label: Label = $HUD/HPLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var levelup_modal: Control = $HUD/LevelUpModal
@onready var cards_container: HBoxContainer = $HUD/LevelUpModal/VBoxContainer/CardsContainer
@onready var gameover_modal: Control = $HUD/GameOverModal
@onready var restart_btn: Button = $HUD/GameOverModal/VBoxContainer/RestartButton

var enemy_scene = preload("res://scenes/Enemy.tscn")

var elapsed_time: float = 0.0
var spawn_timer: float = 0.0

var mob_slime_stats = preload("res://resources/SlimeStats.tres")
var mob_skel_stats = preload("res://resources/SkeletonStats.tres")
var mob_werewolf_stats = preload("res://resources/WerewolfStats.tres")

func _ready() -> void:
	player.add_to_group("player")
	player.health_changed.connect(_on_health_changed)
	player.exp_changed.connect(_on_exp_changed)
	player.level_up_triggered.connect(_on_level_up)
	player.player_died.connect(_on_player_died)
	restart_btn.pressed.connect(_on_restart_pressed)

	levelup_modal.visible = false
	gameover_modal.visible = false

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	elapsed_time += delta
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	timer_label.text = "⏱️ %02d:%02d" % [minutes, seconds]

	# Spawner
	spawn_timer += delta
	var spawn_rate = max(0.3, 1.8 - min(1.4, elapsed_time / 60.0 * 0.35))
	if spawn_timer >= spawn_rate:
		spawn_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var dist = 520.0 + randf() * 100.0
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos

	if elapsed_time > 60.0 and randf() < 0.3:
		enemy.stats = mob_werewolf_stats.duplicate()
	elif elapsed_time > 25.0 and randf() < 0.4:
		enemy.stats = mob_skel_stats.duplicate()
	else:
		enemy.stats = mob_slime_stats.duplicate()

	add_child(enemy)

func _on_health_changed(curr: float, max_hp: float) -> void:
	hp_label.text = "❤️ HP: %d / %d" % [ceil(curr), ceil(max_hp)]

func _on_exp_changed(curr: int, max_exp: int) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = curr
	exp_label.text = "EXP %d / %d" % [curr, max_exp]
	level_label.text = "⭐ LV: %d" % player.level

func _on_level_up(lvl: int) -> void:
	get_tree().paused = true
	levelup_modal.visible = true

	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()

	var all_skills = [
		{"id": "slash", "name": "기사 검기 (Slash)", "desc": "전방으로 관통 검기를 날립니다."},
		{"id": "orbit", "name": "수호 방패 (Orbit)", "desc": "주위를 회전하며 적에게 피해를 줍니다."},
		{"id": "lightning", "name": "낙뢰 폭격 (Lightning)", "desc": "무작위 적에게 번개를 내리꽂습니다."},
		{"id": "arrows", "name": "화살 폭풍 (Arrows)", "desc": "사방으로 화살을 일제 발사합니다."},
		{"id": "speed", "name": "신속의 장화 (Speed)", "desc": "이동 속도가 15% 증가합니다."},
		{"id": "health", "name": "거인의 심장 (Health)", "desc": "최대 체력 +25 & 35 회복"},
		{"id": "regen", "name": "성스러운 재생 (Regen)", "desc": "초당 체력 지속 회복"}
	]
	all_skills.shuffle()

	for i in range(min(3, all_skills.size())):
		var sk = all_skills[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(220, 120)
		btn.text = "%s\\n\\n%s" % [sk["name"], sk["desc"]]
		btn.pressed.connect(func():
			player.upgrade_skill(sk["id"])
			levelup_modal.visible = false
			get_tree().paused = false
		)
		cards_container.add_child(btn)

func _on_player_died() -> void:
	gameover_modal.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
"""
    with open("scripts/GameManager.gd", "w", encoding="utf-8") as f:
        f.write(game_manager_gd.strip())

    # 8. Create Resource stats .tres files
    knight_tres = """[gd_resource type="Resource" script_class="CharacterStats" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/CharacterStats.gd" id="1_stats"]

[resource]
script = ExtResource("1_stats")
character_name = "Knight"
max_health = 100.0
current_health = 100.0
move_speed = 180.0
base_attack_power = 25.0
attack_interval = 0.8
exp_reward = 0
magnet_radius = 120.0
"""
    with open("resources/KnightStats.tres", "w", encoding="utf-8") as f:
        f.write(knight_tres.strip())

    slime_tres = """[gd_resource type="Resource" script_class="CharacterStats" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/CharacterStats.gd" id="1_stats"]

[resource]
script = ExtResource("1_stats")
character_name = "Slime"
max_health = 30.0
current_health = 30.0
move_speed = 95.0
base_attack_power = 10.0
attack_interval = 1.0
exp_reward = 1
magnet_radius = 0.0
"""
    with open("resources/SlimeStats.tres", "w", encoding="utf-8") as f:
        f.write(slime_tres.strip())

    skel_tres = """[gd_resource type="Resource" script_class="CharacterStats" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/CharacterStats.gd" id="1_stats"]

[resource]
script = ExtResource("1_stats")
character_name = "Skeleton"
max_health = 80.0
current_health = 80.0
move_speed = 70.0
base_attack_power = 18.0
attack_interval = 1.0
exp_reward = 3
magnet_radius = 0.0
"""
    with open("resources/SkeletonStats.tres", "w", encoding="utf-8") as f:
        f.write(skel_tres.strip())

    werewolf_tres = """[gd_resource type="Resource" script_class="CharacterStats" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/CharacterStats.gd" id="1_stats"]

[resource]
script = ExtResource("1_stats")
character_name = "Werewolf"
max_health = 250.0
current_health = 250.0
move_speed = 85.0
base_attack_power = 28.0
attack_interval = 1.0
exp_reward = 10
magnet_radius = 0.0
"""
    with open("resources/WerewolfStats.tres", "w", encoding="utf-8") as f:
        f.write(werewolf_tres.strip())

    # 9. Create TSCN Scenes
    # Player.tscn
    player_tscn = """[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/Player.gd" id="1_player"]
[ext_resource type="Resource" path="res://resources/KnightStats.tres" id="2_stats"]
[ext_resource type="Texture2D" path="res://asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight.png" id="3_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 16.0

[sub_resource type="Animation" id="Animation_idle"]
resource_name = "idle"
length = 0.6
loop_mode = 1
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Sprite2D:frame")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.1, 0.2, 0.3, 0.4, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1, 1),
"update": 1,
"values": [0, 1, 2, 3, 4, 5]
}

[sub_resource type="Animation" id="Animation_walk"]
resource_name = "walk"
length = 0.8
loop_mode = 1
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Sprite2D:frame")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1, 1, 1, 1),
"update": 1,
"values": [6, 7, 8, 9, 10, 11, 12, 13]
}

[sub_resource type="AnimationLibrary" id="AnimationLibrary_main"]
_data = {
"idle": SubResource("Animation_idle"),
"walk": SubResource("Animation_walk")
}

[node name="Player" type="CharacterBody2D" groups=["player"]]
collision_layer = 1
collision_mask = 2
script = ExtResource("1_player")
stats = ExtResource("2_stats")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("3_tex")
hframes = 8
vframes = 9

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("CircleShape2D_body")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
"": SubResource("AnimationLibrary_main")
}

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(1.5, 1.5)
position_smoothing_enabled = true
"""
    with open("scenes/Player.tscn", "w", encoding="utf-8") as f:
        f.write(player_tscn.strip())

    # Enemy.tscn
    enemy_tscn = """[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/Enemy.gd" id="1_enemy"]
[ext_resource type="Resource" path="res://resources/SlimeStats.tres" id="2_stats"]
[ext_resource type="Texture2D" path="res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png" id="3_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 14.0

[node name="Enemy" type="CharacterBody2D" groups=["enemies"]]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_enemy")
stats = ExtResource("2_stats")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("3_tex")
hframes = 6

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("CircleShape2D_body")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
"""
    with open("scenes/Enemy.tscn", "w", encoding="utf-8") as f:
        f.write(enemy_tscn.strip())

    # ExpGem.tscn
    gem_tscn = """[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ExpGem.gd" id="1_gem"]

[sub_resource type="CircleShape2D" id="CircleShape2D_gem"]
radius = 12.0

[node name="ExpGem" type="Area2D"]
collision_layer = 8
collision_mask = 1
script = ExtResource("1_gem")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_gem")

[node name="ColorRect" type="ColorRect" parent="."]
offset_left = -5.0
offset_top = -5.0
offset_right = 5.0
offset_bottom = 5.0
color = Color(0.2, 0.75, 1, 1)
"""
    with open("scenes/ExpGem.tscn", "w", encoding="utf-8") as f:
        f.write(gem_tscn.strip())

    # SlashProjectile.tscn
    slash_tscn = """[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/SlashProjectile.gd" id="1_slash"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_slash"]
radius = 16.0
height = 54.0

[node name="SlashProjectile" type="Area2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_slash")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_slash")

[node name="ColorRect" type="ColorRect" parent="."]
offset_left = -6.0
offset_top = -24.0
offset_right = 6.0
offset_bottom = 24.0
color = Color(0.38, 0.64, 0.98, 0.8)
"""
    with open("scenes/SlashProjectile.tscn", "w", encoding="utf-8") as f:
        f.write(slash_tscn.strip())

    # OrbitProjectile.tscn
    orbit_tscn = """[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/OrbitProjectile.gd" id="1_orbit"]

[sub_resource type="CircleShape2D" id="CircleShape2D_orb"]
radius = 12.0

[node name="OrbitProjectile" type="Area2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_orbit")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_orb")

[node name="ColorRect" type="ColorRect" parent="."]
offset_left = -8.0
offset_top = -8.0
offset_right = 8.0
offset_bottom = 8.0
color = Color(0.98, 0.88, 0.28, 1)
"""
    with open("scenes/OrbitProjectile.tscn", "w", encoding="utf-8") as f:
        f.write(orbit_tscn.strip())

    # ArrowProjectile.tscn
    arrow_tscn = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/ArrowProjectile.gd" id="1_arrow"]
[ext_resource type="Texture2D" path="res://asset/Characters01/Arrow(Projectile)/Arrow01(32x32).png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_arr"]
size = Vector2(24, 8)

[node name="ArrowProjectile" type="Area2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_arrow")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_arr")
"""
    with open("scenes/ArrowProjectile.tscn", "w", encoding="utf-8") as f:
        f.write(arrow_tscn.strip())

    # Main.tscn
    main_tscn = """[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/GameManager.gd" id="1_mgr"]
[ext_resource type="PackedScene" path="res://scenes/Player.tscn" id="2_player"]

[node name="Main" type="Node2D"]
script = ExtResource("1_mgr")

[node name="Player" parent="." instance=ExtResource("2_player")]

[node name="HUD" type="CanvasLayer" parent="."]

[node name="ExpBar" type="ProgressBar" parent="HUD"]
anchors_preset = 10
anchor_right = 1.0
offset_left = 20.0
offset_top = 10.0
offset_right = -20.0
offset_bottom = 30.0
grow_horizontal = 2
show_percentage = false

[node name="ExpLabel" type="Label" parent="HUD"]
anchors_preset = 10
anchor_right = 1.0
offset_top = 10.0
offset_bottom = 30.0
grow_horizontal = 2
text = "EXP 0 / 10"
horizontal_alignment = 1
vertical_alignment = 1

[node name="HPLabel" type="Label" parent="HUD"]
offset_left = 20.0
offset_top = 40.0
offset_right = 180.0
offset_bottom = 65.0
text = "❤️ HP: 100 / 100"

[node name="LevelLabel" type="Label" parent="HUD"]
offset_left = 200.0
offset_top = 40.0
offset_right = 320.0
offset_bottom = 65.0
text = "⭐ LV: 1"

[node name="TimerLabel" type="Label" parent="HUD"]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -150.0
offset_top = 40.0
offset_right = -20.0
offset_bottom = 65.0
grow_horizontal = 0
text = "⏱️ 00:00"
horizontal_alignment = 2

[node name="LevelUpModal" type="Control" parent="HUD"]
process_mode = 2
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Background" type="ColorRect" parent="HUD/LevelUpModal"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.75)

[node name="VBoxContainer" type="VBoxContainer" parent="HUD/LevelUpModal"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -350.0
offset_top = -150.0
offset_right = 350.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1

[node name="Title" type="Label" parent="HUD/LevelUpModal/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "⚡ 레벨 업! 스킬 선택 ⚡"
horizontal_alignment = 1

[node name="CardsContainer" type="HBoxContainer" parent="HUD/LevelUpModal/VBoxContainer"]
layout_mode = 2
alignment = 1

[node name="GameOverModal" type="Control" parent="HUD"]
process_mode = 2
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Background" type="ColorRect" parent="HUD/GameOverModal"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.85)

[node name="VBoxContainer" type="VBoxContainer" parent="HUD/GameOverModal"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -80.0
offset_right = 150.0
offset_bottom = 80.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1

[node name="Title" type="Label" parent="HUD/GameOverModal/VBoxContainer"]
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 36
text = "💀 사망했습니다"
horizontal_alignment = 1

[node name="RestartButton" type="Button" parent="HUD/GameOverModal/VBoxContainer"]
layout_mode = 2
text = "🔄 다시 시작하기"
"""
    with open("scenes/Main.tscn", "w", encoding="utf-8") as f:
        f.write(main_tscn.strip())

    print("Godot 4.6 Project structure & files created successfully!")

if __name__ == "__main__":
    create_godot_project()


js_code = r'''/* --- RESOURCE LOADER --- */
const assets = {
    images: {},
    load(name, src) {
        return new Promise((resolve) => {
            const img = new Image();
            img.src = src;
            img.onload = () => {
                this.images[name] = img;
                resolve(img);
            };
            img.onerror = () => {
                console.warn('Image load failed:', src);
                resolve(null);
            };
        });
    }
};

// Game Configuration & Stats Manager (Player and Enemy stats)
const GameStats = {
    player: {
        maxHp: 100,
        speed: 180,
        attack: 25,
        attackRate: 0.8,
        magnet: 110
    },
    mobs: {
        slime: { name: 'Slime', hp: 30, speed: 95, atk: 10, exp: 1, sprite: 'slime_walk', frames: 6 },
        bat: { name: 'Bat', hp: 20, speed: 120, atk: 8, exp: 1, sprite: 'bat_fly', frames: 4 },
        skeleton: { name: 'Skeleton', hp: 70, speed: 75, atk: 15, exp: 3, sprite: 'skel_walk', frames: 8 },
        orc: { name: 'Orc', hp: 110, speed: 65, atk: 20, exp: 4, sprite: 'orc_walk', frames: 8 },
        werewolf: { name: 'Werewolf', hp: 240, speed: 85, atk: 28, exp: 10, sprite: 'werewolf_walk', frames: 8 },
        elite_orc: { name: 'Elite Orc', hp: 350, speed: 60, atk: 35, exp: 18, sprite: 'elite_orc_walk', frames: 8 }
    }
};

function initStatConfigUI() {
    const toggle = document.getElementById('stat-panel-toggle');
    const panel = document.getElementById('stat-panel');
    const closeBtn = document.getElementById('stat-close-btn');

    toggle.onclick = () => panel.classList.toggle('hidden');
    closeBtn.onclick = () => panel.classList.add('hidden');

    const bindInput = (id, obj, key) => {
        const el = document.getElementById(id);
        if (el) {
            el.addEventListener('input', (e) => {
                const val = parseFloat(e.target.value);
                if (!isNaN(val)) {
                    obj[key] = val;
                    if (game && game.player && key === 'maxHp') {
                        const diff = val - game.player.maxHp;
                        game.player.maxHp = val;
                        game.player.hp = Math.min(game.player.maxHp, game.player.hp + Math.max(0, diff));
                    }
                }
            });
        }
    };

    bindInput('cfg-player-hp', GameStats.player, 'maxHp');
    bindInput('cfg-player-speed', GameStats.player, 'speed');
    bindInput('cfg-player-atk', GameStats.player, 'attack');
    bindInput('cfg-player-rate', GameStats.player, 'attackRate');
    bindInput('cfg-player-magnet', GameStats.player, 'magnet');

    bindInput('cfg-mob1-hp', GameStats.mobs.slime, 'hp');
    bindInput('cfg-mob1-speed', GameStats.mobs.slime, 'speed');
    bindInput('cfg-mob1-atk', GameStats.mobs.slime, 'atk');
    bindInput('cfg-mob1-exp', GameStats.mobs.slime, 'exp');

    bindInput('cfg-mob2-hp', GameStats.mobs.skeleton, 'hp');
    bindInput('cfg-mob2-speed', GameStats.mobs.skeleton, 'speed');
    bindInput('cfg-mob2-atk', GameStats.mobs.skeleton, 'atk');
    bindInput('cfg-mob2-exp', GameStats.mobs.skeleton, 'exp');

    bindInput('cfg-mob3-hp', GameStats.mobs.werewolf, 'hp');
    bindInput('cfg-mob3-speed', GameStats.mobs.werewolf, 'speed');
    bindInput('cfg-mob3-atk', GameStats.mobs.werewolf, 'atk');
    bindInput('cfg-mob3-exp', GameStats.mobs.werewolf, 'exp');
}

/* --- SKILL DEFINITIONS --- */
const SKILLS_DB = {
    sword_slash: {
        id: 'sword_slash',
        name: '기사 검기 (Slash)',
        icon: '⚔️',
        desc: '전방으로 강력한 검기를 날려 적들을 관통합니다.',
        maxLevel: 5,
        level: 1,
        cooldown: 0.8,
        timer: 0
    },
    holy_orbit: {
        id: 'holy_orbit',
        name: '수호 방패 (Orbit)',
        icon: '🛡️',
        desc: '기사 주변을 회전하는 방패가 근접한 적에게 피해를 줍니다.',
        maxLevel: 5,
        level: 0,
        count: 1
    },
    lightning: {
        id: 'lightning',
        name: '낙뢰 폭격 (Lightning)',
        icon: '⚡',
        desc: '주변 무작위 적에게 강력한 벼락을 내리꽂습니다.',
        maxLevel: 5,
        level: 0,
        cooldown: 2.0,
        timer: 0
    },
    arrow_rain: {
        id: 'arrow_rain',
        name: '화살 폭풍 (Arrows)',
        icon: '🏹',
        desc: '전방향으로 화살을 일제히 난사합니다.',
        maxLevel: 5,
        level: 0,
        cooldown: 1.6,
        timer: 0
    },
    speed_up: {
        id: 'speed_up',
        name: '신속의 장화 (Speed)',
        icon: '👢',
        desc: '이동 속도가 15% 증가합니다.',
        maxLevel: 5,
        level: 0
    },
    max_hp_up: {
        id: 'max_hp_up',
        name: '거인의 심장 (Health)',
        icon: '💖',
        desc: '최대 체력이 +25 증가하며 즉시 35의 체력을 회복합니다.',
        maxLevel: 5,
        level: 0
    },
    heal_aura: {
        id: 'heal_aura',
        name: '성스러운 재생 (Regen)',
        icon: '✨',
        desc: '1초마다 체력을 3씩 지속적으로 회복합니다.',
        maxLevel: 5,
        level: 0,
        timer: 0
    }
};

/* --- WEB AUDIO SOUND EFFECTS --- */
const AudioSys = {
    ctx: null,
    init() {
        if (!this.ctx) {
            this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        }
    },
    playHit() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(140, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(40, this.ctx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.12, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.1);
    },
    playSlash() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(450, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(120, this.ctx.currentTime + 0.12);
        gain.gain.setValueAtTime(0.18, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.12);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.12);
    },
    playExp() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(600, this.ctx.currentTime);
        osc.frequency.setValueAtTime(900, this.ctx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.08, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.1);
    },
    playLevelUp() {
        if (!this.ctx) return;
        const notes = [440, 554, 659, 880];
        notes.forEach((freq, idx) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, this.ctx.currentTime + idx * 0.08);
            gain.gain.setValueAtTime(0.2, this.ctx.currentTime + idx * 0.08);
            gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + idx * 0.08 + 0.2);
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            osc.start(this.ctx.currentTime + idx * 0.08);
            osc.stop(this.ctx.currentTime + idx * 0.08 + 0.2);
        });
    },
    playLightning() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(320, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(70, this.ctx.currentTime + 0.25);
        gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.25);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.25);
    }
};

/* --- SURVIVOR GAME CORE --- */
class SurvivorGame {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.resize();
        window.addEventListener('resize', () => this.resize());

        this.keys = {};
        window.addEventListener('keydown', (e) => {
            AudioSys.init();
            const k = e.key.toLowerCase();
            this.keys[k] = true;
            if (['w', 'a', 's', 'd', 'arrowup', 'arrowleft', 'arrowdown', 'arrowright'].includes(k)) {
                e.preventDefault();
            }
        });
        window.addEventListener('keyup', (e) => {
            this.keys[e.key.toLowerCase()] = false;
        });

        document.getElementById('btn-restart').onclick = () => this.reset();

        this.reset();
    }

    resize() {
        const container = document.getElementById('game-container');
        this.canvas.width = container.clientWidth;
        this.canvas.height = container.clientHeight;
    }

    reset() {
        this.isPaused = false;
        this.isGameOver = false;
        this.gameTime = 0;
        this.killCount = 0;

        // Player State (Knight)
        this.player = {
            x: 0,
            y: 0,
            hp: GameStats.player.maxHp,
            maxHp: GameStats.player.maxHp,
            level: 1,
            exp: 0,
            nextExp: 10,
            facing: 1, // 1: right, -1: left
            state: 'idle',
            animTime: 0,
            invincibleTimer: 0
        };

        this.skills = JSON.parse(JSON.stringify(SKILLS_DB));

        this.mobs = [];
        this.gems = [];
        this.projectiles = [];
        this.particles = [];
        this.damageTexts = [];

        this.spawnTimer = 0;
        this.orbitAngle = 0;

        document.getElementById('levelup-modal').classList.add('hidden');
        document.getElementById('gameover-modal').classList.add('hidden');
        this.updateSkillsHUD();
        this.updateHUD();
    }

    update(dt) {
        if (this.isPaused || this.isGameOver) return;

        this.gameTime += dt;

        // 1. WASD & Arrow Key Movement
        let dx = 0;
        let dy = 0;
        if (this.keys['w'] || this.keys['arrowup']) dy -= 1;
        if (this.keys['s'] || this.keys['arrowdown']) dy += 1;
        if (this.keys['a'] || this.keys['arrowleft']) dx -= 1;
        if (this.keys['d'] || this.keys['arrowright']) dx += 1;

        const isMoving = dx !== 0 || dy !== 0;
        if (isMoving) {
            const len = Math.hypot(dx, dy);
            let spd = GameStats.player.speed;
            if (this.skills.speed_up.level > 0) {
                spd *= (1 + this.skills.speed_up.level * 0.15);
            }
            this.player.x += (dx / len) * spd * dt;
            this.player.y += (dy / len) * spd * dt;

            if (dx > 0) this.player.facing = 1;
            else if (dx < 0) this.player.facing = -1;

            this.player.state = 'walk';
        } else {
            this.player.state = 'idle';
        }

        this.player.animTime += dt;
        if (this.player.invincibleTimer > 0) this.player.invincibleTimer -= dt;

        // Passive Health Regen
        if (this.skills.heal_aura.level > 0) {
            this.skills.heal_aura.timer = (this.skills.heal_aura.timer || 0) + dt;
            if (this.skills.heal_aura.timer >= 1.0) {
                this.skills.heal_aura.timer = 0;
                const healAmt = this.skills.heal_aura.level * 3;
                if (this.player.hp < this.player.maxHp) {
                    this.player.hp = Math.min(this.player.maxHp, this.player.hp + healAmt);
                    this.addDamageText(this.player.x, this.player.y - 30, `+${healAmt}`, '#4ade80');
                }
            }
        }

        // 2. Active Skills Execution
        this.updateSkills(dt);

        // 3. Spawning Mobs
        this.spawnTimer += dt;
        const spawnInterval = Math.max(0.3, 1.8 - Math.min(1.4, this.gameTime / 60 * 0.35));
        if (this.spawnTimer >= spawnInterval) {
            this.spawnTimer = 0;
            this.spawnMonster();
        }

        // 4. Update Mobs Movement & Attack
        const p = this.player;
        for (let i = this.mobs.length - 1; i >= 0; i--) {
            const mob = this.mobs[i];
            mob.animTime += dt;

            const mdx = p.x - mob.x;
            const mdy = p.y - mob.y;
            const dist = Math.hypot(mdx, mdy);

            if (dist > 0.1) {
                mob.x += (mdx / dist) * mob.speed * dt;
                mob.y += (mdy / dist) * mob.speed * dt;
                mob.facing = mdx >= 0 ? 1 : -1;
            }

            // Player Collision Check
            if (dist < 30 && p.invincibleTimer <= 0) {
                p.hp -= mob.atk;
                p.invincibleTimer = 0.5;
                AudioSys.playHit();
                this.addDamageText(p.x, p.y - 35, `-${mob.atk}`, '#ef4444');
                this.createBloodParticles(p.x, p.y, '#dc2626');

                if (p.hp <= 0) {
                    p.hp = 0;
                    this.triggerGameOver();
                    return;
                }
            }
        }

        // 5. Update Projectiles & Hits
        for (let i = this.projectiles.length - 1; i >= 0; i--) {
            const proj = this.projectiles[i];
            proj.life -= dt;

            if (proj.type === 'orbit') {
                proj.x = p.x + Math.cos(proj.angle) * 75;
                proj.y = p.y + Math.sin(proj.angle) * 75;
            } else {
                proj.x += proj.vx * dt;
                proj.y += proj.vy * dt;
            }

            for (let j = this.mobs.length - 1; j >= 0; j--) {
                const mob = this.mobs[j];
                const dist = Math.hypot(proj.x - mob.x, proj.y - mob.y);
                if (dist < proj.radius + 20) {
                    if (!proj.hitMobs) proj.hitMobs = new Set();
                    if (!proj.hitMobs.has(mob)) {
                        proj.hitMobs.add(mob);
                        mob.hp -= proj.damage;
                        AudioSys.playHit();
                        this.addDamageText(mob.x, mob.y - 25, `${Math.round(proj.damage)}`, '#f59e0b');
                        this.createBloodParticles(mob.x, mob.y, '#f59e0b');

                        if (mob.hp <= 0) {
                            this.killMob(j);
                        }

                        if (proj.pierce !== undefined) {
                            proj.pierce--;
                            if (proj.pierce <= 0) {
                                proj.life = 0;
                                break;
                            }
                        }
                    }
                }
            }

            if (proj.life <= 0) {
                this.projectiles.splice(i, 1);
            }
        }

        // 6. EXP Magnet & Gem Collection
        const magnetDist = GameStats.player.magnet;
        for (let i = this.gems.length - 1; i >= 0; i--) {
            const gem = this.gems[i];
            const gdx = p.x - gem.x;
            const gdy = p.y - gem.y;
            const dist = Math.hypot(gdx, gdy);

            if (dist < magnetDist) {
                const pullSpeed = 400;
                gem.x += (gdx / dist) * pullSpeed * dt;
                gem.y += (gdy / dist) * pullSpeed * dt;
            }

            if (dist < 26) {
                p.exp += gem.value;
                AudioSys.playExp();
                this.gems.splice(i, 1);
                this.checkLevelUp();
            }
        }

        // 7. Particles & Floating Texts
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const pt = this.particles[i];
            pt.x += pt.vx * dt;
            pt.y += pt.vy * dt;
            pt.life -= dt;
            if (pt.life <= 0) this.particles.splice(i, 1);
        }

        for (let i = this.damageTexts.length - 1; i >= 0; i--) {
            const dtItem = this.damageTexts[i];
            dtItem.y -= 25 * dt;
            dtItem.life -= dt;
            if (dtItem.life <= 0) this.damageTexts.splice(i, 1);
        }

        this.updateHUD();
    }

    updateSkills(dt) {
        const p = this.player;
        const slash = this.skills.sword_slash;
        if (slash.level > 0) {
            slash.timer = (slash.timer || 0) + dt;
            const rate = GameStats.player.attackRate / (1 + (slash.level - 1) * 0.18);
            if (slash.timer >= rate) {
                slash.timer = 0;
                this.fireSlash();
            }
        }

        const orbit = this.skills.holy_orbit;
        if (orbit.level > 0) {
            this.orbitAngle += dt * 3.8;
            this.projectiles = this.projectiles.filter(pr => pr.type !== 'orbit');
            const count = orbit.level + 1;
            for (let i = 0; i < count; i++) {
                const angle = this.orbitAngle + (i * Math.PI * 2 / count);
                this.projectiles.push({
                    type: 'orbit',
                    x: p.x + Math.cos(angle) * 75,
                    y: p.y + Math.sin(angle) * 75,
                    angle: angle,
                    radius: 14,
                    damage: GameStats.player.attack * 0.75 * (1 + orbit.level * 0.25),
                    life: 0.1
                });
            }
        }

        const lightning = this.skills.lightning;
        if (lightning.level > 0) {
            lightning.timer = (lightning.timer || 0) + dt;
            const interval = Math.max(0.6, 2.2 - lightning.level * 0.3);
            if (lightning.timer >= interval) {
                lightning.timer = 0;
                this.strikeLightning();
            }
        }

        const arrows = this.skills.arrow_rain;
        if (arrows.level > 0) {
            arrows.timer = (arrows.timer || 0) + dt;
            const interval = Math.max(0.7, 1.8 - arrows.level * 0.22);
            if (arrows.timer >= interval) {
                arrows.timer = 0;
                this.fireArrows();
            }
        }
    }

    fireSlash() {
        const p = this.player;
        AudioSys.playSlash();
        const dir = p.facing;
        const spd = 420;
        const lvl = this.skills.sword_slash.level;
        const dmg = GameStats.player.attack * (1 + (lvl - 1) * 0.35);

        this.projectiles.push({
            type: 'slash',
            x: p.x + dir * 20,
            y: p.y,
            vx: dir * spd,
            vy: 0,
            radius: 28 + lvl * 4,
            damage: dmg,
            pierce: 2 + lvl,
            life: 0.75,
            facing: dir
        });
    }

    strikeLightning() {
        if (this.mobs.length === 0) return;
        const targetsCount = Math.min(this.mobs.length, this.skills.lightning.level);
        AudioSys.playLightning();

        const sorted = [...this.mobs].sort(() => 0.5 - Math.random());
        for (let i = 0; i < targetsCount; i++) {
            const mob = sorted[i];
            const dmg = GameStats.player.attack * 1.8 * (1 + this.skills.lightning.level * 0.3);
            mob.hp -= dmg;
            this.addDamageText(mob.x, mob.y - 30, `⚡${Math.round(dmg)}`, '#67e8f9');
            this.createLightningEffect(mob.x, mob.y);

            if (mob.hp <= 0) {
                const idx = this.mobs.indexOf(mob);
                if (idx !== -1) this.killMob(idx);
            }
        }
    }

    fireArrows() {
        const p = this.player;
        AudioSys.playSlash();
        const count = 4 + this.skills.arrow_rain.level * 2;
        const dmg = GameStats.player.attack * 0.65 * (1 + this.skills.arrow_rain.level * 0.2);
        for (let i = 0; i < count; i++) {
            const angle = (Math.PI * 2 / count) * i;
            this.projectiles.push({
                type: 'arrow',
                x: p.x,
                y: p.y,
                vx: Math.cos(angle) * 460,
                vy: Math.sin(angle) * 460,
                radius: 8,
                damage: dmg,
                pierce: 1,
                life: 1.2,
                angle: angle
            });
        }
    }

    spawnMonster() {
        const angle = Math.random() * Math.PI * 2;
        const dist = 500 + Math.random() * 80;
        const x = this.player.x + Math.cos(angle) * dist;
        const y = this.player.y + Math.sin(angle) * dist;

        let mobType = 'slime';
        const t = this.gameTime;
        if (t > 120 && Math.random() < 0.25) mobType = 'elite_orc';
        else if (t > 80 && Math.random() < 0.35) mobType = 'werewolf';
        else if (t > 50 && Math.random() < 0.45) mobType = 'orc';
        else if (t > 25 && Math.random() < 0.5) mobType = 'skeleton';
        else if (Math.random() < 0.4) mobType = 'bat';

        const proto = GameStats.mobs[mobType] || GameStats.mobs.slime;
        const timeScale = 1 + (t / 180);

        this.mobs.push({
            type: mobType,
            x: x,
            y: y,
            hp: proto.hp * timeScale,
            maxHp: proto.hp * timeScale,
            speed: proto.speed,
            atk: Math.round(proto.atk * (1 + t / 300)),
            exp: proto.exp,
            sprite: proto.sprite,
            frames: proto.frames,
            animTime: Math.random(),
            facing: 1
        });
    }

    killMob(idx) {
        const mob = this.mobs[idx];
        this.killCount++;
        this.mobs.splice(idx, 1);

        this.gems.push({
            x: mob.x,
            y: mob.y,
            value: mob.exp
        });

        this.createBloodParticles(mob.x, mob.y, '#ef4444');
    }

    checkLevelUp() {
        const p = this.player;
        if (p.exp >= p.nextExp) {
            p.exp -= p.nextExp;
            p.level++;
            p.nextExp = Math.round(p.nextExp * 1.45 + 5);
            AudioSys.playLevelUp();
            this.showLevelUpModal();
        }
    }

    showLevelUpModal() {
        this.isPaused = true;
        const modal = document.getElementById('levelup-modal');
        const container = document.getElementById('cards-container');
        container.innerHTML = '';

        const available = Object.values(this.skills).filter(s => s.level < s.maxLevel);
        const chosen = [];
        const pool = [...available];
        while (chosen.length < 3 && pool.length > 0) {
            const randIdx = Math.floor(Math.random() * pool.length);
            chosen.push(pool.splice(randIdx, 1)[0]);
        }

        chosen.forEach(sk => {
            const card = document.createElement('div');
            card.className = 'skill-card';
            card.innerHTML = `
                <div class="skill-icon">${sk.icon}</div>
                <div class="skill-name">${sk.name}</div>
                <div class="skill-level">${sk.level === 0 ? '신규 획득 [LV 1]' : `레벨 업 [LV ${sk.level + 1}]`}</div>
                <div class="skill-desc">${sk.desc}</div>
            `;
            card.onclick = () => {
                this.selectSkill(sk.id);
                modal.classList.add('hidden');
                this.isPaused = false;
            };
            container.appendChild(card);
        });

        modal.classList.remove('hidden');
    }

    selectSkill(id) {
        const sk = this.skills[id];
        sk.level++;

        if (id === 'max_hp_up') {
            this.player.maxHp += 25;
            this.player.hp = Math.min(this.player.maxHp, this.player.hp + 35);
        }

        this.updateSkillsHUD();
        this.updateHUD();
        this.checkLevelUp();
    }

    triggerGameOver() {
        this.isGameOver = true;
        document.getElementById('final-time').innerText = this.formatTime(this.gameTime);
        document.getElementById('final-kills').innerText = this.killCount;
        document.getElementById('gameover-modal').classList.remove('hidden');
    }

    formatTime(sec) {
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }

    updateHUD() {
        const p = this.player;
        document.getElementById('hp-val').innerText = `${Math.max(0, Math.ceil(p.hp))} / ${Math.ceil(p.maxHp)}`;
        document.getElementById('lvl-val').innerText = p.level;
        document.getElementById('kill-val').innerText = this.killCount;
        document.getElementById('time-val').innerText = this.formatTime(this.gameTime);

        const pct = Math.min(100, (p.exp / p.nextExp) * 100);
        document.getElementById('exp-fill').style.width = `${pct}%`;
        document.getElementById('exp-text').innerText = `EXP ${Math.floor(p.exp)} / ${p.nextExp}`;
    }

    updateSkillsHUD() {
        const container = document.getElementById('active-skills');
        container.innerHTML = '';
        Object.values(this.skills).forEach(sk => {
            if (sk.level > 0) {
                const badge = document.createElement('div');
                badge.className = 'active-skill-badge';
                badge.innerHTML = `<span class="icon">${sk.icon}</span><span class="lvl">LV.${sk.level}</span>`;
                container.appendChild(badge);
            }
        });
    }

    addDamageText(x, y, text, color) {
        this.damageTexts.push({ x, y, text, color, life: 0.6 });
    }

    createBloodParticles(x, y, color) {
        for (let i = 0; i < 6; i++) {
            const angle = Math.random() * Math.PI * 2;
            const spd = 40 + Math.random() * 80;
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * spd,
                vy: Math.sin(angle) * spd,
                life: 0.35,
                color,
                size: 3 + Math.random() * 3
            });
        }
    }

    createLightningEffect(x, y) {
        for (let i = 0; i < 12; i++) {
            const angle = Math.random() * Math.PI * 2;
            const spd = 80 + Math.random() * 120;
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * spd,
                vy: Math.sin(angle) * spd,
                life: 0.25,
                color: '#67e8f9',
                size: 3
            });
        }
    }

    render() {
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;
        const cx = w / 2;
        const cy = h / 2;
        const p = this.player;

        ctx.clearRect(0, 0, w, h);

        ctx.save();
        ctx.translate(cx - p.x, cy - p.y);

        // 1. Grid Floor
        const gridSize = 64;
        const startX = Math.floor((p.x - cx) / gridSize) * gridSize;
        const endX = Math.ceil((p.x + cx) / gridSize) * gridSize;
        const startY = Math.floor((p.y - cy) / gridSize) * gridSize;
        const endY = Math.ceil((p.y + cy) / gridSize) * gridSize;

        ctx.strokeStyle = '#1e293b';
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let x = startX; x <= endX; x += gridSize) {
            ctx.moveTo(x, startY);
            ctx.lineTo(x, endY);
        }
        for (let y = startY; y <= endY; y += gridSize) {
            ctx.moveTo(startX, y);
            ctx.lineTo(endX, y);
        }
        ctx.stroke();

        // 2. EXP Gems
        for (const gem of this.gems) {
            ctx.fillStyle = '#38bdf8';
            ctx.shadowColor = '#38bdf8';
            ctx.shadowBlur = 8;
            ctx.beginPath();
            ctx.arc(gem.x, gem.y, 6, 0, Math.PI * 2);
            ctx.fill();
            ctx.shadowBlur = 0;
        }

        // 3. Monsters
        for (const mob of this.mobs) {
            this.drawSprite(mob.sprite, mob.x, mob.y, mob.facing, mob.animTime, mob.frames, 100, 100, 64);
            if (mob.hp < mob.maxHp) {
                const barW = 36;
                const barH = 5;
                const pct = Math.max(0, mob.hp / mob.maxHp);
                ctx.fillStyle = 'rgba(0,0,0,0.6)';
                ctx.fillRect(mob.x - barW / 2, mob.y - 38, barW, barH);
                ctx.fillStyle = '#ef4444';
                ctx.fillRect(mob.x - barW / 2, mob.y - 38, barW * pct, barH);
            }
        }

        // 4. Player (Knight)
        const pSprite = p.state === 'walk' ? 'knight_walk' : 'knight_idle';
        const pFrames = p.state === 'walk' ? 8 : 6;
        if (p.invincibleTimer <= 0 || Math.floor(p.invincibleTimer * 15) % 2 === 0) {
            this.drawSprite(pSprite, p.x, p.y, p.facing, p.animTime, pFrames, 100, 100, 80);
        }

        // 5. Projectiles
        for (const proj of this.projectiles) {
            if (proj.type === 'slash') {
                ctx.save();
                ctx.translate(proj.x, proj.y);
                ctx.scale(proj.facing, 1);
                ctx.strokeStyle = '#60a5fa';
                ctx.lineWidth = 6;
                ctx.shadowColor = '#3b82f6';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(0, 0, proj.radius, -Math.PI / 3, Math.PI / 3);
                ctx.stroke();
                ctx.restore();
            } else if (proj.type === 'orbit') {
                ctx.fillStyle = '#fde047';
                ctx.shadowColor = '#facc15';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(proj.x, proj.y, proj.radius, 0, Math.PI * 2);
                ctx.fill();
                ctx.shadowBlur = 0;
            } else if (proj.type === 'arrow') {
                const arrowImg = assets.images['arrow'];
                if (arrowImg) {
                    ctx.save();
                    ctx.translate(proj.x, proj.y);
                    ctx.rotate(proj.angle);
                    ctx.drawImage(arrowImg, -16, -16, 32, 32);
                    ctx.restore();
                } else {
                    ctx.fillStyle = '#fbbf24';
                    ctx.beginPath();
                    ctx.arc(proj.x, proj.y, 4, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        // 6. Particles
        for (const pt of this.particles) {
            ctx.fillStyle = pt.color;
            ctx.beginPath();
            ctx.arc(pt.x, pt.y, pt.size || 3, 0, Math.PI * 2);
            ctx.fill();
        }

        // 7. Floating Damage Texts
        ctx.font = 'bold 14px Segoe UI, sans-serif';
        ctx.textAlign = 'center';
        for (const dtItem of this.damageTexts) {
            ctx.fillStyle = dtItem.color;
            ctx.fillText(dtItem.text, dtItem.x, dtItem.y);
        }

        ctx.restore();
    }

    drawSprite(imgKey, x, y, facing, time, totalFrames, frameW, frameH, renderSize) {
        const img = assets.images[imgKey];
        const frameIdx = Math.floor(time * 10) % totalFrames;
        const ctx = this.ctx;

        if (img) {
            ctx.save();
            ctx.translate(x, y);
            if (facing === -1) ctx.scale(-1, 1);
            ctx.drawImage(
                img,
                frameIdx * frameW, 0, frameW, frameH,
                -renderSize / 2, -renderSize / 2, renderSize, renderSize
            );
            ctx.restore();
        } else {
            ctx.fillStyle = imgKey && imgKey.startsWith('knight') ? '#3b82f6' : '#dc2626';
            ctx.fillRect(x - 20, y - 20, 40, 40);
        }
    }
}

/* --- PRELOAD AND START --- */
let game = null;
async function start() {
    initStatConfigUI();

    // Preload Knight and Monster Sprites
    await Promise.all([
        assets.load('knight_idle', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Idle.png'),
        assets.load('knight_walk', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Walk.png'),
        assets.load('knight_attack', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Attack01.png'),
        assets.load('knight_death', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Death.png'),

        assets.load('slime_walk', 'asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png'),
        assets.load('bat_fly', 'asset/Characters01/Characters(100x100 split)/Bat/Bat with shadows/Bat_Flying.png'),
        assets.load('skel_walk', 'asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton with shadows/Skeleton_Walk.png'),
        assets.load('orc_walk', 'asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Walk.png'),
        assets.load('werewolf_walk', 'asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Walk.png'),
        assets.load('elite_orc_walk', 'asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Walk.png'),

        assets.load('arrow', 'asset/Characters01/Arrow(Projectile)/Arrow01(32x32).png')
    ]);

    game = new SurvivorGame();

    let lastTime = performance.now();
    function loop(now) {
        const dt = Math.min(0.1, (now - lastTime) / 1000);
        lastTime = now;

        game.update(dt);
        game.render();

        requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);
}

window.onload = start;
'''

with open("game.js", "w", encoding="utf-8") as f:
    f.write(js_code.strip())
print("game.js created successfully")


html_code = """<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Knight Survivor - 탕탕특공대 스타일 게임</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; }
        body { background-color: #0f172a; color: #fff; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; overflow: hidden; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        #game-container { position: relative; width: 100vw; height: 100vh; max-width: 1280px; max-height: 800px; box-shadow: 0 10px 40px rgba(0,0,0,0.8); background: #1e1e24; overflow: hidden; border-radius: 8px; display: flex; }
        canvas { display: block; width: 100%; height: 100%; image-rendering: pixelated; }
        #hud { position: absolute; top: 0; left: 0; right: 0; padding: 12px 20px; pointer-events: none; display: flex; flex-direction: column; gap: 8px; z-index: 10; }
        .hud-row { display: flex; justify-content: space-between; align-items: center; }
        .exp-bar-container { width: 100%; height: 20px; background: rgba(0, 0, 0, 0.6); border-radius: 10px; overflow: hidden; border: 2px solid #3b82f6; position: relative; }
        .exp-bar-fill { height: 100%; width: 0%; background: linear-gradient(90deg, #3b82f6, #60a5fa); transition: width 0.15s ease-out; }
        .exp-text { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 11px; font-weight: bold; text-shadow: 1px 1px 2px #000; }
        .badge { background: rgba(0, 0, 0, 0.7); padding: 6px 14px; border-radius: 20px; font-size: 14px; font-weight: bold; border: 1px solid rgba(255, 255, 255, 0.15); display: flex; align-items: center; gap: 6px; }
        .badge-hp { border-color: #ef4444; color: #f87171; }
        .badge-score { border-color: #fbbf24; color: #fde047; }
        .badge-level { border-color: #3b82f6; color: #93c5fd; }
        .overlay { position: absolute; inset: 0; background: rgba(0, 0, 0, 0.85); backdrop-filter: blur(4px); display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 100; }
        .hidden { display: none !important; }
        .levelup-box { text-align: center; max-width: 800px; width: 90%; }
        .levelup-title { font-size: 32px; font-weight: 900; color: #facc15; text-shadow: 0 0 15px rgba(250, 204, 21, 0.6); margin-bottom: 24px; letter-spacing: 2px; }
        .cards-container { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; }
        .skill-card { background: linear-gradient(145deg, #1f2937, #111827); border: 2px solid #374151; border-radius: 12px; padding: 20px; width: 220px; cursor: pointer; transition: all 0.2s ease; text-align: left; display: flex; flex-direction: column; gap: 8px; }
        .skill-card:hover { transform: translateY(-8px) scale(1.03); border-color: #60a5fa; box-shadow: 0 10px 25px rgba(59, 130, 246, 0.4); }
        .skill-card .skill-icon { font-size: 36px; text-align: center; margin-bottom: 4px; }
        .skill-card .skill-name { font-size: 18px; font-weight: bold; color: #e0e7ff; }
        .skill-card .skill-level { font-size: 12px; color: #93c5fd; font-weight: bold; }
        .skill-card .skill-desc { font-size: 13px; color: #9ca3af; line-height: 1.4; }
        .gameover-box { text-align: center; background: #1f2937; padding: 36px 48px; border-radius: 16px; border: 2px solid #ef4444; box-shadow: 0 0 40px rgba(239, 68, 68, 0.4); }
        .btn-restart { margin-top: 24px; background: linear-gradient(135deg, #ef4444, #dc2626); color: #fff; border: none; padding: 12px 32px; border-radius: 8px; font-size: 18px; font-weight: bold; cursor: pointer; transition: all 0.2s; }
        .btn-restart:hover { transform: scale(1.05); box-shadow: 0 0 20px rgba(239, 68, 68, 0.7); }
        #stat-panel-toggle { position: absolute; bottom: 16px; right: 16px; background: #374151; color: #fff; border: 1px solid #4b5563; padding: 8px 14px; border-radius: 6px; font-size: 13px; cursor: pointer; z-index: 50; opacity: 0.85; transition: opacity 0.2s; }
        #stat-panel-toggle:hover { opacity: 1; background: #4b5563; }
        #stat-panel { position: absolute; top: 50px; right: 16px; width: 330px; background: rgba(17, 24, 39, 0.95); border: 1px solid #374151; border-radius: 12px; padding: 16px; z-index: 60; max-height: 80vh; overflow-y: auto; backdrop-filter: blur(8px); font-size: 13px; }
        #stat-panel h3 { font-size: 16px; color: #facc15; margin-bottom: 12px; border-bottom: 1px solid #374151; padding-bottom: 6px; display: flex; justify-content: space-between; align-items: center; }
        .stat-group { margin-bottom: 14px; background: rgba(31, 41, 55, 0.6); padding: 10px; border-radius: 6px; }
        .stat-group-title { font-weight: bold; color: #93c5fd; margin-bottom: 8px; }
        .stat-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
        .stat-row label { color: #d1d5db; }
        .stat-row input { width: 80px; background: #111827; border: 1px solid #4b5563; color: #fff; padding: 4px 6px; border-radius: 4px; text-align: right; }
        #active-skills { position: absolute; bottom: 16px; left: 16px; display: flex; gap: 8px; pointer-events: none; z-index: 10; }
        .active-skill-badge { background: rgba(0,0,0,0.7); border: 1px solid #3b82f6; border-radius: 8px; padding: 6px 10px; font-size: 12px; display: flex; flex-direction: column; align-items: center; }
        .active-skill-badge .icon { font-size: 18px; }
        .active-skill-badge .lvl { font-size: 10px; color: #60a5fa; font-weight: bold; }
    </style>
</head>
<body>
    <div id="game-container">
        <canvas id="gameCanvas"></canvas>
        <div id="hud">
            <div class="exp-bar-container">
                <div id="exp-fill" class="exp-bar-fill"></div>
                <div id="exp-text" class="exp-text">EXP 0 / 10</div>
            </div>
            <div class="hud-row">
                <div class="badge badge-hp">❤️ HP: <span id="hp-val">100 / 100</span></div>
                <div class="badge badge-level">⭐ LV: <span id="lvl-val">1</span></div>
                <div class="badge badge-score">💀 처치: <span id="kill-val">0</span> | ⏱️ 시간: <span id="time-val">00:00</span></div>
            </div>
        </div>
        <div id="active-skills"></div>
        <div id="levelup-modal" class="overlay hidden">
            <div class="levelup-box">
                <div class="levelup-title">⚡ 레벨 업! 스킬 선택 ⚡</div>
                <div id="cards-container" class="cards-container"></div>
            </div>
        </div>
        <div id="gameover-modal" class="overlay hidden">
            <div class="gameover-box">
                <h1 style="color: #ef4444; font-size: 36px; margin-bottom: 12px;">💀 기사가 쓰러졌습니다</h1>
                <p style="color: #9ca3af; margin-bottom: 6px;">생존 시간: <span id="final-time" style="color: #fff; font-weight: bold;">00:00</span></p>
                <p style="color: #9ca3af; margin-bottom: 20px;">처치한 몬스터: <span id="final-kills" style="color: #fbbf24; font-weight: bold;">0</span> 마리</p>
                <button id="btn-restart" class="btn-restart">🔄 다시 시작하기</button>
            </div>
        </div>
        <button id="stat-panel-toggle">⚙️ 스탯 관리자</button>
        <div id="stat-panel" class="hidden">
            <h3>
                <span>캐릭터 & 몬스터 스탯 관리</span>
                <button id="stat-close-btn" style="background:none; border:none; color:#9ca3af; cursor:pointer; font-size:16px;">✕</button>
            </h3>
            <div class="stat-group">
                <div class="stat-group-title">🛡️ 플레이어 (Knight)</div>
                <div class="stat-row"><label>최대 체력</label><input type="number" id="cfg-player-hp" value="100"></div>
                <div class="stat-row"><label>이동 속도</label><input type="number" id="cfg-player-speed" value="180"></div>
                <div class="stat-row"><label>기본 공격력</label><input type="number" id="cfg-player-atk" value="25"></div>
                <div class="stat-row"><label>공격 주기 (초)</label><input type="number" id="cfg-player-rate" value="0.8" step="0.1"></div>
                <div class="stat-row"><label>자석 반경 (px)</label><input type="number" id="cfg-player-magnet" value="110"></div>
            </div>
            <div class="stat-group">
                <div class="stat-group-title">🦇 슬라임 & 박쥐 (초급 적)</div>
                <div class="stat-row"><label>체력</label><input type="number" id="cfg-mob1-hp" value="30"></div>
                <div class="stat-row"><label>이동 속도</label><input type="number" id="cfg-mob1-speed" value="95"></div>
                <div class="stat-row"><label>공격력</label><input type="number" id="cfg-mob1-atk" value="10"></div>
                <div class="stat-row"><label>경험치</label><input type="number" id="cfg-mob1-exp" value="1"></div>
            </div>
            <div class="stat-group">
                <div class="stat-group-title">💀 스켈레톤 & 오크 (중급 적)</div>
                <div class="stat-row"><label>체력</label><input type="number" id="cfg-mob2-hp" value="80"></div>
                <div class="stat-row"><label>이동 속도</label><input type="number" id="cfg-mob2-speed" value="70"></div>
                <div class="stat-row"><label>공격력</label><input type="number" id="cfg-mob2-atk" value="18"></div>
                <div class="stat-row"><label>경험치</label><input type="number" id="cfg-mob2-exp" value="3"></div>
            </div>
            <div class="stat-group">
                <div class="stat-group-title">🐺 늑대인간 & 엘리트 (고급/보스 적)</div>
                <div class="stat-row"><label>체력</label><input type="number" id="cfg-mob3-hp" value="250"></div>
                <div class="stat-row"><label>이동 속도</label><input type="number" id="cfg-mob3-speed" value="85"></div>
                <div class="stat-row"><label>공격력</label><input type="number" id="cfg-mob3-atk" value="28"></div>
                <div class="stat-row"><label>경험치</label><input type="number" id="cfg-mob3-exp" value="10"></div>
            </div>
        </div>
    </div>
    <script src="game.js"></script>
</body>
</html>
"""

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html_code.strip())
print("index.html created successfully")