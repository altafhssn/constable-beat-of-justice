class_name Player
extends CharacterBody2D

signal acquired_damage(damage: float, position: Vector2)
signal health_changed(hp: float, max_hp: float)

enum WeaponType { LATHI, PISTOL, SHIELD, DANGAL, TRISHUL, RIFLE }

const WEAPON_RANGES = {
	WeaponType.LATHI: 36.0,
	WeaponType.PISTOL: 60.0,
	WeaponType.SHIELD: 30.0,
	WeaponType.DANGAL: 24.0,
	WeaponType.TRISHUL: 44.0,
	WeaponType.RIFLE: 72.0,
}

const COMBO_MULTIPLIER = [1.0, 1.2, 1.5]

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
var attack_active_window: float = 0.0
var current_weapon: WeaponType = WeaponType.LATHI
var facing_direction: Vector2 = Vector2.DOWN
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength: float = 0.0

# Timers
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var invincibility_timer: float = 0.0

# Rescue stats
var civilians_rescued: int = 0
var total_gold: int = 0
var temporary_buffs: Dictionary = {}

# Gold stat for floors
var xp: float = 0.0
var xp_to_next: float = 50.0
var level: int = 1

# Sprite rendering
var sprite_node: Sprite2D
var weapon_sprite: Sprite2D
var weapon_offset: float = 12.0

func _init():
	collision_layer = 1
	collision_mask = 2

func _ready():
	sprite_node = Sprite2D.new()
	sprite_node.texture = SpriteRegistry.get_sprite("player_stand")
	sprite_node.centered = true
	sprite_node.scale = Vector2(1.5, 1.5)
	add_child(sprite_node)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_lathi")
	weapon_sprite.centered = true
	weapon_sprite.scale = Vector2(1.5, 1.5)
	add_child(weapon_sprite)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var tex_size = sprite_node.texture.get_size() if sprite_node.texture else Vector2(32, 43)
	shape.size = Vector2(20, 28)
	col.shape = shape
	add_child(col)

func _process(delta):
	if is_dead:
		return
	
	if dash_timer > 0: dash_timer -= delta
	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta
	if invincibility_timer > 0: invincibility_timer -= delta
	if attack_cooldown > 0: attack_cooldown -= delta
	if attack_active_window > 0: attack_active_window -= delta
	else: is_attacking = false
	
	# Knockback decay
	if knockback_strength > 0:
		knockback_strength -= delta * 500
		knockback_vector = knockback_vector.lerp(Vector2.ZERO, delta * 10)
	
	is_dashing = dash_timer > 0
	update_sprite()

func _physics_process(delta):
	if is_dead:
		return
	
	var input_handler = get_node("/root/Main/InputHandler")
	var move_dir = input_handler.move_vector
	
	# Apply knockback if active
	if knockback_strength > 0:
		velocity = knockback_vector * knockback_strength + move_dir * move_speed * 0.3
	elif is_dashing:
		var dash_dir = move_dir if move_dir != Vector2.ZERO else facing_direction
		velocity = dash_dir * dash_speed
	else:
		velocity = move_dir * move_speed
	
	move_and_slide()
	
	if move_dir != Vector2.ZERO and not is_dashing:
		facing_direction = move_dir.normalized()

func attack() -> float:
	if attack_cooldown > 0 or is_dead:
		return 0.0
	
	is_attacking = true
	attack_active_window = 0.15
	combo_step = (combo_step + 1) % 3
	attack_cooldown = 0.25
	
	match current_weapon:
		WeaponType.LATHI: attack_cooldown = 0.25
		WeaponType.PISTOL: attack_cooldown = 0.6
		WeaponType.SHIELD: attack_cooldown = 0.4
		WeaponType.DANGAL: attack_cooldown = 0.2
		WeaponType.TRISHUL: attack_cooldown = 0.35
		WeaponType.RIFLE: attack_cooldown = 0.5
	
	var damage = get_attack_damage()
	
	# Spawn hitbox area
	var hitbox_pos = global_position + facing_direction * get_attack_range() * 0.6
	var hitbox_size = get_attack_range() * 0.5
	
	# Spawn attack arc visual
	if is_inside_tree():
		spawn_attack_arc()
	
	# Emit attack for Main to detect hits
	return damage
	
func spawn_attack_arc():
	var arc = ColorRect.new()
	arc.size = Vector2(get_attack_range() * 1.2, 16)
	arc.color = Color(1, 1, 0.6, 0.3)
	arc.pivot_offset = Vector2(0, 8)
	arc.position = global_position + facing_direction * get_attack_range() * 0.3
	# Rotate to face direction
	arc.rotation = atan2(facing_direction.y, facing_direction.x)
	add_child(arc)
	
	var tween = create_tween()
	tween.tween_property(arc, "color:a", 0.0, 0.15)
	tween.parallel().tween_property(arc, "scale", Vector2(1.3, 1.0), 0.15)
	tween.tween_callback(arc.queue_free)

