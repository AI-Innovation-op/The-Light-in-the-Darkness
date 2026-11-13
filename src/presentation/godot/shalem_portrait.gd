extends Control
var clock = 0.0
var reduced_motion = false

func _process(delta):
    if not reduced_motion:
        clock += delta
    queue_redraw()

func _draw():
    draw_rect(Rect2(Vector2.ZERO,size),Color("211a30"))
    var scale_factor = size.x/80.0
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_factor)
    draw_colored_polygon(PackedVector2Array([Vector2(14,42),Vector2(14,13),Vector2(33,26),Vector2(48,26),Vector2(64,12),Vector2(64,47),Vector2(58,65),Vector2(40,73),Vector2(22,64)]),Color("0b101a"))
    draw_colored_polygon(PackedVector2Array([Vector2(17,18),Vector2(20,36),Vector2(29,29)]),Color("4f3a4c"))
    draw_colored_polygon(PackedVector2Array([Vector2(59,19),Vector2(50,30),Vector2(61,36)]),Color("4f3a4c"))
    var blink = not reduced_motion and fmod(clock,5.0)>4.84
    draw_rect(Rect2(24,43,12,2 if blink else 7),Color("e1b967"))
    draw_rect(Rect2(45,43,12,2 if blink else 7),Color("e1b967"))
    if not blink:
        draw_rect(Rect2(29,42,3,9),Color("151221"))
        draw_rect(Rect2(49,42,3,9),Color("151221"))
    draw_line(Vector2(38,55),Vector2(43,55),Color("91717b"),2)
    draw_line(Vector2(15,55),Vector2(5,53),Color("9b939b"),1)
    draw_line(Vector2(64,55),Vector2(75,52),Color("9b939b"),1)
