## Lightweight particles, rings, damage numbers and hazards, drawn in one pass.
extends Node2D

const MAX_PARTS := 500

var run: Node2D
var font: Font
var parts: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var nums: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var shake_amt := 0.0
var floor_layer: Node2D


func setup(r: Node2D) -> void:
	run = r
	font = UI.body_font()
	z_index = 40
	floor_layer = Node2D.new()
	floor_layer.z_index = -10
	floor_layer.draw.connect(_draw_floor)
	r.add_child(floor_layer)


func update(dt: float) -> void:
	for i in range(parts.size() - 1, -1, -1):
		var p := parts[i]
		p.life = float(p.life) - dt
		if float(p.life) <= 0.0:
			parts.remove_at(i)
			continue
		p.pos += p.vel * dt
		p.vel *= 1.0 - 4.0 * dt
	for i in range(rings.size() - 1, -1, -1):
		var q := rings[i]
		q.t = float(q.t) + dt * 3.2
		if float(q.t) >= 1.0:
			rings.remove_at(i)
	for i in range(nums.size() - 1, -1, -1):
		var n := nums[i]
		n.t = float(n.t) + dt
		n.pos.y -= dt * 22.0
		if float(n.t) > 0.55:
			nums.remove_at(i)
	for i in range(flashes.size() - 1, -1, -1):
		var f := flashes[i]
		f.life = float(f.life) - dt
		var k: float = maxf(float(f.life) / float(f.max), 0.0)
		f.spr.modulate.a = k
		if f.has("frames"):
			f.spr.frame = int((1.0 - k) * int(f.frames)) % int(f.frames)
		if float(f.life) <= 0.0:
			f.spr.queue_free()
			flashes.remove_at(i)
	if shake_amt > 0.0:
		shake_amt = maxf(0.0, shake_amt - dt * 18.0)
	queue_redraw()
	floor_layer.queue_redraw()


func shake(a: float) -> void:
	if Save.d.settings.shake:
		shake_amt = maxf(shake_amt, a)


func shake_offset() -> Vector2:
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt


func burst(pos: Vector2, col: Color, n: int) -> void:
	if parts.size() > MAX_PARTS:
		return
	for i in n:
		parts.append({
			"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30.0, 130.0),
			"life": randf_range(0.2, 0.5), "col": col if i % 3 else col.lightened(0.5), "s": 2.0 if i % 2 else 1.0,
		})


func explosion(pos: Vector2, r: float, col: Color) -> void:
	ring(pos, r, col)
	ring(pos, r * 0.6, Color.WHITE)
	burst(pos, col, 22)


func ring(pos: Vector2, r: float, col: Color) -> void:
	rings.append({"pos": pos, "r": r, "col": col, "t": 0.0})


func number(pos: Vector2, v: float, crit: bool) -> void:
	if not Save.d.settings.numbers or nums.size() > 70:
		return
	nums.append({"pos": pos, "txt": Save.fmt(round(v)), "t": 0.0, "crit": crit})


func text(pos: Vector2, s: String, col: Color) -> void:
	nums.append({"pos": pos, "txt": s, "t": -0.3, "crit": false, "col": col})


func sprite_flash(tex: Texture2D, pos: Vector2, rot: float, sc: float, life: float, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.rotation = rot
	s.scale = Vector2(sc, sc)
	s.modulate = col
	s.z_index = 30
	s.offset = Vector2(20, 0)
	run.add_child(s)
	flashes.append({"spr": s, "life": life, "max": life})


func bolt(tex: Texture2D, at: Vector2, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = 3
	s.position = at + Vector2(0, -48)
	s.modulate = col
	s.z_index = 30
	run.add_child(s)
	flashes.append({"spr": s, "life": 0.24, "max": 0.24, "frames": 3})


func _draw() -> void:
	for p in parts:
		var sz: float = p.s
		draw_rect(Rect2(p.pos, Vector2(sz, sz)), p.col)
	for q in rings:
		var t: float = q.t
		var c: Color = q.col
		c.a = 1.0 - t
		draw_arc(q.pos, float(q.r) * (0.3 + t * 0.7), 0, TAU, 36, c, 2.0, false)
	for n in nums:
		var col: Color = n.get("col", Color("ffe066") if n.crit else Color.WHITE)
		var sz := 16
		var a: float = clampf(1.0 - (float(n.t) - 0.25) / 0.3, 0.0, 1.0)
		col.a = a
		var out := Color(0.08, 0.05, 0.12, a)
		draw_string_outline(font, n.pos, n.txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 3, out)
		draw_string(font, n.pos, n.txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	# player health pip under the feet
	if run.alive_flag:
		var w := 26.0
		var at: Vector2 = run.player_pos + Vector2(-w / 2.0, 20)
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, 4)), Color("140c1c"))
		draw_rect(Rect2(at, Vector2(w * clampf(run.hp / float(run.stats.max_hp), 0.0, 1.0), 2)), Color("e8423a"))


func _draw_floor() -> void:
	if run == null:
		return
	for h in run.enemies.hazards:
		var c: Color = h.col
		var r: float = h.r
		if float(h.warn) > 0.0:
			var k: float = 1.0 - float(h.warn) / float(h.warn0)
			floor_layer.draw_arc(h.pos, r, 0, TAU, 40, c, 1.0, false)
			c.a *= 0.6
			floor_layer.draw_circle(h.pos, r * k, c)
		else:
			floor_layer.draw_circle(h.pos, r, c)
			c.a = minf(c.a * 2.0, 1.0)
			floor_layer.draw_arc(h.pos, r, 0, TAU, 40, c, 1.0, false)
