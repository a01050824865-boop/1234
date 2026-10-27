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
var wave_banner: Label = null
var wave_tween: Tween = null

var enemy_scene = preload("res://scenes/Enemy.tscn")

var score: int = 0
var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var current_wave: int = 1
var skill_points: int = 0
var skill_point_hud_btn: Button = null
var skill_point_hud_badge: Label = null
swswssdddddddvar skill_tree_script = preload("res://scripts/SkillTreeUI.gd")
var skill_tree_ui: Control = null

# Resource Stats
var mob_slime_stats = preload("res://resources/SlimeStats.tres")
var mob_bat_stats = preload("res://resources/BatStats.tres")
var mob_skel_stats = preload("res://resources/SkeletonStats.tres")
var mob_orc_stats = preload("res://resources/OrcStats.tres")
var mob_werewolf_stats = preload("res://resources/WerewolfStats.tres")
var mob_elite_orc_stats = preload("res://resources/EliteOrcStats.tres")
var mob_armored_orc_stats = preload("res://resources/ArmoredOrcStats.tres")
var mob_werebear_stats = preload("res://resources/WerebearStats.tres")
var mob_boss_minotaur_stats = preload("res://resources/BossMinotaurStats.tres")

# Boss Textures (Minotaur)
var tex_boss_walk = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Walk.png")
var tex_boss_atk = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Attack01.png")
var tex_boss_cleave = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Attack02.png")
var tex_boss_slam = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Attack03.png")
var tex_boss_hurt = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Hurt.png")
var tex_boss_death = preload("res://asset/Tiny RPG Character Asset Pack 02 -Full 20 Characters/Characters(100x100 split)/Minotaur/Minotaur with shadows/Minotaur_Death.png")

var boss_spawned: bool = false
var is_boss_alive: bool = false
var current_boss: Enemy = null
var boss_bar_container: Control = null
var boss_name_label: Label = null
var boss_hp_bar: ProgressBar = null
var boss_hp_text: Label = null

# Sprite Textures
var tex_slime = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png")
var tex_slime_attack = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime/Slime_Attack01.png")
var tex_slime_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Hurt.png")
var tex_slime_death = preload("res://asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Death.png")

var tex_bat = preload("res://asset/Characters01/Characters(100x100 split)/Bat/Bat/Bat_Flying.png")
var tex_bat_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Bat/Bat with shadows/Bat_Hurt.png")
var tex_bat_death = preload("res://asset/Characters01/Characters(100x100 split)/Bat/Bat with shadows/Bat_Death.png")

var tex_skel = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Walk.png")
var tex_skel_attack = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Attack01.png")
var tex_skel_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton with shadows/Skeleton_Hurt.png")
var tex_skel_death = preload("res://asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton with shadows/Skeleton_Death.png")

var tex_orc = preload("res://asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Walk.png")
var tex_orc_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Hurt.png")
var tex_orc_death = preload("res://asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Death.png")

var tex_werewolf = preload("res://asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Walk.png")
var tex_werewolf_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Hurt.png")
var tex_werewolf_death = preload("res://asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Death.png")

var tex_elite_orc = preload("res://asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Walk.png")
var tex_elite_orc_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Hurt.png")
var tex_elite_orc_death = preload("res://asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Death.png")

var tex_armored_orc = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Walk.png")
var tex_armored_orc_atk = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Attack01.png")
var tex_armored_orc_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Hurt.png")
var tex_armored_orc_death = preload("res://asset/Characters01/Characters(100x100 split)/Armored Orc/Armored Orc with shadows/Armored Orc_Death.png")

var tex_werebear = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Walk.png")
var tex_werebear_atk = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Attack01.png")
var tex_werebear_hurt = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Hurt.png")
var tex_werebear_death = preload("res://asset/Characters01/Characters(100x100 split)/Werebear/Werebear with shadows/Werebear_Death.png")

