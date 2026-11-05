## One run: the farmer, the world, spawning, pickups and the win/lose flow.
extends Node2D

signal ended(result: Dictionary)

const EnemySys = preload("res://scripts/game/enemies.gd")
const WeaponSys = preload("res://scripts/game/weapons.gd")
const FxSys = preload("res://scripts/game/fx.gd")
const Hud = preload("res://scripts/game/hud.gd")

const VIEW := Vector2(640, 360)
const BASE_SPEED := 88.0
const BASE_MAGNET := 38.0
const CHUNK := 300.0
const MAX_GEMS := 240
const DANGER_ENTER := 0.10  # red edges and action music below this share of health
const DANGER_EXIT := 0.15  # the music waits for this, so small heals do not flip it
const XP_CHEST_BONUS := 1.0  # in fractions of the current level

var stage: Dictionary
var rad := 0
var character: Dictionary
var bot := false

var stats := {}
var world: Node2D
var ground: Sprite2D
var player: Sprite2D
var camera: Camera2D
var enemies: Node
var weapons: Node
var fx: Node2D
var hud: CanvasLayer

var player_pos := Vector2.ZERO
var facing := 1.0
var facing_vec := Vector2.RIGHT
var hp := 100.0
var iframes := 0.0
var slow_t := 0.0
var level := 1
var xp := 0.0
var xp_next := 8.0
var pending_levels := 0
var pending_chests := 0
var pending_nuke := false
var danger_music := false
var next_xp_chest := 45.0
var time := 0.0
var kills := 0
var run_coins := 0.0
var alive_flag := true
var finished := false
var boss_spawned := false
var mid_spawned := false
var spawn_acc := 0.0
var wave_i := 0
var next_elite := 60.0
var next_swarm := 75.0
var next_crate := 6.0
var hit_flash := 0.0
var anim_t := 0.0
var revives := 0
var rerolls := 0
var skips := 0
var banishes := 0
var banished := {}
var pickups: Array[Dictionary] = []
var pick_tex := {}
var chunks := {}
var prop_tex := {}
var win_timer := -1.0


func start(p_stage: int, p_rad: int, char_id: String, p_bot: bool = false) -> void:
	stage = DB.STAGES[p_stage]
	rad = p_rad
	bot = p_bot
	for c in DB.CHARACTERS:
		if c.id == char_id:
			character = c
	_build()
	recompute_stats()
	hp = float(stats.max_hp)
	revives = int(stats.revive)
	rerolls = int(stats.reroll)
	skips = int(stats.skip)
	banishes = int(stats.banish)
	weapons.add_weapon(character.weapon)
	hud.refresh_items()
	hud.banner(tr(stage.name), Color("b8ff3a"))
	Audio.positions.clear()
	Audio.play_music("battle")


func _build() -> void:
	ground = Sprite2D.new()
	ground.texture = load("res://assets/sprites/ground_%d.png" % int(stage.ground))
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.region_enabled = true
	ground.region_rect = Rect2(0, 0, 128 * 9, 128 * 6)
	ground.centered = false
	ground.z_index = -100
	add_child(ground)

	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)

	player = Sprite2D.new()
	player.texture = load("res://assets/sprites/char_%s.png" % character.id)
	player.hframes = 6
	player.vframes = 2
	player.offset = Vector2(0, -8)
	world.add_child(player)

	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	enemies = EnemySys.new()
	add_child(enemies)
	enemies.setup(self)
	weapons = WeaponSys.new()
	add_child(weapons)
	weapons.setup(self)
	fx = FxSys.new()
	add_child(fx)
	fx.setup(self)
	hud = Hud.new()
	add_child(hud)
	hud.setup(self)

	for t in ["gem_1", "gem_2", "gem_3", "pickup_coin", "pickup_pie", "pickup_magnet", "pickup_dynamite", "pickup_chest", "pickup_xpchest"]:
		pick_tex[t] = load("res://assets/sprites/%s.png" % t)
	for p in stage.props:
		prop_tex[p] = load("res://assets/sprites/prop_%s.png" % p)


