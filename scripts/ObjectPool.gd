class_name ObjectPool
extends Node

static var instance: ObjectPool = null

# Dictionary of PackedScene.resource_path -> Array[Node]
var pools: Dictionary = {}

func _init() -> void:
	if instance == null:
		instance = self

static func get_pool() -> ObjectPool:
	if instance == null:
		instance = ObjectPool.new()
	return instance

static func spawn(scene: PackedScene, parent: Node) -> Node:
	return get_pool()._get_or_create(scene, parent)

static func recycle(node: Node) -> void:
	get_pool()._return_to_pool(node)

func _get_or_create(scene: PackedScene, parent: Node) -> Node:
	if scene == null:
		return null
		
	var path = scene.resource_path
	if not pools.has(path):
		pools[path] = []

	var pool_list: Array = pools[path]
	var node: Node = null

	while pool_list.size() > 0:
		var candidate = pool_list.pop_back()
		if is_instance_valid(candidate):
			node = candidate
			break

	if node == null:
		node = scene.instantiate()
		node.set_meta("pool_scene_path", path)
		if parent:
			if Engine.is_editor_hint():
				parent.add_child(node)
			else:
				parent.call_deferred("add_child", node)
	else:
		if node.get_parent() != parent:
			if node.get_parent():
				node.get_parent().call_deferred("remove_child", node)
			if parent:
				parent.call_deferred("add_child", node)

	# 노드 활성화 (물리 쿼리 충돌 방지를 위해 deferred 처리)
	node.visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.set_process(true)
	node.set_physics_process(true)
	
	if node is CollisionObject2D:
		_set_collision_shapes_state(node, false)

	return node

func _return_to_pool(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var path = node.get_meta("pool_scene_path", "")
	if path == "":
		node.queue_free()
		return

	if not pools.has(path):
		pools[path] = []

	# 노드 비활성화 (물리 쿼리 충돌 방지를 위해 deferred 처리)
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.set_process(false)
	node.set_physics_process(false)

	if node is CollisionObject2D:
		_set_collision_shapes_state(node, true)

	if not pools[path].has(node):
		pools[path].append(node)

func _set_collision_shapes_state(node: CollisionObject2D, disabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", disabled)
	for owner_id in node.get_shape_owners():
		node.call_deferred("shape_owner_set_disabled", owner_id, disabled)
