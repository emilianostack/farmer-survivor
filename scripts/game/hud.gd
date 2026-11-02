## In-run interface: bars, banners, level-up choices, chests and the pause menu.
extends CanvasLayer

var run: Node2D
var root: Control
var xp_fill: ColorRect
var xp_back: ColorRect
var lvl_label: Label
var time_label: Label
var kill_label: Label
var coin_label: Label
var items_box: HBoxContainer
var boss_box: Control
var boss_fill: ColorRect
var boss_name: Label
var banner_label: Label
var overlay: Control = null
var _banner_tween: Tween
var danger_rect: ColorRect


func setup(r: Node2D) -> void:
	run = r
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.theme = UI.theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_danger()
	xp_back = ColorRect.new()
	xp_back.color = Color("1c1828")
	xp_back.position = Vector2(0, 0)
	xp_back.size = Vector2(640, 8)
	root.add_child(xp_back)
	xp_fill = ColorRect.new()
	xp_fill.color = Color("7fe84b")
	xp_fill.position = Vector2(1, 1)
	xp_fill.size = Vector2(0, 5)
	root.add_child(xp_fill)
	lvl_label = _lab(Vector2(584, 6), Vector2(52, 16), HORIZONTAL_ALIGNMENT_RIGHT, 16)
	time_label = _lab(Vector2(270, 8), Vector2(100, 22), HORIZONTAL_ALIGNMENT_CENTER, 24)
	time_label.add_theme_font_override("font", UI.title_font())
	kill_label = _lab(Vector2(490, 22), Vector2(146, 16), HORIZONTAL_ALIGNMENT_RIGHT, 16)
	coin_label = _lab(Vector2(490, 36), Vector2(146, 16), HORIZONTAL_ALIGNMENT_RIGHT, 16, UI.COL_GOLD)
	items_box = HBoxContainer.new()
	items_box.position = Vector2(4, 11)
	items_box.add_theme_constant_override("separation", 1)
	root.add_child(items_box)
	boss_box = Control.new()
	boss_box.position = Vector2(120, 334)
	boss_box.size = Vector2(400, 20)
	boss_box.visible = false
	root.add_child(boss_box)
	var bb := ColorRect.new()
	bb.color = Color("140c1c")
	bb.size = Vector2(400, 10)
	bb.position = Vector2(0, 8)
	boss_box.add_child(bb)
	boss_fill = ColorRect.new()
	boss_fill.color = Color("e8423a")
	boss_fill.position = Vector2(1, 9)
	boss_fill.size = Vector2(398, 8)
	boss_box.add_child(boss_fill)
	boss_name = UI.label("", 16, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	boss_name.size = Vector2(400, 14)
	boss_name.position = Vector2(0, -8)
	boss_name.add_theme_constant_override("outline_size", 3)
	boss_box.add_child(boss_name)
	banner_label = UI.title("", 32, UI.COL_GOOD)
	banner_label.position = Vector2(0, 64)
	banner_label.size = Vector2(640, 44)
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)


func _lab(p: Vector2, s: Vector2, al: int, size: int, col: Color = UI.COL_TEXT) -> Label:
	var l := UI.label("", size, col, al)
	l.position = p
	l.size = s
	l.add_theme_constant_override("outline_size", 3)
	root.add_child(l)
	return l


func update_bars() -> void:
	xp_fill.size.x = 638.0 * clampf(run.xp / run.xp_next, 0.0, 1.0)
	lvl_label.text = tr("HUD_LEVEL") % run.level
	time_label.text = UI.time_str(run.time)
	kill_label.text = tr("HUD_KILLS") % Save.fmt(run.kills)
	coin_label.text = tr("HUD_COINS") % Save.fmt(floorf(run.run_coins))
	var b = run.enemies.boss_ref
	boss_box.visible = b != null
	if b != null:
		boss_name.text = tr(b.data.name)
		boss_fill.size.x = 398.0 * clampf(b.hp / b.max_hp, 0.0, 1.0)
		boss_fill.color = Color("ff8a2a") if b.enraged else Color("e8423a")


