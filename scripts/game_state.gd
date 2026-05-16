class_name game_state
extends Node2D
# CONSTABLE: BEAT OF JUSTICE — Core Game State & Turn Manager
# All game data lives here, referenced by other scripts

const TILE_SIZE = 32
const MAP_W = 40
const MAP_H = 40
const MAX_FLOORS = 25
const FOV_RADIUS = 8

const ZONES = [
	{ "name": "Basti - Slums", "floor": 1 },
	{ "name": "Bazaar - Market", "floor": 6 },
	{ "name": "Naka - Checkpost", "floor": 11 },
	{ "name": "Kothi - Mansion", "floor": 16 },
	{ "name": "Commissioner's Office", "floor": 21 }
]

const RANKS = [
	"Constable", "Head Constable", "Assistant SI", "Sub Inspector",
	"Inspector", "DSP", "ASP", "SP", "DIG", "IG", "Commissioner"
]

const ENEMY_TYPES = ["pickpocket", "thug", "pickpocket", "thug", "smuggler", "guard", "hitman", "elite"]

const BOSS_NAMES = {
	5: "Gunda King", 10: "Hawala Don", 15: "Border Lord", 20: "Minister Sahib", 25: "The Commissioner"
}

const CIVILIAN_TYPES = ["chai_wala", "news_boy", "teacher", "nurse", "auto_driver"]
const CIVILIAN_NAMES = {
	"chai_wala": "Chai Wala", "news_boy": "News Boy", "teacher": "Teacher",
	"nurse": "Nurse", "auto_driver": "Auto Driver"
}
const CIVILIAN_BUFFS = {
	"chai_wala": { "hp": 3 }, "news_boy": { "xp": 10 }, "teacher": { "xp_mult": 1.5 },
	"nurse": { "max_hp": 5 }, "auto_driver": { "moves": 1 }
}

const ITEM_TYPES = ["lathi", "katta", "bandage", "vest", "cuffs", "whistle"]
const ITEM_EFFECTS = {
	"lathi": { "atk": 2 }, "katta": { "atk": 3 }, "bandage": { "hp_heal": 5 },
	"vest": { "def": 2 }, "cuffs": { "stun": 2 }, "whistle": { "atk": 1, "def": 1 }
}
const ITEM_NAMES = {
	"lathi": "Reinforced Lathi", "katta": "Katta", "bandage": "Bandage",
	"vest": "Vest", "cuffs": "Handcuffs", "whistle": "Whistle"
}

var player = {
	"x": 0, "y": 0,
	"hp": 20, "max_hp": 20,
	"atk": 5, "def": 2,
	"xp": 0,
	"level": 1,
	"floor": 1,
	"gold": 0,
	"kills": 0,
	"civilians_rescued": 0,
	"warrants": [],
	"inventory": [],
	"xp_mult": 1.0
}

var map_data = []         # 0=floor, 1=wall
var enemies = []          # {x,y,hp,max_hp,atk,def,type,xp,stun,is_boss}
var civilians = []        # {x,y,type,rescued}
var items = []            # {x,y,type}
var explored = []         # bool[MAP_W][MAP_H]
var vis_map = []          # bool[MAP_W][MAP_H]
var stair_x = 0
var stair_y = 0
var game_over = false
var turn_count = 0
var messages = []
var just_descended = false
var current_floor_intro := ""

const MOVE_REPEAT_DELAY = 0.16
const MOVE_REPEAT_INTERVAL = 0.09

var held_move_dir := Vector2i.ZERO
var move_repeat_timer := 0.0
var facing_dir := Vector2i.DOWN
var player_visual_from := Vector2.ZERO
var player_visual_to := Vector2.ZERO
var move_anim_timer := 0.0
var attack_anim_timer := 0.0

const MOVE_ANIM_DURATION = 0.12
const ATTACK_ANIM_DURATION = 0.18

# References set by main scene
var renderer = null
var hud = null

func _ready():
	renderer = get_node_or_null("Renderer")
	hud = get_node_or_null("HUDLayer/HUD")
	if renderer:
		renderer.game_state = self
	if hud:
		hud.game_state = self
	init_dungeon(1)
	render()

