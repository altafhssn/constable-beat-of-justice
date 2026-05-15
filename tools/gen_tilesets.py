#!/usr/bin/env python3
"""Generate themed 128x128 pixel art tilesets for Constable: Beat of Justice."""

from PIL import Image, ImageDraw

TILE = 32
COLS = 4
ROWS = 4
SIZE = 128  # TILE * COLS

# Each theme: (name, [FLOOR, WALL, DOOR, STAIRS, BLOOD, DEBRIS, decor1, decor2, ...])
# Colors are (R,G,B) tuples

THEMES = {
    "basti": {
        "floor":     [(139, 90, 43), (120, 78, 37), (100, 65, 30)],
        "wall":      [(100, 70, 30), (85, 60, 25), (70, 48, 18)],
        "door":      [(80, 50, 25), (65, 40, 20), (55, 32, 15)],
        "stairs":    [(180, 150, 80), (165, 135, 70), (150, 120, 60)],
        "blood":     [(120, 20, 20), (100, 15, 15), (80, 10, 10)],
        "debris":    [(90, 75, 40), (75, 60, 30), (60, 48, 20)],
        "decor":     [(200, 180, 100), (50, 120, 50), (40, 100, 40), (180, 80, 40)],
    },
    "bazaar": {
        "floor":     [(200, 160, 80), (185, 145, 72), (170, 130, 65)],
        "wall":      [(180, 60, 40), (160, 50, 35), (140, 40, 28)],
        "door":      [(120, 40, 30), (100, 32, 22), (90, 25, 18)],
        "stairs":    [(220, 190, 100), (200, 170, 85), (185, 155, 75)],
        "blood":     [(140, 25, 25), (115, 18, 18), (90, 12, 12)],
        "debris":    [(160, 120, 50), (140, 100, 40), (120, 85, 30)],
        "decor":     [(60, 150, 60), (200, 60, 60), (200, 200, 60), (60, 60, 200)],
    },
    "naka": {
        "floor":     [(140, 140, 140), (125, 125, 125), (110, 110, 110)],
        "wall":      [(80, 80, 80), (65, 65, 65), (50, 50, 50)],
        "door":      [(60, 55, 50), (50, 45, 42), (42, 38, 35)],
        "stairs":    [(180, 180, 140), (165, 165, 125), (150, 150, 110)],
        "blood":     [(130, 22, 22), (105, 16, 16), (85, 10, 10)],
        "debris":    [(100, 95, 85), (85, 80, 70), (70, 65, 55)],
        "decor":     [(180, 180, 50), (50, 130, 130), (180, 90, 40), (130, 90, 50)],
    },
    "kothi": {
        "floor":     [(210, 200, 180), (195, 185, 165), (180, 170, 150)],
        "wall":      [(170, 150, 130), (155, 135, 115), (140, 120, 100)],
        "door":      [(100, 70, 50), (85, 58, 40), (72, 48, 32)],
        "stairs":    [(200, 180, 120), (185, 165, 105), (170, 150, 90)],
        "blood":     [(140, 18, 18), (115, 12, 12), (90, 8, 8)],
        "debris":    [(160, 145, 120), (140, 125, 100), (120, 105, 85)],
        "decor":     [(200, 160, 60), (60, 100, 160), (160, 60, 100), (220, 210, 180)],
    },
    "commissioner": {
        "floor":     [(50, 50, 80), (45, 45, 72), (38, 38, 65)],
        "wall":      [(30, 30, 50), (25, 25, 42), (18, 18, 35)],
        "door":      [(80, 30, 20), (68, 25, 15), (56, 18, 10)],
        "stairs":    [(100, 90, 50), (90, 80, 42), (80, 70, 35)],
        "blood":     [(150, 15, 15), (125, 10, 10), (100, 5, 5)],
        "debris":    [(60, 55, 70), (50, 45, 58), (40, 35, 45)],
        "decor":     [(180, 20, 20), (20, 80, 180), (140, 140, 30), (100, 100, 120)],
    },
}

