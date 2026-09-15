class_name GameManager
extends Node2D

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var exp_bar: ProgressBar = $HUD/ExpBar
@onready var exp_label: Label = $HUD/ExpLabel
@onready var hp_label: Label = $HUD/HPLabel
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

# Sprite Textures
var tex_slime = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png")
var tex_bat = preload("res://asset/Characters01/Characters(100x100 split)/Bat/Bat/Bat_Flying.png")
var tex_skel = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton with shadows/Skeleton_Walk.png")
var tex_orc = preload("res://asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Walk.png")
var tex_werewolf = preload("res://asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Walk.png")
var tex_elite_orc = preload("res://asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Walk.png")

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

	# Spawner: 웨이브가 오를수록 젠 주기 단축
	spawn_timer += delta
	var spawn_rate = max(0.25, 1.4 - (current_wave - 1) * 0.12)
	if spawn_timer >= spawn_rate:
		spawn_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var dist = 520.0 + randf() * 100.0
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos

	# 웨이브별 몬스터 출현 풀 및 확률 테이블 (슬라임은 기본 스탯 고정 유지, 신규 웨이브마다 새로운 몬스터 등장)
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
		_:
			# Wave 6+ (100s+): 엘리트 오크(보스급 체력) + 늑대인간 + 오크 + 스켈레톤
			if roll < 25.0:
				chosen_type = "elite_orc"
			elif roll < 60.0:
				chosen_type = "werewolf"
			elif roll < 85.0:
				chosen_type = "orc"
			else:
				chosen_type = "skeleton"

	match chosen_type:
		"elite_orc":
			enemy.stats = mob_elite_orc_stats.duplicate()
			enemy.sprite_texture = tex_elite_orc
			enemy.frames_count = 8
		"werewolf":
			enemy.stats = mob_werewolf_stats.duplicate()
			enemy.sprite_texture = tex_werewolf
			enemy.frames_count = 8
		"orc":
			enemy.stats = mob_orc_stats.duplicate()
			enemy.sprite_texture = tex_orc
			enemy.frames_count = 8
		"skeleton":
			enemy.stats = mob_skel_stats.duplicate()
			enemy.sprite_texture = tex_skel
			enemy.frames_count = 8
		"bat":
			enemy.stats = mob_bat_stats.duplicate()
			enemy.sprite_texture = tex_bat
			enemy.frames_count = 6
		_:
			# slime (웨이브가 지나도 첫 웨이브 스탯 그대로 유지)
			enemy.stats = mob_slime_stats.duplicate()
			enemy.sprite_texture = tex_slime
			enemy.frames_count = 6

	add_child(enemy)

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
			"id": "slash",
			"name": "기사 검기 (Slash)",
			"desc": "전방으로 날카로운 은빛 검기를 날려 적들을 관통합니다.",
			"icon": "res://asset/knight_slash_wave.png",
			"hframes": 6,
			"frame": 1
		},
		{
			"id": "orbit",
			"name": "수호 방패 (Orbit)",
			"desc": "주위를 성스러운 방패가 공전하며 접근하는 적을 타격합니다.",
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
		var lv_text = "현재 LV %d ➡️ LV %d" % [cur_lv, cur_lv + 1] if sk["id"] != "health" else "체력 보너스"

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(250, 260)

		# Style the card box
		var style = StyleBoxFlat.new()
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
		vbox.add_child(tex_rect)

		# Skill Name Label
		var name_lbl = Label.new()
		name_lbl.text = sk["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)

		# Level Tag
		var lv_lbl = Label.new()
		lv_lbl.text = lv_text
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		lv_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(lv_lbl)

		# Description Label
		var desc_lbl = Label.new()
		desc_lbl.text = sk["desc"]
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
	if final_score_label:
		final_score_label.text = "최종 점수: %d" % score
	gameover_modal.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()