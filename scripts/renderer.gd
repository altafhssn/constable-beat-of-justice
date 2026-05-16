class_name renderer
extends Node2D
# Renderer — draws map tiles, entities, fog of war, animated sprites

const TILE_SIZE = 48
const MAP_W = 40
const MAP_H = 40

var tex_player = null
var tex_enemies = null
var tex_bosses = null
var tex_civilians = null
var tex_items = null
var tex_tiles = null

var game_state = null
var _textures_loaded = false
var draw_offset := Vector2.ZERO

func _ready():
	game_state = get_parent()
	# Load textures programmatically
	tex_player = load("res://assets/sprites/player.png")
	tex_enemies = load("res://assets/sprites/enemies.png")
	tex_bosses = load("res://assets/sprites/bosses.png")
	tex_civilians = load("res://assets/sprites/civilians.png")
	tex_items = load("res://assets/sprites/items.png")
	tex_tiles = load("res://assets/tiles/tileset.png")
	_textures_loaded = (tex_player != null)

func render(update_hud_only: bool = false):
	if not _textures_loaded:
		_ready()
	queue_redraw()

func get_floor_color(zone_index: int, visible: bool) -> Color:
	if not visible:
		return Color("#17130f")
	match zone_index:
		0: return Color("#4a3424")
		1: return Color("#463020")
		2: return Color("#30323a")
		3: return Color("#4a4038")
		4: return Color("#252536")
		_: return Color("#30333a")

func get_wall_color(zone_index: int, visible: bool) -> Color:
	if not visible:
		return Color("#0c0907")
	match zone_index:
		0: return Color("#241912")
		1: return Color("#2f1712")
		2: return Color("#181a20")
		3: return Color("#2b2521")
		4: return Color("#11111d")
		_: return Color("#15171b")

func is_internal_cover(gs, x: int, y: int) -> bool:
	if gs.map_data[x][y] != 1:
		return false
	var floor_neighbors = 0
	var dirs = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for d in dirs:
		var nx = x + d.x
		var ny = y + d.y
		if nx < 0 or nx >= MAP_W or ny < 0 or ny >= MAP_H:
			continue
		if gs.map_data[nx][ny] == 0:
			floor_neighbors += 1
	return floor_neighbors >= 2

func get_cover_color(zone_index: int) -> Color:
	match zone_index:
		0: return Color("#8d6846")
		1: return Color("#b45d3b")
		2: return Color("#60646f")
		3: return Color("#7c6753")
		4: return Color("#60607d")
		_: return Color("#555555")

func draw_world_label(text: String, pos: Vector2, color: Color):
	var f = ThemeDB.fallback_font
	var fs = 13
	var size = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var label_pos = pos - Vector2(size.x * 0.5, 18)
	draw_rect(Rect2(label_pos + Vector2(-3, -12), size + Vector2(6, 16)), Color(0, 0, 0, 0.55))
	draw_string(f, label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)

func get_player_visual_tile(gs) -> Vector2:
	if gs.move_anim_timer <= 0.0:
		return Vector2(gs.player.x, gs.player.y)
	var t = 1.0 - (gs.move_anim_timer / gs.MOVE_ANIM_DURATION)
	return gs.player_visual_from.lerp(gs.player_visual_to, ease_out_cubic(t))

func draw_attack_arc(center: Vector2, dir: Vector2i, progress: float):
	var dir_vec := Vector2(dir.x, dir.y)
	var angle = dir_vec.angle()
	var reach = TILE_SIZE * 0.58
	var alpha = 1.0 - progress
	var arc_center = center + dir_vec * (TILE_SIZE * 0.42)
	draw_arc(arc_center, reach, angle - 0.9, angle + 0.9, 18, Color(1.0, 0.82, 0.35, alpha), 5.0)
	draw_line(center, arc_center + dir_vec * 12.0, Color(0.92, 0.62, 0.22, alpha), 4.0)

