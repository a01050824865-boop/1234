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

func init_slash(pos: Vector2, dir: Vector2, dmg: float, p_pierce: int = 3, spd: float = 420.0, life: float = 0.75) -> void:
	global_position = pos
	direction_vector = dir.normalized()
	damage = dmg
	pierce = p_pierce
	speed = spd
	life_time = life
	total_lifetime = life
	anim_timer = 0.0
	scale = Vector2(1.4, 1.4)
	rotation = direction_vector.angle()
	if sprite:
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	global_position += direction_vector * speed * delta
	life_time -= delta
	anim_timer += delta
	if sprite and total_lifetime > 0:
		var progress = 1.0 - (life_time / total_lifetime)
		sprite.frame = clamp(int(progress * 6), 0, 5)
	if life_time <= 0:
		ObjectPool.recycle(self)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		pierce -= 1
		if pierce <= 0:
			ObjectPool.recycle(self)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		pierce -= 1
		if pierce <= 0:
			ObjectPool.recycle(self)