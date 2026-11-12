extends Node2D
## Kök sahne: yönlendiriciyi başlatır (ekranlar Main tarafından CanvasLayer'lara açılır).

func _ready() -> void:
	Main.boot(self)
