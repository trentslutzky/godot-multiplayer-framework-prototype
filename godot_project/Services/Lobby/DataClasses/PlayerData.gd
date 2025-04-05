extends Node
class_name PlayerData

@export var peer_id: int = -1
@export var steam_id: int = -1
@export var username: String = ""

func serialize() -> Dictionary[String, Variant]:
	return {
		"peer_id": self.peer_id,
		"steam_id": self.steam_id,
		"username": self.username,
	}

static func deserialize(data: Dictionary) -> PlayerData:
	var player_data := PlayerData.new()
	player_data.peer_id = data.get("peer_id", -1)
	player_data.username = data.get("username", "")
	player_data.steam_id = data.get("steam_id", -1)
	return player_data
