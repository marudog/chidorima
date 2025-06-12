extends Node

@export var KO : Label
@export var Miss : Label
@export var Score : Label
@export var StartButton : Button

var kill_count
var miss

func _ready() -> void:
	KO.text = "KO : " + str(kill_count)
	Miss.text = "Miss : " + str(miss)
	var score = max((kill_count * 500) - (miss * 100), 0)
	Score.text = "Score : " + str(score)

	StartButton.visible = false
	# 2초 뒤에 보이게
	await get_tree().create_timer(2.0).timeout
	StartButton.visible = true

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://title.tscn")
