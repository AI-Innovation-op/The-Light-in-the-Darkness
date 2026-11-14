extends Node2D
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")

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
    if state=="windup":
        var length = 88.0
        draw_line(Vector2.ZERO,direction*length,Color("d9875e"),4)
        draw_arc(Vector2.ZERO,44,-PI,PI,24,Color("d9875e"),2)
        var tip = direction*length
        draw_colored_polygon(PackedVector2Array([tip,tip-direction.rotated(0.5)*17,tip-direction.rotated(-0.5)*17]),Color("f0c385"))
    var face = -1.0 if direction.x<0 else 1.0
    draw_set_transform(Vector2.ZERO,0,Vector2(face,1))
    var pose = "boss_morwenna" if is_boss else "ash_prowler"
    draw_texture_rect(Sprites.texture(pose),Sprites.foot_rect(pose),false,Color(1.65,1.65,1.65) if hurt>0 else Color.WHITE)
    draw_set_transform(Vector2.ZERO)
    if not is_boss:
        draw_rect(Rect2(-25,-65,50,3),Color("1d2630"))
        draw_rect(Rect2(-25,-65,50*maxf(0,hp)/max_hp,3),Color("c78668"))
