## Runs every mutant from one central loop: pooled sprites, a spatial hash and
## no per-enemy nodes logic, which keeps hundreds of enemies cheap.
extends Node

const CELL := 48.0
const MAX_ALIVE := 320

class E:
	var id: String
	var data: Dictionary
	var pos: Vector2
	var push := Vector2.ZERO
	var hp: float
	var max_hp: float
	var dmg: float
	var speed: float
	var r: float
	var beh: String
	var spr: Sprite2D
	var phase: float
	var flash := 0.0
	var atk := 0.0
	var state := 0
	var state_t := 0.0
	var dir := Vector2.ZERO
	var size := 1.0
	var elite := false
	var boss := false
	var mid := false
	var dead := false
	var frames := 4
	var uid := 0
	var step := 0
	var enraged := false

var run: Node2D
var alive: Array[E] = []
var grid := {}
var pool: Array[Sprite2D] = []
var bullets: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var _uid := 0
var _frame := 0
var textures := {}
var boss_ref: E = null
var hp_mult := 1.0
var dmg_mult := 1.0


func setup(r: Node2D) -> void:
	run = r
	for id in DB.ENEMIES:
		var p := "res://assets/sprites/pickup_crate.png" if id == "crate" else "res://assets/sprites/enemy_%s.png" % id
		textures[id] = load(p)
	for s in ["kernel", "seed", "rad"]:
		textures["e_" + s] = load("res://assets/sprites/eproj_%s.png" % s)
	var st: Dictionary = run.stage
	hp_mult = float(st.hp) * pow(DB.RAD_HP, run.rad)
	dmg_mult = float(st.dmg) * pow(DB.RAD_DMG, run.rad)


func _get_sprite() -> Sprite2D:
	var s: Sprite2D
	if pool.is_empty():
		s = Sprite2D.new()
		run.world.add_child(s)
	else:
		s = pool.pop_back()
		s.visible = true
	return s


func spawn(id: String, pos: Vector2, opts: Dictionary = {}) -> E:
	if alive.size() >= MAX_ALIVE and not opts.get("force", false):
		return null
	var d: Dictionary = DB.ENEMIES[id]
	var e := E.new()
	_uid += 1
	e.uid = _uid
	e.id = id
	e.data = d
	e.pos = pos
	e.beh = d.beh
	e.boss = e.beh == "boss"
	e.phase = randf() * 4.0
	e.frames = int(d.get("frames", 4))
	var minutes: float = run.time / 60.0
	var growth: float = 1.0 if e.boss else 1.0 + minutes * 0.32 + minutes * minutes * 0.055
	e.max_hp = float(d.hp) * hp_mult * growth * float(opts.get("hp", 1.0))
	if id == "crate":
		e.max_hp = 1.0
	e.hp = e.max_hp
	e.dmg = float(d.dmg) * dmg_mult * (1.0 + minutes * 0.05)
	e.speed = float(d.spd) * randf_range(0.92, 1.08) * float(opts.get("speed", 1.0))
	e.size = float(opts.get("size", 1.0))
	e.r = float(d.r) * e.size
	e.elite = opts.get("elite", false)
	e.mid = opts.get("mid", false)
	e.atk = randf_range(0.6, 2.0)
	var s := _get_sprite()
	s.texture = textures[id]
	s.hframes = e.frames
	s.vframes = 2 if e.frames > 1 else 1
	s.frame = 0
	s.scale = Vector2(e.size, e.size)
	s.modulate = Color(0.72, 1.0, 0.6) if (e.elite or e.mid) else Color.WHITE
	s.position = pos
	e.spr = s
	alive.append(e)
	if e.boss:
		boss_ref = e
		e.state_t = 2.0
	return e


func _key(p: Vector2) -> int:
	return (int(floor(p.x / CELL)) + 32768) * 65536 + int(floor(p.y / CELL)) + 32768


func _rebuild_grid() -> void:
	grid.clear()
	for e in alive:
		var k := _key(e.pos)
		if grid.has(k):
			grid[k].append(e)
		else:
			grid[k] = [e]


## All live enemies whose body touches the circle.
func query(p: Vector2, radius: float) -> Array:
	var out := []
	var reach := radius + 44.0
	var x0 := int(floor((p.x - reach) / CELL))
	var x1 := int(floor((p.x + reach) / CELL))
	var y0 := int(floor((p.y - reach) / CELL))
	var y1 := int(floor((p.y + reach) / CELL))
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var k := (x + 32768) * 65536 + y + 32768
			if not grid.has(k):
				continue
			for e: E in grid[k]:
				if e.dead:
					continue
				var rr := radius + e.r
				if e.pos.distance_squared_to(p) <= rr * rr:
					out.append(e)
	return out


