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

func _ready():
	joystick_center = joystick_base.global_position + joystick_base.size * 0.5
	
	# Set up button touch areas
	setup_button(attack_btn, "_on_attack_pressed")
	setup_button(dash_btn, "_on_dash_pressed")
	setup_button(interact_btn, "_on_interact_pressed")
	setup_button(inventory_btn, "_on_inventory_pressed")

func setup_button(btn: TextureRect, method: String):
	# Button will handle via _input — need to track global rects
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
	return (nub_pos - center).normalized()
