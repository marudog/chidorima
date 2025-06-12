extends Node

var enemy_speed_multiplier := 1.0

func _ready():
	var background = get_node("Background")
	background.background_changed.connect(_on_background_changed)

func _on_background_changed():
	enemy_speed_multiplier *= 1.05

func get_enemy_speed_multiplier():
	return enemy_speed_multiplier
