class_name GameManager
extends Node2D

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var exp_bar: ProgressBar = $HUD/ExpBar
@onready var exp_label: Label = $HUD/ExpLabel
@onready var hp_label: Label = $HUD/HPLabel
@onready var shield_status_label: Label = $HUD/ShieldStatusLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var levelup_modal: Control = $HUD/LevelUpModal
@onready var cards_container: HBoxContainer = $HUD/LevelUpModal/VBoxContainer/CardsContainer
@onready var gameover_modal: Control = $HUD/GameOverModal
@onready var final_score_label: Label = $HUD/GameOverModal/VBoxContainer/FinalScoreLabel
@onready var restart_btn: Button = $HUD/GameOverModal/VBoxContainer/RestartButton

var enemy_scene = preload("res://scenes/Enemy.tscn")

var score: int = 0
var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var current_wave: int = 1

# Resource Stats
var mob_slime_stats = preload("res://resources/SlimeStats.tres")
var mob_bat_stats = preload("res://resources/BatStats.tres")
var mob_skel_stats = preload("res://resources/SkeletonStats.tres")
var mob_orc_stats = preload("res://resources/OrcStats.tres")
var mob_werewolf_stats = preload("res://resources/WerewolfStats.tres")
var mob_elite_orc_stats = preload("res://resources/EliteOrcStats.tres")
var mob_armored_orc_stats = preload("res://resources/ArmoredOrcStats.tres")
var mob_werebear_stats = preload("res://resources/WerebearStats.tres")

# Sprite Textures
var tex_slime = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png")
var tex_slime_attack = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime/Slime_Attack01.png")
var tex_bat = preload("res://asset/Characters01/Characters(100x100 split)/Bat/Bat/Bat_Flying.png")
var tex_skel = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Walk.png")
var tex_skel_attack = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Attack01.png")
var tex_orc = preload("res://asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Walk.png")
var tex_werewolf = preload("res://asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Walk.png")
var tex_elite_orc = preload("res://asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Walk.png")
var tex_armored_orc = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Walk.png")
var tex_armored_orc_atk = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Attack01.png")
var tex_werebear = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Walk.png")
var tex_werebear_atk = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Attack01.png")

func _ready() -> void:
	player.add_to_group("player")
	player.health_changed.connect(_on_health_changed)
	player.exp_changed.connect(_on_exp_changed)
	player.level_up_triggered.connect(_on_level_up)
	player.player_died.connect(_on_player_died)
	restart_btn.pressed.connect(_on_restart_pressed)

	levelup_modal.visible = false
	gameover_modal.visible = false

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	elapsed_time += delta
	current_wave = int(elapsed_time / 20.0) + 1 # 20초마다 새 웨이브 진입
	
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	timer_label.text = "⏱️ %02d:%02d [WAVE %d]" % [minutes, seconds, current_wave]

	update_shield_hud()

	# Spawner: 웨이브가 오를수록 젠 주기 대폭 단축 & 한 번에 소환되는 몬스터 수 대폭 증가
	spawn_timer += delta
	var spawn_rate = max(0.18, 1.2 - (current_wave - 1) * 0.1)
	if spawn_timer >= spawn_rate:
		spawn_timer = 0.0
		# 후반부로 갈수록 한 번에 여러 마리의 몬스터 소환 (스킬 난사에 맞추어 개체 수 유지)
		var spawn_batch = 1
		if current_wave >= 7:
			spawn_batch = randi_range(4, 7)
		elif current_wave >= 5:
			spawn_batch = randi_range(3, 5)
		elif current_wave >= 3:
			spawn_batch = randi_range(2, 3)
		elif current_wave >= 2:
			spawn_batch = randi_range(1, 2)
		
		for i in range(spawn_batch):
			spawn_enemy()

func spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var dist = 520.0 + randf() * 100.0
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var enemy = ObjectPool.spawn(enemy_scene, self) as Enemy
	if not enemy:
		return
	enemy.global_position = pos

	# 웨이브별 몬스터 출현 풀 및 확률 테이블 (후반부로 갈수록 더 강력한 몬스터 출현)
	var roll = randf() * 100.0
	var chosen_type = "slime"

	match current_wave:
		1:
			# Wave 1 (0~20s): 슬라임만 100%
			chosen_type = "slime"
		2:
			# Wave 2 (20~40s): 박쥐(빠름) 대량 출현 + 슬라임
			if roll < 70.0:
				chosen_type = "bat"
			else:
				chosen_type = "slime"
		3:
			# Wave 3 (40~60s): 스켈레톤(단단함) 등장 + 박쥐 + 슬라임
			if roll < 50.0:
				chosen_type = "skeleton"
			elif roll < 80.0:
				chosen_type = "bat"
			else:
				chosen_type = "slime"
		4:
			# Wave 4 (60~80s): 오크(강한 파괴력/체력) 등장 + 스켈레톤 + 박쥐 + 슬라임
			if roll < 45.0:
				chosen_type = "orc"
			elif roll < 75.0:
				chosen_type = "skeleton"
			elif roll < 90.0:
				chosen_type = "bat"
			else:
				chosen_type = "slime"
		5:
			# Wave 5 (80~100s): 늑대인간(고속 돌진/강공격) 등장 + 오크 + 스켈레톤 + 박쥐
			if roll < 40.0:
				chosen_type = "werewolf"
			elif roll < 70.0:
				chosen_type = "orc"
			elif roll < 90.0:
				chosen_type = "skeleton"
			else:
				chosen_type = "bat"
		6:
			# Wave 6 (100~120s): 중장갑 오크 & 엘리트 오크 등장 + 늑대인간 + 오크
			if roll < 25.0:
				chosen_type = "armored_orc"
			elif roll < 50.0:
				chosen_type = "elite_orc"
			elif roll < 80.0:
				chosen_type = "werewolf"
			else:
				chosen_type = "orc"
		7:
			# Wave 7 (120~140s): 중장갑 오크 주력 + 엘리트 오크 + 늑대인간
			if roll < 35.0:
				chosen_type = "armored_orc"
			elif roll < 65.0:
				chosen_type = "elite_orc"
			elif roll < 90.0:
				chosen_type = "werewolf"
			else:
				chosen_type = "orc"
		_:
			# Wave 8+ (140s+): 거대 웨어베어(보스급 체력 1450, EXP 85) + 중장갑 오크 + 엘리트 오크 + 늑대인간
			if roll < 20.0:
				chosen_type = "werebear"
			elif roll < 50.0:
				chosen_type = "armored_orc"
			elif roll < 75.0:
				chosen_type = "elite_orc"
			else:
				chosen_type = "werewolf"

	match chosen_type:
		"werebear":
			# 거대 베어비스트 (체력 1450, 공격력 70, EXP 85)
			enemy.init_enemy(mob_werebear_stats, tex_werebear, 8, tex_werebear_atk, 9, 70.0)
			enemy.scale = Vector2(2.4, 2.4)
		"armored_orc":
			# 중장갑 오크 (체력 750, 공격력 50, EXP 45)
			enemy.init_enemy(mob_armored_orc_stats, tex_armored_orc, 8, tex_armored_orc_atk, 7, 65.0)
			enemy.scale = Vector2(2.1, 2.1)
		"elite_orc":
			enemy.init_enemy(mob_elite_orc_stats, tex_elite_orc, 8)
			enemy.scale = Vector2(2.0, 2.0)
		"werewolf":
			enemy.init_enemy(mob_werewolf_stats, tex_werewolf, 8)
		"orc":
			enemy.init_enemy(mob_orc_stats, tex_orc, 8)
		"skeleton":
			enemy.init_enemy(mob_skel_stats, tex_skel, 8, tex_skel_attack, 6, 65.0)
		"bat":
			enemy.init_enemy(mob_bat_stats, tex_bat, 6)
		_:
			# slime (웨이브가 지나도 첫 웨이브 스탯 그대로 유지)
			enemy.init_enemy(mob_slime_stats, tex_slime, 6, tex_slime_attack, 6, 50.0)

