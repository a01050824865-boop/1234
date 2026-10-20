W 0:00:00:260   DisplayServerWindows: Your video card drivers are known to have low quality OpenGL 3.3 support, switching to ANGLE.
  <C++ 소스>      platform/windows/display_server_windows.cpp:7423 @ DisplayServerWindows()
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
