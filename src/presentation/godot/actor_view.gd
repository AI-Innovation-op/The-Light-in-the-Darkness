extends CharacterBody2D
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")

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

func current_sprite() -> String:
    return Sprites.hero_pose(kind,armed,attack_time>0)

func _draw():
    draw_set_transform(Vector2.ZERO)
    draw_circle(Vector2(0,2),12,Color(0,0,0,0.25))
    if selected:
        draw_arc(Vector2(0,2),17,0,TAU,20,Color("d2b476"),1.5)
        draw_line(Vector2(-5,12),Vector2(5,12),Color("d2b476"),2)
    var bob = -1.0 if velocity.length()>8 and sin(clock*15)>0 else 0.0
    draw_set_transform(Vector2(0,bob),0,Vector2(facing,1))
    modulate.a = 0.5 if hurt_time>0 and fmod(clock,0.12)<0.06 else 1.0
    var pose = current_sprite()
    draw_texture_rect(Sprites.texture(pose),Sprites.foot_rect(pose),false)
    if attack_time>0 and armed and kind=="Thomas":
        draw_arc(Vector2(13,-33),39,-1.3,1.2,12,Color("b8a5d5"),2)
    if guarding:
        draw_arc(Vector2(0,-36),35,-1.3,1.3,12,Color("b7cbbd"),3)
