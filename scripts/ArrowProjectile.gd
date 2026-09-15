class_name ArrowProjectile
extends Area2D

var direction_vector: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var speed: float = 460.0
var life_time: float = 1.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction_vector.angle()

var is_recycled: bool = false

func init_arrow(pos: Vector2, dir: Vector2, dmg: float, spd: float = 460.0, life: float = 1.2) -> void:
	global_position = pos
	direction_vector = dir.normalized()
	damage = dmg
	speed = spd
	life_time = life
	is_recycled = false
	rotation = direction_vector.angle()

func _physics_process(delta: float) -> void:
	if is_recycled:
		return
	global_position += direction_vector * speed * delta
	life_time -= delta
	if life_time <= 0 and not is_recycled:
		is_recycled = true
		ObjectPool.recycle(self)

func _on_body_entered(body: Node2D) -> void:
	if is_recycled:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		if not is_recycled:
			is_recycled = true
			ObjectPool.recycle(self)