class_name WaterRepeater
extends Node2D

@export var repeat_count: int = 80 # Aumentado de 20 a 80 para cubrir más distancia
@export var tile_width: float = 64.0

func _ready() -> void:
	if get_child_count() == 0:
		return
	
	var base_sprite = get_child(0)
	if not (base_sprite is AnimatedSprite2D or base_sprite is Sprite2D):
		return
		
	# Reproduce la animación base si no se está reproduciendo
	if base_sprite is AnimatedSprite2D:
		base_sprite.play()
			
	# Crear duplicados para cubrir el mapa
	for i in range(1, repeat_count):
		var sprite_duplicate = base_sprite.duplicate()
		sprite_duplicate.position.x = base_sprite.position.x + (i * tile_width)
		add_child(sprite_duplicate)
		
		# Asegurar que se reproduzca
		if sprite_duplicate is AnimatedSprite2D:
			sprite_duplicate.play()
