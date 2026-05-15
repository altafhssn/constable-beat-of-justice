class_name Main
extends Node

# Preload all type references to ensure class_name is registered
const Player = preload("res://scripts/Player.gd")
const FloorRenderer = preload("res://scripts/FloorRenderer.gd")
const Enemy = preload("res://scripts/Enemy.gd")
const Civilian = preload("res://scripts/Civilian.gd")
const FloorItem = preload("res://scripts/FloorItem.gd")
const FloorGenerator = preload("res://scripts/FloorGenerator.gd")
const SpriteRegistry = preload("res://scripts/SpriteRegistry.gd")

@onready var input_handler = $InputHandler

# Game state
var current_floor: int = 1
var player: Player = null
var floor_renderer: FloorRenderer = null
var camera: Camera2D = null
var hud = null  # CanvasLayer with HUD script
var enemies: Array = []
var civilians: Array = []
var items: Array = []

# Camera room boundary
var current_camera_limits: Rect2 = Rect2()
var camera_transitioning: bool = false
var target_camera_limits: Rect2 = Rect2()
var camera_limit_lerp_speed: float = 6.0

# Room tracking
var current_room_index: int = -1
var visited_rooms: Array = []  # indices of rooms visited

# Screen shake
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Minimap
var minimap: Control = null
var minimap_rooms: Array = []  # room rects in minimap coords
var minimap_player_pos: Vector2 = Vector2.ZERO
var minimap_enemy_positions: Array = []
var minimap_stairs_pos: Vector2 = Vector2.ZERO

# Floor transition overlay
var transition_overlay: ColorRect = null
var transition_label: Label = null
var is_transitioning: bool = false

# Boss fight
var current_boss: BossChachaBhatija = null
var is_boss_floor: bool = false
var boss_arena_walls: Array = []  # Wall tiles that block exits during boss fight

# Demo mode
var demo_complete: bool = false
var waiting_for_restart: bool = false

# UI overlays
var game_over_ui: CanvasLayer = null

func _ready():
	start_game()

func restart_game():
	# Clean up everything
	for child in get_children():
		if child is Enemy or child is Civilian or child is FloorItem or child is BossChachaBhatija:
			child.queue_free()
	if current_boss and is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
	
	# Remove overlays
	if game_over_ui and is_instance_valid(game_over_ui):
		game_over_ui.queue_free()
		game_over_ui = null
	
	demo_complete = false
	current_floor = 1
	enemies.clear()
	civilians.clear()
	items.clear()
	visited_rooms.clear()
	boss_arena_walls.clear()
	
	start_game()

func start_game():
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.zoom = Vector2(1.8, 1.8)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	
	player = Player.new()
	player.name = "Player"
	add_child(player)
	# Camera follows player position manually (Godot 4 approach)
	player.health_changed.connect(_on_player_health_changed)
	
	floor_renderer = FloorRenderer.new()
	floor_renderer.name = "FloorRenderer"
	add_child(floor_renderer)
	move_child(floor_renderer, 0)
	
	# Create HUD
	var hud_scene = preload("res://scenes/HUD.tscn")
	var hud_instance = hud_scene.instantiate()
	add_child(hud_instance)
	hud = hud_instance
	
	# Create minimap
	create_minimap()
	
	# Create floor transition overlay
	create_transition_overlay()
	
	# Connect input signals
	input_handler.action_pressed.connect(_on_input_action)
	
	generate_floor(current_floor)

func create_minimap():
	var minimap_container = CanvasLayer.new()
	minimap_container.name = "MinimapLayer"
	minimap_container.layer = 20
	add_child(minimap_container)
	
	minimap = Control.new()
	minimap.name = "Minimap"
	minimap.position = Vector2(4, 80)
	minimap.size = Vector2(0, 0)
	minimap_container.add_child(minimap)
	minimap.draw.connect(_on_minimap_draw)

func get_floor_theme(floor_num: int) -> int:
	if floor_num <= 5: return 0
	elif floor_num <= 10: return 1
	elif floor_num <= 15: return 2
	elif floor_num <= 20: return 3
	return 4

