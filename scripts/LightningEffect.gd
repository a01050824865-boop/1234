class_name LightningEffect
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var timer: float = 0.0
var duration: float = 0.35

func _ready() -> void:
	if sprite:
		sprite.frame = 0

func _process(delta: float) -> void:
	timer += delta
	if sprite:
		var frame_idx = int((timer / duration) * 10)
		sprite.frame = clamp(frame_idx, 0, 9)
	if timer >= duration:
		queue_free()
