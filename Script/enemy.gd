extends Node2D

@onready var sprite = $Sprite2D
@onready var run_sound = $RunSound # RunSound는 AudioStreamPlayer 노드

var player
var move_direction := 1
var is_boosted := false
var health := 3
var speed = 0
var is_dead := false
var is_knockback := false
var has_entered_screen := false
var last_hit_sound_idx := -1

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
	speed = randf_range(200, 400)

	var main = get_tree().get_root().get_node("Main")
	speed *= main.get_enemy_speed_multiplier()

func _process(delta):
	if is_dead:
		# 죽은 후에는 회전하며 날아감
		rotation += 20 * delta
		position += dead_fly_dir * 600 * delta
		modulate.a -= 1.5 * delta # 점점 투명해짐
		if modulate.a <= 0:
			queue_free()

		$HitParticles.global_position = global_position
		return

	if is_knockback:
		$HitParticles.global_position = global_position
		return

	if player:
		var direction = (player.global_position - global_position).normalized()
		if move_direction == 1:
			if global_position.x < player.global_position.x:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
			global_position += direction * speed * delta
		else:
			global_position -= direction * speed * 5 * delta

		$HitParticles.global_position = global_position

	_check_out_of_screen()

func _check_out_of_screen():
	var viewport_rect = get_viewport().get_visible_rect()
	if viewport_rect.has_point(global_position):
		has_entered_screen = true
	elif has_entered_screen and not viewport_rect.has_point(global_position):
		queue_free()

# 대각선 반대 방향으로 날아가기 위한 변수
var dead_fly_dir := Vector2.ZERO

func knockback(dir: Vector2):
	if is_dead:
		return
	health -= 1
	if health > 0:
		is_knockback = true
		$Area2D.monitoring = false
		sprite.flip_v = true
		sprite.flip_h = true

		var tween = create_tween()
		var knockback_distance = 200
		var original_pos = global_position
		speed += 20
		tween.tween_property(self, "global_position", original_pos + dir * knockback_distance, 0.15)
		tween.finished.connect(_on_knockback_finished)
	else:
		die(dir)

	$HitParticles.restart()
	$HitParticles.emitting = true

	play_hit_sound()
	
func _on_knockback_finished():
	# 넉백 후 0.2초간 멈춤
	await get_tree().create_timer(0.2).timeout
	is_knockback = false
	$Area2D.monitoring = true
	sprite.flip_v = false
	sprite.flip_h = false

func die(dir: Vector2):
	is_dead = true
	$Area2D.monitoring = false
	# 적 기준 위쪽 반원(-135도 ~ -45도) 방향으로만 날아감
	var angle = deg_to_rad(randf_range(-135, -45))
	var fly_dir = Vector2(1, 0).rotated(angle) # (1, 0)은 오른쪽, 거기서 위쪽 반원만 회전
	var speed = randf_range(900, 1200)
	dead_fly_dir = fly_dir.normalized() * (speed / 600.0)
	set_physics_process(false)

	$HitParticles.restart()
	$HitParticles.emitting = true

	# 죽은 적 카운트 증가
	if player:
		player.add_kill()
		show_kill_combo(player.kill_count)

func _on_area_2d_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") and not is_boosted:
		move_direction = -1
		sprite.flip_h = not sprite.flip_h
		is_boosted = true
		body.on_hit_by_enemy()

		if run_sound:
			run_sound.play()

func play_hit_sound():
	var available_indices = []
	for i in range(8):
		if i != last_hit_sound_idx:
			var player = get_node("HitSound%d" % i)
			if not player.playing:
				available_indices.append(i)
	# 만약 모두 재생 중이면, 이전 인덱스만 제외하고 아무거나 재생
	if available_indices.is_empty():
		for i in range(8):
			if i != last_hit_sound_idx:
				available_indices.append(i)
	# 그래도 없으면 그냥 0번 사용
	if available_indices.is_empty():
		available_indices.append(0)
	var idx = available_indices[randi() % available_indices.size()]
	var player = get_node("HitSound%d" % idx)
	player.play()
	last_hit_sound_idx = idx

func show_kill_combo(kill_count: int):
	if kill_count < 2:
		return
	var combo_scene = preload("res://ComboLabel.tscn")
	var combo_label = combo_scene.instantiate()
	var ui_layer = get_tree().get_root().find_child("ComboControl", true, false)
	ui_layer.add_child(combo_label)

	# 플레이어 머리 위 중앙 좌표 계산
	var player_pos = player.global_position if player else global_position
	var ui_pos = ui_layer.global_position
	combo_label.position = (player_pos + Vector2(-50, -240)) - ui_pos
	combo_label.text = "%d K.O" % kill_count
