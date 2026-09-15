class_name CharacterStats
extends Resource

@export var character_name: String = "Knight"
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var move_speed: float = 180.0
@export var base_attack_power: float = 25.0
@export var attack_interval: float = 0.8
@export var exp_reward: int = 1
@export var score_reward: int = 10
@export var magnet_radius: float = 120.0

func reset_health() -> void:
	current_health = max_health

func take_damage(amount: float) -> bool:
	current_health = max(0.0, current_health - amount)
	return current_health <= 0.0

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)