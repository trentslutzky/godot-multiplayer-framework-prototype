extends Control

@export var lobby_title_label: RichTextLabel
@export var lobby_id_label: RichTextLabel
@export var players_label: RichTextLabel
@export var start_game_button: Button
@export var close_lobby_button: Button
@export var waiting_for_host_label: RichTextLabel

@onready var _lobby := LobbyService
@onready var _gameSequence := GameSequence

func _ready() -> void:
	close_lobby_button.pressed.connect(_on_close_lobby_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	# lobby signals
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.players_updated.connect(_on_lobby_players_updated)
	waiting_for_host_label.visible = false


func _on_close_lobby_button_pressed():
	_lobby.leave_lobby()


func _on_lobby_joined():
	lobby_id_label.text = str(_lobby.lobby_id) if _lobby.lobby_id != -1 else ""
	start_game_button.visible = _lobby.is_host
	close_lobby_button.text = "  CLOSE LOBBY" if _lobby.is_host else "  LEAVE LOBBY"
	waiting_for_host_label.visible = !_lobby.is_host


func _on_lobby_players_updated(players_data: Dictionary[int, PlayerData]):
	if players_data.has(1):
		lobby_title_label.text = players_data[1].username + "'s LOBBY"
	else:
		lobby_title_label.text = ""
	players_label.text = "Players" + "(" + str(players_data.size()) + "/8)"


func _on_start_game_button_pressed():
	_gameSequence.host_start_game()
