class_name MagnetItem
extends Area2D

var player: Player = null
var is_collected: bool = false
var float_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var aura: ColorRect = $Aura

func _ready() -> void:
	add_to_group("items")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	float_timer += delta * 4.0
	# 부유 효과 & 펄스 발광 애니메이션
	if sprite:
		sprite.position.y = sin(float_timer) * 3.0
		var s = 1.0 + sin(float_timer * 2.0) * 0.08
		sprite.scale = Vector2(s, s)
	if aura:
		aura.color.a = 0.25 + sin(float_timer * 3.0) * 0.15

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player

	# 플레이어 접근 시 자석 아이템도 플레이어 쪽으로 자연스럽게 끌려옴
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= max(65.0, player.stats.magnet_radius):
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * 450.0 * delta

func init_item(pos: Vector2) -> void:
	global_position = pos
	is_collected = false
	float_timer = randf() * TAU
	modulate = Color(1, 1, 1, 1)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		is_collected = true
		collect(body as Player)

func collect(target_player: Player) -> void:
	# 1. 화면 내 모든 경험치 보석들을 플레이어에게 강력 유도
	var gems = get_tree().get_nodes_in_group("exp_gems")
	for gem in gems:
		if is_instance_valid(gem) and gem.visible and gem.has_method("attract_to_player_magnet"):
			gem.attract_to_player_magnet(850.0)

	# 2. 플레이어 발광 시각 효과
	if is_instance_valid(target_player):
		var tw = target_player.create_tween()
		target_player.modulate = Color(1.3, 2.2, 3.0, 1.0)
		tw.tween_property(target_player, "modulate", Color(1, 1, 1, 1), 0.4)

	# 3. 플로팅 텍스트 팝업 알림
	spawn_magnet_popup(global_position)

	# 4. 풀 반환
	ObjectPool.recycle(self)

func spawn_magnet_popup(pos: Vector2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var label = Label.new()
	label.text = "🧲 전역 자석 발동! 모든 경험치 흡수!"
	label.global_position = pos + Vector2(-120, -35)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))
	parent_node.add_child(label)
	var tw = label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 45.0, 1.2)
	tw.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.6)
	tw.chain().tween_callback(label.queue_free)
