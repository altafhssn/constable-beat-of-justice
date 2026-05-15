class_name Civilian
extends CharacterBody2D

# Civilian types
var civilian_type: String = "chai_wala"
var is_rescued: bool = false
var rescue_buff: String = ""
var dialogue_lines: Array = []

# Sprite
var sprite_node: Sprite2D

func _ready():
	sprite_node = Sprite2D.new()
	sprite_node.centered = true
	sprite_node.scale = Vector2(1.5, 1.5)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	add_child(col)
	
	# Set placeholder sprite
	sprite_node.texture = SpriteRegistry.get_civilian_sprite(civilian_type)

func init(data: Dictionary):
	civilian_type = data.get("type", "chai_wala")
	position = data.get("position", Vector2.ZERO)
	# Each civilian type has specific rescue info
	match civilian_type:
		"chai_wala":
			rescue_buff = "heal_20"
			dialogue_lines = ["Arre baba! Dhanyawad!", "I saw the Syndicate's face..."]
		"newspaper_boy":
			rescue_buff = "reveal_enemies"
			dialogue_lines = ["Bhaiya please save me!", "I have photos... evidence!"]
		"teacher":
			rescue_buff = "atk_boost"
			dialogue_lines = ["Thank you constable!", "My daughter was kidnapped..."]
		"nurse":
			rescue_buff = "revive"
			dialogue_lines = ["Mujhe bachao!", "I know the Commissioner's secret..."]
		"auto_driver":
			rescue_buff = "speed_boost"
			dialogue_lines = ["Oye hoye! Thanks bhai!", "I drove the Syndicate's car..."]

func rescue():
	is_rescued = true
	# Free animation
	# Emit rescue signal or notify Main
	var main = get_node("/root/Main")
	if main and main.player:
		main.player.on_rescue(self)
	queue_free()
