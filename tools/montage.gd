## Tiles review screenshots into contact sheets. FS_DIR=folder
extends SceneTree
func _init() -> void:
	var dir := OS.get_environment("FS_DIR")
	var files: Array = Array(DirAccess.get_files_at(dir)).filter(func(f): return f.ends_with(".png") and not f.begins_with("m"))
	files.sort()
	var cols := 2
	var per := 6
	var page := 0
	for start in range(0, files.size(), per):
		var out := Image.create(cols * 642, 3 * 362, false, Image.FORMAT_RGBA8)
		for i in range(start, min(start + per, files.size())):
			var img := Image.load_from_file(dir + "/" + files[i])
			img.convert(Image.FORMAT_RGBA8)
			img.resize(640, 360, Image.INTERPOLATE_NEAREST)
			var k: int = i - start
			out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i((k % cols) * 642, (k / cols) * 362))
		out.save_png(dir + "/m%d.png" % page)
		page += 1
	quit()
