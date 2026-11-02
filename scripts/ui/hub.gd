## The farm: choose an expedition, spend coins, grow the idle economy, read the story.
extends Control

signal start_run(stage: int, rad: int, char_id: String)
signal open_options
signal back

const TABS := ["expedition", "workshop", "farm", "journal"]

var tab := "expedition"
var body: Control
var coin_label: Label
var rate_label: Label
var info_label: Label
var journal_page := 0
var tab_buttons := {}
var focus_key := "go"
var exp_buttons := {}


func _ready() -> void:
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_music("menu")
	rebuild()
	Save.coins_changed.connect(_update_coins)


func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/story_0.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)
	var shade := UI.dim()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_right = -8
	root.offset_top = 6
	root.offset_bottom = -6
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	# header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	root.add_child(head)
	head.add_child(UI.title(tr("GAME_TITLE"), 24, UI.COL_GOOD, HORIZONTAL_ALIGNMENT_LEFT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var ci := VBoxContainer.new()
	ci.add_theme_constant_override("separation", -3)
	coin_label = UI.label("", 16, UI.COL_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	rate_label = UI.label("", 16, UI.COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	ci.add_child(coin_label)
	ci.add_child(rate_label)
	head.add_child(ci)
	head.add_child(UI.icon("coin"))
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	root.add_child(tabs)
	tab_buttons.clear()
	for t in TABS:
		var b := UI.button(tr("TAB_" + t.to_upper()), _set_tab.bind(t))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		tab_buttons[t] = b
	tabs.add_child(UI.button(tr("BTN_OPTIONS"), func(): open_options.emit()))
	tabs.add_child(UI.button(tr("BTN_BACK"), func(): back.emit()))
	body = PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_update_coins()
	_render()


func _update_coins() -> void:
	if not is_instance_valid(coin_label):
		return
	coin_label.text = Save.fmt(floorf(float(Save.d.coins)))
	var r := Save.coins_per_second()
	rate_label.text = (tr("HUB_RATE") % Save.fmt(r)) if r > 0.0 else ""


func _set_tab(t: String) -> void:
	tab = t
	_render()
	tab_buttons[t].grab_focus()


func _render() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for t in TABS:
		tab_buttons[t].modulate = Color.WHITE if t == tab else Color(0.72, 0.72, 0.8)
	match tab:
		"expedition": _expedition()
		"workshop": _workshop()
		"farm": _farm()
		"journal": _journal()


## Tight wrapped text, for the screens with a lot to say.
func _small(txt: String, col: Color) -> Label:
	var l := UI.wrapped(txt, 16, col)
	l.add_theme_constant_override("line_spacing", -3)
	return l


func _section(txt: String) -> Label:
	return UI.title(txt, 16, UI.COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT)


# --- Expedition -------------------------------------------------------------------

func _expedition() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 3)
	row.add_child(left)
	left.add_child(_section(tr("HUB_CHOOSE_FARMER")))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 4)
	left.add_child(grid)
	var sel: Dictionary = DB.CHARACTERS[0]
	for c in DB.CHARACTERS:
		if c.id == Save.d.selected_char:
			sel = c
		var cb := _char_button(c)
		grid.add_child(cb)
		exp_buttons["char_" + String(c.id)] = cb
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 4)
	left.add_child(who)
	var who_name := UI.title(tr(sel.name), 16, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	who_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(who_name)
	who.add_child(UI.icon(sel.weapon, 0.8))
	var wname := UI.label(tr("WPN_" + String(sel.weapon).to_upper()), 16, UI.COL_GOLD)
	wname.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(wname)
	var d := _small(tr(sel.desc), UI.COL_TEXT)
	left.add_child(d)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	row.add_child(right)
	right.add_child(_section(tr("HUB_CHOOSE_STAGE")))
	for s in DB.STAGES:
		var i: int = s.id
		var open := Save.stage_unlocked(i)
		var txt: String = tr(s.name)
		if not open:
			txt = tr("HUB_LOCKED_BY") % tr(DB.ENEMIES[DB.STAGES[i - 1].boss].name)
		elif Save.stage_cleared_rad(i) >= 0:
			txt += "  -  " + tr("HUB_CLEARED")
		var b := UI.button(txt, _pick_stage.bind(i), Vector2(0, 24))
		b.disabled = not open
		if i == int(Save.d.selected_stage):
			b.add_theme_color_override("font_color", UI.COL_GOOD)
		right.add_child(b)
		exp_buttons["stage_%d" % i] = b
	var si := int(Save.d.selected_stage)
	var st: Dictionary = DB.STAGES[si]
	right.add_child(_small(tr(st.desc), UI.COL_MUTED))
	var boss: String = tr(DB.ENEMIES[st.boss].name)
	var when := UI.time_str(DB.STAGE_LENGTH)
	var goal := ""
	if Save.stage_cleared_rad(si) >= 0:
		goal = tr("HUB_GOAL_DONE")
	elif si + 1 < DB.STAGES.size():
		goal = tr("HUB_GOAL_NEXT") % [boss, when, tr(DB.STAGES[si + 1].name)]
	else:
		goal = tr("HUB_GOAL_LAST") % [boss, when]
	right.add_child(_small(goal, UI.COL_GOLD))
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(gap)
	# Radiation: the control, what it is, what it does right now.
	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 4)
	left.add_child(rad)
	rad.add_child(UI.icon("rad"))
	var cur := int(Save.d.selected_rad)
	var lab := UI.label(tr("HUB_RAD") % cur, 16, UI.COL_GOOD)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rad.add_child(lab)
	var minus := UI.button("-", _rad.bind(-1), Vector2(22, 22))
	minus.disabled = cur <= 0
	rad.add_child(minus)
	exp_buttons["minus"] = minus
	var plus := UI.button("+", _rad.bind(1), Vector2(22, 22))
	var top_rad := Save.max_rad(si)
	plus.disabled = cur >= top_rad
	rad.add_child(plus)
	exp_buttons["plus"] = plus
	left.add_child(_small(tr("HUB_RAD_WHAT"), UI.COL_TEXT))
	var shown: int = maxi(cur, 1)
	var effect := "HUB_RAD_D" if cur > 0 else "HUB_RAD_NEXT"
	left.add_child(_small(tr(effect) % [roundi(pow(DB.RAD_HP, shown) * 100), roundi(pow(DB.RAD_DMG, shown) * 100), roundi(pow(DB.RAD_COINS, shown) * 100)], UI.COL_MUTED))
	right.add_child(_small(tr("HUB_RAD_UNLOCK") % [top_rad, top_rad + 1], UI.COL_GOOD))
	var go := UI.button(tr("BTN_START"), func():
		start_run.emit(int(Save.d.selected_stage), int(Save.d.selected_rad), String(Save.d.selected_char)), Vector2(0, 30))
	right.add_child(go)
	exp_buttons["go"] = go
	_restore_focus.call_deferred()


func _char_button(c: Dictionary) -> Button:
	var unlocked := Save.char_unlocked(c.id)
	var need_ok: bool = int(c.needs) < 0 or Save.stage_cleared_rad(int(c.needs)) >= 0
	var txt := ""
	if not unlocked:
		txt = Save.fmt(float(c.cost)) if need_ok else "?"
	var b := UI.button("", _pick_char.bind(c), Vector2(66, 64))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -2)
	b.add_child(v)
	var fr := UI.frame("res://assets/sprites/char_%s.png" % c.id, Rect2(0, 0, 30, 38))
	if not unlocked:
		fr.modulate = Color(0.1, 0.1, 0.15)
	v.add_child(fr)
	if not unlocked:
		var l := UI.label(txt, 16, UI.COL_GOLD if need_ok and float(Save.d.coins) >= float(c.cost) else UI.COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		l.add_theme_constant_override("outline_size", 3)
		v.add_child(l)
	elif c.id == Save.d.selected_char:
		v.add_child(UI.label(tr("HUB_SELECTED"), 16, UI.COL_GOOD, HORIZONTAL_ALIGNMENT_CENTER))
	b.disabled = not unlocked and not need_ok
	return b


func _pick_char(c: Dictionary) -> void:
	if not Save.char_unlocked(c.id):
		if not Save.spend(float(c.cost)):
			return
		Save.d.chars[c.id] = true
		Audio.play("buy", 0.0)
	Save.d.selected_char = c.id
	focus_key = "char_" + String(c.id)
	Save.save_game()
	_render()


func _pick_stage(i: int) -> void:
	Save.d.selected_stage = i
	focus_key = "stage_%d" % i
	Save.d.selected_rad = minf(int(Save.d.selected_rad), Save.max_rad(i))
	_render()


func _rad(delta: int) -> void:
	focus_key = "plus" if delta > 0 else "minus"
	Save.d.selected_rad = clampi(int(Save.d.selected_rad) + delta, 0, Save.max_rad(int(Save.d.selected_stage)))
	_render()


# --- Workshop ---------------------------------------------------------------------

func _workshop() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	body.add_child(v)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	v.add_child(grid)
	info_label = UI.wrapped(tr("WS_HINT"), 16, UI.COL_MUTED)
	var first: Button = null
	for m in DB.META:
		var b := _meta_button(m)
		grid.add_child(b)
		if first == null:
			first = b
	v.add_child(info_label)


func _meta_button(m: Dictionary) -> Button:
	var lv := Save.meta_level(m.id)
	var maxed: bool = lv >= int(m.max)
	var cost := Save.meta_cost(m)
	var key := "META_" + String(m.id).to_upper()
	var idx: int = DB.META.find(m)
	var b := UI.button("", func():
		if Save.buy_meta(m):
			Audio.play("buy", 0.0)
			_render()
			await get_tree().process_frame
			_focus_grid(idx), Vector2(150, 42))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 3
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	h.add_child(UI.icon(m.icon))
	var t := VBoxContainer.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.add_theme_constant_override("separation", -3)
	h.add_child(t)
	var nm := UI.label(tr(key), 16)
	var cl := UI.label(tr("WS_MAX") if maxed else Save.fmt(cost), 16, UI.COL_GOOD if maxed else (UI.COL_GOLD if float(Save.d.coins) >= cost else UI.COL_BAD))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cl)
	row.add_child(UI.label("  %d/%d" % [lv, int(m.max)], 16, UI.COL_MUTED))
	t.add_child(nm)
	t.add_child(row)
	b.disabled = maxed
	var hint := func():
		nm.add_theme_color_override("font_color", Color("2a1a14"))
		info_label.text = tr(key + "_D")
	b.focus_entered.connect(hint)
	b.focus_exited.connect(func(): nm.remove_theme_color_override("font_color"))
	return b


