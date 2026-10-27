class_name SkillTreeUI
extends Control

signal skill_tree_closed

var player: Player = null
var game_manager: GameManager = null

# UI 노드 참조
var bg_overlay: ColorRect
var canvas_tree: Control
var detail_panel: PanelContainer
var detail_title: Label
var detail_category: Label
var detail_desc: Label
var detail_awakening: Label
var detail_level_label: Label
var detail_progress: ProgressBar
var upgrade_btn: Button
var sp_label: Label
var close_btn: Button

# 현재 선택된 스킬 ID
var selected_skill_id: String = "slash"

# 스킬 노드 정의 (스타워즈 제다이 폴른 오더 스타일 원형/성좌형 배치)
# 카테고리: FORCE (주문/원거리 마법), LIGHTSABER (검술/공격), SURVIVAL (생존/수호)
# pos: 1280x720 캔버스 내에서의 (x, y) 좌표
var skills_meta = {
	# [LIGHTSABER - 검술 & 무기] (중앙 상단)
	"slash": {
		"id": "slash",
		"name": "기사 검기 (Slash)",
		"category": "LIGHTSABER",
		"category_color": Color(0.3, 0.75, 1.0),
		"desc": "전방으로 날카로운 은빛 검기를 날려 적들을 관통합니다.",
		"awakening_desc": "진홍의 염제 검기: 20마리 관통, 대형 화염 참격파 및 지속 화염 피해!",
		"icon": "res://asset/knight_slash_wave.png",
		"crop": Rect2(64, 2, 60, 60),
		"parent": "", # 루트
		"pos": Vector2(430, 420),
		"tier": 1
	},
	"arrows": {
		"id": "arrows",
		"name": "화살 폭풍 (Arrows)",
		"category": "LIGHTSABER",
		"category_color": Color(0.3, 0.75, 1.0),
		"desc": "사방 360도로 관통 화살을 일제 발사하여 적 무리를 격퇴합니다.",
		"awakening_desc": "빛의 성스러운 유성우: 24발 전방위 난사, 무한 관통 + 유도 파편 분열!",
		"icon": "res://asset/Characters01/Arrow(Projectile)/Arrow01(32x32).png",
		"crop": Rect2(4, 4, 24, 24),
		"parent": "slash",
		"pos": Vector2(430, 250),
		"tier": 2
	},

	# [FORCE - 주문 & 마법 원거리] (좌측 영역)
	"orbit": {
		"id": "orbit",
		"name": "수호의 보주 (Orbit)",
		"category": "FORCE",
		"category_color": Color(0.65, 0.45, 1.0),
		"desc": "주위를 성스러운 보주가 공전하며 접근하는 적을 타격합니다.",
		"awakening_desc": "태양의 플라즈마: 보주 6개 급속 회전, 플라즈마 폭발 및 적 탄환 소멸!",
		"icon": "res://asset/shield_orb_icon.png",
		"crop": Rect2(0, 0, 32, 32),
		"parent": "", # 루트
		"pos": Vector2(280, 460),
		"tier": 1
	},
	"lightning": {
		"id": "lightning",
		"name": "낙뢰 폭격 (Lightning)",
		"category": "FORCE",
		"category_color": Color(0.65, 0.45, 1.0),
		"desc": "하늘에서 강력한 번개를 소환해 무작위 적을 강타합니다.",
		"awakening_desc": "천벌의 뇌신 폭풍: 8명 동시 타격, 십자 방전 연쇄 감전 + 0.35초 기절!",
		"icon": "res://asset/Characters01/Magic(Projectile)/Wizard_Attack01_Effect.png",
		"crop": Rect2(334, 32, 38, 38),
		"parent": "orbit",
		"pos": Vector2(160, 350),
		"tier": 2
	},
	"speed": {
		"id": "speed",
		"name": "신속의 장화 (Speed)",
		"category": "FORCE",
		"category_color": Color(0.65, 0.45, 1.0),
		"desc": "기사의 이동 속도가 영구적으로 +15% 증가합니다.",
		"awakening_desc": "질풍의 섬광 보폭: 이동속도 +75%, 25% 완전 회피 + 궤적 바람 칼날 슬로우!",
		"icon": "res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Walk.png",
		"crop": Rect2(338, 32, 32, 32),
		"parent": "orbit",
		"pos": Vector2(150, 540),
		"tier": 2
	},

	# [SURVIVAL - 생존 & 수호 체계] (우측 영역)
	"shield": {
		"id": "shield",
		"name": "성스러운 철벽 [Q]",
		"category": "SURVIVAL",
		"category_color": Color(0.3, 0.9, 0.5),
		"desc": "Q키로 발동하는 무적 방패입니다 (지속 6.5초 / 쿨타임 15초).",
		"awakening_desc": "절대성역: 무적 시간 연장, 적 탄환 소멸 및 100% 반사 피해!",
		"icon": "res://asset/holy_shield_crop.png",
		"crop": Rect2(0, 0, 13, 16),
		"parent": "", # 루트
		"pos": Vector2(580, 460),
		"tier": 1
	},
	"regen": {
		"id": "regen",
		"name": "성스러운 재생 (Regen)",
		"category": "SURVIVAL",
		"category_color": Color(0.3, 0.9, 0.5),
		"desc": "초당 체력을 지속적으로 회복합니다.",
		"awakening_desc": "불사조의 가호: 초당 +5 HP 회복 + 치명상 시 1회 부활 및 광역 넉백!",
		"icon": "res://asset/Characters01/Magic(Projectile)/Priest_Heal_effect.png",
		"crop": Rect2(232, 26, 38, 38),
		"parent": "shield",
		"pos": Vector2(700, 350),
		"tier": 2
	},
	"health": {
		"id": "health",
		"name": "거인의 심장 (Health)",
		"category": "SURVIVAL",
		"category_color": Color(0.3, 0.9, 0.5),
		"desc": "최대 체력 +25 증가 및 체력을 즉시 회복합니다.",
		"awakening_desc": "타이탄의 강철 피부: 최대 HP +150 및 풀피 회복, 피격 피해 10 감소!",
		"icon": "res://asset/Characters01/Magic(Projectile)/Priest_Attack_effect.png",
		"crop": Rect2(234, 28, 36, 36),
		"parent": "shield",
		"pos": Vector2(710, 540),
		"tier": 2
	}
}