func generate_floor(floor_num: int):
	# Clear existing boss
	if current_boss:
		current_boss.cleanup()
		current_boss = null
	is_boss_floor = false
	
	for child in get_children():
		if child is Enemy or child is Civilian or child is FloorItem:
			child.queue_free()
	enemies.clear()
	civilians.clear()
	items.clear()
	visited_rooms.clear()
	current_room_index = -1
	
	var floor_gen = FloorGenerator.new()
	var floor_data = floor_gen.generate(floor_num)
	
	var theme = get_floor_theme(floor_num)
	if floor_renderer:
		floor_renderer.build_from_grid(floor_data.grid, theme)
	
	player.position = floor_data.player_start
	player.is_dead = false
	player.velocity = Vector2.ZERO
	
	# Check for boss floor
	if floor_data.get("is_boss_floor", false) and floor_data.get("boss_position", Vector2.ZERO) != Vector2.ZERO:
		is_boss_floor = true
		# Don't spawn normal enemies on boss floors
		spawn_boss(floor_num, floor_data.boss_position)
	else:
		for enemy_data in floor_data.enemies:
			var enemy = Enemy.new()
			enemy.init(enemy_data)
			add_child(enemy)
			enemies.append(enemy)
	
	for civ_data in floor_data.civilians:
		var civ = Civilian.new()
		civ.init(civ_data)
		add_child(civ)
		civilians.append(civ)
	
	for item_data in floor_data.items:
		var item = FloorItem.new()
		item.init(item_data)
		add_child(item)
		items.append(item)
	
	# Transition overlay
	if transition_overlay and transition_overlay.is_inside_tree():
		transition_overlay.queue_free()
	
	# Update HUD and minimap
	if hud and hud.has_method("update_all"):
		hud.update_all()
	
	update_minimap_data()
	reposition_camera_instant()
	
	# Connect enemy signals for minimap
	for e in enemies:
		if is_instance_valid(e):
			e.tree_exited.connect(_on_enemy_dying)

func update_minimap_data():
	if not floor_renderer or not minimap:
		return
	
	# Calculate minimap layout
	var grid_w = 20 if floor_renderer.grid.size() > 0 else 0
	var grid_h = floor_renderer.grid.size() if floor_renderer.grid.size() > 0 else 34
	
	# Scale: minimap fits in ~120px
	var minimap_max_size = 120.0
	var scale = clamp(float(minimap_max_size) / max(grid_w, grid_h), 1.0, 8.0)
	minimap.size = Vector2(grid_w * scale, grid_h * scale)
	
	# Store minimap rooms for drawing
	minimap_rooms.clear()
	for room in floor_renderer.rooms:
		minimap_rooms.append(Rect2(
			room.x * scale, room.y * scale,
			room.w * scale, room.h * scale
		))
	
	minimap.queue_redraw()

func _on_minimap_draw():
	if not floor_renderer or not is_instance_valid(player):
		return
	
	var grid_w = 20
	var grid_h = 34
	var minimap_max_size = 120.0
	var scale = clamp(float(minimap_max_size) / max(grid_w, grid_h), 1.0, 8.0)
	
	# Draw explored rooms only (fog of war)
	var drawn = {}
	for ri in range(floor_renderer.rooms.size()):
		var room = floor_renderer.rooms[ri]
		var is_visible = visited_rooms.has(ri)
		
		var rx = room.x * scale
		var ry = room.y * scale
		var rw = room.w * scale
		var rh = room.h * scale
		
		if is_visible:
			# Room background (dark)
			minimap.draw_rect(Rect2(rx, ry, rw, rh), Color(0.2, 0.2, 0.2, 0.8))
			# Room border
			minimap.draw_rect(Rect2(rx, ry, rw, rh), Color(0.4, 0.4, 0.4, 0.6), false, 1.0)
			
			# Mark all floor/wall tiles inside this room
			for y in range(room.y, room.y + room.h):
				for x in range(room.x, room.x + room.w):
					var key = str(x) + "," + str(y)
					if drawn.has(key):
						continue
					drawn[key] = true
					if y < floor_renderer.grid.size() and x < floor_renderer.grid[y].size():
						var tile = floor_renderer.grid[y][x]
						if tile == 0:  # FLOOR
							minimap.draw_rect(Rect2(x * scale, y * scale, scale, scale), Color(0.35, 0.25, 0.15, 0.6))
						elif tile == 1:  # WALL
							minimap.draw_rect(Rect2(x * scale, y * scale, scale, scale), Color(0.5, 0.3, 0.15, 0.7))
						elif tile == 3:  # STAIRS
							minimap.draw_rect(Rect2(x * scale, y * scale, scale, scale), Color(1.0, 0.8, 0.1, 0.8))
		else:
			# Unexplored room: show as dark fog
			minimap.draw_rect(Rect2(rx, ry, rw, rh), Color(0.05, 0.05, 0.05, 0.9))
	
	# Draw enemies (red dots)
	for e in enemies:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var ep = Vector2(
			(e.position.x / 24.0) * scale,
			(e.position.y / 24.0) * scale
		)
		if ep.x >= 0 and ep.x < minimap.size.x and ep.y >= 0 and ep.y < minimap.size.y:
			minimap.draw_circle(ep, 2.0, Color(1, 0.2, 0.2, 0.9))
	
	# Draw stairs marker
	if floor_renderer:
		for y in range(floor_renderer.grid.size()):
			for x in range(floor_renderer.grid[y].size()):
				if floor_renderer.grid[y][x] == 3:  # STAIRS
					var sp = Vector2(x * scale, y * scale)
					minimap.draw_rect(Rect2(sp.x - 1, sp.y - 1, scale + 2, scale + 2), Color(1, 0.8, 0.1, 0.9), false, 1.5)
					break
	
	# Draw player (bright blue dot)
	var pp = Vector2(
		(player.position.x / 24.0) * scale,
		(player.position.y / 24.0) * scale
	)
	minimap.draw_circle(pp, 3.0, Color(0.3, 0.8, 1.0, 1.0))
	
	# Draw border around minimap
	minimap.draw_rect(Rect2(Vector2.ZERO, minimap.size), Color(0.6, 0.6, 0.6, 0.5), false, 1.0)

