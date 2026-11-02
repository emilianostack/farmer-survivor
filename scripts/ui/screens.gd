## Smaller screens: title, story slides, results and the options panel.
class_name Screens
extends RefCounted


class Title extends Control:
	signal play
	signal options

	func _ready() -> void:
		theme = UI.theme()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		Audio.play_music("menu")
		var bg := TextureRect.new()
		bg.texture = load("res://assets/sprites/story_3.png")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(bg)
		var a := UI.title("FARMER", 48, Color("ffe066"))
		a.add_theme_constant_override("outline_size", 8)
		a.position = Vector2(0, 16)
		a.size = Vector2(640, 56)
		add_child(a)
		var b := UI.title("SURVIVORS", 48, Color("b8ff3a"))
		b.add_theme_constant_override("outline_size", 8)
		b.position = Vector2(0, 62)
		b.size = Vector2(640, 56)
		add_child(b)
		var s := UI.label(tr("GAME_TAGLINE"), 16, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		s.add_theme_constant_override("outline_size", 3)
		s.position = Vector2(0, 118)
		s.size = Vector2(640, 18)
		add_child(s)
		var v := VBoxContainer.new()
		v.position = Vector2(240, 150)
		v.custom_minimum_size = Vector2(160, 0)
		v.add_theme_constant_override("separation", 3)
		add_child(v)
		var p := UI.button(tr("BTN_PLAY"), func(): play.emit(), Vector2(160, 24))
		v.add_child(p)
		v.add_child(UI.button(tr("BTN_OPTIONS"), func(): options.emit(), Vector2(160, 24)))
		if not OS.has_feature("web"):  # a browser tab has nothing to quit to
			v.add_child(UI.button(tr("BTN_QUIT"), func():
				Save.save_game()
				get_tree().quit(), Vector2(160, 24)))
		p.grab_focus()
		if Save.offline_earned > 0.0:
			var o := UI.label(tr("OFFLINE_EARNED") % Save.fmt(Save.offline_earned), 16, UI.COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			o.add_theme_constant_override("outline_size", 3)
			o.position = Vector2(0, 340)
			o.size = Vector2(640, 18)
			add_child(o)
			Save.offline_earned = 0.0


class Story extends Control:
	signal done

	var slides: Array
	var i := 0
	var shown := 0.0
	var image: TextureRect
	var text: Label
	var hint: Label

	func _init(p_slides: Array) -> void:
		slides = p_slides

	func _ready() -> void:
		theme = UI.theme()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image = TextureRect.new()
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.position = Vector2(0, -44)
		image.size = Vector2(640, 360)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(image)
		var panel := PanelContainer.new()
		panel.position = Vector2(14, 282)
		panel.custom_minimum_size = Vector2(612, 72)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size = Vector2(612, 72)
		add_child(panel)
		text = UI.wrapped("")
		panel.add_child(text)
		hint = UI.label(tr("STORY_HINT_TOUCH" if UI.is_touch() else "STORY_HINT"), 16, UI.COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		hint.position = Vector2(14, 264)
		hint.size = Vector2(612, 16)
		hint.add_theme_constant_override("outline_size", 3)
		add_child(hint)
		_show()

	func _show() -> void:
		var s: Dictionary = slides[i]
		image.texture = load("res://assets/sprites/story_%d.png" % int(s.img))
		text.text = tr(s.key)
		text.visible_ratio = 0.0
		shown = 0.0

	func _process(delta: float) -> void:
		shown += delta * 45.0
		text.visible_characters = int(shown)

	func _input(e: InputEvent) -> void:
		if e.is_action_pressed("ui_cancel"):
			done.emit()
			return
		var pressed: bool = e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed)
		if not pressed:
			return
		get_viewport().set_input_as_handled()
		if text.visible_characters < text.text.length():
			shown = 99999.0
			return
		Audio.play("ui", 0.0)
		i += 1
		if i >= slides.size():
			done.emit()
		else:
			_show()


class Results extends Control:
	signal closed

	var r: Dictionary

	func _init(p: Dictionary) -> void:
		r = p

	func _ready() -> void:
		theme = UI.theme()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var bg := TextureRect.new()
		bg.texture = load("res://assets/sprites/story_%d.png" % (4 if r.win else 2))
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(bg)
		var shade := UI.dim()
		add_child(shade)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(460, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		panel.add_child(v)
		v.add_child(UI.title(tr("RES_WIN") if r.win else tr("RES_LOSE"), 32, UI.COL_GOOD if r.win else UI.COL_BAD))
		v.add_child(UI.label(tr(DB.STAGES[r.stage].name) + ("  -  " + tr("HUB_RAD") % int(r.rad) if int(r.rad) > 0 else ""), 16, UI.COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 14)
		v.add_child(grid)
		for pair in [["RES_TIME", UI.time_str(r.time)], ["RES_LEVEL", str(r.level)], ["RES_KILLS", Save.fmt(r.kills)], ["RES_COINS", "+" + Save.fmt(r.coins)]]:
			var n := UI.label(tr(pair[0]), 16, UI.COL_MUTED)
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(n)
			grid.add_child(UI.label(pair[1], 16, UI.COL_GOLD))
		var biggest := 1.0
		for w in r.damage:
			biggest = maxf(biggest, float(w.done))
		for w in r.damage:
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 6)
			h.add_child(UI.icon(w.id, 0.8))
			var name_key: String = DB.WEAPONS[w.id].evo.name if w.evolved else "WPN_" + String(w.id).to_upper()
			var nm := UI.label(tr(name_key), 16, UI.COL_GOOD if w.evolved else UI.COL_TEXT)
			nm.custom_minimum_size = Vector2(190, 0)
			nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(nm)
			var bar := ColorRect.new()
			bar.color = Color("cf6a2a")
			bar.custom_minimum_size = Vector2(maxf(2.0, 150.0 * float(w.done) / biggest), 6)
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(bar)
			var dv := UI.label(Save.fmt(float(w.done)), 16, UI.COL_MUTED)
			dv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(dv)
			v.add_child(h)
		for note in r.get("notes", []):
			var line := UI.wrapped(note, 16, UI.COL_GOOD if r.win else UI.COL_GOLD)
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(line)
		var b := UI.button(tr("BTN_CONTINUE"), func(): closed.emit(), Vector2(0, 26))
		v.add_child(b)
		add_child(UI.center(panel))
		b.grab_focus()


class Options extends Control:
	signal closed
	signal language_changed

	var wipe_armed := false
	var return_focus: Control

	func _ready() -> void:
		theme = UI.theme()
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_build()

	func _build() -> void:
		for c in get_children():
			c.queue_free()
		add_child(UI.dim())
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(340, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		panel.add_child(v)
		v.add_child(UI.title(tr("OPT_TITLE"), 24))
		var s: Dictionary = Save.d.settings
		var lang := "English"
		for l in Save.LANGUAGES:
			if l.code == s.locale:
				lang = l.name
		var lb := UI.button(tr("OPT_LANGUAGE") % lang, _next_lang)
		v.add_child(lb)
		v.add_child(_slider(tr("OPT_MUSIC"), "music"))
		v.add_child(_slider(tr("OPT_SFX"), "sfx"))
		if not OS.has_feature("web"):  # web portals provide their own fullscreen control
			v.add_child(_toggle("OPT_FULLSCREEN", "fullscreen"))
		v.add_child(_toggle("OPT_SHAKE", "shake"))
		v.add_child(_toggle("OPT_NUMBERS", "numbers"))
		var wipe := UI.button(tr("OPT_WIPE_SURE") if wipe_armed else tr("OPT_WIPE"), func():
			if wipe_armed:
				Save.wipe()
				wipe_armed = false
				language_changed.emit()
			else:
				wipe_armed = true
			_build())
		if wipe_armed:
			wipe.add_theme_color_override("font_color", UI.COL_BAD)
		v.add_child(wipe)
		v.add_child(UI.button(tr("BTN_BACK"), _close))
		add_child(UI.center(panel))
		lb.grab_focus.call_deferred()

	func _close() -> void:
		Save.save_game()
		closed.emit()
		queue_free()

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("pause") or e.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close()

	func _next_lang() -> void:
		var langs: Array = Save.LANGUAGES
		var idx := 0
		for i in langs.size():
			if langs[i].code == Save.d.settings.locale:
				idx = i
		Save.d.settings.locale = langs[(idx + 1) % langs.size()].code
		Save.apply_settings()
		language_changed.emit()
		_build()

	func _slider(txt: String, key: String) -> Control:
		var h := HBoxContainer.new()
		var l := UI.label(txt)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(Save.d.settings[key])
		sl.custom_minimum_size = Vector2(140, 16)
		sl.value_changed.connect(func(val: float):
			Save.d.settings[key] = val
			Audio.apply_volumes()
			if key == "sfx":
				Audio.play("ui", 0.0))
		h.add_child(sl)
		return h

	func _toggle(label_key: String, key: String) -> Button:
		var on: bool = Save.d.settings[key]
		return UI.button("%s: %s" % [tr(label_key), tr("OPT_ON") if on else tr("OPT_OFF")], func():
			Save.d.settings[key] = not on
			Save.apply_settings()
			_build())
