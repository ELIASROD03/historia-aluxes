extends CanvasLayer

func _process(_delta: float) -> void:
	if has_node("/root/Global"):
		var en_dialogo = get_node("/root/Global").en_dialogo
		visible = not en_dialogo