func recompute_stats() -> void:
	var s := {
		"might": 1.0, "area": 1.0, "cooldown": 1.0, "speed": 1.0, "amount": 0.0, "growth": 1.0, "greed": 1.0,
		"magnet": 1.0, "luck": 1.0, "regen": 0.0, "armor": 0.0, "max_hp": 100.0, "revive": 0.0, "reroll": 0.0, "skip": 0.0, "banish": 0.0,
	}
	for k in s:
		s[k] = float(s[k]) + Save.meta_bonus(k)
	var bonus: Dictionary = character.bonus
	for k in bonus:
		s[k] = float(s[k]) + float(bonus[k])
	for id in weapons.passives:
		var p: Dictionary = DB.PASSIVES[id]
		s[p.stat] = float(s[p.stat]) + float(p.v) * int(weapons.passives[id])
	s.greed = float(s.greed) * Save.coin_mult() * pow(DB.RAD_COINS, rad)
	s.cooldown = maxf(float(s.cooldown), 0.35)
	var old_max: float = float(stats.get("max_hp", s.max_hp))
	stats = s
	if float(s.max_hp) > old_max:
		hp += float(s.max_hp) - old_max


func view_rect() -> Rect2:
	return Rect2(player_pos - VIEW / 2.0, VIEW)


func spawn_point() -> Vector2:
	var side := randi() % 4
	var hw := VIEW.x / 2.0 + 28.0
	var hh := VIEW.y / 2.0 + 28.0
	match side:
		0: return player_pos + Vector2(-hw, randf_range(-hh, hh))
		1: return player_pos + Vector2(hw, randf_range(-hh, hh))
		2: return player_pos + Vector2(randf_range(-hw, hw), -hh)
	return player_pos + Vector2(randf_range(-hw, hw), hh)


func _process(delta: float) -> void:
	if not alive_flag and not finished and win_timer < 0.0:
		return
	var dt: float = minf(delta, 0.05)
	if win_timer >= 0.0:
		win_timer -= dt
		fx.update(dt)
		if win_timer < 0.0:
			_finish(true)
		return
	time += dt
	_player(dt)
	_spawning(dt)
	enemies.update(dt)
	if pending_nuke:
		pending_nuke = false
		enemies.nuke()
	weapons.update(dt)
	_pickups(dt)
	_chunks()
	fx.update(dt)
	hud.update_bars()
	camera.position = player_pos.round() + fx.shake_offset()
	var ox := floorf(player_pos.x / 128.0) * 128.0 - 128.0 * 4.0
	var oy := floorf(player_pos.y / 128.0) * 128.0 - 128.0 * 3.0
	ground.position = Vector2(ox, oy)
	_update_danger()
	if finished or win_timer >= 0.0:
		return  # never open a menu (and pause) once the run is over
	if pending_chests > 0 and not hud.is_busy():
		pending_chests -= 1
		hud.open_chest()
	if pending_levels > 0 and not hud.is_busy():
		pending_levels -= 1
		hud.open_level_up()


func _input_dir() -> Vector2:
	if bot:
		return _bot_dir()
	var keys := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return keys if keys != Vector2.ZERO else hud.touch_dir()


## Test driver: plays like a person. Dodges what is close, otherwise grabs loot
## and circles the horde so that short-range weapons connect.
func _bot_dir() -> Vector2:
	var away := Vector2.ZERO
	for e in enemies.query(player_pos, 44.0):
		if e.beh == "crate":
			continue
		var v: Vector2 = player_pos - e.pos
		away += v.normalized() * (1.0 + (e.r / 10.0))
	for b in enemies.bullets:
		if player_pos.distance_to(b.pos) < 50.0:
			away += (player_pos - Vector2(b.pos)).normalized() * 1.5
	for h in enemies.hazards:
		if player_pos.distance_to(h.pos) < float(h.r) + 16.0:
			away += (player_pos - Vector2(h.pos)).normalized() * 3.0
	if away.length() > 0.1:
		return (away.normalized() + away.normalized().orthogonal() * 0.7).limit_length(1.0)
	var best = null
	var bd := 170.0
	for p in pickups:
		var d: float = player_pos.distance_to(p.pos)
		if d < bd:
			bd = d
			best = p
	if best != null:
		return (Vector2(best.pos) - player_pos).normalized()
	var n = enemies.nearest(player_pos, 400.0)
	if n != null:
		var to: Vector2 = n.pos - player_pos
		return to.normalized().rotated(0.5) if to.length() > 50.0 else to.normalized().orthogonal()
	return Vector2.from_angle(time * 0.4)


