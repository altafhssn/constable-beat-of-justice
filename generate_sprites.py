import struct, zlib, os

def rgba(r,g,b,a=255): return (r,g,b,a)

def create_png(filename, pixels, w, h):
    def chunk(ct, data):
        c = ct + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    raw = b''
    for y in range(h):
        raw += b'\x00'  # filter none
        for x in range(w):
            px = pixels[y * w + x]
            raw += bytes(px)
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'wb') as f:
        f.write(header + ihdr + idat + iend)
    print(f"  {filename}: {os.path.getsize(filename)} bytes")

def rect(p, w, h, x, y, w2, h2, c):
    for j in range(y, min(y+h2, h)):
        for i in range(x, min(x+w2, w)):
            p[j * w + i] = c

def empty(w, h):
    return [rgba(0,0,0,0)] * (w * h)

# ─── PLAYER SPRITESHEET (3 frames, 32x48 per frame = 96x48) ───
print("Generating player spritesheet...")
pw, ph = 96, 48
pix = empty(pw, ph)

def draw_player_frame(ox, frame):
    # Shadow
    rect(pix, pw, ph, ox+2, 42, 28, 5, rgba(0,0,0,40))
    # Legs - khaki
    c_leg = rgba(191,166,122)
    if frame == 0:  # idle
        rect(pix, pw, ph, ox+6, 30, 9, 12, c_leg)
        rect(pix, pw, ph, ox+17, 30, 9, 12, c_leg)
    elif frame == 1:  # walk1
        rect(pix, pw, ph, ox+8, 30, 9, 9, c_leg)
        rect(pix, pw, ph, ox+15, 30, 9, 9, c_leg)
        rect(pix, pw, ph, ox+9, 38, 7, 4, c_leg)
        rect(pix, pw, ph, ox+15, 38, 7, 4, c_leg)
    else:  # walk2
        rect(pix, pw, ph, ox+6, 30, 9, 9, c_leg)
        rect(pix, pw, ph, ox+17, 30, 9, 9, c_leg)
        rect(pix, pw, ph, ox+7, 38, 7, 4, c_leg)
        rect(pix, pw, ph, ox+17, 38, 7, 4, c_leg)
    
    # Boots
    rect(pix, pw, ph, ox+5, 42, 11, 4, rgba(51,51,51))
    rect(pix, pw, ph, ox+16, 42, 11, 4, rgba(51,51,51))
    
    # Torso (khaki uniform)
    rect(pix, pw, ph, ox+4, 13, 24, 20, c_leg)
    
    # Belt
    rect(pix, pw, ph, ox+5, 30, 22, 3, rgba(92,58,30))
    rect(pix, pw, ph, ox+13, 30, 6, 3, rgba(192,192,192))  # buckle
    
    # Arms + sleeves
    rect(pix, pw, ph, ox+1, 15, 3, 12, rgba(139,94,60))  # skin
    rect(pix, pw, ph, ox+28, 15, 3, 12, rgba(139,94,60))
    rect(pix, pw, ph, ox+1, 15, 3, 3, c_leg)  # sleeve
    rect(pix, pw, ph, ox+28, 15, 3, 3, c_leg)
    
    # Lathi in right hand
    rect(pix, pw, ph, ox+26, 17, 3, 15, rgba(204,136,68))
    rect(pix, pw, ph, ox+27, 16, 1, 2, rgba(204,136,68))
    
    # Head
    rect(pix, pw, ph, ox+8, 5, 16, 10, rgba(139,94,60))  # skin
    # Eyes
    rect(pix, pw, ph, ox+11, 8, 2, 2, rgba(34,34,34))
    rect(pix, pw, ph, ox+19, 8, 2, 2, rgba(34,34,34))
    # Nose
    rect(pix, pw, ph, ox+15, 10, 2, 2, rgba(90,58,42))
    # Mouth
    rect(pix, pw, ph, ox+13, 12, 6, 1, rgba(90,58,42))
    
    # Peak cap
    rect(pix, pw, ph, ox+6, 0, 20, 5, rgba(92,107,63))  # olive
    rect(pix, pw, ph, ox+4, 3, 24, 2, rgba(58,74,26))  # brim
    # Badge
    rect(pix, pw, ph, ox+14, 1, 4, 3, rgba(212,168,67))
    
    # Collar
    rect(pix, pw, ph, ox+10, 12, 4, 2, rgba(92,107,63))
    rect(pix, pw, ph, ox+18, 12, 4, 2, rgba(92,107,63))

for i in range(3):
    draw_player_frame(i * 32, i)

