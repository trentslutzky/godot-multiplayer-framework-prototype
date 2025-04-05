extends Node
class_name GenericLobbyHandler

var peer: MultiplayerPeer

var joined: bool = false
var joining: bool = false
var creating: bool = false


func reset():
	joined = false
	joining = false
	peer = null


func create_lobby() -> void:
	pass


func join_lobby(_lobby_id = -1) -> void:
	pass