func update_minimap():
	if not minimap or not is_instance_valid(player):
		return
	minimap.queue_redraw()

# Update camera to follow player with smooth room transitions
func _process(delta):
	if not is_instance_valid(player) or player.is_dead:
		if is_instance_valid(player) and player.is_dead and not waiting_for_restart and not game_over_ui:
			show_game_over()
		return
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.update(player, delta)
	
	check_combat()
	cleanup_dead()
	
	# Update camera limits based on nearest room
	update_camera_limits(delta)
	
	# Update shake
	if shake_timer > 0:
		shake_timer -= delta
		shake_intensity = lerp(shake_intensity, 0.0, delta * 6.0)
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = lerp(shake_offset, Vector2.ZERO, delta * 10.0)
	
	# Update camera position to follow player (smoothing handles the rest)
	if camera:
		camera.global_position = camera.global_position.lerp(player.global_position + shake_offset, delta * camera.position_smoothing_speed)
	
	# Update minimap every few frames (cheap redraw)
	if Engine.get_process_frames() % 5 == 0:
		update_minimap()
	
	# Update boss HP bar
	if current_boss and not current_boss.is_dead:
		update_boss_hp_bar()
	else:
		if hud and hud.has_method("hide_boss_hp"):
			hud.hide_boss_hp()

func update_camera_limits(delta: float = 0.0):
	if not floor_renderer or not is_instance_valid(player):
		return
	
	var rooms_bounds = floor_renderer.get_room_bounds()
	if rooms_bounds.is_empty():
		return
	
	# Find which room the player is in
	var player_pos = player.global_position
	var new_target = Rect2()
	var found_index = -1
	
	for i in range(rooms_bounds.size()):
		var room_bounds = rooms_bounds[i]
		if room_bounds.has_point(player_pos):
			new_target = room_bounds
			found_index = i
			break
	
	if found_index < 0:
		# Find nearest room
		var min_dist = INF
		for i in range(rooms_bounds.size()):
			var center = rooms_bounds[i].get_center()
			var dist = player_pos.distance_to(center)
			if dist < min_dist:
				min_dist = dist
				new_target = rooms_bounds[i]
				found_index = i
	
	# Track visited rooms
	if found_index >= 0 and found_index != current_room_index:
		current_room_index = found_index
		if not visited_rooms.has(found_index):
			visited_rooms.append(found_index)
	
	if new_target.size.x <= 0 or new_target.size.y <= 0:
		return
	
	# Only recalculate target when room changes
	if target_camera_limits.size.x <= 0 or target_camera_limits.size.y <= 0:
		target_camera_limits = new_target
	
	# Smoothly interpolate camera limits toward target
	if current_camera_limits.position != new_target.position:
		target_camera_limits = new_target
	
	var zoom = camera.zoom
	var viewport_size = get_viewport().get_visible_rect().size
	var half_viewport = viewport_size / zoom / 2.0
	
	# Smoothly lerp camera bounds instead of snapping
	if delta > 0:
		var lerp_factor = min(1.0, delta * camera_limit_lerp_speed)
		current_camera_limits.position = current_camera_limits.position.lerp(
			target_camera_limits.position, lerp_factor)
		current_camera_limits.size = current_camera_limits.size.lerp(
			target_camera_limits.size, lerp_factor)
	else:
		current_camera_limits = target_camera_limits
	
	camera.limit_left = int(current_camera_limits.position.x)
	camera.limit_top = int(current_camera_limits.position.y)
	camera.limit_right = int(current_camera_limits.position.x + current_camera_limits.size.x)
	camera.limit_bottom = int(current_camera_limits.position.y + current_camera_limits.size.y)

