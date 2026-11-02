## Floating virtual stick: drag anywhere on the screen to steer the farmer.
class_name TouchStick
extends Control

const RADIUS := 34.0
const DEADZONE := 0.15
const REST := Vector2(72, 284)
const IDLE_ALPHA := 0.22
const ACTIVE_ALPHA := 0.5

## Current steering, with length from 0 to 1.
var dir := Vector2.ZERO
## Touches inside these rects belong to buttons, not to the stick.
var blocked: Array[Control] = []
var _finger := -1
var _origin := REST
var _knob := REST


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		_on_touch(make_input_local(e))
	elif e is InputEventScreenDrag and e.index == _finger:
		_steer((make_input_local(e) as InputEventScreenDrag).position)


func _on_touch(e: InputEventScreenTouch) -> void:
	if not e.pressed:
		if e.index == _finger:
			release()
		return
	if _finger >= 0 or not visible or _is_blocked(e.position):
		return
	_finger = e.index
	_origin = e.position
	_steer(e.position)


func _is_blocked(p: Vector2) -> bool:
	for c in blocked:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return true
	return false


func _steer(p: Vector2) -> void:
	var offset := p - _origin
	if offset.length() > RADIUS:  # the base follows the thumb, so it never runs out of travel
		_origin = p - offset.limit_length(RADIUS)
		offset = p - _origin
	var v := offset / RADIUS
	dir = Vector2.ZERO if v.length() < DEADZONE else v
	_knob = _origin + offset
	queue_redraw()


func release() -> void:
	_finger = -1
	dir = Vector2.ZERO
	_origin = REST
	_knob = REST
	queue_redraw()


func _draw() -> void:
	var a := ACTIVE_ALPHA if _finger >= 0 else IDLE_ALPHA
	draw_circle(_origin, RADIUS, Color(0.08, 0.06, 0.14, a))
	draw_arc(_origin, RADIUS, 0.0, TAU, 40, Color(0.96, 0.93, 0.85, a), 2.0)
	draw_circle(_knob, RADIUS * 0.42, Color(0.96, 0.93, 0.85, a + 0.2))
