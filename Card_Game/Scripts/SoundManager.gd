extends Node2D

var current_hover_player: AudioStreamPlayer = null
var sounds = {
	"card_pickup": preload("res://Sounds/card_pickup.wav"),
	"card_drop": preload("res://Sounds/card_drop.wav"),
	"card_pop": preload("res://Sounds/card_pop.wav"),
	"card_pack_open": preload("res://Sounds/card_pack_open.wav"),
	"coin": preload("res://Sounds/coin.wav"),
	"damage": preload("res://Sounds/damage.wav"),
	"sword_slash": preload("res://Sounds/sword_slash.wav"),
	"spear_thrust": preload("res://Sounds/spear_thrust.wav"),
	"claw_slash": preload("res://Sounds/claw_slash.wav"),
	"arrow": preload("res://Sounds/arrow.wav"),
	"ui_hover": preload("res://Sounds/ui_hover.wav"),
}

func play(sound_name: String, volume_db: float = 0.0, position = null) -> void:
	if not sounds.has(sound_name):
		return
	var is_hover_sound = sound_name == "ui_hover"
	# Stop previous hover sound safely
	if is_hover_sound and current_hover_player:
		if is_instance_valid(current_hover_player):
			current_hover_player.stop()
			current_hover_player.queue_free()
		current_hover_player = null
	var sfx
	if position != null and not is_hover_sound:
		sfx = AudioStreamPlayer2D.new()
		sfx.position = position
		sfx.attenuation = 1.0
	else:
		sfx = AudioStreamPlayer.new()
	sfx.stream = sounds[sound_name]
	sfx.volume_db = volume_db
	add_child(sfx)
	sfx.play()
	if is_hover_sound:
		current_hover_player = sfx
	# Free after finished safely
	var duration = sfx.stream.get_length()
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(sfx):
		sfx.queue_free()
	# Only clear hover reference if this was the current hover
	if is_hover_sound and current_hover_player == sfx:
		current_hover_player = null