func reposition_camera_instant():
	if camera and is_instance_valid(player):
		camera.global_position = player.global_position
		
		# Initialize camera limits for first room
		var rooms_bounds = floor_renderer.get_room_bounds()
		if rooms_bounds.size() > 0:
			var player_pos = player.global_position
			for i in range(rooms_bounds.size()):
				if rooms_bounds[i].has_point(player_pos):
					current_camera_limits = rooms_bounds[i]
					target_camera_limits = rooms_bounds[i]
					current_room_index = i
					visited_rooms.append(i)
					break

func _input(event):
	if not is_instance_valid(player) or player.is_dead:
		# Allow restart via SPACE or tap during game over
		if waiting_for_restart:
			if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
				restart_game()
			elif event is InputEventScreenTouch and event.pressed:
				restart_game()
		return
	
	# Stair interaction
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		check_stair_interaction()

func check_stair_interaction():
	if not is_instance_valid(player) or not floor_renderer or is_transitioning:
		return
	
	# Demo mode: show victory after beating boss on floor 1
	if current_floor == 1 and demo_complete:
		show_demo_complete()
		return
	
	var player_tile_pos = Vector2i(
		int(player.position.x / 24.0),
		int(player.position.y / 24.0)
	)
	
	# Check if player is on stairs tile
	var grid = floor_renderer.grid
	if player_tile_pos.y >= 0 and player_tile_pos.y < grid.size() and \
	   player_tile_pos.x >= 0 and player_tile_pos.x < grid[player_tile_pos.y].size():
		if grid[player_tile_pos.y][player_tile_pos.x] == 3:  # STAIRS
			current_floor += 1
			if current_floor > 25:
				win_game()
			else:
				do_floor_transition(current_floor)

func check_combat():
	if not is_instance_valid(player):
		return
	
	# Attack hit detection
	if player.is_attacking:
		var hit_center = player.get_attack_hitbox_center()
		var hit_radius = player.get_attack_hitbox_radius()
		
		# Check hits on regular enemies
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.is_dead:
				continue
			if hit_center.distance_to(enemy.global_position) < hit_radius:
				if not enemy.was_hit_this_attack:
					enemy.was_hit_this_attack = true
					var damage = player.get_attack_damage()
					enemy.take_damage(damage)
					show_damage_number(damage, enemy.global_position + Vector2(0, -16))
					spawn_effect("hit", enemy.global_position)
					shake_camera(0.1, 3.0)
		
		# Check hits on boss parts
		if current_boss and not current_boss.is_dead and is_instance_valid(current_boss):
			# Check Chacha
			if is_instance_valid(current_boss.chacha):
				if hit_center.distance_to(current_boss.chacha.global_position) < hit_radius:
					if player.is_attacking:  # Only hit once per attack
						var damage = player.get_attack_damage()
						current_boss.take_chacha_damage(damage)
						show_damage_number(damage, current_boss.chacha.global_position + Vector2(0, -20))
						spawn_effect("hit", current_boss.chacha.global_position)
						shake_camera(0.15, 5.0)
			# Check Bhatija
			if is_instance_valid(current_boss.bhatija):
				if hit_center.distance_to(current_boss.bhatija.global_position) < hit_radius:
					if player.is_attacking:
						var damage = player.get_attack_damage()
						current_boss.take_bhatija_damage(damage)
						show_damage_number(damage, current_boss.bhatija.global_position + Vector2(0, -20))
						spawn_effect("hit", current_boss.bhatija.global_position)
						shake_camera(0.15, 5.0)
		
		# Civilian rescue
		for civ in civilians:
			if is_instance_valid(civ) and not civ.is_rescued:
				if hit_center.distance_to(civ.global_position) < hit_radius:
					civ.rescue()
	
	# Enemy attack
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.ai_state == Enemy.AIState.ATTACK:
			if enemy.attack_cooldown <= 0 and player.global_position.distance_to(enemy.global_position) < enemy.attack_range:
				player.take_damage(enemy.atk)
				show_damage_number(-enemy.atk, player.global_position + Vector2(0, -16))
				spawn_effect("hit", player.global_position)
				shake_camera(0.2, 6.0)  # Strong shake on damage taken
				enemy.attack_cooldown = 1.0
	
	# Item pickup
	for item in items:
		if is_instance_valid(item) and player.global_position.distance_to(item.global_position) < 20:
			player.pickup_item(item)
			item.queue_free()
			update_minimap()

