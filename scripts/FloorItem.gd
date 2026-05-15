class_name FloorItem
extends Area2D

var item_type: String = "health"  # health, weapon, upgrade
var weapon_type: int = 0  # Player.WeaponType
var value: float = 0.0

# Sprite
var sprite_node: Sprite2D

func _ready():
	sprite_node = Sprite2D.new()
	sprite_node.centered = true
	sprite_node.scale = Vector2(1.5, 1.5)
	add_child(sprite_node)
	
	# Set placeholder item sprite
	var tex = SpriteRegistry.get_item_sprite(item_type)
	if tex:
		sprite_node.texture = tex
	
	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	add_child(col)

func init(data: Dictionary):
	item_type = data.get("item_type", "health")
	weapon_type = data.get("weapon_type", 0)
	value = data.get("value", 10.0)
	position = data.get("position", Vector2.ZERO)
	
	# Update sprite based on item type
	if sprite_node:
		var tex = SpriteRegistry.get_item_sprite(item_type)
		if tex:
			sprite_node.texture = tex