var node_buttons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()

func setup(p_mgr: GameManager, p_player: Player) -> void:
	game_manager = p_mgr
	player = p_player

func _build_ui() -> void:
	# 1. 딥 다크 우주/스타워즈 테마 배경 오버레이
	bg_overlay = ColorRect.new()
	bg_overlay.anchors_preset = Control.PRESET_FULL_RECT
	bg_overlay.anchor_right = 1.0
	bg_overlay.anchor_bottom = 1.0
	bg_overlay.color = Color(0.03, 0.04, 0.07, 0.94)
	add_child(bg_overlay)

	# 2. 스킬트리 성좌 캔버스 (선 + 원호 배경 드로잉 + 노드 버튼 배치)
	canvas_tree = SkillTreeCanvas.new()
	canvas_tree.ui = self
	canvas_tree.anchors_preset = Control.PRESET_FULL_RECT
	canvas_tree.anchor_right = 1.0
	canvas_tree.anchor_bottom = 1.0
	add_child(canvas_tree)

	# 3. 상단 헤더: 타이틀 + SP + 닫기
	var header = PanelContainer.new()
	header.anchors_preset = Control.PRESET_TOP_WIDE
	header.anchor_right = 1.0
	header.offset_bottom = 70.0
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	h_style.border_width_bottom = 2
	h_style.border_color = Color(0.2, 0.35, 0.5, 0.6)
	h_style.content_margin_left = 30
	h_style.content_margin_right = 30
	h_style.content_margin_top = 12
	h_style.content_margin_bottom = 12
	header.add_theme_stylebox_override("panel", h_style)
	add_child(header)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 20)
	header.add_child(hbox)

	var title_lbl = Label.new()
	title_lbl.text = "✦ 기사단 비전 성좌 스킬 트리 (SKILL CONSTELLATION)"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_lbl)

	sp_label = Label.new()
	sp_label.text = "보유 스킬 포인트: 0 SP"
	sp_label.add_theme_font_size_override("font_size", 18)
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	hbox.add_child(sp_label)

	close_btn = Button.new()
	close_btn.text = "✖ 닫기 (ESC / K)"
	close_btn.custom_minimum_size = Vector2(130, 38)
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.18, 0.22, 0.3, 0.9)
	c_style.set_corner_radius_all(6)
	c_style.border_width_left = 1
	c_style.border_width_top = 1
	c_style.border_width_right = 1
	c_style.border_width_bottom = 1
	c_style.border_color = Color(0.4, 0.6, 0.8, 0.8)
	close_btn.add_theme_stylebox_override("normal", c_style)
	close_btn.pressed.connect(_on_close_pressed)
	hbox.add_child(close_btn)

	# 4. 카테고리 텍스트 헤더 (캔버스 내부 영역 라벨)
	_create_category_label("FORCE", Vector2(210, 150), Color(0.65, 0.5, 1.0))
	_create_category_label("LIGHTSABER", Vector2(430, 130), Color(0.4, 0.8, 1.0))
	_create_category_label("SURVIVAL", Vector2(650, 150), Color(0.35, 0.95, 0.6))

	# 5. 각 스킬 노드 버튼 생성 (원형 아이콘 형태)
	for sk_id in skills_meta.keys():
		var data = skills_meta[sk_id]
		var btn = _create_skill_node_button(data)
		node_buttons[sk_id] = btn
		canvas_tree.add_child(btn)

	# 6. 우측 하단 상세 정보 패널 (Detail HUD)
	_build_detail_panel()