create_png('assets/sprites/player.png', pix, pw, ph)

# ─── ENEMIES (6 types, 32x32 each = 192x32) ───
print("Generating enemies spritesheet...")
ew, eh = 192, 32
epix = empty(ew, eh)

def mk_enemy(ox, type_name):
    c_skin = rgba(139,94,60)
    if type_name == 'pickpocket':
        rect(epix, ew, eh, ox+4, 4, 20, 12, rgba(136,136,136))  # grey shirt
        rect(epix, ew, eh, ox+4, 16, 20, 8, rgba(100,100,100))  # pants
        rect(epix, ew, eh, ox+8, 6, 2, 1, rgba(34,34,34))  # eyes
        rect(epix, ew, eh, ox+14, 6, 2, 1, rgba(34,34,34))
        rect(epix, ew, eh, ox+6, 0, 16, 5, rgba(80,80,80))  # cap
        rect(epix, ew, eh, ox+5, 5, 14, 7, c_skin)  # face
    elif type_name == 'thug':
        rect(epix, ew, eh, ox+4, 0, 20, 6, rgba(204,51,51))  # bandana
        rect(epix, ew, eh, ox+4, 6, 20, 6, c_skin)  # face
        rect(epix, ew, eh, ox+8, 6, 3, 2, rgba(34,34,34))  # angry eyes
        rect(epix, ew, eh, ox+13, 6, 3, 2, rgba(34,34,34))
        rect(epix, ew, eh, ox+2, 12, 24, 10, rgba(68,68,68))  # vest
        rect(epix, ew, eh, ox+0, 12, 2, 8, c_skin)  # arms
        rect(epix, ew, eh, ox+26, 12, 2, 8, c_skin)
    elif type_name == 'smuggler':
        rect(epix, ew, eh, ox+5, 0, 18, 10, c_skin)  # face
        rect(epix, ew, eh, ox+8, 2, 2, 1, rgba(34,34,34))  # eyes
        rect(epix, ew, eh, ox+14, 2, 2, 1, rgba(34,34,34))
        rect(epix, ew, eh, ox+6, 4, 16, 4, rgba(153,153,51))  # sunglasses
        rect(epix, ew, eh, ox+2, 10, 24, 12, rgba(166,123,91))  # tan coat
        rect(epix, ew, eh, ox+0, 12, 2, 8, c_skin)  # arms
        rect(epix, ew, eh, ox+26, 12, 2, 8, c_skin)
    elif type_name == 'guard':
        rect(epix, ew, eh, ox+4, 0, 20, 6, rgba(92,107,63))  # beret
        rect(epix, ew, eh, ox+4, 6, 20, 6, c_skin)  # face
        rect(epix, ew, eh, ox+8, 7, 2, 1, rgba(34,34,34))  # eyes
        rect(epix, ew, eh, ox+14, 7, 2, 1, rgba(34,34,34))
        rect(epix, ew, eh, ox+2, 12, 24, 12, rgba(85,107,47))  # olive uniform
        rect(epix, ew, eh, ox+22, 8, 4, 12, rgba(68,68,68))  # rifle
    elif type_name == 'hitman':
        rect(epix, ew, eh, ox+5, 0, 18, 8, c_skin)  # face
        rect(epix, ew, eh, ox+8, 2, 2, 1, rgba(34,34,34))  # eyes
        rect(epix, ew, eh, ox+14, 2, 2, 1, rgba(34,34,34))
        rect(epix, ew, eh, ox+6, 3, 16, 4, rgba(34,34,34))  # shades
        rect(epix, ew, eh, ox+2, 8, 24, 16, rgba(17,17,17))  # black suit
        rect(epix, ew, eh, ox+11, 8, 6, 4, rgba(204,51,51))  # tie
    elif type_name == 'elite':
        rect(epix, ew, eh, ox+4, 0, 20, 5, rgba(139,0,0))  # maroon beret
        rect(epix, ew, eh, ox+4, 5, 20, 7, c_skin)  # face
        rect(epix, ew, eh, ox+8, 6, 2, 1, rgba(34,34,34))  # eyes
        rect(epix, ew, eh, ox+14, 6, 2, 1, rgba(34,34,34))
        rect(epix, ew, eh, ox+2, 12, 24, 12, rgba(47,79,79))  # tactical vest
        rect(epix, ew, eh, ox+2, 12, 3, 8, rgba(68,68,68))  # straps
        rect(epix, ew, eh, ox+23, 12, 3, 8, rgba(68,68,68))