func _focus_grid(i: int) -> void:
	var grids := body.get_child(0).get_child(0)
	if i < grids.get_child_count():
		var b: Button = grids.get_child(i)
		if b.disabled:
			tab_buttons[tab].grab_focus()
		else:
			b.grab_focus()


# --- Farm -------------------------------------------------------------------------

func _farm() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	body.add_child(v)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	v.add_child(grid)
	for i in DB.BUILDINGS.size():
		grid.add_child(_building_button(DB.BUILDINGS[i], i))
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(bottom)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", -2)
	bottom.add_child(text)
	var soil := int(Save.d.soil)
	text.add_child(_section(tr("FARM_REPLANT")))
	text.add_child(UI.wrapped(tr("FARM_REPLANT_D") % [roundi(DB.SOIL_COIN_BONUS * 100), roundi(DB.SOIL_MIGHT_BONUS * 100)], 16, UI.COL_MUTED))
	text.add_child(UI.label(tr("FARM_SOIL") % soil, 16, UI.COL_GOOD))
	var gain := Save.soil_available()
	var rp := UI.button(tr("FARM_REPLANT_BTN") % maxf(gain, 0), func():
		Save.replant()
		Audio.play("win", 0.0)
		_render(), Vector2(150, 24))
	rp.disabled = gain <= 0
	rp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(rp)


