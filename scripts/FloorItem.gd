extends Area2D

var item_type: String = "health"  # health, weapon, upgrade
var weapon_type: int = 0  # Player.WeaponType
var value: float = 0.0

func init(data: Dictionary):
	item_type = data.get("item_type", "health")
	weapon_type = data.get("weapon_type", 0)
	value = data.get("value", 10.0)
	position = data.get("position", Vector2.ZERO)