func _player(dt: float) -> void:
	var dir := _input_dir()
	var spd := BASE_SPEED * float(stats.speed)
	if slow_t > 0.0:
		slow_t -= dt
		spd *= 0.55
	player_pos += dir * spd * dt
	var moving := dir.length_squared() > 0.01
	hud.tick_hint(dt, moving)
	if moving:
		facing_vec = dir.normalized()
		if absf(dir.x) > 0.1:
			facing = signf(dir.x)
	anim_t += dt
	var f := 2 + int(anim_t * 10.0) % 4 if moving else int(anim_t * 2.0) % 2
	if hit_flash > 0.0:
		hit_flash -= dt
		f += 6
	player.frame = f
	player.flip_h = facing < 0.0
	player.position = player_pos
	if iframes > 0.0:
		iframes -= dt
		player.modulate.a = 0.5 if int(time * 20.0) % 2 == 0 else 1.0
	else:
		player.modulate.a = 1.0
	hp = minf(hp + float(stats.regen) * dt, float(stats.max_hp))


func hurt(amount: float) -> void:
	if iframes > 0.0 or not alive_flag or win_timer >= 0.0:
		return
	var dmg: float = maxf(amount - float(stats.armor), 1.0)
	hp -= dmg
	iframes = 0.3
	hit_flash = 0.12
	fx.shake(2.0)
	Audio.play("hurt")
	if hp <= 0.0:
		if revives > 0:
			revives -= 1
			hp = float(stats.max_hp) * 0.5
			iframes = 2.5
			fx.explosion(player_pos, 90.0, Color("b8ff3a"))
			pending_nuke = true  # hurt() runs inside the enemy loops
			hud.banner(tr("HUD_REVIVED"), Color("b8ff3a"))
		else:
			alive_flag = false
			fx.burst(player_pos, Color("cf2f3a"), 24)
			player.visible = false
			_finish(false)


func _spawning(dt: float) -> void:
	var waves: Array = stage.waves
	while wave_i + 1 < waves.size() and time >= float(waves[wave_i + 1].t):
		wave_i += 1
	var w: Dictionary = waves[wave_i]
	var rate: float = float(w.rate) * (1.0 + rad * 0.08)
	if boss_spawned:
		rate *= 0.45
	spawn_acc += rate * dt
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		enemies.spawn(w.pool.pick_random(), spawn_point())
	if time >= next_elite and not boss_spawned:
		next_elite += 60.0
		var elite_id: String = w.pool.pick_random()
		enemies.spawn(elite_id, spawn_point(), {"hp": 9.0, "size": 1.5, "elite": true, "force": true, "speed": 0.9})
	if time >= next_swarm and not boss_spawned:
		next_swarm += 90.0
		_swarm(w.pool[0])
	if time >= next_xp_chest:
		next_xp_chest = time + randf_range(75.0, 100.0)
		_add_pickup("pickup_xpchest", player_pos + Vector2.from_angle(randf() * TAU) * randf_range(110.0, 160.0))
	if time >= next_crate:
		next_crate = time + randf_range(7.0, 11.0)
		enemies.spawn("crate", spawn_point() * 0.9 + player_pos * 0.1, {"force": true})
	if not mid_spawned and time >= DB.MID_BOSS_TIME:
		mid_spawned = true
		enemies.spawn(stage.mid, spawn_point(), {"hp": 42.0, "size": 2.2, "mid": true, "force": true, "speed": 0.95})
		hud.banner(tr("HUD_MIDBOSS"), Color("ffae3a"))
		Audio.play("boss")
	if not boss_spawned and time >= DB.STAGE_LENGTH:
		boss_spawned = true
		enemies.spawn(stage.boss, player_pos + Vector2(0, -170), {"force": true})
		hud.banner(tr(DB.ENEMIES[stage.boss].name), Color("ff5a4a"))
		fx.shake(8.0)
		Audio.play("boss")
		if not danger_music:
			Audio.play_music("boss")


