@tool
extends EditorPlugin

# PyxelStudio Importer Plugin
# Registers sprite (.pyxelsprite) and tileset (.gmap) importers.

const SPRITE_IMPORTER_PATH  := "res://addons/pyxelstudio/pyxel_sprite_importer.gd"
const TILESET_IMPORTER_PATH := "res://addons/pyxelstudio/pyxel_tileset_importer.gd"

var _sprite_importer  = null
var _tileset_importer = null

func _enter_tree() -> void:
	_sprite_importer  = load(SPRITE_IMPORTER_PATH).new()
	_tileset_importer = load(TILESET_IMPORTER_PATH).new()
	add_import_plugin(_sprite_importer)
	add_import_plugin(_tileset_importer)
	print("[PyxelStudio] Importers registered.")

func _exit_tree() -> void:
	if _sprite_importer:
		remove_import_plugin(_sprite_importer)
		_sprite_importer = null
	if _tileset_importer:
		remove_import_plugin(_tileset_importer)
		_tileset_importer = null
