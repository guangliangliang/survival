extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.visible = not OS.has_feature("web")

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
