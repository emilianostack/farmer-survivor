## Weapons, pickups, icons, terrain, props, interface and story illustrations.
extends RefCounted

const Px = preload("res://tools/px.gd")
const A = preload("res://tools/art_actors.gd")

static var STEEL = Px.ramp(["2c3048", "5a6480", "9aa8bc", "dfe8f0", "ffffff"])
static var WOOD = Px.ramp(["2e1a22", "5a3428", "8a5a34", "b8864a", "dcb46c"])
static var RUST = Px.ramp(["3a1a24", "6b2c24", "9a4a2a", "c8743a"])
static var GOLD = Px.ramp(["6b3414", "b86a1c", "eeb02e", "ffe066", "fffbd0"])
static var HAY = Px.ramp(["7a4a1e", "b8822c", "e6b84a", "fbe48a"])
static var STONE = Px.ramp(["2a2a3c", "4a4c60", "74788a", "a4a8b4"])
static var RADBARREL = Px.ramp(["5a3a14", "a87818", "e6c02a", "fbe86a"])
const GLOW = Color("b8ff3a")
const GLOW_D = Color("4fd13a")
const DARK = Color("140c1c")


static func radiation_sign(c, cx: float, cy: float, r: float, fg: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var v = Vector2(x + 0.5 - cx, y + 0.5 - cy)
			var d = v.length()
			if d > r:
				continue
			var ang = fposmod(v.angle() + PI / 2.0 + PI / 6.0, TAU / 3.0)
			if d < r * 0.24 or (d > r * 0.36 and ang < PI / 3.0):
				c.put(x, y, fg)


# --- Weapons -------------------------------------------------------------------

static func slash(c) -> void:
	var cx = 6.0
	var cy = 32.0
	for y in c.h:
		for x in c.w:
			var v = Vector2(x + 0.5 - cx, y + 0.5 - cy)
			var d = v.length()
			var a = abs(v.angle())
			if a > 1.25:
				continue
			var inner = 22.0 + (a / 1.25) * 15.0
			if d > 37.0 or d < inner:
				continue
			var e = (d - inner) / max(37.0 - inner, 0.1)
			var col = Color("ffffff") if e > 0.72 else (Color("c8f0ff") if e > 0.4 else Color("6aaee0"))
			c.put(x, y, Color(col.r, col.g, col.b, 0.95 if e > 0.4 else 0.6))


static func pitchfork(c) -> void:
	c.line(0, 4, 14, 4, WOOD[3])
	c.line(0, 5, 14, 5, WOOD[1])
	c.rect(14, 1, 2, 7, STEEL[2])
	for ty in [1, 4, 7]:
		c.line(15, ty, 22, ty, STEEL[3])
		c.put(23, ty, STEEL[4])


static func pellet(c) -> void:
	c.sphere(3, 3, 2.5, 2.5, Px.ramp(["b86a1c", "eeb02e", "fffbd0"]))


static func sickle(c) -> void:
	for a in range(0, 14):
		var ang = -2.4 + a * 0.3
		var r = 7.0
		var w = 2.8 - abs(a - 7) * 0.3
		var p = Vector2(9 + cos(ang) * r, 9 + sin(ang) * r)
		c.ellipse(p.x, p.y, max(0.7, w), max(0.7, w), STEEL[2 + int(a % 5 == 0) + int(a < 4)])
	c.line(6, 15, 2, 19, WOOD[3], 2)


static func bee(c, f: int) -> void:
	c.ellipse(5, 2 + f, 3, 2, Color(0.85, 0.95, 1.0))
	c.sphere(5, 6, 4, 3, Px.ramp(["b86a1c", "eeb02e", "ffe066"]), null, 0.0)
	c.rect(3, 3, 2, 6, DARK)
	c.rect(6, 3, 1, 6, DARK)
	c.put(9, 6, DARK)


static func puddle(c, f: int) -> void:
	var r = Px.ramp(["1a3a6a", "2a7ab0", "3fc8c8", "9ff0d0"])
	c.ellipse(24, 16, 23, 15, Color(r[1].r, r[1].g, r[1].b, 0.72))
	c.ellipse(24, 16, 19, 12, Color(r[2].r, r[2].g, r[2].b, 0.72))
	for i in 6:
		var a = i * 1.1 + f * 0.8
		c.ellipse(24 + cos(a) * 13, 16 + sin(a) * 7, 2, 1.5, r[3])
	c.rect(14 + f * 3, 10, 2, 2, Color.WHITE)


static func tractor(c, f: int) -> void:
	var red = Px.ramp(["5a1426", "a4262e", "d8423a", "f07a5a", "ffc8a0"])
	# body
	c.rect(30, 22, 30, 15, red[2])
	c.rect(30, 22, 30, 3, red[3])
	c.rect(30, 34, 30, 3, red[1])
	c.rect(30, 22, 32, 1, red[4])
	for i in 5:
		c.rect(50, 25 + i * 2, 9, 1, DARK)
	# cab
	c.rect(10, 6, 20, 2, red[2])
	c.rect(12, 8, 2, 16, red[1])
	c.rect(27, 8, 3, 16, red[1])
	c.rect(14, 8, 13, 13, Color("a8e0f0"))
	c.line(16, 18, 24, 9, Color.WHITE, 2)
	c.rect(8, 24, 24, 14, red[2])
	c.rect(8, 24, 24, 2, red[3])
	# exhaust
	c.rect(44, 10, 3, 12, STEEL[1])
	c.rect(43, 9, 5, 2, STEEL[2])
	# wheels
	var w = func(cx, cy, r):
		c.sphere(cx, cy, r, r, Px.ramp(["140c1c", "2a2238", "48405c"]), null, 0.0)
		c.sphere(cx, cy, r * 0.55, r * 0.55, GOLD)
		var ang = f * PI / 4.0
		for k in 4:
			var q = ang + k * PI / 2.0
			c.line(cx + cos(q) * r * 0.58, cy + sin(q) * r * 0.58, cx + cos(q) * r, cy + sin(q) * r, DARK)
	w.call(18.0, 37.0, 11.0)
	w.call(52.0, 40.0, 7.0)
	# blades at the front
	for i in 5:
		c.line(61, 26 + i * 4, 66 + (i + f) % 2 * 2, 26 + i * 4, STEEL[3], 2)


static func bolt(c, f: int) -> void:
	var x = 8.0
	var seed = [3, 7, 11][f]
	for y in range(0, 92, 6):
		var nx = 8.0 + sin(y * 0.3 + seed) * 5.0
		c.line(x, y, nx, y + 6, Color("7fe8ff"), 3)
		c.line(x, y, nx, y + 6, Color.WHITE, 1)
		x = nx


static func scarecrow(c, f: int) -> void:
	var dy = [0, -1][f]
	c.line(13, 12, 13, 38, WOOD[2], 3)
	c.line(1, 18 + dy, 25, 18 + dy, WOOD[3], 2)
	c.lathe(13, 16 + dy, 30 + dy, func(t): return 6.0 + t * 2.0, Px.ramp(["5a1426", "a4262e", "d8423a", "f07a5a"]), null, null, 0.05)
	for i in [5, 9, 16, 20]:
		c.line(i, 18 + dy, i, 21 + dy + (i + f) % 2, HAY[3])
	c.sphere(13, 10 + dy, 6, 6, HAY, null, 0.04)
	c.rect(10, 8 + dy, 2, 2, DARK)
	c.rect(15, 8 + dy, 2, 2, DARK)
	c.line(10, 13 + dy, 16, 13 + dy, DARK)
	c.lathe(13, 0 + dy, 5 + dy, func(t): return 4.0 + t, Px.ramp(["1f1420", "3f2422", "6b3f2c"]), null, null, 0.04)
	c.rect(5, 5 + dy, 17, 2, Color("3f2422"))


static func kernel(c) -> void:
	c.sphere(4, 4, 3.5, 3.5, A.CORN, A.GLOW_D, 0.0)


static func seed_shot(c) -> void:
	c.sphere(4, 4, 3.5, 3.5, A.RED, null, 0.0)
	c.put(3, 3, Color.WHITE)


static func rad_blob(c) -> void:
	c.sphere(6, 6, 5.5, 5.5, Px.ramp(["1f6b3d", "4fd13a", "b8ff3a", "f4ffc0"]), null, 0.0)


# --- Pickups -------------------------------------------------------------------

static func gem(c, r: Array) -> void:
	c.poly([Vector2(5, 0), Vector2(10, 5), Vector2(5, 13), Vector2(0, 5)], r[1])
	c.poly([Vector2(5, 0), Vector2(0, 5), Vector2(5, 5)], r[3])
	c.poly([Vector2(5, 0), Vector2(5, 5), Vector2(10, 5)], r[2])
	c.poly([Vector2(0, 5), Vector2(5, 5), Vector2(5, 13)], r[2])
	c.put(3, 3, Color.WHITE)


static func coin(c, f: int) -> void:
	var rx = [5.0, 3.6, 1.5, 3.6][f]
	c.sphere(6, 6, rx, 5.5, GOLD, null, 0.02)
	if rx > 3:
		c.line(6, 3, 6, 8, GOLD[1])


static func pie(c) -> void:
	c.lathe(8, 6, 13, func(t): return 7.5 - t * 1.0, Px.ramp(["6b3414", "b8703a", "dca060"]), null, null, 0.05)
	c.ellipse(8, 6, 7, 3, Px.ramp(["6b3414", "b8703a", "dca060", "f0cc90"])[3])
	c.ellipse(8, 6, 5, 2, Color("cf2f3a"))
	c.line(3, 5, 12, 5, Color("f0cc90"))
	c.line(5, 7, 11, 7, Color("f0cc90"))
	c.line(6, 3, 7, 0, Color(1, 1, 1, 0.8))
	c.line(10, 3, 9, 0, Color(1, 1, 1, 0.8))


static func magnet(c) -> void:
	for a in range(-1, 16):
		var ang = PI + a * PI / 14.0
		var p = Vector2(8 + cos(ang) * 5.5, 8 + sin(ang) * 5.5)
		c.ellipse(p.x, p.y, 2.2, 2.2, A.RED[2] if a % 3 else A.RED[3])
	c.rect(1, 8, 4, 6, A.RED[2])
	c.rect(11, 8, 4, 6, A.RED[1])
	c.rect(1, 12, 4, 3, STEEL[3])
	c.rect(11, 12, 4, 3, STEEL[2])


static func dynamite(c) -> void:
	for i in 3:
		c.lathe(4 + i * 4, 4, 15, func(_t): return 2.0, A.RED, null, null, 0.0)
	c.rect(2, 8, 12, 2, HAY[3])
	c.line(8, 4, 11, 1, DARK)
	c.rect(11, 0, 2, 2, Color("ffae3a"))
	c.put(13, 0, Color.WHITE)


static func chest(c) -> void:
	c.rect(2, 9, 22, 12, WOOD[2])
	c.rect(2, 9, 22, 2, WOOD[3])
	c.rect(2, 19, 22, 2, WOOD[1])
	c.lathe(13, 2, 10, func(t): return 7.0 + sqrt(t) * 4.5, WOOD, null, null, 0.04)
	c.rect(2, 9, 22, 1, GOLD[1])
	for x in [4, 20]:
		c.rect(x, 2, 2, 19, GOLD[2])
		c.rect(x, 2, 1, 19, GOLD[3])
	c.rect(11, 8, 4, 5, GOLD[3])
	c.rect(12, 10, 2, 2, DARK)


static func crate(c) -> void:
	c.rect(1, 3, 18, 15, HAY[2])
	for y in range(3, 18, 2):
		for x in range(1, 19):
			if (x * 7 + y * 3) % 5 == 0:
				c.put(x, y, HAY[1])
			elif (x * 3 + y * 11) % 7 == 0:
				c.put(x, y, HAY[3])
	c.rect(1, 3, 18, 1, HAY[3])
	c.rect(1, 17, 18, 1, HAY[0])
	c.rect(5, 3, 1, 15, WOOD[1])
	c.rect(14, 3, 1, 15, WOOD[1])


# --- Icons ---------------------------------------------------------------------


static func icons() -> Dictionary:
	var d = {}
	d["scythe"] = func(c):
		c.line(4, 19, 14, 2, WOOD[3], 2)
		for a in 12:
			var q = PI + 0.2 + a * 0.16
			c.ellipse(14 - 8 + cos(q) * -8 * -1 + 8, 7 + sin(q) * 5, 1.4, 1.4, STEEL[3])
	d["pitchfork"] = func(c):
		c.line(3, 19, 12, 8, WOOD[3], 2)
		c.line(9, 5, 15, 11, STEEL[2], 2)
		for o in [[9, 5, 12, 0], [12, 8, 16, 3], [15, 11, 19, 7]]:
			c.line(o[0], o[1], o[2], o[3], STEEL[3])
	d["shotgun"] = func(c):
		c.line(1, 8, 16, 8, STEEL[2], 2)
		c.line(1, 10, 15, 10, STEEL[1])
		c.line(11, 11, 19, 15, WOOD[3], 3)
		c.line(9, 11, 12, 13, WOOD[2], 2)
	d["sickles"] = func(c):
		sickle(c)
	d["bees"] = func(c):
		c.lathe(10, 2, 19, func(t): return 8.0 * sin(t * PI * 0.85 + 0.2), Px.ramp(["7a4a1e", "b8822c", "e6b84a", "fbe48a"]), null, null, 0.03)
		for y in [6, 10, 14]:
			for x in range(0, 20):
				c.tint(x, y, Color("7a4a1e"))
		c.rect(8, 12, 4, 4, DARK)
	d["weedkiller"] = func(c):
		c.lathe(10, 4, 19, func(_t): return 6.5, Px.ramp(["1a3a6a", "2a7ab0", "3fc8c8", "9ff0d0"]), null, null, 0.03)
		c.rect(8, 1, 5, 3, STEEL[2])
		c.rect(7, 9, 7, 6, Color("f4ecd8"))
		radiation_sign(c, 10.5, 12, 3, DARK)
	d["tractor"] = func(c):
		c.rect(5, 8, 13, 7, Color("d8423a"))
		c.rect(4, 2, 8, 8, Color("a4262e"))
		c.rect(6, 4, 4, 4, Color("a8e0f0"))
		c.sphere(7, 15, 4.5, 4.5, Px.ramp(["140c1c", "2a2238", "eeb02e"]), null, 0.0)
		c.sphere(16, 16, 3, 3, Px.ramp(["140c1c", "2a2238", "eeb02e"]), null, 0.0)
	d["lightning"] = func(c):
		c.poly([Vector2(12, 0), Vector2(4, 11), Vector2(9, 11), Vector2(6, 20), Vector2(16, 8), Vector2(11, 8), Vector2(15, 0)], Color("ffe066"))
		c.line(11, 2, 7, 10, Color.WHITE)
	d["scarecrow"] = func(c):
		c.line(10, 4, 10, 20, WOOD[2], 2)
		c.line(2, 9, 18, 9, WOOD[3], 2)
		c.sphere(10, 6, 4.5, 4.5, HAY, null, 0.0)
		c.rect(8, 5, 1, 1, DARK)
		c.rect(11, 5, 1, 1, DARK)
		c.rect(5, 1, 10, 2, Color("3f2422"))
	# passive items
	d["hat"] = func(c):
		c.lathe(10, 4, 12, func(t): return 5.0 + t * 1.5, HAY, null, null, 0.08)
		c.rect(3, 11, 15, 1, Color("c23a3a"))
		c.lathe(10, 12, 15, func(t): return 9.5 - t * 1.5, HAY, null, null, 0.08)
	d["boots"] = func(c):
		c.rect(6, 3, 7, 10, Px.ramp(["1f1420", "3f2422", "6b3f2c", "96603c"])[2])
		c.rect(6, 3, 2, 10, Px.ramp(["1f1420", "3f2422", "6b3f2c", "96603c"])[3])
		c.rect(6, 12, 12, 5, Px.ramp(["1f1420", "3f2422", "6b3f2c", "96603c"])[2])
		c.rect(6, 16, 12, 2, DARK)
		c.rect(5, 3, 9, 2, GOLD[2])
	d["gloves"] = func(c):
		c.lathe(10, 4, 14, func(_t): return 5.5, HAY, null, null, 0.05)
		for x in [6, 9, 12]:
			c.rect(x, 2, 2, 5, HAY[2])
		c.rect(15, 7, 3, 3, HAY[3])
		c.rect(4, 14, 12, 4, A.RED[2])
	d["almanac"] = func(c):
		c.rect(3, 2, 14, 16, Color("2f8a43"))
		c.rect(3, 2, 3, 16, Color("1a5a3c"))
		c.rect(8, 5, 7, 2, GOLD[3])
		c.rect(8, 9, 7, 1, Color("f4ecd8"))
		c.rect(8, 12, 5, 1, Color("f4ecd8"))
	d["whetstone"] = func(c):
		c.poly([Vector2(2, 14), Vector2(5, 6), Vector2(18, 6), Vector2(15, 14)], STONE[2])
		c.poly([Vector2(2, 14), Vector2(15, 14), Vector2(15, 17), Vector2(2, 17)], STONE[1])
		c.line(6, 8, 16, 8, STONE[3])
		c.put(13, 3, Color.WHITE)
		c.put(15, 2, Color.WHITE)
	d["lunchbox"] = func(c):
		c.rect(2, 6, 16, 12, Color("2f72a8"))
		c.rect(2, 6, 16, 3, Color("5aa0d0"))
		c.rect(2, 12, 16, 1, Color("1f4a78"))
		c.rect(7, 2, 6, 2, STEEL[3])
		c.rect(6, 3, 1, 3, STEEL[3])
		c.rect(13, 3, 1, 3, STEEL[3])
		c.rect(9, 10, 2, 4, GOLD[3])
	d["horseshoe"] = func(c):
		for a in range(-2, 18):
			var q = PI * 0.95 + a * PI / 15.0
			c.ellipse(10 + cos(q) * 6.5, 9 + sin(q) * 6.5 * 1.15, 1.7, 1.7, GOLD[3] if a < 8 else GOLD[2])
		for p in [[5, 7], [15, 7], [10, 2]]:
			c.put(p[0], p[1], DARK)
	d["thermos"] = func(c):
		c.lathe(10, 4, 19, func(_t): return 5.5, A.RED, null, null, 0.03)
		c.rect(6, 1, 9, 4, STEEL[2])
		c.rect(6, 1, 9, 1, STEEL[3])
		c.rect(5, 9, 11, 2, STEEL[3])
	d["overalls"] = func(c):
		c.rect(4, 8, 12, 11, A.DENIM[2])
		c.rect(6, 2, 2, 7, A.DENIM[1])
		c.rect(12, 2, 2, 7, A.DENIM[1])
		c.rect(7, 8, 6, 4, A.DENIM[3])
		c.rect(9, 14, 2, 5, A.DENIM[0])
		c.put(6, 8, GOLD[3])
		c.put(13, 8, GOLD[3])
	d["clover"] = func(c):
		for o in [[6, 6], [14, 6], [6, 13], [14, 13]]:
			c.sphere(o[0], o[1], 4, 4, A.GREEN, null, 0.0)
		c.line(10, 10, 13, 19, A.LEAF[1], 2)
	d["heart"] = func(c):
		c.sphere(6, 7, 5, 5, A.RED, null, 0.0)
		c.sphere(14, 7, 5, 5, A.RED, null, 0.0)
		c.poly([Vector2(1, 8), Vector2(19, 8), Vector2(10, 19)], A.RED[2])
		c.rect(4, 4, 2, 2, Color.WHITE)
	d["reroll"] = func(c):
		for a in 22:
			var q = a * 0.26
			c.ellipse(10 + cos(q) * 7, 10 + sin(q) * 7, 1.3, 1.3, A.GREEN[3])
		c.poly([Vector2(14, 1), Vector2(19, 8), Vector2(11, 8)], A.GREEN[4])
	d["skip"] = func(c):
		c.poly([Vector2(3, 3), Vector2(11, 10), Vector2(3, 17)], STEEL[3])
		c.poly([Vector2(10, 3), Vector2(18, 10), Vector2(10, 17)], STEEL[2])
	d["banish"] = func(c):
		c.ellipse(10, 10, 9, 9, A.RED[2])
		c.ellipse(10, 10, 6, 6, Color(0, 0, 0, 0))
		c.line(4, 16, 16, 4, A.RED[2], 2)
	d["revive"] = func(c):
		c.lathe(10, 9, 19, func(t): return 3.5 + t * 3.5, A.GREEN, null, null, 0.03)
		c.leaf(Vector2(10, 10), Vector2(3, 2), 3, A.LEAF)
		c.leaf(Vector2(10, 10), Vector2(17, 2), 3, A.LEAF)
	d["coin"] = func(c):
		c.sphere(10, 10, 8, 8, GOLD, null, 0.02)
		c.rect(8, 5, 4, 10, GOLD[1])
		c.rect(9, 6, 2, 8, GOLD[4])
	d["rad"] = func(c):
		c.ellipse(10, 10, 9.5, 9.5, Color("ffe066"))
		radiation_sign(c, 10, 10, 8.5, DARK)
	d["skull"] = func(c):
		c.sphere(10, 8, 7, 7, Px.ramp(["a4a8b4", "dfe4ea", "ffffff"]), null, 0.0)
		c.rect(6, 13, 8, 5, Color("dfe4ea"))
		c.rect(6, 7, 3, 3, DARK)
		c.rect(11, 7, 3, 3, DARK)
		c.rect(8, 15, 1, 3, DARK)
		c.rect(11, 15, 1, 3, DARK)
	d["clock"] = func(c):
		c.ellipse(10, 10, 9, 9, STEEL[3])
		c.ellipse(10, 10, 7, 7, Color("f4ecd8"))
		c.line(10, 10, 10, 5, DARK)
		c.line(10, 10, 14, 11, DARK)
	return d


static func building(c, id: String) -> void:
	var roof = Px.ramp(["4b1230", "8f1d36", "cf2f3a", "f15b47"])
	match id:
		"coop":
			c.rect(5, 15, 24, 14, WOOD[2])
			c.rect(5, 15, 24, 2, WOOD[3])
			for x in [9, 15, 21]:
				c.rect(x, 15, 1, 14, WOOD[1])
			c.poly([Vector2(2, 16), Vector2(17, 5), Vector2(32, 16)], roof[2])
			c.line(2, 16, 17, 5, roof[3])
			c.rect(13, 21, 8, 8, DARK)
			c.sphere(17, 22, 3, 3, Px.ramp(["b4bccc", "e4e8ec", "ffffff"]), null, 0.0)
			c.rect(17, 17, 2, 2, roof[2])
			c.put(20, 22, GOLD[3])
		"barn":
			c.rect(4, 13, 26, 17, roof[2])
			for x in range(5, 30, 4):
				c.rect(x, 13, 1, 17, roof[1])
			c.poly([Vector2(1, 14), Vector2(8, 4), Vector2(26, 4), Vector2(33, 14)], Color("4a4c60"))
			c.line(8, 4, 26, 4, Color("74788a"))
			c.rect(11, 18, 12, 12, Color("f4ecd8"))
			c.line(11, 18, 22, 29, roof[2])
			c.line(22, 18, 11, 29, roof[2])
		"silo":
			c.lathe(13, 8, 30, func(_t): return 8.0, STEEL, null, null, 0.04)
			c.sphere(13, 9, 8, 7, Px.ramp(["2c3048", "5a6480", "cf2f3a", "f15b47"]), null, 0.03)
			for y in [14, 19, 24]:
				c.line(5, y, 21, y, STEEL[1])
			c.rect(23, 18, 8, 12, WOOD[2])
			c.rect(23, 18, 8, 2, WOOD[3])
		"windmill":
			c.poly([Vector2(10, 30), Vector2(13, 12), Vector2(21, 12), Vector2(24, 30)], Color("f4ecd8"))
			c.poly([Vector2(17, 12), Vector2(21, 12), Vector2(24, 30), Vector2(18, 30)], Color("cfc4b4"))
			c.poly([Vector2(11, 12), Vector2(17, 5), Vector2(23, 12)], roof[2])
			c.rect(15, 23, 5, 7, WOOD[1])
			var hub = Vector2(17, 12)
			for a in 4:
				var q = a * PI / 2.0 + 0.5
				var tip = hub + Vector2(cos(q), sin(q)) * 13
				c.line(hub.x, hub.y, tip.x, tip.y, WOOD[1], 2)
				c.line(hub.x + cos(q + 0.5) * 6, hub.y + sin(q + 0.5) * 6, tip.x + cos(q + 1.0) * 2, tip.y + sin(q + 1.0) * 2, Color("e4e8ec"), 2)
		"greenhouse":
			var glass = Color("a8e0f0")
			c.poly([Vector2(3, 14), Vector2(17, 4), Vector2(31, 14)], glass)
			c.rect(4, 14, 26, 15, glass)
			c.line(3, 14, 17, 4, STEEL[3])
			c.line(31, 14, 17, 4, STEEL[3])
			for x in range(4, 31, 6):
				c.rect(x, 14, 1, 15, STEEL[3])
			c.rect(4, 14, 26, 1, STEEL[3])
			for x in [8, 15, 22, 27]:
				c.rect(x, 22, 2, 7, A.LEAF[2])
				c.rect(x - 1, 20, 4, 3, A.LEAF[3])
				c.put(x, 21, A.RED[3])
			c.rect(4, 28, 26, 2, WOOD[1])
		"lab":
			c.rect(4, 12, 26, 18, Color("dfe4ea"))
			c.rect(4, 12, 26, 3, Color("a4a8b4"))
			c.rect(4, 12, 26, 1, Color.WHITE)
			c.rect(14, 21, 6, 9, Color("2f72a8"))
			for x in [7, 24]:
				c.rect(x, 18, 4, 4, Color("7fe8ff"))
			c.sphere(17, 11, 7, 7, STEEL, null, 0.03)
			c.ellipse(17, 18, 4, 4, Color("ffe066"))
			radiation_sign(c, 17, 18, 3.5, DARK)
			c.line(24, 8, 28, 2, STEEL[3])
			c.put(28, 1, GLOW)


# --- Terrain -------------------------------------------------------------------

## Tiling value noise: every lattice wraps, so the 128px tile has no seams.
static func wrap_noise(x: float, y: float, cells: int, seed: int) -> float:
	var fx = x * cells
	var fy = y * cells
	var ix = int(floor(fx))
	var iy = int(floor(fy))
	var tx = fx - ix
	var ty = fy - iy
	tx = tx * tx * (3 - 2 * tx)
	ty = ty * ty * (3 - 2 * ty)
	var h = func(a: int, b: int) -> float:
		var aa = posmod(a, cells)
		var bb = posmod(b, cells)
		var v = int((aa * 7349 + bb * 9151 + seed * 113) * 2654435761) & 0xffffff
		v = (v ^ (v >> 7)) * 1103515245 & 0xffffff
		return float(v) / float(0xffffff)
	return lerp(lerp(h.call(ix, iy), h.call(ix + 1, iy), tx), lerp(h.call(ix, iy + 1), h.call(ix + 1, iy + 1), tx), ty)


static func ground(c, kind: int) -> void:
	var s = c.w
	var pal = [
		Px.ramp(["2f6b3a", "3a7f3e", "4a9444", "5ea84a"]),
		Px.ramp(["3b4a34", "4c5a38", "5f6a3e", "767a46"]),
		Px.ramp(["2a2a3a", "34344a", "40405a", "4c4e68"]),
	][kind]
	var patch = [Color("6b4a2c"), Color("3a5a50"), Color("20202e")][kind]
	var patch2 = [Color("8a6438"), Color("2f8a64"), Color("2a2a3c")][kind]
	for y in s:
		for x in s:
			var u = float(x) / s
			var v = float(y) / s
			var n = wrap_noise(u, v, 4, 1 + kind) * 0.5 + wrap_noise(u, v, 8, 2 + kind) * 0.3 + wrap_noise(u, v, 16, 3) * 0.2
			var b = wrap_noise(u, v, 3 + kind * 4, 9 + kind)
			var d = (Px.BAYER[(y & 3) * 4 + (x & 3)] / 15.0 - 0.5) * 0.06
			var col = pal[clamp(int((n + d - 0.28) * 6.0), 0, 3)]
			if b + d * 0.5 > (9.0 if kind == 0 else 0.76):
				col = patch if b < 0.85 - kind * 0.03 else patch2
			c.put(x, y, col)
	var rng = RandomNumberGenerator.new()
	rng.seed = 77 + kind
	if kind == 0:
		for i in 90:
			var x = rng.randi_range(0, s - 1)
			var y = rng.randi_range(0, s - 1)
			c.put(x, y, pal[3].lightened(0.15))
			c.put((x + 1) % s, posmod(y - 1, s), pal[3])
			c.put(posmod(x - 1, s), posmod(y - 1, s), pal[3])
		for i in 7:
			var x = rng.randi_range(0, s - 1)
			var y = rng.randi_range(0, s - 1)
			var col = [Color("ffe066"), Color("f4ecd8"), Color("f07a9a")][i % 3]
			c.put(x, y, col)
	elif kind == 1:
		for i in 60:
			var x = rng.randi_range(0, s - 1)
			var y = rng.randi_range(0, s - 1)
			c.put(x, y, pal[0].darkened(0.2))
			c.put(x, posmod(y - 1, s), pal[3])
		for i in 12:
			c.put(rng.randi_range(0, s - 1), rng.randi_range(0, s - 1), GLOW_D)
	else:
		# concrete slabs with glowing cracks
		for k in [0, 64]:
			for i in s:
				c.put(i, k, pal[0].darkened(0.3))
				c.put(k, i, pal[0].darkened(0.3))
				c.put(i, (k + 1) % s, pal[3])
				c.put((k + 1) % s, i, pal[3])
		for k in 4:
			var x = rng.randi_range(0, s - 1)
			var y = rng.randi_range(0, s - 1)
			for i in 16:
				x = posmod(x + rng.randi_range(-1, 1), s)
				y = posmod(y + 1, s)
				c.put(x, y, GLOW_D if k == 0 else DARK)


static func prop(c, id: String) -> void:
	match id:
		"dirt":
			c.ellipse(24, 12, 23, 10, Color("6b4a2c"))
			c.ellipse(14, 9, 12, 6, Color("6b4a2c"))
			c.ellipse(30, 14, 14, 7, Color("7a5632"))
			c.ellipse(20, 10, 11, 5, Color("8a6438"))
			for p in [[9, 8], [16, 14], [27, 6], [35, 13], [24, 17], [31, 9]]:
				c.rect(p[0], p[1], 2, 1, Color("5a3a24"))
		"fence":
			for x in [4, 18, 32]:
				c.rect(x, 4, 3, 18, WOOD[2])
				c.rect(x, 4, 1, 18, WOOD[3])
			c.rect(0, 8, 40, 3, WOOD[3])
			c.rect(0, 14, 40, 3, WOOD[2])
		"hay":
			c.lathe(16, 3, 24, func(t): return 13.0 * sqrt(max(0.05, 1.0 - pow(t * 2.0 - 1.0, 4.0))), HAY, null, null, 0.2)
			for y in [8, 13, 18]:
				for x in range(3, 30, 2):
					c.tint(x, y, HAY[1])
		"tree":
			c.lathe(16, 26, 46, func(t): return 3.5 + t * 2.0, WOOD, null, null, 0.05)
			for b in [[16, 16, 14], [7, 20, 8], [25, 20, 8], [16, 9, 9]]:
				c.sphere(b[0], b[1], b[2], b[2] * 0.85, A.DGREEN, null, 0.15)
		"sunflower":
			c.line(8, 12, 8, 30, A.LEAF[2], 2)
			c.leaf(Vector2(8, 22), Vector2(15, 18), 2.5, A.LEAF)
			for a in 10:
				var q = a * TAU / 10.0
				c.ellipse(8 + cos(q) * 5.5, 9 + sin(q) * 5.5, 2, 2, GOLD[3])
			c.sphere(8, 9, 4, 4, WOOD, null, 0.1)
		"rock":
			c.sphere(12, 12, 11, 8, STONE, null, 0.08)
			c.sphere(19, 15, 5, 4, STONE, null, 0.08)
		"wheelbarrow":
			c.poly([Vector2(3, 8), Vector2(29, 8), Vector2(23, 18), Vector2(7, 18)], A.RED[2])
			c.poly([Vector2(3, 8), Vector2(29, 8), Vector2(28, 10), Vector2(4, 10)], A.RED[3])
			c.sphere(17, 21, 4, 4, Px.ramp(["140c1c", "48405c"]), null, 0.0)
			c.line(0, 6, 8, 14, WOOD[2], 2)
		"deadtree":
			c.line(14, 44, 15, 18, WOOD[1], 5)
			c.line(15, 22, 4, 10, WOOD[1], 3)
			c.line(15, 18, 24, 6, WOOD[1], 3)
			c.line(8, 15, 3, 16, WOOD[1], 2)
			c.line(20, 12, 27, 13, WOOD[1], 2)
			c.line(16, 22, 16, 34, WOOD[2])
		"reeds":
			for x in [3, 7, 11, 15, 19]:
				var t = 8 + (x * 3) % 9
				c.line(x, 28, x + 1, t, A.DGREEN[2])
				c.rect(x, t - 3, 2, 5, WOOD[2])
		"barrel":
			c.lathe(9, 4, 26, func(t): return 8.0 + sin(t * PI) * 1.0, RADBARREL, null, null, 0.04)
			c.ellipse(9, 5, 8, 2.5, RADBARREL[0])
			c.ellipse(9, 5, 6, 1.5, GLOW)
			c.rect(1, 12, 17, 1, RADBARREL[0])
			c.rect(1, 20, 17, 1, RADBARREL[0])
			radiation_sign(c, 9, 16, 3.5, DARK)
		"tiltsign":
			c.line(10, 30, 10, 12, WOOD[2], 2)
			c.poly([Vector2(10, 0), Vector2(21, 11), Vector2(10, 22), Vector2(-1, 11)], Color("ffe066"))
			radiation_sign(c, 10, 11, 5, DARK)
		"toxicpool":
			c.ellipse(24, 12, 23, 11, Color("2f8a64"))
			c.ellipse(23, 11, 19, 8, GLOW_D)
			c.ellipse(21, 10, 12, 4, GLOW)
			c.rect(30, 8, 2, 2, Color.WHITE)
		"barrier":
			c.poly([Vector2(4, 4), Vector2(32, 4), Vector2(36, 22), Vector2(0, 22)], STONE[2])
			c.rect(4, 4, 28, 2, STONE[3])
			for x in range(4, 34, 8):
				c.poly([Vector2(x, 10), Vector2(x + 4, 10), Vector2(x, 16), Vector2(x - 4, 16)], Color("ffe066"))
		"pipe":
			c.lathe(24, 6, 22, func(_t): return 24.0, STEEL, null, null, 0.03)
			c.rect(14, 5, 4, 18, STEEL[1])
			c.rect(32, 5, 4, 18, STEEL[1])
			c.rect(4, 17, 3, 8, GLOW)
		"tower":
			c.lathe(26, 0, 62, func(t): return 13.0 + pow(abs(t - 0.3), 1.6) * 18.0, STONE, null, null, 0.05)
			for i in 3:
				c.tint(18 + i * 8, 8, GLOW_D)
			c.rect(10, 18, 32, 2, Color("cf2f3a"))
		"crate":
			c.rect(1, 3, 24, 22, WOOD[2])
			c.rect(1, 3, 24, 3, WOOD[3])
			c.rect(1, 22, 24, 3, WOOD[1])
			c.line(1, 5, 24, 23, WOOD[1], 2)


# --- Interface -----------------------------------------------------------------

## Dark plank sign with brass corners. The fill is flat so it can stretch cleanly.
static func panel(c, base: Array) -> void:
	var s = c.w
	c.rect(0, 0, s, s, base[1])
	c.rect(1, 1, s - 2, 1, base[3])
	c.rect(1, 1, 1, s - 2, base[3])
	c.rect(1, s - 2, s - 2, 1, base[0])
	c.rect(s - 2, 1, 1, s - 2, base[0])
	for q in [[0, 0], [s - 4, 0], [0, s - 4], [s - 4, s - 4]]:
		c.rect(q[0], q[1], 4, 4, GOLD[2])
		c.rect(q[0], q[1], 3, 1, GOLD[3])
		c.put(q[0] + 1, q[1] + 1, GOLD[0])


static func button(c, top: Color, mid: Color, bot: Color) -> void:
	var s = c.w
	c.rect(1, 0, s - 2, s, DARK)
	c.rect(0, 1, s, s - 2, DARK)
	c.rect(1, 1, s - 2, s - 2, mid)
	c.rect(1, 1, s - 2, 2, top)
	c.rect(1, s - 3, s - 2, 2, bot)


# --- Story art (320x180, displayed at 2x) --------------------------------------

static func sky(c, a: Color, b: Color, hz: int) -> void:
	for y in c.h:
		var t = clamp(float(y) / hz, 0.0, 1.0)
		for x in c.w:
			var d = (Px.BAYER[(y & 3) * 4 + (x & 3)] / 15.0 - 0.5) * 0.14
			var q = round(clamp(t + d, 0.0, 1.0) * 7.0) / 7.0
			c.put(x, y, a.lerp(b, q))


static func hills(c, base_y: float, amp: float, freq: float, col: Color, seed: float = 0.0) -> void:
	for x in c.w:
		var top = base_y + sin(x * freq + seed) * amp + sin(x * freq * 2.3 + seed * 2.0) * amp * 0.4
		for y in range(int(top), c.h):
			c.put(x, y, col)


static func cooling_tower(c, x: int, base: int, s: float, col: Color, col2: Color) -> void:
	var h = int(44 * s)
	c.lathe(x, base - h, base, func(t): return (10.0 + pow(abs(t - 0.32), 1.6) * 22.0) * s, [col2, col2, col, col], null, null, 0.08)


static func barn(c, x: int, y: int, wall: Color, roof: Color) -> void:
	c.rect(x, y, 44, 26, wall)
	for i in range(0, 44, 4):
		c.rect(x + i, y, 1, 26, wall.darkened(0.2))
	c.poly([Vector2(x - 4, y + 1), Vector2(x + 10, y - 14), Vector2(x + 34, y - 14), Vector2(x + 48, y + 1)], roof)
	c.rect(x + 16, y + 10, 12, 16, Color("f4ecd8").lerp(wall, 0.3))
	c.line(x + 16, y + 10, x + 27, y + 25, wall)
	c.line(x + 27, y + 10, x + 16, y + 25, wall)


static func crop_rows(c, hz: int, soil: Color, soil2: Color, plant: Color) -> void:
	for y in range(hz, c.h):
		for x in c.w:
			var t = float(y - hz) / (c.h - hz)
			var u = (x - c.w / 2.0) / (0.15 + t * 0.85)
			var band = fposmod(u, 34.0)
			c.put(x, y, soil if band < 17 else soil2)
			if band > 20 and band < 31 and (y + int(x * 0.5)) % 4 == 0:
				c.put(x, y, plant)


static func moon(c, x: int, y: int, r: int, col: Color) -> void:
	c.ellipse(x, y, r + 5, r + 5, col.darkened(0.55))
	c.ellipse(x, y, r + 2, r + 2, col.darkened(0.25))
	c.ellipse(x, y, r, r, col)
	c.ellipse(x - 3, y + 2, 2.5, 2.5, col.darkened(0.12))
	c.ellipse(x + 4, y - 3, 3, 3, col.darkened(0.12))


static func stars(c, n: int, hz: int) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = 5
	for i in n:
		c.put(r.randi_range(0, c.w), r.randi_range(0, hz), Color("f4ecd8") if i % 3 else Color("7fe8ff"))


static func story(c, id: int, spr: Callable) -> void:
	match id:
		0:  # a quiet valley, and the plant on the horizon
			sky(c, Color("4fa8e0"), Color("ffe6a8"), 96)
			c.ellipse(60, 40, 16, 16, Color("fff4c0"))
			cooling_tower(c, 236, 100, 1.0, Color("d4d8dc"), Color("9aa0ac"))
			cooling_tower(c, 276, 100, 0.8, Color("d4d8dc"), Color("9aa0ac"))
			for i in 7:
				c.ellipse(240 + i * 3, 50 - i * 5, 7 + i, 5 + i, Color(1, 1, 1))
			hills(c, 96, 5, 0.03, Color("6fb050"), 1.0)
			hills(c, 104, 3, 0.05, Color("4a9444"), 2.0)
			barn(c, 52, 84, Color("cf2f3a"), Color("5a3428"))
			crop_rows(c, 112, Color("8a5a34"), Color("6b4228"), Color("7fd04b"))
			c.stamp(spr.call("hank", 1.0), 180, 118)
		1:  # the accident
			sky(c, Color("0d0a22"), Color("3a2050"), 110)
			stars(c, 60, 80)
			moon(c, 66, 36, 13, Color("e8ecd0"))
			cooling_tower(c, 196, 116, 1.5, Color("6a6a88"), Color("3a3a58"))
			cooling_tower(c, 268, 116, 1.25, Color("6a6a88"), Color("3a3a58"))
			c.line(180, 60, 188, 80, GLOW, 2)
			c.line(188, 80, 182, 100, GLOW, 2)
			c.line(182, 100, 192, 116, GLOW, 2)
			hills(c, 112, 3, 0.04, Color("1f2238"), 1.0)
			c.rect(0, 118, 320, 62, Color("1a1c30"))
			for y in range(118, 180):
				var t = float(y - 118) / 62.0
				var cx = 188.0 - t * 110.0 + sin(t * 7.0) * 12.0
				var w = 6.0 + t * 26.0
				for x in range(int(cx - w), int(cx + w)):
					var e = abs(x - cx) / w
					c.put(x, y, GLOW if e < 0.45 and (x + y) % 3 else (GLOW_D if e < 0.8 else Color("1f6b3d")))
			for i in 6:
				c.rect(150 - i * 22, 128 + i * 8, 2, 2, Color("f4ffc0"))
		2:  # the rise
			sky(c, Color("0a0f22"), Color("1f4a3a"), 110)
			stars(c, 50, 70)
			moon(c, 256, 34, 15, Color("d8ff90"))
			barn(c, 40, 88, Color("3a1a30"), Color("1a0f20"))
			hills(c, 108, 3, 0.05, Color("12261f"), 3.0)
			crop_rows(c, 112, Color("1f2a24"), Color("161f20"), GLOW_D)
			var row = [["carrot", 96, 106], ["pea", 130, 122], ["tomato", 148, 104], ["onion", 196, 110], ["potato", 226, 122], ["corn", 262, 104], ["beet", 62, 128], ["pea", 176, 132]]
			for r in row:
				var s = spr.call(r[0], 0.0)
				c.ellipse(r[1] + s.w / 2, r[2] + s.h - 3, s.w * 0.6, 4, Color("1f6b3d"))
				c.stamp(s, r[1], r[2])
		3:  # hank takes up the scythe
			sky(c, Color("1a0f2e"), Color("e0602a"), 120)
			c.ellipse(160, 118, 56, 56, Color("ffcb6a"))
			c.ellipse(160, 118, 46, 46, Color("fff0a8"))
			cooling_tower(c, 40, 124, 1.0, Color("2a1a3a"), Color("2a1a3a"))
			cooling_tower(c, 280, 124, 1.2, Color("2a1a3a"), Color("2a1a3a"))
			hills(c, 120, 4, 0.04, Color("2a1a3a"), 1.0)
			c.rect(0, 136, 320, 44, Color("1a1024"))
			var left = [["carrot", 22, 136], ["tomato", 54, 128], ["potato", 8, 150], ["corn", 80, 134], ["pea", 100, 156], ["onion", 50, 150]]
			for r in left:
				c.stamp(spr.call(r[0], 0.0), r[1], r[2])
			var right = [["broccoli", 256, 124], ["eggplant", 232, 136], ["beet", 280, 148], ["chili", 210, 148], ["garlic", 244, 154], ["pea", 200, 160]]
			for r in right:
				c.stamp(spr.call(r[0], 0.0), r[1], r[2], true)
			var hero = spr.call("hank", 1.0)
			c.stamp(hero, 146, 124)
			c.line(171, 158, 180, 122, WOOD[3], 2)
			for a in 14:
				var q = -2.7 + a * 0.13
				c.ellipse(170 + cos(q) * 13, 126 + sin(q) * 8, 1.5, 1.5, STEEL[3])
		4:  # victory: the valley heals
			sky(c, Color("5fb0e8"), Color("ffd8a8"), 100)
			c.ellipse(246, 60, 20, 20, Color("fff4c0"))
			cooling_tower(c, 60, 100, 0.9, Color("c4c8cc"), Color("9aa0ac"))
			c.line(44, 62, 76, 100, A.RED[2], 2)
			c.line(76, 62, 44, 100, A.RED[2], 2)
			hills(c, 96, 5, 0.03, Color("7fc85a"), 2.0)
			hills(c, 104, 3, 0.05, Color("5ca84a"), 4.0)
			barn(c, 214, 84, Color("cf2f3a"), Color("5a3428"))
			crop_rows(c, 112, Color("8a5a34"), Color("6b4228"), Color("9cf04b"))
			var i = 0
			for n in ["hank", "mabel", "rosa", "tucker"]:
				c.stamp(spr.call(n, 1.0), 118 + i * 24, 122 + (i % 2) * 4)
				i += 1
			for s in [[100, 136], [230, 130], [80, 150], [250, 148], [160, 164]]:
				var g = spr.call("sunflower", 0.0)
				c.stamp(g, s[0], s[1])


## A radioactive strongbox: green bands and a crystal for a lock.
static func xp_chest(c) -> void:
	chest(c)
	var band = Px.ramp(["1f6b3d", "4fd13a", "b8ff3a", "f4ffc0"])
	for x in [4, 20]:
		c.rect(x, 2, 2, 19, band[1])
		c.rect(x, 2, 1, 19, band[2])
	c.rect(2, 9, 22, 1, band[1])
	c.poly([Vector2(13, 5), Vector2(18, 10), Vector2(13, 17), Vector2(8, 10)], band[1])
	c.poly([Vector2(13, 5), Vector2(8, 10), Vector2(13, 10)], band[3])
	c.poly([Vector2(13, 5), Vector2(13, 10), Vector2(18, 10)], band[2])


# --- Store art ---------------------------------------------------------------

## Key art for the store page: dusk over the valley, the horde closing in on Hank.
static func key_art(c, spr: Callable) -> void:
	var w: int = c.w
	var h: int = c.h
	var hz = int(h * 0.60)
	sky(c, Color("120a2a"), Color("ff7a2a"), hz)
	var cx = w / 2
	c.ellipse(cx, hz - 4, h * 0.25, h * 0.25, Color("ffcb6a"))
	c.ellipse(cx, hz - 4, h * 0.20, h * 0.20, Color("fff0a8"))
	var dark = Color("2a1638")
	var towers: Array = [int(w * 0.13), int(w * 0.87)]
	for tx in towers:
		cooling_tower(c, tx, hz + 8, h / 150.0, dark, dark)
		# toxic plume
		for i in 9:
			var a = 1.0 - i / 9.0
			var pc = Color("4fd13a").lerp(Color("2a1638"), 1.0 - a)
			c.ellipse(tx + sin(i * 0.9) * 5.0 + i * 2.5, hz - h * 0.30 - i * h * 0.035, 5 + i * 1.3, 3 + i, pc)
		c.line(tx - 6, hz - h * 0.22, tx + 2, hz - h * 0.08, GLOW, 2)
		c.line(tx + 2, hz - h * 0.08, tx - 4, hz + 4, GLOW, 2)
	hills(c, hz + 2, 3, 0.04, dark, 1.0)
	c.rect(0, hz + 8, w, h - hz - 8, Color("1a1024"))
	# glowing furrows converging on the reactor
	for y in range(hz + 8, h):
		var t = float(y - hz - 8) / max(h - hz - 8, 1)
		for x in w:
			var u = (x - cx) / (0.15 + t * 0.85)
			if fposmod(u, 46.0) < 3.0 and (x + y) % 2 == 0:
				c.put(x, y, Color("1f6b3d"))
	# bosses loom behind the crowd
	c.stamp(spr.call("boss_gourd", 0.0), int(w * 0.02), hz - 62)
	if w < 400:
		c.stamp(spr.call("boss_corn", 0.0), w - 112, hz - 76, true)
	# the horde, back rows first
	var rows: Array = [
		[["carrot", 0.32], ["tomato", 0.40], ["onion", 0.60], ["corn", 0.68], ["pea", 0.50]],
		[["potato", 0.22], ["pea", 0.34], ["eggplant", 0.72], ["garlic", 0.80], ["chili", 0.62]],
		[["beet", 0.13], ["chili", 0.30], ["carrot", 0.70], ["tomato", 0.88]],
	]
	var ry = hz + 4
	for row in rows:
		for e in row:
			var s = spr.call(e[0], 0.0)
			c.stamp(s, int(w * float(e[1])) - s.w / 2, ry, float(e[1]) > 0.5)
		ry += int(h * 0.075)
	# hero, large
	var hero = spr.call("hank", 1.0).scaled(2)
	var hx: int = cx - hero.w / 2
	var hy: int = h - hero.h - int(h * 0.05)
	c.ellipse(cx, hy + hero.h - 6, 30, 7, Color("4fd13a"))
	c.ellipse(cx, hy + hero.h - 6, 25, 5, Color(0.04, 0.03, 0.08))
	c.stamp(hero, hx, hy)
	var tip = Vector2(hx + 64, hy - 10)
	c.line(hx + 42, hy + 64, tip.x, tip.y, DARK, 5)
	c.line(hx + 42, hy + 64, tip.x, tip.y, WOOD[3], 3)
	for a in 26:
		var q = -3.0 + a * 0.07
		var sz: float = maxf(0.8, 3.2 - a * 0.1)
		c.ellipse(tip.x - 7 + cos(q) * 22, tip.y + 8 + sin(q) * 16, sz + 1.0, sz + 1.0, DARK)
	for a in 26:
		var q = -3.0 + a * 0.07
		var sz: float = maxf(0.8, 3.2 - a * 0.1)
		c.ellipse(tip.x - 7 + cos(q) * 22, tip.y + 8 + sin(q) * 16, sz, sz, STEEL[3 if a % 3 else 4])
	# foreground, big and close
	var fg: Array = [["tomato", 0.03, 54], ["broccoli", 0.80, 78], ["pea", 0.25, 40], ["eggplant", 0.66, 66]]
	for e in fg:
		var b = spr.call(e[0], 0.0).scaled(2)
		c.stamp(b, int(w * float(e[1])) - 10, h - int(e[2]), float(e[1]) > 0.5)
