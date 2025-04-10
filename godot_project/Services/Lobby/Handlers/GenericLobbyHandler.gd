extends Node
class_name GenericLobbyHandler

var joined: bool = false
var joining: bool = false
var creating: bool = false
var created: bool = false

@warning_ignore("unused_signal")
signal creating_lobby

@warning_ignore("unused_signal")
signal created_lobby

@warning_ignore("unused_signal")
signal failed_to_create_or_join(error_text: String)

@warning_ignore("unused_signal")
signal joining_lobby

@warning_ignore("unused_signal")
signal joined_lobby

func reset() -> void:
	joined = false
	joining = false
	creating = false
	created = false


func create_lobby() -> void:
	pass


func join_lobby(_lobby_id: int = -1) -> void:
	pass


func close_peer() -> void:
	pass