func _process(delta):
	if game_over:
		held_move_dir = Vector2i.ZERO
		return
	
	if move_anim_timer > 0.0:
		move_anim_timer = max(0.0, move_anim_timer - delta)
		render(true)
	if attack_anim_timer > 0.0:
		attack_anim_timer = max(0.0, attack_anim_timer - delta)
		render(true)
	
	var move_dir = get_keyboard_move_dir()
	if move_dir == Vector2i.ZERO:
		held_move_dir = Vector2i.ZERO
		move_repeat_timer = 0.0
		return
	
	facing_dir = move_dir
	if move_dir != held_move_dir:
		held_move_dir = move_dir
		move_repeat_timer = MOVE_REPEAT_DELAY
		try_move(move_dir.x, move_dir.y)
		return
	
	move_repeat_timer -= delta
	if move_repeat_timer <= 0.0:
		move_repeat_timer = MOVE_REPEAT_INTERVAL
		try_move(move_dir.x, move_dir.y)

func get_keyboard_move_dir() -> Vector2i:
	var x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	var y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	if y != 0:
		return Vector2i(0, y)
	if x != 0:
		return Vector2i(x, 0)
	return Vector2i.ZERO

func get_zone_index(floor: int) -> int:
	for i in range(ZONES.size() - 1, -1, -1):
		if floor >= ZONES[i].floor:
			return i
	return 0

func get_rank() -> String:
	return RANKS[min(player.level - 1, RANKS.size() - 1)]

func check_level_up():
	var xp_needed = 20 + player.level * 15 + pow(player.level, 1.5) * 2
	while player.xp >= xp_needed:
		player.xp -= xp_needed
		player.level += 1
		player.max_hp += 5
		player.hp = player.max_hp
		player.atk += 2
		player.def += 1
		add_message("LEVEL UP! Now " + get_rank(), Color("#44dd44"))
		if player.warrants.size() < 10:
			var wnames = [
				"Lathi Mastery", "FIR Filing", "Handcuff Slam", "Crowd Control",
				"Body Armor", "Solidarity", "Beat Patrol", "Tip-Off Network",
				"Baton Charge", "Honorary Medal"
			]
			player.warrants.append(wnames[player.warrants.size()])
			add_message("New Warrant: " + wnames[player.warrants.size() - 1], Color("#D4A843"))
		xp_needed = 20 + player.level * 15 + pow(player.level, 1.5) * 2

func add_message(text: String, color := Color("#cccccc")):
	messages.append({ "text": text, "color": color })
	if messages.size() > 12:
		messages.pop_front()
	print(text)

func get_item_name(item_type: String) -> String:
	return ITEM_NAMES.get(item_type, item_type.capitalize())

func get_floor_boss_name() -> String:
	return BOSS_NAMES.get(player.floor, ZONES[get_zone_index(player.floor)].name.split(" - ")[0] + " Captain")

func is_floor_boss_alive() -> bool:
	for e in enemies:
		if e.is_boss and e.hp > 0:
			return true
	return false