func refresh_items() -> void:
	for c in items_box.get_children():
		c.queue_free()
	for s in run.weapons.slots:
		items_box.add_child(UI.icon(s.id, 0.82))
	for id in run.weapons.passives:
		items_box.add_child(UI.icon(id, 0.82))


func banner(txt: String, col: Color) -> void:
	banner_label.text = txt
	banner_label.add_theme_color_override("font_color", col)
	if _banner_tween:
		_banner_tween.kill()
	banner_label.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.5)


func is_busy() -> bool:
	return overlay != null


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		if overlay == null and not run.finished and run.win_timer < 0.0:
			open_pause()
			get_viewport().set_input_as_handled()
		elif overlay != null and overlay.has_meta("pause"):
			close_overlay()
			get_viewport().set_input_as_handled()


func _open(c: Control) -> void:
	overlay = c
	root.add_child(c)
	get_tree().paused = true


func close_overlay() -> void:
	if overlay:
		overlay.queue_free()
	overlay = null
	get_tree().paused = false


# --- Level up ---------------------------------------------------------------------

func _options() -> Array:
	var w = run.weapons
	var pool := []
	for s in w.slots:
		if s.level < DB.MAX_WEAPON_LEVEL:
			if not run.banished.has(s.id):
				pool.append({"type": "weapon", "id": s.id, "weight": 3.0})
	for id in w.passives:
		if int(w.passives[id]) < DB.MAX_PASSIVE_LEVEL:
			if not run.banished.has(id):
				pool.append({"type": "passive", "id": id, "weight": 2.0})
	if w.slots.size() < DB.MAX_WEAPONS:
		for id in DB.WEAPONS:
			if w.has_weapon(id) == null and not run.banished.has(id):
				pool.append({"type": "weapon", "id": id, "weight": 1.5})
	if w.passives.size() < DB.MAX_PASSIVES:
		for id in DB.PASSIVES:
			if not w.passives.has(id) and not run.banished.has(id):
				pool.append({"type": "passive", "id": id, "weight": 1.0})
	var n := 3
	if randf() < (float(run.stats.luck) - 1.0) * 0.5:
		n = 4
	var picks := []
	while picks.size() < n and not pool.is_empty():
		var total := 0.0
		for o in pool:
			total += float(o.weight)
		var r := randf() * total
		for i in pool.size():
			r -= float(pool[i].weight)
			if r <= 0.0:
				picks.append(pool[i])
				pool.remove_at(i)
				break
	if picks.is_empty():
		picks = [{"type": "coins", "id": "coin"}, {"type": "heal", "id": "heart"}]
	return picks


func _describe(o: Dictionary) -> Dictionary:
	var w = run.weapons
	match String(o.type):
		"coins":
			return {"name": tr("LVL_COINS"), "desc": tr("LVL_COINS_D"), "tag": ""}
		"heal":
			return {"name": tr("LVL_HEAL"), "desc": tr("LVL_HEAL_D"), "tag": ""}
		"weapon":
			var s = w.has_weapon(o.id)
			var nm := tr("WPN_" + String(o.id).to_upper())
			if s == null:
				return {"name": nm, "desc": tr("WPN_%s_D" % String(o.id).to_upper()), "tag": tr("LVL_NEW")}
			var delta: Dictionary = DB.WEAPONS[o.id].levels[s.level - 1]
			return {"name": nm, "desc": UI.delta_text(delta), "tag": tr("LVL_TAG") % (s.level + 1)}
		_:
			var cur := int(w.passives.get(o.id, 0))
			var nm := tr("PAS_" + String(o.id).to_upper())
			return {"name": nm, "desc": tr("PAS_%s_D" % String(o.id).to_upper()), "tag": tr("LVL_NEW") if cur == 0 else tr("LVL_TAG") % (cur + 1)}


func open_level_up() -> void:
	Audio.play("levelup", 0.0)
	var opts := _options()
	if run.bot:
		_apply(opts[0])
		return
	_show_level_up(opts)


