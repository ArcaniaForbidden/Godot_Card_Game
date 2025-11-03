extends Panel

var normal_color: Color = Color.BLACK
var hover_color: Color = Color.WHITE

@onready var pause_menu_close_button = $PauseMenuCloseButton
@onready var options_button = $OptionsButton
@onready var save_button = $SaveButton
@onready var load_button = $LoadButton
@onready var main_menu_button = $MainMenuButton
@onready var exit_game_button = $ExitGameButton

func _ready():
	visible = false
	for button in [pause_menu_close_button, options_button, save_button, load_button, main_menu_button, exit_game_button]:
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_entered.connect(Callable(self, "_on_button_hovered").bind(button, true))
		button.mouse_exited.connect(Callable(self, "_on_button_hovered").bind(button, false))

func _on_button_hovered(button: Control, hovered: bool) -> void:
	if UIManager.options_panel.visible:
		return
	if hovered and SoundManager:
		SoundManager.play("ui_hover", 0.0)
	var label = button.get_node_or_null("Label")
	if not label:
		return
	if label.label_settings:
		label.label_settings = label.label_settings.duplicate()
	else:
		return
	label.label_settings.font_color = hover_color if hovered else normal_color

func _on_button_pressed(button: Object) -> void:
	if UIManager.options_panel.visible:
		return
	match button:
		pause_menu_close_button:
			visible = false
			print("Pause menu close button pressed")
		options_button:
			UIManager.options_panel.visible = true
			UIManager.audio_panel.visible = true
			UIManager.graphics_panel.visible = false
			var label = button.get_node_or_null("Label")
			if label.label_settings:
				label.label_settings = label.label_settings.duplicate()
				label.label_settings.font_color = normal_color
			print("Options menu opened")
		save_button:
			print("Save game logic here")
		load_button:
			print("Load game logic here")
		main_menu_button:
			print("Main menu logic here")
		exit_game_button:
			get_tree().quit()
