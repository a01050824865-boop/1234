class_name ArrowProjectile
extends Area2D

var direction_vector: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var speed: float = 460.0
var life_time: float = 1.2
var is_recycled: bool = false
var is_awakened: bool = false
var pierce_count: int = 1
var hit_enemies: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction_vector.angle()

func init_arrow(pos: Vector2, dir: Vector2, dmg: float, spd: float = 460.0, life: float = 1.2, p_awakened: bool = false) -> void:
	global_position = pos
	direction_vector = dir.normalized()
	damage = dmg
	speed = spd
	life_time = life
	is_recycled = false
	is_awakened = p_awakened
	hit_enemies.clear()
	
	if is_awakened:
		scale = Vector2(1.8, 1.8)
		modulate = Color(3.5, 3.0, 1.0, 1.0) # 황금빛 광선
		pierce_count = 999 # 무한 관통
	else:
		scale = Vector2(1.0, 1.0)
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		pierce_count = 1
		
	rotation = direction_vector.angle()

func _physics_process(delta: float) -> void:
	if is_recycled:
		return
	global_position += direction_vector * speed * delta
	life_time -= delta
	if life_time <= 0 and not is_recycled:
		is_recycled = true
		ObjectPool.recycle(self)

func _on_body_entered(body: Node2D) -> void:
	if is_recycled:
		return
	if body in hit_enemies:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		hit_enemies.append(body)
		body.take_damage(damage)
		
		# 각성 화살 특성: 적 관통 시 유도 파편 발사
		if is_awakened and randf() < 0.4:
			_spawn_fragments(body.global_position)
			
		pierce_count -= 1
		if pierce_count <= 0 and not is_recycled:
			is_recycled = true
			ObjectPool.recycle(self)

func _spawn_fragments(pos: Vector2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	for en in enemies:
		if is_instance_valid(en) and en.visible and en != self and en.has_method("take_damage"):
			if en.global_position.distance_to(pos) <= 120.0:
				en.take_damage(damage * 0.4)
				# 파편 궤적 라인 연출
				var line = Line2D.new()
				line.width = 2.0
				line.default_color = Color(3.5, 2.8, 0.8, 0.8)
				line.points = PackedVector2Array([pos, en.global_position])
				parent_node.add_child(line)
				var tw = line.create_tween()
				tw.tween_property(line, "modulate:a", 0.0, 0.15)
				tw.chain().tween_callback(line.queue_free)
				break
