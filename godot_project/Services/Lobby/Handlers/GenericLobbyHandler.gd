extends Node
class_name GenericLobbyHandler

var peer: MultiplayerPeer

var joined: bool = false
var joining: bool = false
var creating: bool = false
var created: bool = false

@onready var _lobby := LobbyService

func reset():
	joined = false
	joining = false
	peer = null


func create_lobby() -> void:
	pass


func join_lobby(_lobby_id = -1) -> void:
	pass

func _process(_delta: float) -> void:
	if not joined and joining:
		if peer.get_connection_status() == 2:
			joined = true
			joining = false
			multiplayer.multiplayer_peer = peer
			_lobby.joined_lobby.emit()
	if not created and creating:
		if peer.get_connection_status() == 2:
			creating = false
			created = true
			multiplayer.multiplayer_peer = peer
			_lobby.created_lobby.emit()
