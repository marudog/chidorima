extends Node

@export var enemy_scene: PackedScene

@export var spawn_interval := 1.0 # 스폰 간격(초)
@export var is_active := true      # 스폰 활성화 여부

func _ready():
	var timer = $SpawnTimer
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true

func _on_spawn_timer_timeout():
	# L, R 자식 노드 목록 가져오기
		var spawn_points = [get_node("SpawnerL"), get_node("SpawnerR")]
		# 랜덤으로 하나 선택
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy) # 씬 트리에 직접 추가
		enemy.global_position = spawn_point.global_position
		spawn_interval = randf()