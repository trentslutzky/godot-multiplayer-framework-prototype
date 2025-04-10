extends Control

@export_category("Main Menu")
@export var menu_landing: Control
@export var main_menu_host_button: Control
@export var main_menu_join_button: Control
@export var main_menu_quit_button: Button

@export_category("Lobby Menu")
@export var lobby_menu: Control

@export_category("Loading Screen")
@export var loading: Control
@export var loading_text: RichTextLabel

@export_category("Join Menu")
@export var join_menu: Control
@export var back_button: Button

@export_category("Other")
@export var error_text: RichTextLabel

@onready var _lobby := LobbyService
@onready var _steam := SteamService

func _ready() -> void:
	show_main_menu()
	
	# main menu
	main_menu_host_button.pressed.connect(_on_main_menu_host_button_pressed)
	main_menu_join_button.pressed.connect(_on_main_menu_join_button_pressed)
	main_menu_quit_button.pressed.connect(_on_main_menu_quit_button_pressed)
	
	# join menu
	back_button.pressed.connect(_on_join_menu_back_button_pressed)
	
	# lobby signals
	_lobby.creating_lobby.connect(_on_creating_lobby)
	_lobby.joining_lobby.connect(_on_joining_lobby)
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.lobby_error.connect(_on_lobby_error)
	_lobby.left_lobby.connect(_on_left_lobby)
	
	error_text.text = ""


func _on_creating_lobby():
	_show_loading_screen("Creating lobby...")

func _on_joining_lobby():
	_show_loading_screen("Joining lobby...")


func _on_lobby_joined():
	_show_lobby_menu()


func _on_left_lobby():
	show_main_menu()


func _on_lobby_error(error: String):
	error_text.text = error
	show_main_menu()


func _on_main_menu_host_button_pressed():
	_lobby.handler.create_lobby()


func _on_main_menu_join_button_pressed():
	if _lobby.using_steam:
		_steam.get_friends_in_lobbies()
		show_join_menu()
	else:
		_lobby.handler.join_lobby()


func _on_join_menu_back_button_pressed():
	show_main_menu()


func _on_main_menu_quit_button_pressed():
	get_tree().quit()


func _show_loading_screen(text: String = ""):
	menu_landing.visible = false
	lobby_menu.visible = false
	loading.visible = true
	join_menu.visible = false
	loading_text.text = text
	error_text.text = ""


func _show_lobby_menu():
	menu_landing.visible = false
	lobby_menu.visible = true
	loading.visible = false
	join_menu.visible = false


func show_main_menu():
	menu_landing.visible = true
	lobby_menu.visible = false
	loading.visible = false
	join_menu.visible = false


func show_join_menu():
	menu_landing.visible = false
	lobby_menu.visible = false
	loading.visible = false
	join_menu.visible = true
