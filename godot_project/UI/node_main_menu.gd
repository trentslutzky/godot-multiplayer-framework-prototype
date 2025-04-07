extends Control

@onready var _lobby := LobbyService
@onready var _steam := SteamService

@export_category("buttons")
@export var host_button: Button
@export var join_button: Button
@export var lobby_joined_label: RichTextLabel
@export var players_data_label: RichTextLabel
@export var main_landing: Control
@export var lobby_ui: Control
@export var leave_lobby_button: Button
@export var friend_lobby_button_vbox: VBoxContainer

func _ready() -> void:
	## connect local signals ##
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	leave_lobby_button.pressed.connect(_leave_lobby_button_pressed)
	
	## reset UI elements ##
	lobby_joined_label.text = ""

	## connect to external signals ##
	_lobby.joining_lobby.connect(_on_joining_lobby)
	_lobby.creating_lobby.connect(_on_creating_lobby)
	_lobby.created_lobby.connect(_on_lobby_created)
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.failed_to_join_lobby.connect(_lobby_create_or_join_failed)
	_lobby.failed_to_create_lobby.connect(_lobby_create_or_join_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	_steam.friends_lobby_list_updated.connect(_steam_friends_lobby_list_updated)

	main_landing.visible = true
	lobby_ui.visible = false
	
	join_button.visible = !_lobby.using_steam
	friend_lobby_button_vbox.visible = _lobby.using_steam
	
	_steam_friends_lobby_list_updated()


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
	_lobby.handler.join_lobby()


func _leave_lobby_button_pressed():
	_lobby.leave_lobby()


func _steam_friends_lobby_list_updated():
	for child in friend_lobby_button_vbox.get_children():
		child.queue_free()
	var friends_lobby_ids := _steam.friends_lobby_ids
	for friend_steam_id in friends_lobby_ids:
		var steam_lobby_id = friends_lobby_ids[friend_steam_id]
		var steam_username = _steam.steam_usernames.get(friend_steam_id, str(friend_steam_id))
		var new_button_scene = load("res://UI/join_steam_friend_lobby_button.tscn")
		var new_button = new_button_scene.instantiate()
		new_button.steam_username = steam_username
		new_button.steam_lobby_id = steam_lobby_id
		friend_lobby_button_vbox.add_child(new_button)
