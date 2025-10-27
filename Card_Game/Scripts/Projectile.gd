extends Area2D
class_name Projectile

var damage: int = 1
var speed: float = 1000.0
var lifetime: float = 2.0
var direction: Vector2 = Vector2.ZERO
var owner_card: Card = null  # NEW – who fired this projectile

@onready var sprite: Sprite2D = $Sprite2D
@onready var polygon: CollisionPolygon2D = $CollisionPolygon2D

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))
	set_physics_process(true)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

# --- Unified target validation ---
func can_damage_types(attacker: Card, target: Card) -> bool:
	if not attacker or not target:
		return false
	match attacker.card_type:
		"enemy":
			return target.card_type in ["unit", "building"]
		"unit":
			return target.card_type in ["enemy", "neutral"]
		"building":
			return target.card_type == "enemy"
		_:
			return false

# --- Collision logic ---
func _on_area_entered(area: Area2D):
	var card = area.get_parent()
	if card and card is Card and card.is_inside_tree() and card.has_method("take_damage"):
		if owner_card and can_damage_types(owner_card, card):
			card.take_damage(damage)
			queue_free()
