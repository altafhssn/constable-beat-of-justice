class_name FloorRenderer
extends Node2D

# Renders the floor grid using a TileMapLayer with themed tileset textures
# The themed tilesets are 128x128 — a 4x4 grid of 32x32px tiles
# We rescale to 24x24px for the actual game

const TILE_SIZE: int = 24
const ATLAS_TILES: int = 4  # 4 tiles per row/col in source

var grid: Array = []
var theme: int = 0

# Tilemap internals
var _tilemap_layer: TileMapLayer = null
var _source_id: int = -1

# Collision container for wall tiles
var _collision_root: Node2D = null
const COLLISION_LAYER: int = 2  # walls on layer 2 (player mask is 2)
const COLLISION_MASK: int = 0

# Tile atlas source images (themed 128x128 PNGs)
const THEME_PATHS = [
	"res://assets/tilesets/basti.png",
	"res://assets/tilesets/bazaar.png",
	"res://assets/tilesets/naka.png",
	"res://assets/tilesets/kothi.png",
	"res://assets/tilesets/commissioner.png",
]

# Room boundaries (for camera limiting)
var rooms: Array = []

func _ready():
	_tilemap_layer = TileMapLayer.new()
	_tilemap_layer.name = "TileMapLayer"
	add_child(_tilemap_layer)
	
	_collision_root = Node2D.new()
	_collision_root.name = "WallColliders"
	add_child(_collision_root)

func build_from_grid(grid_data: Array, floor_theme: int):
	grid = grid_data
	theme = floor_theme
	extract_rooms()
	build_tileset_from_theme()
	render_map()
	build_collision()

# Detect connected rooms from the grid
func extract_rooms():
	rooms.clear()
	if grid.is_empty():
		return
	
	var h = grid.size()
	var w = grid[0].size()
	var visited = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)
	
	for y in range(h):
		for x in range(w):
			var tile = grid[y][x]
			if tile < 0 or visited[y][x]:
				continue
			visited[y][x] = true
			
			if tile >= 0 and tile <= 5:
				# BFS for connected non-empty region
				var min_x = x
				var max_x = x
				var min_y = y
				var max_y = y
				var queue = [Vector2i(x, y)]
				var has_floor = (tile == 0)
				
				while queue.size() > 0:
					var p = queue.pop_front()
					min_x = mini(min_x, p.x)
					max_x = maxi(max_x, p.x)
					min_y = mini(min_y, p.y)
					max_y = maxi(max_y, p.y)
					
					for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						var np = p + d
						if np.y < 0 or np.y >= h or np.x < 0 or np.x >= w:
							continue
						if visited[np.y][np.x]:
							continue
						var nt = grid[np.y][np.x]
						if nt < 0:
							continue
						visited[np.y][np.x] = true
						queue.push_back(np)
						if nt == 0:
							has_floor = true
				
				# Only count regions with floor tiles as "rooms"
				if has_floor:
					rooms.append({"x": min_x, "y": min_y, "w": max_x - min_x + 1, "h": max_y - min_y + 1})

# Build a proper TileSet from themed atlas textures
func build_tileset_from_theme():
	if not _tilemap_layer:
		return
	
	# Load the themed texture
	var theme_path = THEME_PATHS[clampi(theme, 0, THEME_PATHS.size() - 1)]
	var src_texture = load(theme_path) as Texture2D
	if not src_texture:
		build_fallback_tileset()
		return
	
	var src_image = src_texture.get_image()
	if not src_image:
		build_fallback_tileset()
		return
	
	# Create an atlas image: we scale each 32x32 tile down to 24x24
	# and lay them out in a 4-column row for the TileSetAtlasSource
	var src_tile_sz = 32
	var atlas_cols = 4
	var atlas_img = Image.create(TILE_SIZE * atlas_cols, TILE_SIZE * ATLAS_TILES, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0, 0, 0, 0))
	
	for ty in range(ATLAS_TILES):
		for tx in range(atlas_cols):
			var region = Rect2i(tx * src_tile_sz, ty * src_tile_sz, src_tile_sz, src_tile_sz)
			var tile_img = src_image.get_region(region)
			tile_img.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
			atlas_img.blit_rect(tile_img, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(tx * TILE_SIZE, ty * TILE_SIZE))
	
	var atlas_texture = ImageTexture.create_from_image(atlas_img)
	
	# Build TileSet
	var ts = TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create tiles in the atlas (10 tiles: FLOOR, WALL, DOOR, STAIRS, BLOOD, DEBRIS + 4 variants)
	for i in range(10):
		var atlas_coord = Vector2i(i % atlas_cols, i / atlas_cols)
		atlas_source.create_tile(atlas_coord, Vector2i(1, 1))
	
	_source_id = ts.add_source(atlas_source, 0)
	_tilemap_layer.tile_set = ts

# Fallback: colored tiles when no theme texture available
func build_fallback_tileset():
	if not _tilemap_layer:
		return
	
	var colors = {
		0: get_floor_color(),
		1: get_wall_color(),
		2: Color(0.6, 0.4, 0.1),
		3: Color(1.0, 0.8, 0.1),
		4: Color(0.7, 0.1, 0.1),
		5: Color(0.4, 0.3, 0.2),
	}
	
	var atlas_img = Image.create(TILE_SIZE * 6, TILE_SIZE, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0, 0, 0, 0))
	
	for tile_type in [0, 1, 2, 3, 4, 5]:
		var color = colors.get(tile_type, Color(1, 0, 1))
		for py in range(TILE_SIZE):
			for px in range(TILE_SIZE):
				atlas_img.set_pixel(tile_type * TILE_SIZE + px, py, color)
	
	var atlas_texture = ImageTexture.create_from_image(atlas_img)
	
	var ts = TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	for i in range(6):
		atlas_source.create_tile(Vector2i(i, 0), Vector2i(1, 1))
	
	_source_id = ts.add_source(atlas_source, 0)
	_tilemap_layer.tile_set = ts

