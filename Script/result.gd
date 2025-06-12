extends Node

@export var KO : Label
@export var Miss : Label
@export var Score : Label

var kill_count
var miss

func _ready() -> void:
	KO.text = "KO : " + str(kill_count)
	Miss.text = "Miss : " + str(miss)
	Score.text = "Score : " + str((kill_count * 500) - (miss * 100))

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://title.tscn")