for i, t in enumerate(['pickpocket', 'thug', 'smuggler', 'guard', 'hitman', 'elite']):
    mk_enemy(i * 32, t)

create_png('assets/sprites/enemies.png', epix, ew, eh)

# ─── TILES (5 zones, wall+floor per zone = 10 tiles, 32x32 each = 320x32) ───
print("Generating tileset...")
tw, th = 320, 32
tpix = empty(tw, th)

ZONES = [
    ('basti', rgba(58,48,32), rgba(74,58,42)),
    ('bazaar', rgba(74,40,40), rgba(90,56,48)),
    ('naka', rgba(42,42,48), rgba(58,58,69)),
    ('kothi', rgba(26,26,40), rgba(42,42,58)),
    ('office', rgba(26,10,10), rgba(42,10,10))
]

for zi, (zname, fc, wc) in enumerate(ZONES):
    ox = zi * 64
    # Floor tile
    rect(tpix, tw, th, ox, 0, 32, 32, fc)
    # Noise
    rect(tpix, tw, th, ox+3, 5, 2, 1, rgba(255,255,255,10))
    rect(tpix, tw, th, ox+12, 9, 1, 2, rgba(255,255,255,10))
    rect(tpix, tw, th, ox+22, 3, 2, 1, rgba(255,255,255,10))
    rect(tpix, tw, th, ox+8, 19, 1, 1, rgba(255,255,255,10))
    rect(tpix, tw, th, ox+25, 21, 2, 1, rgba(255,255,255,10))
    # Edge highlights
    rect(tpix, tw, th, ox, 0, 32, 1, rgba(0,0,0,20))
    rect(tpix, tw, th, ox, 0, 1, 32, rgba(0,0,0,20))
    
    # Wall tile
    ox2 = ox + 32
    rect(tpix, tw, th, ox2, 0, 32, 32, wc)
    rect(tpix, tw, th, ox2, 0, 32, 2, rgba(0,0,0,80))  # top shadow
    rect(tpix, tw, th, ox2, 0, 2, 32, rgba(0,0,0,80))  # left shadow
    # Brick lines
    rect(tpix, tw, th, ox2+4, 4, 24, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+2, 8, 28, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+4, 12, 24, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+2, 16, 28, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+4, 20, 24, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+2, 24, 28, 1, rgba(255,255,255,12))
    rect(tpix, tw, th, ox2+4, 28, 24, 1, rgba(255,255,255,12))

create_png('assets/tiles/tileset.png', tpix, tw, th)

# ─── ITEMS (6 types, 16x16 each = 96x16) ───
print("Generating items...")
iw, ih = 96, 16
ipix = empty(iw, ih)

rect(ipix, iw, ih, 0, 4, 3, 10, rgba(204,136,68))  # lathi
rect(ipix, iw, ih, 16, 3, 12, 4, rgba(102,102,102))  # katta
rect(ipix, iw, ih, 14, 5, 16, 4, rgba(102,102,102))
rect(ipix, iw, ih, 33, 2, 8, 2, rgba(255,255,255))  # bandage
rect(ipix, iw, ih, 35, 4, 4, 2, rgba(255,255,255))
rect(ipix, iw, ih, 32, 0, 2, 14, rgba(255,255,255))
rect(ipix, iw, ih, 44, 6, 14, 2, rgba(255,255,255))
rect(ipix, iw, ih, 48, 2, 12, 14, rgba(47,79,79))  # vest
rect(ipix, iw, ih, 64, 2, 4, 12, rgba(170,170,170))  # cuffs
rect(ipix, iw, ih, 72, 2, 4, 12, rgba(170,170,170))
rect(ipix, iw, ih, 67, 7, 6, 2, rgba(170,170,170))
rect(ipix, iw, ih, 82, 0, 12, 4, rgba(192,192,192))  # whistle
rect(ipix, iw, ih, 84, 4, 8, 2, rgba(192,192,192))
rect(ipix, iw, ih, 86, 6, 4, 2, rgba(192,192,192))

create_png('assets/sprites/items.png', ipix, iw, ih)

# ─── CIVILIANS (5 types, 24x32 each = 120x32) ───
print("Generating civilians...")
cw, ch = 120, 32
cpix = empty(cw, ch)

