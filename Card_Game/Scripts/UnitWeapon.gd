extends Node2D
class_name Weapon

# --- Weapon stats ---
var damage: int = 1
var attack_range: float = 100.0
var attack_cooldown: float = 1.0
var time_since_attack: float = 0.0
var weapon_type: String = "melee" # "melee" or "ranged"
var melee_type: String = "lunge"  # "lunge" or "slash"
var is_attacking: bool = false
var base_position: Vector2 = Vector2.ZERO
var has_dealt_damage_this_attack: bool = false
var checking_lunge: bool = false
var hit_targets: Array = []

# --- Projectile properties for ranged weapons ---
var projectile_scene = preload("res://Scenes/Projectile.tscn")
var projectile_sprite: Texture2D
var projectile_speed: float = 500.0
var projectile_lifetime: float = 2.0
var projectile_polygon: Array = []

# --- Orbit variables ---
var orbit_radius_x: float = 45.0
var orbit_radius_y: float = 25.0
var orbit_speed: float = 2.0
var orbit_angle: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var area2d: Area2D = $Area2D

func _process(delta):
	# --- Check melee lunge collisions ---
	if checking_lunge and not has_dealt_damage_this_attack:
		check_collision_for_damage()
	# --- Weapon cooldown / orbit ---
	if is_attacking:
		return
	time_since_attack += delta
	orbit_angle += orbit_speed * delta
	var parent_card = get_parent() as Card
	if not parent_card:
		return
	if time_since_attack >= attack_cooldown:
		var target = get_nearest_enemy_in_range(parent_card.global_position, attack_range)
		if target:
			if weapon_type == "ranged":
				ranged_attack(parent_card, target)
			elif weapon_type == "melee":
				melee_attack(target)
			time_since_attack = 0.0
	# Simple orbit for visual
	position = Vector2(orbit_radius_x * cos(orbit_angle), orbit_radius_y * sin(orbit_angle))

