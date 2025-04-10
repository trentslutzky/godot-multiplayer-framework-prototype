extends Node

signal game_starting

func host_start_game():
	_start_game.rpc()

@rpc("authority", "call_local", "reliable")
func _start_game():
	print("GAME STARTING....")
	game_starting.emit()
