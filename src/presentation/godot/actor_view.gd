extends CharacterBody2D

var kind = "Thomas"
const HeroState = preload("res://src/domain/combat/hero_state.gd")
var model = HeroState.new()
var hp: float:
    get: return model.health
    set(value): model.health = value
var max_hp: float:
    get: return model.max_health
var speed: float:
    get: return model.speed
var facing = 1.0
var armed: bool:
    get: return model.armed
    set(value): model.armed = value
var selected = false
var guarding = false
var guard_time = 0.0
var guard: float:
    get: return model.guard
    set(value): model.guard = value
var cooldown = 0.0
var attack_time = 0.0
var hurt_time = 0.0
var dodge_time = 0.0
var dodge_cooldown = 0.0
var dodge_direction = Vector2.RIGHT
var clock = 0.0

func _ready():
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    collision_layer = 2
    collision_mask = 1
    var shape = CollisionShape2D.new()
    var capsule = CircleShape2D.new()
    capsule.radius = 9.0
    shape.shape = capsule
    add_child(shape)
    model.configure(kind)

func tick(delta: float, direction: Vector2):
    clock += delta
    cooldown = maxf(0,cooldown-delta)
    attack_time = maxf(0,attack_time-delta)
    hurt_time = maxf(0,hurt_time-delta)
    dodge_cooldown = maxf(0,dodge_cooldown-delta)
    dodge_time = maxf(0,dodge_time-delta)
    if guarding:
        guard_time += delta
    else:
        guard_time = 0
        guard = minf(100,guard+delta*24)
    if absf(direction.x)>0.1:
        facing = signf(direction.x)
    if dodge_time>0:
        velocity = dodge_direction*420
    else:
        velocity = direction*speed*(0.4 if guarding else 1.0)*(0.5 if attack_time>0 else 1.0)
    move_and_slide()
    position.x = clampf(position.x,70,2070)
    position.y = clampf(position.y,350,470)
    z_index = int(position.y)
    queue_redraw()

func evade(direction: Vector2) -> bool:
    if dodge_cooldown>0:
        return false
    dodge_direction = direction if direction.length()>0.2 else Vector2(facing,0)
    dodge_time = 0.20
    dodge_cooldown = 0.65
    return true

func strike(heavy: bool) -> bool:
    if cooldown>0 or dodge_time>0 or hp<=0:
        return false
    cooldown = 0.65 if heavy else 0.32
    attack_time = 0.23 if heavy else 0.16
    return true

func take_hit(amount: float, heavy: bool) -> String:
    var result = model.receive_hit(amount,heavy,guarding,guard_time,dodge_time>0 or hurt_time>0)
    if result in ["hit","guard_broken"]:
        hurt_time = 0.5
    return result

func pixel(x: float,y: float,w: float,h: float,color: String):
    draw_rect(Rect2(x,y,w,h),Color(color))

func _draw():
    draw_set_transform(Vector2.ZERO)
    pixel_ellipse(Vector2(0,2),Vector2(15,5),Color(0,0,0,0.35))
    if selected:
        draw_arc(Vector2(0,2),17,0,TAU,20,Color("d2b476"),1.5)
        draw_line(Vector2(-5,12),Vector2(5,12),Color("d2b476"),2)
    var bob = -1.0 if velocity.length()>8 and sin(clock*15)>0 else 0.0
    draw_set_transform(Vector2(0,bob),0,Vector2(facing,1))
    if hurt_time>0 and fmod(clock,0.12)<0.06:
        modulate.a = 0.50
    else:
        modulate.a = 1
    pixel(-8,-14,6,14,"242737")
    pixel(3,-14,6,14,"171d2b")
    pixel(-10,-3,8,4,"17171e")
    pixel(3,-3,9,4,"17171e")
    if kind == "Thomas":
        pixel(-12,-34,22,24,"4c5359")
        pixel(-10,-33,5,20,"717575")
        pixel(-14,-30,5,16,"313946")
        pixel(-11,-16,22,4,"745943")
        pixel(0,-16,4,4,"d5bd8d")
        pixel(-7,-48,15,15,"bd997e")
        pixel(-10,-50,18,7,"342f33")
        pixel(-10,-45,5,9,"302c31")
        pixel(4,-42,3,2,"b7c3c5")
        pixel(9,-28,5,13,"92735f")
        if armed:
            pixel(14,-31,4,26,"8f9da6")
            pixel(15,-31,2,23,"d4ded9")
            pixel(10,-9,13,3,"b79a65")
            pixel(14,-8,4,8,"664936")
            if attack_time>0:
                draw_arc(Vector2(12,-21),36,-1.3,1.2,12,Color("dce3d1"),4)
                draw_arc(Vector2(12,-21),31,-1.3,1.2,12,Color("836da2"),3)
    elif kind == "Khaterine":
        draw_colored_polygon(PackedVector2Array([Vector2(-9,-35),Vector2(9,-35),Vector2(17,-1),Vector2(-17,-1)]),Color("292a42"))
        pixel(-9,-33,5,30,"4a4863")
        pixel(8,-30,5,25,"181e2e")
        pixel(-9,-18,19,3,"9b8065")
        pixel(-8,-48,16,17,"d3c8ae")
        pixel(-5,-44,10,11,"be9d89")
        pixel(-6,-44,4,10,"775c61")
        pixel(-11,-50,22,6,"292a42")
        pixel(-12,-46,5,20,"25263d")
        pixel(8,-46,5,20,"25263d")
        pixel(6,-37,4,16,"a79f92")
        pixel(11,-27,6,9,"bc9a85")
        if armed:
            draw_circle(Vector2(18,-29),6+sin(clock*4),Color("8175ad"))
            draw_circle(Vector2(18,-29),3,Color("d1c2ec"))
    else:
        draw_colored_polygon(PackedVector2Array([Vector2(-8,-33),Vector2(8,-33),Vector2(15,0),Vector2(-15,0)]),Color("62758b"))
        pixel(-7,-46,14,14,"c8a58a")
        pixel(-9,-49,19,6,"735044")
        pixel(-10,-44,5,17,"80594a")
        pixel(-13,-31,5,19,"a2abb4")
        pixel(9,-31,5,19,"bec3c3")
    if guarding:
        draw_arc(Vector2(0,-24),27,-1.3,1.3,12,Color("b7cbbd"),3)

func pixel_ellipse(center: Vector2,radius: Vector2,color: Color):
    var points = PackedVector2Array()
    for i in range(24):
        points.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radius)
    draw_colored_polygon(points,color)
