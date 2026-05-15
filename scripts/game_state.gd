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

# References set by main scene
var renderer = null
var hud = null

func _ready():
	# Find renderer and hud children
	for child in get_children():
		if child is Node2D and child.script and child.script.resource_path.find("renderer") >= 0:
			renderer = child
			child.game_state = self
		elif child is CanvasLayer and child.script and child.script.resource_path.find("hud") >= 0:
			hud = child
			child.game_state = self
	init_dungeon(1)

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

func init_dungeon(floor_num: int):
	map_data.clear()
	enemies.clear()
	civilians.clear()
	items.clear()
	explored.clear()
	
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
			var px = prev.x + prev.w / 2
			var py = prev.y + prev.h / 2
			var cx = rx + rw / 2
			var cy = ry + rh / 2
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
	player.x = first.x + first.w / 2
	player.y = first.y + first.h / 2
	player.floor = floor_num
	
	var last = rooms[-1]
	stair_x = last.x + last.w / 2
	stair_y = last.y + last.h / 2
	
	# Enemies
	var ecount = min(4 + floor_num * 0.6, 12)
	var etype_max = min((floor_num - 1) / 4, ENEMY_TYPES.size() - 1)
	for i in range(ecount):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1 if rooms.size() > 1 else 0
		var r = rooms[ri]
		var ex = r.x + 1 + randi() % max(1, r.w - 2)
		var ey = r.y + 1 + randi() % max(1, r.h - 2)
		var et = ENEMY_TYPES[randi() % (etype_max + 1)]
		enemies.append({
			"x": ex, "y": ey, "hp": 8 + floor_num * 2, "max_hp": 8 + floor_num * 2,
			"atk": 3 + floor_num, "def": 1 + floor_num / 2,
			"type": et, "xp": 5 + floor_num * 2, "stun": 0, "is_boss": false
		})
		# Boss on multiples of 5
		if floor_num % 5 == 0 and i == ecount - 1:
			var b = enemies[-1]
			b.is_boss = true
			b.max_hp = 30 + floor_num * 5
			b.hp = b.max_hp
			b.atk = 10 + floor_num * 3
			b.def = 5 + floor_num / 2
			b.xp = 50 + floor_num * 5
			b.x = stair_x
			b.y = stair_y - 1
	
	# Civilians
	var cc = 1 + randi() % 3
	for i in range(cc):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1
		var r = rooms[ri]
		var cx = r.x + 1 + randi() % max(1, r.w - 2)
		var cy = r.y + 1 + randi() % max(1, r.h - 2)
		civilians.append({ "x": cx, "y": cy, "type": CIVILIAN_TYPES[randi() % CIVILIAN_TYPES.size()], "rescued": false })
	
	# Items
	var ic = 1 + randi() % 3
	for i in range(ic):
		var ri = randi() % rooms.size()
		if ri == 0 and rooms.size() > 1: ri = 1
		var r = rooms[ri]
		var ix = r.x + 1 + randi() % max(1, r.w - 2)
		var iy = r.y + 1 + randi() % max(1, r.h - 2)
		items.append({ "x": ix, "y": iy, "type": ITEM_TYPES[randi() % ITEM_TYPES.size()] })
	
	update_fov()
	update_explored()
	add_message("Floor " + str(floor_num) + " — " + ZONES[get_zone_index(floor_num)].name, Color("#88ccff"))

func update_fov():
	for x in range(MAP_W):
		for y in range(MAP_H):
			vis_map[x][y] = false
	
	var px = player.x
	var py = player.y
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
				var lx = px + round(dx * s / float(steps))
				var ly = py + round(dy * s / float(steps))
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
	var nx = player.x + dx
	var ny = player.y + dy
	if nx < 0 or nx >= MAP_W or ny < 0 or ny >= MAP_H: return
	if map_data[nx][ny] == 1: return
	
	# Attack enemy
	for e in enemies:
		if e.x == nx and e.y == ny and e.hp > 0:
			var dmg = max(1, player.atk + randi() % 3 - int(e.def))
			if e.stun > 0: dmg *= 2
			e.hp -= dmg
			add_message("Lathi strike! " + str(dmg) + " damage", Color("#ff8844"))
			if e.hp <= 0:
				player.kills += 1
				player.xp += int(e.xp * player.xp_mult)
				if e.is_boss: add_message(BOSS_NAMES[player.floor] + " arrested!", Color("#44dd44"))
				add_message("+" + str(e.xp) + " XP", Color("#44dd44"))
			else:
				e.stun = max(0, e.stun - 1)
			end_turn()
			return
	
	# Stairs
	if nx == stair_x and ny == stair_y:
		if player.floor >= MAX_FLOORS:
			game_over = true
			add_message("VICTORY! Commissioner arrested!", Color("#D4A843"))
			render(true)
			return
		player.floor += 1
		player.x = nx; player.y = ny
		add_message("Descending to Floor " + str(player.floor), Color("#88ccff"))
		init_dungeon(player.floor)
		check_level_up()
		just_descended = true
		render(true)
		return
	
	player.x = nx; player.y = ny
	turn_count += 1
	end_turn()

func end_turn():
	update_fov()
	update_explored()
	check_level_up()
	
	# Item pickup
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
			add_message("Picked up " + it, Color("#D4A843"))
			to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		items.remove_at(i)
	
	enemy_phase()
	render(true)

func enemy_phase():
	var px = player.x; var py = player.y
	for e in enemies:
		if e.hp <= 0: continue
		if e.stun > 0: e.stun -= 1; continue
		var dist = abs(e.x - px) + abs(e.y - py)
		if dist <= 1:
			var dmg = max(1, e.atk + randi() % 2 - int(player.def))
			player.hp -= dmg
			add_message(e.type + " hits for " + str(dmg) + " damage", Color("#ff4444"))
			if player.hp <= 0:
				player.hp = 0; game_over = true
				add_message("Fell in the line of duty...", Color("#ff3333"))
				return
			continue
		var dx = sign(px - e.x); var dy = sign(py - e.y)
		var tries = [[dx, 0], [0, dy], [dx, dy], [-dx, 0], [0, -dy]]
		for t in tries:
			var nx = e.x + t[0]; var ny = e.y + t[1]
			if nx < 0 or nx >= MAP_W or ny < 0 or ny >= MAP_H: continue
			if map_data[nx][ny] == 1: continue
			var occ = false
			for e2 in enemies:
				if e2 != e and e2.x == nx and e2.y == ny and e2.hp > 0: occ = true; break
			if occ or (nx == px and ny == py): continue
			e.x = nx; e.y = ny; break
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
	if event.is_action_pressed("move_up"):
		try_move(0, -1); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		try_move(0, 1); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		try_move(-1, 0); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		try_move(1, 0); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("action_wait"):
		turn_count += 1; end_turn(); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("action_interact"):
		rescue_civilian(); get_viewport().set_input_as_handled()
