extends VBoxContainer

var players_list_item_scene: PackedScene = preload("res://UI/main_menu/components/lobby_players_list/lobby_menu_player_item.tscn")

@onready var _lobby: LobbyService = LobbyService

func _ready() -> void:
	_lobby.players_changed.connect(_on_lobby_players_changed)
	
func _on_lobby_players_changed(players: Dictionary[int, PlayerData]) -> void:
	for child: Control in get_children():
		child.queue_free()
	for player_id: int in players:
		var new_player_item: LobbyMenuPlayerItem = players_list_item_scene.instantiate()
		new_player_item.player_data = players[player_id]
		add_child(new_player_item)
