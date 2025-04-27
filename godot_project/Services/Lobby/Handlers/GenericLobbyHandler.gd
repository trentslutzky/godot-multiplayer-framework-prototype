class_name GenericLobbyHandler
extends Node
##
## Generic version of the lobby handler class. Should not be instanced and used anywhere, and will
## be overidden by SteamLobbyHandler or LocalLobbyHandler when used in the lobby service.
##

# set up handler signals - we have to annotate them to ignore warnings since
# they are unused here and will be called in the inherited classes instead.
@warning_ignore("unused_signal")
signal creating_lobby  ## The handler started creating a lobby.
@warning_ignore("unused_signal")
signal created_lobby  ## The handler successfully created a lobby.
@warning_ignore("unused_signal")
signal failed_to_create_or_join(error_code: String, error_text: String)  ## The handler failed for <error_text>
@warning_ignore("unused_signal")
signal joining_lobby  ## The handler started joining a lobby
@warning_ignore("unused_signal")
signal joined_lobby  ## The handler successfully joined the lobby

var lobby_id: int = -1  ## The ID of the lobby

var _joined: bool = false  ## We have joined a lobby
var _joining: bool = false  ## We are currently trying to join a lobby
var _creating: bool = false  ## We are currently trying to create a lobby
var _created: bool = false  ## We have created a lobby


# set up generic functions for creating/joining/leaving (close)
func create_lobby() -> void:
	pass  ## Attempt to create a lobby


func join_lobby(_lobby_id: int = -1) -> void:
	pass  ## Attempt to join a lobby with loby id <lobby_id>


func close_peer() -> void:
	pass  ## Disconnect and close this peer


## Reset the state of this handler
func reset() -> void:
	_joined = false
	_joining = false
	_creating = false
	_created = false
	lobby_id = -1
