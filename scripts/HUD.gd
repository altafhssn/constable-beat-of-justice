class_name HUD
extends CanvasLayer

const Player = preload("res://scripts/Player.gd")

@onready var hp_fill = $HPBarFill
@onready var hp_text = $HPText
@onready var floor_text = $FloorText
@onready var weapon_label = $WeaponLabel
@onready var xp_fill = $XpBarFill
@onready var gold_text = $GoldText

var player_ref: Player = null

# Boss HP bar
var boss_bar_bg: ColorRect
var boss_bar_fill: ColorRect
var boss_name_label: Label

func _ready():
	create_boss_hp_bar()
	await get_tree().process_frame
	var main = get_node("/root/Main")
	if main and main.player:
		player_ref = main.player
		player_ref.health_changed.connect(_update_hp)
		update_all()

func create_boss_hp_bar():
	boss_bar_bg = ColorRect.new()
	boss_bar_bg.size = Vector2(200, 16)
	boss_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	boss_bar_bg.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 8)
	boss_bar_bg.visible = false
	add_child(boss_bar_bg)
	
	boss_bar_fill = ColorRect.new()
	boss_bar_fill.size = Vector2(200, 16)
	boss_bar_fill.color = Color(0.8, 0.2, 0.1, 0.9)
	boss_bar_fill.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 8)
	boss_bar_fill.visible = false
	add_child(boss_bar_fill)
	
	boss_name_label = Label.new()
	boss_name_label.text = ""
	boss_name_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 0)
	boss_name_label.add_theme_font_size_override("font_size", 12)
	boss_name_label.modulate = Color(1, 1, 1, 0.9)
	boss_name_label.visible = false
	add_child(boss_name_label)

func show_boss_hp(name: String, ratio: float):
	boss_bar_bg.visible = true
	boss_bar_fill.visible = true
	boss_name_label.visible = true
	boss_name_label.text = name
	boss_bar_fill.size.x = 200 * ratio
	if ratio > 0.5:
		boss_bar_fill.color = Color(0.8, 0.2, 0.1, 0.9)
	elif ratio > 0.25:
		boss_bar_fill.color = Color(0.9, 0.7, 0.1, 0.9)
	else:
		boss_bar_fill.color = Color(1.0, 0.3, 0.0, 0.9)

func hide_boss_hp():
	boss_bar_bg.visible = false
	boss_bar_fill.visible = false
	boss_name_label.visible = false

func update_all():
	if not player_ref:
		return
	_update_hp(player_ref.current_hp, player_ref.max_hp)
	var main = get_node("/root/Main")
	floor_text.text = "F" + str(main.current_floor if is_instance_valid(main) else 1) + "/25"
	weapon_label.text = get_weapon_name(player_ref.current_weapon)
	var xp_pct = player_ref.xp / player_ref.xp_to_next if player_ref.xp_to_next > 0 else 0
	xp_fill.size.x = 98 * min(xp_pct, 1.0)
	gold_text.text = str(player_ref.total_gold)

func _update_hp(hp: float, max_hp: float):
	if not hp_fill or not hp_text:
		return
	var pct = hp / max_hp if max_hp > 0 else 0
	hp_fill.size.x = 96 * max(pct, 0)
	hp_text.text = str(int(hp)) + "/" + str(int(max_hp))
	if pct < 0.25:
		hp_fill.color = Color(1, 0.2, 0.2)
	elif pct < 0.5:
		hp_fill.color = Color(1, 0.6, 0.2)
	else:
		hp_fill.color = Color(0.2, 1, 0.2)

func get_weapon_name(wtype) -> String:
	match wtype:
		0: return "LATHI"
		1: return "KATTA"
		2: return "SHIELD"
		3: return "DANGAL"
		4: return "TRISHUL"
		5: return "INSAS"
	return "LATHI"