func nearest(p: Vector2, max_dist: float = 99999.0) -> E:
	var best: E = null
	var bd := max_dist * max_dist
	for e in alive:
		if e.beh == "crate":
			continue
		var d := e.pos.distance_squared_to(p)
		if d < bd:
			bd = d
			best = e
	return best


func random_on_screen() -> E:
	var view: Rect2 = run.view_rect().grow(-10)
	var picks: Array[E] = []
	for e in alive:
		if e.beh != "crate" and view.has_point(e.pos):
			picks.append(e)
	return picks.pick_random() if not picks.is_empty() else null


func update(dt: float) -> void:
	_frame += 1
	_rebuild_grid()
	var pp: Vector2 = run.player_pos
	var t: float = run.time
	var stagger := _frame % 3
	for i in range(alive.size() - 1, -1, -1):
		if i >= alive.size():
			continue
		var e := alive[i]
		if e.dead:
			continue
		if e.beh == "crate":
			if e.pos.distance_to(pp) > 620.0:
				_release(e, i)
			continue
		var to := pp - e.pos
		var dist := to.length()
		var d := to / maxf(dist, 0.001)
		var move := d * e.speed
		match e.beh:
			"ranged":
				e.atk -= dt
				if dist < 150.0:
					move = Vector2.ZERO if dist > 90.0 else -d * e.speed * 0.6
					if e.atk <= 0.0:
						e.atk = randf_range(2.4, 3.4)
						_shoot(e, d)
			"dash":
				match e.state:
					0:
						e.atk -= dt
						if dist < 130.0 and e.atk <= 0.0:
							e.state = 1
							e.state_t = 0.5
					1:
						move = Vector2.ZERO
						e.state_t -= dt
						e.flash = 0.03 if int(t * 16.0) % 2 == 0 else 0.0
						if e.state_t <= 0.0:
							e.state = 2
							e.state_t = 0.55
							e.dir = d
					2:
						move = e.dir * e.speed * 4.2
						e.state_t -= dt
						if e.state_t <= 0.0:
							e.state = 0
							e.atk = 2.5
			"explode":
				if e.state == 0 and dist < 28.0:
					e.state = 1
					e.state_t = 0.45
				if e.state == 1:
					move = Vector2.ZERO
					e.state_t -= dt
					e.flash = 0.03 if int(t * 22.0) % 2 == 0 else 0.0
					if e.state_t <= 0.0:
						run.fx.explosion(e.pos, 40.0, Color("ffae3a"))
						Audio.play("boom")
						if e.pos.distance_to(run.player_pos) < 42.0:
							run.hurt(e.dmg)
						_finish(e, i, false)
						continue
			"gas":
				e.atk -= dt
				if e.atk <= 0.0:
					e.atk = 2.6
					add_hazard(e.pos, 22.0, 0.0, 3.0, e.dmg * 0.5, Color(0.72, 1.0, 0.25, 0.32))
			"boss":
				move = _boss_ai(e, dt, d, dist)
		e.pos += (move + e.push) * dt
		e.push = e.push.move_toward(Vector2.ZERO, 420.0 * dt)
		# soft separation, staggered across frames
		if i % 3 == stagger and not e.boss:
			var k := _key(e.pos)
			if grid.has(k):
				for o: E in grid[k]:
					if o == e or o.boss:
						continue
					var sep := e.pos - o.pos
					var l := sep.length_squared()
					var mind := e.r + o.r
					if l < mind * mind and l > 0.01:
						e.pos += sep / sqrt(l) * minf(70.0 * dt * 3.0, 3.0)
		# recycle stragglers to the front of the horde
		if dist > 480.0:
			e.pos = run.spawn_point()
		if e.flash > 0.0:
			e.flash -= dt
		var f := int(t * (8.0 if e.beh != "boss" else 6.0) + e.phase) % e.frames
		e.spr.frame = f + (e.frames if e.flash > 0.0 else 0)
		e.spr.position = e.pos
		e.spr.flip_h = to.x < 0.0
		# contact damage
		if e.dmg > 0.0 and dist < e.r + 9.0:
			run.hurt(e.dmg)
	_update_bullets(dt)
	_update_hazards(dt)


func _shoot(e: E, d: Vector2) -> void:
	match String(e.data.shot):
		"tear":
			fire_bullet("rad", e.pos, d * 95.0, e.dmg * 0.8, 5.0, true)
		"kernel":
			fire_bullet("kernel", e.pos, d.rotated(0.2) * 125.0, e.dmg * 0.6, 4.0)
			fire_bullet("kernel", e.pos, d.rotated(-0.2) * 125.0, e.dmg * 0.6, 4.0)
		_:
			fire_bullet("seed", e.pos, d * 130.0, e.dmg * 0.8, 4.0)


