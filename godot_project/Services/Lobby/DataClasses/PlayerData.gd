extends Node
class_name PlayerData

@export var peer_id: int = -1
@export var steam_id: int = -1
@export var username: String = ""

@onready var _lobby := LobbyService

func initialize(_peer_id: int, _username: String):
	self.peer_id = _peer_id
	self.username = _username
	
#	if _lobby.using_steam:
#		self.steam_id = _lobby.handler.peer.get_steam64_from_peer_id(_peer_id)


func serialize() -> Dictionary[String, Variant]:
	return {
		"peer_id": self.peer_id,
		"steam_id": self.steam_id,
		"username": self.username,
	}


static func deserialize(data: Dictionary) -> PlayerData:
	var player_data := PlayerData.new()
	player_data.initialize(
		data.get("peer_id", 0),
		data.get("username", "")
	)
	return player_data
