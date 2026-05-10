extends CharacterBody2D

enum WeaponType { LATHI, PISTOL, SHIELD, DANGAL, TRISHUL, RIFLE }

# Stats
var max_hp: float = 100.0
var current_hp: float = 100.0
var atk: float = 10.0
var def: float = 3.0
var move_speed: float = 200.0
var dash_speed: float = 600.0
var dash_duration: float = 0.15
var dash_cooldown: float = 0.5
var max_dash_charges: int = 3
var dash_charges: int = 3

# Combat state
var is_attacking: bool = false
var is_dashing: bool = false
var is_dead: bool = false
var combo_step: int = 0
var attack_cooldown: float = 0.0
var current_weapon: WeaponType = WeaponType.LATHI
var facing_direction: Vector2 = Vector2.DOWN

# Timers
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var invincibility_timer: float = 0.0

# Rescue stats
var civilians_rescued: int = 0
var temporary_buffs: Dictionary = {}

func _init():
	# Placeholder size for now — will use actual sprite size
	collision_layer = 1
	collision_mask = 2

func _ready():
	pass

func _process(delta):
	if is_dead:
		return
	
	# Timers
	if dash_timer > 0: dash_timer -= delta
	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta
	if invincibility_timer > 0: invincibility_timer -= delta
	if attack_cooldown > 0: attack_cooldown -= delta
	
	is_dashing = dash_timer > 0

func _physics_process(delta):
	if is_dead:
		return
	
	# Get input
	var input_handler = get_node("/root/Main/InputHandler")
	var move_dir = input_handler.move_vector
	
	if is_dashing:
		# Dash movement
		var dash_dir = move_dir if move_dir != Vector2.ZERO else facing_direction
		velocity = dash_dir * dash_speed
	else:
		velocity = move_dir * move_speed
	
	move_and_slide()
	
	# Update facing direction
	if move_dir != Vector2.ZERO and not is_dashing:
		facing_direction = move_dir.normalized()

func attack():
	if attack_cooldown > 0 or is_dead:
		return
	
	is_attacking = true
	combo_step = (combo_step + 1) % 3
	attack_cooldown = 0.3
	
	# Different timing per weapon
	match current_weapon:
		WeaponType.LATHI:
			attack_cooldown = 0.25
		WeaponType.PISTOL:
			attack_cooldown = 0.6
		WeaponType.SHIELD:
			attack_cooldown = 0.4
		WeaponType.DANGAL:
			attack_cooldown = 0.2
		WeaponType.TRISHUL:
			attack_cooldown = 0.35
		WeaponType.RIFLE:
			attack_cooldown = 0.5
	
	# Reset attack flag after a short window
	await get_tree().create_timer(0.1).timeout
	is_attacking = false

func dash():
	if dash_charges <= 0 or dash_timer > 0 or is_dead:
		return
	
	is_dashing = true
	dash_timer = dash_duration
	dash_charges -= 1
	dash_cooldown_timer = dash_cooldown
	
	# Recharge dash after cooldown
	await get_tree().create_timer(dash_cooldown).timeout
	if dash_charges < max_dash_charges:
		dash_charges += 1

func take_damage(amount: float):
	if invincibility_timer > 0 or is_dead:
		return
	
	var actual_damage = max(1, amount - def)
	current_hp -= actual_damage
	invincibility_timer = 0.3
	
	if current_hp <= 0:
		current_hp = 0
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO

func get_attack_damage() -> float:
	var base = atk
	match current_weapon:
		WeaponType.LATHI:
			base *= 1.0
		WeaponType.PISTOL:
			base *= 1.5
		WeaponType.SHIELD:
			base *= 0.8
		WeaponType.DANGAL:
			base *= 1.3
		WeaponType.TRISHUL:
			base *= 0.9
		WeaponType.RIFLE:
			base *= 2.0
	
	# Apply temp buffs
	if temporary_buffs.has("atk_boost"):
		base *= temporary_buffs["atk_boost"]
	
	return base + randi() % 3

func on_rescue(civ):
	civilians_rescued += 1
	# Apply civilian buff
	match civ.civilian_type:
		"chai_wala":
			current_hp = min(max_hp, current_hp + 20)
		"teacher":
			temporary_buffs["atk_boost"] = temporary_buffs.get("atk_boost", 1.0) + 0.5
		"nurse":
			# +1 revive
			pass
		"newspaper_boy":
			# Reveal enemies — handled by Main
			pass
		"auto_driver":
			move_speed *= 1.2

func pickup_item(item):
	match item.item_type:
		"weapon":
			change_weapon(item.weapon_type)
		"health":
			current_hp = min(max_hp, current_hp + item.value)
		"upgrade":
			temporary_buffs["atk_boost"] = temporary_buffs.get("atk_boost", 1.0) + item.value

func change_weapon(weapon: WeaponType):
	current_weapon = weapon
	emit_signal("weapon_changed", weapon)
