## The farmer's arsenal: firing logic and the player's projectiles.
extends Node

const GOLD := Color(1.0, 0.86, 0.35)

class Slot:
	var id := ""
	var level := 1
	var evolved := false
	var t := 0.5
	var s: Dictionary = {}
	var done := 0.0

class P:
	var spr: Sprite2D
	var pos: Vector2
	var vel: Vector2
	var dmg: float
	var life: float
	var pierce: int
	var r: float
	var knock: float
	var slot: Slot
	var hits := {}
	var homing := false
	var spin := 0.0
	var speed := 0.0
	var anim := 0

var run: Node2D
var slots: Array[Slot] = []
var passives := {}
var shots: Array[P] = []
var orbs: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var turrets: Array[Dictionary] = []
var queue: Array[Dictionary] = []
var orbit_angle := 0.0
var tex := {}


func setup(r: Node2D) -> void:
	run = r
	for t in ["fx_slash", "proj_pitchfork", "proj_pellet", "proj_sickle", "proj_bee", "proj_puddle", "proj_tractor", "fx_bolt", "proj_scarecrow"]:
		tex[t] = load("res://assets/sprites/%s.png" % t)


func has_weapon(id: String) -> Slot:
	for s in slots:
		if s.id == id:
			return s
	return null


func add_weapon(id: String) -> void:
	var s := Slot.new()
	s.id = id
	slots.append(s)
	refresh(s)


func level_up(id: String) -> void:
	var s := has_weapon(id)
	if s:
		s.level += 1
		refresh(s)


func add_passive(id: String) -> void:
	passives[id] = int(passives.get(id, 0)) + 1
	run.recompute_stats()
	for s in slots:
		refresh(s)


func evolvable() -> Slot:
	for s in slots:
		if s.evolved or s.level < DB.MAX_WEAPON_LEVEL:
			continue
		var evo: Dictionary = DB.WEAPONS[s.id].evo
		if passives.has(evo.passive):
			return s
	return null


func evolve(s: Slot) -> void:
	s.evolved = true
	refresh(s)


func refresh(s: Slot) -> void:
	var w: Dictionary = DB.WEAPONS[s.id]
	var st: Dictionary = w.base.duplicate()
	var lv: Array = w.levels
	for i in s.level - 1:
		var delta: Dictionary = lv[i]
		for k in delta:
			st[k] = st.get(k, 0) + delta[k]
	if s.evolved:
		var e: Dictionary = w.evo
		for k in ["dmg", "area", "cd", "spin", "rate"]:
			if e.has(k) and st.has(k):
				st[k] = st[k] * e[k]
		for k in ["amount", "pierce"]:
			if e.has(k):
				st[k] = st.get(k, 0) + e[k]
	s.s = st
	if s.id == "sickles":
		_rebuild_orbs()


func _final(s: Slot) -> Dictionary:
	var st := run.stats as Dictionary
	return {
		"dmg": float(s.s.dmg) * float(st.might),
		"area": float(s.s.area) * float(st.area),
		"cd": maxf(float(s.s.get("cd", 1.0)) * float(st.cooldown), 0.12),
		"amount": int(s.s.amount) + int(st.amount),
		"knock": float(s.s.get("knock", 0.0)),
	}


func _rebuild_orbs() -> void:
	for o in orbs:
		o.spr.queue_free()
	orbs.clear()
	var s := has_weapon("sickles")
	if s == null:
		return
	var n: int = _final(s).amount
	for i in n:
		var sp := Sprite2D.new()
		sp.texture = tex.proj_sickle
		sp.z_index = 15
		sp.modulate = GOLD if s.evolved else Color.WHITE
		run.add_child(sp)
		orbs.append({"spr": sp, "i": i, "hit": {}})


func update(dt: float) -> void:
	for s in slots:
		if s.id == "sickles":
			continue
		s.t -= dt
		if s.t <= 0.0:
			var f := _final(s)
			s.t = f.cd
			_fire(s, f)
	# delayed follow-up attacks
	for i in range(queue.size() - 1, -1, -1):
		var q := queue[i]
		q.t = float(q.t) - dt
		if float(q.t) <= 0.0:
			var c: Callable = q.fn
			c.call()
			queue.remove_at(i)
	_update_orbs(dt)
	_update_shots(dt)
	_update_zones(dt)
	_update_turrets(dt)


func _later(t: float, fn: Callable) -> void:
	queue.append({"t": t, "fn": fn})