func _create_category_label(text: String, pos: Vector2, col: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", col)
	lbl.position = pos - Vector2(60, 10)
	lbl.custom_minimum_size = Vector2(120, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas_tree.add_child(lbl)

func _create_skill_node_button(data: Dictionary) -> Button:
	var btn = Button.new()
	var sz = 64.0
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.position = data["pos"] - Vector2(sz / 2.0, sz / 2.0)
	btn.focus_mode = Control.FOCUS_NONE
	
	# 아이콘 컨테이너
	var tex_rect = TextureRect.new()
	tex_rect.name = "Icon"
	tex_rect.custom_minimum_size = Vector2(40, 40)
	tex_rect.anchors_preset = Control.PRESET_CENTER
	tex_rect.anchor_left = 0.5
	tex_rect.anchor_top = 0.5
	tex_rect.anchor_right = 0.5
	tex_rect.anchor_bottom = 0.5
	tex_rect.offset_left = -20.0
	tex_rect.offset_top = -20.0
	tex_rect.offset_right = 20.0
	tex_rect.offset_bottom = 20.0
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var raw_tex = load(data["icon"]) as Texture2D
	if raw_tex:
		var atlas = AtlasTexture.new()
		atlas.atlas = raw_tex
		atlas.region = data["crop"]
		tex_rect.texture = atlas
	btn.add_child(tex_rect)

	# 레벨 표시 미니 뱃지 (우하단)
	var badge = Label.new()
	badge.name = "Badge"
	badge.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	badge.anchor_left = 1.0
	badge.anchor_top = 1.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -22.0
	badge.offset_top = -18.0
	badge.offset_right = 2.0
	badge.offset_bottom = 0.0
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(badge)

	var target_id = data["id"]
	btn.pressed.connect(func():
		selected_skill_id = target_id
		_refresh_all()
	)

	return btn

func _build_detail_panel() -> void:
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(360, 480)
	detail_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	detail_panel.anchor_left = 1.0
	detail_panel.anchor_right = 1.0
	detail_panel.offset_left = -380.0
	detail_panel.offset_top = 90.0
	detail_panel.offset_right = -20.0
	detail_panel.offset_bottom = 570.0

	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.11, 0.16, 0.95)
	p_style.set_corner_radius_all(10)
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 2
	p_style.border_color = Color(0.3, 0.5, 0.8, 0.8)
	p_style.content_margin_left = 18
	p_style.content_margin_right = 18
	p_style.content_margin_top = 18
	p_style.content_margin_bottom = 18
	detail_panel.add_theme_stylebox_override("panel", p_style)
	add_child(detail_panel)

	var dvbox = VBoxContainer.new()
	dvbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dvbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dvbox.add_theme_constant_override("separation", 12)
	detail_panel.add_child(dvbox)

	detail_category = Label.new()
	detail_category.text = "CATEGORY"
	detail_category.add_theme_font_size_override("font_size", 12)
	dvbox.add_child(detail_category)

	detail_title = Label.new()
	detail_title.text = "스킬 이름"
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_title.add_theme_color_override("font_color", Color(1, 1, 1))
	dvbox.add_child(detail_title)

	var sep1 = HSeparator.new()
	dvbox.add_child(sep1)

	var lv_row = HBoxContainer.new()
	detail_level_label = Label.new()
	detail_level_label.text = "단계: LV 0 / 5"
	detail_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_level_label.add_theme_font_size_override("font_size", 14)
	detail_level_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	lv_row.add_child(detail_level_label)
	dvbox.add_child(lv_row)

	detail_progress = ProgressBar.new()
	detail_progress.custom_minimum_size = Vector2(0, 8)
	detail_progress.max_value = 5
	detail_progress.step = 1
	detail_progress.show_percentage = false
	var prog_bg = StyleBoxFlat.new()
	prog_bg.bg_color = Color(0.15, 0.18, 0.24, 0.9)
	prog_bg.set_corner_radius_all(4)
	var prog_fill = StyleBoxFlat.new()
	prog_fill.bg_color = Color(0.95, 0.8, 0.25, 1.0)
	prog_fill.set_corner_radius_all(4)
	detail_progress.add_theme_stylebox_override("background", prog_bg)
	detail_progress.add_theme_stylebox_override("fill", prog_fill)
	dvbox.add_child(detail_progress)

	detail_desc = Label.new()
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.text = "기본 스킬 설명"
	detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_desc.add_theme_font_size_override("font_size", 13)
	detail_desc.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	dvbox.add_child(detail_desc)

	detail_awakening = Label.new()
	detail_awakening.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_awakening.text = "★ 최종 5레벨 각성 특성"
	detail_awakening.add_theme_font_size_override("font_size", 13)
	detail_awakening.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	dvbox.add_child(detail_awakening)

	upgrade_btn = Button.new()
	upgrade_btn.text = "⚡ 스킬 강화 (-1 SP)"
	upgrade_btn.custom_minimum_size = Vector2(0, 44)
	var u_style = StyleBoxFlat.new()
	u_style.bg_color = Color(0.15, 0.45, 0.25, 0.95)
	u_style.set_corner_radius_all(8)
	u_style.border_width_left = 2
	u_style.border_width_top = 2
	u_style.border_width_right = 2
	u_style.border_width_bottom = 2
	u_style.border_color = Color(0.4, 0.9, 0.5, 1.0)
	upgrade_btn.add_theme_stylebox_override("normal", u_style)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	dvbox.add_child(upgrade_btn)

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh_all()

func close() -> void:
	visible = false
	get_tree().paused = false
	skill_tree_closed.emit()

func _on_close_pressed() -> void:
	close()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_K or event.physical_keycode == KEY_T:
			close()
			get_viewport().set_input_as_handled()

func get_skill_level(sk_id: String) -> int:
	if not player:
		return 0
	if sk_id == "health":
		return player.health_awakening_level
	return player.skills.get(sk_id, 0)

func is_skill_unlocked(sk_id: String) -> bool:
	return get_skill_level(sk_id) > 0

func can_unlock_skill(_sk_id: String) -> bool:
	# 선행 조건 없이 처음부터 모든 스킬 자유 습득/강화 가능
	return true

func _refresh_all() -> void:
	if not player or not game_manager:
		return

	# SP 라벨 갱신
	sp_label.text = "보유 스킬 포인트: %d SP" % game_manager.skill_points

	# 노드 버튼들 비주얼 갱신
	for sk_id in skills_meta.keys():
		var btn = node_buttons.get(sk_id) as Button
		if not btn:
			continue
		var lv = get_skill_level(sk_id)
		var is_unlocked = (lv > 0)
		var is_selected = (sk_id == selected_skill_id)
		var is_max = (lv >= 5)

		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(32) # 완벽한 원형
		style.corner_detail = 16

		if is_selected:
			# 선택된 노드: 황금빛 굵은 테두리
			style.bg_color = Color(0.2, 0.25, 0.35, 0.95)
			style.border_color = Color(1.0, 0.85, 0.25, 1.0)
			style.set_border_width_all(4)
		elif is_max:
			# 마스터: 각성 골드 글로우
			style.bg_color = Color(0.25, 0.2, 0.08, 0.92)
			style.border_color = Color(1.0, 0.75, 0.2, 0.9)
			style.set_border_width_all(3)
		elif is_unlocked:
			# 활성화 노드: 시안/블루 하이라이트
			style.bg_color = Color(0.12, 0.16, 0.24, 0.9)
			style.border_color = Color(0.3, 0.8, 1.0, 0.85)
			style.set_border_width_all(2)
		else:
			# 미습득 상태 (자유롭게 습득 가능)
			style.bg_color = Color(0.08, 0.1, 0.15, 0.88)
			style.border_color = Color(0.5, 0.65, 0.8, 0.7)
			style.set_border_width_all(2)

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

		# 아이콘 색상 조절
		var icon_rect = btn.get_node_or_null("Icon") as TextureRect
		if icon_rect:
			if is_max:
				icon_rect.modulate = Color(3.0, 2.0, 0.8, 1.0) # 강한 골드 발광
			elif is_unlocked:
				icon_rect.modulate = Color(1.3, 1.3, 1.3, 1.0)
			else:
				# 미습득 상태에서도 깨끗하게 볼 수 있도록 적절한 밝기
				icon_rect.modulate = Color(0.85, 0.85, 0.9, 0.85)

		# 레벨 뱃지 텍스트
		var badge = btn.get_node_or_null("Badge") as Label
		if badge:
			if lv > 0:
				badge.text = "%d" % lv
				badge.visible = true
				badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_max else Color(0.4, 0.9, 1.0))
			else:
				badge.visible = false

	# 우측 상세 패널 갱신
	_refresh_detail_panel()
	# 캔버스 선/아크 다시 그리기
	canvas_tree.queue_redraw()

