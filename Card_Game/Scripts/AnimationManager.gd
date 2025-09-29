extends Node
class_name AnimationManager

var card: Node = null
var sprite_animated: AnimatedSprite2D = null

func setup(card_node: Node, animated_sprite: AnimatedSprite2D) -> void:
	card = card_node
	sprite_animated = animated_sprite

func play_animation(animation_name: String) -> void:
	if not sprite_animated:
		return
	if sprite_animated.sprite_frames.has_animation(animation_name):
		sprite_animated.play(animation_name)

func play_idle() -> void:
	play_animation("idle")

func play_walk() -> void:
	play_animation("walk")

func play_attack() -> void:
	play_animation("attack")

func play_hit() -> void:
	play_animation("hit")

func play_death() -> void:
	play_animation("death")