func init_dungeon(floor_num: int):
	map_data.clear()
	enemies.clear()
	civilians.clear()
	items.clear()
	explored.clear()
	vis_map.clear()
	
	for x in range(MAP_W):
		map_data.append([])
		explored.append([])
		vis_map.append([])
		for y in range(MAP_H):
			map_data[x].append(1)
			explored[x].append(false)
			vis_map[x].append(false)
	
	# BSP room generation
	var rooms = []
	var num_rooms = 6 + randi() % 5
	for _attempt in range(100):
		if rooms.size() >= num_rooms:
			break
		var rw = 5 + randi() % 8
		var rh = 5 + randi() % 8
		var rx = 1 + randi() % (MAP_W - rw - 2)
		var ry = 1 + randi() % (MAP_H - rh - 2)
		var overlap = false
		for r in rooms:
			if rx < r.x + r.w + 1 and rx + rw + 1 > r.x and ry < r.y + r.h + 1 and ry + rh + 1 > r.y:
				overlap = true
				break
		if overlap:
			continue
		for x in range(rx, rx + rw):
			for y in range(ry, ry + rh):
				map_data[x][y] = 0
		if rooms.size() > 0:
			var prev = rooms[-1]
			var px = int(prev.x + prev.w / 2)
			var py = int(prev.y + prev.h / 2)
			var cx = int(rx + rw / 2)
			var cy = int(ry + rh / 2)
			var sx = 1 if cx > px else -1
			var xp = int(px)
			while xp != int(cx):
				map_data[xp][int(py)] = 0
				xp += sx
			var sy = 1 if cy > py else -1
			var yp = int(py)
			while yp != int(cy):
				map_data[int(cx)][yp] = 0
				yp += sy
		rooms.append({ "x": rx, "y": ry, "w": rw, "h": rh })
	
	var first = rooms[0]
	player.x = int(first.x + first.w / 2)
	player.y = int(first.y + first.h / 2)
	player.floor = floor_num
	current_floor_intro = "Basti Beat: rescue civilians, clear alleys, find the stairs." if floor_num == 1 else ""
	
	var last = rooms[-1]
	stair_x = int(last.x + last.w / 2)
	stair_y = int(last.y + last.h / 2)
	
	# Enemies
	var ecount = 3 if floor_num == 1 else int(min(4 + floor_num * 0.6, 12))
	var etype_max = int(min((floor_num - 1) / 4, ENEMY_TYPES.size() - 1))
	for i in range(ecount):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1 if rooms.size() > 1 else 0
		var r = rooms[ri]
		var ex = r.x + 1 + randi() % max(1, r.w - 2)
		var ey = r.y + 1 + randi() % max(1, r.h - 2)
		var et = ["thug", "pickpocket", "thug"][i] if floor_num == 1 else ENEMY_TYPES[randi() % (etype_max + 1)]
		enemies.append({
			"x": ex, "y": ey, "hp": 8 + floor_num * 2, "max_hp": 8 + floor_num * 2,
			"atk": 2 + floor_num if floor_num == 1 else 3 + floor_num, "def": 0 if floor_num == 1 else 1 + floor_num / 2,
			"type": et, "xp": 5 + floor_num * 2, "stun": 0, "is_boss": false
		})
		# Every floor has a captain/boss that must be defeated before stairs unlock.
		if i == ecount - 1:
			var b = enemies[-1]
			b.is_boss = true
			b.max_hp = 30 + floor_num * 5 if floor_num % 5 == 0 else 14 + floor_num * 4
			b.hp = b.max_hp
			b.atk = 10 + floor_num * 3 if floor_num % 5 == 0 else 3 + floor_num
			b.def = 5 + floor_num / 2 if floor_num % 5 == 0 else 1
			b.xp = 50 + floor_num * 5 if floor_num % 5 == 0 else 12 + floor_num * 3
			b.x = stair_x
			b.y = stair_y - 1
	
	# Civilians
	var cc = 1 if floor_num == 1 else 1 + randi() % 3
	for i in range(cc):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1
		var r = rooms[ri]
		var cx = r.x + 1 + randi() % max(1, r.w - 2)
		var cy = r.y + 1 + randi() % max(1, r.h - 2)
		var ctype = "chai_wala" if floor_num == 1 else CIVILIAN_TYPES[randi() % CIVILIAN_TYPES.size()]
		civilians.append({ "x": cx, "y": cy, "type": ctype, "rescued": false })
	
	# Items
	var ic = 2 if floor_num == 1 else 1 + randi() % 3
	for i in range(ic):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1
		var r = rooms[ri]
		var ix = r.x + 1 + randi() % max(1, r.w - 2)
		var iy = r.y + 1 + randi() % max(1, r.h - 2)
		var item_type = ["bandage", "lathi"][i] if floor_num == 1 else ITEM_TYPES[randi() % ITEM_TYPES.size()]
		items.append({ "x": ix, "y": iy, "type": item_type })
	
	polish_floor_layout(floor_num)
	
	player_visual_from = Vector2(player.x, player.y)
	player_visual_to = player_visual_from
	move_anim_timer = 0.0
	attack_anim_timer = 0.0
	
	update_fov()
	update_explored()
	if floor_num == 1:
		add_message("Sadarpur Basti patrol started.", Color("#D4A843"))
		add_message("Rescue the Chai Wala with R when adjacent.", Color("#99bbdd"))
	add_message("Floor " + str(floor_num) + " — " + ZONES[get_zone_index(floor_num)].name, Color("#88ccff"))

func polish_floor_layout(floor_num: int):
	if floor_num == 1:
		polish_first_floor()
	else:
		polish_procedural_floor(floor_num)

