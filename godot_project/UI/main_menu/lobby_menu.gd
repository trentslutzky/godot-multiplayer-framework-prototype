extends Control

@export var lobby_title_label: RichTextLabel
@export var lobby_id_label: RichTextLabel
@export var players_label: RichTextLabel
@export var start_game_button: Button
@export var close_lobby_button: Button
@export var waiting_for_host_label: RichTextLabel

@onready var _lobby: LobbyService = LobbyService
@onready var _gameSequence: GameSequence = GameSequence

func _ready() -> void:
	close_lobby_button.pressed.connect(_on_close_lobby_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	# lobby signals
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.created_lobby.connect(_on_lobby_created)
	_lobby.players_changed.connect(_on_lobby_players_changed)
	waiting_for_host_label.visible = false


func _on_close_lobby_button_pressed() -> void:
	_lobby.leave_lobby()


func _on_lobby_joined() -> void:
	start_game_button.visible = false
	close_lobby_button.text = "  LEAVE LOBBY"
	waiting_for_host_label.visible = true


func _on_lobby_created() -> void:
	start_game_button.visible = true
	close_lobby_button.text = "  CLOSE LOBBY"
	waiting_for_host_label.visible = false


func _on_lobby_players_changed(players_data: Dictionary[int, PlayerData]) -> void:
	if players_data.has(1):
		lobby_title_label.text = players_data[1].username + "'s LOBBY"
	else:
		lobby_title_label.text = ""
	players_label.text = "Players" + "(" + str(players_data.size()) + "/8)"


func _on_start_game_button_pressed() -> void:
	_gameSequence.host_start_game()