func _fire(s: Slot, f: Dictionary) -> void:
	match s.id:
		"scythe":
			for i in int(f.amount):
				_later(i * 0.14, _swing.bind(s, f, i))
		"pitchfork":
			var target = run.enemies.nearest(run.player_pos, 340.0)
			var base: Vector2 = run.facing_vec
			if target != null:
				base = (target.pos - run.player_pos).normalized()
			for i in int(f.amount):
				var a := (i - (int(f.amount) - 1) / 2.0) * 0.16
				_later(i * 0.05, _throw.bind(s, f, base.rotated(a)))
			Audio.play("shoot")
		"shotgun":
			var target = run.enemies.nearest(run.player_pos, 260.0)
			var base: Vector2 = run.facing_vec
			if target != null:
				base = (target.pos - run.player_pos).normalized()
			var n := int(f.amount)
			for i in n:
				var a := (float(i) / maxf(n - 1, 1) - 0.5) * (0.7 + n * 0.02)
				var p := _shot(s, f, "proj_pellet", run.player_pos, base.rotated(a) * float(s.s.speed) * randf_range(0.9, 1.05), float(s.s.life), int(s.s.pierce), 4.0 * float(f.area))
				p.spr.rotation = 0.0
			Audio.play("shoot")
			run.fx.shake(1.0)
		"bees":
			for i in int(f.amount):
				var p := _shot(s, f, "proj_bee", run.player_pos, Vector2.from_angle(randf() * TAU) * float(s.s.speed), float(s.s.life), int(s.s.pierce), 5.0)
				p.homing = true
				p.speed = float(s.s.speed)
				p.spr.hframes = 2
				p.spr.rotation = 0.0
			Audio.play("bee")
		"weedkiller":
			for i in int(f.amount):
				var e = run.enemies.random_on_screen()
				var at: Vector2 = e.pos if e != null else run.player_pos + Vector2.from_angle(randf() * TAU) * 60.0
				_zone(s, f, at)
			Audio.play("shoot")
		"tractor":
			for i in int(f.amount):
				_later(i * 0.5, _drive.bind(s, f))
		"lightning":
			for i in int(f.amount):
				_later(i * 0.08, _strike.bind(s, f))
		"scarecrow":
			for i in int(f.amount):
				var off := Vector2.from_angle(randf() * TAU) * randf_range(30.0, 70.0)
				_place(s, f, run.player_pos + off)


func _swing(s: Slot, f: Dictionary, i: int) -> void:
	var dir: Vector2 = Vector2(run.facing, 0)
	var moved: Vector2 = run.facing_vec
	if s.evolved:
		dir = moved.rotated(TAU * i / maxf(int(f.amount), 1))
	elif i % 2 == 1:
		dir = Vector2(-run.facing, 0)
	else:
		dir = (dir + moved * 0.8).normalized()
	var r: float = 62.0 * float(f.area)
	var hits: Array = run.enemies.query(run.player_pos + dir * r * 0.5, r * 0.75)
	for e in hits:
		var to: Vector2 = e.pos - run.player_pos
		if to.length() < 22.0 or to.normalized().dot(dir) > 0.1:
			run.enemies.damage(e, f.dmg, run.player_pos, f.knock, s)
	run.fx.sprite_flash(tex.fx_slash, run.player_pos + dir * 6.0, dir.angle(), float(f.area) * 1.15, 0.22, GOLD if s.evolved else Color.WHITE)
	Audio.play("slash")


func _throw(s: Slot, f: Dictionary, dir: Vector2) -> void:
	_shot(s, f, "proj_pitchfork", run.player_pos, dir * float(s.s.speed), 1.6, int(s.s.pierce), 7.0 * float(f.area))


func _shot(s: Slot, f: Dictionary, texid: String, pos: Vector2, vel: Vector2, life: float, pierce: int, r: float) -> P:
	var p := P.new()
	var sp := Sprite2D.new()
	sp.texture = tex[texid]
	sp.position = pos
	sp.rotation = vel.angle()
	sp.z_index = 15
	sp.scale = Vector2.ONE * clampf(float(f.area), 1.0, 1.8)
	sp.modulate = GOLD if s.evolved else Color.WHITE
	run.add_child(sp)
	p.spr = sp
	p.pos = pos
	p.vel = vel
	p.dmg = f.dmg
	p.life = life
	p.pierce = pierce
	p.r = r
	p.knock = f.knock
	p.slot = s
	shots.append(p)
	return p


