## Persistent progress, settings and the idle economy.
extends Node

signal coins_changed

var path := "user://farmer_survivors.save"
const LANGUAGES := [
	{"code": "en", "name": "English"},
	{"code": "pt_BR", "name": "Português (Brasil)"},
	{"code": "es", "name": "Español"},
	{"code": "fr", "name": "Français"},
]

var d: Dictionary = {}
var offline_earned := 0.0
var _accum := 0.0
var _save_timer := 0.0


func _default() -> Dictionary:
	return {
		"version": 1,
		"coins": 0.0,
		"lifetime": 0.0,
		"soil": 0,
		"meta": {},
		"buildings": {},
		"chars": {"hank": true},
		"cleared": {},  # stage index (string) -> highest radiation level cleared, -1 absent
		"kills": 0,
		"runs": 0,
		"best_time": 0.0,
		"last_time": Time.get_unix_time_from_system(),
		"seen_intro": false,
		"selected_char": "hank",
		"selected_stage": 0,
		"selected_rad": 0,
		"journal": 1,
		"settings": {"locale": "en", "music": 0.7, "sfx": 0.8, "fullscreen": false, "shake": true, "numbers": true},
	}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()
	apply_settings()


func _process(delta: float) -> void:
	var rate := coins_per_second()
	if rate > 0.0:
		_accum += rate * delta
		if _accum >= 1.0:
			var whole := floorf(_accum)
			_accum -= whole
			add_coins(whole, true)
	_save_timer += delta
	if _save_timer > 30.0:
		_save_timer = 0.0
		save_game()


func load_game() -> void:
	d = _default()
	if FileAccess.file_exists(path):
		var txt := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary:
			_merge(d, parsed)
	# Coins the farm earned while the game was closed.
	var now := Time.get_unix_time_from_system()
	var away: float = clampf(now - float(d.last_time), 0.0, DB.OFFLINE_CAP_HOURS * 3600.0)
	offline_earned = floorf(away * coins_per_second())
	if offline_earned > 0.0:
		add_coins(offline_earned, true)
	d.last_time = now


func _merge(into: Dictionary, from: Dictionary) -> void:
	# A damaged field keeps its default instead of breaking the game.
	for k in from:
		if not into.has(k):
			into[k] = from[k]
			continue
		var a = into[k]
		var b = from[k]
		var both_numbers: bool = (a is int or a is float) and (b is int or b is float)
		if not both_numbers and typeof(a) != typeof(b):
			continue
		if a is Dictionary and k == "settings":
			_merge(a, b)
		else:
			into[k] = b


func save_game() -> void:
	d.last_time = Time.get_unix_time_from_system()
	if OS.has_feature("web"):
		# Browser storage syncs on close, so a rename right after would race it.
		var web := FileAccess.open(path, FileAccess.WRITE)
		if web:
			web.store_string(JSON.stringify(d))
		return
	# Write then swap, so a crash mid-save cannot corrupt the player's progress.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(tmp, path)


func wipe() -> void:
	var s: Dictionary = d.settings
	d = _default()
	d.settings = s
	save_game()
	coins_changed.emit()


func apply_settings() -> void:
	var s: Dictionary = d.settings
	TranslationServer.set_locale(s.locale)
	_set_fullscreen(s.fullscreen)
	if has_node("/root/Audio"):
		get_node("/root/Audio").apply_volumes()


func _set_fullscreen(on: bool) -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _notification(what: int) -> void:
	var leaving := what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT
	if leaving and not d.is_empty():  # phones kill background tabs without warning
		save_game()


# --- Economy -----------------------------------------------------------------

func add_coins(n: float, _idle: bool = false) -> void:
	d.coins = float(d.coins) + n
	d.lifetime = float(d.lifetime) + n
	coins_changed.emit()


func spend(n: float) -> bool:
	if float(d.coins) < n:
		return false
	d.coins = float(d.coins) - n
	coins_changed.emit()
	save_game()
	return true


func meta_level(id: String) -> int:
	return int(d.meta.get(id, 0))


func meta_cost(m: Dictionary) -> float:
	return ceilf(float(m.cost) * pow(float(m.grow), meta_level(m.id)))


func buy_meta(m: Dictionary) -> bool:
	if meta_level(m.id) >= int(m.max):
		return false
	if not spend(meta_cost(m)):
		return false
	d.meta[m.id] = meta_level(m.id) + 1
	save_game()
	return true


## Permanent bonus for a stat, summed over all workshop upgrades.
func meta_bonus(stat: String) -> float:
	var total := 0.0
	for m in DB.META:
		if m.stat == stat:
			total += float(m.v) * meta_level(m.id)
	if stat == "might":
		total += DB.SOIL_MIGHT_BONUS * int(d.soil)
	return total


func building_count(id: String) -> int:
	return int(d.buildings.get(id, 0))


func building_cost(b: Dictionary) -> float:
	return ceilf(float(b.cost) * pow(DB.BUILDING_GROWTH, building_count(b.id)))


func building_rate(b: Dictionary) -> float:
	var n := building_count(b.id)
	return float(b.cps) * n * pow(2.0, n / DB.BUILDING_MILESTONE) * coin_mult()


func buy_building(b: Dictionary) -> bool:
	if not spend(building_cost(b)):
		return false
	d.buildings[b.id] = building_count(b.id) + 1
	save_game()
	return true


func coins_per_second() -> float:
	var total := 0.0
	for b in DB.BUILDINGS:
		total += building_rate(b)
	return total


## Global multiplier granted by Clean Soil (prestige).
func coin_mult() -> float:
	return 1.0 + DB.SOIL_COIN_BONUS * int(d.soil)


func soil_available() -> int:
	return int(floor(sqrt(float(d.lifetime) / DB.SOIL_DIVISOR))) - int(d.soil)


## Prestige: bulldoze the farm, keep the workshop, gain Clean Soil.
func replant() -> void:
	var gain := soil_available()
	if gain <= 0:
		return
	d.soil = int(d.soil) + gain
	d.buildings = {}
	d.coins = 0.0
	coins_changed.emit()
	save_game()


func stage_cleared_rad(i: int) -> int:
	return int(d.cleared.get(str(i), -1))


func stage_unlocked(i: int) -> bool:
	return i == 0 or stage_cleared_rad(i - 1) >= 0


func max_rad(i: int) -> int:
	return stage_cleared_rad(i) + 1


func record_clear(i: int, rad: int) -> void:
	d.cleared[str(i)] = maxf(stage_cleared_rad(i), rad)
	d.journal = maxf(int(d.journal), i + 2)
	save_game()


func char_unlocked(id: String) -> bool:
	return d.chars.get(id, false)


static func fmt(n: float) -> String:
	var units := ["", "K", "M", "B", "T", "Qa", "Qi"]
	var a := absf(n)
	var i := 0
	while a >= 1000.0 and i < units.size() - 1:
		a /= 1000.0
		i += 1
	if i == 0:
		return str(int(n))
	var s := "%.2f" % a if a < 100.0 else "%.1f" % a
	return s + units[i]
