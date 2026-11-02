## Regenerates every sprite in assets/sprites.
## Run: godot --headless --path . --script res://tools/gen_sprites.gd
extends SceneTree

const Px = preload("res://tools/px.gd")
const A = preload("res://tools/art_actors.gd")
const W = preload("res://tools/art_world.gd")
const OUT := "res://assets/sprites/"

var preview_rows: Array = []
var enemy_fns := {}


func sheet(file: String, fw: int, fh: int, frames: int, draw: Callable, shadow = null) -> Array:
	var cells = []
	for f in frames:
		var c = Px.new(fw, fh)
		draw.call(c, f)
		c.outline()
		cells.append(c)
	var out = Px.new(fw * frames, fh * 2)
	for f in frames:
		var c = cells[f]
		var sil = c.white_silhouette()
		if shadow != null:
			c.shadow(shadow.x, shadow.y, shadow.z, shadow.z * 0.34)
		out.stamp(c, f * fw, 0)
		out.stamp(sil, f * fw, fh)
	out.to_image().save_png(OUT + file + ".png")
	preview_rows.append(out)
	return cells


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for chr in characters():
		var cfg: Dictionary = chr
		sheet("char_" + cfg.id, 30, 38, 6, func(c, f): A.farmer(c, f, cfg), Vector3(14, 34, 10))
	var e = [
		["pea", 22, 22, A.pea, Vector3(10, 19, 7)],
		["carrot", 26, 34, A.carrot, Vector3(12, 31, 8)],
		["tomato", 30, 30, A.tomato, Vector3(14, 27, 11)],
		["potato", 34, 34, A.potato, Vector3(16, 31, 13)],
		["onion", 30, 34, A.onion, Vector3(14, 31, 10)],
		["corn", 28, 38, A.corn, Vector3(13, 35, 9)],
		["chili", 24, 34, A.chili, Vector3(11, 31, 7)],
		["eggplant", 30, 36, A.eggplant, Vector3(14, 33, 11)],
		["broccoli", 44, 46, A.broccoli, Vector3(21, 43, 17)],
		["beet", 32, 36, A.beet, Vector3(15, 33, 11)],
		["garlic", 28, 30, A.garlic, Vector3(13, 27, 10)],
		["boss_gourd", 100, 98, A.gourd_king, Vector3(48, 92, 40)],
		["boss_corn", 108, 118, A.corn_colossus, Vector3(52, 113, 34)],
		["boss_root", 124, 122, A.root_of_evil, Vector3(60, 114, 46)],
	]
	for d in e:
		var fn: Callable = d[3]
		enemy_fns[d[0]] = fn
		sheet("enemy_" + d[0], d[1], d[2], 4, func(c, f): fn.call(c, f), d[4])
	_world()
	print("sprites ok")
	quit()


func one(file: String, fw: int, fh: int, draw: Callable, use_outline: bool = true) -> Variant:
	var c = Px.new(fw, fh)
	draw.call(c)
	if use_outline:
		c.outline()
	c.to_image().save_png(OUT + file + ".png")
	preview_rows.append(c)
	return c


func strip(file: String, fw: int, fh: int, frames: int, draw: Callable, use_outline: bool = true) -> void:
	var out = Px.new(fw * frames, fh)
	for f in frames:
		var c = Px.new(fw, fh)
		draw.call(c, f)
		if use_outline:
			c.outline()
		out.stamp(c, f * fw, 0)
	out.to_image().save_png(OUT + file + ".png")
	preview_rows.append(out)


