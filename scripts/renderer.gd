class_name renderer
extends Node2D
# Renderer — draws map tiles, entities, fog of war, animated sprites

const TILE_SIZE = 32
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
	if update_hud_only: return
	queue_redraw()

func _draw():
	if not game_state: return
	var gs = game_state
	if gs.map_data.is_empty(): return
	
	var vp = get_viewport_rect()
	if vp.size.x <= 1: return
	
	var cam = Vector2(gs.player.x * TILE_SIZE + TILE_SIZE/2, gs.player.y * TILE_SIZE + TILE_SIZE/2)
	position = -cam + vp.size / 2
	
	var vw = int(vp.size.x / TILE_SIZE) + 3
	var vh = int(vp.size.y / TILE_SIZE) + 3
	var px = gs.player.x - vw/2
	var py = gs.player.y - vh/2
	var zi = gs.get_zone_index(gs.player.floor)
	
	for x in range(max(0, px), min(MAP_W, px + vw)):
		for y in range(max(0, py), min(MAP_H, py + vh)):
			if not gs.explored[x][y]: continue
			var sx = x * TILE_SIZE; var sy = y * TILE_SIZE
			var tile_y = zi*64+32 if gs.map_data[x][y] == 0 else zi*64
			if tex_tiles: draw_texture_rect_region(tex_tiles, Rect2(sx, sy, TILE_SIZE, TILE_SIZE), Rect2(0, tile_y, TILE_SIZE, TILE_SIZE))
			if not gs.vis_map[x][y]: draw_rect(Rect2(sx, sy, TILE_SIZE, TILE_SIZE), Color(0, 0, 0, 0.6))
	
	for it in gs.items:
		if not gs.vis_map[it.x][it.y] or not tex_items: continue
		var idx = gs.ITEM_TYPES.find(it.type)
		if idx >= 0: draw_texture_rect_region(tex_items, Rect2(it.x*TILE_SIZE+8, it.y*TILE_SIZE+16, 16, 16), Rect2(idx*16, 0, 16, 16))
	
	for c in gs.civilians:
		if c.rescued or not gs.vis_map[c.x][c.y] or not tex_civilians: continue
		var idx = gs.CIVILIAN_TYPES.find(c.type)
		if idx >= 0: draw_texture_rect_region(tex_civilians, Rect2(c.x*TILE_SIZE+4, c.y*TILE_SIZE, 24, 32), Rect2(idx*24, 0, 24, 32))
	
	for e in gs.enemies:
		if e.hp <= 0 or not gs.vis_map[e.x][e.y]: continue
		if e.is_boss:
			if tex_bosses:
				var bi = clampi((e.max_hp - 30) / 25, 0, 4)
				draw_texture_rect_region(tex_bosses, Rect2(e.x*TILE_SIZE-8, e.y*TILE_SIZE-16, 48, 48), Rect2(bi*48, 0, 48, 48))
		elif tex_enemies:
			var idx = gs.ENEMY_TYPES.find(e.type)
			if idx >= 0: draw_texture_rect_region(tex_enemies, Rect2(e.x*TILE_SIZE, e.y*TILE_SIZE, 32, 32), Rect2(idx*32, 0, 32, 32))
		var hpct = float(e.hp) / e.max_hp
		draw_rect(Rect2(e.x*TILE_SIZE, e.y*TILE_SIZE-4, 32, 3), Color(0,0,0,0.6))
		var hpc = Color("#44dd44") if hpct>0.5 else Color("#dddd44") if hpct>0.25 else Color("#ff4444")
		draw_rect(Rect2(e.x*TILE_SIZE+1, e.y*TILE_SIZE-3, 30*hpct, 1), hpc)
	
	if gs.vis_map[gs.stair_x][gs.stair_y]:
		var sx = gs.stair_x*TILE_SIZE; var sy = gs.stair_y*TILE_SIZE
		draw_rect(Rect2(sx+8, sy+4, 16, 24), Color("#885522"))
		draw_rect(Rect2(sx+6, sy+2, 20, 4), Color("#aa7733"))
		for s in range(4): draw_rect(Rect2(sx+6+s*2, sy+6+s*6, 16-s*4, 2), Color("#665522"))
	
	if tex_player:
		var frame = (gs.turn_count % 3)
		draw_texture_rect_region(tex_player, Rect2(gs.player.x*TILE_SIZE, gs.player.y*TILE_SIZE-16, 32, 48), Rect2(frame*32, 0, 32, 48))
	
	if gs.game_over:
		var msg = "FELL IN LINE OF DUTY..." if gs.player.hp <= 0 else "VICTORY! Commissioner Arrested!"
		var col = Color("#ff3333") if gs.player.hp <= 0 else Color("#D4A843")
		var f = ThemeDB.fallback_font
		var fs = ThemeDB.fallback_font_size
		draw_rect(Rect2(-position.x, -position.y, vp.size.x, vp.size.y), Color(0,0,0,0.7))
		draw_string(f, vp.size/2 - Vector2(180, 10), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
