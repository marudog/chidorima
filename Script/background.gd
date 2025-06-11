extends Node2D

signal background_changed

@export var backgrounds: Array[Texture2D] = []
@onready var sprite = $Sprite2D # 배경 이미지를 표시하는 Sprite2D 노드

var current_index := 0

func _ready():
	if backgrounds.size() == 0:
		return
	sprite.texture = backgrounds[current_index]
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func _on_timer_timeout():
	var tween = create_tween()
	# 1. 알파값 0까지 페이드아웃
	tween.tween_property(sprite, "modulate:a", 0.5, 0.5)
	tween.tween_callback(func():
		# 2. 이미지 교체
		current_index = (current_index + 1) % backgrounds.size()
		sprite.texture = backgrounds[current_index]
		emit_signal("background_changed") # 배경 변경 신호 발생
	)
	# 3. 알파값 1까지 페이드인
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

func shake():
	var tween = create_tween()
	var original_pos = position
	tween.tween_property(self, "position", original_pos + Vector2(randf_range(-30, 30), randf_range(-30, 30)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)