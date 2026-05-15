class_name Enemy
extends CharacterBody2D

enum EnemyType {
	STREET_THUG, PICKPOCKET, DRUNK_BRAWLER,
	SMUGGLER, COUNTERFEITER, GOON_SQUAD,
	ARMED_GUARD, SNIFFER_DOG, HITMAN, CORRUPT_OFFICIAL
}

# Stats
var enemy_type: EnemyType = EnemyType.STREET_THUG
var max_hp: float = 30.0
var current_hp: float = 30.0
var atk: float = 5.0
var def: float = 1.0
var move_speed: float = 80.0
var detection_range: float = 150.0
var attack_range: float = 20.0

# AI state
enum AIState { PATROL, CHASE, ATTACK, STUNNED, DEAD }
var ai_state: AIState = AIState.PATROL
var patrol_points: Array = []
var current_patrol_target: int = 0
var chase_target: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0
var stun_timer: float = 0.0
var is_dead: bool = false

var was_hit_this_attack: bool = false

func _init():
	collision_layer = 1
	collision_mask = 3  # collide with layer 1 (player) and layer 2 (walls)
var player_ref: Player = null

# Sprite
var sprite_node: Sprite2D
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect

func _ready():
	# Create sprite
	sprite_node = Sprite2D.new()
	sprite_node.centered = true
	sprite_node.scale = Vector2(1.5, 1.5)
	add_child(sprite_node)
	
	# HP bar background (dark) — hidden until damaged
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(32, 4)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bar_bg.position = Vector2(-16, -28)
	hp_bar_bg.pivot_offset = Vector2(0, 0)
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)
	
	# HP bar fill (green) — hidden until damaged
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(32, 4)
	hp_bar_fill.color = Color(0.2, 0.9, 0.2, 0.9)
	hp_bar_fill.position = Vector2(-16, -28)
	hp_bar_fill.pivot_offset = Vector2(0, 0)
	hp_bar_fill.visible = false
	add_child(hp_bar_fill)
	
	# Collision shape
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	col.shape = shape
	add_child(col)
	
	collision_layer = 2
	collision_mask = 1

func init(data: Dictionary):
	enemy_type = data.get("type", EnemyType.STREET_THUG)
	max_hp = data.get("hp", 30.0)
	current_hp = max_hp
	atk = data.get("atk", 5.0)
	def = data.get("def", 1.0)
	move_speed = data.get("speed", 80.0)
	detection_range = data.get("detection", 150.0)
	position = data.get("position", Vector2.ZERO)
	
	# Set sprite
	if sprite_node:
		sprite_node.texture = SpriteRegistry.get_enemy_sprite(enemy_type)

func update(player: Player, delta: float):
	if ai_state == AIState.DEAD or is_dead:
		return
	
	player_ref = player
	var dist_to_player = global_position.distance_to(player.global_position)
	
	# Reset hit flag between attacks
	if not player.is_attacking:
		was_hit_this_attack = false
	
	# Update timers
	if attack_cooldown > 0: attack_cooldown -= delta
	if stun_timer > 0: stun_timer -= delta
	
	# State machine
	match ai_state:
		AIState.PATROL:
			if dist_to_player < detection_range:
				ai_state = AIState.CHASE
		
		AIState.CHASE:
			if dist_to_player > detection_range * 1.5:
				ai_state = AIState.PATROL
			elif dist_to_player < attack_range:
				ai_state = AIState.ATTACK
			else:
				chase_target = player.global_position
		
		AIState.ATTACK:
			if dist_to_player > attack_range * 1.5:
				ai_state = AIState.CHASE
			elif attack_cooldown <= 0:
				perform_attack()
		
		AIState.STUNNED:
			if stun_timer <= 0:
				ai_state = AIState.CHASE

func _physics_process(delta):
	if ai_state == AIState.DEAD or ai_state == AIState.STUNNED:
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite_node:
			sprite_node.modulate = Color(1, 1, 1, 0.6) if ai_state == AIState.STUNNED else Color(1, 0, 0, 0.3)
		return
	
	if sprite_node:
		sprite_node.modulate = Color(1, 1, 1, 1.0)
	
	match ai_state:
		AIState.CHASE:
			var dir = (chase_target - global_position).normalized()
			velocity = dir * move_speed
			# Flip sprite based on direction
			if sprite_node and dir.x < 0:
				sprite_node.flip_h = true
			elif sprite_node:
				sprite_node.flip_h = false
		AIState.PATROL:
			# Simple wander
			velocity = Vector2(cos(Time.get_ticks_msec() * 0.001), sin(Time.get_ticks_msec() * 0.0007)) * move_speed * 0.3
			if sprite_node:
				sprite_node.flip_h = velocity.x < 0
		_:
			velocity = Vector2.ZERO
	
	move_and_slide()

func perform_attack():
	if not player_ref:
		return
	player_ref.take_damage(atk)
	attack_cooldown = 1.0

func take_damage(amount: float):
	var actual_damage = max(1, amount - def)
	current_hp -= actual_damage
	
	# Show HP bar
	if hp_bar_bg and hp_bar_fill:
		hp_bar_bg.visible = true
		hp_bar_fill.visible = true
		var ratio = max(0.0, current_hp / max_hp)
		hp_bar_fill.size.x = 32 * ratio
		# Color changes: green → yellow → red
		if ratio > 0.5:
			hp_bar_fill.color = Color(0.2, 0.9, 0.2, 0.9)
		elif ratio > 0.25:
			hp_bar_fill.color = Color(0.9, 0.9, 0.2, 0.9)
		else:
			hp_bar_fill.color = Color(0.9, 0.2, 0.2, 0.9)
	
	# Stun on hit
	ai_state = AIState.STUNNED
	stun_timer = 0.2
	
	if current_hp <= 0:
		die()

func die():
	ai_state = AIState.DEAD
	is_dead = true
	velocity = Vector2.ZERO
	if sprite_node:
		sprite_node.modulate = Color(0.5, 0, 0, 0.5)
	# Remove after death
	await get_tree().create_timer(0.3).timeout
	queue_free()
