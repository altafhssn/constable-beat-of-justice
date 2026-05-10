extends RefCounted

# Generates a floor with rooms, corridors, enemies, civilians, items

const TILE_SIZE: int = 24
const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 34
const MIN_ROOMS: int = 3
const MAX_ROOMS: int = 6

enum TileType {
	FLOOR = 0,
	WALL = 1,
	DOOR = 2,
	STAIRS = 3,
	BLOOD = 4,
	DEBRIS = 5,
	EMPTY = -1
}

var floor_theme: int = 0  # 0=Basti, 1=Bazaar, 2=Naka, 3=Kothi, 4=Commissioner

func generate(floor_num: int) -> Dictionary:
	# Determine theme based on floor number
	if floor_num <= 5: floor_theme = 0
	elif floor_num <= 10: floor_theme = 1
	elif floor_num <= 15: floor_theme = 2
	elif floor_num <= 20: floor_theme = 3
	else: floor_theme = 4
	
	# Generate room layout
	var tile_grid = generate_rooms()
	
	# Place player start
	var player_start = Vector2(TILE_SIZE * 2, TILE_SIZE * 2)
	
	# Place stairs (end of floor)
	var stairs_pos = find_farthest_room_center(tile_grid)
	if stairs_pos != Vector2.ZERO:
		tile_grid[int(stairs_pos.y / TILE_SIZE)][int(stairs_pos.x / TILE_SIZE)] = TileType.STAIRS
	
	# Generate enemies
	var enemies = generate_enemies(floor_num, tile_grid)
	
	# Generate civilians
	var civilians = generate_civilians(floor_num, tile_grid)
	
	# Generate items
	var items = generate_items(floor_num, tile_grid)
	
	return {
		"tilemap": create_tilemap(tile_grid),
		"player_start": player_start,
		"enemies": enemies,
		"civilians": civilians,
		"items": items
	}

func generate_rooms() -> Array:
	var grid = []
	for y in range(MAP_HEIGHT):
		grid.append([])
		for x in range(MAP_WIDTH):
			grid[y].append(TileType.EMPTY)
	
	# Simple room generation: create rectangular rooms
	var num_rooms = randi() % (MAX_ROOMS - MIN_ROOMS + 1) + MIN_ROOMS
	var rooms = []
	
	for i in range(num_rooms):
		var w = 4 + randi() % 5
		var h = 4 + randi() % 5
		var x = 1 + randi() % (MAP_WIDTH - w - 2)
		var y = 1 + randi() % (MAP_HEIGHT - h - 2)
		
		var can_place = true
		for ry in range(y - 1, y + h + 1):
			for rx in range(x - 1, x + w + 1):
				if rx >= 0 and rx < MAP_WIDTH and ry >= 0 and ry < MAP_HEIGHT:
					if grid[ry][rx] != TileType.EMPTY:
						can_place = false
		
		if can_place:
			for ry in range(y, y + h):
				for rx in range(x, x + w):
					if ry == y or ry == y + h - 1 or rx == x or rx == x + w - 1:
						grid[ry][rx] = TileType.WALL
					else:
						grid[ry][rx] = TileType.FLOOR
			rooms.append(Rect2(x, y, w, h))
	
	# Connect rooms with corridors
	if rooms.size() > 1:
		for i in range(rooms.size() - 1):
			var r1 = rooms[i]
			var r2 = rooms[i + 1]
			var cx = int((r1.position.x + r1.size.x / 2 + r2.position.x + r2.size.x / 2) / 2)
			var cy = int((r1.position.y + r1.size.y / 2 + r2.position.y + r2.size.y / 2) / 2)
			
			var x1 = int(r1.position.x + r1.size.x / 2)
			var y1 = int(r1.position.y + r1.size.y / 2)
			var x2 = int(r2.position.x + r2.size.x / 2)
			var y2 = int(r2.position.y + r2.size.y / 2)
			
			# Horizontal then vertical corridor
			for x in range(min(x1, x2), max(x1, x2) + 1):
				if y1 >= 0 and y1 < MAP_HEIGHT and x >= 0 and x < MAP_WIDTH:
					if grid[y1][x] == TileType.EMPTY:
						grid[y1][x] = TileType.FLOOR
			for y in range(min(y1, y2), max(y1, y2) + 1):
				if y >= 0 and y < MAP_HEIGHT and x2 >= 0 and x2 < MAP_WIDTH:
					if grid[y][x2] == TileType.EMPTY:
						grid[y][x2] = TileType.FLOOR
	
	return grid