func get_attack_range() -> float:
	return WEAPON_RANGES.get(current_weapon, 32.0)

func get_combo_multiplier() -> float:
	return COMBO_MULTIPLIER[combo_step]

func get_attack_hitbox_center() -> Vector2:
	return global_position + facing_direction * get_attack_range() * 0.5

func get_attack_hitbox_radius() -> float:
	return get_attack_range() * 0.5

func dash():
	if dash_charges <= 0 or dash_timer > 0 or is_dead:
		return
	
	is_dashing = true
	dash_timer = dash_duration
	dash_charges -= 1
	
	await get_tree().create_timer(dash_cooldown).timeout
	if dash_charges < max_dash_charges:
		dash_charges += 1

func take_damage(amount: float):
	if invincibility_timer > 0 or is_dead:
		return
	
	var actual_damage = max(1, amount - def)
	current_hp -= actual_damage
	invincibility_timer = 0.3
	health_changed.emit(current_hp, max_hp)
	
	# Knockback away from attacker
	knockback_strength = 300.0
	knockback_vector = -facing_direction
	
	if current_hp <= 0:
		current_hp = 0
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	if sprite_node:
		sprite_node.modulate = Color(0.5, 0, 0, 1)

func get_attack_damage() -> float:
	var base = atk * get_combo_multiplier()
	match current_weapon:
		WeaponType.LATHI: base *= 1.0
		WeaponType.PISTOL: base *= 1.5
		WeaponType.SHIELD: base *= 0.8
		WeaponType.DANGAL: base *= 1.3
		WeaponType.TRISHUL: base *= 0.9
		WeaponType.RIFLE: base *= 2.0
	
	if temporary_buffs.has("atk_boost"):
		base *= temporary_buffs["atk_boost"]
	
	return base + randi() % 3

func add_gold(amount: int):
	total_gold += amount

func add_xp(amount: float):
	xp += amount
	while xp >= xp_to_next:
		level_up()

func level_up():
	xp -= xp_to_next
	level += 1
	xp_to_next = 50 + level * 20
	max_hp += 10
	current_hp = min(max_hp, current_hp + 20)
	atk += 2
	def += 1

func on_rescue(civ):
	civilians_rescued += 1
	match civ.civilian_type:
		"chai_wala":
			current_hp = min(max_hp, current_hp + 20)
		"teacher":
			temporary_buffs["atk_boost"] = temporary_buffs.get("atk_boost", 1.0) + 0.5
		"nurse":
			pass
		"newspaper_boy":
			pass
		"auto_driver":
			move_speed *= 1.2

func pickup_item(item):
	match item.item_type:
		"weapon":
			if item.weapon_type >= 0 and item.weapon_type < WeaponType.size():
				change_weapon(item.weapon_type as int)
		"health":
			current_hp = min(max_hp, current_hp + item.value)
		"upgrade":
			temporary_buffs["atk_boost"] = temporary_buffs.get("atk_boost", 1.0) + item.value

func update_sprite():
	if not sprite_node:
		return
	
	if is_attacking:
		match current_weapon:
			WeaponType.LATHI: sprite_node.texture = SpriteRegistry.get_sprite("player_hold")
			WeaponType.PISTOL, WeaponType.RIFLE: sprite_node.texture = SpriteRegistry.get_sprite("player_gun")
			_: sprite_node.texture = SpriteRegistry.get_sprite("player_stand")
	elif is_dashing:
		sprite_node.texture = SpriteRegistry.get_sprite("player_reload")
	elif velocity.length() > 10:
		sprite_node.texture = SpriteRegistry.get_sprite("player_hold")
	else:
		sprite_node.texture = SpriteRegistry.get_sprite("player_stand")
	
	if facing_direction.x < 0:
		sprite_node.flip_h = true
		weapon_sprite.flip_h = true
	elif facing_direction.x > 0:
		sprite_node.flip_h = false
		weapon_sprite.flip_h = false
	
	update_weapon_sprite()
	
	if invincibility_timer > 0:
		sprite_node.modulate = Color(1, 1, 1, 0.5 if int(invincibility_timer * 10) % 2 == 0 else 1.0)
	else:
		sprite_node.modulate = Color(1, 1, 1, 1.0)

func update_weapon_sprite():
	if not weapon_sprite: return
	match current_weapon:
		WeaponType.LATHI: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_lathi")
		WeaponType.PISTOL: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_pistol")
		WeaponType.SHIELD: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_knife")
		WeaponType.DANGAL: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_shotgun")
		WeaponType.TRISHUL: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_machinegun")
		WeaponType.RIFLE: weapon_sprite.texture = SpriteRegistry.get_sprite("weapon_shotgun")
	weapon_sprite.position = facing_direction * weapon_offset
	weapon_sprite.visible = is_attacking or velocity.length() > 10
	# Scale weapon sprites to fit
	weapon_sprite.scale = Vector2(1.2, 1.2)

func change_weapon(weapon: int):
	current_weapon = weapon as WeaponType