func _refresh_detail_panel() -> void:
	var data = skills_meta.get(selected_skill_id)
	if not data:
		return

	var lv = get_skill_level(selected_skill_id)
	var is_unlocked = (lv > 0)
	var is_max = (lv >= 5)

	detail_category.text = "✦ %s 계열" % data["category"]
	detail_category.add_theme_color_override("font_color", data["category_color"])

	detail_title.text = data["name"]
	if is_max:
		detail_level_label.text = "단계: LV 5 [★ 각성 마스터]"
		detail_level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	elif lv == 4:
		detail_level_label.text = "단계: LV 4 ➡️ [다음 레벨 각성!]"
		detail_level_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2))
	elif is_unlocked:
		detail_level_label.text = "단계: LV %d / 5" % lv
		detail_level_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	else:
		detail_level_label.text = "단계: 미습득 (LV 0)"
		detail_level_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))

	detail_progress.value = lv
	detail_desc.text = data["desc"]
	detail_awakening.text = "✨ [최종 각성]: " + data["awakening_desc"]

	# 업그레이드 버튼 상태
	if is_max:
		upgrade_btn.text = "✓ 최종 각성 완료 (MAX)"
		upgrade_btn.disabled = true
	elif game_manager.skill_points <= 0:
		upgrade_btn.text = "🔒 SP 부족 (필요: 1 SP)"
		upgrade_btn.disabled = true
	else:
		if lv == 4:
			upgrade_btn.text = "⚡ 최종 각성 진화! (-1 SP)"
		elif lv == 0:
			upgrade_btn.text = "✨ 스킬 습득 (-1 SP)"
		else:
			upgrade_btn.text = "▲ 레벨업 강화 (-1 SP)"
		upgrade_btn.disabled = false

