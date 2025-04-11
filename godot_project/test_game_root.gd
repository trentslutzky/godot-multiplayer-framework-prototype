extends Node3D

var test_box_scene: PackedScene = preload("res://test_box.tscn")

@export var players_root_node: Node3D

func _ready() -> void:
	if not multiplayer.is_server(): return
	var new_box: Node3D = test_box_scene.instantiate()
	new_box.position = Vector3(randf_range(-9.0, 9.0), 0.0, -8.0)
	players_root_node.add_child(new_box)
