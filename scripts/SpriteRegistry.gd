extends Node

# Sprite registry — loads all game sprites from centralized paths
# Updated with free/CC0 assets (Kenney, OpenGameArt, Chasersgaming)

const SPRITES = {
	# Player — Officer Character spritesheet (CC0, Chasersgaming)
	"player_stand": preload("res://assets/characters/officer_sheet_boxed.png"),
	"player_hold": preload("res://assets/characters/officer_sheet_boxed.png"),
	"player_gun": preload("res://assets/characters/officer_sheet_boxed.png"),
	"player_machine": preload("res://assets/characters/officer_sheet_boxed.png"),
	"player_reload": preload("res://assets/characters/officer_sheet_boxed.png"),
	"player_silencer": preload("res://assets/characters/officer_sheet_boxed.png"),
	
	# Enemies — Brawler character variants (CC0, Chasersgaming)
	"enemy_soldier_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Walk_1_strip4.png"),
	"enemy_soldier_gun": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Punch_1.png"),
	"enemy_hitman_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Idle_1_strip4.png"),
	"enemy_hitman_gun": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Stab.png"),
	"enemy_zombie_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Hurt.png"),
	"enemy_survivor_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Walk_2_strip4.png"),
	"enemy_thug": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Punch_2.png"),
	"enemy_brawler": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Kick_1.png"),
	"enemy_robot_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Knock_Out.png"),
	"enemy_robot_gun": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Head_Butt_strip2.png"),
	"enemy_manbrown_stand": preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Daze_strip4.png"),
	
	# Civilians — Officer characters (friendly variants)
	"civ_chai_wala": preload("res://assets/characters/officer_sheet_boxed.png"),
	"civ_woman_stand": preload("res://assets/characters/officer_sheet_boxed.png"),
	"civ_manold_stand": preload("res://assets/characters/officer_sheet_boxed.png"),
	
	# Weapons — Kenney Weapon Pack (CC0)
	"weapon_lathi": preload("res://assets/sprites/weapons/lathi.png"),
	"weapon_pistol": preload("res://assets/sprites/weapons/pistol.png"),
	"weapon_trishul": preload("res://assets/sprites/weapons/trishul.png"),
	"weapon_knife": preload("res://assets/sprites/weapons/weapon_gun.png"),
	"weapon_shotgun": preload("res://assets/weapons/shotgun.png"),
	"weapon_machinegun": preload("res://assets/weapons/machinegun.png"),
	"weapon_health": preload("res://assets/sprites/weapons/health_pickup.png"),
	"weapon_atk_boost": preload("res://assets/sprites/weapons/atk_boost.png"),
	"weapon_def_boost": preload("res://assets/sprites/weapons/def_boost.png"),
	
	# Effects (keep existing - good enough)
	"effect_flame_0": preload("res://assets/sprites/effects/flame_0.png"),
	"effect_flame_1": preload("res://assets/sprites/effects/flame_1.png"),
	"effect_flame_2": preload("res://assets/sprites/effects/flame_2.png"),
	"effect_flame_3": preload("res://assets/sprites/effects/flame_3.png"),
	"effect_spark_0": preload("res://assets/sprites/effects/spark_0.png"),
	"effect_spark_1": preload("res://assets/sprites/effects/spark_1.png"),
	"effect_dust_0": preload("res://assets/sprites/effects/dust_0.png"),
	"effect_dust_1": preload("res://assets/sprites/effects/dust_1.png"),
	"effect_level_glow": preload("res://assets/sprites/effects/level_up_glow.png"),
	
	# Tilesets (keep existing generated ones — functional for now)
	"tileset_basti": preload("res://assets/tilesets/basti.png"),
	"tileset_bazaar": preload("res://assets/tilesets/bazaar.png"),
	"tileset_naka": preload("res://assets/tilesets/naka.png"),
	"tileset_kothi": preload("res://assets/tilesets/kothi.png"),
	"tileset_commissioner": preload("res://assets/tilesets/commissioner.png"),
	
	# New tilesets (Market Street for slum/urban zones)
	"tileset_market_street": preload("res://assets/new_tilesets/SMS_16x16_TileSet.png"),
	"tileset_market_street_128": preload("res://assets/new_tilesets/SMS_C_Street_16x16_128_x128.png"),
	
	# UI — Kenney UI Pack (CC0)
	"ui_hp_bar": preload("res://assets/ui/hp_bar_bg.png"),
	"ui_hp_bar_fill": preload("res://assets/ui/hp_bar.png"),
	"ui_xp_bar": preload("res://assets/ui/xp_bar.png"),
	"ui_att_btn": preload("res://assets/ui/attack_btn.png"),
	"ui_dash_btn": preload("res://assets/ui/dash_btn.png"),
	"ui_interact_btn": preload("res://assets/ui/interact_btn.png"),
	"ui_inv_btn": preload("res://assets/ui/inventory_btn.png"),
	"ui_gold_icon": preload("res://assets/ui/gold_icon.png"),
	"ui_joystick_base": preload("res://assets/ui/joystick_base.png"),
	"ui_joystick_nub": preload("res://assets/ui/joystick_nub.png"),
	
	# Kenney UI button styles
	"ui_button_rect": preload("res://assets/ui/button_rectangle_depth_flat.png"),
	"ui_button_rounded": preload("res://assets/ui/button_rectangle_depth_border.png"),
	"ui_panel": preload("res://assets/ui/button_rectangle_depth_flat.png"),
	"ui_cross": preload("res://assets/ui/icon_cross.png"),
	"ui_circle": preload("res://assets/ui/icon_circle.png"),
}

