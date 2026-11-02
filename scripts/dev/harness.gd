## Development harness, only active with `-- --dev=<mode>`.
##   --dev=sim:<stage>:<rad>:<char>:<speed>  bot plays a whole run, prints a report
##   --dev=shots:<dir>                       captures every screen to PNG files
##   --dev=i18n                              checks all locales for missing keys
extends Node

var main: Node
var mode := ""
var arg: PackedStringArray


func begin(m: Node, spec: String) -> void:
	main = m
	arg = spec.split(":")
	mode = arg[0]
	Save.path = "user://dev_test.save"
	DirAccess.remove_absolute(Save.path)
	match mode:
		"sim":
			_sim()
		"eco":
			_eco()
		"store":
			_store.call_deferred()
		"bugs":
			_bugs.call_deferred()
		"chaos":
			_chaos.call_deferred()
		"flow":
			_flow.call_deferred()
		"covers":
			_covers.call_deferred()
		"trailer":
			_trailer.call_deferred()
		"touch":
			_touch.call_deferred()
		"i18n":
			_i18n()
		"shots":
			_shots.call_deferred()


func _sim() -> void:
	Save.d = Save._default()
	var meta := int(arg[5]) if arg.size() > 5 else 0
	for m in DB.META:
		Save.d.meta[m.id] = min(meta, int(m.max))
	Engine.time_scale = float(arg[4])
	Engine.max_physics_steps_per_frame = 16
	main.start_run(int(arg[1]), int(arg[2]), arg[3], true)
	var log_t := 0.0
	while main.run != null:
		await get_tree().process_frame
		var r = main.run
		if r == null:
			break
		if r.time - log_t >= 60.0:
			log_t = r.time
			print("t=%3d lvl=%2d hp=%3d/%3d alive=%3d kills=%5d weapons=%s fps=%d" % [r.time, r.level, r.hp, r.stats.max_hp, r.enemies.alive.size(), r.kills, r.weapons.slots.map(func(s): return "%s%d" % [s.id, s.level]), Engine.get_frames_per_second()])


func on_result(r: Dictionary) -> void:
	if mode == "sim":
		print("RESULT ", JSON.stringify(r))
		get_tree().quit()


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:" + arg[1] + "/" + name + ".png")
	print("shot ", name)


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Walks the whole game and photographs every screen, for layout review.
func _shots() -> void:
	var loc: String = arg[2] if arg.size() > 2 else "en"
	UI.force_touch = "touch" in arg
	Save.d = Save._default()
	Save.d.settings.locale = loc
	Save.apply_settings()
	Save.d.coins = 123456.0
	Save.d.cleared = {"0": 1, "1": 0}
	Save.d.journal = 3
	Save.d.buildings = {"coop": 12, "barn": 5, "silo": 2}
	Save.d.meta = {"might": 4, "greed": 7, "reach": 3}
	main.show_title()
	await _wait(8)
	await _snap("01_title")
	main.show_story(main.INTRO, func(): pass)
	await _wait(240)
	await _snap("02_story")
	main.show_hub()
	await _wait(8)
	await _snap("03_hub_expedition")
	var keep: Dictionary = Save.d.cleared
	Save.d.cleared = {}
	main.current.rebuild()
	await _wait(8)
	await _snap("03a_hub_new_player")
	Save.d.cleared = keep
	Save.d.selected_rad = 1
	main.current.rebuild()
	await _wait(8)
	await _snap("03b_hub_radiation")
	Save.d.selected_rad = 0
	var hub = main.current
	for t in ["workshop", "farm", "journal"]:
		hub._set_tab(t)
		await _wait(8)
		await _snap("04_hub_" + t)
	main.open_options(main.ui_layer)
	await _wait(8)
	await _snap("05_options")
	Save.d.meta = {"might": 20, "vitality": 20, "armor": 8, "haste": 10, "reach": 10, "greed": 7}
	Engine.time_scale = 1.0
	main.ui_layer.get_children().back().queue_free()
	main.start_run(int(arg[3]) if arg.size() > 3 else 1, 1, "hank", true)
	var r = main.run
	r.time = 215.0
	r.next_elite = 9999.0
	r.weapons.add_weapon("pitchfork")
	r.weapons.add_weapon("sickles")
	r.weapons.add_weapon("weedkiller")
	r.weapons.add_weapon("lightning")
	r.weapons.add_passive("hat")
	r.hud.refresh_items()
	for i in 90:
		r.enemies.spawn(["corn", "eggplant", "chili", "potato", "pea"].pick_random(), r.player_pos + Vector2.from_angle(randf() * TAU) * randf_range(70, 300))
	for off in [Vector2(90, -60), Vector2(-110, 40), Vector2(60, 80)]:
		r._add_pickup("pickup_xpchest", r.player_pos + off)
	await _wait(150)
	await _snap("06_run")
	r.hp = float(r.stats.max_hp) * 0.05
	r.iframes = 99.0
	await _wait(25)
	await _snap("06b_danger")
	r.hp = float(r.stats.max_hp)
	await _wait(3)
	r.bot = false
	r.hud._show_level_up(r.hud._options())
	await _wait(6)
	await _snap("07_levelup")
	r.hud.close_overlay()
	r.hud.open_chest()
	await _wait(6)
	await _snap("08_chest")
	r.hud.close_overlay()
	r.hud.open_pause()
	await _wait(6)
	await _snap("09_pause")
	r.hud.close_overlay()
	r.hp = 99999.0
	r.stats.max_hp = 99999.0
	r.time = 479.0
	r.enemies.alive.filter(func(e): return e.beh != "crate").map(func(e): e.pos += Vector2(900, 0))
	await _wait(100)
	await _snap("10_boss")
	main.show_story.call_deferred(main.ENDING, func(): pass)
	r.hud.queue_free()
	r.queue_free()
	main.run = null
	await _wait(200)
	await _snap("11_ending")
	var res := Screens.Results.new({"win": true, "time": 512.0, "kills": 4312, "level": 41, "coins": 2510.0, "stage": 1, "rad": 1, "notes": [tr("RES_UNLOCK_STAGE") % tr("STAGE_3"), tr("RES_UNLOCK_RAD") % 2],
		"damage": [{"id": "scythe", "evolved": true, "done": 91234.0, "level": 8}, {"id": "lightning", "evolved": false, "done": 45210.0, "level": 8}, {"id": "bees", "evolved": false, "done": 12010.0, "level": 5}, {"id": "tractor", "evolved": false, "done": 8010.0, "level": 3}, {"id": "weedkiller", "evolved": false, "done": 5010.0, "level": 3}, {"id": "sickles", "evolved": false, "done": 2010.0, "level": 3}]})
	main._swap(res)
	await _wait(8)
	await _snap("12_results")
	get_tree().quit()


