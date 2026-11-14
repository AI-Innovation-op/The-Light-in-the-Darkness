extends Node2D
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")
var facing = 1.0

func _draw():
    draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    draw_texture_rect(Sprites.texture("shalem_cat"),Sprites.foot_rect("shalem_cat"),false)