func _show_level_up(opts: Array) -> void:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(UI.dim())
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	panel.custom_minimum_size = Vector2(400, 0)
	v.add_child(UI.title(tr("LVL_TITLE"), 24))
	var first: Button = null
	for o in opts:
		var b := _card(o)
		v.add_child(b)
		if first == null:
			first = b
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var rr := UI.button(tr("LVL_REROLL") % run.rerolls, func():
		run.rerolls -= 1
		overlay.queue_free()
		overlay = null
		_show_level_up(_options()))
	rr.disabled = run.rerolls <= 0
	row.add_child(rr)
	var sk := UI.button(tr("LVL_SKIP") % run.skips, func():
		run.skips -= 1
		close_overlay())
	sk.disabled = run.skips <= 0
	row.add_child(sk)
	var ba := UI.button(tr("LVL_BANISH") % run.banishes, func():
		_toggle_banish(c))
	ba.disabled = run.banishes <= 0
	row.add_child(ba)
	c.add_child(UI.center(panel))
	_open(c)
	first.grab_focus()


func _toggle_banish(c: Control) -> void:
	if c.has_meta("banish"):
		c.remove_meta("banish")
	else:
		c.set_meta("banish", true)
	banner(tr("LVL_BANISH_HINT") if c.has_meta("banish") else "", UI.COL_BAD)