func polish_first_floor():
	_build_first_floor_layout()
	
	civilians.clear()
	items.clear()
	enemies.clear()
	
	civilians.append({ "x": 15, "y": 11, "type": "chai_wala", "rescued": false })
	
	items.append({ "x": 7, "y": 25, "type": "bandage" })
	items.append({ "x": 15, "y": 28, "type": "lathi" })
	
	enemies.append({ "x": 22, "y": 18, "hp": 9, "max_hp": 9, "atk": 3, "def": 0, "type": "thug", "xp": 6, "stun": 0, "is_boss": false })
	enemies.append({ "x": 26, "y": 21, "hp": 7, "max_hp": 7, "atk": 2, "def": 0, "type": "pickpocket", "xp": 7, "stun": 0, "is_boss": false })
	enemies.append({ "x": 31, "y": 18, "hp": 18, "max_hp": 18, "atk": 3, "def": 1, "type": "thug", "xp": 15, "stun": 0, "is_boss": true })

func _build_first_floor_layout():
	for x in range(MAP_W):
		for y in range(MAP_H):
			map_data[x][y] = 1
	
	_carve_room(Rect2i(4, 20, 9, 8))    # police entry chowk
	_carve_room(Rect2i(12, 8, 8, 7))    # chai stall rescue
	_carve_room(Rect2i(12, 25, 9, 7))   # supply shortcut
	_carve_room(Rect2i(20, 16, 10, 9))  # street fight arena
	_carve_room(Rect2i(30, 14, 7, 10))  # captain and stairs
	
	_carve_h_corridor(12, 23, 23)
	_carve_h_corridor(19, 22, 12)
	_carve_h_corridor(20, 24, 28)
	_carve_h_corridor(29, 32, 19)
	_carve_v_corridor(16, 12, 28)
	_carve_v_corridor(24, 18, 28)
	
	_add_cover(Rect2i(8, 22, 1, 3))
	_add_cover(Rect2i(16, 10, 2, 1))
	_add_cover(Rect2i(22, 20, 1, 3))
	_add_cover(Rect2i(27, 17, 1, 2))
	_add_cover(Rect2i(33, 16, 1, 2))
	
	player.x = 7
	player.y = 24
	stair_x = 34
	stair_y = 21

func polish_procedural_floor(floor_num: int):
	var path_y = 18 + randi() % 5
	var upper_y = 6 + randi() % 5
	var lower_y = 27 + randi() % 4
	var rooms = [
		Rect2i(3, path_y - 3, 8, 7),
		Rect2i(12, upper_y, 8, 7),
		Rect2i(12, lower_y, 9, 7),
		Rect2i(21, path_y - 4, 10, 9),
		Rect2i(30, path_y - 5, 7, 10)
	]
	
	for x in range(MAP_W):
		for y in range(MAP_H):
			map_data[x][y] = 1
	
	for room in rooms:
		_carve_room(room)
	
	var start_center = _room_center(rooms[0])
	var rescue_center = _room_center(rooms[1])
	var supply_center = _room_center(rooms[2])
	var arena_center = _room_center(rooms[3])
	var boss_center = _room_center(rooms[4])
	_carve_h_corridor(start_center.x, arena_center.x, start_center.y)
	_carve_v_corridor(arena_center.x, start_center.y, arena_center.y)
	_carve_h_corridor(rescue_center.x, arena_center.x, rescue_center.y)
	_carve_v_corridor(arena_center.x, rescue_center.y, arena_center.y)
	_carve_h_corridor(supply_center.x, arena_center.x, supply_center.y)
	_carve_v_corridor(arena_center.x, arena_center.y, supply_center.y)
	_carve_h_corridor(arena_center.x, boss_center.x, boss_center.y)
	
	_add_zone_cover(floor_num, rooms[1])
	_add_zone_cover(floor_num, rooms[2])
	_add_zone_cover(floor_num, rooms[3])
	_add_zone_cover(floor_num, rooms[4])
	
	player.x = start_center.x
	player.y = start_center.y
	var occupied = [Vector2i(player.x, player.y)]
	var stair_pos = get_free_open_tile(Vector2i(boss_center.x + 2, boss_center.y + 2), occupied)
	stair_x = stair_pos.x
	stair_y = stair_pos.y
	occupied.append(stair_pos)
	
	civilians.clear()
	items.clear()
	enemies.clear()
	
	var civilian_pos = get_free_open_tile(rescue_center, occupied)
	occupied.append(civilian_pos)
	civilians.append({ "x": civilian_pos.x, "y": civilian_pos.y, "type": CIVILIAN_TYPES[randi() % CIVILIAN_TYPES.size()], "rescued": false })
	
	var item_pos_a = get_free_open_tile(Vector2i(supply_center.x - 2, supply_center.y), occupied)
	occupied.append(item_pos_a)
	var item_pos_b = get_free_open_tile(Vector2i(supply_center.x + 2, supply_center.y + 1), occupied)
	occupied.append(item_pos_b)
	items.append({ "x": item_pos_a.x, "y": item_pos_a.y, "type": ITEM_TYPES[randi() % ITEM_TYPES.size()] })
	items.append({ "x": item_pos_b.x, "y": item_pos_b.y, "type": ITEM_TYPES[randi() % ITEM_TYPES.size()] })
	
	var etype_max = int(min((floor_num - 1) / 4, ENEMY_TYPES.size() - 1))
	var enemy_count = int(min(3 + floor_num * 0.55, 10))
	var spawn_points = [
		Vector2i(arena_center.x - 3, arena_center.y - 2),
		Vector2i(arena_center.x + 3, arena_center.y + 2),
		Vector2i(arena_center.x + 1, arena_center.y - 3),
		Vector2i(rescue_center.x + 2, rescue_center.y + 1),
		Vector2i(supply_center.x + 2, supply_center.y - 1),
		Vector2i(boss_center.x - 2, boss_center.y - 2)
	]
	for i in range(enemy_count):
		var base_p = spawn_points[i % spawn_points.size()]
		var p = get_free_open_tile(base_p + Vector2i(int(i / spawn_points.size()), 0), occupied)
		occupied.append(p)
		var et = ENEMY_TYPES[randi() % (etype_max + 1)]
		enemies.append({
			"x": p.x, "y": p.y, "hp": 8 + floor_num * 2, "max_hp": 8 + floor_num * 2,
			"atk": 3 + floor_num, "def": 1 + floor_num / 2,
			"type": et, "xp": 5 + floor_num * 2, "stun": 0, "is_boss": false
		})
	
	var boss_pos = get_free_open_tile(Vector2i(boss_center.x, boss_center.y - 1), occupied)
	enemies.append({
		"x": boss_pos.x, "y": boss_pos.y,
		"hp": 30 + floor_num * 5 if floor_num % 5 == 0 else 14 + floor_num * 4,
		"max_hp": 30 + floor_num * 5 if floor_num % 5 == 0 else 14 + floor_num * 4,
		"atk": 10 + floor_num * 3 if floor_num % 5 == 0 else 3 + floor_num,
		"def": 5 + floor_num / 2 if floor_num % 5 == 0 else 1,
		"type": ENEMY_TYPES[min(etype_max, ENEMY_TYPES.size() - 1)], "xp": 50 + floor_num * 5 if floor_num % 5 == 0 else 12 + floor_num * 3,
		"stun": 0, "is_boss": true
	})

