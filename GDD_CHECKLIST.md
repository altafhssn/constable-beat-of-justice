extends Node

# GDD compliance checklist — what's built vs what's planned
# Status: 🔴 Not started  🟡 Partial  ✅ Complete  ⏸️ Skipped for now
#
# ===== PHASE 1: FOUNDATION (Weeks 1-2) =====
# 🟡 Godot 4 project setup          → project.godot created
# 🟡 Player controller              → Player.gd has movement, dash, attack
# 🔴 Tilemap with actual tiles      → Placeholder; needs Image-based TileMap
# 🟡 Basic melee combat             → Lathi combo (3-step)
# 🟡 Simple enemy AI                → Enemy.gd with patrol/chase/attack/stun
# 🔴 Room-to-room transitions       → Not yet
# 🟡 Touch input system             → MobileUI.tscn + InputHandler.gd
#
# ===== PHASE 2: CONTENT (Weeks 3-5) =====
# - 25 floor procedural generation  
# - 10+ enemy types  
# - 5 bosses with 3-phase patterns  
# - Civilian rescue system  
# - Weapon upgrade system (6+ base weapons)  
# - 20+ "Warrant" upgrades (boon equivalents)  
# - Damage numbers, HP bars, HUD  
#
# ===== PHASE 3: META (Weeks 6-7) =====
# - Police Station hub  
# - Meta progression (Seva Points)  
# - Weapon unlocks  
# - Story diary entries  
# - Run history/stats  
#
# ===== PHASE 4: POLISH (Weeks 8-10) =====
# - Full pixel art, animations, particles  
# - SFX, music  
# - Mobile optimization  
# - UI polish  

# Key GDD Requirements:
# ✅ 6 weapons: Lathi, Pistol, Shield, Dangal, Trishul, Rifle
# ✅ Dash roll (3 charges with cooldown)
# ✅ Real-time combat (not turn-based)
# 🟡 10 enemy types (8 coded in enum, stats differ per floor)
# 🟡 5 civilians (Chai Wala, Newspaper Boy, Teacher, Nurse, Auto Driver)
# 🟡 25 floors across 5 themes (Basti/Bazaar/Naka/Kothi/Commissioner)
# 🔴 7 weapon upgrades (Bamboo Reinforced, Tea-Break, etc.)
# 🔴 20 Warrant upgrades (boon equivalents)
# 🔴 5 bosses with 3 phases
# 🔴 Police Station hub
# 🔴 "Police Power" special ability
# 🔴 Rescue gives Seva Points
# 🔴 Story diary system
# 🔴 Minimap