func _swarm(id: String) -> void:
	hud.banner(tr("HUD_SWARM"), Color("ffe066"))
	for i in 26:
		enemies.spawn(id, player_pos + Vector2.from_angle(TAU * i / 26.0) * 215.0, {"force": true})


# --- Pickups ----------------------------------------------------------------------

func _add_pickup(kind: String, pos: Vector2, value: float = 1.0) -> void:
	var s := Sprite2D.new()
	s.texture = pick_tex[kind]
	s.position = pos
	if kind == "pickup_coin":
		s.hframes = 4
	s.z_index = -2
	add_child(s)
	pickups.append({"kind": kind, "pos": pos, "spr": s, "v": value, "fly": false, "spd": 0.0})


func _gem(pos: Vector2, v: float) -> void:
	if pickups.size() >= MAX_GEMS:
		# Merge into a far-away gem rather than letting the floor overflow.
		var far: Dictionary = pickups[randi() % pickups.size()]
		if String(far.kind).begins_with("gem"):
			far.v = float(far.v) + v
			return
	var kind := "gem_1"
	if v >= 15.0:
		kind = "gem_3"
	elif v >= 5.0:
		kind = "gem_2"
	_add_pickup(kind, pos, v)


func drop_from(e) -> void:
	_gem(e.pos, float(e.data.xp))
	var luck: float = stats.luck
	var roll := randf()
	if e.boss:
		return
	if e.mid or (e.elite and randf() < 0.35 * luck):
		_add_pickup("pickup_xpchest", e.pos + Vector2(26, 0))
	if e.mid or e.elite:
		_add_pickup("pickup_chest", e.pos)
		for i in 6:
			_add_pickup("pickup_coin", e.pos + Vector2.from_angle(TAU * i / 6.0) * 22.0, 3.0)
	elif roll < 0.05 * luck:
		_add_pickup("pickup_coin", e.pos, 1.0)
	elif roll < 0.053 * luck:
		_add_pickup("pickup_pie", e.pos)
	elif roll < 0.0545 * luck:
		_add_pickup("pickup_magnet", e.pos)


func drop_crate(pos: Vector2) -> void:
	var r := randf()
	if r < 0.45:
		for i in 3:
			_add_pickup("pickup_coin", pos + Vector2.from_angle(TAU * i / 3.0) * 8.0, 2.0)
	elif r < 0.7:
		_add_pickup("pickup_pie", pos)
	elif r < 0.84:
		_add_pickup("pickup_magnet", pos)
	elif r < 0.92:
		_add_pickup("pickup_xpchest", pos)
	else:
		_add_pickup("pickup_dynamite", pos)


func _pickups(dt: float) -> void:
	var range_r := BASE_MAGNET * float(stats.magnet)
	var t := time
	for i in range(pickups.size() - 1, -1, -1):
		var p := pickups[i]
		var dist: float = p.pos.distance_to(player_pos)
		if not p.fly and dist < range_r:
			p.fly = true
		if p.fly:
			p.spd = minf(float(p.spd) + 900.0 * dt, 520.0)
			p.pos = p.pos.move_toward(player_pos, float(p.spd) * dt)
			p.spr.position = p.pos
		elif p.kind == "pickup_coin":
			p.spr.frame = int(t * 8.0) % 4
		if dist < 12.0:
			_collect(p)
			p.spr.queue_free()
			pickups.remove_at(i)


