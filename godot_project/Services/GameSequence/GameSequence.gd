extends Node

signal game_starting
signal game_started

func host_start_game() -> void:
	_start_game.rpc()

@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	game_starting.emit()
	get_tree().change_scene_to_file("res://game.tscn")
	await get_tree().create_timer(2.0)