func _on_upgrade_pressed() -> void:
	if not game_manager or game_manager.skill_points <= 0:
		return
	if not can_unlock_skill(selected_skill_id):
		return
	var lv = get_skill_level(selected_skill_id)
	if lv >= 5:
		return

	game_manager.skill_points -= 1
	player.upgrade_skill(selected_skill_id)
	game_manager._update_skill_point_hud()
	_refresh_all()

# ----------------------------------------------------
# 배경 원호 & 연결 성좌 라인을 그리는 서브 캔버스 클래스
# ----------------------------------------------------
class SkillTreeCanvas extends Control:
	var ui: SkillTreeUI = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if not ui:
			return

		var center_pt = Vector2(430, 560) # 부채꼴 아크의 중심점 (하단)

		# 1. 스타워즈 제다이 스타일 배경 동심원 아크 (Subtle Circle Arcs)
		var arc_col = Color(0.18, 0.28, 0.42, 0.25)
		draw_arc(center_pt, 140.0, -PI * 0.9, -PI * 0.1, 48, arc_col, 2.0, true)
		draw_arc(center_pt, 240.0, -PI * 0.9, -PI * 0.1, 64, arc_col, 1.5, true)
		draw_arc(center_pt, 340.0, -PI * 0.85, -PI * 0.15, 64, arc_col, 1.0, true)

		# 2. 스킬 간의 연결 성좌 선 (Connection Lines)
		for sk_id in ui.skills_meta.keys():
			var data = ui.skills_meta[sk_id]
			var parent_id = data.get("parent", "")
			if parent_id == "":
				continue
			var parent_data = ui.skills_meta.get(parent_id)
			if not parent_data:
				continue

			var p1 = parent_data["pos"]
			var p2 = data["pos"]

			var p_lv = ui.get_skill_level(parent_id)
			var c_lv = ui.get_skill_level(sk_id)

			var line_col: Color
			var line_width: float = 2.0

			if p_lv > 0 and c_lv > 0:
				# 연결된 양쪽 스킬이 모두 열림 -> 빛나는 골드/시안 라인
				line_col = Color(0.9, 0.8, 0.3, 0.9) if c_lv >= 5 else Color(0.4, 0.85, 1.0, 0.85)
				line_width = 3.5
			elif p_lv > 0 or c_lv > 0:
				# 한쪽이라도 습득된 상태 -> 부드러운 은회색 라인
				line_col = Color(0.5, 0.7, 0.85, 0.6)
				line_width = 2.0
			else:
				# 둘 다 미습득 상태 (자유 선택 가이드 연결선)
				line_col = Color(0.3, 0.4, 0.55, 0.35)
				line_width = 1.5

			draw_line(p1, p2, line_col, line_width, true)