func _building_button(bd: Dictionary, idx: int) -> Button:
	var n := Save.building_count(bd.id)
	var cost := Save.building_cost(bd)
	var b := UI.button("", func():
		if Save.buy_building(bd):
			Audio.play("buy", 0.0)
			_render()
			await get_tree().process_frame
			var grid: GridContainer = body.get_child(0).get_child(0)
			grid.get_child(idx).grab_focus(), Vector2(300, 46))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 4
	h.offset_right = -6
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 6)
	b.add_child(h)
	var img := TextureRect.new()
	img.texture = load("res://assets/sprites/bld_%s.png" % bd.id)
	img.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	img.custom_minimum_size = Vector2(34, 32)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(img)
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.add_theme_constant_override("separation", -3)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	var key := "BLD_" + String(bd.id).to_upper()
	var nm := UI.label("%s  x%d" % [tr(key), n], 16)
	t.add_child(nm)
	var rate := float(bd.cps) * Save.coin_mult()
	var sub := UI.label(tr("FARM_EACH") % Save.fmt(rate) if rate >= 1000.0 else tr("FARM_EACH") % ("%.1f" % rate), 16, UI.COL_MUTED)
	t.add_child(sub)
	var cl := UI.label(Save.fmt(cost), 16, UI.COL_GOLD if float(Save.d.coins) >= cost else UI.COL_BAD, HORIZONTAL_ALIGNMENT_RIGHT)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cl)
	b.focus_entered.connect(func(): nm.add_theme_color_override("font_color", Color("2a1a14")))
	b.focus_exited.connect(func(): nm.remove_theme_color_override("font_color"))
	return b


# --- Journal ----------------------------------------------------------------------

func _journal() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(150, 0)
	row.add_child(list)
	var unlocked: int = minf(int(Save.d.journal), DB.JOURNAL.size())
	for i in DB.JOURNAL.size():
		var open := i < unlocked
		var b := UI.button(tr("JOURNAL_ENTRY") % (i + 1) if open else tr("HUB_LOCKED"), func():
			journal_page = i
			_render())
		b.disabled = not open
		list.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	var t := UI.wrapped(tr(DB.JOURNAL[clampi(journal_page, 0, unlocked - 1)]))
	scroll.add_child(t)


func _restore_focus() -> void:
	if tab != "expedition":
		return
	var b: Button = exp_buttons.get(focus_key)
	if b == null or not is_instance_valid(b) or b.disabled:
		b = exp_buttons["go"]
	b.grab_focus()
	focus_key = "go"