func _ready() -> void:
	player.add_to_group("player")
	player.health_changed.connect(_on_health_changed)
	player.exp_changed.connect(_on_exp_changed)
	player.level_up_triggered.connect(_on_level_up)
	player.player_died.connect(_on_player_died)
	restart_btn.pressed.connect(_on_restart_pressed)

	levelup_modal.visible = false
	gameover_modal.visible = false
	_setup_wave_banner()
	_setup_boss_ui()
	show_wave_announcement(1)
	_setup_skill_tree_hud_and_modal()

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	# 보스전 중에는 시간 및 웨이브 진행 정지
	if not is_boss_alive:
		elapsed_time += delta
		var new_wave = int(elapsed_time / 20.0) + 1 # 20초마다 새 웨이브 진입
		if new_wave != current_wave:
			current_wave = new_wave
			show_wave_announcement(current_wave)
			if current_wave >= 8 and not boss_spawned:
				spawn_boss()

	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60

	if is_boss_alive:
		timer_label.text = "⚠️ %02d:%02d [BOSS WAVE %d]" % [minutes, seconds, current_wave]
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	else:
		timer_label.text = "⏱️ %02d:%02d [WAVE %d]" % [minutes, seconds, current_wave]
		timer_label.remove_theme_color_override("font_color")

	update_shield_hud()

	# 보스가 살아있는 동안에는 일반 잡몹 스폰 전면 중단
	if is_boss_alive:
		spawn_timer = 0.0
		return

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
			enemy.init_enemy(mob_werebear_stats, tex_werebear, 8, tex_werebear_atk, 9, 70.0, tex_werebear_hurt, 4, tex_werebear_death, 4)
			enemy.scale = Vector2(2.4, 2.4)
		"armored_orc":
			# 중장갑 오크 (체력 750, 공격력 50, EXP 45)
			enemy.init_enemy(mob_armored_orc_stats, tex_armored_orc, 8, tex_armored_orc_atk, 7, 65.0, tex_armored_orc_hurt, 4, tex_armored_orc_death, 4)
			enemy.scale = Vector2(2.1, 2.1)
		"elite_orc":
			enemy.init_enemy(mob_elite_orc_stats, tex_elite_orc, 8, null, 6, 0.0, tex_elite_orc_hurt, 4, tex_elite_orc_death, 4)
			enemy.scale = Vector2(2.0, 2.0)
		"werewolf":
			enemy.init_enemy(mob_werewolf_stats, tex_werewolf, 8, null, 6, 0.0, tex_werewolf_hurt, 4, tex_werewolf_death, 4)
		"orc":
			enemy.init_enemy(mob_orc_stats, tex_orc, 8, null, 6, 0.0, tex_orc_hurt, 4, tex_orc_death, 4)
		"skeleton":
			enemy.init_enemy(mob_skel_stats, tex_skel, 8, tex_skel_attack, 6, 65.0, tex_skel_hurt, 4, tex_skel_death, 4)
		"bat":
			enemy.init_enemy(mob_bat_stats, tex_bat, 6, null, 6, 0.0, tex_bat_hurt, 4, tex_bat_death, 4)
		_:
			# slime (웨이브가 지나도 첫 웨이브 스탯 그대로 유지)
			enemy.init_enemy(mob_slime_stats, tex_slime, 6, tex_slime_attack, 6, 50.0, tex_slime_hurt, 4, tex_slime_death, 4)

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
func _setup_skill_tree_hud_and_modal() -> void:
	if not hud:
		return
	
	# 1. 스킬 트리 열기 버튼 (화면 우측 상단 HUD)
	skill_point_hud_btn = Button.new()
	skill_point_hud_btn.text = "📜 스킬 트리 (K / T)"
	skill_point_hud_btn.custom_minimum_size = Vector2(170, 36)
	skill_point_hud_btn.anchors_preset = Control.PRESET_TOP_RIGHT
	skill_point_hud_btn.anchor_left = 1.0
	skill_point_hud_btn.anchor_right = 1.0
	skill_point_hud_btn.offset_left = -190.0
	skill_point_hud_btn.offset_top = 70.0
	skill_point_hud_btn.offset_right = -20.0
	skill_point_hud_btn.offset_bottom = 106.0
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.16, 0.25, 0.92)
	btn_style.border_color = Color(0.9, 0.75, 0.25, 1.0)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	skill_point_hud_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.28, 0.45, 0.95)
	skill_point_hud_btn.add_theme_stylebox_override("hover", btn_hover)
	skill_point_hud_btn.pressed.connect(toggle_skill_tree)
	hud.add_child(skill_point_hud_btn)

	# 2. 보유 스킬 포인트 뱃지
	skill_point_hud_badge = Label.new()
	skill_point_hud_badge.text = "SP: 0"
	skill_point_hud_badge.anchors_preset = Control.PRESET_TOP_RIGHT
	skill_point_hud_badge.anchor_left = 1.0
	skill_point_hud_badge.anchor_right = 1.0
	skill_point_hud_badge.offset_left = -180.0
	skill_point_hud_badge.offset_top = 110.0
	skill_point_hud_badge.offset_right = -20.0
	skill_point_hud_badge.offset_bottom = 132.0
	skill_point_hud_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skill_point_hud_badge.add_theme_font_size_override("font_size", 14)
	skill_point_hud_badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	hud.add_child(skill_point_hud_badge)

	# 3. 스타워즈/성좌 스타일 전용 SkillTreeUI 생성 및 연결
	skill_tree_ui = skill_tree_script.new()
	skill_tree_ui.visible = false
	hud.add_child(skill_tree_ui)
	skill_tree_ui.setup(self, player)