func fire_bullet(kind: String, pos: Vector2, vel: Vector2, dmg: float, r: float, slow: bool = false) -> void:
	if bullets.size() > 260:
		return
	var s := Sprite2D.new()
	s.texture = textures["e_" + kind]
	s.position = pos
	s.z_index = 20
	run.add_child(s)
	bullets.append({"spr": s, "pos": pos, "vel": vel, "dmg": dmg, "r": r, "life": 6.0, "slow": slow})


func _update_bullets(dt: float) -> void:
	var pp: Vector2 = run.player_pos
	for i in range(bullets.size() - 1, -1, -1):
		var b := bullets[i]
		b.pos += b.vel * dt
		b.life -= dt
		b.spr.position = b.pos
		var hit: bool = b.pos.distance_to(pp) < float(b.r) + 8.0
		if hit:
			run.hurt(b.dmg)
			if b.slow:
				run.slow_t = 1.6
		if hit or b.life <= 0.0:
			b.spr.queue_free()
			bullets.remove_at(i)


func clear_bullets() -> void:
	for b in bullets:
		b.spr.queue_free()
	bullets.clear()


func add_hazard(pos: Vector2, r: float, warn: float, life: float, dmg: float, col: Color) -> void:
	hazards.append({"pos": pos, "r": r, "warn": warn, "warn0": maxf(warn, 0.01), "life": life, "dmg": dmg, "col": col, "tick": 0.0})


func _update_hazards(dt: float) -> void:
	var pp: Vector2 = run.player_pos
	for i in range(hazards.size() - 1, -1, -1):
		var h := hazards[i]
		if float(h.warn) > 0.0:
			h.warn = float(h.warn) - dt
			continue
		h.life = float(h.life) - dt
		h.tick = float(h.tick) - dt
		if float(h.dmg) > 0.0 and float(h.tick) <= 0.0 and pp.distance_to(h.pos) < float(h.r) + 6.0:
			h.tick = 0.5
			run.hurt(h.dmg)
		if float(h.life) <= 0.0:
			hazards.remove_at(i)


# --- Bosses ----------------------------------------------------------------------

func _radial(pos: Vector2, n: int, speed: float, dmg: float, kind: String, rot: float = 0.0) -> void:
	for k in n:
		var a := rot + TAU * k / n
		fire_bullet(kind, pos, Vector2.from_angle(a) * speed, dmg, 4.0)


func _summon(id: String, n: int, around: Vector2) -> void:
	for k in n:
		var p := around + Vector2.from_angle(TAU * k / n) * 60.0
		spawn(id, p, {"force": true})


