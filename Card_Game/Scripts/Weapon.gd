extends Node2D
class_name Weapon

@export var orbit_radius_x: float = 45.0
@export var orbit_radius_y: float = 25.0
@export var orbit_speed: float = 2.0
var orbit_angle: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _process(delta):
	orbit_angle += orbit_speed * delta
	var x = orbit_radius_x * cos(orbit_angle)
	var y = orbit_radius_y * sin(orbit_angle)
	var orbit_offset = Vector2(0,-30)
	position = Vector2(x, y) + orbit_offset # local position relative to parent