func _on_input_action(action, direction: Vector2):
	if not is_instance_valid(player) or player.is_dead:
		return
	
	# Use the enum values from input_handler
	var AT = input_handler.ActionType
	match action:
		AT.ATTACK:
			player.attack()
		AT.DASH:
			player.dash()
		AT.INTERACT:
			check_stair_interaction()

func _on_enemy_dying():
	update_minimap()

func show_damage_number(value: float, pos: Vector2):
	var label = Label.new()
	label.text = str(int(value))
	if value < 0:
		label.modulate = Color(1, 0.3, 0.3, 1.0)
	else:
		label.modulate = Color(1, 1, 0.3, 1.0)
	label.position = pos - Vector2(10, 0)
	label.scale = Vector2(0.8, 0.8)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -24), 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func shake_camera(duration: float = 0.15, intensity: float = 4.0):
	shake_timer = duration
	shake_intensity = intensity

func create_transition_overlay():
	var layer = CanvasLayer.new()
	layer.name = "TransitionLayer"
	layer.layer = 100
	add_child(layer)
	
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.size = get_viewport().get_visible_rect().size
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(transition_overlay)
	
	transition_label = Label.new()
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.3)
	transition_label.size = get_viewport().get_visible_rect().size
	transition_label.add_theme_font_size_override("font_size", 32)
	transition_label.modulate = Color(1, 1, 1, 0)
	layer.add_child(transition_label)

func do_floor_transition(floor_num: int):
	if is_transitioning:
		return
	is_transitioning = true
	player.is_dead = true  # Freeze player during transition
	
	# Floor theme names
	var theme_names = ["BASTI - Slums", "BAZAAR - Market", "NAKA - Checkpost", "KOTHI - Mansion", "COMMISSIONER"]
	var theme_idx = get_floor_theme(floor_num)
	transition_label.text = "Floor " + str(floor_num) + "\n" + theme_names[theme_idx]
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	tween.parallel().tween_property(transition_label, "modulate:a", 1.0, 0.3)
	
	# Generate new floor while black
	tween.tween_callback(func():
		generate_floor(floor_num)
	)
	
	# Fade in
	tween.tween_interval(0.4)
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.4)
	tween.parallel().tween_property(transition_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		is_transitioning = false
		player.is_dead = false
	)

func spawn_boss(floor_num: int, pos: Vector2):
	# Floor 1 + every 5th floor = boss floor
	match floor_num:
		1, 5:
			current_boss = BossChachaBhatija.new()
			current_boss.start_boss(player, self, pos)
			current_boss.boss_phase_changed.connect(_on_boss_phase_changed)
			current_boss.boss_defeated.connect(_on_boss_defeated)
			add_child(current_boss)
			# Lock the boss area (prevent retreat)
			lock_boss_arena()
		_:
			# Future bosses will go here
			pass

func lock_boss_arena():
	# Place temporary wall barriers near player start to prevent retreat
	# These are removed when boss is defeated
	var barrier_positions = [
		Vector2(2 * 24, 2 * 24),  # Near player start
		Vector2(3 * 24, 2 * 24),
		Vector2(4 * 24, 2 * 24),
	]
	for bp in barrier_positions:
		var wall = StaticBody2D.new()
		wall.collision_layer = 2
		wall.collision_mask = 0
		wall.position = bp
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(24, 24)
		col.shape = rect
		wall.add_child(col)
		add_child(wall)
		boss_arena_walls.append(wall)
	# Also add a visual barrier
	for bp in barrier_positions:
		var barrier = ColorRect.new()
		barrier.size = Vector2(24, 24)
		barrier.color = Color(0.8, 0.1, 0.1, 0.5)
		barrier.position = bp
		add_child(barrier)
		boss_arena_walls.append(barrier)
	# Notify player
	print("⚠️ BOSS ARENA — No retreat!")