func _room_center(room: Rect2i) -> Vector2i:
	return Vector2i(room.position.x + int(room.size.x / 2), room.position.y + int(room.size.y / 2))

func _add_cover(rect: Rect2i):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x > 0 and x < MAP_W - 1 and y > 0 and y < MAP_H - 1:
				map_data[x][y] = 1

func _add_zone_cover(floor_num: int, room: Rect2i):
	var c = _room_center(room)
	match get_zone_index(floor_num):
		0:
			_add_cover(Rect2i(c.x - 2, c.y + 2, 3, 1))
		1:
			_add_cover(Rect2i(c.x - 3, c.y + 2, 4, 1))
		2:
			_add_cover(Rect2i(c.x + 2, c.y - 2, 1, 4))
		3:
			_add_cover(Rect2i(c.x - 2, c.y - 1, 1, 3))
			_add_cover(Rect2i(c.x + 2, c.y - 1, 1, 3))
		4:
			_add_cover(Rect2i(c.x - 3, c.y + 2, 5, 1))

func _carve_room(rect: Rect2i):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x > 0 and x < MAP_W - 1 and y > 0 and y < MAP_H - 1:
				map_data[x][y] = 0

func _carve_h_corridor(x1: int, x2: int, y: int):
	for x in range(min(x1, x2), max(x1, x2) + 1):
		for yy in range(y - 1, y + 2):
			if x > 0 and x < MAP_W - 1 and yy > 0 and yy < MAP_H - 1:
				map_data[x][yy] = 0

func _carve_v_corridor(x: int, y1: int, y2: int):
	for y in range(min(y1, y2), max(y1, y2) + 1):
		for xx in range(x - 1, x + 2):
			if xx > 0 and xx < MAP_W - 1 and y > 0 and y < MAP_H - 1:
				map_data[xx][y] = 0

