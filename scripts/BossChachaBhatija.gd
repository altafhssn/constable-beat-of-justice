class_name BossChachaBhatija
extends CharacterBody2D

## CHACHA BHATIJA — Duo Boss Fight (Floor 5)
## Phase 1: Chacha advances slowly + Bhatija throws firecrackers
## Phase 2: One enrages when other takes 5 hits
## Phase 3: Both enrage — wide sweeps + taser rush

enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

# Boss stats
var combined_max_hp: float = 200.0
var chacha_hp: float = 100.0
var bhatija_hp: float = 100.0
var current_phase: BossPhase = BossPhase.PHASE_1
var hit_count_since_phase_change: int = 0
var is_enraged: bool = false
var is_dead: bool = false
var victory_emitted: bool = false

# References
var chacha: CharacterBody2D
var bhatija: CharacterBody2D
var player_ref: Node2D
var main_ref: Node

# Attack timers
var chacha_attack_timer: float = 0.0
var bhatija_attack_timer: float = 0.0
var firecracker_cooldown: float = 0.0
var taser_cooldown: float = 0.0

# Signals
signal boss_phase_changed(phase: int)
signal boss_defeated()

func _init():
	collision_layer = 0
	collision_mask = 0

func start_boss(player: Node2D, main: Node, pos: Vector2):
	player_ref = player
	main_ref = main
	global_position = pos
	
	spawn_chacha()
	spawn_bhatija()
	
	main_ref.shake_camera(0.3, 8.0)
	print("BOSS FIGHT: Chacha Bhatija!")

func spawn_chacha():
	chacha = CharacterBody2D.new()
	chacha.name = "Chacha"
	
	# Sprite
	var spr = Sprite2D.new()
	spr.texture = preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Walk_1_strip4.png")
	spr.scale = Vector2(2.0, 2.0)
	spr.centered = true
	chacha.add_child(spr)
	
	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	chacha.add_child(col)
	
	chacha.collision_layer = 2
	chacha.collision_mask = 1
	chacha.position = Vector2(-40, 0)
	chacha.set_meta("boss_part", "chacha")
	add_child(chacha)

func spawn_bhatija():
	bhatija = CharacterBody2D.new()
	bhatija.name = "Bhatija"
	
	var spr = Sprite2D.new()
	spr.texture = preload("res://assets/characters/brawler/SMS BRAWLER Character Renegade FREE FILES/Renegade_Run_1_strip4.png")
	spr.scale = Vector2(1.5, 1.5)
	spr.centered = true
	bhatija.add_child(spr)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	bhatija.add_child(col)
	
	bhatija.collision_layer = 2
	bhatija.collision_mask = 1
	bhatija.position = Vector2(40, 0)
	bhatija.set_meta("boss_part", "bhatija")
	add_child(bhatija)

func _process(delta):
	if is_dead or not is_instance_valid(player_ref):
		return
	
	update_phase()
	update_timers(delta)
	ai_chacha(delta)
	ai_bhatija(delta)
	check_victory()

func update_phase():
	var combined_hp = chacha_hp + bhatija_hp
	var combined_ratio = combined_hp / combined_max_hp
	
	var new_phase = current_phase
	if combined_ratio <= 0.3:
		new_phase = BossPhase.PHASE_3
	elif combined_ratio <= 0.6 or hit_count_since_phase_change >= 5:
		new_phase = BossPhase.PHASE_2
	
	if new_phase != current_phase:
		current_phase = new_phase
		hit_count_since_phase_change = 0
		is_enraged = current_phase == BossPhase.PHASE_3 or \
			(current_phase == BossPhase.PHASE_2 and hit_count_on_one() >= 3)
		boss_phase_changed.emit(current_phase)
		if main_ref:
			main_ref.shake_camera(0.4, 12.0)
			if current_phase == BossPhase.PHASE_3:
				main_ref.shake_camera(0.6, 16.0)

