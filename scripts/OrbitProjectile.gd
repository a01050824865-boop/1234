class_name OrbitProjectile
extends Area2D

var damage: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D
var anim_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale = Vector2(1.3, 1.3)

func _physics_process(delta: float) -> void:
	anim_timer += delta
	rotation += delta * 4.0
	var pulse = 1.2 + sin(anim_timer * 6.0) * 0.12
	scale = Vector2(pulse, pulse)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)