func find_farthest_room_center(grid: Array) -> Vector2:
	# Find the farthest point from (2,2) for stair placement
	var best_pos = Vector2.ZERO
	var best_dist = 0.0
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if grid[y][x] == TileType.FLOOR:
				var dist = Vector2(x * TILE_SIZE, y * TILE_SIZE).distance_to(Vector2(TILE_SIZE * 4, TILE_SIZE * 4))
				if dist > best_dist:
					best_dist = dist
					best_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	return best_pos

func generate_enemies(floor_num: int, grid: Array) -> Array:
	var num_enemies = 2 + floor_num / 5
	var enemies = []
	var floor_positions = []
	
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if grid[y][x] == TileType.FLOOR:
				floor_positions.append(Vector2(x * TILE_SIZE, y * TILE_SIZE))
	
	floor_positions.shuffle()
	
	for i in range(min(num_enemies, floor_positions.size())):
		var enemy_type = get_enemy_type_for_floor(floor_num)
		enemies.append({
			"type": enemy_type,
			"hp": 20 + floor_num * 5,
			"atk": 3 + floor_num * 2,
			"def": 1 + floor_num / 5,
			"speed": 60 + floor_num * 3,
			"detection": 120 + floor_num * 5,
			"position": floor_positions[i]
		})
	
	return enemies

func generate_civilians(floor_num: int, grid: Array) -> Array:
	var num_civs = 1 + (floor_num / 8)
	var civilians = []
	var floor_positions = []
	
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if grid[y][x] == TileType.FLOOR:
				floor_positions.append(Vector2(x * TILE_SIZE, y * TILE_SIZE))
	
	floor_positions.shuffle()
	
	var civ_types = ["chai_wala", "newspaper_boy", "teacher", "nurse", "auto_driver"]
	
	for i in range(min(num_civs, floor_positions.size())):
		civilians.append({
			"type": civ_types[i % civ_types.size()],
			"position": floor_positions[i]
		})
	
	return civilians

func generate_items(floor_num: int, grid: Array) -> Array:
	var items = []
	var floor_positions = []
	
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if grid[y][x] == TileType.FLOOR:
				floor_positions.append(Vector2(x * TILE_SIZE, y * TILE_SIZE))
	
	floor_positions.shuffle()
	
	if floor_positions.size() > 0:
		items.append({
			"item_type": "health",
			"value": 30.0,
			"position": floor_positions[0]
		})
	
	return items

func get_enemy_type_for_floor(floor_num: int) -> int:
	if floor_num <= 5:
		return [0, 1, 2][randi() % 3]  # StreetThug, Pickpocket, DrunkBrawler
	elif floor_num <= 10:
		return [3, 4, 5][randi() % 3]  # Smuggler, Counterfeiter, GoonSquad
	elif floor_num <= 15:
		return [6, 7][randi() % 2]  # ArmedGuard, SnifferDog
	elif floor_num <= 20:
		return [8, 9][randi() % 2]  # Hitman, CorruptOfficial
	else:
		return [5, 6, 8][randi() % 3]  # Elite mix

func create_tilemap(grid: Array):
	# For now, return a placeholder — actual TileMap node creation
	# This will be set up properly when we have actual tile assets
	return null