func _draw():
	if not game_state: return
	var gs = game_state
	if gs.map_data.is_empty(): return
	
	var vp = get_viewport_rect()
	if vp.size.x <= 1: return
	
	var player_visual_tile = get_player_visual_tile(gs)
	var player_tile := Vector2i(int(gs.player.x), int(gs.player.y))
	var cam = Vector2(player_visual_tile.x * TILE_SIZE + TILE_SIZE/2, player_visual_tile.y * TILE_SIZE + TILE_SIZE/2)
	draw_offset = -cam + vp.size / 2
	
	var vw = int(vp.size.x / TILE_SIZE) + 3
	var vh = int(vp.size.y / TILE_SIZE) + 3
	var px = player_tile.x - int(vw / 2)
	var py = player_tile.y - int(vh / 2)
	var zi = gs.get_zone_index(gs.player.floor)
	
	for x in range(max(0, px), min(MAP_W, px + vw)):
		for y in range(max(0, py), min(MAP_H, py + vh)):
			if not gs.explored[x][y]: continue
			var sx = x * TILE_SIZE + draw_offset.x; var sy = y * TILE_SIZE + draw_offset.y
			var is_floor = gs.map_data[x][y] == 0
			var tile_y = zi*64+32 if is_floor else zi*64
			var tile_rect = Rect2(sx, sy, TILE_SIZE, TILE_SIZE)
			
			if tex_tiles:
				draw_texture_rect_region(tex_tiles, tile_rect, Rect2(0, tile_y, TILE_SIZE, TILE_SIZE))
			
			var visible = gs.vis_map[x][y]
			if is_floor:
				draw_rect(tile_rect, get_floor_color(zi, visible))
				draw_rect(Rect2(sx + 1, sy + 1, TILE_SIZE - 2, TILE_SIZE - 2), Color("#6d5036") if visible and zi == 0 else Color("#202229"), false, 1.0)
				if visible and zi == 0 and (x + y) % 5 == 0:
					draw_rect(Rect2(sx + 4, sy + 20, 24, 3), Color("#2b2119"))
				if visible and zi == 0 and x % 7 == 0:
					draw_rect(Rect2(sx + 2, sy + 2, 4, 12), Color("#8d6846"))
			else:
				var cover = visible and is_internal_cover(gs, x, y)
				draw_rect(tile_rect, get_cover_color(zi) if cover else get_wall_color(zi, visible))
				if cover:
					draw_rect(Rect2(sx + 6, sy + 10, TILE_SIZE - 12, TILE_SIZE - 20), Color(0, 0, 0, 0.18))
					draw_rect(Rect2(sx + 8, sy + 12, TILE_SIZE - 16, 5), Color(1, 1, 1, 0.14))
				else:
					draw_rect(Rect2(sx + 2, sy + 2, TILE_SIZE - 4, TILE_SIZE - 4), Color("#3c2a1e") if visible and zi == 0 else Color("#111318"), false, 1.0)
	
	for it in gs.items:
		var item_tile := Vector2i(int(it.x), int(it.y))
		if not gs.vis_map[item_tile.x][item_tile.y]: continue
		var idx = gs.ITEM_TYPES.find(it.type)
		if idx >= 0 and tex_items:
			draw_texture_rect_region(tex_items, Rect2(item_tile.x*TILE_SIZE+draw_offset.x+8, item_tile.y*TILE_SIZE+draw_offset.y+16, 16, 16), Rect2(idx*16, 0, 16, 16))
		else:
			draw_circle(Vector2(item_tile.x*TILE_SIZE + draw_offset.x + 16, item_tile.y*TILE_SIZE + draw_offset.y + 16), 6, Color("#d4a843"))
		draw_world_label(gs.get_item_name(it.type), Vector2(item_tile.x*TILE_SIZE + draw_offset.x + 16, item_tile.y*TILE_SIZE + draw_offset.y + 14), Color("#f2c866"))
	
	for c in gs.civilians:
		var civilian_tile := Vector2i(int(c.x), int(c.y))
		if c.rescued or not gs.vis_map[civilian_tile.x][civilian_tile.y]: continue
		var idx = gs.CIVILIAN_TYPES.find(c.type)
		if idx >= 0 and tex_civilians:
			draw_texture_rect_region(tex_civilians, Rect2(civilian_tile.x*TILE_SIZE+draw_offset.x+4, civilian_tile.y*TILE_SIZE+draw_offset.y, 24, 32), Rect2(idx*24, 0, 24, 32))
		else:
			draw_rect(Rect2(civilian_tile.x*TILE_SIZE + draw_offset.x + 9, civilian_tile.y*TILE_SIZE + draw_offset.y + 6, 14, 20), Color("#7bd88f"))
		draw_world_label(gs.CIVILIAN_NAMES.get(c.type, "Civilian"), Vector2(civilian_tile.x*TILE_SIZE + draw_offset.x + 16, civilian_tile.y*TILE_SIZE + draw_offset.y + 8), Color("#9cffae"))
	
	for e in gs.enemies:
		var enemy_tile := Vector2i(int(e.x), int(e.y))
		if e.hp <= 0 or not gs.vis_map[enemy_tile.x][enemy_tile.y]: continue
		if e.is_boss:
			if tex_bosses:
				var bi = clampi(int((e.max_hp - 30) / 25), 0, 4)
				draw_texture_rect_region(tex_bosses, Rect2(enemy_tile.x*TILE_SIZE+draw_offset.x-8, enemy_tile.y*TILE_SIZE+draw_offset.y-16, 48, 48), Rect2(bi*48, 0, 48, 48))
			else:
				draw_rect(Rect2(enemy_tile.x*TILE_SIZE + draw_offset.x - 4, enemy_tile.y*TILE_SIZE + draw_offset.y - 8, 40, 40), Color("#b33a3a"))
		elif tex_enemies:
			var idx = gs.ENEMY_TYPES.find(e.type)
			if idx >= 0: draw_texture_rect_region(tex_enemies, Rect2(enemy_tile.x*TILE_SIZE+draw_offset.x, enemy_tile.y*TILE_SIZE+draw_offset.y, 32, 32), Rect2(idx*32, 0, 32, 32))
		else:
			draw_circle(Vector2(enemy_tile.x*TILE_SIZE + draw_offset.x + 16, enemy_tile.y*TILE_SIZE + draw_offset.y + 16), 11, Color("#d94a4a"))
		if e.is_boss:
			draw_world_label(gs.get_floor_boss_name(), Vector2(enemy_tile.x*TILE_SIZE + draw_offset.x + 16, enemy_tile.y*TILE_SIZE + draw_offset.y + 8), Color("#ffcc66"))
		elif gs.player.floor == 1:
			draw_world_label(e.type.capitalize(), Vector2(enemy_tile.x*TILE_SIZE + draw_offset.x + 16, enemy_tile.y*TILE_SIZE + draw_offset.y + 8), Color("#ff8c73"))
		var hpct = float(e.hp) / e.max_hp
		draw_rect(Rect2(enemy_tile.x*TILE_SIZE+draw_offset.x, enemy_tile.y*TILE_SIZE+draw_offset.y-4, 32, 3), Color(0,0,0,0.6))
		var hpc = Color("#44dd44") if hpct>0.5 else Color("#dddd44") if hpct>0.25 else Color("#ff4444")
		draw_rect(Rect2(enemy_tile.x*TILE_SIZE+draw_offset.x+1, enemy_tile.y*TILE_SIZE+draw_offset.y-3, 30*hpct, 1), hpc)
	
	if gs.vis_map[gs.stair_x][gs.stair_y]:
		var sx = gs.stair_x*TILE_SIZE + draw_offset.x; var sy = gs.stair_y*TILE_SIZE + draw_offset.y
		draw_rect(Rect2(sx+8, sy+4, 16, 24), Color("#885522"))
		draw_rect(Rect2(sx+6, sy+2, 20, 4), Color("#aa7733"))
		for s in range(4): draw_rect(Rect2(sx+6+s*2, sy+6+s*6, 16-s*4, 2), Color("#665522"))
		draw_world_label("Stairs", Vector2(sx + 16, sy + 6), Color("#f2c866"))
	
	var player_pos = Vector2(player_visual_tile.x*TILE_SIZE + draw_offset.x + TILE_SIZE * 0.5, player_visual_tile.y*TILE_SIZE + draw_offset.y + TILE_SIZE * 0.5)
	var move_progress = 0.0 if gs.move_anim_timer <= 0.0 else 1.0 - (gs.move_anim_timer / gs.MOVE_ANIM_DURATION)
	var bob = sin(move_progress * PI) * 6.0 if gs.move_anim_timer > 0.0 else 0.0
	var attack_progress = 0.0 if gs.attack_anim_timer <= 0.0 else 1.0 - (gs.attack_anim_timer / gs.ATTACK_ANIM_DURATION)
	var squash = 1.0 + sin(attack_progress * PI) * 0.14 if gs.attack_anim_timer > 0.0 else 1.0
	var facing_sign = -1.0 if gs.facing_dir.x < 0 else 1.0
	if tex_player:
		var frame = (gs.turn_count % 3)
		var body_rect = Rect2(player_pos.x - 18, player_pos.y - 42 - bob, 36, 54 * squash)
		draw_texture_rect_region(tex_player, body_rect, Rect2(frame*32, 0, 32, 48))
	
	# High-contrast marker guarantees the player is visible during prototyping.
	draw_circle(player_pos + Vector2(0, -bob), 11, Color("#4da3ff"))
	draw_circle(player_pos + Vector2(4 * facing_sign, -4 - bob), 3, Color("#ffffff"))
	if gs.attack_anim_timer > 0.0:
		draw_attack_arc(player_pos + Vector2(0, -bob), gs.facing_dir, attack_progress)
	draw_world_label("Constable", player_pos + Vector2(0, -18 - bob), Color("#9fd0ff"))
	
	if gs.game_over:
		var msg = "FELL IN LINE OF DUTY..." if gs.player.hp <= 0 else "VICTORY! Commissioner Arrested!"
		var col = Color("#ff3333") if gs.player.hp <= 0 else Color("#D4A843")
		var f = ThemeDB.fallback_font
		var fs = ThemeDB.fallback_font_size
		draw_rect(Rect2(0, 0, vp.size.x, vp.size.y), Color(0,0,0,0.7))
		draw_string(f, vp.size/2 - Vector2(180, 10), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
