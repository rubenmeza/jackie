extends Control

@onready var _rules_panel: PanelContainer = $RulesPanel
@onready var _how_to_play_btn: Button = $VBox/HowToPlayButton


func _ready() -> void:
	GameState.reset()
	GameState.chips = 500

	$VBox/PlayButton.pressed.connect(_on_play_pressed)
	_how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	$RulesPanel/RulesVBox/CloseRulesButton.pressed.connect(_on_close_rules_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_how_to_play_pressed() -> void:
	_rules_panel.visible = not _rules_panel.visible
	_how_to_play_btn.text = "HIDE RULES" if _rules_panel.visible else "HOW TO PLAY"


func _on_close_rules_pressed() -> void:
	_rules_panel.hide()
	_how_to_play_btn.text = "HOW TO PLAY"
