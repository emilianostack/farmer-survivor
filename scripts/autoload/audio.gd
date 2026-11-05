## Sound effects (voice pool, rate limited) and looping music.
extends Node

const SFX := ["hit", "kill", "pickup", "coin", "levelup", "hurt", "shoot", "slash", "boom", "zap", "chest", "ui", "buy", "boss", "win", "lose", "bee", "tractor"]
const VOICES := 14
const MIN_GAP := 0.045
## Per-sound trims in dB, measured so every effect sits at a similar loudness.
const TRIM := {"boss": -4.0, "slash": 3.0, "shoot": 1.5}

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last_play := {}
var music: AudioStreamPlayer
var current_track := ""
var sfx_db := 0.0
var positions := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in SFX:
		var path := "res://assets/audio/%s.wav" % s
		if ResourceLoader.exists(path):
			streams[s] = load(path)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	add_child(music)
	apply_volumes()


func apply_volumes() -> void:
	if music == null:
		return
	var s: Dictionary = Save.d.settings
	music.volume_db = linear_to_db(maxf(float(s.music) * 0.6, 0.0001))
	sfx_db = linear_to_db(maxf(float(s.sfx) * 0.7, 0.0001))
	for p in players:
		p.volume_db = sfx_db


func play(id: String, pitch_var: float = 0.08) -> void:
	if not streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_play.get(id, -1.0)) < MIN_GAP:
		return
	last_play[id] = now
	for p in players:
		if not p.playing:
			p.stream = streams[id]
			p.volume_db = sfx_db + float(TRIM.get(id, 0.0))
			p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
			p.play()
			return


## resume: continue from where this track last stopped (used after the action music).
func play_music(track: String, resume: bool = false) -> void:
	if track == current_track:
		return
	if current_track != "" and music.playing:
		positions[current_track] = music.get_playback_position()
	current_track = track
	var path := "res://assets/audio/music_%s.wav" % track
	if not ResourceLoader.exists(path):
		music.stop()
		return
	var st: AudioStreamWAV = load(path)
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = int(st.get_length() * st.mix_rate)
	music.stream = st
	music.play(float(positions.get(track, 0.0)) if resume else 0.0)


func stop_music() -> void:
	current_track = ""
	music.stop()
