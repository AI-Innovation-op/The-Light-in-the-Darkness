extends Control
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")
var reduced_motion = false

func _draw():
    draw_rect(Rect2(Vector2.ZERO,size),Color("211a30"))
    var portrait = Sprites.texture("portrait_shalem")
    var extent = portrait.get_size()
    extent *= minf(size.x/extent.x,size.y/extent.y)
    draw_texture_rect(portrait,Rect2((size-extent)/2,extent),false)
