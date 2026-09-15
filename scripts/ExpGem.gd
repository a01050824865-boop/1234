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

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		is_collected = true
		body.gain_exp(exp_amount)
		ObjectPool.recycle(self)