func update_boss_hp_bar():
	if not hud or not hud.has_method("show_boss_hp"):
		return
	if current_boss and not current_boss.is_dead:
		var ratio = current_boss.get_combined_hp_ratio()
		var name = "Chacha Bhatija"
		hud.show_boss_hp(name, ratio)

func unlock_boss_arena():
	for w in boss_arena_walls:
		if is_instance_valid(w):
			w.queue_free()
	boss_arena_walls.clear()

func _on_boss_phase_changed(phase: int):
	var phase_names = ["PHASE 1", "PHASE 2", "PHASE 3 — ENRAGED!"]
	var pname = phase_names[min(phase, phase_names.size() - 1)]
	print("BOSS PHASE: " + pname)
	# Show phase text
	var label = Label.new()
	label.text = pname
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.25)
	label.size = get_viewport().get_visible_rect().size
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 0.5, 0, 0)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _on_boss_defeated():
	print("🎉 BOSS DEFEATED!")
	is_boss_floor = false
	demo_complete = true
	unlock_boss_arena()
	# Victory shake + celebration
	shake_camera(0.5, 20.0)
	var label = Label.new()
	label.text = "VICTORY!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.2)
	label.size = get_viewport().get_visible_rect().size
	label.add_theme_font_size_override("font_size", 40)
	label.modulate = Color(1, 0.8, 0, 0)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
	
	# Spawn reward
	var reward_position = player.global_position + Vector2(0, -30)
	var reward = FloorItem.new()
	reward.init({
		"item_type": "weapon",
		"weapon_type": Player.WeaponType.SHIELD,
		"position": reward_position
	})
	add_child(reward)
	items.append(reward)

func spawn_effect(effect_name: String, pos: Vector2):
	var spr = Sprite2D.new()
	spr.texture = SpriteRegistry.get_sprite("effect_spark_0")
	spr.centered = true
	spr.position = pos
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)
	
	var tween = create_tween()
	tween.tween_property(spr, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(spr, "modulate:a", 0.0, 0.3)
	tween.tween_callback(spr.queue_free)

func cleanup_dead():
	var i = 0
	while i < enemies.size():
		if not is_instance_valid(enemies[i]) or enemies[i].is_dead:
			enemies.remove_at(i)
		else:
			i += 1

func _on_player_health_changed(hp: float, max_hp: float):
	pass

func win_game():
	print("You win!")
	# TODO: Show win screen

func show_game_over():
	if game_over_ui and is_instance_valid(game_over_ui):
		return
	waiting_for_restart = true
	
	game_over_ui = CanvasLayer.new()
	game_over_ui.name = "GameOverUI"
	game_over_ui.layer = 200
	add_child(game_over_ui)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	game_over_ui.add_child(overlay)
	
	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.3)
	title.size = get_viewport().get_visible_rect().size
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = Color(0.9, 0.2, 0.2, 0)
	game_over_ui.add_child(title)
	
	var prompt = Label.new()
	prompt.text = "Tap or press SPACE to retry"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.55)
	prompt.size = get_viewport().get_visible_rect().size
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.modulate = Color(1, 1, 1, 0)
	game_over_ui.add_child(prompt)
	
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(prompt, "modulate:a", 0.8, 0.4)

func show_demo_complete():
	if game_over_ui and is_instance_valid(game_over_ui):
		return
	waiting_for_restart = true
	
	game_over_ui = CanvasLayer.new()
	game_over_ui.name = "DemoCompleteUI"
	game_over_ui.layer = 200
	add_child(game_over_ui)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	game_over_ui.add_child(overlay)
	
	var title = Label.new()
	title.text = "DEMO COMPLETE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.25)
	title.size = get_viewport().get_visible_rect().size
	title.add_theme_font_size_override("font_size", 44)
	title.modulate = Color(0.3, 0.9, 1.0, 0)
	game_over_ui.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Chacha Bhatija defeated!\nYou cleared the Basti"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.4)
	subtitle.size = get_viewport().get_visible_rect().size
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(1, 1, 1, 0)
	game_over_ui.add_child(subtitle)
	
	var prompt = Label.new()
	prompt.text = "Press SPACE or tap to restart"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, get_viewport().get_visible_rect().size.y * 0.6)
	prompt.size = get_viewport().get_visible_rect().size
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.modulate = Color(1, 1, 1, 0)
	game_over_ui.add_child(prompt)
	
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(subtitle, "modulate:a", 0.8, 0.4)
	tween.parallel().tween_property(prompt, "modulate:a", 0.6, 0.4)
