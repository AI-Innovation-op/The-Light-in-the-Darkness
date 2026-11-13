extends Node2D

var shapes: Array = []
var clock = 0.0

func rect(x: float,y: float,w: float,h: float,color: String):
    shapes.append([Rect2(x,y,w,h),Color(color)])

func _ready():
    var rng = RandomNumberGenerator.new()
    rng.seed = 81418
    rect(-500,-200,3400,780,"101c2a")
    rect(-500,155,3400,390,"1b2c39")
    for i in range(100):
        var sx = rng.randi_range(-100,2300)
        var sy = rng.randi_range(20,175)
        rect(sx,sy,2,2,"566478")
    for x in range(-100,2400,60):
        rect(x,160+rng.randi_range(-40,30),35,180,"192733")
        rect(x+12,140+rng.randi_range(-45,0),13,150,"192733")
    for i in range(9):
        house(i*260-70,190+rng.randi_range(-12,20),190,145)
    # Parroquia: piedra, ventana cálida, sin identificar visualmente a todo el clero como villano.
    rect(60,145,170,194,"38434a")
    rect(105,69,78,268,"3c464d")
    rect(112,74,6,260,"535c60")
    rect(118,45,51,28,"283540")
    rect(139,27,5,27,"b39a6f")
    rect(131,34,21,4,"b39a6f")
    rect(129,98,28,47,"172a34")
    rect(135,107,16,30,"d7a461")
    rect(141,107,4,30,"42474a")
    rect(78,245,42,90,"23313b")
    rect(151,245,42,90,"23313b")
    rect(89,260,16,27,"bd975e")
    rect(163,260,16,27,"bd975e")
    # Calle de piedra y barro; franja de combate legible.
    rect(-200,330,2700,230,"293b42")
    rect(-200,342,2700,3,"566266")
    rect(-200,470,2700,90,"202e37")
    for i in range(370):
        var x = rng.randi_range(-100,2300)
        var y = rng.randi_range(350,510)
        rect(x,y,rng.randi_range(5,22),2,"34484e" if i%3 else "435559")
    for x in range(270,610,30):
        rect(x,333,3,13,"867459")
        rect(x-5,340,12,2,"556a54")
    # Límite del huerto y vallas que dejan abierta la calle.
    for x in range(310,630,28):
        rect(x,295,6,41,"64594f")
    rect(308,305,325,5,"776554")
    rect(308,325,325,5,"776554")
    for x in [650,1200,1660,2020]:
        rect(x,282,5,55,"615549")
        rect(x-5,283,15,20,"b58b55")
        rect(x-1,286,6,12,"edc989")
    for x in range(85,2200,85):
        rect(x,499,5,21,"3e5149")
        rect(x+6,505,3,18,"3e5149")
    # Bosque de las Hogueras, al final de la escena.
    for x in [1410,1740,1910,2150]:
        rect(x,80,30,260,"202f35")
        rect(x+7,85,7,246,"354044")
    queue_redraw()

func house(x: float,y: float,w: float,h: float):
    rect(x,y,w,h,"404648")
    rect(x,y,w,11,"5a5652")
    rect(x+6,y+12,w-12,h-15,"6b6254")
    for yy in range(int(y+15),int(y+h),15):
        rect(x+8,yy,w-16,2,"5c554d")
    rect(x+5,y+10,8,h-10,"3b3839")
    rect(x+w-16,y+10,8,h-10,"3b3839")
    rect(x+w/2-4,y+10,8,h-10,"3b3839")
    rect(x+5,y+h-19,w-13,7,"35383b")
    rect(x+22,y+33,30,44,"26343d")
    rect(x+27,y+39,20,29,"c79b61")
    rect(x+35,y+39,3,30,"5d5446")
    rect(x+27,y+52,20,3,"5d5446")
    rect(x+w-60,y+42,31,h-42,"34373a")
    rect(x+w-56,y+49,23,h-50,"48443f")
    rect(x+w-39,y+h-35,3,3,"ba9e63")
    for step in range(7):
        rect(x-12+step*8,y-7-step*8,w+24-step*16,9,"313842")
        rect(x-12+step*8,y-7-step*8,9,9,"565654")
    rect(x+w-43,y-73,18,40,"4d5152")

func _process(delta: float):
    clock += delta
    queue_redraw()

func _draw():
    for shape in shapes:
        draw_rect(shape[0],shape[1])
    draw_circle(Vector2(740,78),29,Color("a5aaa1"))
    draw_circle(Vector2(752,71),26,Color("101c2a"))
    for x in [650,1200,1660,2020]:
        draw_circle(Vector2(x+2,295),39,Color(0.85,0.62,0.32,0.055))
    for i in range(22):
        var px = fmod(i*113+clock*8,2300)
        var py = 170+fmod(i*67-clock*11,290)
        draw_rect(Rect2(px,py,2,2),Color(0.74,0.79,0.73,0.24))
    for i in range(3):
        var x = 1400+i*280+sin(clock*0.15+i)*45
        draw_rect(Rect2(x,335+i*33,230,13),Color(0.59,0.68,0.68,0.025))
