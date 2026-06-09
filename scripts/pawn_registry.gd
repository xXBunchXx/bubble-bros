extends Node

## Autoload singleton. Scans res://data/pawns/ at startup and maps
## id (filename without extension) -> PawnData. Because every peer ships
## the same data files, an id is all that needs to cross the network.

const PAWN_DIR := "res://data/pawns/"

var _pawns: Dictionary = {}

func _ready() -> void:
	var dir := DirAccess.open(PAWN_DIR)
	if dir == null:
		push_warning("PawnRegistry: no pawn directory at %s" % PAWN_DIR)
		return
	for file in dir.get_files():
		# Exported builds rename resources to .tres.remap; strip it
		var res_file := file.trim_suffix(".remap")
		if not res_file.ends_with(".tres"):
			continue
		var id := res_file.get_basename()
		var data := load(PAWN_DIR + res_file) as PawnData
		if data:
			_pawns[id] = data

func get_pawn(id: String) -> PawnData:
	if id not in _pawns:
		push_error("PawnRegistry: unknown pawn id '%s'" % id)
		return null
	return _pawns[id]

func ids() -> Array:
	return _pawns.keys()
