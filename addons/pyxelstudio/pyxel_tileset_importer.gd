@tool
extends EditorImportPlugin
# DO NOT add class_name here — causes preload conflicts
# ─────────────────────────────────────────────────────────────────────────────
# PyxelStudio Tileset Importer
#Hello
# Reads a PyxelStudio .gmap file alongside its atlas PNG and produces:
#   • A TileSet resource with physics layers, collision shapes, one-way
#     platforms, z-index, and custom data — all from the per-tile metadata
#     set in PyxelStudio's export wizard.
#   • A PackedScene (.tscn) containing a TileMapLayer node pre-configured
#     with the TileSet, ready to drop into any scene.
#
# Expected .gmap structure:
# {
#   "format":    "gmap",
#   "version":   1,
#   "tileWidth":  16,
#   "tileHeight": 16,
#   "padding":    1,
#   "spacing":    0,
#   "columns":    8,
#   "tileCount":  32,
#   "imageFile":  "tileset.png",
#   "tiles": [
#     {
#       "id":           0,
#       "col":          0,        // atlas grid column (use this, not x/y)
#       "row":          0,        // atlas grid row
#       "name":         "Grass",
#       "physicsLayer": 0,
#       "collision":    "full",   // "none"|"full"|"slope_right"|"slope_left"
#       "oneWay":       false,
#       "zIndex":       0,
#       "customData":   ""
#     },
#     ...
#   ]
# }
# ─────────────────────────────────────────────────────────────────────────────

func _get_importer_name() -> String:
	return "pyxelstudio.tileset"

func _get_visible_name() -> String:
	return "PyxelStudio Tileset"

func _get_recognized_extensions() -> PackedStringArray:
	return ["gmap"]

func _get_save_extension() -> String:
	return "scn"

func _get_resource_type() -> String:
	return "PackedScene"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 1  # Run after image imports so PNG is ready

func _get_preset_count() -> int:
	return 1

func _get_preset_name(_preset: int) -> String:
	return "Default"

func _get_import_options(_path: String, _preset: int) -> Array[Dictionary]:
	return [
		{
			"name":          "pixel_snap",
			"default_value": true,
			"usage":         PROPERTY_USAGE_DEFAULT
		},
		{
			"name":          "custom_data_layer_name",
			"default_value": "type",
			"usage":         PROPERTY_USAGE_DEFAULT
		},
	]

func _get_option_visibility(_path: String, _option: StringName, _options: Dictionary) -> bool:
	return true

# ─── Main import ─────────────────────────────────────────────────────────────