func hit_count_on_one() -> int:
	return hit_count_since_phase_change

func update_timers(delta):
	chacha_attack_timer -= delta
	bhatija_attack_timer -= delta
	firecracker_cooldown -= delta
	taser_cooldown -= delta

func ai_chacha(delta):
	if not is_instance_valid(chacha) or not is_instance_valid(player_ref):
		return
	
	var dist = global_position.distance_to(player_ref.global_position)
	var dir = (player_ref.global_position - global_position).normalized()
	
	# Chacha slowly advances
	var speed = 40.0
	if is_enraged:
		speed = 80.0
	if current_phase == BossPhase.PHASE_3:
		speed = 100.0
	
	chacha.position += dir * speed * delta
	
	# Wide sweep attack
	if chacha_attack_timer <= 0 and dist < 60:
		perform_chacha_sweep()
		chacha_attack_timer = 1.5 if not is_enraged else 0.8

func perform_chacha_sweep():
	if not is_instance_valid(player_ref) or not is_instance_valid(chacha):
		return
	
	var dir = (player_ref.global_position - chacha.global_position).normalized()
	var damage = 10.0
	var range_mult = 1.0
	
	if is_enraged:
		damage = 15.0
		range_mult = 1.5
	if current_phase == BossPhase.PHASE_3:
		damage = 20.0
		range_mult = 2.0
	
	# Wide arc sweep — check if player is in range
	var hit_distance = chacha.global_position.distance_to(player_ref.global_position)
	if hit_distance < 50 * range_mult:
		player_ref.take_damage(damage)
		if main_ref:
			main_ref.shake_camera(0.2, 8.0)
			main_ref.show_damage_number(-damage, player_ref.global_position + Vector2(0, -16))
	
	if main_ref:
		# Visual sweep arc
		var arc = ColorRect.new()
		arc.size = Vector2(80 * range_mult, 20)
		arc.color = Color(1, 0.5, 0.2, 0.4)
		arc.pivot_offset = Vector2(0, 10)
		arc.position = chacha.global_position + dir * 20
		arc.rotation = atan2(dir.y, dir.x)
		main_ref.add_child(arc)
		var tween = main_ref.create_tween()
		tween.tween_property(arc, "color:a", 0.0, 0.2)
		tween.tween_callback(arc.queue_free)

func ai_bhatija(delta):
	if not is_instance_valid(bhatija) or not is_instance_valid(player_ref):
		return
	
	var dir = (player_ref.global_position - bhatija.global_position).normalized()
	
	# Bhatija zips around — fast movement
	var speed = 120.0
	if is_enraged:
		speed = 180.0
	if current_phase == BossPhase.PHASE_3:
		speed = 250.0
	
	bhatija.position += dir * speed * delta
	
	# Flip sprite
	var spr = bhatija.get_child(0)
	if spr and spr is Sprite2D:
		spr.flip_h = dir.x < 0
	
	# Phase 1: Firecracker throws
	if current_phase == BossPhase.PHASE_1 and firecracker_cooldown <= 0:
		throw_firecracker()
		firecracker_cooldown = 2.0
	
	# Phase 2: Triple firecrackers
	if current_phase == BossPhase.PHASE_2 and firecracker_cooldown <= 0:
		throw_firecracker()
		await get_tree().create_timer(0.2).timeout
		throw_firecracker()
		await get_tree().create_timer(0.2).timeout
		throw_firecracker()
		firecracker_cooldown = 3.0
	
	# Phase 3: Taser rush instead of firecrackers
	if current_phase == BossPhase.PHASE_3 and taser_cooldown <= 0:
		taser_rush()
		taser_cooldown = 2.5

