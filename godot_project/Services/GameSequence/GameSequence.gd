extends Node

signal game_starting
signal game_started

var un_stared_peers: PackedInt32Array = []

func host_start_game() -> void:
	un_stared_peers = multiplayer.get_peers()
	_start_game.rpc()


func _all_players_loaded() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	game_starting.emit()
	if multiplayer.is_server(): return
	get_tree().change_scene_to_file("res://game.tscn")
	_scene_changed.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _scene_changed() -> void:
	for i: int in range(un_stared_peers.size()):
		if un_stared_peers.get(i) == multiplayer.get_remote_sender_id():
			un_stared_peers.remove_at(i)
	if un_stared_peers.size() == 0:
		_all_players_loaded()
		return