func get_nearest_open_tile(preferred: Vector2i, avoid: Vector2i) -> Vector2i:
	var best := Vector2i(clampi(preferred.x, 1, MAP_W - 2), clampi(preferred.y, 1, MAP_H - 2))
	if map_data[best.x][best.y] == 0 and best != avoid:
		return best
	
	for radius in range(1, 8):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var p := Vector2i(best.x + dx, best.y + dy)
				if p.x <= 0 or p.x >= MAP_W - 1 or p.y <= 0 or p.y >= MAP_H - 1:
					continue
				if p == avoid:
					continue
				if map_data[p.x][p.y] == 0:
					return p
	return best

func get_free_open_tile(preferred: Vector2i, occupied: Array) -> Vector2i:
	var best := get_nearest_open_tile(preferred, Vector2i(-999, -999))
	if not occupied.has(best):
		return best
	
	for radius in range(1, 10):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var p := Vector2i(best.x + dx, best.y + dy)
				if p.x <= 0 or p.x >= MAP_W - 1 or p.y <= 0 or p.y >= MAP_H - 1:
					continue
				if occupied.has(p):
					continue
				if map_data[p.x][p.y] == 0:
					return p
	return best

func update_fov():
	for x in range(MAP_W):
		for y in range(MAP_H):
			vis_map[x][y] = false
	
	var px = int(player.x)
	var py = int(player.y)
	var r = FOV_RADIUS
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r * r: continue
			var tx = px + dx
			var ty = py + dy
			if tx < 0 or tx >= MAP_W or ty < 0 or ty >= MAP_H: continue
			var blocked = false
			var steps = max(abs(dx), abs(dy))
			for s in range(1, steps + 1):
				var lx = int(px + round(dx * s / float(steps)))
				var ly = int(py + round(dy * s / float(steps)))
				if lx == tx and ly == ty: break
				if map_data[lx][ly] == 1: blocked = true; break
			if not blocked or (abs(dx) <= 1 and abs(dy) <= 1):
				vis_map[tx][ty] = true

func update_explored():
	for x in range(MAP_W):
		for y in range(MAP_H):
			if vis_map[x][y]:
				explored[x][y] = true

func try_move(dx: int, dy: int):
	if game_over: return
	facing_dir = Vector2i(dx, dy)
	var old_pos = Vector2(player.x, player.y)
	var nx = player.x + dx
	var ny = player.y + dy
	if nx < 0 or nx >= MAP_W or ny < 0 or ny >= MAP_H: return
	if map_data[nx][ny] == 1: return
	
	# Attack enemy
	for e in enemies:
		if e.x == nx and e.y == ny and e.hp > 0:
			attack_enemy(e)
			return
	
	# Stairs
	if nx == stair_x and ny == stair_y:
		if is_floor_boss_alive():
			add_message("Stairs locked. Arrest " + get_floor_boss_name() + " first.", Color("#ffcc66"))
			render(true)
			return
		descend_or_win()
		return
	
	player.x = nx; player.y = ny
	start_move_animation(old_pos, Vector2(player.x, player.y))
	turn_count += 1
	end_turn()

func start_move_animation(from_tile: Vector2, to_tile: Vector2):
	player_visual_from = from_tile
	player_visual_to = to_tile
	move_anim_timer = MOVE_ANIM_DURATION

func descend_or_win():
	if player.floor >= MAX_FLOORS:
		game_over = true
		add_message("VICTORY! Commissioner arrested!", Color("#D4A843"))
		render(true)
		return
	player.floor += 1
	add_message("Descending to Floor " + str(player.floor), Color("#88ccff"))
	init_dungeon(player.floor)
	check_level_up()
	just_descended = true
	render(true)

func attack_enemy(e, spend_turn: bool = true):
	attack_anim_timer = ATTACK_ANIM_DURATION
	var dmg = max(1, player.atk + randi() % 3 - int(e.def))
	if e.stun > 0:
		dmg *= 2
	e.hp -= dmg
	add_message("Lathi strike! " + str(dmg) + " damage", Color("#ff8844"))
	if e.hp <= 0:
		player.kills += 1
		player.xp += int(e.xp * player.xp_mult)
		if e.is_boss:
			add_message(get_floor_boss_name() + " arrested! Stairs unlocked.", Color("#44dd44"))
		add_message("+" + str(e.xp) + " XP", Color("#44dd44"))
	else:
		e.stun = max(0, e.stun - 1)
	if spend_turn:
		end_turn()
	else:
		check_level_up()
		render(true)

