class_name ArrowProjectile
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