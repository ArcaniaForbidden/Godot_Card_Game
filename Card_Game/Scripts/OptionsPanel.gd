extends Panel

var normal_color: Color = Color.BLACK
var hover_color: Color = Color.WHITE
var resolutions = [
	Vector2i(3840, 2160),
	Vector2i(2560, 1440),
	Vector2i(1920, 1080),
	Vector2i(1440, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
]

@onready var options_close_button = $OptionsCloseButton
@onready var audio_button = $AudioButton
@onready var graphics_button = $GraphicsButton
@onready var audio_panel = $AudioPanel
@onready var master_volume_h_slider = $AudioPanel/MasterVolumeHSlider
@onready var master_volume_textureprogressbar = $AudioPanel/MasterVolumeTextureProgressBar
@onready var master_volume_value_label = $AudioPanel/MasterVolumeValueLabel
@onready var sound_volume_h_slider = $AudioPanel/SoundVolumeHSlider
@onready var sound_volume_textureprogressbar = $AudioPanel/SoundVolumeTextureProgressBar
@onready var sound_volume_value_label = $AudioPanel/SoundVolumeValueLabel
@onready var music_volume_h_slider = $AudioPanel/MusicVolumeHSlider
@onready var music_volume_textureprogressbar = $AudioPanel/MusicVolumeTextureProgressBar
@onready var music_volume_value_label = $AudioPanel/MusicVolumeValueLabel
@onready var graphics_panel = $GraphicsPanel
@onready var resolution_option = $GraphicsPanel/ResolutionOptionButton
@onready var fullscreen_button = $GraphicsPanel/FullscreenButton
@onready var vsync_button = $GraphicsPanel/VSyncButton
@onready var fps_h_slider = $GraphicsPanel/FPSHSlider
@onready var fps_textureprogressbar = $GraphicsPanel/FPSTextureProgressBar
@onready var fps_value_label = $GraphicsPanel/FPSValueLabel
@onready var apply_button = $GraphicsPanel/ApplyButton

func _ready():
	visible = false
	master_volume_h_slider.value = SoundManager.master_volume_percentage
	master_volume_h_slider.value_changed.connect(_on_master_volume_h_slider_value_changed)
	master_volume_textureprogressbar.value = master_volume_h_slider.value
	master_volume_value_label.text = str(int(master_volume_h_slider.value)) + "%"
	sound_volume_h_slider.value = SoundManager.sound_volume_percentage
	sound_volume_h_slider.value_changed.connect(_on_sound_volume_h_slider_value_changed)
	sound_volume_textureprogressbar.value = sound_volume_h_slider.value
	sound_volume_value_label.text = str(int(sound_volume_h_slider.value)) + "%"
	music_volume_h_slider.value = SoundManager.music_volume_percentage
	music_volume_h_slider.value_changed.connect(_on_music_volume_h_slider_value_changed)
	music_volume_textureprogressbar.value = music_volume_h_slider.value
	music_volume_value_label.text = str(int(music_volume_h_slider.value)) + "%"
	fps_h_slider.value_changed.connect(_on_fps_h_slider_value_changed)
	fps_textureprogressbar.value = fps_h_slider.value
	fps_value_label.text = str(int(fps_h_slider.value))
	for button in [audio_button, graphics_button, options_close_button, apply_button, fullscreen_button, vsync_button]:
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_entered.connect(Callable(self, "_on_button_hovered").bind(button, true))
		button.mouse_exited.connect(Callable(self, "_on_button_hovered").bind(button, false))
	fullscreen_button.toggle_mode = true
	vsync_button.toggle_mode = true
	# Populate resolution OptionButton
	for res in resolutions:
		resolution_option.add_item(str(res.x) + "x" + str(res.y))
	# Initialize from current settings
	var window_size = DisplayServer.window_get_size()
	for i in resolutions.size():
		if resolutions[i] == window_size:
			resolution_option.select(i)
			break

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == Key.KEY_ESCAPE:
			_on_button_pressed(options_close_button)

func _on_button_hovered(button: Control, hovered: bool) -> void:
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
	match button:
		options_close_button:
			visible = false
			if UIManager and UIManager.pause_menu_panel:
				UIManager.pause_menu_panel.visible = true
				print("Options close button pressed")
		audio_button:
			audio_panel.visible = true
			graphics_panel.visible = false
			print("Audio button pressed")
		graphics_button:
			audio_panel.visible = false
			graphics_panel.visible = true
			print("Graphics button pressed")
		fullscreen_button:
			if fullscreen_button.button_pressed:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				print("Fullscreen enabled")
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				print("Fullscreen disabled")
		vsync_button:
			if vsync_button.button_pressed:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				print("VSync enabled")
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				print("VSync disabled")
		apply_button:
			save_graphics_settings()
			load_graphics_settings()
			print("Graphics settings applied!")

func _on_master_volume_h_slider_value_changed(value: float) -> void:
	master_volume_textureprogressbar.value = value
	master_volume_value_label.text = str(int(value)) + "%"
	if SoundManager:
		SoundManager.master_volume_percentage = int(value)

func _on_sound_volume_h_slider_value_changed(value: float) -> void:
	sound_volume_textureprogressbar.value = value
	sound_volume_value_label.text = str(int(value)) + "%"
	if SoundManager:
		SoundManager.sound_volume_percentage = int(value)

func _on_music_volume_h_slider_value_changed(value: float) -> void:
	music_volume_textureprogressbar.value = value
	music_volume_value_label.text = str(int(value)) + "%"
	if SoundManager:
		SoundManager.music_volume_percentage = int(value)

func _on_fps_h_slider_value_changed(value: float) -> void:
	fps_textureprogressbar.value = value
	fps_value_label.text = str(int(value))

func save_graphics_settings():
	var cfg = ConfigFile.new()
	var selected_res = resolutions[resolution_option.selected]
	cfg.set_value("graphics", "resolution_x", selected_res.x)
	cfg.set_value("graphics", "resolution_y", selected_res.y)
	cfg.set_value("graphics", "fullscreen", fullscreen_button.button_pressed)
	cfg.set_value("graphics", "vsync", vsync_button.button_pressed)
	cfg.set_value("graphics", "fps", int(fps_h_slider.value))
	cfg.save("user://graphics.cfg")
	print("Graphics settings saved!")

func load_graphics_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://graphics.cfg") != OK:
		print("No saved graphics settings, using defaults.")
		return
	var width: int = cfg.get_value("graphics", "resolution_x", 1920)
	var height: int = cfg.get_value("graphics", "resolution_y", 1080)
	var fullscreen: bool = cfg.get_value("graphics", "fullscreen", false)
	var vsync: bool = cfg.get_value("graphics", "vsync", true)
	var fps: int = cfg.get_value("graphics", "fps", 60)
	for i in resolutions.size():
		if resolutions[i].x == width and resolutions[i].y == height:
			resolution_option.select(i)
			break
	fullscreen_button.button_pressed = fullscreen
	vsync_button.button_pressed = vsync
	fps_h_slider.value = fps
	if not Engine.is_editor_hint():
		DisplayServer.window_set_size(Vector2i(width, height))
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
		)
		Engine.max_fps = fps