func get_adjacent_enemy():
	var preferred_x = player.x + facing_dir.x
	var preferred_y = player.y + facing_dir.y
	for e in enemies:
		if e.hp > 0 and e.x == preferred_x and e.y == preferred_y:
			return e
	for e in enemies:
		if e.hp > 0 and abs(e.x - player.x) + abs(e.y - player.y) == 1:
			return e
	return null

func attack_adjacent_enemy():
	if game_over:
		return
	var target = get_adjacent_enemy()
	if target:
		attack_enemy(target)
	else:
		add_message("No enemy in lathi range.", Color("#888888"))
		render(true)

func end_turn():
	update_fov()
	update_explored()
	check_level_up()
	check_item_pickups()
	enemy_phase()
	render(true)

func check_item_pickups():
	var to_remove = []
	for i in range(items.size()):
		if items[i].x == player.x and items[i].y == player.y:
			var it = items[i].type
			if ITEM_EFFECTS.has(it):
				var eff = ITEM_EFFECTS[it]
				if eff.has("hp_heal"): player.hp = min(player.max_hp, player.hp + eff.hp_heal)
				if eff.has("atk"): player.atk += eff.atk
				if eff.has("def"): player.def += eff.def
			player.inventory.append(it)
			add_message("Picked up " + get_item_name(it), Color("#D4A843"))
			to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		items.remove_at(i)

func attack_player(e, label: String = "hits"):
	var dmg = max(1, e.atk + randi() % 2 - int(player.def))
	player.hp -= dmg
	add_message(e.type.capitalize() + " " + label + " for " + str(dmg) + " damage", Color("#ff4444"))
	if player.hp <= 0:
		player.hp = 0
		game_over = true
		add_message("Fell in the line of duty...", Color("#ff3333"))

func tile_key(p: Vector2i) -> String:
	return str(p.x) + "," + str(p.y)

func is_tile_walkable_for_enemy(p: Vector2i, reserved: Array) -> bool:
	if p.x < 0 or p.x >= MAP_W or p.y < 0 or p.y >= MAP_H:
		return false
	if map_data[p.x][p.y] == 1:
		return false
	if p.x == player.x and p.y == player.y:
		return false
	if reserved.has(p):
		return false
	return true

func has_clear_cardinal_line(from_p: Vector2i, to_p: Vector2i) -> bool:
	if from_p.x != to_p.x and from_p.y != to_p.y:
		return false
	var sx = 0
	var sy = 0
	if to_p.x > from_p.x:
		sx = 1
	elif to_p.x < from_p.x:
		sx = -1
	if to_p.y > from_p.y:
		sy = 1
	elif to_p.y < from_p.y:
		sy = -1
	var step := Vector2i(sx, sy)
	var p := from_p + step
	while p != to_p:
		if p.x < 0 or p.x >= MAP_W or p.y < 0 or p.y >= MAP_H:
			return false
		if map_data[p.x][p.y] == 1:
			return false
		p += step
	return true

func get_enemy_neighbors(p: Vector2i, reserved: Array) -> Array:
	var result = []
	var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		var np = p + d
		if is_tile_walkable_for_enemy(np, reserved):
			result.append(np)
	return result

func get_adjacent_goal_tiles(target: Vector2i, reserved: Array) -> Array:
	var goals = []
	var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		var p = target + d
		if is_tile_walkable_for_enemy(p, reserved):
			goals.append(p)
	return goals

func find_step_toward(start: Vector2i, goals: Array, reserved: Array, max_depth: int = 80) -> Vector2i:
	if goals.is_empty():
		return start
	var goal_keys = {}
	for g in goals:
		goal_keys[tile_key(g)] = true
	
	var queue = [{ "pos": start, "first": start, "depth": 0 }]
	var visited = { tile_key(start): true }
	var head = 0
	while head < queue.size():
		var entry = queue[head]
		head += 1
		var p: Vector2i = entry["pos"]
		if goal_keys.has(tile_key(p)):
			return entry["first"]
		if entry["depth"] >= max_depth:
			continue
		for np in get_enemy_neighbors(p, reserved):
			var key = tile_key(np)
			if visited.has(key):
				continue
			visited[key] = true
			queue.append({
				"pos": np,
				"first": np if p == start else entry["first"],
				"depth": entry["depth"] + 1
			})
	return start

