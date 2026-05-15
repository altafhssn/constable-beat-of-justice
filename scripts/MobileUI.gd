class_name MobileUI
extends Node2D

@onready var joystick_base = $JoystickBase
@onready var joystick_nub = $JoystickBase/JoystickNub
@onready var attack_btn = $AttackButton
@onready var dash_btn = $DashButton
@onready var interact_btn = $InteractButton
@onready var inventory_btn = $InventoryButton

var joystick_active: bool = false
var joystick_touch_id: int = -1
var joystick_radius: float = 50.0
var joystick_center: Vector2 = Vector2.ZERO
var input_handler_ref = null

func _ready():
	joystick_center = joystick_base.global_position + joystick_base.size * 0.5
	
	# Set textures from sprite registry
	if SpriteRegistry.get_sprite("ui_joystick_base"):
		joystick_base.texture = SpriteRegistry.get_sprite("ui_joystick_base")
	if SpriteRegistry.get_sprite("ui_joystick_nub"):
		joystick_nub.texture = SpriteRegistry.get_sprite("ui_joystick_nub")
	if SpriteRegistry.get_sprite("ui_att_btn"):
		attack_btn.texture = SpriteRegistry.get_sprite("ui_att_btn")
	if SpriteRegistry.get_sprite("ui_dash_btn"):
		dash_btn.texture = SpriteRegistry.get_sprite("ui_dash_btn")
	if SpriteRegistry.get_sprite("ui_interact_btn"):
		interact_btn.texture = SpriteRegistry.get_sprite("ui_interact_btn")
	if SpriteRegistry.get_sprite("ui_inv_btn"):
		inventory_btn.texture = SpriteRegistry.get_sprite("ui_inv_btn")
	
	# Find InputHandler
	await get_tree().process_frame
	var main = get_node("/root/Main")
	if main and main.input_handler:
		input_handler_ref = main.input_handler

func _process(_delta):
	# Continuously update InputHandler with joystick direction
	if joystick_active and input_handler_ref:
		var joy_vec = get_joystick_vector()
		input_handler_ref.touch_move_vector = joy_vec
		input_handler_ref.update_move_vector()
	elif input_handler_ref and not joystick_active:
		# Only reset if MobileUI was the last to set touch movement
		# Don't interfere with keyboard controls
		pass

func setup_button(btn: TextureRect, method: String):
	pass

func _input(event):
	# Joystick touch
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(joystick_center) < joystick_radius * 2:
			joystick_active = true
			joystick_touch_id = event.index
		elif not event.pressed and event.index == joystick_touch_id:
			joystick_active = false
			joystick_touch_id = -1
			joystick_nub.position = Vector2(35, 35)  # Reset to center
			if input_handler_ref:
				input_handler_ref.touch_move_vector = Vector2.ZERO
				input_handler_ref.update_move_vector()
	
	if event is InputEventScreenDrag and event.index == joystick_touch_id:
		var delta = event.position - joystick_center
		if delta.length() > joystick_radius:
			delta = delta.normalized() * joystick_radius
		joystick_nub.position = Vector2(35, 35) + delta
	
	# Button presses (simplified — check global rects)
	if event is InputEventScreenTouch and event.pressed:
		var btn_rects = {
			"attack": Rect2(attack_btn.global_position, attack_btn.size),
			"dash": Rect2(dash_btn.global_position, dash_btn.size),
			"interact": Rect2(interact_btn.global_position, interact_btn.size),
			"inventory": Rect2(inventory_btn.global_position, inventory_btn.size)
		}
		
		var main = get_node("/root/Main")
		if not main or not main.input_handler:
			return
		
		for action in btn_rects:
			if btn_rects[action].has_point(event.position):
				match action:
					"attack":
						main.input_handler.action_pressed.emit(InputHandler.ActionType.ATTACK, Vector2.DOWN)
					"dash":
						main.input_handler.action_pressed.emit(InputHandler.ActionType.DASH, Vector2.DOWN)
					"interact":
						main.input_handler.action_pressed.emit(InputHandler.ActionType.INTERACT, Vector2.DOWN)
					"inventory":
						main.input_handler.action_pressed.emit(InputHandler.ActionType.INVENTORY, Vector2.DOWN)

func get_joystick_vector() -> Vector2:
	if not joystick_active:
		return Vector2.ZERO
	var nub_pos = joystick_nub.global_position + joystick_nub.size * 0.5
	var center = joystick_base.global_position + joystick_base.size * 0.5
	var diff = nub_pos - center
	if diff.length() < 10:
		return Vector2.ZERO
	return diff.normalized()
