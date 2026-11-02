## Tiny pixel-art rasteriser used by the asset generator.
## Everything is drawn at 1:1 onto a colour buffer. Volumes are shaded with a
## quantised colour ramp (with a touch of Bayer dither), then a selective
## outline is added, which is what gives the sprites their hand-pixelled look.
extends RefCounted

const OUTLINE := Color("140c1c")
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const LIGHT := Vector3(-0.55, -0.68, 0.5)

var w: int
var h: int
var buf: PackedColorArray


func _init(width: int, height: int) -> void:
	w = width
	h = height
	buf = PackedColorArray()
	buf.resize(w * h)
	buf.fill(Color(0, 0, 0, 0))


static func ramp(hexes: Array) -> Array:
	var out = []
	for s in hexes:
		out.append(Color(s))
	return out


func inb(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func put(x: int, y: int, c: Color) -> void:
	if inb(x, y):
		buf[y * w + x] = c


func get_px(x: int, y: int) -> Color:
	return buf[y * w + x] if inb(x, y) else Color(0, 0, 0, 0)


func filled(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.5


## Paint only over what already exists (for surface detail).
func tint(x: int, y: int, c: Color) -> void:
	if filled(x, y):
		put(x, y, c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for j in rh:
		for i in rw:
			put(x + i, y + j, c)


func line(x0: float, y0: float, x1: float, y1: float, c: Color, thick: int = 1) -> void:
	var steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
	for s in steps + 1:
		var t = float(s) / float(max(steps, 1))
		var x = int(round(lerp(x0, x1, t)))
		var y = int(round(lerp(y0, y1, t)))
		if thick <= 1:
			put(x, y, c)
		else:
			var a = -(thick - 1) / 2
			for j in thick:
				for i in thick:
					put(x + a + i, y + a + j, c)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 2):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
			var dx = (x + 0.5 - cx) / max(rx, 0.01)
			var dy = (y + 0.5 - cy) / max(ry, 0.01)
			if dx * dx + dy * dy <= 1.0:
				put(x, y, c)


func _shade(n: Vector3, x: int, y: int, r: Array, dither: float) -> Color:
	var l: float = n.normalized().dot(LIGHT.normalized()) * 0.5 + 0.5
	l = pow(clamp(l, 0.0, 1.0), 1.15)
	l += (BAYER[(y & 3) * 4 + (x & 3)] / 15.0 - 0.5) * dither
	var i = int(clamp(l * r.size(), 0, r.size() - 1))
	return r[i]


## Sphere/ellipsoid with quantised lighting. `rim` is an optional glow colour
## that wraps the lower-right edge: the mutant "radiation" signature.
func sphere(cx: float, cy: float, rx: float, ry: float, r: Array, rim = null, dither: float = 0.1) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 2):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
			var dx = (x + 0.5 - cx) / max(rx, 0.01)
			var dy = (y + 0.5 - cy) / max(ry, 0.01)
			var d = dx * dx + dy * dy
			if d > 1.0:
				continue
			var n = Vector3(dx, dy, sqrt(max(0.0, 1.0 - d)))
			if rim != null and d > pow(1.0 - 1.7 / min(rx, ry), 2.0) and dx * 0.7 + dy * 0.7 > 0.5:
				put(x, y, rim)
			else:
				put(x, y, _shade(n, x, y, r, dither))


## Solid of revolution: `profile(t)` gives the half width for t in 0..1 running
## top to bottom, `bend(t)` shifts the centre sideways. Nearly every vegetable
## in the game is one of these.
func lathe(cx: float, y0: float, y1: float, profile: Callable, r: Array, rim = null, bend = null, dither: float = 0.1) -> void:
	var ya = int(floor(y0))
	var yb = int(ceil(y1))
	for y in range(ya, yb):
		var t: float = clamp((y + 0.5 - y0) / max(y1 - y0, 0.01), 0.0, 1.0)
		var hw: float = profile.call(t)
		if hw <= 0.05:
			continue
		var c: float = cx + (bend.call(t) if bend != null else 0.0)
		for x in range(int(floor(c - hw)), int(ceil(c + hw))):
			var nx = (x + 0.5 - c) / hw
			if abs(nx) > 1.0:
				continue
			var ny = t * 2.0 - 1.0
			var n = Vector3(nx, ny * 0.85, sqrt(max(0.02, 1.0 - nx * nx)) * sqrt(max(0.05, 1.0 - ny * ny * 0.8)))
			if rim != null and nx > 1.0 - 1.7 / hw and ny > -0.25:
				put(x, y, rim)
			else:
				put(x, y, _shade(n, x, y, r, dither))


func poly(pts: Array, c: Color) -> void:
	var miny = 99999.0
	var maxy = -99999.0
	for p in pts:
		miny = min(miny, p.y)
		maxy = max(maxy, p.y)
	for y in range(int(floor(miny)), int(ceil(maxy)) + 1):
		var nodes = []
		var j = pts.size() - 1
		for i in pts.size():
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[j]
			var yy = y + 0.5
			if (a.y < yy and b.y >= yy) or (b.y < yy and a.y >= yy):
				nodes.append(a.x + (yy - a.y) / (b.y - a.y) * (b.x - a.x))
			j = i
		nodes.sort()
		var k = 0
		while k + 1 < nodes.size():
			for x in range(int(round(nodes[k])), int(round(nodes[k + 1]))):
				put(x, y, c)
			k += 2


## Leaf: a tapered blade from a to b, with a lighter midrib.
func leaf(a: Vector2, b: Vector2, width: float, r: Array) -> void:
	var dir = b - a
	var nrm = dir.orthogonal().normalized()
	var mid = a + dir * 0.45
	poly([a, mid + nrm * width, b, mid - nrm * width], r[1])
	poly([a, mid + nrm * width * 0.1, b, mid - nrm * width], r[2])
	line(a.x, a.y, b.x, b.y, r[r.size() - 1])


## Selective outline: each edge takes a very dark version of what it touches,
## so a carrot gets a warm line and a cabbage a cool one.
func outline(strength: float = 0.82) -> void:
	var src = buf.duplicate()
	for y in h:
		for x in w:
			if src[y * w + x].a > 0.5:
				continue
			var best = Color(0, 0, 0, 0)
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var px: int = x + o.x
				var py: int = y + o.y
				if px >= 0 and py >= 0 and px < w and py < h and src[py * w + px].a > 0.5:
					best = src[py * w + px]
					break
			if best.a > 0.5:
				buf[y * w + x] = best.lerp(OUTLINE, strength)


## Soft contact shadow, placed under everything already drawn.
func shadow(cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx = (x + 0.5 - cx) / rx
			var dy = (y + 0.5 - cy) / ry
			var d = dx * dx + dy * dy
			if d <= 1.0 and inb(x, y) and get_px(x, y).a < 0.1:
				put(x, y, Color(0.04, 0.03, 0.08, 0.34 if d < 0.6 else 0.2))


## Blit another canvas, used to compose scenes out of sprites.
func stamp(o, ox: int, oy: int, flip: bool = false) -> void:
	for y in o.h:
		for x in o.w:
			var c: Color = o.buf[y * o.w + (o.w - 1 - x if flip else x)]
			if c.a <= 0.01:
				continue
			if not inb(ox + x, oy + y):
				continue
			if c.a >= 0.99:
				put(ox + x, oy + y, c)
			else:
				put(ox + x, oy + y, get_px(ox + x, oy + y).lerp(Color(c.r, c.g, c.b, 1), c.a))


func to_image() -> Image:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			img.set_pixel(x, y, buf[y * w + x])
	return img


func white_silhouette():
	var o = get_script().new(w, h)
	for i in buf.size():
		if buf[i].a > 0.5:
			o.buf[i] = Color(1, 1, 1, 1)
	return o


func scaled(n: int):
	var o = get_script().new(w * n, h * n)
	for y in o.h:
		for x in o.w:
			o.buf[y * o.w + x] = buf[(y / n) * w + (x / n)]
	return o
