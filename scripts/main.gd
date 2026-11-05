## Top-level screen flow.
extends Node

const RunScene = preload("res://scripts/game/run.gd")
const Hub = preload("res://scripts/ui/hub.gd")
const Harness = preload("res://scripts/dev/harness.gd")

const INTRO := [{"img": 0, "key": "STORY_1"}, {"img": 1, "key": "STORY_2"}, {"img": 2, "key": "STORY_3"}, {"img": 3, "key": "STORY_4"}]
const ENDING := [{"img": 4, "key": "STORY_END_1"}, {"img": 4, "key": "STORY_END_2"}]

var ui_layer: CanvasLayer
var current: Node = null
var run: Node2D = null
var harness: Node = null
var on_results_done := Callable()


func _ready() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	if OS.has_feature("web"):
		_free_browser_keys()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--dev="):
			harness = Harness.new()
			add_child(harness)
			harness.begin(self, a.substr(6))
			return
	show_title()


## In a browser Esc leaves fullscreen, so it must not also pause the game.
## P and the on-screen button pause instead. Menus still close with Esc.
func _free_browser_keys() -> void:
	for e in InputMap.action_get_events("pause"):
		if e is InputEventKey and (e.physical_keycode == KEY_ESCAPE or e.keycode == KEY_ESCAPE):
			InputMap.action_erase_event("pause", e)


func _swap(n: Node) -> void:
	if current != null:
		current.queue_free()
	current = n
	if n != null:
		ui_layer.add_child(n)


func show_title() -> void:
	var t := Screens.Title.new()
	t.play.connect(_on_play)
	t.options.connect(func(): open_options(ui_layer, show_title))
	_swap(t)


## A new player is playing within a second of pressing Play: the first run starts at
## once, with the controls drawn on screen. The intro story waits until after it.
func _on_play() -> void:
	if int(Save.d.runs) == 0 and not Save.d.seen_intro:
		start_run(0, 0, String(Save.d.selected_char))
	else:
		show_farm()


## The hub, with the intro story in front of it the first time. The story can be skipped.
func show_farm() -> void:
	if Save.d.seen_intro:
		show_hub()
		return
	show_story(INTRO, func():
		Save.d.seen_intro = true
		Save.save_game()
		show_hub())


func show_story(slides: Array, next: Callable) -> void:
	var s := Screens.Story.new(slides)
	s.done.connect(next)
	_swap(s)


func show_hub() -> void:
	var h := Hub.new()
	h.start_run.connect(start_run)
	h.back.connect(show_title)
	h.open_options.connect(func(): open_options(ui_layer, func(): h.rebuild()))
	_swap(h)


func start_run(stage: int, rad: int, char_id: String, bot: bool = false) -> void:
	_swap(null)
	run = RunScene.new()
	add_child(run)
	run.ended.connect(_on_run_ended)
	run.start(stage, rad, char_id, bot)


func _on_run_ended(r: Dictionary) -> void:
	get_tree().paused = false
	run.queue_free()
	run = null
	Save.add_coins(r.coins)
	Save.d.kills = int(Save.d.kills) + int(r.kills)
	Save.d.runs = int(Save.d.runs) + 1
	Save.d.best_time = maxf(float(Save.d.best_time), float(r.time))
	var first_final: bool = false
	var stage_i := int(r.stage)
	var had_stage: bool = stage_i + 1 < DB.STAGES.size() and Save.stage_unlocked(stage_i + 1)
	var had_rad := Save.max_rad(stage_i)
	if r.win:
		first_final = int(r.stage) == 2 and Save.stage_cleared_rad(2) < 0
		Save.record_clear(int(r.stage), int(r.rad))
		Save.d.selected_rad = minf(int(Save.d.selected_rad), Save.max_rad(int(r.stage)))
	Save.save_game()
	Audio.play("win" if r.win else "lose", 0.0)
	Audio.play_music("menu")
	if harness != null and harness.mode == "sim":
		harness.on_result(r)
		return
	r["notes"] = progress_notes(stage_i, int(r.rad), r.win, had_stage, had_rad)
	var res := Screens.Results.new(r)
	res.closed.connect(func():
		if first_final:
			show_story(ENDING, show_hub)
		else:
			show_farm())
	_swap(res)


## Opens the options panel on top of `parent`. `refresh` rebuilds the screen below.
func open_options(parent: Node, refresh: Callable = Callable()) -> Control:
	var o := Screens.Options.new()
	if refresh.is_valid():
		o.language_changed.connect(func():
			# Keep the panel on top of the rebuilt screen.
			refresh.call()
			parent.move_child(o, -1))
	o.closed.connect(func():
		if current != null and current is Control and is_instance_valid(current):
			_refocus(current))
	parent.add_child(o)
	return o


func _refocus(c: Control) -> void:
	for n in c.find_children("*", "Button", true, false):
		var b: Button = n
		if b.is_visible_in_tree() and not b.disabled:
			b.grab_focus()
			return


## What this run changed, or what the player still needs, for the results screen.
func progress_notes(stage: int, _rad: int, win: bool, had_stage: bool, had_rad: int) -> Array:
	var notes := []
	var has_next := stage + 1 < DB.STAGES.size()
	if win:
		if has_next and not had_stage and Save.stage_unlocked(stage + 1):
			notes.append(tr("RES_UNLOCK_STAGE") % tr(DB.STAGES[stage + 1].name))
		if Save.max_rad(stage) > had_rad:
			notes.append(tr("RES_UNLOCK_RAD") % Save.max_rad(stage))
	elif has_next and not Save.stage_unlocked(stage + 1):
		notes.append(tr("RES_HINT_LOSE") % [tr(DB.ENEMIES[DB.STAGES[stage].boss].name), UI.time_str(DB.STAGE_LENGTH)])
	return notes
