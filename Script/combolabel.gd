extends Label

@export var duration := 0.7

func _ready():
	modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_property(self, "position", position + Vector2(0, -100), duration)
	tween.tween_callback(queue_free)