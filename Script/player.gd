extends Node2D

const FRAME_WIDTH = 320
const FRAME_HEIGHT = 320
const IMAGE_WIDTH = 1280
const IMAGE_HEIGHT = 960
const START_ROW = 1 # 0부터 시작, 2번째 줄

@onready var sprite = $Sprite2D
@onready var left_hit = get_tree().get_root().find_child("LeftHit", true, false)
@onready var right_hit = get_tree().get_root().find_child("RightHit", true, false)
@onready var miss_sound = get_node("MissSound")
@onready var heart_container = get_tree().get_root().find_child("HeartContainer", true, false)
@export var heart_texture: Texture2D
@export var left_hit_active: Texture2D
@export var left_hit_inactive: Texture2D
@export var right_hit_active: Texture2D
@export var right_hit_inactive: Texture2D

var current_frame := 0
var max_frame := int(IMAGE_WIDTH / FRAME_WIDTH) - 1
var attack_offset := 80 # 이동할 거리(픽셀)

var is_attacking := false
var prev_frame := -1
var prev_row := -1
var attack_range := 200
var kill_count := 0
var miss := 0

var hp := 3

func _ready() -> void:
	var atlas_texture = sprite.texture

	if atlas_texture is AtlasTexture:
		# AtlasTexture로 캐스팅
		atlas_texture = atlas_texture as AtlasTexture
		# 예: atlas_texture.region_rect에 접근

	update_hearts()

func _process(delta):
	attack_range_check()

func _input(event):
	if event is InputEventKey and event.pressed and not is_attacking:
		is_attacking = true
		var new_frame = current_frame
		var new_row = 1
		while true:
			new_frame = randi() % (max_frame + 1)
			new_row = 1 + randi() % 2
			if new_frame != prev_frame or new_row != prev_row:
				break
		current_frame = new_frame
		prev_frame = current_frame
		prev_row = new_row

		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			sprite.flip_h = false
			update_sprite_region(new_row)
			attack_motion(attack_offset)
			attack_check()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			sprite.flip_h = true
			update_sprite_region(new_row)
			attack_motion(-attack_offset)
			attack_check()

 # 모바일 터치 대응
	if (
		(event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton)
		and event.pressed and not is_attacking
	):
		is_attacking = true
		var new_frame = current_frame
		var new_row = 1
		while true:
			new_frame = randi() % (max_frame + 1)
			new_row = 1 + randi() % 2
			if new_frame != prev_frame or new_row != prev_row:
				break
		current_frame = new_frame
		prev_frame = current_frame
		prev_row = new_row

		var screen_center = get_viewport().size.x / 2
		var pos = event.position if event.has_method("position") else event.global_position
		if pos.x > screen_center:
			# 오른쪽 터치
			sprite.flip_h = false
			update_sprite_region(new_row)
			attack_motion(attack_offset)
			attack_check()
		else:
			# 왼쪽 터치
			sprite.flip_h = true
			update_sprite_region(new_row)
			attack_motion(-attack_offset)
			attack_check()

func update_sprite_region(row):
	var sprite = $Sprite2D
	var atlas_texture = sprite.texture
	if atlas_texture is AtlasTexture:
		atlas_texture = atlas_texture as AtlasTexture
		# region의 x는 프레임 인덱스 * 프레임 너비, y는 row * 프레임 높이
		atlas_texture.region.position = Vector2(current_frame * FRAME_WIDTH, row * FRAME_HEIGHT)
		sprite.texture = atlas_texture

func attack_check():
	var player_pos = global_position
	var attack_dir = sprite.flip_h if sprite.flip_h else false
	var background = get_tree().get_root().find_child("Background", true, false)
	var hit_success := false

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.is_boosted:
			continue
			
		var enemy_pos = enemy.global_position
		var dir = enemy_pos - player_pos

		if attack_dir and dir.x < 0 and abs(dir.x) < attack_range and abs(dir.y) < FRAME_HEIGHT / 2:
			enemy.knockback(Vector2(-1, 0))
			hit_success = true
		elif not attack_dir and dir.x > 0 and abs(dir.x) < attack_range and abs(dir.y) < FRAME_HEIGHT / 2:
			enemy.knockback(Vector2(1, 0))
			hit_success = true

	if hit_success:
		if background:
			background.shake()
	else:
		# 공격이 빗나간 경우 효과음 재생
		if miss_sound:
			miss_sound.play()

		miss += 1


func attack_motion(offset):
	var tween = create_tween()
	var original_pos = sprite.position
	tween.tween_property(sprite, "position", original_pos + Vector2(offset, 0), 0.04)
	tween.tween_property(sprite, "position", original_pos, 0.04)
	tween.finished.connect(_on_attack_motion_finished)

func _on_attack_motion_finished():
	is_attacking = false

func attack_range_check():
	var attack_range := 200
	var player_pos = global_position
	var left_active = false
	var right_active = false

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var dir = enemy.global_position - player_pos
		if dir.x < 0 and abs(dir.x) < attack_range and abs(dir.y) < FRAME_HEIGHT / 2:
			left_active = true
		elif dir.x > 0 and abs(dir.x) < attack_range and abs(dir.y) < FRAME_HEIGHT / 2:
			right_active = true

	# 버튼 이미지 변경
	left_hit.icon = left_hit_active if left_active else left_hit_inactive
	right_hit.icon = right_hit_active if right_active else right_hit_inactive

func add_kill():
	kill_count += 1

func on_hit_by_enemy():
	hp -= 1
	attack_range += 20
	update_hearts()

	if hp <= 0:
		goto_result()

func goto_result():
	var result_scene = preload("res://Result.tscn")
	var result = result_scene.instantiate()
	result.kill_count = kill_count
	result.miss = miss
	get_tree().root.add_child(result)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = result

func update_hearts():
	if not heart_container:
		return
	# 기존 하트 제거
	for child in heart_container.get_children():
		child.queue_free()
	# 현재 hp만큼 하트 추가
	for i in range(hp):
		var heart = TextureRect.new()
		heart.texture = heart_texture
		heart_container.add_child(heart)