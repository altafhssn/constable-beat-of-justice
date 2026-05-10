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

var player_ref: Player = null

func init(data: Dictionary):
	enemy_type = data.get("type", EnemyType.STREET_THUG)
	max_hp = data.get("hp", 30.0)
	current_hp = max_hp
	atk = data.get("atk", 5.0)
	def = data.get("def", 1.0)
	move_speed = data.get("speed", 80.0)
	detection_range = data.get("detection", 150.0)
	position = data.get("position", Vector2.ZERO)
	
	# Set up collision
	collision_layer = 2
	collision_mask = 1

func update(player: Player, delta: float):
	if ai_state == AIState.DEAD:
		return
	
	player_ref = player
	var dist_to_player = global_position.distance_to(player.global_position)
	
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
		return
	
	match ai_state:
		AIState.CHASE:
			var dir = (chase_target - global_position).normalized()
			velocity = dir * move_speed
		AIState.PATROL:
			# Simple wander
			velocity = Vector2(cos(Time.get_ticks_msec() * 0.001), sin(Time.get_ticks_msec() * 0.0007)) * move_speed * 0.3
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
	
	# Stun on hit
	ai_state = AIState.STUNNED
	stun_timer = 0.2
	
	if current_hp <= 0:
		die()

func die():
	ai_state = AIState.DEAD
	velocity = Vector2.ZERO
	# Remove after death animation
	await get_tree().create_timer(0.5).timeout
	queue_free()
