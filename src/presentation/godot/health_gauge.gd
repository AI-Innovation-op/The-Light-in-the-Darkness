extends Control
## Fixed-height HUD gauge, independent of theme font minimum sizes.
var max_value = 100.0
var value = 100.0
var tint = Color("b8c3ac")

func _ready():
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
    queue_redraw()

func _draw():
    draw_rect(Rect2(Vector2.ZERO,size),Color("2a3540"))
    draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(value/maxf(1,max_value),0,1),size.y)),tint)