func _on_level_up(_lvl: int) -> void:
	skill_points += 1
	_update_skill_point_hud()
	# 레벨업 시 스킬 트리 창 자동 팝업
	open_skill_tree()

func _update_skill_point_hud() -> void:
	if skill_point_hud_badge:
		skill_point_hud_badge.text = "SP: %d" % skill_points
		if skill_points > 0:
			skill_point_hud_badge.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		else:
			skill_point_hud_badge.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
	if skill_tree_ui and skill_tree_ui.visible:
		skill_tree_ui._refresh_all()

func toggle_skill_tree() -> void:
	if not skill_tree_ui:
		return
	if skill_tree_ui.visible:
		close_skill_tree()
	else:
		open_skill_tree()

func open_skill_tree() -> void:
	if not skill_tree_ui:
		return
	skill_tree_ui.open()
	_update_skill_point_hud()

func close_skill_tree() -> void:
	if not skill_tree_ui:
		return
	skill_tree_ui.close()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_K or event.physical_keycode == KEY_T:
			toggle_skill_tree()

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
func _setup_wave_banner() -> void:
	if not hud:
		return
	wave_banner = Label.new()
	wave_banner.name = "WaveBannerLabel"
	wave_banner.anchors_preset = Control.PRESET_CENTER
	wave_banner.anchor_left = 0.5
	wave_banner.anchor_top = 0.5
	wave_banner.anchor_right = 0.5
	wave_banner.anchor_bottom = 0.5
	wave_banner.offset_left = -300.0
	wave_banner.offset_top = -140.0
	wave_banner.offset_right = 300.0
	wave_banner.offset_bottom = -60.0
	wave_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wave_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	wave_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_banner.add_theme_font_size_override("font_size", 42)
	wave_banner.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
	wave_banner.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	wave_banner.add_theme_constant_override("shadow_offset_x", 3)
	wave_banner.add_theme_constant_override("shadow_offset_y", 3)
	wave_banner.modulate.a = 0.0
	wave_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(wave_banner)

func show_wave_announcement(wave_num: int) -> void:
	if not wave_banner:
		return
	wave_banner.text = "⚔️ WAVE %d ⚔️" % wave_num
	if wave_num >= 8:
		wave_banner.text = "⚠️ BOSS WAVE %d ⚠️" % wave_num
		wave_banner.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	else:
		wave_banner.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))

	if wave_tween and wave_tween.is_valid():
		wave_tween.kill()

	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(0.8, 0.8)
	wave_banner.pivot_offset = Vector2(300, 40)

	wave_tween = create_tween()
	# 페이드인 + 확대 (0.45초)
	wave_tween.parallel().tween_property(wave_banner, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_tween.parallel().tween_property(wave_banner, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 유지 (1.2초)
	wave_tween.tween_interval(1.2)
	# 페이드아웃 + 서서히 위로 이동 (0.6초)
	wave_tween.parallel().tween_property(wave_banner, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	wave_tween.parallel().tween_property(wave_banner, "scale", Vector2(1.15, 1.15), 0.6)

func _setup_boss_ui() -> void:
	if not hud:
		return
	boss_bar_container = Control.new()
	boss_bar_container.name = "BossUIContainer"
	boss_bar_container.anchors_preset = Control.PRESET_TOP_WIDE
	boss_bar_container.anchor_left = 0.5
	boss_bar_container.anchor_right = 0.5
	boss_bar_container.offset_left = -320.0
	boss_bar_container.offset_top = 40.0
	boss_bar_container.offset_right = 320.0
	boss_bar_container.offset_bottom = 95.0
	boss_bar_container.visible = false
	hud.add_child(boss_bar_container)

	boss_name_label = Label.new()
	boss_name_label.anchors_preset = Control.PRESET_TOP_WIDE
	boss_name_label.anchor_right = 1.0
	boss_name_label.offset_bottom = 26.0
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 20)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	boss_name_label.text = "👑 [중간보스] 미노타우로스 (Minotaur)"
	boss_bar_container.add_child(boss_name_label)

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.anchors_preset = Control.PRESET_BOTTOM_WIDE
	boss_hp_bar.anchor_top = 1.0
	boss_hp_bar.anchor_right = 1.0
	boss_hp_bar.anchor_bottom = 1.0
	boss_hp_bar.offset_top = -24.0
	boss_hp_bar.offset_bottom = 0.0
	boss_hp_bar.show_percentage = false

	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.12, 0.12, 0.15, 0.85)
	style_bg.set_corner_radius_all(6)
	style_bg.border_width_left = 2
	style_bg.border_width_top = 2
	style_bg.border_width_right = 2
	style_bg.border_width_bottom = 2
	style_bg.border_color = Color(0.8, 0.15, 0.15, 0.9)

	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.9, 0.15, 0.15, 1.0)
	style_fill.set_corner_radius_all(6)

	boss_hp_bar.add_theme_stylebox_override("background", style_bg)
	boss_hp_bar.add_theme_stylebox_override("fill", style_fill)
	boss_bar_container.add_child(boss_hp_bar)

	boss_hp_text = Label.new()
	boss_hp_text.anchors_preset = Control.PRESET_FULL_RECT
	boss_hp_text.anchor_right = 1.0
	boss_hp_text.anchor_bottom = 1.0
	boss_hp_text.offset_top = 31.0
	boss_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_hp_text.add_theme_font_size_override("font_size", 14)
	boss_hp_text.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	boss_hp_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_hp_text.text = "3500 / 3500"
	boss_bar_container.add_child(boss_hp_text)

