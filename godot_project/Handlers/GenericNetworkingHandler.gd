extends Node
class_name GenericNetworkingHandler

@onready var _net := NetworkingService

var peer: MultiplayerPeer

var joined: bool = false
var joining: bool = false


func _ready() -> void:
	multiplayer.server_disconnected.connect(_reset)


func reset():
	joined = false
	joining = false


func _reset():
	joined = false
	joining = false


func lobby_host() -> void:
	pass


func lobby_join(_lobby_id = -1) -> void:
	pass
