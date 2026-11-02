## Playable characters and vegetable mutants.
extends RefCounted

const Px = preload("res://tools/px.gd")

# --- Palettes (hue-shifted: shadows lean purple, lights lean yellow) ---------
static var ORANGE := Px.ramp(["5a1f2b", "a33a1f", "dd6a1d", "f79a2e", "ffcb6a"])
static var RED := Px.ramp(["4b1230", "8f1d36", "cf2f3a", "f15b47", "ff9c7a"])
static var GREEN := Px.ramp(["133b35", "1f6b3d", "3ea344", "7fd04b", "c8ee6a"])
static var LEAF := Px.ramp(["0f3030", "1a5a3c", "2f8a43", "5cc04a"])
static var DGREEN := Px.ramp(["0d2a2e", "154a3a", "22703f", "3f9c4a", "7ccc5a"])
static var POTATO := Px.ramp(["3a2430", "6b4333", "9a6b45", "c89a62", "e8c88c"])
static var PURPLE := Px.ramp(["1f1040", "3f1a6b", "6b2c9e", "9c52c8", "d59cf0"])
static var ONION := Px.ramp(["3b1240", "7a2468", "b84a8c", "e088ae", "f8c8d0"])
static var YELLOW := Px.ramp(["7a3c1a", "c27a1e", "ecb22e", "fbdc55", "fff5a8"])
static var CORN := Px.ramp(["8a4a1c", "d0861f", "f4bb30", "ffe066"])
static var BEET := Px.ramp(["230a2e", "4f1044", "8a1656", "c42a6a", "ee6a8e"])
static var GARLIC := Px.ramp(["6b5a78", "a896a8", "d4c8c0", "f0e8d8", "ffffff"])
static var SKIN := Px.ramp(["8a4a3a", "c67a56", "ecae80", "ffd8a8"])
static var SKIN_D := Px.ramp(["3a2030", "6b3a30", "9a5c3e", "c88a5c"])
static var DENIM := Px.ramp(["1c2448", "2c3f78", "3f64a8", "6a94d0"])
static var STRAW := Px.ramp(["7a4a1e", "b8822c", "e6b84a", "fbe48a"])
static var BOOT := Px.ramp(["1f1420", "3f2422", "6b3f2c", "96603c"])
static var WHITE := Px.ramp(["7a84a0", "b4bccc", "e4e8ec", "ffffff"])

const GLOW := Color("b8ff3a")
const GLOW_D := Color("4fd13a")
const DARK := Color("140c1c")
const BLOOD := Color("2a0f1c")


static func legs(c, cx: float, y: float, phase: int, spread: int, r: Array, len: int = 4) -> void:
	var o = [1, 0, -1, 0][phase]
	var o2 = -o
	c.line(cx - spread, y - len, cx - spread - 1 + o, y + (-1 if o > 0 else 0), r[1], 2)
	c.line(cx + spread, y - len, cx + spread + 1 + o2, y + (-1 if o2 > 0 else 0), r[1], 2)


static func eyes(c, cx: float, y: int, gap: int, s: int = 2, brow: bool = true) -> void:
	for side in [-1, 1]:
		var ex: int = int(cx) + side * gap + 1
		c.rect(ex - s / 2, y, s + 1, s + 1, Color("efffb0"))
		c.rect(ex - s / 2 + (1 if s >= 2 else 0), y + (1 if s >= 2 else 0), max(1, s - 1), max(1, s - 1), Color("1d0e1e"))
		c.put(ex - s / 2 + s, y, GLOW)
		if brow:
			for i in s + 2:
				var bx: int = ex - s / 2 - 1 + i
				var by: int = y - 1 + (i if side == 1 else (s + 1 - i)) / 2 - (s / 2)
				c.put(bx, by, DARK)


## Jagged mouth, open controls height.
static func mouth(c, x0: int, y: int, mw: int, open: int) -> void:
	c.rect(x0, y, mw, open + 1, BLOOD)
	for i in mw:
		if i % 2 == 0:
			c.put(x0 + i, y, Color("fff4d0"))
		elif open >= 2:
			c.put(x0 + i, y + open, Color("fff4d0"))
	if open >= 3:
		c.rect(x0 + 1, y + open - 1, max(1, mw - 2), 1, Color("c0284a"))