# --- Get closest enemy in range ---
func get_nearest_enemy_in_range(origin: Vector2, range: float) -> Node2D:
	var card_manager = get_tree().root.get_node("Main/CardManager")
	var nearest_target = null
	var nearest_dist = range
	for stack in card_manager.all_stacks:
		if stack.size() == 0:
			continue
		var card = stack[0]
		if card.card_type == "enemy":
			var dist = origin.distance_to(card.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_target = card
	return nearest_target

# --- Melee attack logic ---
func melee_attack(target: Node2D):
	if weapon_type != "melee":
		return
	is_attacking = true
	has_dealt_damage_this_attack = false
	hit_targets.clear()
	var parent_card = get_parent()
	if not parent_card:
		is_attacking = false
		return
	if melee_type == "lunge":
		lunge_attack(target)
	elif melee_type == "slash":
		slash_attack(target)

func slash_attack(target: Node2D):
	if weapon_type != "melee" or melee_type != "slash":
		return
	is_attacking = true
	has_dealt_damage_this_attack = false
	hit_targets.clear()
	var parent_card = get_parent()
	if not parent_card:
		is_attacking = false
		return
	# --- Calculate geometry ---
	var to_target = (target.global_position - parent_card.global_position).normalized()
	var target_angle = to_target.angle()
	var start_angle = target_angle + deg_to_rad(60)
	var end_angle = target_angle - deg_to_rad(60)
	var distance_to_target = (target.global_position - parent_card.global_position).length()
	var offset = area2d.global_position - global_position
	var radius = max(distance_to_target - offset.length(), 0)
	var base_position = position
	var base_rotation = rotation  # store for restoration later
	var total_time = attack_cooldown
	# --- Phase 1: Aim at target ---
	rotation = target_angle + deg_to_rad(90)
	# --- Define callables ---
	var do_sweep = func(angle: float):
		rotation = angle + deg_to_rad(90)
		position = Vector2(cos(angle), sin(angle)) * radius
		check_collision_for_damage()
	var on_return_finished = func():
		# Smoothly rotate back to idle orientation
		var reset_tween = get_tree().create_tween()
		reset_tween.tween_property(self, "rotation", base_rotation, total_time * 0.25).set_ease(Tween.EASE_IN_OUT)
		reset_tween.finished.connect(func():
			is_attacking = false
			has_dealt_damage_this_attack = false
			hit_targets.clear()
		)
	var return_to_base = func():
		var return_tween = get_tree().create_tween()
		return_tween.set_parallel(true)
		return_tween.tween_property(self, "rotation", target_angle + deg_to_rad(90), total_time * 0.25).set_ease(Tween.EASE_OUT)
		return_tween.tween_property(self, "position", base_position, total_time * 0.25).set_ease(Tween.EASE_IN_OUT)
		return_tween.finished.connect(on_return_finished)
	var start_sweep = func():
		var sweep_tween = get_tree().create_tween()
		sweep_tween.tween_method(do_sweep, start_angle, end_angle, total_time * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sweep_tween.finished.connect(return_to_base)
	var on_windup_finished = func():
		start_sweep.call()
	var windup_tween = get_tree().create_tween()
	windup_tween.set_parallel(true)
	windup_tween.tween_property(self, "rotation", start_angle + deg_to_rad(90), total_time * 0.25).set_ease(Tween.EASE_IN_OUT)
	windup_tween.tween_property(self, "position", Vector2(cos(start_angle), sin(start_angle)) * radius, total_time * 0.25).set_ease(Tween.EASE_OUT)
	windup_tween.finished.connect(on_windup_finished)

func lunge_attack(target: Node2D):
	base_position = position
	var to_target_global = target.global_position - global_position
	var distance_to_target = to_target_global.length()
	var direction = to_target_global.normalized()
	var spear_tip_offset_global = area2d.global_position - global_position
	var lunge_distance = max(distance_to_target - spear_tip_offset_global.length(), 0)
	var final_position = base_position + direction * lunge_distance
	var target_angle = direction.angle() + deg_to_rad(90)
	var total_time = attack_cooldown
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", target_angle, total_time * 0.2)
	tween.tween_callback(func(): checking_lunge = true)
	tween.tween_property(self, "position", final_position, total_time * 0.2)
	tween.tween_callback(func(): checking_lunge = false)
	tween.tween_property(self, "position", base_position, total_time * 0.2)
	tween.tween_property(self, "rotation", deg_to_rad(360), total_time * 0.2)
	tween.finished.connect(func():
		is_attacking = false
		checking_lunge = false
		has_dealt_damage_this_attack = false
		hit_targets.clear()
	)

# --- Fire projectile for ranged weapons ---
func ranged_attack(card: Card, target: Node2D):
	if weapon_type != "ranged":
		return
	is_attacking = true  # prevent orbit logic from interfering
	# Rotate bow to aim at target first
	var to_target = (target.global_position - global_position).normalized()
	var target_angle = to_target.angle() + deg_to_rad(90)
	var original_rotation = rotation  # store current rotation (includes sprite_rotation_offset)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", target_angle, 0.2)
	tween.tween_callback(func():
		# Spawn projectile after bow has rotated
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		projectile.damage = damage
		projectile.scale = Vector2(3, 3)
		var sprite_node = projectile.get_node_or_null("Sprite2D")
		if sprite_node and projectile_sprite:
			sprite_node.texture = projectile_sprite
		projectile.direction = (target.global_position - global_position).normalized()
		projectile.rotation = projectile.direction.angle()
		projectile.z_index = get_parent().z_index
		projectile.speed = projectile_speed
		projectile.lifetime = projectile_lifetime
		get_tree().root.add_child(projectile)
	)
	# Hold on target for 0.5s
	tween.tween_interval(0.5)
	# Rotate back to original rotation
	tween.tween_property(self, "rotation", original_rotation, 0.2)
	tween.finished.connect(func():
		is_attacking = false
	)

# --- Check for damage collisions ---
func check_collision_for_damage():
	if not area2d:
		return
	for area in area2d.get_overlapping_areas():
		var card = area.get_parent()
		if card and card.is_inside_tree() and card is Card:
			if card.card_type == "enemy" and card.has_method("take_damage"):
				if card not in hit_targets:
					card.take_damage(damage)
					hit_targets.append(card)
