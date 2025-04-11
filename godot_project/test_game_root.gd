extends Node3D

@export var player_spawner: MultiplayerSpawner
var test_box_scene: PackedScene = preload("res://test_box.tscn")

@export var players_root_node: Node3D


func _enter_tree() -> void:
	player_spawner.spawn_function = spawn_player


func _ready() -> void:
	if not multiplayer.is_server(): return
	
	player_spawner.spawn(1)
	for peer_id: int in multiplayer.get_peers():
		player_spawner.spawn(peer_id)


func spawn_player(peer_id: int) -> Node:
	var new_box: Node3D = test_box_scene.instantiate()
	new_box.position = Vector3(randf_range(-9.0, 9.0), 0.0, -8.0)
	new_box.set_multiplayer_authority(peer_id)
	return new_box
