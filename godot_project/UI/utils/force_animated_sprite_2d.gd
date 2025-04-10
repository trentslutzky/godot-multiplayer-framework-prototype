extends AnimatedSprite2D

@export var animation_to_play: String = "default"

func _ready() -> void:
	play(animation_to_play)