func _update_shots(dt: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var p := shots[i]
		if p.homing:
			var t = run.enemies.nearest(p.pos, 240.0)
			if t != null:
				var want: Vector2 = (t.pos - p.pos).normalized() * p.speed
				p.vel = p.vel.lerp(want, minf(1.0, dt * 6.0))
			p.anim += 1
			p.spr.frame = (p.anim / 3) % 2
			p.spr.flip_h = p.vel.x < 0.0
		p.pos += p.vel * dt
		p.life -= dt
		p.spr.position = p.pos
		var gone := p.life <= 0.0
		if not gone:
			for e in run.enemies.query(p.pos, p.r):
				if p.hits.has(e.uid):
					continue
				p.hits[e.uid] = true
				run.enemies.damage(e, p.dmg, p.pos - p.vel.normalized() * 8.0, p.knock, p.slot)
				p.pierce -= 1
				if p.pierce <= 0:
					gone = true
					break
		if gone:
			p.spr.queue_free()
			shots.remove_at(i)


func _update_orbs(dt: float) -> void:
	var s := has_weapon("sickles")
	if s == null or orbs.is_empty():
		return
	var f := _final(s)
	if orbs.size() != int(f.amount):
		_rebuild_orbs()
	orbit_angle += float(s.s.spin) * dt
	var r: float = float(s.s.orbit) * float(f.area)
	var now: float = run.time
	for o in orbs:
		var a: float = orbit_angle + TAU * int(o.i) / orbs.size()
		var pos: Vector2 = run.player_pos + Vector2.from_angle(a) * r
		o.spr.position = pos
		o.spr.rotation += dt * 12.0
		for e in run.enemies.query(pos, 10.0 * float(f.area)):
			if now - float(o.hit.get(e.uid, -9.0)) > 0.5:
				o.hit[e.uid] = now
				run.enemies.damage(e, f.dmg, run.player_pos, f.knock, s)
		if o.hit.size() > 200:
			o.hit.clear()


func _zone(s: Slot, f: Dictionary, at: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex.proj_puddle
	sp.hframes = 3
	sp.position = at
	sp.z_index = -5
	var sc: float = float(f.area) * 1.1
	sp.scale = Vector2(sc, sc)
	sp.modulate = Color(1.0, 0.75, 1.0, 0.95) if s.evolved else Color(1, 1, 1, 0.9)
	run.add_child(sp)
	zones.append({"spr": sp, "pos": at, "r": 24.0 * sc, "life": float(s.s.life), "tick": 0.0, "dmg": f.dmg, "slot": s, "age": 0.0})


func _update_zones(dt: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z := zones[i]
		z.life = float(z.life) - dt
		z.tick = float(z.tick) - dt
		z.age = float(z.age) + dt
		z.spr.frame = int(float(z.age) * 5.0) % 3
		if float(z.tick) <= 0.0:
			z.tick = 0.4
			for e in run.enemies.query(z.pos, z.r):
				run.enemies.damage(e, z.dmg, z.pos, 0.0, z.slot)
		if float(z.life) <= 0.0:
			z.spr.queue_free()
			zones.remove_at(i)


func _drive(s: Slot, f: Dictionary) -> void:
	var side: float = [-1.0, 1.0].pick_random()
	var y: float = run.player_pos.y + randf_range(-70.0, 70.0)
	var e = run.enemies.random_on_screen()
	if e != null:
		y = e.pos.y
	var start := Vector2(run.player_pos.x - side * 370.0, y)
	var p := _shot(s, f, "proj_tractor", start, Vector2(side * float(s.s.speed), 0), 1.9, 9999, 26.0 * float(f.area))
	p.spr.rotation = 0.0
	p.spr.flip_h = side < 0.0
	p.spr.hframes = 2
	Audio.play("tractor")


func _strike(s: Slot, f: Dictionary) -> void:
	var e = run.enemies.random_on_screen()
	if e == null:
		return
	var at: Vector2 = e.pos
	var r: float = 24.0 * float(f.area)
	for h in run.enemies.query(at, r):
		run.enemies.damage(h, f.dmg, at, f.knock, s)
	run.fx.bolt(tex.fx_bolt, at, GOLD if s.evolved else Color.WHITE)
	run.fx.ring(at, r, Color("7fe8ff"))
	Audio.play("zap")


func _place(s: Slot, f: Dictionary, at: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex.proj_scarecrow
	sp.hframes = 2
	sp.position = at
	sp.modulate = GOLD if s.evolved else Color.WHITE
	run.world.add_child(sp)
	turrets.append({"spr": sp, "pos": at, "life": float(s.s.life), "t": 0.0, "slot": s, "age": 0.0})


func _update_turrets(dt: float) -> void:
	for i in range(turrets.size() - 1, -1, -1):
		var t := turrets[i]
		t.life = float(t.life) - dt
		t.t = float(t.t) - dt
		t.age = float(t.age) + dt
		t.spr.frame = int(float(t.age) * 3.0) % 2
		var s: Slot = t.slot
		if float(t.t) <= 0.0:
			t.t = float(s.s.rate)
			var e = run.enemies.nearest(t.pos, 200.0)
			if e != null:
				var f := _final(s)
				_shot(s, f, "proj_pellet", t.pos + Vector2(0, -10), (e.pos - t.pos).normalized() * float(s.s.speed), 1.0, 1, 4.0)
		if float(t.life) <= 0.0:
			t.spr.queue_free()
			turrets.remove_at(i)
