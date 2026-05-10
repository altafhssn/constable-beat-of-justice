extends Node

@onready var input_handler = $InputHandler

# Game state
var current_floor: int = 1
var player: Player = null
var enemies: Array = []
var civilians: Array = []
var items: Array = []

func _ready():
	start_game()

func start_game():
	# Create player
	player = Player.new()
	player.name = "Player"
	add_child(player)
	
	# Generate first floor
	generate_floor(current_floor)

func generate_floor(floor_num: int):
	# Clear previous floor
	for child in get_children():
		if child is Enemy or child is Civilian or child is FloorItem:
			child.queue_free()
	
	# Generate floor based on theme
	var floor_gen = FloorGenerator.new()
	var floor_data = floor_gen.generate(floor_num)
	
	# Instantiate floor tiles
	var tilemap = floor_data.tilemap
	tilemap.name = "TileMap"
	add_child(tilemap)
	
	# Position player at entrance
	player.position = floor_data.player_start
	
	# Spawn enemies
	for enemy_data in floor_data.enemies:
		var enemy = Enemy.new()
		enemy.init(enemy_data)
		add_child(enemy)
		enemies.append(enemy)
	
	# Spawn civilians
	for civ_data in floor_data.civilians:
		var civ = Civilian.new()
		civ.init(civ_data)
		add_child(civ)
		civilians.append(civ)
	
	# Spawn items (weapons, upgrades)
	for item_data in floor_data.items:
		var item = FloorItem.new()
		item.init(item_data)
		add_child(item)
		items.append(item)

func _process(delta):
	if not player or player.is_dead:
		return
	
	# Update enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.update(player, delta)
	
	# Check collisions
	check_interactions()

func check_interactions():
	# Check player attack hits
	if player.is_attacking:
		for enemy in enemies:
			if is_instance_valid(enemy) and player.global_position.distance_to(enemy.global_position) < 32:
				enemy.take_damage(player.get_attack_damage())
		
		# Check rescue
		for civ in civilians:
			if is_instance_valid(civ) and not civ.is_rescued and player.global_position.distance_to(civ.global_position) < 24:
				civ.rescue()
				player.on_rescue(civ)
	
	# Check item pickup
	for item in items:
		if is_instance_valid(item) and player.global_position.distance_to(item.global_position) < 20:
			player.pickup_item(item)
			item.queue_free()