func _world() -> void:
	one("fx_slash", 44, 64, func(c): W.slash(c), false)
	one("proj_pitchfork", 26, 10, func(c): W.pitchfork(c))
	one("proj_pellet", 7, 7, func(c): W.pellet(c))
	one("proj_sickle", 20, 20, func(c): W.sickle(c))
	strip("proj_bee", 12, 12, 2, func(c, f): W.bee(c, f))
	strip("proj_puddle", 48, 32, 3, func(c, f): W.puddle(c, f), false)
	strip("proj_tractor", 70, 50, 2, func(c, f): W.tractor(c, f))
	strip("fx_bolt", 16, 96, 3, func(c, f): W.bolt(c, f), false)
	strip("proj_scarecrow", 28, 40, 2, func(c, f): W.scarecrow(c, f))
	one("eproj_kernel", 9, 9, func(c): W.kernel(c))
	one("eproj_seed", 9, 9, func(c): W.seed_shot(c))
	one("eproj_rad", 13, 13, func(c): W.rad_blob(c))
	for g in [["gem_1", ["1f6b3d", "4fd13a", "b8ff3a", "f4ffc0"]], ["gem_2", ["1f3a8a", "2f72e0", "6ac0ff", "d0f0ff"]], ["gem_3", ["8f1d36", "cf2f3a", "ff8a5a", "ffe0c0"]]]:
		var r = Px.ramp(g[1])
		one(g[0], 12, 15, func(c): W.gem(c, r))
	strip("pickup_coin", 12, 12, 4, func(c, f): W.coin(c, f))
	one("pickup_pie", 16, 15, func(c): W.pie(c))
	one("pickup_magnet", 16, 16, func(c): W.magnet(c))
	one("pickup_dynamite", 16, 16, func(c): W.dynamite(c))
	one("pickup_chest", 26, 22, func(c): W.chest(c))
	one("pickup_crate", 20, 20, func(c): W.crate(c))
	one("pickup_xpchest", 26, 22, func(c): W.xp_chest(c))
	var icons: Dictionary = W.icons()
	for k in icons:
		var fn: Callable = icons[k]
		one("icon_" + k, 22, 22, func(c):
			var t = Px.new(20, 20)
			fn.call(t)
			c.stamp(t, 1, 1))
	for b in ["coop", "barn", "silo", "windmill", "greenhouse", "lab"]:
		one("bld_" + b, 34, 32, func(c): W.building(c, b))
	for k in 3:
		one("ground_%d" % k, 128, 128, func(c): W.ground(c, k), false)
	var props := {"dirt": [48, 24], "fence": [40, 24], "hay": [32, 26], "tree": [32, 48], "sunflower": [18, 32], "rock": [26, 20], "wheelbarrow": [32, 26],
		"deadtree": [30, 46], "reeds": [24, 30], "barrel": [20, 28], "tiltsign": [22, 32], "toxicpool": [48, 24],
		"barrier": [38, 24], "pipe": [50, 28], "tower": [52, 64], "crate": [26, 28]}
	var stamps := {}
	for k in props:
		var c = one("prop_" + k, props[k][0], props[k][1], func(q): W.prop(q, k))
		stamps[k] = c
	# Interface skins
	one("ui_panel", 24, 24, func(c): W.panel(c, Px.ramp(["2a1a24", "3f2a30", "4f3638", "7a5a48"])), false)
	one("ui_panel_dark", 24, 24, func(c): W.panel(c, Px.ramp(["0f0c18", "1c1828", "262234", "4a4560"])), false)
	one("ui_btn", 12, 12, func(c): W.button(c, Color("9a7a58"), Color("6b5040"), Color("4a3430")), false)
	one("ui_btn_hover", 12, 12, func(c): W.button(c, Color("f8e080"), Color("d8a03a"), Color("9a6420")), false)
	one("ui_btn_pressed", 12, 12, func(c): W.button(c, Color("9a6420"), Color("b8822c"), Color("d8a03a")), false)
	one("ui_btn_disabled", 12, 12, func(c): W.button(c, Color("3a3644"), Color("2a2634"), Color("201c28")), false)
	# Story art, built out of the real sprites.
	var spr := func(n: String, kind: float):
		if kind > 0.5:
			var o = Px.new(30, 38)
			A.farmer(o, 0, _char(n))
			o.outline()
			return o
		if stamps.has(n):
			return stamps[n]
		var sizes := {"pea": [22, 22], "carrot": [26, 34], "tomato": [30, 30], "potato": [34, 34], "onion": [30, 34], "corn": [28, 38], "chili": [24, 34], "eggplant": [30, 36], "broccoli": [44, 46], "beet": [32, 36], "garlic": [28, 30], "boss_gourd": [100, 98], "boss_corn": [108, 118], "boss_root": [124, 122]}
		var e = Px.new(sizes[n][0], sizes[n][1])
		enemy_fns[n].call(e, 1)
		e.outline()
		return e
	for i in 5:
		one("story_%d" % i, 320, 180, func(c): W.story(c, i, spr), false)
	# Store page art (kept out of the game package)
	var keyart = Px.new(315, 250)
	W.key_art(keyart, spr)
	keyart.to_image().save_png("res://store/keyart.png")
	var wide = Px.new(480, 150)
	W.key_art(wide, spr)
	wide.to_image().save_png("res://store/keyart_wide.png")
	# Application icon
	var icon = Px.new(64, 64)
	icon.rect(0, 0, 64, 64, Color("1a2a1c"))
	W.radiation_sign(icon, 32, 32, 30, Color("2f8a43"))
	var h = Px.new(30, 38)
	A.farmer(h, 0, _char("hank"))
	h.outline()
	var big = h.to_image()
	big.resize(90, 114, Image.INTERPOLATE_NEAREST)
	var ii = icon.to_image()
	ii.blit_rect_mask(big, big, Rect2i(0, 0, 90, 64), Vector2i(-11, 0))
	ii.resize(128, 128, Image.INTERPOLATE_NEAREST)
	ii.save_png(OUT + "icon.png")
	_preview()


