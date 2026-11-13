extends RefCounted
## Combat entity. No nodes, input, scene tree, UI, or file access.
var name = "Thomas"
var health = 80.0
var max_health = 80.0
var speed = 170.0
var guard = 100.0
var armed = true

func configure(identity: String):
    name = identity
    max_health = 110.0 if identity == "Khaterine" else 80.0
    health = max_health
    speed = 128.0 if identity == "Khaterine" else 170.0
    guard = 100.0
    armed = true

func receive_hit(amount: float,heavy: bool,blocking: bool,block_age: float,invulnerable: bool) -> String:
    if invulnerable or health<=0:
        return "evaded"
    if blocking and guard>0:
        if block_age<0.18:
            guard = minf(100,guard+15)
            return "parried"
        guard = maxf(0,guard-(65 if heavy else 28))
        if guard>0:
            return "blocked"
        armed = false
        health = maxf(0,health-maxf(0,amount)*0.3)
        return "guard_broken"
    health = maxf(0,health-maxf(0,amount))
    if heavy:
        armed = false
    return "hit"
