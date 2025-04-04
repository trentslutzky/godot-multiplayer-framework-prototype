extends Node
class_name GenericNetworkingHandler

var peer: MultiplayerPeer

var joined: bool = false
var joining: bool = false


func reset():
	joined = false
	joining = false
	peer = null


func lobby_host() -> void:
	pass


func lobby_join(_lobby_id = -1) -> void:
	pass
