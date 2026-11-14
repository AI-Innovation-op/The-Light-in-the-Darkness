extends RefCounted
## Presentation-only asset selection. Physics, damage and progression do not depend on art.
const POSES = {
    "thomas_idle": [80.0,0.60], "thomas_attack": [62.0,0.32],
    "thomas_disarmed": [76.0,0.50], "khaterine_idle": [82.0,0.50],
    "khaterine_attack": [80.0,0.39], "elowen_npc": [78.0,0.50],
    "shalem_cat": [32.0,0.50], "ash_prowler": [57.0,0.50],
    "boss_morwenna": [103.0,0.42], "boss_malphas": [108.0,0.59],
    "portrait_thomas": [0.0,0.50], "portrait_khaterine": [0.0,0.50],
    "portrait_shalem": [0.0,0.50]
}
static var cache: Dictionary = {}

static func texture(id: String) -> Texture2D:
    if cache.has(id):
        return cache[id]
    assert(POSES.has(id),"Unknown sprite: "+id)
    var original: Texture2D = load("res://assets/sprites/%s.png" % id)
    var image = original.get_image()
    var atlas = AtlasTexture.new()
    atlas.atlas = original
    atlas.region = image.get_used_rect()
    cache[id] = atlas
    return atlas

static func foot_rect(id: String) -> Rect2:
    var image_size = texture(id).get_size()
    var height: float = POSES[id][0]
    var extent = image_size*(height/image_size.y)
    return Rect2(Vector2(-extent.x*POSES[id][1],-extent.y),extent)

static func hero_pose(kind: String,armed: bool,attacking: bool) -> String:
    if kind=="Thomas":
        if not armed:
            return "thomas_disarmed"
        return "thomas_attack" if attacking else "thomas_idle"
    if kind=="Khaterine":
        return "khaterine_attack" if armed and attacking else "khaterine_idle"
    return "elowen_npc"

static func portrait_for(speaker: String) -> String:
    if speaker.begins_with("Thomas"):
        return "portrait_thomas"
    if speaker.begins_with("Khaterine"):
        return "portrait_khaterine"
    if speaker.begins_with("Shalem"):
        return "portrait_shalem"
    return ""