def mk_civ(ox, ctype):
    c_skin = rgba(139,94,60)
    # Legs
    rect(cpix, cw, ch, ox+5, 20, 7, 10, rgba(68,68,68))
    rect(cpix, cw, ch, ox+12, 20, 7, 10, rgba(68,68,68))
    # Body
    if ctype == 'chai_wala':
        rect(cpix, cw, ch, ox+3, 8, 18, 14, rgba(255,255,255))  # vest
        rect(cpix, cw, ch, ox+2, 8, 4, 8, c_skin)  # arms
        rect(cpix, cw, ch, ox+18, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+16, 0, 6, 8, rgba(204,136,68))  # kettle
    elif ctype == 'news_boy':
        rect(cpix, cw, ch, ox+3, 8, 18, 14, rgba(136,170,204))  # kurta
        rect(cpix, cw, ch, ox+2, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+18, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+13, 0, 10, 10, rgba(204,187,170))  # bag
    elif ctype == 'teacher':
        rect(cpix, cw, ch, ox+3, 8, 18, 14, rgba(204,119,170))  # saree
        rect(cpix, cw, ch, ox+2, 4, 4, 6, rgba(136,170,204))  # dupatta
        rect(cpix, cw, ch, ox+8, 1, 8, 4, rgba(34,34,34))  # glasses
    elif ctype == 'nurse':
        rect(cpix, cw, ch, ox+3, 8, 18, 14, rgba(255,255,255))  # uniform
        rect(cpix, cw, ch, ox+2, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+18, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+5, 0, 14, 6, rgba(255,136,136))  # cap
    elif ctype == 'auto_driver':
        rect(cpix, cw, ch, ox+3, 8, 18, 14, rgba(204,68,68))  # shirt
        rect(cpix, cw, ch, ox+2, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+18, 8, 4, 8, c_skin)
        rect(cpix, cw, ch, ox+2, 14, 20, 8, rgba(85,170,204))  # lungi
    # Face
    rect(cpix, cw, ch, ox+6, 0, 12, 8, c_skin)
    rect(cpix, cw, ch, ox+8, 2, 2, 1, rgba(34,34,34))
    rect(cpix, cw, ch, ox+14, 2, 2, 1, rgba(34,34,34))

for i, t in enumerate(['chai_wala', 'news_boy', 'teacher', 'nurse', 'auto_driver']):
    mk_civ(i * 24, t)

create_png('assets/sprites/civilians.png', cpix, cw, ch)

# ─── BOSSES (5 types, 48x48 each = 240x48) ───
print("Generating bosses...")
bw, bh = 240, 48
bpix = empty(bw, bh)

