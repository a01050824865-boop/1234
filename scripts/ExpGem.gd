class_name ExpGem
extends Area2D

@export var exp_amount: int = 1
var player: Player = null
var is_attracted: bool = false
var speed: float = 400.0
var gem_color: Color = Color(0.22, 0.82, 0.52)
var is_collected: bool = false

func _ready() -> void:
	add_to_group("exp_gems")
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

func attract_to_player_magnet(p_speed: float = 800.0) -> void:
	is_attracted = true
	speed = p_speed

func init_gem(amount: int, pos: Vector2) -> void:
	add_to_group("exp_gems")
	exp_amount = amount
	global_position = pos
	is_attracted = false
	is_collected = false
	speed = 400.0

	# 눈이 편안하고 깊이 있는 자연스러운 원석 보석 색상
	if exp_amount >= 70:
		# 거대 웨어베어 (85 EXP): 깊고 풍부한 루비 레드
		gem_color = Color(0.92, 0.22, 0.34)
		scale = Vector2(2.3, 2.3)
	elif exp_amount >= 40:
		# 중장갑 오크 (45 EXP): 따뜻한 앰버 선셋 카넬리안
		gem_color = Color(0.95, 0.48, 0.2)
		scale = Vector2(2.0, 2.0)
	elif exp_amount >= 20:
		# 엘리트 오크 (25 EXP): 은은하고 우아한 황금 시트린
		gem_color = Color(0.95, 0.78, 0.25)
		scale = Vector2(1.8, 1.8)
	elif exp_amount >= 10:
		# 늑대인간 (12 EXP): 부드러운 로즈 쿼츠 핑크
		gem_color = Color(0.92, 0.42, 0.72)
		scale = Vector2(1.6, 1.6)
	elif exp_amount >= 6:
		# 오크 (8 EXP): 신비로운 라벤더 아메지스트
		gem_color = Color(0.68, 0.45, 0.92)
		scale = Vector2(1.45, 1.45)
	elif exp_amount >= 3:
		# 스켈레톤 (4 EXP): 맑고 투명한 사파이어 블루
		gem_color = Color(0.32, 0.62, 0.95)
		scale = Vector2(1.35, 1.35)
	elif exp_amount == 2:
		# 박쥐 (2 EXP): 청명한 아쿠아마린
		gem_color = Color(0.28, 0.8, 0.92)
		scale = Vector2(1.2, 1.2)
	else:
		# 슬라임 (1 EXP): 부드러운 에메랄드 그린
		gem_color = Color(0.25, 0.82, 0.52)
		scale = Vector2(1.1, 1.1)

	queue_redraw()

func _draw() -> void:
	# 위쪽이 더 길쭉한 크리스탈 마름모
	var top = Vector2(0, -11)
	var right = Vector2(6.5, -1)
	var bottom = Vector2(0, 7)
	var left = Vector2(-6.5, -1)

	# 1. 자연스러운 보석 톤의 은은한 음영 테두리 (인위적인 흰색 선 제거)
	var border_poly = PackedVector2Array([
		Vector2(0, -12),
		Vector2(7.5, -1),
		Vector2(0, 8),
		Vector2(-7.5, -1)
	])
	var border_col = gem_color.darkened(0.42)
	border_col.a = 0.85
	draw_colored_polygon(border_poly, border_col)

	# 2. 좌측 패싯 (자연스러운 빛 반사 면)
	var left_poly = PackedVector2Array([top, left, bottom])
	var left_col = gem_color.lightened(0.18)
	draw_colored_polygon(left_poly, left_col)

	# 3. 우측 패싯 (부드러운 음영 면)
	var right_poly = PackedVector2Array([top, right, bottom])
	var right_col = gem_color.darkened(0.14)
	draw_colored_polygon(right_poly, right_col)

	# 4. 부드러운 중앙 능선 (동일 계열 색상의 은은한 광택선)
	var ridge_col = gem_color.lightened(0.4)
	ridge_col.a = 0.55
	draw_line(top, bottom, ridge_col, 1.0, true)

	# 5. 은은한 미세 하이라이트 글린트
	draw_circle(Vector2(-1.8, -4.5), 1.0, Color(1.0, 1.0, 1.0, 0.5))

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		is_collected = true
		body.gain_exp(exp_amount)
		ObjectPool.recycle(self)