func _card(o: Dictionary) -> Button:
	var info := _describe(o)
	var b := UI.button("", func():
		if overlay != null and overlay.has_meta("banish") and o.type != "coins" and o.type != "heal":
			run.banishes -= 1
			run.banished[o.id] = true
			overlay.queue_free()
			overlay = null
			_show_level_up(_options())
			return
		_apply(o), Vector2(384, 44))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.offset_right = -6
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 8)
	b.add_child(h)
	h.add_child(UI.icon(o.id, 1.5))
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_constant_override("separation", -2)
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nm := UI.label(info.name, 16, UI.COL_GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	top.add_child(UI.label(info.tag, 16, UI.COL_GOOD))
	t.add_child(top)
	var d := UI.wrapped(info.desc, 16)
	t.add_child(d)
	# keep text readable on the bright focus state
	var tint := func(on: bool):
		nm.add_theme_color_override("font_color", Color("5a1a10") if on else UI.COL_GOLD)
		d.add_theme_color_override("font_color", Color("2a1a14") if on else UI.COL_TEXT)
	b.focus_entered.connect(tint.bind(true))
	b.focus_exited.connect(tint.bind(false))
	return b


func _apply(o: Dictionary) -> void:
	var w = run.weapons
	match String(o.type):
		"weapon":
			if w.has_weapon(o.id):
				w.level_up(o.id)
			else:
				w.add_weapon(o.id)
		"passive":
			w.add_passive(o.id)
		"coins":
			run.run_coins += 25.0 * float(run.stats.greed)
		"heal":
			run.hp = minf(run.hp + 30.0, float(run.stats.max_hp))
	refresh_items()
	if overlay != null:
		close_overlay()


# --- Chest ------------------------------------------------------------------------

func open_chest() -> void:
	var w = run.weapons
	var lines := []
	var evo = w.evolvable()
	var coins := roundf(randf_range(30.0, 90.0) * float(run.stats.greed))
	run.run_coins += coins
	if evo != null:
		var e: Dictionary = DB.WEAPONS[evo.id].evo
		w.evolve(evo)
		lines.append({"icon": evo.id, "text": tr("CHEST_EVOLVED") % tr(e.name), "col": UI.COL_GOOD})
	else:
		var n := 1
		var r := randf()
		if r < 0.1 * float(run.stats.luck):
			n = 3
		for i in n:
			var cands := []
			for s in w.slots:
				if s.level < DB.MAX_WEAPON_LEVEL:
					cands.append(s)
			if cands.is_empty():
				break
			var s = cands.pick_random()
			w.level_up(s.id)
			lines.append({"icon": s.id, "text": tr("CHEST_LEVEL") % [tr("WPN_" + String(s.id).to_upper()), s.level], "col": UI.COL_TEXT})
	lines.append({"icon": "coin", "text": tr("CHEST_COINS") % Save.fmt(coins), "col": UI.COL_GOLD})
	refresh_items()
	if run.bot:
		return
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(UI.dim())
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	panel.custom_minimum_size = Vector2(300, 0)
	v.add_child(UI.title(tr("CHEST_TITLE"), 24))
	for l in lines:
		var h := HBoxContainer.new()
		h.add_child(UI.icon(l.icon))
		var t := UI.wrapped(l.text, 16, l.col)
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(t)
		v.add_child(h)
	var b := UI.button(tr("BTN_CONTINUE"), close_overlay)
	v.add_child(b)
	c.add_child(UI.center(panel))
	_open(c)
	b.grab_focus()


# --- Pause ------------------------------------------------------------------------

func open_pause() -> void:
	var c := Control.new()
	c.set_meta("pause", true)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(UI.dim())
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	panel.custom_minimum_size = Vector2(320, 0)
	v.add_child(UI.title(tr("PAUSE_TITLE"), 24))
	var grid := GridContainer.new()
	grid.columns = 4
	var st: Dictionary = run.stats
	var rows := [
		["STAT_MIGHT", "%d%%" % roundi(float(st.might) * 100)], ["STAT_AREA", "%d%%" % roundi(float(st.area) * 100)],
		["STAT_COOLDOWN", "%d%%" % roundi(float(st.cooldown) * 100)], ["STAT_SPEED", "%d%%" % roundi(float(st.speed) * 100)],
		["STAT_ARMOR", str(int(st.armor))], ["STAT_REGEN", "%.1f/s" % float(st.regen)],
		["STAT_LUCK", "%d%%" % roundi(float(st.luck) * 100)], ["STAT_HP", "%d/%d" % [roundi(run.hp), roundi(float(st.max_hp))]],
	]
	for r in rows:
		var n := UI.label(tr(r[0]), 16, UI.COL_MUTED)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(n)
		grid.add_child(UI.label(r[1] + "   ", 16))
	v.add_child(grid)
	var resume := UI.button(tr("BTN_RESUME"), close_overlay)
	v.add_child(resume)
	v.add_child(UI.button(tr("BTN_OPTIONS"), _pause_options))
	v.add_child(UI.button(tr("BTN_GIVEUP"), func():
		close_overlay()
		run.give_up()))
	c.add_child(UI.center(panel))
	_open(c)
	resume.grab_focus()


func _pause_options() -> void:
	var o: Control = run.get_parent().open_options(root)
	o.closed.connect(func():
		# Rebuild, as the language may have changed.
		close_overlay()
		open_pause())


# --- Low health warning -----------------------------------------------------------

const DANGER_SHADER := """
shader_type canvas_item;
uniform float intensity = 0.0;
const vec2 VIEW = vec2(640.0, 360.0);

void fragment() {
	vec2 px = floor(UV * VIEW);
	vec2 edge = min(px, VIEW - px);
	float dist = min(edge.x, edge.y * 1.25);
	// Stepped bands with a checker between them, to stay in the pixel-art style.
	float k = clamp(1.0 - dist / 84.0, 0.0, 1.0);
	float checker = mod(px.x + px.y, 2.0) * 0.08;
	float band = floor((k + checker) * 6.0) / 6.0;
	COLOR = vec4(1.0, 0.04, 0.06, pow(band, 1.25) * intensity);
}
"""


func _build_danger() -> void:
	var sh := Shader.new()
	sh.code = DANGER_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	danger_rect = ColorRect.new()
	danger_rect.material = mat
	danger_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_rect.visible = false
	root.add_child(danger_rect)


func set_danger(on: bool) -> void:
	danger_rect.visible = on


func _process(_delta: float) -> void:
	if danger_rect != null and danger_rect.visible:
		# About two pulses a second, sharpened so it beats instead of drifting.
		var wave := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 1.9)
		danger_rect.material.set_shader_parameter("intensity", 0.45 + 0.55 * wave * wave)
