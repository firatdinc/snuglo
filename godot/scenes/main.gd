extends Node2D

func _ready() -> void:
	var g := Game.new()
	add_child(g)
	g.start(Main.current_level())
	Dev.attach(g)
