extends Control

@onready var _lobby := LobbyService

var lobby_id: String = ""

@export_category("buttons")
@export var host_button: Button
@export var join_button: Button
@export var lobby_joined_label: RichTextLabel
@export var players_data_label: RichTextLabel
@export var use_steam_checkbox: CheckBox
@export var lobby_id_linedit: LineEdit
@export var main_landing: Control
@export var lobby_ui: Control
@export var leave_lobby_button: Button

func _ready() -> void:
	## connect local signals ##
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	use_steam_checkbox.toggled.connect(_use_steam_checkbox_toggled)
	lobby_id_linedit.text_changed.connect(_lobby_id_linedit_changed)
	leave_lobby_button.pressed.connect(_leave_lobby_button_pressed)
	
	## reset UI elements ##
	lobby_joined_label.text = ""

	_lobby.joining_lobby.connect(_on_joining_lobby)
	_lobby.creating_lobby.connect(_on_creating_lobby)
	_lobby.created_lobby.connect(_on_lobby_created)
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.failed_to_join_lobby.connect(_lobby_create_or_join_failed)
	_lobby.failed_to_create_lobby.connect(_lobby_create_or_join_failed)
	
	multiplayer.server_disconnected.connect(_server_disconnected)

	main_landing.visible = true
	lobby_ui.visible = false


func _server_disconnected():
	lobby_joined_label.text = "The lobby closed."
	main_landing.visible = true
	lobby_ui.visible = false


func _process(_delta: float) -> void:
	if not _lobby.in_lobby:
		players_data_label.text = ""
		return
	if _lobby.players_data.has(1):
		var host_username: String = _lobby.players_data[1].username
		players_data_label.text = "In " + host_username + "'s lobby.\n\n"
	else:
		players_data_label.text = ""
	players_data_label.text += "peer id: " + str(multiplayer.get_unique_id()) + "\n\n"
	players_data_label.text += "Players:\n"
	for player_id in _lobby.players_data:
		players_data_label.text += _lobby.players_data.get(player_id).username
		players_data_label.text += "\n"

func _on_creating_lobby():
	lobby_joined_label.text = "Creating lobby..."
	main_landing.visible = false


func _on_joining_lobby():
	lobby_joined_label.text = "Joining..."
	main_landing.visible = false


func _on_lobby_joined():
	lobby_joined_label.text = ""
	main_landing.visible = false
	lobby_ui.visible = true

func _on_lobby_created():
	lobby_joined_label.text = "Lobby created"
	main_landing.visible = false
	lobby_ui.visible = true


func _lobby_create_or_join_failed(error_text: String):
	lobby_joined_label.text = "Failed: " + error_text
	main_landing.visible = true
	lobby_ui.visible = false


func _on_host_button_pressed():
	_lobby.handler.create_lobby()


func _on_join_button_pressed():
	_lobby.handler.join_lobby(int(lobby_id))


func _leave_lobby_button_pressed():
	_lobby.leave_lobby()


func _use_steam_checkbox_toggled(toggled_on: bool):
	_lobby.init_new_lobby_handler(toggled_on)


func _lobby_id_linedit_changed(text: String):
	lobby_id = text
