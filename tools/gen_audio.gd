## Synthesises every sound effect and the chiptune soundtrack.
## Run: godot --headless --path . --script res://tools/gen_audio.gd
extends SceneTree

const RATE := 22050
const OUT := "res://assets/audio/"
const NOTES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

var rng := RandomNumberGenerator.new()


func save(name: String, samples: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 32000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	st.save_to_wav(OUT + name + ".wav")


func square(ph: float, duty: float = 0.5) -> float:
	return 1.0 if fposmod(ph, 1.0) < duty else -1.0


func tri(ph: float) -> float:
	var p := fposmod(ph, 1.0)
	return 4.0 * abs(p - 0.5) - 1.0


## Generic effect: pitch sweep + noise, with an exponential tail.
func fx(dur: float, f0: float, f1: float, duty: float, noise: float, vol: float, decay: float = 5.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var held := 0.0
	for i in n:
		var t := float(i) / n
		var f: float = lerp(f0, f1, t)
		ph += f / RATE
		if i % 3 == 0:
			held = rng.randf_range(-1, 1)
		var v := square(ph, duty) * (1.0 - noise) + held * noise
		s[i] = v * vol * exp(-t * decay) * min(1.0, (n - i) / 60.0)
	return s


func seq(parts: Array) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	for p in parts:
		o.append_array(p)
	return o


func midi(note: String) -> float:
	var pitch: int = NOTES[note[0]]
	var i := 1
	if note[1] == "#":
		pitch += 1
		i = 2
	elif note[1] == "b":
		pitch -= 1
		i = 2
	var oct := int(note.substr(i))
	return 440.0 * pow(2.0, (pitch + (oct + 1) * 12 - 69) / 12.0)


## Mixes a chiptune: lead (pulse), bass (triangle), drums (noise).
func song(name: String, bpm: float, lead: Array, bass: Array, drums: String, duty: float) -> void:
	var step := 60.0 / bpm / 4.0  # sixteenth notes
	var steps: int = max(lead.size(), bass.size())
	var n := int(steps * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var step_n := int(step * RATE)
	for voice in [[lead, 0.20, duty, 2], [bass, 0.30, -1.0, 2]]:
		var pat: Array = voice[0]
		var i := 0
		while i < pat.size():
			var note: String = pat[i]
			if note == "-" or note == ".":
				i += 1
				continue
			var hold := 1
			while i + hold < pat.size() and pat[i + hold] == "-":
				hold += 1
			var f := midi(note)
			var len_n := hold * step_n
			var ph := 0.0
			for k in len_n:
				ph += f / RATE
				var w: float = tri(ph) if voice[2] < 0.0 else square(ph + sin(k * 0.0012) * 0.01, voice[2])
				var env: float = min(1.0, k / 50.0) * exp(-3.2 * float(k) / len_n) * (0.6 + 0.4 * min(1.0, float(len_n - k) / 200.0))
				var idx := (i * step_n + k) % n
				buf[idx] += w * voice[1] * env
			i += hold
	# drums loop over the song
	var held := 0.0
	for s in steps:
		var c := drums[s % drums.length()]
		if c == ".":
			continue
		var len_n := int((0.09 if c == "h" else 0.16) * RATE)
		var ph := 0.0
		for k in len_n:
			var t := float(k) / len_n
			var idx := (s * step_n + k) % n
			if c == "k":
				ph += lerp(150.0, 45.0, t) / RATE
				buf[idx] += tri(ph) * 0.4 * (1.0 - t)
			else:
				if k % 2 == 0:
					held = rng.randf_range(-1, 1)
				buf[idx] += held * (0.09 if c == "h" else 0.2) * pow(1.0 - t, 2.0)
	save("music_" + name, buf)


func expand(s: String) -> Array:
	return Array(s.split(" ", false))


func _init() -> void:
	rng.seed = 11
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	save("hit", fx(0.06, 500, 180, 0.3, 0.3, 0.35, 4))
	save("kill", fx(0.13, 340, 70, 0.25, 0.5, 0.4, 3))
	save("pickup", fx(0.07, 900, 1500, 0.5, 0.0, 0.22, 2))
	save("coin", seq([fx(0.05, 988, 988, 0.5, 0, 0.25, 1), fx(0.12, 1319, 1319, 0.5, 0, 0.25, 3)]))
	save("levelup", seq([fx(0.08, 523, 523, 0.5, 0, 0.3, 1), fx(0.08, 659, 659, 0.5, 0, 0.3, 1), fx(0.08, 784, 784, 0.5, 0, 0.3, 1), fx(0.25, 1047, 1047, 0.5, 0, 0.32, 3)]))
	save("hurt", fx(0.18, 260, 80, 0.5, 0.45, 0.5, 3))
	save("shoot", fx(0.1, 800, 220, 0.25, 0.25, 0.3, 4))
	save("slash", fx(0.14, 200, 900, 0.5, 0.75, 0.28, 3))
	save("boom", fx(0.45, 150, 30, 0.5, 0.8, 0.7, 4))
	save("zap", fx(0.2, 1800, 300, 0.2, 0.55, 0.4, 3))
	save("chest", seq([fx(0.1, 440, 440, 0.5, 0, 0.3, 1), fx(0.1, 554, 554, 0.5, 0, 0.3, 1), fx(0.1, 659, 659, 0.5, 0, 0.3, 1), fx(0.1, 880, 880, 0.5, 0, 0.3, 1), fx(0.35, 1109, 1109, 0.5, 0, 0.3, 3)]))
	save("ui", fx(0.04, 700, 900, 0.5, 0, 0.2, 2))
	save("buy", seq([fx(0.06, 660, 660, 0.5, 0, 0.26, 1), fx(0.14, 990, 990, 0.5, 0, 0.26, 3)]))
	save("boss", fx(1.2, 70, 40, 0.5, 0.35, 0.7, 2))
	save("win", seq([fx(0.13, 523, 523, 0.5, 0, 0.3, 1), fx(0.13, 659, 659, 0.5, 0, 0.3, 1), fx(0.13, 784, 784, 0.5, 0, 0.3, 1), fx(0.13, 1047, 1047, 0.5, 0, 0.3, 1), fx(0.5, 1319, 1319, 0.5, 0, 0.3, 3)]))
	save("lose", seq([fx(0.2, 392, 392, 0.5, 0, 0.3, 1), fx(0.2, 330, 330, 0.5, 0, 0.3, 1), fx(0.2, 262, 262, 0.5, 0, 0.3, 1), fx(0.6, 196, 180, 0.5, 0, 0.3, 3)]))
	save("bee", fx(0.09, 240, 280, 0.2, 0.1, 0.16, 1))
	save("tractor", fx(0.6, 60, 120, 0.3, 0.5, 0.45, 1.5))

	# Menu: lazy country waltz-ish loop in G major.
	song("menu", 96,
		expand("G4 - - - B4 - D5 - E5 - D5 - B4 - - - A4 - - - C5 - E5 - D5 - B4 - G4 - - - G4 - - - B4 - D5 - G5 - E5 - D5 - - - C5 - B4 - A4 - G4 - A4 - B4 - G4 - - - - - - -"),
		expand("G2 - - - D3 - - - G2 - - - D3 - - - D3 - - - A3 - - - D3 - - - A3 - - - E3 - - - B3 - - - C3 - - - G3 - - - D3 - - - A3 - - - G2 - - - D3 - G2 - - - - -"),
		"k.......s.......", 0.5)
	# Battle: driving A minor, the horde is coming.
	var lead_a := "A4 . A4 C5 . A4 E5 . D5 . C5 . B4 . G4 . A4 . A4 C5 . E5 A5 . G5 . E5 . D5 . C5 . "
	var lead_b := "F5 . F5 E5 . D5 C5 . D5 . D5 C5 . B4 A4 . E5 . E5 D5 . C5 B4 . C5 . B4 . A4 - - . "
	var bass_a := "A2 . A2 . A3 . A2 . A2 . A2 . A3 . G2 . F2 . F2 . F3 . F2 . G2 . G2 . G3 . G2 . "
	var bass_b := "D3 . D3 . D2 . D3 . D3 . D3 . D2 . D3 . E3 . E3 . E2 . E3 . A2 . A2 . E2 . G2 . "
	song("battle", 140, expand(lead_a + lead_a + lead_b + lead_b), expand(bass_a + bass_a + bass_b + bass_b), "k.h.s.h.k.k.s.hh", 0.25)
	# Boss: fast, chromatic and mean.
	var lead_c := "E5 . E5 . F5 . E5 . D#5 . E5 . B4 . C5 . E5 . E5 . G5 . F5 . E5 . D#5 . B4 . - . "
	var bass_c := "E2 E2 . E2 E3 . E2 . E2 E2 . E2 F2 . F#2 . E2 E2 . E2 E3 . E2 . G2 G2 . G2 F#2 . F2 . "
	song("boss", 168, expand(lead_c + lead_c), expand(bass_c + bass_c), "k.hhs.hkk.hhs.sh", 0.125)
	# Danger: frantic E minor arpeggios, the farmer is one bite from compost.
	var lead_d := "E5 G5 B5 E6 B5 G5 E5 G5 E5 G5 B5 E6 B5 G5 E5 G5 "
	var lead_e := "F5 A5 C6 F6 C6 A5 F5 A5 D5 F5 A5 D6 A5 F5 D#5 B4 "
	var bass_d := "E2 . E2 E2 E3 . E2 E2 E2 . E2 E2 E3 . E2 G2 "
	var bass_e := "F2 . F2 F2 F3 . F2 F2 D2 . D2 D2 B2 . B2 D#3 "
	song("danger", 176, expand(lead_d + lead_d + lead_e + lead_d + lead_d + lead_e + lead_e + lead_d), expand(bass_d + bass_d + bass_e + bass_d + bass_d + bass_e + bass_e + bass_d), "k.hsk.hsk.hsk.ss", 0.25)
	print("audio ok")
	quit()
