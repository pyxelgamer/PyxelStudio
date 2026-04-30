@tool
extends EditorImportPlugin
# DO NOT add class_name here — causes preload conflicts

func _get_importer_name() -> String:    return "pyxelstudio.sprite"
func _get_visible_name() -> String:     return "PyxelStudio Sprite"
func _get_recognized_extensions() -> PackedStringArray: return ["pyxelsprite"]
func _get_save_extension() -> String:   return "scn"
func _get_resource_type() -> String:    return "PackedScene"
func _get_priority() -> float:          return 1.0
func _get_import_order() -> int:        return 2

func _get_preset_count() -> int: return 1
func _get_preset_name(_p: int) -> String: return "Default"

func _get_import_options(_path: String, _preset: int) -> Array[Dictionary]:
	return [
		{ "name": "fps",               "default_value": 12,   "usage": PROPERTY_USAGE_DEFAULT },
		{ "name": "pixel_snap",        "default_value": true, "usage": PROPERTY_USAGE_DEFAULT },
		{ "name": "default_animation", "default_value": "",   "usage": PROPERTY_USAGE_DEFAULT },
	]

func _get_option_visibility(_path: String, _option: StringName, _options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String,
			 options: Dictionary, _platform_variants: Array,
			 gen_files: Array) -> Error:

	# ── Read .pyxelsprite JSON ─────────────────────────────────────────────
	var text := FileAccess.get_file_as_string(source_file)
	if text.is_empty():
		printerr("[PyxelStudio] Cannot read: ", source_file)
		return ERR_FILE_CANT_READ

	var data = JSON.parse_string(text)
	if not data is Dictionary or not data.has("animations"):
		printerr("[PyxelStudio] Bad format: ", source_file)
		return ERR_INVALID_DATA

	# ── Find PNG ───────────────────────────────────────────────────────────
	var img_file: String = str(data.get("imageFile", ""))
	var abs_png: String
	if img_file.is_empty():
		abs_png = source_file.get_basename() + ".png"
	else:
		abs_png = source_file.get_base_dir().path_join(img_file)

	if not FileAccess.file_exists(abs_png):
		printerr("[PyxelStudio] PNG not found: ", abs_png)
		return ERR_FILE_NOT_FOUND

	# Convert to res:// path so ResourceLoader can find it
	var res_png: String = abs_png
	if not abs_png.begins_with("res://"):
		res_png = ProjectSettings.localize_path(abs_png)

	# Load texture — it must already be imported by Godot's image importer
	var texture: Texture2D = ResourceLoader.load(res_png, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	if texture == null:
		printerr("[PyxelStudio] Cannot load texture (is PNG imported?): ", res_png)
		return ERR_CANT_CREATE

	# ── Build SpriteFrames ────────────────────────────────────────────────
	var fps: float        = float(options.get("fps", 12))
	var pixel_snap: bool  = bool(options.get("pixel_snap", true))
	var def_anim: String  = str(options.get("default_animation", ""))

	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var first_anim := ""

	for anim_data in data["animations"]:
		var aname: String   = str(anim_data.get("name", "Anim"))
		var do_loop: bool   = bool(anim_data.get("loop", true))
		var ping_pong: bool = bool(anim_data.get("pingPong", false))
		if first_anim.is_empty():
			first_anim = aname

		sf.add_animation(aname)
		sf.set_animation_loop(aname, do_loop)
		sf.set_animation_speed(aname, fps)

		var frames_arr: Array = anim_data.get("frames", [])
		for fr in frames_arr:
			var at := AtlasTexture.new()
			at.atlas       = texture
			at.filter_clip = true
			at.region      = Rect2(float(fr.get("x",0)), float(fr.get("y",0)),
								   float(fr.get("w",32)), float(fr.get("h",32)))
			sf.add_frame(aname, at)

		# Ping-pong: append reversed frames (skip endpoints to avoid double hit)
		if ping_pong and frames_arr.size() > 2:
			var rev: Array = frames_arr.duplicate()
			rev.reverse()
			for i in range(1, rev.size() - 1):
				var at2 := AtlasTexture.new()
				at2.atlas       = texture
				at2.filter_clip = true
				at2.region      = Rect2(float(rev[i].get("x",0)), float(rev[i].get("y",0)),
										float(rev[i].get("w",32)), float(rev[i].get("h",32)))
				sf.add_frame(aname, at2)

	# ── Build AnimatedSprite2D ────────────────────────────────────────────
	var sprite := AnimatedSprite2D.new()
	sprite.name          = "AnimatedSprite2D"
	sprite.sprite_frames = sf
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_snap \
		else CanvasItem.TEXTURE_FILTER_LINEAR

	var play_name: String = def_anim if def_anim != "" and sf.has_animation(def_anim) else first_anim
	sprite.animation = play_name
	# autoplay is a StringName in Godot 4 — set to animation name to autoplay on scene start
	sprite.autoplay  = play_name

	var scene := PackedScene.new()
	scene.pack(sprite)
	sprite.free()

	# ── Save artifact ─────────────────────────────────────────────────────
	var artifact := save_path + ".scn"
	var err := ResourceSaver.save(scene, artifact)
	if err != OK:
		printerr("[PyxelStudio] Save failed (", err, "): ", artifact)
		return err

	# ── Friendly copy in res://imports/sprites/ ───────────────────────────
	var imports_dir := "res://imports/sprites"
	var dir_err := DirAccess.make_dir_recursive_absolute(imports_dir)
	if dir_err == OK or DirAccess.dir_exists_absolute(imports_dir):
		var friendly := imports_dir + "/" + source_file.get_file().get_basename() + ".tscn"
		var err2 := ResourceSaver.save(scene, friendly)
		if err2 == OK:
			gen_files.append(friendly)

	print("[PyxelStudio] ✓ Sprite: ", source_file.get_file(),
		  " → ", data["animations"].size(), " animation(s)")
	return OK
