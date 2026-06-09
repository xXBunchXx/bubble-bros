class_name PawnData
extends Resource

## Defines a controllable unit type. Create instances as .tres files in
## res://data/pawns/ — they are auto-registered by id (the filename).
## To add a new unit type: New Resource > PawnData, fill in stats, save.
## No networking code needed; units spawn across the network by id.

@export var display_name := "Pawn"
@export var speed := 150.0
@export var radius := 18.0
## Tint applied on top of the per-player color (use white for pure player color)
@export var color := Color.WHITE
## Later: health, damage, attack range, sprite, etc.
@export var max_health := 100.0
