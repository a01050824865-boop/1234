class_name LightningEffect
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var timer: float = 0.0
var duration: float = 0.35
var is_awakened: bool = false
var damage: float = 0.0

func init_lightning(pos: Vector2, p_awakened: bool = false, p_damage: float = 0.0) -> void:
	global_position = pos
	timer = 0.0
	is_awakened = p_awakened
	damage = p_damage
	
	if is_awakened:
		scale = Vector2(2.2, 2.2)
		modulate = Color(2.5, 1.2, 3.5, 1.0) # 청자색 심연 번개
		_spawn_awakened_sub_bolts(pos)
	else:
		scale = Vector2(1.5, 1.5)
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	if sprite:
		sprite.frame = 0

func _process(delta: float) -> void:
	timer += delta
	if sprite and duration > 0:
		var frame_idx = int((timer / duration) * 8)
		sprite.frame = clamp(frame_idx, 0, 7)
	if timer >= duration:
		ObjectPool.recycle(self)

func _spawn_awakened_sub_bolts(center_pos: Vector2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# 십자 방전파 이펙트 (Cross electric lines)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var line = Line2D.new()
		line.width = 3.0
		line.default_color = Color(2.5, 1.5, 3.5, 0.9)
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 60.0])
		line.global_position = center_pos
		parent_node.add_child(line)
		var tw = line.create_tween()
		tw.tween_property(line, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(line.queue_free)

	# 주변 적 연쇄 감전 & 스턴(0.35초)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	for en in enemies:
		if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
			if en.global_position.distance_to(center_pos) <= 85.0:
				if en.has_method("apply_stun"):
					en.apply_stun(0.35)
				en.take_damage(damage * 0.35)
				hit_count += 1
				if hit_count >= 3:
					break
