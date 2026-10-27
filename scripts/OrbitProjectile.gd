class_name OrbitProjectile
extends Area2D

var damage: float = 20.0
var is_awakened: bool = false
var hit_cooldowns: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
var anim_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if is_awakened:
		scale = Vector2(2.0, 2.0)
		modulate = Color(3.5, 1.8, 0.4, 1.0)
	else:
		scale = Vector2(1.3, 1.3)
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_awakened(awakened: bool) -> void:
	is_awakened = awakened
	if is_awakened:
		scale = Vector2(2.0, 2.0)
		modulate = Color(3.5, 1.8, 0.4, 1.0)
	else:
		scale = Vector2(1.3, 1.3)
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	anim_timer += delta
	rotation += delta * (7.0 if is_awakened else 4.0)
	var base_scale = 1.9 if is_awakened else 1.2
	var pulse = base_scale + sin(anim_timer * 8.0) * (0.2 if is_awakened else 0.12)
	scale = Vector2(pulse, pulse)

	# Update hit cooldowns
	var to_remove = []
	for body_ref in hit_cooldowns:
		hit_cooldowns[body_ref] -= delta
		if hit_cooldowns[body_ref] <= 0:
			to_remove.append(body_ref)
	for body_ref in to_remove:
		hit_cooldowns.erase(body_ref)

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if hit_cooldowns.has(body):
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		hit_cooldowns[body] = 0.25
		body.take_damage(damage)
		if is_awakened:
			_spawn_plasma_burst(body.global_position)

func _on_area_entered(area: Area2D) -> void:
	if is_awakened and area.is_in_group("enemy_projectiles"):
		area.queue_free()

func _spawn_plasma_burst(pos: Vector2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	# Visual blast ring
	var blast = Line2D.new()
	blast.width = 4.0
	blast.default_color = Color(3.5, 2.0, 0.5, 0.9)
	var pts: PackedVector2Array = []
	for i in range(17):
		var th = i * TAU / 16.0
		pts.append(Vector2(cos(th), sin(th)))
	blast.points = pts
	blast.global_position = pos
	blast.scale = Vector2(4.0, 4.0)
	parent_node.add_child(blast)
	var tw = blast.create_tween()
	tw.parallel().tween_property(blast, "scale", Vector2(45.0, 45.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(blast, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(blast.queue_free)

	# Area splash damage to nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for en in enemies:
		if is_instance_valid(en) and en.visible and en.has_method("take_damage"):
			if en.global_position.distance_to(pos) <= 50.0:
				en.take_damage(damage * 0.4)
