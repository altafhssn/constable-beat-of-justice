class_name hud
extends Node2D
# HUD overlay — drawn on top of game. Parent is CanvasLayer.

var game_state = null

func _ready():
	game_state = get_parent().get_parent()

func update():
	queue_redraw()

func _draw():
	if not game_state: return
	var gs = game_state
	var vp = get_viewport_rect()
	var f = ThemeDB.fallback_font
	var fs = ThemeDB.fallback_font_size
	
	draw_rect(Rect2(0, 0, vp.size.x, 64), Color(0, 0, 0, 0.85))
	
	var hp_str = "HP: " + str(gs.player.hp) + "/" + str(gs.player.max_hp)
	draw_string(f, Vector2(8, 18), hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ff6666"))
	var hp_pct = float(gs.player.hp) / gs.player.max_hp
	draw_rect(Rect2(8, 24, 120, 7), Color(0.15, 0.15, 0.15))
	var hpc = Color("#44dd44") if hp_pct > 0.5 else Color("#dddd44") if hp_pct > 0.25 else Color("#ff4444")
	draw_rect(Rect2(8, 24, 120 * hp_pct, 7), hpc)
	
	var xpn = 20 + gs.player.level * 15 + pow(gs.player.level, 1.5) * 2
	var xpp = float(gs.player.xp) / xpn
	draw_rect(Rect2(8, 34, 120, 5), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(8, 34, 120 * xpp, 5), Color("#88ccff"))
	
	var zn = gs.ZONES[gs.get_zone_index(gs.player.floor)].name
	draw_string(f, Vector2(8, 54), "F" + str(gs.player.floor) + "/25 - " + zn, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#99bbdd"))
	
	var rs = gs.get_rank() + "  ATK:" + str(gs.player.atk) + " DEF:" + str(gs.player.def)
	draw_string(f, Vector2(vp.size.x - 220, 18), rs, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#D4A843"))
	draw_string(f, Vector2(vp.size.x - 220, 54), "K:" + str(gs.player.kills) + " C:" + str(gs.player.civilians_rescued), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#aaaaaa"))
	
	var my = vp.size.y - 10
	var ms = max(0, gs.messages.size() - 6)
	for i in range(ms, gs.messages.size()):
		var m = gs.messages[i]
		draw_string(f, Vector2(8, my), m.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, m.color)
		my -= 18
	
	if gs.player.warrants.size() > 0:
		var wy = 80
		draw_string(f, Vector2(8, wy), "Warrants:", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#D4A843"))
		wy += 18
		for i in range(min(gs.player.warrants.size(), 4)):
			draw_string(f, Vector2(16, wy), "- " + gs.player.warrants[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#bbaa77"))
			wy += 16
	
	draw_string(f, Vector2(8, vp.size.y - 10), "WASD:Move  R:Rescue  I:Wait", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#555555"))
