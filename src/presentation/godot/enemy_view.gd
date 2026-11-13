extends Node2D

var hp = 56.0
var max_hp = 56.0
var is_boss = false
var state = "approach"
var timer = 0.0
var direction = Vector2.LEFT
var target_position = Vector2.ZERO
var hurt = 0.0
var clock = 0.0
var heavy = true
var attack_fired = false
var posture_hits = 0

func tick(delta: float, target: Vector2) -> bool:
    clock += delta
    hurt = maxf(0,hurt-delta)
    timer -= delta
    var attacked = false
    match state:
        "approach":
            direction = (target-position).normalized()
            if position.distance_to(target)<(110 if is_boss else 63):
                state = "windup"
                timer = (1.1 if hp>max_hp*0.5 else 0.8) if is_boss else (0.85 if heavy else 0.60)
                target_position = target
                attack_fired = false
            else:
                position += direction*delta*75
        "windup":
            if timer<=0:
                state = "strike"
                timer = 0.30 if is_boss else 0.22
                direction = (target_position-position).normalized()
        "strike":
            position += direction*delta*210
            if not attack_fired:
                attack_fired = true
                attacked = true
            if timer<=0:
                state = "recover"
                timer = 1.25 if is_boss else 1.0
        "recover":
            if timer<=0:
                state = "approach"
        "stunned":
            if timer<=0:
                state = "approach"
    position.y = clampf(position.y,350,470)
    position.x = clampf(position.x,90,2050)
    z_index = int(position.y)
    queue_redraw()
    return attacked

func damage(amount: float, knockback: Vector2):
    hp -= amount
    position += knockback*12
    hurt = 0.16
    if hp>0 and amount>=25:
        posture_hits += 1
        if not is_boss or posture_hits>=3:
            state = "stunned"
            timer = 0.8 if is_boss else 0.55
            posture_hits = 0

func _draw():
    draw_set_transform(Vector2.ZERO)
    draw_circle(Vector2(0,2),15,Color(0,0,0,0.3))
    if state == "windup":
        var length = 88.0
        draw_line(Vector2.ZERO,direction*length,Color("d9875e"),4)
        draw_arc(Vector2.ZERO,44,-PI,PI,24,Color("d9875e"),2)
        var tip = direction*length
        draw_colored_polygon(PackedVector2Array([tip,tip-direction.rotated(0.5)*17,tip-direction.rotated(-0.5)*17]),Color("f0c385"))
    var face = -1.0 if direction.x<0 else 1.0
    draw_set_transform(Vector2.ZERO,0,Vector2(face,1))
    if is_boss:
        draw_boss()
        return
    var body = Color("b2a9a0") if hurt>0 else Color("3b393b")
    draw_colored_polygon(PackedVector2Array([Vector2(-24,-14),Vector2(-17,-28),Vector2(6,-30),Vector2(24,-18),Vector2(15,-10),Vector2(-14,-8)]),body)
    draw_rect(Rect2(-20,-10,5,12),Color("1b242b"))
    draw_rect(Rect2(10,-11,5,13),Color("1b242b"))
    draw_rect(Rect2(14,-28,16,13),Color("454348"))
    draw_rect(Rect2(25,-25,9,8),Color("2a3035"))
    draw_rect(Rect2(23,-25,3,3),Color("b8c6a5"))
    for i in range(4):
        draw_line(Vector2(-16+i*8,-24),Vector2(-22+i*8,-38-(i%2)*4),Color("5f625a"),3)
    draw_line(Vector2(-21,-16),Vector2(-34,-28),Color("464b46"),4)
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(-25,-51,50,3),Color("1d2630"))
    draw_rect(Rect2(-25,-51,50*maxf(0,hp)/max_hp,3),Color("c78668"))

func draw_boss():
    var robe = Color("77727a") if hurt>0 else Color("47364c")
    draw_colored_polygon(PackedVector2Array([Vector2(-13,-51),Vector2(13,-51),Vector2(23,1),Vector2(-22,1)]),robe)
    draw_rect(Rect2(-4,-49,8,44),Color("b79b62"))
    draw_rect(Rect2(-12,-65,25,19),Color("2a2538"))
    draw_rect(Rect2(-7,-61,15,14),Color("c2a997"))
    draw_rect(Rect2(-13,-68,27,8),Color("a68a56"))
    draw_rect(Rect2(-3,-78,7,14),Color("c8ae72"))
    draw_rect(Rect2(-8,-74,17,4),Color("c8ae72"))
    draw_line(Vector2(12,-40),Vector2(42,-14),Color("b1a17d"),3)
    draw_circle(Vector2(42,-14),10,Color("a79160"))
    draw_circle(Vector2(42,-14),5,Color("9fc58b") if hp<max_hp*0.5 else Color("e3c28c"))