## Every locale must have every key, with matching % placeholders.
func _i18n() -> void:
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	var head := f.get_csv_line()
	var re := RegEx.create_from_string("%[ds%]")
	var keys := {}
	var bad := 0
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2:
			continue
		if row.size() != head.size():
			print("BAD COLUMNS ", row[0], " ", row.size())
			bad += 1
			continue
		keys[row[0]] = true
		var want := ""
		for c in range(1, row.size()):
			if row[c].strip_edges() == "":
				print("EMPTY ", row[0], " ", head[c])
				bad += 1
			var found := ",".join(re.search_all(row[c]).map(func(m): return m.get_string()))
			if c == 1:
				want = found
			elif found != want:
				print("PLACEHOLDERS ", row[0], " ", head[c], " ", found, " vs ", want)
				bad += 1
	var need := ["GAME_TITLE", "GAME_TAGLINE"]
	for id in DB.WEAPONS:
		need.append_array(["WPN_" + id.to_upper(), "WPN_%s_D" % id.to_upper(), DB.WEAPONS[id].evo.name])
	for id in DB.PASSIVES:
		need.append_array(["PAS_" + id.to_upper(), "PAS_%s_D" % id.to_upper()])
	for m in DB.META:
		need.append_array(["META_" + String(m.id).to_upper(), "META_%s_D" % String(m.id).to_upper()])
	for b in DB.BUILDINGS:
		need.append("BLD_" + String(b.id).to_upper())
	for c in DB.CHARACTERS:
		need.append_array([c.name, c.desc])
	for s in DB.STAGES:
		need.append_array([s.name, s.desc])
	for k in DB.JOURNAL:
		need.append(k)
	for k in need:
		if not keys.has(k):
			print("MISSING ", k)
			bad += 1
	for code in ["en", "pt_BR", "es", "fr"]:
		TranslationServer.set_locale(code)
		print(code, " -> ", tr("BTN_PLAY"), " | ", tr("BOSS_ROOT"))
	print("i18n keys=", keys.size(), " problems=", bad)
	get_tree().quit()


var fails := 0


func _ok(cond: bool, what: String) -> void:
	print("PASS " if cond else "FAIL ", what)
	if not cond:
		fails += 1


## Economy, prestige, offline income and save/load round trip.
func _eco() -> void:
	Save.d = Save._default()
	_ok(Save.d.settings.locale == "en", "default language is English")
	Save.add_coins(100.0)
	var coop: Dictionary = DB.BUILDINGS[0]
	_ok(Save.buy_building(coop), "buy coop")
	_ok(Save.building_count("coop") == 1 and is_equal_approx(float(Save.d.coins), 60.0), "coop cost deducted")
	_ok(is_equal_approx(Save.building_cost(coop), ceilf(40.0 * 1.15)), "cost scales 1.15x")
	_ok(is_equal_approx(Save.coins_per_second(), 0.2), "income 0.2/s")
	Save.d.buildings["coop"] = 25
	_ok(is_equal_approx(Save.coins_per_second(), 0.2 * 25 * 2), "milestone doubles output at 25")
	var might: Dictionary = DB.META[0]
	Save.d.coins = 1000.0
	_ok(Save.buy_meta(might) and Save.meta_level("might") == 1, "buy workshop upgrade")
	_ok(is_equal_approx(Save.meta_bonus("might"), 0.05), "might bonus +5%")
	_ok(is_equal_approx(Save.meta_cost(might), ceilf(60.0 * 1.42)), "workshop cost scales")
	Save.d.meta["might"] = 20
	Save.d.coins = 1e12
	_ok(not Save.buy_meta(might), "cannot exceed max level")
	Save.d.meta["might"] = 1
	Save.d.lifetime = 25000.0 * 16.0
	Save.d.coins = 500.0
	_ok(Save.soil_available() == 4, "prestige formula")
	Save.replant()
	_ok(int(Save.d.soil) == 4 and float(Save.d.coins) == 0.0 and Save.building_count("coop") == 0, "replant resets farm, grants soil")
	_ok(Save.meta_level("might") == 1, "replant keeps workshop")
	_ok(is_equal_approx(Save.coin_mult(), 1.2), "soil coin multiplier")
	_ok(Save.soil_available() == 0, "no double prestige")
	_ok(not Save.stage_unlocked(1), "stage 2 starts locked")
	Save.record_clear(0, 0)
	_ok(Save.stage_unlocked(1) and Save.max_rad(0) == 1, "clearing unlocks next stage and radiation 1")
	_ok(int(Save.d.journal) == 2, "journal entry unlocked")
	Save.d.buildings = {"barn": 10}
	Save.d.last_time = Time.get_unix_time_from_system() - 3600.0
	var last: float = Save.d.last_time
	var f := FileAccess.open(Save.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(Save.d))
	f.close()
	var rate := Save.coins_per_second()
	var before := float(Save.d.coins)
	Save.load_game()
	_ok(int(Save.d.soil) == 4 and Save.meta_level("might") == 1 and Save.building_count("barn") == 10, "save/load round trip")
	_ok(absf(Save.offline_earned - 3600.0 * rate) < rate * 3.0, "offline income for one hour: %s" % Save.offline_earned)
	_ok(absf(float(Save.d.coins) - before - Save.offline_earned) < 0.01, "offline coins credited")
	Save.d.last_time = last - 1e7
	f = FileAccess.open(Save.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(Save.d))
	f.close()
	Save.load_game()
	_ok(Save.offline_earned <= DB.OFFLINE_CAP_HOURS * 3600.0 * rate + 1.0, "offline income capped at 8h")
	_ok(Save.fmt(1234.0) == "1.23K" and Save.fmt(2500000.0) == "2.50M", "number formatting")
	print("eco fails=", fails)
	get_tree().quit()


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var u := InputEventAction.new()
	u.action = action
	Input.parse_input_event(u)
	await _wait(4)