static func drip(c, x: int, y: int, l: int) -> void:
	for i in l:
		c.tint(x, y + i, GLOW if i < l - 1 else GLOW_D)


# --- Vegetables --------------------------------------------------------------

static func pea(c, p: int) -> void:
	var by = 11.0 + [0, -1, -2, -1][p]
	var sq = [0.0, 0.3, 0.0, -0.3][p]
	legs(c, 10, 19, p, 3, LEAF, 3)
	c.sphere(10, by, 6.5 + sq, 6.5 - sq, GREEN, GLOW_D)
	c.line(10, by - 6, 8 - (p % 2), by - 10, LEAF[3])
	c.leaf(Vector2(10, by - 6), Vector2(15, by - 9), 2, LEAF)
	c.rect(9, int(by) - 3, 5, 4, Color("efffb0"))
	c.rect(11, int(by) - 2, 2, 3, DARK)
	c.put(12, int(by) - 3, GLOW)
	c.rect(8, int(by) - 4, 6, 1, DARK)
	mouth(c, 8, int(by) + 2, 5, 1 + (p % 2))


static func carrot(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	var y0 = 8.0 + dy
	legs(c, 12, 31, p, 3, ORANGE, 6)
	for i in 3:
		var sway = [0, 1, 0, -1][(p + i) % 4]
		c.leaf(Vector2(12, y0 + 1), Vector2(7 + i * 5 + sway, y0 - 7 + abs(i - 1) * 2), 2.2, LEAF)
	var prof = func(t: float) -> float: return 8.5 * pow(1.0 - t, 0.7) * min(1.0, t * 7.0 + 0.45)
	c.lathe(12, y0, 28.0 + dy, prof, ORANGE, GLOW_D)
	for ry in [15, 19, 23]:
		c.line(6 + (ry - 15) / 2, ry + dy, 11, ry + dy + 1, ORANGE[1])
	c.line(15, 17 + dy, 18, 16 + dy, ORANGE[1])
	eyes(c, 12, int(y0) + 3, 3)
	mouth(c, 9, int(y0) + 8, 7, 2 + (p % 2))
	drip(c, 15, int(y0) + 11, 3)


static func tomato(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	var sq = [0.0, 0.4, 0.0, -0.4][p]
	var cy = 15.0 + dy
	legs(c, 14, 27, p, 4, LEAF, 4)
	c.sphere(14, cy, 11.5 + sq, 10.0 - sq, RED, GLOW_D)
	for a in 5:
		var ang = -PI / 2 + (a - 2) * 0.55
		c.leaf(Vector2(14, cy - 9), Vector2(14, cy - 9) + Vector2(cos(ang) * 8, sin(ang) * 3 + 2.5), 1.6, LEAF)
	c.line(14, cy - 10, 15, cy - 13, LEAF[1], 2)
	eyes(c, 14, int(cy) - 4, 4)
	var o: int = 3 + (p % 2)
	c.rect(7, int(cy) + 2, 15, o + 1, BLOOD)
	for i in 8:
		c.put(7 + i * 2, int(cy) + 2, Color("fff4d0"))
		c.put(8 + i * 2, int(cy) + 2 + o, Color("fff4d0"))
	c.rect(10, int(cy) + 3 + o - 2, 8, 1, GLOW_D)
	c.put(6, int(cy) - 6, RED[4])


static func potato(c, p: int) -> void:
	var dy = [0, 0, -1, 0][p]
	legs(c, 16, 31, p, 6, POTATO, 5)
	c.sphere(14, 18.0 + dy, 12, 11, POTATO, GLOW_D)
	c.sphere(21, 15.0 + dy, 8, 8, POTATO)
	c.sphere(11, 12.0 + dy, 6, 5, POTATO)
	for s in [[7, 22], [11, 25], [20, 23], [24, 19], [18, 9]]:
		c.put(s[0], s[1] + dy, POTATO[1])
		c.put(s[0] + 1, s[1] + dy, POTATO[0])
	# many mutated eyes
	for e in [[13, 13, 2], [20, 12, 2], [8, 16, 1], [25, 14, 1], [16, 8, 1]]:
		c.rect(e[0], e[1] + dy, e[2] + 1, e[2] + 1, Color("efffb0"))
		c.put(e[0] + e[2] / 2, e[1] + dy + e[2] / 2, DARK)
	c.rect(10, 11 + dy, 7, 1, DARK)
	mouth(c, 11, 19 + dy, 11, 2 + (p % 2))
	# radioactive sprouts
	c.line(23, 8 + dy, 26, 4 + dy, GLOW_D)
	c.put(26, 3 + dy, GLOW)
	c.line(9, 8 + dy, 7, 5 + dy, GLOW_D)
	c.put(7, 4 + dy, GLOW)


static func onion(c, p: int) -> void:
	var dy = [0, -1, -1, 0][p]
	legs(c, 14, 31, p, 3, ONION, 4)
	var prof = func(t: float) -> float: return 12.0 * sin(pow(t, 0.75) * PI) + 0.5
	c.lathe(14, 6.0 + dy, 28.0 + dy, prof, ONION, GLOW_D)
	for lx in [-7, -3, 3, 7]:
		c.line(14 + lx * 0.3, 8 + dy, 14 + lx, 19 + dy, ONION[1 if lx > 0 else 2])
	var sway = [-1, 0, 1, 0][p]
	c.line(14, 7 + dy, 13 + sway, 2 + dy, LEAF[2], 2)
	c.line(13 + sway, 2 + dy, 17 + sway, 0 + dy, LEAF[3])
	eyes(c, 14, 14 + dy, 4)
	mouth(c, 11, 21 + dy, 7, 1)
	var tear = [0, 1, 2, 3][p]
	c.rect(9, 18 + dy + tear, 2, 2, Color("7fe8ff"))
	c.rect(19, 18 + dy + ((tear + 2) % 4), 2, 2, Color("7fe8ff"))


static func corn(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	legs(c, 13, 35, p, 4, DGREEN, 5)
	var prof = func(t: float) -> float: return 8.2 * sin(pow(t, 0.8) * PI * 0.92 + 0.14) + 0.3
	c.lathe(13, 3.0 + dy, 30.0 + dy, prof, CORN, GLOW_D, null, 0.05)
	# kernels
	for ky in range(4, 30, 3):
		for kx in range(2, 25):
			var x: int = kx + (1 if (ky / 3) % 2 == 0 else 0)
			if (kx + ky / 3) % 3 == 0:
				c.tint(x, ky + dy + 2, CORN[0])
			if (ky % 2 == 0) and kx % 3 == 1:
				c.tint(x, ky + dy, CORN[3])
	# husk cape
	var husk = DGREEN
	c.leaf(Vector2(13, 31 + dy), Vector2(3 + (p % 2), 13 + dy), 4.5, husk)
	c.leaf(Vector2(13, 31 + dy), Vector2(23 - (p % 2), 13 + dy), 4.5, husk)
	c.rect(7, 9 + dy, 13, 1, DARK)
	eyes(c, 13, 10 + dy, 3)
	mouth(c, 10, 16 + dy, 7, 2 + (p % 2))


static func chili(c, p: int) -> void:
	var dy = [0, -1, 0, 1][p]
	legs(c, 11, 31, p, 2, RED, 3)
	var prof = func(t: float) -> float: return 7.0 * pow(1.0 - t, 0.75) * min(1.0, 0.55 + t * 5.0)
	var bend = func(t: float) -> float: return sin(t * 3.0) * 2.5 * t
	c.lathe(9, 7.0 + dy, 29.0 + dy, prof, RED, Color("ffae3a"), bend)
	c.ellipse(9, 7 + dy, 5, 2, LEAF[2])
	c.line(9, 6 + dy, 7, 1 + dy, LEAF[1], 2)
	# flames
	var fl = [[12, 3], [15, 5], [17, 2], [3, 3]]
	for i in fl.size():
		var f: Array = fl[i]
		var fy: int = int(f[1]) + ((p + i) % 3) + dy
		c.rect(int(f[0]), fy, 2, 3, Color("ffae3a"))
		c.put(int(f[0]), fy + 1, Color("fff09a"))
	eyes(c, 9, 11 + dy, 3)
	mouth(c, 7, 16 + dy, 6, 2)


static func eggplant(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	legs(c, 14, 33, p, 4, PURPLE, 4)
	var prof = func(t: float) -> float: return lerp(5.5, 13.0, smoothstep(0.0, 0.7, t)) * sqrt(max(0.0, 1.0 - pow(t, 6.0))) + 0.3
	c.lathe(14, 5.0 + dy, 30.0 + dy, prof, PURPLE, GLOW_D)
	# glossy highlight
	c.line(8, 12 + dy, 7, 19 + dy, Color("e8c8ff"), 2)
	for a in [-1, 0, 1]:
		c.leaf(Vector2(14, 4 + dy), Vector2(14 + a * 9, 9 + dy - abs(a) * 0), 2.2, LEAF)
	c.line(14, 4 + dy, 15, 0 + dy, LEAF[1], 3)
	eyes(c, 14, 14 + dy, 4)
	c.rect(9, 12 + dy, 11, 1, DARK)
	mouth(c, 10, 21 + dy, 9, 2 + (p % 2))


static func broccoli(c, p: int) -> void:
	var dy = [0, -1, -1, 0][p]
	legs(c, 21, 43, p, 7, Px.ramp(["2a4a30", "3f7a3f", "6fb04a"]), 6)
	var prof = func(t: float) -> float: return lerp(9.0, 13.0, t) + 0.5
	c.lathe(21, 19.0 + dy, 38.0 + dy, prof, Px.ramp(["1f4a3a", "3f8a48", "76bf52", "a8dc72"]), GLOW_D)
	# arms
	var a = [0, 1, 0, -1][p]
	c.line(9, 22 + dy, 3, 30 + dy + a, DGREEN[3], 3)
	c.line(33, 22 + dy, 39, 30 + dy - a, DGREEN[2], 3)
	c.sphere(3, 32 + dy + a, 3.5, 3.5, DGREEN)
	c.sphere(39, 32 + dy - a, 3.5, 3.5, DGREEN)
	for b in [[7, 18, 6], [34, 18, 6], [13, 11, 7], [28, 11, 7], [21, 7, 7], [21, 16, 8], [11, 19, 5], [31, 19, 5]]:
		c.sphere(b[0], b[1] + dy, b[2], b[2], DGREEN, GLOW_D)
	for i in 40:
		var x = 3 + (i * 17) % 36
		var y = 2 + (i * 11) % 22
		if i % 3 == 0:
			c.tint(x, y + dy, DGREEN[4])
		elif i % 3 == 1:
			c.tint(x, y + dy, DGREEN[1])
	eyes(c, 21, 25 + dy, 5, 3)
	mouth(c, 15, 31 + dy, 13, 2 + (p % 2))


static func beet(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	legs(c, 15, 33, p, 4, BEET, 4)
	var prof = func(t: float) -> float: return 12.5 * pow(sin(pow(t, 0.62) * PI), 0.75) + 0.2
	for i in [-1, 0, 1]:
		var sw = [0, 1, 0, -1][(p + i + 1) % 4]
		var tip = Vector2(15 + i * 9 + sw, 1 + dy + abs(i) * 3)
		c.leaf(Vector2(15, 11 + dy), tip, 3.5, DGREEN)
		c.line(15, 11 + dy, tip.x, tip.y, BEET[3])
	c.lathe(15, 8.0 + dy, 31.0 + dy, prof, BEET, GLOW_D)
	for ry in [20, 23]:
		c.line(6, ry + dy, 12, ry + dy + 1, BEET[1])
	eyes(c, 15, 14 + dy, 4)
	mouth(c, 11, 21 + dy, 9, 2 + (p % 2))
	drip(c, 21, 22 + dy, 4)


static func garlic(c, p: int) -> void:
	var dy = [0, -1, 0, -1][p]
	legs(c, 13, 27, p, 3, GARLIC, 3)
	var prof = func(t: float) -> float: return 11.5 * pow(sin(pow(t, 0.55) * PI), 0.7) + 0.4
	c.lathe(13, 3.0 + dy, 25.0 + dy, prof, GARLIC, GLOW_D)
	for lx in [-5, 0, 5]:
		c.line(13 + lx * 0.2, 4 + dy, 13 + lx, 23 + dy, GARLIC[1])
	c.line(13, 4 + dy, 13, 0 + dy, GARLIC[1], 2)
	eyes(c, 13, 12 + dy, 4)
	mouth(c, 9, 18 + dy, 9, 1 + (p % 2))
	for g in [[3, 5], [22, 3], [24, 13]]:
		var gy: int = g[1] - (p % 3)
		c.put(g[0], gy, GLOW)
		c.put(g[0] + 1, gy, GLOW_D)
		c.put(g[0], gy + 1, GLOW_D)


# --- Bosses ------------------------------------------------------------------

static func gourd_king(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	var sq = [0.0, 0.5, 1.0, 0.5][p]
	var cx = 48.0
	var cy = 60.0 + dy
	# vine legs
	for s in [-1, 1]:
		var o = [2, 0, -2, 0][p] * s
		c.line(cx + s * 22, 80 + dy, cx + s * 30 + o, 92, DGREEN[1], 5)
		c.line(cx + s * 30 + o, 92, cx + s * 36 + o, 92, DGREEN[2], 4)
	# ribs, back to front
	for rib in [[-29, 13, 22], [29, 13, 22], [-20, 17, 28], [20, 17, 28], [-8, 20, 31], [8, 20, 31]]:
		c.sphere(cx + rib[0], cy, rib[1] + 3 + sq, rib[2] - sq, ORANGE, GLOW_D if abs(rib[0]) > 25 else null)
	c.sphere(cx, cy, 12, 32 - sq, ORANGE)
	# stem and crown
	c.line(cx, cy - 31, cx + 3, cy - 40, DGREEN[1], 7)
	var gold = YELLOW
	for k in 7:
		var kx = cx - 18 + k * 6
		var th = 11 if k % 2 == 0 else 6
		c.rect(int(kx), int(cy - 39 - th + 8), 5, th, gold[2])
		c.rect(int(kx), int(cy - 39 - th + 8), 2, th, gold[3])
	c.rect(int(cx) - 19, int(cy) - 33, 41, 6, gold[1])
	c.rect(int(cx) - 19, int(cy) - 33, 41, 2, gold[3])
	for k in [-11, 0, 11]:
		c.rect(int(cx) + k, int(cy) - 32, 3, 3, GLOW)
	# carved face glowing with radiation
	var g = func(pts: Array) -> void:
		var inner = []
		for q in pts:
			inner.append(Vector2(cx, cy) + q)
		c.poly(inner, GLOW_D)
		var mid = Vector2.ZERO
		for q in inner:
			mid += q
		mid /= inner.size()
		var core = []
		for q in inner:
			core.append(mid + (q - mid) * 0.6)
		c.poly(core, GLOW)
	g.call([Vector2(-26, -8), Vector2(-8, -3), Vector2(-14, -18)])
	g.call([Vector2(26, -8), Vector2(8, -3), Vector2(14, -18)])
	g.call([Vector2(-3, 0), Vector2(3, 0), Vector2(0, -6)])
	var mo: int = 2 + p
	g.call([Vector2(-27, 4), Vector2(-16, 7 + mo), Vector2(-10, 3), Vector2(-5, 8 + mo), Vector2(0, 4), Vector2(5, 8 + mo), Vector2(10, 3), Vector2(16, 7 + mo), Vector2(27, 4), Vector2(20, 18 + mo), Vector2(9, 22 + mo), Vector2(5, 16 + mo), Vector2(0, 22 + mo), Vector2(-5, 16 + mo), Vector2(-9, 22 + mo), Vector2(-20, 18 + mo)])


static func corn_colossus(c, p: int) -> void:
	var dy = [0, -1, -2, -1][p]
	var cx = 52.0
	for s in [-1, 1]:
		var o = [3, 0, -3, 0][p] * s
		c.line(cx + s * 12, 92, cx + s * 16 + o, 112, DGREEN[2], 7)
		c.line(cx + s * 16 + o, 112, cx + s * 24 + o, 113, DGREEN[1], 5)
	# back husk cape
	for s in [-1, 1]:
		c.leaf(Vector2(cx, 100 + dy), Vector2(cx + s * 46, 34 + dy + (p % 2) * 2), 15, DGREEN)
		c.leaf(Vector2(cx, 100 + dy), Vector2(cx + s * 30, 12 + dy), 13, DGREEN)
	var prof = func(t: float) -> float: return 25.0 * sin(pow(t, 0.8) * PI * 0.92 + 0.14) + 0.5
	c.lathe(cx, 4.0 + dy, 100.0 + dy, prof, CORN, GLOW_D, null, 0.03)
	for ky in range(5, 100, 5):
		for kx in range(int(cx) - 28, int(cx) + 28):
			var off: int = 2 if (ky / 5) % 2 == 0 else 0
			var kk: int = (kx + off) % 5
			if kk == 0:
				c.tint(kx, ky + dy, CORN[0])
				c.tint(kx, ky + dy + 1, CORN[0])
				c.tint(kx, ky + dy + 2, CORN[0])
			if ky % 5 == 0:
				pass
			c.tint(kx, ky + dy + 4, CORN[1])
			if kk == 2:
				c.tint(kx, ky + dy + 1, CORN[3])
	# radioactive cracks
	for r in [[32, 40, 38, 58], [38, 58, 34, 70], [72, 34, 66, 52], [66, 52, 72, 66]]:
		c.line(r[0], r[1] + dy, r[2], r[3] + dy, GLOW)
	# front husks
	for s in [-1, 1]:
		c.leaf(Vector2(cx, 104 + dy), Vector2(cx + s * 25, 62 + dy), 11, DGREEN)
	# face: three eyes
	c.rect(int(cx) - 19, 24 + dy, 38, 2, DARK)
	for e in [[-13, 28, 6], [8, 28, 6], [-3, 13, 7]]:
		c.ellipse(cx + e[0] + 3, e[1] + dy + 3, e[2] * 0.75, e[2] * 0.6, Color("efffb0"))
		c.rect(int(cx) + e[0] + 2, e[1] + dy + 2, 3, 3, DARK)
		c.put(int(cx) + e[0] + 3, e[1] + dy + 1, GLOW)
	c.rect(int(cx) - 14, 42 + dy, 28, 8 + p, BLOOD)
	for i in 14:
		c.rect(int(cx) - 14 + i * 2, 42 + dy, 1, 2, Color("fff4d0"))
		c.rect(int(cx) - 13 + i * 2, 48 + dy + p, 1, 2, Color("fff4d0"))
	c.rect(int(cx) - 8, 46 + dy + p, 16, 2, GLOW_D)


static func root_of_evil(c, p: int) -> void:
	var cx = 60.0
	var dy = [0, -1, -2, -1][p]
	var cy = 64.0 + dy
	# writhing root tentacles
	for i in 8:
		var ang: float = 0.25 + i * 0.37
		var pts = []
		var x = cx + cos(ang) * 22
		var y = cy + 18 + sin(ang) * 10
		var d = 1 if cos(ang) > 0 else -1
		for k in 7:
			var wob: float = sin(k * 1.3 + p * PI / 2.0 + i) * 3.5
			var nx = x + d * (4.0 + abs(cos(ang)) * 4.5)
			var ny = y + 5.0 + wob
			c.line(x, y, nx, min(ny, 119.0), BEET[2 if k < 3 else 1], max(1, 6 - k))
			x = nx
			y = min(ny, 119.0)
	# toxic leaf crown
	for i in range(-3, 4):
		var sw = [0, 2, 0, -2][(p + i + 3) % 4]
		var tip = Vector2(cx + i * 15 + sw, 5 + dy + abs(i) * abs(i) * 3)
		c.leaf(Vector2(cx, cy - 24), tip, 10, DGREEN)
		c.line(cx, cy - 24, tip.x, tip.y, BEET[3], 2)
	var prof = func(t: float) -> float: return 40.0 * pow(sin(pow(t, 0.65) * PI), 0.7) + 0.5
	c.lathe(cx, cy - 34, cy + 50, prof, BEET, GLOW_D)
	# rings and veins
	for ry in [12, 22, 30]:
		for x in range(int(cx) - 40, int(cx) + 40):
			var ww: float = sin(x * 0.35 + ry) * 1.5
			c.tint(x, int(cy + ry + ww), BEET[1])
	for r in [[28, -5, 18, 12], [18, 12, 26, 28], [92, -8, 100, 10], [100, 10, 90, 24], [60, 20, 54, 44], [54, 44, 66, 56]]:
		c.line(r[0], cy + r[1], r[2], cy + r[3], GLOW)
	# great single eye
	var blink: int = 0 if p != 2 else 1
	c.ellipse(cx, cy - 8, 21, 14 - blink, DARK)
	c.ellipse(cx, cy - 8, 19, 12 - blink, Color("efffb0"))
	c.ellipse(cx + 2, cy - 8, 11, 11 - blink, GLOW_D)
	c.ellipse(cx + 2, cy - 8, 8, 8 - blink, GLOW)
	c.rect(int(cx) + 1, int(cy) - 15, 3, 14, DARK)
	c.rect(int(cx) - 1, int(cy) - 11, 2, 2, Color.WHITE)
	# brow
	c.line(cx - 24, cy - 25, cx - 2, cy - 15, DARK, 3)
	c.line(cx + 24, cy - 25, cx + 2, cy - 15, DARK, 3)
	# maw
	var o: int = 7 + p
	c.ellipse(cx, cy + 18, 24, o + 3, BLOOD)
	for i in 12:
		var tx: int = int(cx) - 22 + i * 4
		c.poly([Vector2(tx, cy + 18 - o), Vector2(tx + 3, cy + 18 - o), Vector2(tx + 1.5, cy + 24 - o)], Color("fff4d0"))
		c.poly([Vector2(tx, cy + 18 + o), Vector2(tx + 3, cy + 18 + o), Vector2(tx + 1.5, cy + 13 + o)], Color("fff4d0"))


# --- Playable characters -----------------------------------------------------

## `cfg` keys: skin, hair, shirt, shirt2, pants, hat ("straw"/"veil"/"cap"/"bun"), beard
static func farmer(c, frame: int, cfg: Dictionary) -> void:
	# frame 0-1 idle, 2-5 walk
	var walking = frame >= 2
	var ph = frame - 2
	var bob: int = ([0, -1, 0, -1][ph] if walking else [0, 1][frame])
	var la: int = ([2, 0, -2, 0][ph] if walking else 0)
	var cx = 14
	var feet = 34
	var skin: Array = cfg.skin
	var pants: Array = cfg.pants
	var shirt: Array = cfg.shirt
	# back leg
	c.rect(cx - 1 + la, feet - 7, 4, 5, pants[1])
	c.rect(cx - 2 + la, feet - 3, 6, 3, BOOT[1])
	# back arm
	var ax = [0, 1, 0, -1][ph] if walking else 0
	c.rect(cx + 4 - ax, 20 + bob, 3, 8, shirt[0])
	c.rect(cx + 4 - ax, 27 + bob, 3, 2, skin[1])
	# front leg
	c.rect(cx - 4 - la, feet - 8, 5, 6, pants[2])
	c.rect(cx - 4 - la, feet - 8, 1, 6, pants[3])
	c.rect(cx - 5 - la, feet - 3, 7, 3, BOOT[2])
	c.rect(cx - 5 - la, feet - 3, 7, 1, BOOT[3])
	# torso
	var torso = func(t: float) -> float: return 6.6 + sin(t * PI) * 0.8
	c.lathe(cx, 18 + bob, 28 + bob, torso, shirt, null, null, 0.04)
	if cfg.get("dress", false):
		var skirt = func(t: float) -> float: return 6.5 + t * 3.0
		c.lathe(cx, 24 + bob, 31 + bob, skirt, pants, null, null, 0.02)
		c.rect(cx - 3, 20 + bob, 6, 9, Color("f4ecd8"))
		c.rect(cx - 3, 20 + bob, 1, 9, Color("cfc4b4"))
	elif cfg.get("overalls", true):
		c.lathe(cx, 22 + bob, 28 + bob, func(_t: float) -> float: return 6.5, pants, null, null, 0.02)
		c.rect(cx - 3, 18 + bob, 2, 5, pants[1])
		c.rect(cx + 2, 18 + bob, 2, 5, pants[1])
		c.rect(cx - 2, 22 + bob, 5, 3, pants[3])
		c.put(cx - 3, 22 + bob, YELLOW[3])
		c.put(cx + 3, 22 + bob, YELLOW[3])
	else:
		c.rect(cx - 7, 25 + bob, 14, 2, BOOT[1])
		c.put(cx, 25 + bob, YELLOW[3])
	# plaid pattern
	if cfg.get("plaid", false):
		for y in range(18, 28, 2):
			for x in range(cx - 7, cx + 8, 3):
				if c.get_px(x, y + bob) in [shirt[0], shirt[1], shirt[2], shirt[3]]:
					c.put(x, y + bob, cfg.shirt2)
	# head
	c.sphere(cx + 1, 13 + bob, 6.5, 6.5, skin, null, 0.03)
	if cfg.has("hair"):
		c.rect(cx - 5, 8 + bob, 4, 7, cfg.hair[1])
		c.rect(cx - 5, 9 + bob, 2, 5, cfg.hair[2])
	# face
	c.rect(cx + 3, 12 + bob, 2, 3, DARK)
	c.put(cx + 4, 12 + bob, Color.WHITE)
	c.rect(cx + 2, 10 + bob, 4, 1, cfg.get("brow", Color("5a4030")))
	c.rect(cx + 6, 14 + bob, 2, 2, skin[3])
	c.put(cx + 7, 15 + bob, skin[1])
	if cfg.get("beard", false):
		c.sphere(cx + 2, 18 + bob, 5.5, 3.6, WHITE, null, 0.02)
		c.rect(cx + 2, 16 + bob, 6, 1, WHITE[2])
		c.rect(cx + 4, 17 + bob, 3, 1, skin[0])
	if cfg.get("glasses", false):
		c.rect(cx + 1, 11 + bob, 7, 1, DARK)
		c.rect(cx + 2, 11 + bob, 3, 4, Color(0.75, 0.93, 1.0))
		c.rect(cx + 3, 12 + bob, 2, 3, DARK)
		c.line(cx + 1, 15 + bob, cx + 5, 15 + bob, DARK)
	# headgear
	match cfg.hat:
		"straw":
			c.lathe(cx + 1, 4 + bob, 9 + bob, func(t: float) -> float: return 6.0 + t * 1.2, STRAW, null, null, 0.1)
			c.rect(cx - 7, 8 + bob, 17, 1, Color("c23a3a"))
			c.lathe(cx + 1, 8 + bob, 11 + bob, func(t: float) -> float: return 11.5 - t * 1.5, STRAW, null, null, 0.1)
			for i in range(-9, 10, 3):
				c.tint(cx + 1 + i, 9 + bob, STRAW[1])
		"veil":
			c.lathe(cx + 1, 3 + bob, 9 + bob, func(t: float) -> float: return 6.0 + t, WHITE, null, null, 0.05)
			c.lathe(cx + 1, 8 + bob, 11 + bob, func(t: float) -> float: return 11.5 - t, WHITE, null, null, 0.05)
			for y in range(11, 19):
				for x in range(cx - 7, cx + 9):
					if (x + y) % 2 == 0:
						c.put(x, y + bob, Color("59607a"))
			c.rect(cx + 3, 13 + bob, 2, 2, Color("efffb0"))
		"cap":
			c.lathe(cx + 1, 4 + bob, 10 + bob, func(t: float) -> float: return 3.5 + sqrt(t) * 3.5, cfg.cap, null, null, 0.05)
			c.rect(cx + 3, 9 + bob, 8, 2, cfg.cap[1])
			c.rect(cx + 3, 9 + bob, 8, 1, cfg.cap[2])
			c.rect(cx, 6 + bob, 3, 2, Color("fff4d0"))
		"bun":
			c.sphere(cx - 1, 8 + bob, 7, 5, cfg.hair, null, 0.03)
			c.sphere(cx - 5, 5 + bob, 3.5, 3.5, cfg.hair, null, 0.03)
			c.rect(cx - 7, 9 + bob, 3, 7, cfg.hair[1])
	# front arm
	c.rect(cx - 2 + ax, 20 + bob, 4, 7, shirt[2])
	c.rect(cx - 2 + ax, 20 + bob, 1, 7, shirt[3])
	c.rect(cx - 2 + ax, 27 + bob, 4, 2, skin[2])
