extends Camera2D

var pan_speed: float = 3000.0
var min_zoom: float = 0.25
var max_zoom: float = 4.0
var zoom_speed: float = 0.05
var dragging: bool = false
var drag_start: Vector2
var camera_start: Vector2

func _process(delta):
	# Optional keyboard pan
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta

func _input(event):
	# Mouse drag to pan
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				dragging = true
				drag_start = event.position
				camera_start = global_position
			else:
				dragging = false
	elif event is InputEventMouseMotion:
		if dragging:
			global_position = camera_start - (event.position - drag_start) * zoom.x
	# Zoom with scroll wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)

func zoom_camera(amount: float) -> void:
	var new_zoom = zoom * (1 + amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom
