extends Node

signal game_starting

func host_start_game() -> void:
	_start_game.rpc()

@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