def mk_boss(ox, btype):
    c_gold = rgba(212,168,67)
    c_skin = rgba(139,94,60)
    c_red = rgba(204,51,51)
    
    # Shadow
    rect(bpix, bw, bh, ox+2, 44, 44, 4, rgba(0,0,0,60))
    
    if btype == 'gunda_king':
        rect(bpix, bw, bh, ox+8, 22, 32, 20, rgba(51,51,51))  # legs
        rect(bpix, bw, bh, ox+8, 22, 16, 8, c_red)  # dhoti
        rect(bpix, bw, bh, ox+24, 22, 16, 8, c_red)
        rect(bpix, bw, bh, ox+8, 0, 32, 22, c_skin)  # torso
        rect(bpix, bw, bh, ox+12, 4, 3, 2, rgba(34,34,34))  # eyes
        rect(bpix, bw, bh, ox+33, 4, 3, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+10, 14, 28, 5, c_gold)  # chain
        rect(bpix, bw, bh, ox+18, 18, 4, 4, c_gold)  # pendants
        rect(bpix, bw, bh, ox+26, 18, 4, 4, c_gold)
        rect(bpix, bw, bh, ox+4, 0, 8, 4, c_red)  # bandana
        rect(bpix, bw, bh, ox+36, 0, 8, 4, c_red)
        rect(bpix, bw, bh, ox+0, 16, 8, 8, c_skin)  # arms
        rect(bpix, bw, bh, ox+40, 16, 8, 8, c_skin)
        
    elif btype == 'hawala_don':
        rect(bpix, bw, bh, ox+8, 22, 32, 20, rgba(245,245,220))  # kurta
        rect(bpix, bw, bh, ox+10, 2, 28, 20, c_skin)  # face/body
        rect(bpix, bw, bh, ox+15, 6, 2, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+31, 6, 2, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+10, 14, 28, 8, rgba(255,255,255))  # beard
        rect(bpix, bw, bh, ox+36, 4, 4, 3, c_gold)  # earring
        rect(bpix, bw, bh, ox+6, 0, 36, 4, rgba(184,134,11))  # turban
        rect(bpix, bw, bh, ox+4, 2, 40, 3, rgba(184,134,11))
        rect(bpix, bw, bh, ox+22, 0, 4, 6, c_gold)  # jewel
        rect(bpix, bw, bh, ox+2, 16, 6, 8, c_skin)  # arms
        rect(bpix, bw, bh, ox+40, 16, 6, 8, c_skin)
        rect(bpix, bw, bh, ox+38, 20, 4, 4, c_gold)  # rings
        
    elif btype == 'border_lord':
        rect(bpix, bw, bh, ox+6, 2, 36, 24, rgba(85,107,47))  # camo
        rect(bpix, bw, bh, ox+8, 4, 6, 6, rgba(107,142,35))  # camo spots
        rect(bpix, bw, bh, ox+18, 6, 4, 8, rgba(107,142,35))
        rect(bpix, bw, bh, ox+30, 4, 6, 6, rgba(74,93,35))
        rect(bpix, bw, bh, ox+10, 14, 8, 4, rgba(74,93,35))
        rect(bpix, bw, bh, ox+10, 0, 28, 12, c_skin)  # face
        rect(bpix, bw, bh, ox+14, 4, 3, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+31, 4, 3, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+12, 5, 10, 4, rgba(34,34,34))  # aviators
        rect(bpix, bw, bh, ox+26, 5, 10, 4, rgba(34,34,34))
        rect(bpix, bw, bh, ox+14, 10, 20, 2, c_red)  # scar
        rect(bpix, bw, bh, ox+2, 12, 6, 14, c_skin)  # arms
        rect(bpix, bw, bh, ox+40, 12, 6, 14, c_skin)
        rect(bpix, bw, bh, ox+40, 12, 6, 4, rgba(51,51,51))  # gun
        
    elif btype == 'minister':
        rect(bpix, bw, bh, ox+8, 16, 32, 28, rgba(30,58,95))  # blazer
        rect(bpix, bw, bh, ox+12, 16, 24, 12, rgba(255,255,255))  # shirt
        rect(bpix, bw, bh, ox+20, 16, 8, 6, c_red)  # tie
        rect(bpix, bw, bh, ox+12, 2, 24, 16, c_skin)  # face
        rect(bpix, bw, bh, ox+16, 6, 2, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+30, 6, 2, 2, rgba(34,34,34))
        rect(bpix, bw, bh, ox+12, 12, 24, 6, rgba(255,255,255))  # beard
        rect(bpix, bw, bh, ox+20, 22, 3, 3, c_gold)  # buttons
        rect(bpix, bw, bh, ox+20, 28, 3, 3, c_gold)
        rect(bpix, bw, bh, ox+40, 12, 4, 22, rgba(139,69,19))  # cane
        rect(bpix, bw, bh, ox+40, 10, 4, 3, c_gold)  # cane top
        rect(bpix, bw, bh, ox+2, 16, 6, 12, c_skin)  # arm
        
    elif btype == 'commissioner':
        rect(bpix, bw, bh, ox+6, 2, 36, 36, rgba(17,17,17))  # uniform
        rect(bpix, bw, bh, ox+8, 2, 32, 6, rgba(34,34,34))  # shoulders
        rect(bpix, bw, bh, ox+8, 2, 4, 4, c_gold)  # epaulettes
        rect(bpix, bw, bh, ox+36, 2, 4, 4, c_gold)
        rect(bpix, bw, bh, ox+22, 14, 4, 12, c_red)  # sash
        rect(bpix, bw, bh, ox+12, 0, 24, 12, c_skin)  # face
        rect(bpix, bw, bh, ox+10, 0, 28, 3, rgba(34,34,34))  # cap
        rect(bpix, bw, bh, ox+20, 0, 8, 3, c_gold)  # cap badge
        rect(bpix, bw, bh, ox+14, 3, 2, 2, c_red)  # eyes (red tint)
        rect(bpix, bw, bh, ox+32, 3, 2, 2, c_red)
        rect(bpix, bw, bh, ox+14, 8, 20, 3, c_gold)  # medals
        rect(bpix, bw, bh, ox+12, 8, 2, 2, c_gold)
        rect(bpix, bw, bh, ox+34, 8, 2, 2, c_gold)
        rect(bpix, bw, bh, ox+2, 14, 6, 18, c_skin)  # arms
        rect(bpix, bw, bh, ox+40, 14, 6, 18, c_skin)
        rect(bpix, bw, bh, ox+40, 12, 4, 8, rgba(51,51,51))  # pistol

for i, t in enumerate(['gunda_king', 'hawala_don', 'border_lord', 'minister', 'commissioner']):
    mk_boss(i * 48, t)

create_png('assets/sprites/bosses.png', bpix, bw, bh)

print("\n✅ All sprites generated!")

