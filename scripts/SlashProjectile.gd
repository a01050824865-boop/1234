class_name SlashProjectile
extends Area2D

var direction_vector: Vector2 = Vector2.RIGHT
var damage: float = 25.0
var pierce: int = 3
var speed: float = 420.0
var life_time: float = 0.75

@onready var sprite: Sprite2D = $Sprite2D

var anim_timer: float = 0.0
var total_lifetime: float = 0.75

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	total_lifetime = life_time
	scale = Vector2(1.4, 1.4)
	rotation = direction_vector.angle()

var is_recycled: bool = false
var is_awakened: bool = false
var hit_enemies: Array[Node] = []

func init_slash(pos: Vector2, dir: Vector2, dmg: float, p_pierce: int = 3, spd: float = 420.0, life: float = 0.75, p_awakened: bool = false) -> void:
	global_position = pos
	direction_vector = dir.normalized()
	damage = dmg
	pierce = p_pierce
	speed = spd
	life_time = life
	total_lifetime = life
	anim_timer = 0.0
	is_recycled = false
	is_awakened = p_awakened
	hit_enemies.clear()
	
	if is_awakened:
		scale = Vector2(1.8, 1.8)
		modulate = Color(3.5, 0.7, 0.2, 1.0) # 타오르는 진홍빛 화염 이펙트
	else:
		scale = Vector2(1.4, 1.4)
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	rotation = direction_vector.angle()
	if sprite:
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if is_recycled:
		return
	global_position += direction_vector * speed * delta
	life_time -= delta
	anim_timer += delta
	if sprite and total_lifetime > 0:
		var progress = 1.0 - (life_time / total_lifetime)
		sprite.frame = clamp(int(progress * 6), 0, 5)
	if life_time <= 0 and not is_recycled:
		is_recycled = true
		ObjectPool.recycle(self)

func _on_body_entered(body: Node2D) -> void:
	if is_recycled:
		return
	if body in hit_enemies:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		hit_enemies.append(body)
		body.take_damage(damage)
		if is_awakened and body.has_method("apply_burn"):
			body.apply_burn(damage * 0.32, 3.0)
		pierce -= 1
		if pierce <= 0 and not is_recycled:
			is_recycled = true
			ObjectPool.recycle(self)

func _on_area_entered(area: Area2D) -> void:
	if is_recycled:
		return
	var parent = area.get_parent()
	if parent in hit_enemies:
		return
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		hit_enemies.append(parent)
		parent.take_damage(damage)
		if is_awakened and parent.has_method("apply_burn"):
			parent.apply_burn(damage * 0.32, 3.0)
		pierce -= 1
		if pierce <= 0 and not is_recycled:
			is_recycled = true
			ObjectPool.recycle(self)