func _collect(p: Dictionary) -> void:
	match String(p.kind):
		"pickup_coin":
			run_coins += float(p.v) * float(stats.greed)
			Audio.play("coin")
		"pickup_pie":
			hp = minf(hp + 30.0, float(stats.max_hp))
			fx.text(player_pos + Vector2(-6, -24), "+30", Color("7fd04b"))
			Audio.play("buy")
		"pickup_magnet":
			for q in pickups:
				if String(q.kind).begins_with("gem"):
					q.fly = true
			Audio.play("buy")
		"pickup_dynamite":
			fx.explosion(player_pos, 200.0, Color("ffae3a"))
			fx.shake(7.0)
			Audio.play("boom")
			enemies.nuke()
		"pickup_xpchest":
			_open_xp_chest()
		"pickup_chest":
			Audio.play("chest")
			pending_chests += 1
		_:
			gain_xp(float(p.v))
			Audio.play("pickup", 0.25)


## Pays a level's worth of experience and pulls in every crystal on the map.
func _open_xp_chest() -> void:
	var bonus := ceilf(xp_next * XP_CHEST_BONUS)
	var g: float = maxf(float(stats.growth), 0.01)
	gain_xp(bonus / g)
	for q in pickups:
		if String(q.kind).begins_with("gem"):
			q.fly = true
	fx.explosion(player_pos, 120.0, Color("b8ff3a"))
	fx.shake(2.0)
	hud.banner(tr("HUD_XPCHEST") % Save.fmt(bonus), Color("b8ff3a"))
	Audio.play("chest")


func gain_xp(v: float) -> void:
	xp += v * float(stats.growth)
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		pending_levels += 1
		xp_next = floorf(5.0 + level * 3.5 + pow(level, 1.5) * 0.6)


# --- Scenery ----------------------------------------------------------------------

func _chunks() -> void:
	var cx := int(floor(player_pos.x / CHUNK))
	var cy := int(floor(player_pos.y / CHUNK))
	var wanted := {}
	for x in range(cx - 1, cx + 2):
		for y in range(cy - 1, cy + 2):
			var k := Vector2i(x, y)
			wanted[k] = true
			if not chunks.has(k):
				chunks[k] = _make_chunk(k)
	for k in chunks.keys():
		if not wanted.has(k):
			for s in chunks[k]:
				s.queue_free()
			chunks.erase(k)


func _make_chunk(k: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k) + int(stage.id) * 991
	var out := []
	var keys: Array = stage.props
	for i in rng.randi_range(7, 11):
		var s := Sprite2D.new()
		var key: String = keys[rng.randi() % keys.size()]
		s.texture = prop_tex[key]
		if key == "dirt" or key == "toxicpool":
			s.z_index = -50  # flat on the ground, never over a character
		s.position = Vector2(k) * CHUNK + Vector2(rng.randf() * CHUNK, rng.randf() * CHUNK)
		s.offset.y = -s.texture.get_height() / 2.0 + 4.0
		s.flip_h = rng.randf() < 0.5
		world.add_child(s)
		out.append(s)
	return out


# --- Ending -----------------------------------------------------------------------

func on_boss_dead(e) -> void:
	fx.explosion(e.pos, 160.0, Color("b8ff3a"))
	fx.shake(10.0)
	Audio.play("boom")
	Audio.play("win")
	run_coins += float(stage.reward) * float(stats.greed)
	hud.banner(tr("HUD_VICTORY"), Color("b8ff3a"))
	win_timer = 2.5
	hud.set_danger(false)
	danger_music = false


func give_up() -> void:
	_finish(false)


func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	var dmg := []
	for s in weapons.slots:
		dmg.append({"id": s.id, "evolved": s.evolved, "done": s.done, "level": s.level})
	dmg.sort_custom(func(a, b): return a.done > b.done)
	ended.emit({
		"win": win, "time": time, "kills": kills, "level": level,
		"coins": floorf(run_coins + kills * 0.1 * float(stats.greed)),
		"stage": int(stage.id), "rad": rad, "damage": dmg,
	})


func _update_danger() -> void:
	if finished or not alive_flag or win_timer >= 0.0:
		return
	var ratio: float = hp / float(stats.max_hp)
	hud.set_danger(ratio < DANGER_ENTER)
	if not danger_music and ratio < DANGER_ENTER:
		danger_music = true
		Audio.play_music("danger")
	elif danger_music and ratio >= DANGER_EXIT:
		danger_music = false
		Audio.play_music("boss" if enemies.boss_ref != null else "battle", true)