## state = pattern, state_t = time left, step = counter. Returns the movement.
func _boss_ai(e: E, dt: float, d: Vector2, dist: float) -> Vector2:
	if not e.enraged and e.hp < e.max_hp * 0.5:
		e.enraged = true
		e.speed *= 1.3
		run.hud.banner(tr("BOSS_ENRAGED"), Color("ff5a4a"))
		run.fx.shake(6.0)
	e.state_t -= dt
	var rage := 0.7 if e.enraged else 1.0
	var bd: float = e.dmg * 0.6
	match e.id:
		"boss_gourd":
			match e.state:
				0:
					if e.state_t <= 0.0:
						e.state = 1
						e.state_t = 0.8 * rage
						e.dir = run.player_pos
						add_hazard(e.dir, 70.0, 0.8 * rage, 0.12, e.dmg, Color(1.0, 0.5, 0.15, 0.4))
					return d * e.speed
				1:
					var hop := 1.0 - maxf(e.state_t, 0.0) / (0.8 * rage)
					e.spr.offset.y = -sin(hop * PI) * 40.0
					e.pos = e.pos.lerp(e.dir, minf(1.0, dt * 7.0))
					if e.state_t <= 0.0:
						e.spr.offset.y = 0.0
						run.fx.explosion(e.pos, 70.0, Color("ffcb6a"))
						run.fx.shake(5.0)
						Audio.play("boom")
						_radial(e.pos, 16 if e.enraged else 12, 120.0, bd, "seed")
						e.step += 1
						if e.step % 3 == 0:
							_summon("carrot", 6, e.pos)
						e.state = 0
						e.state_t = 2.4 * rage
					return Vector2.ZERO
		"boss_corn":
			match e.state:
				0:
					if e.state_t <= 0.0:
						e.state = 1
						e.state_t = 1.5
						e.atk = 0.0
						e.step += 1
					return d * e.speed
				1:
					e.atk -= dt
					if e.atk <= 0.0:
						e.atk = 0.32 * rage
						_radial(e.pos, 14, 130.0, bd, "kernel", e.state_t * 2.0)
					if e.state_t <= 0.0:
						if e.step % 2 == 0:
							e.state = 2
							e.state_t = 0.7
							e.dir = d
							add_hazard(e.pos + d * 120.0, 44.0, 0.7, 0.1, 0.0, Color(1.0, 0.8, 0.2, 0.35))
						else:
							_summon("chili", 5, e.pos)
							e.state = 0
							e.state_t = 2.2 * rage
					return Vector2.ZERO
				2:
					if e.state_t <= 0.0:
						e.state = 3
						e.state_t = 0.8
						run.fx.shake(3.0)
					return Vector2.ZERO
				3:
					if e.state_t <= 0.0:
						e.state = 0
						e.state_t = 2.0 * rage
					return e.dir * e.speed * 8.0
		"boss_root":
			match e.state:
				0:
					if e.state_t <= 0.0:
						e.step += 1
						e.state = 1 + e.step % 3
						e.state_t = 2.6 if e.state == 2 else 0.5
						e.atk = 0.0
					return d * e.speed
				1:  # rad pools rain around the player
					if e.state_t <= 0.0:
						var n := 7 if e.enraged else 5
						for k in n:
							var off := Vector2.from_angle(randf() * TAU) * randf_range(0.0, 110.0)
							add_hazard(run.player_pos + off, 34.0, 1.0, 5.0, e.dmg * 0.5, Color(0.72, 1.0, 0.25, 0.42))
						e.state = 0
						e.state_t = 2.0 * rage
					return d * e.speed * 0.5
				2:  # spiral
					e.atk -= dt
					if e.atk <= 0.0:
						e.atk = 0.09
						var a: float = run.time * 5.0
						_radial(e.pos, 3 if e.enraged else 2, 110.0, bd, "rad", a)
					if e.state_t <= 0.0:
						e.state = 0
						e.state_t = 2.0 * rage
					return Vector2.ZERO
				3:  # the root calls its children
					if e.state_t <= 0.0:
						_summon("beet", 4, e.pos)
						_summon("pea", 8, run.player_pos + Vector2(0, -20))
						run.fx.shake(4.0)
						e.state = 0
						e.state_t = 2.0 * rage
					return Vector2.ZERO
	return d * e.speed


# --- Damage ----------------------------------------------------------------------

func damage(e: E, amount: float, from: Vector2 = Vector2.ZERO, knock: float = 0.0, slot = null) -> void:
	if e.dead:
		return
	var crit := randf() < 0.05 * float(run.stats.luck)
	var dealt := amount * randf_range(0.9, 1.1) * (2.0 if crit else 1.0)
	e.hp -= dealt
	e.flash = 0.05
	if slot != null:
		slot.done = float(slot.done) + dealt
	if knock > 0.0 and not e.boss:
		var away := (e.pos - from).normalized()
		e.push += away * knock * (0.3 if e.elite or e.mid else 1.0)
	run.fx.number(e.pos + Vector2(randf_range(-6, 6), -e.r), dealt, crit)
	if e.beh != "crate":
		Audio.play("hit", 0.2)
	if e.hp <= 0.0:
		var i := alive.find(e)
		if i >= 0:
			_finish(e, i, true)


func _finish(e: E, i: int, killed: bool) -> void:
	e.dead = true
	var col: Color = e.data.col
	if e.beh == "crate":
		run.fx.burst(e.pos, col, 8)
		run.drop_crate(e.pos)
	elif killed:
		run.kills += 1
		run.fx.burst(e.pos, col, 16 if e.boss else 7)
		Audio.play("kill", 0.2)
		run.drop_from(e)
		if e.beh == "split":
			for k in 2:
				spawn("pea", e.pos + Vector2.from_angle(randf() * TAU) * 12.0)
	_release(e, i)
	if e == boss_ref:
		boss_ref = null
		run.on_boss_dead(e)


func _release(e: E, i: int) -> void:
	e.dead = true
	e.spr.visible = false
	e.spr.offset = Vector2.ZERO
	pool.append(e.spr)
	alive.remove_at(i)


## The dynamite pickup: flatten everything on screen except big targets.
func nuke() -> void:
	var view: Rect2 = run.view_rect()
	for i in range(alive.size() - 1, -1, -1):
		if i >= alive.size():
			continue
		var e := alive[i]
		if not view.has_point(e.pos) or e.beh == "crate":
			continue
		if e.boss or e.mid or e.elite:
			damage(e, e.max_hp * 0.1)
		else:
			damage(e, 999999.0)
	clear_bullets()