func update_shield_hud() -> void:
	if not shield_status_label or not is_instance_valid(player):
		return
	var shield_lv = player.skills.get("shield", 0)
	if shield_lv <= 0:
		shield_status_label.text = ""
		return

	if player.shield_timer > 0.0:
		shield_status_label.text = "🛡️ [Q] 무적 방어 중! (%.1f초)" % player.shield_timer
		shield_status_label.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0, 1.0))
	elif player.shield_cooldown_timer > 0.0:
		shield_status_label.text = "🛡️ [Q] 방패 쿨타임 (%.1f초)" % player.shield_cooldown_timer
		shield_status_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.8))
	else:
		var cur_dur = 2.5 + (shield_lv - 1) * 1.0
		shield_status_label.text = "🛡️ [Q] 방패 준비 완료 (지속 %.1f초)" % cur_dur
		shield_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))

func _on_health_changed(curr: float, max_hp: float) -> void:
	hp_label.text = "❤️ HP: %d / %d" % [ceil(curr), ceil(max_hp)]

func _on_exp_changed(curr: int, max_exp: int) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = curr
	exp_label.text = "EXP %d / %d" % [curr, max_exp]
	level_label.text = "⭐ LV: %d" % player.level

@warning_ignore("unused_parameter")
func _on_level_up(lvl: int) -> void:
	get_tree().paused = true
	levelup_modal.visible = true
	var title_node = levelup_modal.get_node_or_null("VBoxContainer/Title")
	if title_node:
		title_node.text = "⚡ 레벨 업! [LV %d] 스킬 선택 ⚡" % lvl

	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()

	var all_skills = [
		{
			"id": "shield",
			"name": "성스러운 철벽 [Q]",
			"desc": "Q키로 발동하는 무적 방패입니다. 지속시간이 +1초 늘어납니다 (쿨타임 15초).",
			"icon": "res://asset/holy_shield_crop.png",
			"hframes": 1,
			"frame": 0
		},
		{
			"id": "slash",
			"name": "기사 검기 (Slash)",
			"desc": "전방으로 날카로운 은빛 검기를 날려 적들을 관통합니다.",
			"icon": "res://asset/knight_slash_wave.png",
			"hframes": 6,
			"frame": 1
		},
		{
			"id": "orbit",
			"name": "수호의 보주 (Orbit)",
			"desc": "주위를 성스러운 보주가 공전하며 접근하는 적을 타격합니다.",
			"icon": "res://asset/shield_orb_icon.png",
			"hframes": 1,
			"frame": 0
		},
		{
			"id": "lightning",
			"name": "낙뢰 폭격 (Lightning)",
			"desc": "하늘에서 강력한 번개를 소환해 무작위 적을 강타합니다.",
			"icon": "res://asset/Characters01/Magic(Projectile)/Wizard_Attack01_Effect.png",
			"hframes": 10,
			"frame": 3
		},
		{
			"id": "arrows",
			"name": "화살 폭풍 (Arrows)",
			"desc": "사방 360도로 관통 화살을 일제 발사합니다.",
			"icon": "res://asset/Characters01/Arrow(Projectile)/Arrow01(32x32).png",
			"hframes": 1,
			"frame": 0
		},
		{
			"id": "speed",
			"name": "신속의 장화 (Speed)",
			"desc": "기사의 이동 속도가 영구적으로 +15% 증가합니다.",
			"icon": "res://asset/Characters01/Characters(100x100 split)/Knight/Knight/Knight_Walk.png",
			"hframes": 8,
			"frame": 3
		},
		{
			"id": "health",
			"name": "거인의 심장 (Health)",
			"desc": "최대 체력 +25 증가 및 체력을 35 즉시 회복합니다.",
			"icon": "res://asset/Characters01/Magic(Projectile)/Priest_Attack_effect.png",
			"hframes": 5,
			"frame": 2
		},
		{
			"id": "regen",
			"name": "성스러운 재생 (Regen)",
			"desc": "초당 체력을 지속적으로 회복합니다.",
			"icon": "res://asset/Characters01/Magic(Projectile)/Priest_Heal_effect.png",
			"hframes": 4,
			"frame": 2
		}
	]
	all_skills.shuffle()

	for i in range(min(3, all_skills.size())):
		var sk = all_skills[i]
		var cur_lv = player.skills.get(sk["id"], 0)
		var is_awakening_next = sk["id"] == "slash" and cur_lv == 4
		var sk_name = "🔥 진홍의 염제 검기 (각성)" if is_awakening_next else sk["name"]
		var sk_desc = "검기가 붉은 화염으로 각성합니다! 사거리·공속·반경·공격력 대폭 상승 & 화염 지속 피해(Burn DoT) 부여!" if is_awakening_next else (
			"Q키 방어 지속시간이 +1초 늘어납니다 (현재 %.1f초 ➡️ %.1f초, 쿨타임 15초)" % [2.5 + (cur_lv - 1) * 1.0, 2.5 + cur_lv * 1.0] if sk["id"] == "shield" else sk["desc"]
		)
		var lv_text = "⚡ [스킬 최종 각성 진화!]" if is_awakening_next else ("현재 LV %d ➡️ LV %d" % [cur_lv, cur_lv + 1] if sk["id"] != "health" else "체력 보너스")

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(250, 260)

		# Style the card box
		var style = StyleBoxFlat.new()
		if is_awakening_next:
			style.bg_color = Color(0.22, 0.08, 0.08, 0.98)
			style.border_color = Color(1.0, 0.4, 0.1, 1.0)
			style.set_border_width_all(3)
		else:
			style.bg_color = Color(0.12, 0.14, 0.2, 0.95)
			style.border_color = Color(0.9, 0.75, 0.3, 1.0)
			style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 14
		style.content_margin_bottom = 14
		panel.add_theme_stylebox_override("panel", style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		panel.add_child(vbox)

		# Icon TextureRect
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		var raw_tex = load(sk["icon"]) as Texture2D
		if raw_tex:
			var atlas = AtlasTexture.new()
			atlas.atlas = raw_tex
			var w = raw_tex.get_width() / sk["hframes"]
			var h = raw_tex.get_height()
			atlas.region = Rect2(sk["frame"] * w, 0, w, h)
			tex_rect.texture = atlas
		if is_awakening_next:
			tex_rect.modulate = Color(3.0, 0.7, 0.2, 1.0)
		vbox.add_child(tex_rect)

		# Skill Name Label
		var name_lbl = Label.new()
		name_lbl.text = sk_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2) if is_awakening_next else Color(1.0, 0.9, 0.4))
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)

		# Level Tag
		var lv_lbl = Label.new()
		lv_lbl.text = lv_text
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if is_awakening_next else Color(0.4, 0.85, 1.0))
		lv_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(lv_lbl)

		# Description Label
		var desc_lbl = Label.new()
		desc_lbl.text = sk_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(desc_lbl)

		# Select Button
		var sel_btn = Button.new()
		sel_btn.text = "⚡ 습득 / 강화"
		sel_btn.custom_minimum_size = Vector2(0, 36)
		var btn_sk_id = sk["id"]
		sel_btn.pressed.connect(func():
			player.upgrade_skill(btn_sk_id)
			levelup_modal.visible = false
			get_tree().paused = false
		)
		vbox.add_child(sel_btn)

		cards_container.add_child(panel)

func add_score(amount: int) -> void:
	score += amount
	if score_label:
		score_label.text = "🏆 SCORE: %d" % score

func _on_player_died() -> void:
	get_tree().paused = true
	if final_score_label:
		final_score_label.text = "최종 점수: %d" % score
	gameover_modal.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()