func spawn_boss() -> void:
	if not is_instance_valid(player):
		return
	boss_spawned = true
	is_boss_alive = true

	# 1. 주변 일반 몬스터 제거 (보스 출현 집중)
	clear_nearby_monsters()

	# 2. 보스 스폰 (오브젝트 풀 간섭을 받지 않도록 독립 인스턴스로 즉시 생성)
	var boss_enemy = enemy_scene.instantiate() as Enemy
	if not boss_enemy:
		return

	var spawn_offset = Vector2(0, -220)
	boss_enemy.global_position = player.global_position + spawn_offset
	boss_enemy.scale = Vector2(3.0, 3.0)
	add_child(boss_enemy)
	boss_enemy.init_enemy(
		mob_boss_minotaur_stats,
		tex_boss_walk,
		8,
		tex_boss_atk,
		8,
		90.0,
		tex_boss_hurt,
		4,
		tex_boss_death,
		4,
		true,
		tex_boss_cleave,
		tex_boss_slam
	)

	current_boss = boss_enemy
	boss_enemy.boss_health_changed.connect(_on_boss_health_changed)
	boss_enemy.boss_died.connect(_on_boss_died)

	# 3. 보스 체력바 UI 표시
	if boss_bar_container:
		boss_hp_bar.max_value = mob_boss_minotaur_stats.max_health
		boss_hp_bar.value = mob_boss_minotaur_stats.max_health
		boss_hp_text.text = "%d / %d" % [ceil(mob_boss_minotaur_stats.max_health), ceil(mob_boss_minotaur_stats.max_health)]
		boss_bar_container.visible = true
		boss_bar_container.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(boss_bar_container, "modulate:a", 1.0, 0.6)

func clear_nearby_monsters() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e is Enemy and not e.is_boss:
			ObjectPool.recycle(e)

func _on_boss_health_changed(curr: float, max_val: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = max_val
		boss_hp_bar.value = max(0.0, curr)
	if boss_hp_text:
		boss_hp_text.text = "%d / %d" % [max(0, ceil(curr)), ceil(max_val)]

func _on_boss_died() -> void:
	is_boss_alive = false
	current_boss = null
	if boss_bar_container:
		var tw = create_tween()
		tw.tween_property(boss_bar_container, "modulate:a", 0.0, 0.8)
		tw.chain().tween_callback(func(): boss_bar_container.visible = false)
	# 보스 격퇴 알림
	wave_banner.text = "🏆 중간보스 격퇴 성공! 🏆"
	wave_banner.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	if wave_tween and wave_tween.is_valid():
		wave_tween.kill()
	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(0.8, 0.8)
	wave_tween = create_tween()
	wave_tween.parallel().tween_property(wave_banner, "modulate:a", 1.0, 0.4)
	wave_tween.parallel().tween_property(wave_banner, "scale", Vector2(1.0, 1.0), 0.4)
	wave_tween.tween_interval(1.8)
	wave_tween.parallel().tween_property(wave_banner, "modulate:a", 0.0, 0.6)