func choose_flee_step(start: Vector2i, reserved: Array) -> Vector2i:
	var best = start
	var best_score = abs(start.x - player.x) + abs(start.y - player.y)
	for np in get_enemy_neighbors(start, reserved):
		var score = abs(np.x - player.x) + abs(np.y - player.y)
		if score > best_score:
			best = np
			best_score = score
	return best

func choose_flank_step(start: Vector2i, reserved: Array) -> Vector2i:
	var options = get_enemy_neighbors(start, reserved)
	options.shuffle()
	var current_dist = abs(start.x - player.x) + abs(start.y - player.y)
	for np in options:
		var dist = abs(np.x - player.x) + abs(np.y - player.y)
		if dist == current_dist and has_clear_cardinal_line(np, Vector2i(player.x, player.y)):
			return np
	for np in options:
		if abs(np.x - player.x) + abs(np.y - player.y) == current_dist:
			return np
	return start

func choose_enemy_step(e, reserved: Array) -> Vector2i:
	var start := Vector2i(int(e.x), int(e.y))
	var player_tile := Vector2i(int(player.x), int(player.y))
	var dist = abs(start.x - player_tile.x) + abs(start.y - player_tile.y)
	var low_hp = float(e.hp) / max(1.0, float(e.max_hp)) <= 0.35
	var ranged_type = e.type in ["smuggler", "guard", "hitman", "elite"]
	
	if low_hp and e.type in ["pickpocket", "hitman"]:
		return choose_flee_step(start, reserved)
	if ranged_type and dist < 3:
		return choose_flee_step(start, reserved)
	if ranged_type and dist >= 3 and dist <= 4 and has_clear_cardinal_line(start, player_tile):
		return choose_flank_step(start, reserved)
	if e.is_boss and dist <= 6:
		return find_step_toward(start, get_adjacent_goal_tiles(player_tile, reserved), reserved)
	if dist <= FOV_RADIUS + 4:
		return find_step_toward(start, get_adjacent_goal_tiles(player_tile, reserved), reserved)
	
	var patrol_target := Vector2i(stair_x, stair_y)
	return find_step_toward(start, get_adjacent_goal_tiles(patrol_target, reserved), reserved, 35)

func enemy_phase():
	var px = int(player.x)
	var py = int(player.y)
	var reserved = []
	for other in enemies:
		if other.hp > 0:
			reserved.append(Vector2i(int(other.x), int(other.y)))
	
	for e in enemies:
		if e.hp <= 0: continue
		if game_over: return
		if e.stun > 0:
			e.stun -= 1
			continue
		
		var current := Vector2i(int(e.x), int(e.y))
		reserved.erase(current)
		var dist = abs(e.x - px) + abs(e.y - py)
		if dist <= 1:
			attack_player(e, "strikes")
			reserved.append(current)
			continue
		
		var ranged_type = e.type in ["smuggler", "guard", "hitman", "elite"]
		if ranged_type and dist <= 4 and has_clear_cardinal_line(current, Vector2i(px, py)):
			attack_player(e, "shoots")
			reserved.append(current)
			continue
		
		var next_step = choose_enemy_step(e, reserved)
		if next_step != current:
			e.x = next_step.x
			e.y = next_step.y
			reserved.append(next_step)
		else:
			reserved.append(current)
	update_fov()
	update_explored()

func rescue_civilian():
	if game_over: return
	for c in civilians:
		if c.rescued: continue
		if abs(c.x - player.x) + abs(c.y - player.y) == 1:
			c.rescued = true
			player.civilians_rescued += 1
			var buff = CIVILIAN_BUFFS[c.type]
			if buff.has("hp"): player.hp = min(player.max_hp, player.hp + buff.hp)
			if buff.has("xp"): player.xp += buff.xp
			if buff.has("max_hp"): player.max_hp += buff.max_hp; player.hp += buff.max_hp
			if buff.has("xp_mult"): player.xp_mult += buff.xp_mult - 1.0
			add_message("Rescued " + CIVILIAN_NAMES[c.type] + "!", Color("#44dd44"))
			end_turn()
			return
	add_message("No one to rescue here.", Color("#888888"))

func render(update_hud_only: bool = false):
	if renderer: renderer.render(update_hud_only)
	if hud: hud.update()

func _input(event):
	if game_over: return
	if event.is_action_pressed("action_attack") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		attack_adjacent_enemy(); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("action_wait"):
		turn_count += 1; end_turn(); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("action_interact"):
		rescue_civilian(); get_viewport().set_input_as_handled()