func _import(source_file: String, save_path: String,
			 options: Dictionary, _platform_variants: Array,
			 gen_files: Array) -> Error:

	# ── Ensure imports/tilesets/ directory exists ──
	DirAccess.make_dir_recursive_absolute("res://imports/tilesets")

	# ── Read .gmap ──
	var gmap_text := FileAccess.get_file_as_string(source_file)
	if gmap_text.is_empty():
		printerr("[PyxelStudio] Could not read: ", source_file)
		return ERR_FILE_CANT_READ

	var data = JSON.parse_string(gmap_text)
	if not data is Dictionary or data.get("format", "") != "gmap":
		printerr("[PyxelStudio] Not a valid .gmap file: ", source_file)
		return ERR_INVALID_DATA

	# ── Find companion PNG ──
	var image_file: String = data.get("imageFile", "")
	var png_path: String
	if image_file.is_empty():
		png_path = source_file.get_basename() + ".png"
	else:
		png_path = source_file.get_base_dir().path_join(image_file)

	if not FileAccess.file_exists(png_path):
		printerr("[PyxelStudio] Missing atlas PNG: ", png_path)
		return ERR_FILE_NOT_FOUND

	# Convert to res:// path if needed
	var res_png_path := png_path
	if not png_path.begins_with("res://"):
		res_png_path = ProjectSettings.localize_path(png_path)

	if not ResourceLoader.exists(res_png_path):
		printerr("[PyxelStudio] Atlas PNG not yet imported: ", res_png_path)
		return ERR_FILE_NOT_FOUND

	var texture := ResourceLoader.load(res_png_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if texture == null:
		printerr("[PyxelStudio] Could not load atlas: ", res_png_path)
		return ERR_CANT_CREATE

	var tw:      int  = data.get("tileWidth",  16)
	var th:      int  = data.get("tileHeight", 16)
	var padding: int  = data.get("padding",    0)
	var spacing: int  = data.get("spacing",    0)
	var tiles:   Array = data.get("tiles",     [])
	var pixel_snap: bool   = options.get("pixel_snap", true)
	var custom_layer_name: String = options.get("custom_data_layer_name", "type")

	# ── Collect unique physics layer indices from tile data ──
	var physics_layers_needed: Array[int] = []
	for tile in tiles:
		var pl: int = tile.get("physicsLayer", 0)
		var col: String = tile.get("collision", "none")
		if col != "none" and pl not in physics_layers_needed:
			physics_layers_needed.append(pl)
	physics_layers_needed.sort()

	# ── Check if any tile has custom data ──
	var needs_custom_data := false
	for tile in tiles:
		if tile.get("customData", "") != "":
			needs_custom_data = true
			break

	# ── Build TileSet ──
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tw, th)

	# Add physics layers — one per unique physicsLayer index used in the gmap.
	# We create layers 0..max so indices stay consistent with what PyxelStudio wrote.
	var max_physics_layer := 0
	if not physics_layers_needed.is_empty():
		max_physics_layer = physics_layers_needed.back()
	for _i in range(max_physics_layer + 1):
		tile_set.add_physics_layer()

	# Add custom data layer if needed
	if needs_custom_data:
		tile_set.add_custom_data_layer()
		tile_set.set_custom_data_layer_name(0, custom_layer_name)
		tile_set.set_custom_data_layer_type(0, TYPE_STRING)

	# ── Create atlas source ──
	var source := TileSetAtlasSource.new()
	source.texture              = texture
	source.texture_region_size  = Vector2i(tw, th)
	# padding = outer margin, spacing = gap between tiles
	# bleed pixels are already baked into PNG — margins/separation stay as-is
	var bleed: int = data.get("bleed", 0)
	source.margins    = Vector2i(padding, padding)
	source.separation = Vector2i(spacing, spacing)
	# Note: if bleed > 0, effective tile origin is at (padding, padding) within the PNG
	# Godot's AtlasSource margins already handle this correctly

	var source_id := tile_set.add_source(source)

	# ── Add tiles ──
	for tile in tiles:
		var tx: int = tile.get("x", 0)
		var ty: int = tile.get("y", 0)

		# Use col/row directly from gmap (no pixel math needed)
		# PyxelStudio exports col and row as atlas grid indices
		var atlas_col := int(tile.get("col", tx / max(1, tw)))
		var atlas_row := int(tile.get("row", ty / max(1, th)))
		var coords    := Vector2i(atlas_col, atlas_row)

		# Create tile if it doesn't already exist
		if not source.has_tile(coords):
			source.create_tile(coords)

		var tile_data: TileData = source.get_tile_data(coords, 0)
		if tile_data == null:
			continue

		# Z-index
		var z: int = tile.get("zIndex", 0)
		if z != 0:
			tile_data.z_index = z

		# Physics collision
		var collision: String  = tile.get("collision", "none")
		var phys_layer: int    = tile.get("physicsLayer", 0)
		var one_way: bool      = tile.get("oneWay", false)

		if collision != "none":
			var half_w := tw / 2.0
			var half_h := th / 2.0

			var polygon: PackedVector2Array
			match collision:
				"full":
					polygon = PackedVector2Array([
						Vector2(-half_w, -half_h),
						Vector2( half_w, -half_h),
						Vector2( half_w,  half_h),
						Vector2(-half_w,  half_h),
					])
				"slope_right":
					# Slope: ramp going up to the right (/ shape)
					polygon = PackedVector2Array([
						Vector2(-half_w,  half_h),
						Vector2( half_w, -half_h),
						Vector2( half_w,  half_h),
					])
				"slope", "slope_left":
					# Slope: ramp going up to the left (\ shape)
					polygon = PackedVector2Array([
						Vector2(-half_w, -half_h),
						Vector2( half_w,  half_h),
						Vector2(-half_w,  half_h),
					])
				_:
					# Unknown type — fall back to full rect
					polygon = PackedVector2Array([
						Vector2(-half_w, -half_h),
						Vector2( half_w, -half_h),
						Vector2( half_w,  half_h),
						Vector2(-half_w,  half_h),
					])

			tile_data.add_collision_polygon(phys_layer)
			tile_data.set_collision_polygon_points(phys_layer, 0, polygon)
			tile_data.set_collision_polygon_one_way(phys_layer, 0, one_way)

		# Custom data
		if needs_custom_data:
			var cd: String = tile.get("customData", "")
			if cd != "":
				tile_data.set_custom_data(custom_layer_name, cd)

	# ── Build TileMapLayer scene ──
	var tile_map := TileMapLayer.new()
	tile_map.name       = "TileMapLayer"
	tile_map.tile_set   = tile_set
	if pixel_snap:
		tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var scene := PackedScene.new()
	scene.pack(tile_map)

	# save_path is where Godot requires the import artifact to live
	var save_full := save_path + "." + _get_save_extension()
	# Also write a user-accessible copy to res://imports/tilesets/
	var friendly_path := "res://imports/tilesets/" + source_file.get_file().get_basename() + ".tscn"
	var err := ResourceSaver.save(scene, save_full)
	if err != OK:
		printerr("[PyxelStudio] Failed to save scene: ", save_full, " (error ", err, ")")
		return err

	# Write the friendly copy to imports/tilesets/
	var tilesets_dir := "res://imports/tilesets"
	var dir_err := DirAccess.make_dir_recursive_absolute(tilesets_dir)
	if dir_err == OK or DirAccess.dir_exists_absolute(tilesets_dir):
		var err2 := ResourceSaver.save(scene, friendly_path)
		if err2 == OK:
			gen_files.append(friendly_path)
		else:
			push_warning("[PyxelStudio] Could not write friendly copy: " + friendly_path)

	print("[PyxelStudio] Imported tileset: ", source_file.get_file(),
		  " → ", save_full.get_file(),
		  "  (", tiles.size(), " tiles, ",
		  max_physics_layer + 1, " physics layer(s))")
	return OK
