extends Node2D
## First playable arrival area; the rest of Act II remains future content.
func _draw():
    draw_rect(Rect2(-500,-200,3300,800),Color("121a2b"))
    for i in range(15):
        var x = i*160-80
        var height = 130+(i%4)*35
        draw_rect(Rect2(x,340-height,125,height),Color("33333e"))
        for w in range(3):
            draw_rect(Rect2(x+20+w*29,365-height,8,17),Color("ae985e"))
    draw_rect(Rect2(-200,330,2700,230),Color("4a4547"))
    for x in range(-100,2400,48):
        for y in range(346,500,28):
            draw_rect(Rect2(x+(12 if y%3 else 0),y,42,22),Color("575054"),false,1)
    for x in [800,1430]:
        draw_rect(Rect2(x,70,75,270),Color("756451"))
        draw_rect(Rect2(x+9,75,8,255),Color("bea16b"))
        draw_rect(Rect2(x-18,62,110,18),Color("b09561"))
        draw_rect(Rect2(x+24,4,27,58),Color("786648"))
    draw_rect(Rect2(875,122,555,21),Color("b0965d"))
    for x in range(890,1430,21):
        draw_rect(Rect2(x,145,7,184),Color("c0a873"))
    draw_circle(Vector2(1150,91),39,Color("b6985b"))
    draw_circle(Vector2(1150,91),28,Color("332d3e"))
    for i in range(12):
        var angle = i*TAU/12
        draw_line(Vector2(1150,91)+Vector2(cos(angle),sin(angle))*44,Vector2(1150,91)+Vector2(cos(angle),sin(angle))*60,Color("d7b96e"),3)
    for x in [580,1670]:
        draw_rect(Rect2(x,80,50,135),Color("4e3d60"))
        draw_circle(Vector2(x+25,120),15,Color("bda26c"))
    draw_rect(Rect2(-200,490,2700,30),Color("292932"))