# Render the entire grid onto the TileMapLayer
func render_map():
	if not _tilemap_layer or _source_id < 0:
		return
	
	_tilemap_layer.clear()
	
	var atlas_source = _tilemap_layer.tile_set.get_source(_source_id) as TileSetAtlasSource
	if not atlas_source:
		return
	
	# FloorGenerator TileType → atlas column position
	# We use tiles from the atlas at specific (col, row) positions
	# Tile atlas positions with variants for visual variety
	# Each tile type gets a list of possible atlas coords (randomly picked per cell)
	var tile_variants = {
		0: [Vector2i(0, 0), Vector2i(2, 2)],   # FLOOR variants
		1: [Vector2i(0, 1), Vector2i(3, 2)],   # WALL variants (col 2 row 2 = tile index 10... wait)
		2: [Vector2i(1, 0)],                    # DOOR
		3: [Vector2i(1, 1)],                    # STAIRS
		4: [Vector2i(2, 0)],                    # BLOOD
		5: [Vector2i(2, 1)],                    # DEBRIS
	}
	
	# Calculate tile index for variants
	# Row 0: (0,0), (1,0), (2,0), (3,0) = indices 0-3
	# Row 1: (0,1), (1,1), (2,1), (3,1) = indices 4-7
	# Row 2: (0,2), (1,2), (2,2), (3,2) = indices 8-11
	# Update with proper tile indices
	tile_variants[0] = [Vector2i(0, 0), Vector2i(3, 0)]   # FLOOR: (0,0) or (3,0)
	tile_variants[1] = [Vector2i(0, 1), Vector2i(3, 1)]   # WALL: (0,1) or (3,1)
	
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var tile_type = grid[y][x]
			if tile_type < 0:
				continue
			
			var variants = tile_variants.get(tile_type, [Vector2i(0, 0)])
			# Use position-based hash for consistent per-cell variation
			var variant_index = (x * 7 + y * 13 + theme * 31) % variants.size()
			var atlas_coord = variants[variant_index]
			_tilemap_layer.set_cell(Vector2i(x, y), _source_id, atlas_coord, 0)

# Get room boundaries in pixel coordinates (for camera limits)
func get_room_bounds() -> Array:
	var bounds = []
	for room in rooms:
		bounds.append(Rect2(
			room.x * TILE_SIZE, room.y * TILE_SIZE,
			room.w * TILE_SIZE, room.h * TILE_SIZE
		))
	return bounds

# Get total map size in pixels
func get_map_size_pixels() -> Vector2:
	if grid.is_empty():
		return Vector2.ZERO
	return Vector2(grid[0].size() * TILE_SIZE, grid.size() * TILE_SIZE)

func get_floor_color() -> Color:
	match theme:
		0: return Color(0.55, 0.35, 0.17)
		1: return Color(0.78, 0.55, 0.25)
		2: return Color(0.45, 0.45, 0.45)
		3: return Color(0.75, 0.65, 0.55)
		4: return Color(0.12, 0.12, 0.20)
		_: return Color(0.5, 0.5, 0.5)

func get_wall_color() -> Color:
	match theme:
		0: return Color(0.35, 0.20, 0.10)
		1: return Color(0.55, 0.25, 0.20)
		2: return Color(0.30, 0.30, 0.30)
		3: return Color(0.60, 0.50, 0.40)
		4: return Color(0.05, 0.05, 0.10)
		_: return Color(0.3, 0.3, 0.3)

# Build collision shapes for wall tiles
func build_collision():
	# Clear old colliders
	for child in _collision_root.get_children():
		child.queue_free()
	
	if grid.is_empty():
		return
	
	var h = grid.size()
	var w = grid[0].size()
	var visited = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)
	
	# Merge wall tiles into horizontal rectangles for performance
	for y in range(h):
		var x = 0
		while x < w:
			var tile = grid[y][x]
			# Walls = tile type 1, Doors = 2, Debris = 5
			var is_solid = (tile == 1 or tile == 5)
			if not is_solid or visited[y][x]:
				x += 1
				continue
			
			# Find end of this horizontal run
			var run_end = x + 1
			while run_end < w and not visited[y][run_end]:
				var nt = grid[y][run_end]
				if nt == 1 or nt == 5:
					visited[y][run_end] = true
					run_end += 1
				else:
					break
			
			if run_end > x:
				_create_wall_rect(x, y, run_end - x, 1)
				x = run_end
			else:
				x += 1

func _create_wall_rect(grid_x: int, grid_y: int, width_tiles: int, height_tiles: int):
	var wall = StaticBody2D.new()
	wall.collision_layer = COLLISION_LAYER
	wall.collision_mask = COLLISION_MASK
	wall.position = Vector2(
		(grid_x + width_tiles / 2.0) * TILE_SIZE,
		(grid_y + height_tiles / 2.0) * TILE_SIZE
	)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(width_tiles * TILE_SIZE, height_tiles * TILE_SIZE)
	shape.shape = rect
	wall.add_child(shape)
	
	_collision_root.add_child(wall)
