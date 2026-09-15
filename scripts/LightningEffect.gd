class_name LightningEffect
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var timer: float = 0.0
var duration: float = 0.35

func init_lightning(pos: Vector2) -> void:
	global_position = pos
	timer = 0.0
	if sprite:
		sprite.frame = 0

func _process(delta: float) -> void:
	timer += delta
	if sprite and duration > 0:
		var frame_idx = int((timer / duration) * 10)
		sprite.frame = clamp(frame_idx, 0, 9)
	if timer >= duration:
		ObjectPool.recycle(self)