def make_tile(draw, x, y, base_colors, pattern="solid"):
    """Draw a 32x32 tile at position (x,y)."""
    cx, cy = x * TILE, y * TILE
    c0, c1, c2 = base_colors[0], base_colors[1], base_colors[2]

    if pattern == "solid":
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=c0)
    elif pattern == "bricks":
        # Brick wall pattern
        for by in range(0, TILE, 4):
            offset = 4 if (by // 4) % 2 == 0 else 0
            for bx in range(-offset, TILE, 8):
                color = c0 if ((by // 4) % 2 == (bx + offset) // 8 % 2) else c1
                px = cx + max(0, bx)
                pw = min(8, TILE - max(0, bx))
                draw.rectangle([px, cy+by, px+pw-1, cy+min(by+3, TILE-1)], fill=color)
        # mortar lines
        for by in range(0, TILE, 4):
            draw.line([cx, cy+by, cx+TILE-1, cy+by], fill=(0,0,0,60), width=1)
        for bx in range(0, TILE, 8):
            draw.line([cx+bx, cy, cx+bx, cy+TILE-1], fill=(0,0,0,40), width=1)
    elif pattern == "floor":
        # Tiled floor with subtle grid
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=c0)
        for gy in range(1, 4):
            draw.line([cx, cy+gy*8, cx+TILE-1, cy+gy*8], fill=c1, width=1)
        for gx in range(1, 4):
            draw.line([cx+gx*8, cy, cx+gx*8, cy+TILE-1], fill=c1, width=1)
        # Noise dots
        import random
        random.seed(hash(f"{cx}_{cy}") % 100000)
        for _ in range(8):
            nx = cx + random.randint(2, TILE-3)
            ny = cy + random.randint(2, TILE-3)
            draw.point((nx, ny), fill=c2)
    elif pattern == "stairs":
        # Stair steps
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=c0)
        for s in range(1, 6):
            sy = cy + s * 5
            draw.line([cx, sy, cx+TILE-1, sy], fill=c1, width=2)
            draw.line([cx+s*5, cy, cx+s*5, cy+TILE-1], fill=c2, width=2)
    elif pattern == "blood":
        # Blood splatter
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=(0,0,0,0))
        import random
        random.seed(hash(f"blood_{cx}_{cy}") % 100000)
        # Main splatter
        bx, by = cx + 16, cy + 16
        for _ in range(30):
            dist = random.randint(1, 14)
            angle = random.random() * 6.28
            spx = int(bx + dist * 0.7 * random.random() * (1 if random.random() > 0.5 else -1))
            spy = int(by + dist * 0.7 * random.random() * (1 if random.random() > 0.5 else -1))
            r = random.randint(2, 5)
            draw.ellipse([spx-r, spy-r, spx+r, spy+r], fill=c0)
        for _ in range(15):
            spx = cx + random.randint(4, 28)
            spy = cy + random.randint(4, 28)
            r = random.randint(1, 3)
            draw.ellipse([spx-r, spy-r, spx+r, spy+r], fill=c1)
    elif pattern == "debris":
        # Cracked/rock rubble
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=c0)
        import random
        random.seed(hash(f"debris_{cx}_{cy}") % 100000)
        for _ in range(6):
            rx = cx + random.randint(2, 24)
            ry = cy + random.randint(2, 24)
            rw = random.randint(3, 8)
            rh = random.randint(2, 5)
            draw.ellipse([rx, ry, rx+rw, ry+rh], fill=c1)
            draw.ellipse([rx+1, ry+1, rx+rw-1, ry+rh-1], fill=c2)
    elif pattern == "decor":
        # Decorative tile (varies per theme)
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=c0)
        import random
        random.seed(hash(f"decor_{cx}_{cy}") % 100000)
        for _ in range(5):
            dx = cx + random.randint(4, 24)
            dy = cy + random.randint(4, 24)
            ds = random.randint(2, 6)
            draw.ellipse([dx, dy, dx+ds, dy+ds], fill=c1)
            draw.ellipse([dx+1, dy+1, dx+ds-1, dy+ds-1], fill=c2)
    elif pattern == "door":
        # Door frame
        draw.rectangle([cx+2, cy, cx+TILE-3, cy+TILE-1], fill=c0)
        draw.rectangle([cx+4, cy+2, cx+TILE-5, cy+TILE-3], fill=c1)
        # Door handle
        draw.ellipse([cx+22, cy+TILE//2-2, cx+26, cy+TILE//2+2], fill=c2)
        # Frame outline
        draw.rectangle([cx+2, cy, cx+TILE-3, cy+TILE-1], outline=(0,0,0,80), width=1)
    elif pattern == "empty":
        draw.rectangle([cx, cy, cx+TILE-1, cy+TILE-1], fill=(0,0,0,0))

def generate_theme(name, colors):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0, col 0: FLOOR
    make_tile(draw, 0, 0, colors["floor"], "floor")
    # Row 0, col 1: DOOR
    make_tile(draw, 1, 0, colors["door"], "door")
    # Row 0, col 2: BLOOD
    make_tile(draw, 2, 0, colors["blood"], "blood")
    # Row 0, col 3: spare (floor variant)
    make_tile(draw, 3, 0, colors["floor"], "floor")

    # Row 1, col 0: WALL
    make_tile(draw, 0, 1, colors["wall"], "bricks")
    # Row 1, col 1: STAIRS
    make_tile(draw, 1, 1, colors["stairs"], "stairs")
    # Row 1, col 2: DEBRIS
    make_tile(draw, 2, 1, colors["debris"], "debris")
    # Row 1, col 3: spare (wall variant)
    make_tile(draw, 3, 1, colors["wall"], "bricks")

    # Rows 2-3: decorative / variations
    for r in range(2, 4):
        for c in range(4):
            idx = (r - 2) * 4 + c
            color = colors["decor"]
            c0 = color[idx % len(color)]
            rest = list(color)
            rest[0] = c0
            make_tile(draw, c, r, rest, "decor")

    path = f"/home/altaf/workspace/constable-beat-of-justice/assets/tilesets/{name}.png"
    img.save(path)
    print(f"Generated {path}  {img.size}")

def main():
    for name, colors in THEMES.items():
        generate_theme(name, colors)
    print("Done!")

if __name__ == "__main__":
    main()
