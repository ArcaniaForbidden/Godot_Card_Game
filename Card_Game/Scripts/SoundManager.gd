extends Node

var max_players: int = 30  # maximum simultaneous sounds
var sounds = {
	"card_pickup": preload("res://Sounds/card_pickup.wav"),
	"card_drop": preload("res://Sounds/card_drop.wav"),
	"card_pop": preload("res://Sounds/card_pop.wav"),
	"card_pack_open": preload("res://Sounds/card_pack_open.wav"),
	"coin": preload("res://Sounds/coin.wav"),
}

func play(sound_name: String, volume_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		return
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = sounds[sound_name]
	sfx.volume_db = volume_db
	sfx.attenuation = 0.0001
	add_child(sfx)
	sfx.play()
	# Wait for sound to finish then free
	var duration = sfx.stream.get_length()
	await get_tree().create_timer(duration).timeout
	sfx.queue_free()