func throw_firecracker():
	if not is_instance_valid(bhatija) or not is_instance_valid(player_ref) or not is_instance_valid(main_ref):
		return
	
	var dir = (player_ref.global_position - bhatija.global_position).normalized()
	
	# Create firecracker projectile
	var cracker = ColorRect.new()
	cracker.size = Vector2(6, 6)
	cracker.color = Color(1, 0.8, 0.1, 0.9)
	cracker.position = bhatija.global_position
	main_ref.add_child(cracker)
	
	# Animate projectile
	var target_pos = player_ref.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var tween = main_ref.create_tween()
	tween.tween_property(cracker, "position", target_pos, 0.6)
	tween.parallel().tween_property(cracker, "color", Color(1, 0.3, 0.1, 0), 0.6)
	tween.tween_callback(func():
		# Check hit
		if is_instance_valid(cracker) and is_instance_valid(player_ref):
			if cracker.global_position.distance_to(player_ref.global_position) < 30:
				player_ref.take_damage(5.0)
				if main_ref:
					main_ref.shake_camera(0.1, 4.0)
					main_ref.spawn_effect("hit", player_ref.global_position)
			cracker.queue_free()
	)

func taser_rush():
	if not is_instance_valid(bhatija) or not is_instance_valid(player_ref) or not is_instance_valid(main_ref):
		return
	
	# Bhatija charges at player — stun on contact
	var dir = (player_ref.global_position - bhatija.global_position).normalized()
	
	# Visual: red flash
	var flash = ColorRect.new()
	flash.size = Vector2(24, 24)
	flash.color = Color(1, 0, 0, 0.6)
	flash.position = bhatija.global_position - Vector2(12, 12)
	main_ref.add_child(flash)
	
	# Rush toward player
	var rush_target = player_ref.global_position
	var tween = main_ref.create_tween()
	tween.tween_property(bhatija, "position", rush_target - bhatija.global_position, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(flash):
			if is_instance_valid(player_ref) and bhatija.global_position.distance_to(player_ref.global_position) < 40:
				player_ref.take_damage(8.0)
				# Taser stun — slow player briefly
				player_ref.move_speed *= 0.3
				await get_tree().create_timer(1.5).timeout
				if is_instance_valid(player_ref):
					player_ref.move_speed *= 3.33
			flash.queue_free()
	)

func take_chacha_damage(amount: float):
	if is_dead:
		return
	var actual = max(1, amount - 2.0)
	chacha_hp -= actual
	hit_count_since_phase_change += 1
	if main_ref:
		main_ref.shake_camera(0.1, 3.0)
	if chacha_hp <= 0:
		chacha_hp = 0
		if is_instance_valid(chacha):
			chacha.modulate = Color(0.5, 0, 0, 0.5)
			chacha.queue_free()
	check_victory()

func take_bhatija_damage(amount: float):
	if is_dead:
		return
	var actual = max(1, amount - 1.0)
	bhatija_hp -= actual
	hit_count_since_phase_change += 1
	if main_ref:
		main_ref.shake_camera(0.15, 5.0)
	if bhatija_hp <= 0:
		bhatija_hp = 0
		if is_instance_valid(bhatija):
			bhatija.modulate = Color(0.5, 0, 0, 0.5)
			bhatija.queue_free()
	check_victory()

func check_victory():
	if is_dead or victory_emitted:
		return
	if chacha_hp <= 0 and bhatija_hp <= 0:
		is_dead = true
		victory_emitted = true
		boss_defeated.emit()
		if main_ref:
			main_ref.shake_camera(0.5, 20.0)
			# Reward: spawn SHIELD weapon
			var reward = FloorItem.new()
			reward.init({
				"item_type": "weapon",
				"weapon_type": Player.WeaponType.SHIELD,
				"position": global_position
			})
			main_ref.add_child(reward)
			main_ref.items.append(reward)
		print("BOSS DEFEATED: Chacha Bhatija!")

func get_combined_hp_ratio() -> float:
	var total = chacha_hp + bhatija_hp
	return max(0.0, total / combined_max_hp)

func cleanup():
	if is_instance_valid(chacha):
		chacha.queue_free()
	if is_instance_valid(bhatija):
		bhatija.queue_free()
	queue_free()
