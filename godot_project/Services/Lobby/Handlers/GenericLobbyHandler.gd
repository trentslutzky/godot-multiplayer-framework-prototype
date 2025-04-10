extends Node
class_name GenericLobbyHandler

var joined: bool = false
var joining: bool = false
var creating: bool = false
var created: bool = false

signal creating_lobby
signal created_lobby
signal failed_to_create_or_join(error_text: String)
signal joining_lobby
signal joined_lobby

func reset():
	joined = false
	joining = false
	creating = false
	created = false


func create_lobby() -> void:
	pass


func join_lobby(_lobby_id = -1) -> void:
	pass
