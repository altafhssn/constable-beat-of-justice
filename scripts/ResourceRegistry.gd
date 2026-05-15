class_name ResourceRegistry
extends Node

# Resource registry for global singletons
# Handles game-wide resource loading

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
