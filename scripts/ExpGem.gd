class_name ExpGem
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

var is_collected: bool = false

func init_gem(amount: int, pos: Vector2) -> void:
	exp_amount = amount
	global_position = pos
	is_attracted = false
	is_collected = false
	
	var color_rect = get_node_or_null("ColorRect") as ColorRect
	if color_rect:
		if exp_amount >= 11:
			color_rect.color = Color(1.0, 0.7, 0.1, 1.0) # 황금 루비
			scale = Vector2(2.4, 2.4)
		elif exp_amount >= 6:
			color_rect.color = Color(0.7, 0.3, 1.0, 1.0) # 보라 자수정
			scale = Vector2(1.9, 1.9)
		elif exp_amount >= 3:
			color_rect.color = Color(0.2, 0.75, 1.0, 1.0) # 파랑 사파이어
			scale = Vector2(1.5, 1.5)
		else:
			color_rect.color = Color(0.2, 0.85, 0.35, 1.0) # 초록 에메랄드
			scale = Vector2(1.2, 1.2)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		is_collected = true
		body.gain_exp(exp_amount)
		ObjectPool.recycle(self)