# Map enemy types to sprite keys
const ENEMY_SPRITE_MAP = {
	0: "enemy_soldier_stand",    # Street Thug
	1: "enemy_zombie_stand",     # Pickpocket
	2: "enemy_brawler",          # Drunk Brawler
	3: "enemy_survivor_stand",   # Smuggler
	4: "enemy_survivor_stand",   # Counterfeiter
	5: "enemy_robot_stand",      # Goon Squad
	6: "enemy_robot_gun",        # Armed Guard
	7: "enemy_hitman_stand",     # Sniffer Dog
	8: "enemy_hitman_gun",       # Hitman
	9: "enemy_manbrown_stand",   # Corrupt Official
}

const CIV_SPRITE_MAP = {
	"chai_wala": "civ_chai_wala",
	"newspaper_boy": "civ_manold_stand",
	"teacher": "civ_manold_stand",
	"nurse": "civ_woman_stand",
	"auto_driver": "civ_manold_stand",
}

const WEAPON_ITEM_MAP = {
	"health": "weapon_health",
	"atk_boost": "weapon_atk_boost",
	"def_boost": "weapon_def_boost",
}

static func get_sprite(key: String) -> Texture2D:
	if SPRITES.has(key):
		return SPRITES[key]
	return null

static func get_enemy_sprite(enemy_type: int, state: String = "stand") -> Texture2D:
	var key = ENEMY_SPRITE_MAP.get(enemy_type, "enemy_soldier_stand")
	return SPRITES.get(key)

static func get_civilian_sprite(civ_type: String) -> Texture2D:
	var key = CIV_SPRITE_MAP.get(civ_type, "civ_chai_wala")
	return SPRITES.get(key)

static func get_item_sprite(item_type: String) -> Texture2D:
	var key = WEAPON_ITEM_MAP.get(item_type, "weapon_health")
	return SPRITES.get(key)

static func get_tileset(floor_theme: int) -> Texture2D:
	var themes = ["tileset_basti", "tileset_bazaar", "tileset_naka", "tileset_kothi", "tileset_commissioner"]
	if floor_theme >= 0 and floor_theme < themes.size():
		return SPRITES.get(themes[floor_theme])
	return SPRITES["tileset_basti"]