## Sends a finger event, given in game coordinates (640x360).
func _finger(index: int, p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = get_window().get_final_transform() * p
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await _wait(2)


func _finger_drag(index: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = get_window().get_final_transform() * p
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await _wait(2)


## Plays a run with fingers only, the way a phone would.
func _touch() -> void:
	UI.force_touch = true
	Save.d = Save._default()
	Save.apply_settings()
	main.show_title()
	await _wait(6)
	var play: Button = main.current.find_children("*", "Button", true, false)[0]
	_ok(play.size.y >= UI.TOUCH_MIN_HEIGHT, "menu buttons are finger sized")
	var center := play.get_global_rect().get_center()
	await _finger(0, center, true)
	await _finger(0, center, false)
	await _wait(4)
	_ok(main.current is Screens.Story, "tapping Play starts the story")
	_ok(main.current.hint.text == tr("STORY_HINT_TOUCH"), "story hint talks about tapping")
	for i in 12:
		if not (main.current is Screens.Story):
			break
		await _finger(0, Vector2(320, 100), true)
		await _finger(0, Vector2(320, 100), false)
		await _wait(2)
	_ok(not (main.current is Screens.Story), "tapping finishes the story")
	await _wait(4)
	main.start_run(0, 0, "hank", false)
	await _wait(6)
	var r = main.run
	var stick: TouchStick = r.hud.stick
	_ok(stick != null, "a run shows the stick on touch screens")
	_ok(r._input_dir() == Vector2.ZERO, "no finger, no movement")
	var from: Vector2 = r.player_pos
	await _finger(0, Vector2(400, 200), true)
	_ok(r._input_dir() == Vector2.ZERO, "touching without dragging does not move")
	await _finger_drag(0, Vector2(440, 200))
	_ok(r._input_dir().is_equal_approx(Vector2.RIGHT), "dragging right steers right at full speed")
	await _wait(40)
	_ok(r.player_pos.x > from.x + 20.0, "the stick walks the farmer")
	await _finger(1, Vector2(100, 100), true)
	await _finger_drag(1, Vector2(100, 200))
	_ok(r._input_dir().is_equal_approx(Vector2.RIGHT), "a second finger does not hijack the stick")
	await _finger(1, Vector2(100, 200), false)
	_ok(r._input_dir().is_equal_approx(Vector2.RIGHT), "lifting a second finger keeps steering")
	await _finger_drag(0, Vector2(300, 200))
	_ok(r._input_dir().x < -0.9, "the base follows the thumb, so reversing is instant")
	await _finger(0, Vector2(300, 200), false)
	_ok(r._input_dir() == Vector2.ZERO, "lifting the finger stops the farmer")
	var pause: Button = stick.blocked[0]
	var at := pause.get_global_rect().get_center()
	await _finger(0, at, true)
	_ok(r._input_dir() == Vector2.ZERO, "the pause button does not grab the stick")
	await _finger(0, at, false)
	await _wait(4)
	_ok(get_tree().paused and r.hud.overlay != null, "the pause button pauses")
	var resume: Button = r.hud.overlay.find_children("*", "Button", true, false)[0]
	var rc := resume.get_global_rect().get_center()
	await _finger(0, rc, true)
	await _finger(0, rc, false)
	await _wait(4)
	_ok(not get_tree().paused and r.hud.overlay == null, "tapping Resume closes the pause menu")
	_ok(r._input_dir() == Vector2.ZERO, "no stale steering after the menu")
	await _finger(0, Vector2(400, 200), true)
	await _finger_drag(0, Vector2(440, 200))
	r.gain_xp(40.0)
	await _wait(6)
	_ok(r.hud.overlay != null, "levelling up mid-drag opens the menu")
	await _finger(0, Vector2(440, 200), false)
	_ok(r._input_dir() == Vector2.ZERO, "lifting the finger during a menu clears the stick")
	var card: Button = r.hud.overlay.find_children("*", "Button", true, false)[0]
	var cc := card.get_global_rect().get_center()
	await _finger(0, cc, true)
	await _finger(0, cc, false)
	await _wait(4)
	_ok(r.hud.overlay == null or r.pending_levels > 0, "tapping a card picks it")
	UI.force_touch = false
	print("touch fails=", fails)
	get_tree().quit()


## Plays the real flow through input events, the way a player would.
func _flow() -> void:
	Save.d = Save._default()
	Save.apply_settings()  # the test plays as a brand-new player, whatever the real save says
	Audio.play_music("menu")
	main.show_title()
	await _wait(6)
	_ok(main.current is Screens.Title, "boots to the title screen")
	_ok(TranslationServer.get_locale().begins_with("en"), "starts in English")
	_ok(tr("BTN_PLAY") == "Play", "translations load")
	await _press("ui_accept")
	await _wait(4)
	_ok(main.current is Screens.Story, "Play on a new save opens the story")
	for i in 12:
		if not (main.current is Screens.Story):
			break
		await _press("ui_accept")
	await _wait(6)
	_ok(main.current != null and not (main.current is Screens.Story), "story advances to the hub")
	_ok(Save.d.seen_intro, "intro is only shown once")
	await _wait(6)
	await _press("ui_accept")
	await _wait(6)
	_ok(main.run != null, "Head out starts a run")
	var r = main.run
	Input.action_press("move_right")
	await _wait(40)
	Input.action_release("move_right")
	_ok(r.player_pos.x > 20.0, "move input walks the farmer")
	_ok(r.player.flip_h == false and r.facing == 1.0, "faces the walk direction")
	await _press("pause")
	await _wait(4)
	_ok(get_tree().paused and r.hud.overlay != null, "Esc pauses")
	var t: float = r.time
	await _wait(10)
	_ok(r.time == t, "time stops while paused")
	await _press("pause")
	await _wait(4)
	_ok(not get_tree().paused and r.hud.overlay == null, "Esc resumes")
	# level up through the real menu
	r.gain_xp(40.0)
	await _wait(6)
	_ok(r.hud.overlay != null and get_tree().paused, "level up opens the choice menu")
	var before: int = r.weapons.slots.size() + r.weapons.passives.size()
	var lvl: int = r.weapons.slots[0].level
	await _press("ui_accept")
	await _wait(4)
	_ok(not get_tree().paused or r.pending_levels > 0, "choosing a card continues the game")
	_ok(r.weapons.slots.size() + r.weapons.passives.size() > before or r.weapons.slots[0].level > lvl, "the card was applied")
	while r.hud.overlay != null:
		await _press("ui_accept")
	# chest and evolution
	r.weapons.slots[0].level = 8
	r.weapons.refresh(r.weapons.slots[0])
	r.weapons.add_passive(DB.WEAPONS[r.weapons.slots[0].id].evo.passive)
	r.pending_chests = 1
	await _wait(6)
	_ok(r.weapons.slots[0].evolved, "chest evolves a maxed weapon with its passive")
	await _press("ui_accept")
	await _wait(4)
	for id in DB.WEAPONS:
		if r.weapons.has_weapon(id) == null and r.weapons.slots.size() < 6:
			r.weapons.add_weapon(id)
	await _wait(120)
	r.hp = 1.0
	r.stats.armor = 0.0
	r.iframes = 0.0
	r.revives = 0
	r.hurt(999.0)
	await _wait(6)
	_ok(main.run == null, "dying ends the run")
	print("flow fails=", fails, " coins=", Save.d.coins)
	get_tree().quit()


func _new_run(stage: int = 0, ch: String = "hank"):
	Save.d = Save._default()
	main.start_run(stage, 0, ch, false)
	await _wait(3)
	return main.run


func _end_run() -> void:
	if main.run != null:
		main.run.give_up()
	await _wait(3)
	get_tree().paused = false


func _pool_clean(r) -> bool:
	var seen := {}
	for s in r.enemies.pool:
		if seen.has(s):
			return false
		seen[s] = true
	for e in r.enemies.alive:
		if seen.has(e.spr):
			return false
	return true


## Regression tests for edge cases that normal play rarely reaches.
func _bugs() -> void:
	# dying on the same frame as a level up must not freeze the results screen
	var r = await _new_run()
	r.enemies.spawn("carrot", r.player_pos, {"force": true})
	r._add_pickup("gem_3", r.player_pos, 500.0)
	r.hp = 1.0
	r.iframes = 0.0
	r.stats.armor = 0.0
	await _wait(6)
	_ok(main.run == null and main.current is Screens.Results, "death + level up reaches results")
	_ok(not get_tree().paused, "game is not left paused after death + level up")
	get_tree().paused = false

	# same with a chest
	r = await _new_run()
	r.enemies.spawn("carrot", r.player_pos, {"force": true})
	r._add_pickup("pickup_chest", r.player_pos, 1.0)
	r.hp = 1.0
	r.iframes = 0.0
	r.stats.armor = 0.0
	await _wait(6)
	_ok(not get_tree().paused, "game is not left paused after death + chest")
	get_tree().paused = false

	# revive triggered by a bullet (the screen wipe clears the bullet list mid-loop)
	r = await _new_run()
	for i in 12:
		r.enemies.fire_bullet("seed", r.player_pos + Vector2(i, 0), Vector2.ZERO, 500.0, 4.0)
	r.hp = 1.0
	r.iframes = 0.0
	r.revives = 1
	await _wait(8)
	_ok(r.revives == 0 and r.alive_flag, "bullet revive survives")
	_ok(_pool_clean(r), "sprite pool intact after bullet revive")
	await _end_run()

	# revive triggered by an exploding chili, inside the enemy loop
	r = await _new_run()
	for i in 80:
		r.enemies.spawn("pea", r.player_pos + Vector2.from_angle(i) * 120.0, {"force": true})
	var ch = r.enemies.spawn("chili", r.player_pos + Vector2(4, 0), {"force": true})
	ch.state = 1
	ch.state_t = 0.0
	ch.dmg = 5000.0
	r.hp = 1.0
	r.iframes = 0.0
	r.revives = 1
	await _wait(8)
	_ok(r.alive_flag and _pool_clean(r), "explosion revive keeps enemy list consistent")
	await _end_run()

	# boss telegraphs must not hurt
	r = await _new_run()
	r.enemies.add_hazard(r.player_pos, 40.0, 0.0, 0.2, 0.0, Color.WHITE)
	var hp0: float = r.hp
	await _wait(5)
	_ok(r.hp >= hp0, "zero-damage telegraph does no damage")
	await _end_run()

	# banish must remove owned items as well
	r = await _new_run()
	r.weapons.add_weapon("pitchfork")
	r.banished["pitchfork"] = true
	var seen := false
	for i in 200:
		for o in r.hud._options():
			if o.id == "pitchfork":
				seen = true
	_ok(not seen, "banished owned item never offered")
	await _end_run()

	_ok(not ("." in UI.delta_text({"dmg": 4.0})), "whole numbers without decimals: " + UI.delta_text({"dmg": 4.0}))

	# running away from a boss must not strand it forever
	r = await _new_run()
	var b = r.enemies.spawn("boss_gourd", r.player_pos + Vector2(2000, 0), {"force": true})
	var m = r.enemies.spawn("potato", r.player_pos + Vector2(-2000, 0), {"mid": true, "force": true, "hp": 10.0})
	await _wait(5)
	_ok(b.pos.distance_to(r.player_pos) < 480.0, "boss returns when the player runs off")
	_ok(m.pos.distance_to(r.player_pos) < 480.0, "giant returns when the player runs off")
	await _end_run()

	# two chests at once open one after the other
	r = await _new_run()
	r._add_pickup("pickup_chest", r.player_pos, 1.0)
	r._add_pickup("pickup_chest", r.player_pos, 1.0)
	await _wait(6)
	_ok(r.hud.overlay != null and r.pending_chests == 1, "second chest waits its turn")
	r.hud.close_overlay()
	await _wait(5)
	_ok(r.hud.overlay != null and r.pending_chests == 0, "second chest then opens")
	r.hud.close_overlay()
	await _end_run()

	# Esc inside options, opened from pause, returns to pause and keeps the run alive
	r = await _new_run()
	await _press("pause")
	await _wait(3)
	r.hud._pause_options()
	await _wait(3)
	await _press("pause")
	await _wait(4)
	_ok(get_tree().paused and r.hud.overlay != null and main.run != null, "Esc in options goes back to pause")
	await _press("pause")
	await _wait(4)
	_ok(not get_tree().paused, "Esc again resumes")
	await _end_run()

	# give up while paused
	r = await _new_run()
	await _press("pause")
	await _wait(3)
	r.hud.close_overlay()
	r.give_up()
	await _wait(4)
	_ok(main.current is Screens.Results and not get_tree().paused, "give up lands on results")

	# broken saves must never stop the game from starting
	var broken := ["", "garbage{{{", "[1,2,3]", JSON.stringify({"coins": "abc", "settings": 5, "meta": 7, "buildings": [1], "chars": 3, "cleared": "x"})]
	for txt in broken:
		var f := FileAccess.open(Save.path, FileAccess.WRITE)
		f.store_string(txt)
		f.close()
		Save.load_game()
		var good: bool = Save.d.settings is Dictionary and Save.d.meta is Dictionary and Save.d.buildings is Dictionary and Save.d.chars is Dictionary and Save.d.cleared is Dictionary
		_ok(good and Save.coins_per_second() >= 0.0 and Save.stage_cleared_rad(0) == -1, "broken save handled: " + str(txt).left(20))
	Save.d = Save._default()

	await _xp_chest_tests()
	await _guide_tests()
	await _danger_tests()
	print("bugs fails=", fails)
	get_tree().quit()




## Random everything: all weapons, bosses, deaths, revives, pauses, locales.
func _chaos() -> void:
	seed(int(arg[1]))
	Save.d = Save._default()
	var rounds := 0
	var peak := 0
	for round_i in int(arg[2]):
		rounds += 1
		Save.d.settings.locale = ["en", "pt_BR", "es", "fr"].pick_random()
		Save.apply_settings()
		var ch: Dictionary = DB.CHARACTERS.pick_random()
		main.start_run(randi() % 3, randi() % 4, ch.id, true)
		var r = main.run
		r.time = randf_range(0.0, DB.STAGE_LENGTH - 20.0)
		r.stats.max_hp = 60.0
		r.hp = 60.0
		r.revives = randi() % 3
		for id in DB.WEAPONS:
			if r.weapons.slots.size() < 6 and randf() < 0.8 and r.weapons.has_weapon(id) == null:
				r.weapons.add_weapon(id)
		for s in r.weapons.slots:
			s.level = randi_range(1, 8)
			s.evolved = randf() < 0.4
			r.weapons.refresh(s)
		r.hud.refresh_items()
		for i in 2400:
			await get_tree().process_frame
			if main.run == null:
				break
			var a := randi() % 400
			match a:
				0:
					r._add_pickup("pickup_dynamite", r.player_pos, 1.0)
				1:
					r._add_pickup("pickup_magnet", r.player_pos, 1.0)
				2:
					r.pending_levels += 1
				3:
					r.pending_chests += 1
				4:
					r.time = DB.STAGE_LENGTH
				5:
					r.hud.open_pause()
					await _wait(3)
					if main.run != null:
						r.hud.close_overlay()
				6:
					r.gain_xp(500.0)
				7:
					if r.enemies.boss_ref != null:
						r.enemies.boss_ref.hp = 1.0
				8:
					r.iframes = 0.0
					r.hurt(30.0)
				9:
					r.enemies.spawn("chili", r.player_pos + Vector2(6, 0), {"force": true})
				10:
					r._add_pickup("pickup_xpchest", r.player_pos, 1.0)
			peak = maxi(peak, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		if main.run != null:
			main.run.give_up()
		await _wait(3)
		_ok(main.current is Screens.Results and main.run == null and not get_tree().paused, "round %d ended on a usable screen" % rounds)
		get_tree().paused = false
	print("chaos rounds=", rounds, " peak_nodes=", peak, " fails=", fails)
	get_tree().quit()


func _gems_on_floor(r) -> int:
	var n := 0
	for p in r.pickups:
		if String(p.kind).begins_with("gem"):
			n += 1
	return n


func _xp_chest_tests() -> void:
	# opening it pays XP and pulls in every crystal, however far away
	var r = await _new_run()
	for i in 60:
		r._add_pickup("gem_1", r.player_pos + Vector2.from_angle(i) * (300.0 + i * 12.0), 1.0)
	r._add_pickup("pickup_coin", r.player_pos + Vector2(600, 0), 1.0)
	r.bot = true  # answers the level-up menu, which pauses the game
	var before: int = _gems_on_floor(r)
	var placed: Array = r.pickups.filter(func(p): return String(p.kind).begins_with("gem"))
	var lvl: int = r.level
	var xp0: float = r.xp
	_ok(before == 60, "test crystals placed")
	r._add_pickup("pickup_xpchest", r.player_pos, 1.0)
	await _wait(2)
	_ok(r.level > lvl or r.xp > xp0, "XP chest grants experience")
	await _wait(200)
	var left := 0
	var fresh := 0
	for p in r.pickups:
		if String(p.kind).begins_with("gem"):
			if placed.any(func(q): return is_same(q, p)):
				left += 1
			else:
				fresh += 1
	print("crystals left from the original 60: ", left, ", dropped since by kills: ", fresh)
	_ok(left == 0, "XP chest pulls in every crystal")
	var coin_left := false
	for p in r.pickups:
		if p.kind == "pickup_coin":
			coin_left = true
	_ok(coin_left, "XP chest attracts crystals only")
	_ok(r.level > lvl, "crystals and bonus level the farmer up")
	while r.hud.overlay != null or r.pending_levels > 0:
		if r.hud.overlay != null:
			r.hud.close_overlay()
		await _wait(2)
	await _end_run()

	# the bonus is one full level, whatever the current level
	r = await _new_run()
	r.level = 30
	r.xp_next = 200.0
	r.xp = 0.0
	r.stats.growth = 1.0
	r._open_xp_chest()
	_ok(r.level == 31, "bonus equals one level")
	r.hud.close_overlay()
	await _end_run()

	# it appears on its own, on screen, without being asked
	r = await _new_run()
	r.next_xp_chest = 0.0
	r.time = 50.0
	await _wait(3)
	var found = null
	for p in r.pickups:
		if p.kind == "pickup_xpchest":
			found = p
	_ok(found != null, "XP chest spawns on a timer")
	_ok(found != null and r.view_rect().has_point(found.pos), "spawned XP chest is on screen")
	_ok(r.next_xp_chest > 50.0, "timer is rescheduled")
	await _end_run()

	# dying while opening it must not freeze the game
	r = await _new_run()
	r.enemies.spawn("carrot", r.player_pos, {"force": true})
	r._add_pickup("pickup_xpchest", r.player_pos, 1.0)
	r.hp = 1.0
	r.iframes = 0.0
	r.stats.armor = 0.0
	await _wait(6)
	_ok(main.current is Screens.Results and not get_tree().paused, "death + XP chest reaches results")
	get_tree().paused = false

	# giants always carry one
	r = await _new_run()
	r.drop_from(r.enemies.spawn("potato", r.player_pos + Vector2(100, 0), {"mid": true, "force": true}))
	var has := false
	for p in r.pickups:
		has = has or p.kind == "pickup_xpchest"
	_ok(has, "giant drops an XP chest")
	await _end_run()

	for code in ["en", "pt_BR", "es", "fr"]:
		TranslationServer.set_locale(code)
		_ok(tr("HUD_XPCHEST") != "HUD_XPCHEST" and "%s" in tr("HUD_XPCHEST"), "XP chest text in " + code)
	TranslationServer.set_locale("en")

	# atomic save still round-trips
	Save.d = Save._default()
	Save.d.coins = 777.0
	Save.save_game()
	Save.save_game()
	Save.d = {}
	Save.load_game()
	_ok(float(Save.d.coins) == 777.0, "save round trip")
	_ok(not FileAccess.file_exists(Save.path + ".tmp"), "no temp file left behind")

	# the player's real save keeps loading (read only: nothing is written back)
	var real := "user://farmer_survivors.save"
	if FileAccess.file_exists(real):
		Save.path = real
		Save.load_game()
		Save.path = "user://dev_test.save"
		_ok(Save.d.settings is Dictionary and float(Save.d.coins) >= 0.0, "existing player save loads")
		Save.d = Save._default()


## The explanations must fit on screen in every language at every stage of progress.
func _guide_tests() -> void:
	var states := [
		{"cleared": {}, "stage": 0, "rad": 0, "boss": "BOSS_GOURD"},
		{"cleared": {"0": 0}, "stage": 1, "rad": 0, "boss": "BOSS_CORN"},
		{"cleared": {"0": 2, "1": 0}, "stage": 2, "rad": 0, "boss": "BOSS_ROOT"},
		{"cleared": {"0": 3, "1": 1, "2": 0}, "stage": 0, "rad": 3, "boss": ""},
	]
	for code in ["en", "pt_BR", "es", "fr"]:
		for st in states:
			Save.d = Save._default()
			Save.d.settings.locale = code
			Save.apply_settings()
			Save.d.cleared = st.cleared
			Save.d.selected_stage = st.stage
			Save.d.selected_rad = st.rad
			main.show_hub()
			await _wait(6)
			var hub = main.current
			var text := ""
			var worst := 0.0
			var wide := 0.0
			for n in hub.find_children("*", "Label", true, false):
				var l: Label = n
				if l.is_visible_in_tree():
					text += l.text + "\n"
					worst = maxf(worst, l.get_global_rect().end.y)
					wide = maxf(wide, l.get_global_rect().end.x)
			var go: Button = hub.exp_buttons["go"]
			var label := "%s stage %d" % [code, st.stage]
			_ok(go.get_global_rect().end.y <= 356.0 and worst <= 356.0 and wide <= 640.0, "fits on screen: " + label + " bottom=%d" % maxf(go.get_global_rect().end.y, worst))
			if st.boss != "":
				_ok(tr(st.boss) in text, "names the boss to beat: " + label)
			_ok(tr("HUB_RAD_WHAT") in text, "explains radiation: " + label)
	# a locked field says which boss opens it
	Save.d = Save._default()
	Save.d.settings.locale = "pt_BR"
	Save.apply_settings()
	main.show_hub()
	await _wait(6)
	var b2: Button = main.current.exp_buttons["stage_1"]
	var b3: Button = main.current.exp_buttons["stage_2"]
	_ok(b2.disabled and tr("BOSS_GOURD") in b2.text, "locked field 2 names its boss: " + b2.text)
	_ok(b3.disabled and tr("BOSS_CORN") in b3.text, "locked field 3 names its boss: " + b3.text)
	# results tell the player what just happened
	var notes = main.progress_notes(0, 0, true, Save.stage_unlocked(1), Save.max_rad(0))
	_ok(notes.is_empty(), "no note before the state changes")
	var had_stage := Save.stage_unlocked(1)
	var had_rad := Save.max_rad(0)
	Save.record_clear(0, 0)
	notes = main.progress_notes(0, 0, true, had_stage, had_rad)
	_ok(notes.size() == 2 and tr("STAGE_2") in notes[0], "first win announces field and radiation")
	notes = main.progress_notes(0, 0, true, Save.stage_unlocked(1), Save.max_rad(0))
	_ok(notes.is_empty(), "a repeat win announces nothing")
	Save.d = Save._default()
	notes = main.progress_notes(0, 0, false, false, 0)
	_ok(notes.size() == 1 and tr("BOSS_GOURD") in notes[0], "a loss says what is needed")
	notes = main.progress_notes(2, 0, false, false, 0)
	_ok(notes.is_empty(), "the last field needs no unlock hint")
	Save.d.settings.locale = "en"
	Save.apply_settings()
	Save.d = Save._default()


func _set_hp(r, pct: float) -> void:
	r.hp = float(r.stats.max_hp) * pct
	r.iframes = 99.0
	await _wait(2)


## Low health: pulsing red edges below 10%, action music until 15%.
func _danger_tests() -> void:
	_ok(ResourceLoader.exists("res://assets/audio/music_danger.wav"), "action track exists")
	var st: AudioStreamWAV = load("res://assets/audio/music_danger.wav")
	_ok(st.get_length() > 10.0, "action track length %.1fs" % st.get_length())

	var r = await _new_run()
	r.next_elite = 9999.0
	_ok(not r.hud.danger_rect.visible and Audio.current_track == "battle", "healthy: no red edge, normal music")
	await _set_hp(r, 0.5)
	_ok(not r.hud.danger_rect.visible, "50% health: no red edge")
	await _set_hp(r, 0.10)
	_ok(not r.hud.danger_rect.visible and Audio.current_track == "battle", "exactly 10%: not yet")
	await _set_hp(r, 0.09)
	_ok(r.hud.danger_rect.visible, "below 10%: red edge on")
	_ok(Audio.current_track == "danger", "below 10%: action music on")
	var a: float = r.hud.danger_rect.material.get_shader_parameter("intensity")
	var low := a
	var high := a
	get_tree().paused = true  # freezes the run, while the warning keeps beating
	var until := Time.get_ticks_msec() + 700
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var v: float = r.hud.danger_rect.material.get_shader_parameter("intensity")
		low = minf(low, v)
		high = maxf(high, v)
	get_tree().paused = false
	_ok(high - low > 0.3, "red edge pulses, even paused: %.2f to %.2f" % [low, high])
	await _press("pause")
	await _wait(3)
	_ok(r.hud.danger_rect.visible and Audio.current_track == "danger", "pausing keeps the warning")
	await _press("pause")
	await _wait(3)
	await _set_hp(r, 0.12)
	_ok(not r.hud.danger_rect.visible, "12%: red edge off")
	_ok(Audio.current_track == "danger", "12%: action music holds, no flip-flop")
	await _set_hp(r, 0.09)
	await _set_hp(r, 0.14)
	_ok(Audio.current_track == "danger", "14%: action music still holds")
	await _set_hp(r, 0.15)
	_ok(Audio.current_track == "battle", "15%: normal music returns")
	await _end_run()

	# a boss arriving during the warning must not steal the music, and gets it after
	r = await _new_run()
	await _set_hp(r, 0.05)
	r.time = DB.STAGE_LENGTH
	await _wait(3)
	_ok(r.enemies.boss_ref != null and Audio.current_track == "danger", "boss arrival keeps the action music")
	await _set_hp(r, 0.5)
	_ok(Audio.current_track == "boss", "healing during a boss returns to the boss theme")
	await _set_hp(r, 0.05)
	_ok(Audio.current_track == "danger", "boss fight: low health switches again")
	r.enemies.damage(r.enemies.boss_ref, 9e9)
	await _wait(3)
	_ok(not r.hud.danger_rect.visible, "winning clears the warning")
	r.win_timer = 0.01
	await _wait(5)
	_ok(main.run == null and Audio.current_track == "menu", "after the win the menu music plays")
	get_tree().paused = false

	# death in danger
	r = await _new_run()
	await _set_hp(r, 0.05)
	r.iframes = 0.0
	r.stats.armor = 0.0
	r.revives = 0
	r.hurt(9e9)
	await _wait(4)
	_ok(main.run == null and Audio.current_track == "menu", "dying leaves the action music")
	# a revive heals to 50%, so the warning ends
	r = await _new_run()
	await _set_hp(r, 0.05)
	r.iframes = 0.0
	r.stats.armor = 0.0
	r.revives = 1
	r.hurt(9e9)
	await _wait(4)
	_ok(not r.hud.danger_rect.visible and Audio.current_track == "battle", "revive ends the warning")
	await _end_run()


# --- Store page assets ------------------------------------------------------------

func _logo_card(bg: String, size: Vector2i, one_line: bool, out: String, zoom: int = 2) -> void:
	var sv := SubViewport.new()
	sv.size = size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.disable_3d = true
	add_child(sv)
	var root := Control.new()
	root.theme = UI.theme()
	root.size = Vector2(size)
	sv.add_child(root)
	var img := Image.load_from_file(bg)
	var t := TextureRect.new()
	t.texture = ImageTexture.create_from_image(img)
	t.size = Vector2(size)
	root.add_child(t)
	var w := float(size.x)
	if one_line:
		var a := UI.title("FARMER SURVIVORS", 48, Color("ffe066"))
		a.add_theme_constant_override("outline_size", 8)
		a.position = Vector2(0, 8)
		a.size = Vector2(w, 56)
		root.add_child(a)
	else:
		var a := UI.title("FARMER", 48, Color("ffe066"))
		a.add_theme_constant_override("outline_size", 8)
		a.position = Vector2(0, 2)
		a.size = Vector2(w, 54)
		root.add_child(a)
		var b := UI.title("SURVIVORS", 48, Color("b8ff3a"))
		b.add_theme_constant_override("outline_size", 8)
		b.position = Vector2(0, 42)
		b.size = Vector2(w, 54)
		root.add_child(b)
	await _wait(6)
	await RenderingServer.frame_post_draw
	var shot := sv.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	shot.resize(size.x * zoom, size.y * zoom, Image.INTERPOLATE_NEAREST)
	shot.save_png(out)
	print("store ", out.get_file(), " ", shot.get_size())
	sv.queue_free()


func _store_shot(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	img.save_png(dir + "/" + name + ".png")
	print("store ", name)


## Sets up a mid-game run, lets the bot genuinely play it, then captures.
func _store_run(dir: String, name: String, stage: int, ch: String, t: float, weapons: Array, menu: bool = false) -> void:
	Save.d = Save._default()
	Save.d.seen_intro = true
	for m in DB.META:
		Save.d.meta[m.id] = min(4, int(m.max))
	Save.d.meta["amount"] = 0
	Save.d.settings.shake = false
	Save.apply_settings()
	main.start_run(stage, 0, ch, true)
	var r = main.run
	r.time = maxf(t - 40.0, 0.0)
	r.next_elite = r.time + 20.0
	r.next_swarm = r.time + 25.0
	r.wave_i = 0
	for i in 70:
		r.enemies.spawn(r.stage.waves[-1].pool.pick_random(), r.player_pos + Vector2.from_angle(randf() * TAU) * randf_range(170.0, 260.0))
	r.level = 22
	r.xp_next = 110.0
	for id in weapons:
		if r.weapons.has_weapon(id) == null:
			r.weapons.add_weapon(id)
	for s in r.weapons.slots:
		s.level = randi_range(4, 7)
		r.weapons.refresh(s)
	for id in ["hat", "boots", "whetstone"]:
		r.weapons.add_passive(id)
	r.hud.refresh_items()
	Engine.time_scale = 2.0
	while main.run != null and r.time < t:
		r.hp = float(r.stats.max_hp) * 0.82
		await get_tree().process_frame
	Engine.time_scale = 1.0
	if main.run == null:
		print("store run ended early ", name)
		return
	if menu:
		r.bot = false
		await _wait(2)
		if r.hud.overlay != null:
			r.hud.close_overlay()
		r.hud._show_level_up(r.hud._options())
		await _wait(4)
	await _store_shot(dir, name)
	if menu:
		r.hud.close_overlay()
	r.give_up()
	await _wait(3)


func _store() -> void:
	var d := "C:" + arg[1]
	seed(2026)
	await _logo_card(d + "/keyart.png", Vector2i(315, 250), false, d + "/cover.png")
	await _logo_card(d + "/keyart_wide.png", Vector2i(480, 150), true, d + "/banner.png")
	await _store_run(d, "shot_1_field", 0, "hank", 400.0, ["scythe", "pitchfork", "sickles", "lightning"])
	await _store_run(d, "shot_2_canal", 1, "mabel", 330.0, ["shotgun", "weedkiller", "bees", "scarecrow"])
	await _store_run(d, "shot_3_reactor", 2, "rosa", 250.0, ["bees", "lightning", "tractor", "pitchfork"])
	await _store_run(d, "shot_4_boss", 0, "tucker", DB.STAGE_LENGTH + 6.0, ["tractor", "sickles", "scythe", "lightning"])
	await _store_run(d, "shot_5_levelup", 1, "hank", 200.0, ["scythe", "bees", "scarecrow"], true)
	await _store_run(d, "shot_6_final", 2, "hank", DB.STAGE_LENGTH + 8.0, ["scythe", "tractor", "lightning", "weedkiller", "bees"])
	Save.d = Save._default()
	Save.d.coins = 48210.0
	Save.d.seen_intro = true
	Save.d.cleared = {"0": 2, "1": 0}
	Save.d.journal = 3
	Save.d.chars = {"hank": true, "mabel": true, "rosa": true}
	Save.d.buildings = {"coop": 26, "barn": 14, "silo": 7, "windmill": 2}
	Save.d.meta = {"might": 7, "vitality": 6, "greed": 9, "reach": 4, "haste": 3, "regen": 2, "luck": 2, "magnet": 3}
	Save.apply_settings()
	main.show_hub()
	await _wait(8)
	main.current._set_tab("workshop")
	await _wait(8)
	await _store_shot(d, "shot_7_workshop")
	main.current._set_tab("farm")
	await _wait(8)
	await _store_shot(d, "shot_8_farm")
	get_tree().quit()


## Web portal covers. `gen_sprites` must have written the keyart_* files first.
func _covers() -> void:
	var d := "C:" + arg[1]
	await _logo_card(d + "/keyart_land.png", Vector2i(480, 270), false, d + "/cover_landscape.png", 4)
	await _logo_card(d + "/keyart_port.png", Vector2i(400, 600), false, d + "/cover_portrait.png")
	await _logo_card(d + "/keyart_sq.png", Vector2i(400, 400), false, d + "/cover_square.png")
	get_tree().quit()


## Real bot gameplay for preview videos, run with --write-movie. Nothing is sped up.
func _trailer() -> void:
	seed(2026)
	Save.d = Save._default()
	Save.d.seen_intro = true
	for m in DB.META:
		Save.d.meta[m.id] = min(4, int(m.max))
	Save.d.settings.shake = false
	Save.d.settings.music = 0.0
	Save.d.settings.sfx = 0.0
	Save.apply_settings()
	main.start_run(1, 0, "hank", true)
	var r = main.run
	r.time = 300.0
	r.next_elite = r.time + 6.0
	r.next_swarm = r.time + 3.0
	r.wave_i = 0
	r.level = 22
	r.xp_next = 99999.0
	for id in ["scythe", "bees", "lightning", "tractor", "sickles"]:
		if r.weapons.has_weapon(id) == null:
			r.weapons.add_weapon(id)
	for s in r.weapons.slots:
		s.level = randi_range(4, 7)
		r.weapons.refresh(s)
	for id in ["hat", "boots", "whetstone"]:
		r.weapons.add_passive(id)
	r.hud.refresh_items()
	for i in 90:
		r.enemies.spawn(r.stage.waves[-1].pool.pick_random(), r.player_pos + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 300.0))
	var left := 19.0
	while left > 0.0 and main.run != null:
		r.hp = float(r.stats.max_hp) * 0.82
		left -= get_process_delta_time()
		await get_tree().process_frame
	get_tree().quit()
