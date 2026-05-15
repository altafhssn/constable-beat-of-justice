class_name InputHandler
extends Node

# Handles both keyboard and touch input
# Produces unified movement vector and action signals

enum ActionType { MOVE, ATTACK, DASH, SPECIAL, INTERACT, INVENTORY }

signal action_pressed(action: ActionType, direction: Vector2)
signal action_released(action: ActionType)
signal move_vector_changed(vector: Vector2)

var move_vector: Vector2 = Vector2.ZERO
var touch_move_vector: Vector2 = Vector2.ZERO
var keyboard_move_vector: Vector2 = Vector2.ZERO

# Touch controls
var joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var joystick_radius: float = 60.0
var joystick_touch_id: int = -1
var action_button_ids: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(_delta):
	# Poll keyboard state every frame (required for continuous movement)
	poll_keyboard()

func _input(event):
	# Keyboard action keys (press/release events, not continuous)
	if event is InputEventKey:
		# Action keys: only fire on initial press, not echo repeats
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_SPACE:
					action_pressed.emit(ActionType.DASH, move_vector)
				KEY_E:
					action_pressed.emit(ActionType.INTERACT, move_vector)
				KEY_I:
					action_pressed.emit(ActionType.INVENTORY, move_vector)
				KEY_Q:
					action_pressed.emit(ActionType.SPECIAL, move_vector)
	
	# Mouse click attack
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		action_pressed.emit(ActionType.ATTACK, move_vector)
	
	# Touch input (mobile)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		handle_touch(event)

func poll_keyboard():
	# Polled every frame — this is what makes WASD movement work continuously
	var wasd = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		wasd.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		wasd.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		wasd.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		wasd.x += 1
	
	var last_keyboard = keyboard_move_vector
	keyboard_move_vector = wasd.normalized()
	
	if keyboard_move_vector != last_keyboard:
		update_move_vector()

func handle_touch(event):
	# Simple touch input: tap left half = move toward tap, tap right = attack
	# Will be replaced by virtual joystick UI buttons
	
	var screen_size = get_viewport().get_visible_rect().size
	var is_left_half = event.position.x < screen_size.x * 0.5
	
	if event is InputEventScreenTouch and event.pressed:
		if is_left_half:
			# Move toward tap position
			var center = Vector2(screen_size.x * 0.25, screen_size.y * 0.5)
			touch_move_vector = (event.position - center).normalized()
			update_move_vector()
		else:
			# Attack
			action_pressed.emit(ActionType.ATTACK, touch_move_vector)
	elif event is InputEventScreenTouch and not event.pressed:
		if is_left_half:
			touch_move_vector = Vector2.ZERO
			update_move_vector()

func update_move_vector():
	move_vector = (keyboard_move_vector + touch_move_vector).normalized()
	move_vector_changed.emit(move_vector)
	
	if move_vector != Vector2.ZERO:
		action_pressed.emit(ActionType.MOVE, move_vector)
	else:
		action_released.emit(ActionType.MOVE)
