## Shared look and feel: fonts, theme and small widget helpers.
class_name UI
extends RefCounted

const COL_TEXT := Color("f4ecd8")
const COL_MUTED := Color("b4a890")
const COL_GOOD := Color("b8ff3a")
const COL_GOLD := Color("ffe066")
const COL_BAD := Color("ff6a5a")
const DIM := Color(0.04, 0.03, 0.08, 0.72)

static var _body: Font
static var _title: Font
static var _theme: Theme


static func _crisp(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


static func body_font() -> Font:
	if _body == null:
		_body = _crisp("res://assets/fonts/Jersey10.ttf")
	return _body


static func title_font() -> Font:
	if _title == null:
		var v := FontVariation.new()
		v.base_font = _crisp("res://assets/fonts/PixelifySans.ttf")
		var ts := TextServerManager.get_primary_interface()
		v.variation_opentype = {ts.name_to_tag("wght"): 600}
		_title = v
	return _title


static func _box(path: String, margin: int, pad: Vector2 = Vector2(6, 3)) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(path)
	s.set_texture_margin_all(margin)
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 16
	t.set_color("font_color", "Label", COL_TEXT)
	t.set_color("font_outline_color", "Label", Color("140c1c"))
	var sp := "res://assets/sprites/"
	t.set_stylebox("normal", "Button", _box(sp + "ui_btn.png", 4))
	t.set_stylebox("hover", "Button", _box(sp + "ui_btn_hover.png", 4))
	t.set_stylebox("focus", "Button", _box(sp + "ui_btn_hover.png", 4))
	t.set_stylebox("pressed", "Button", _box(sp + "ui_btn_pressed.png", 4))
	t.set_stylebox("disabled", "Button", _box(sp + "ui_btn_disabled.png", 4))
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", Color("2a1a14"))
	t.set_color("font_focus_color", "Button", Color("2a1a14"))
	t.set_color("font_pressed_color", "Button", Color("2a1a14"))
	t.set_color("font_disabled_color", "Button", Color("7a7488"))
	t.set_stylebox("panel", "PanelContainer", _box(sp + "ui_panel.png", 6, Vector2(8, 6)))
	t.set_stylebox("panel", "Panel", _box(sp + "ui_panel.png", 6, Vector2(8, 6)))
	var track := StyleBoxFlat.new()
	track.bg_color = Color("1c1828")
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = COL_GOLD
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var empty := StyleBoxEmpty.new()
	t.set_stylebox("panel", "ScrollContainer", empty)
	_theme = t
	return t


static func label(txt: String, size: int = 16, col: Color = COL_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align as HorizontalAlignment
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(txt: String, size: int = 24, col: Color = COL_GOLD, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(txt, size, col, align)
	if size >= 24:
		l.add_theme_font_override("font", title_font())
	l.add_theme_constant_override("outline_size", 2 if size <= 32 else 4)
	return l


static func wrapped(txt: String, size: int = 16, col: Color = COL_TEXT) -> Label:
	var l := label(txt, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(txt: String, fn: Callable, min_size := Vector2(0, 22)) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_size
	b.pressed.connect(func():
		Audio.play("ui", 0.0)
		fn.call())
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus())
	return b


static func icon(id: String, sc: float = 1.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load("res://assets/sprites/icon_%s.png" % id)
	r.custom_minimum_size = Vector2(22, 22) * sc
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## One cell of a sprite sheet.
static func frame(path: String, rect: Rect2, sc: float = 1.0) -> TextureRect:
	var a := AtlasTexture.new()
	a.atlas = load(path)
	a.region = rect
	var r := TextureRect.new()
	r.texture = a
	r.custom_minimum_size = rect.size * sc
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func dim() -> ColorRect:
	var c := ColorRect.new()
	c.color = DIM
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func center(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(child)
	return c


static func time_str(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


## Plain-language summary of a weapon level delta.
static func delta_text(d: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in d:
		var v = d[k]
		match k:
			"dmg": parts.append(TranslationServer.translate("DELTA_DMG") % _num(v))
			"amount": parts.append(TranslationServer.translate("DELTA_AMOUNT") % _num(v))
			"area": parts.append(TranslationServer.translate("DELTA_AREA") % str(int(round(v * 100))))
			"cd": parts.append(TranslationServer.translate("DELTA_CD") % _num(absf(v)))
			"rate": parts.append(TranslationServer.translate("DELTA_RATE") % _num(absf(v)))
			"pierce": parts.append(TranslationServer.translate("DELTA_PIERCE") % _num(v))
			"life": parts.append(TranslationServer.translate("DELTA_LIFE") % _num(v))
			"spin": parts.append(TranslationServer.translate("DELTA_SPIN") % _num(v))
	return ", ".join(parts)


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(snappedf(v, 0.01))