func _char(id: String) -> Dictionary:
	for c in characters():
		if c.id == id:
			return c
	return {}


## Contact sheets for reviewing the art (only when FS_PREVIEW is set).
func _preview() -> void:
	var path := OS.get_environment("FS_PREVIEW")
	if path == "":
		return
	var page := 0
	var prev = Px.new(1000, 620)
	prev.rect(0, 0, 1000, 620, Color("3f7a3f"))
	var x = 2
	var y = 2
	var rowh = 0
	for r in preview_rows:
		var rw = r.w
		var rh = r.h
		if x + rw > 1000:
			x = 2
			y += rowh + 3
			rowh = 0
		if y + rh > 620:
			_save_prev(prev, path, page)
			page += 1
			prev = Px.new(1000, 620)
			prev.rect(0, 0, 1000, 620, Color("3f7a3f"))
			x = 2
			y = 2
			rowh = 0
		prev.stamp(r, x, y)
		x += rw + 4
		rowh = max(rowh, rh)
	_save_prev(prev, path, page)


func _save_prev(prev, path: String, page: int) -> void:
	var img: Image = prev.to_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(path + "_%d.png" % page)


static func characters() -> Array:
	return [
		{"id": "hank", "skin": A.SKIN, "shirt": Px.ramp(["5a1426", "a4262e", "d8423a", "f07a5a"]), "shirt2": Color("f4ecd8"), "plaid": true, "pants": A.DENIM, "hat": "straw", "beard": true, "brow": Color("e4e8ec")},
		{"id": "mabel", "skin": A.SKIN, "shirt": Px.ramp(["3a1f5a", "6b3a8e", "9c62b8", "c89ce0"]), "shirt2": Color("f4ecd8"), "pants": Px.ramp(["3a1f5a", "6b3a8e", "8e52a8", "b47cc8"]), "hat": "bun", "hair": Px.ramp(["7a84a0", "b4bccc", "dfe4ea", "ffffff"]), "dress": true, "overalls": false, "glasses": true, "brow": Color("b4bccc")},
		{"id": "rosa", "skin": A.SKIN_D, "shirt": A.WHITE, "shirt2": Color("f4ecd8"), "pants": Px.ramp(["7a84a0", "b4bccc", "e4e8ec", "ffffff"]), "hat": "veil", "overalls": false, "brow": Color("140c1c")},
		{"id": "tucker", "skin": A.SKIN_D, "shirt": Px.ramp(["7a2c1a", "c2521c", "ee8420", "ffb84a"]), "shirt2": Color("f4ecd8"), "pants": Px.ramp(["7a2c1a", "b0481c", "dd6a1d", "f79a2e"]), "hat": "cap", "cap": Px.ramp(["132b4a", "1f4a78", "2f72a8", "5aa0d0"]), "overalls": false, "brow": Color("140c1c")},
	]
