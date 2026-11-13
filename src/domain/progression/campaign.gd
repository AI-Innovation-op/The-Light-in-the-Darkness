extends RefCounted
const Progress = preload("res://src/domain/story/chapter_progress.gd")

var chosen = "Thomas"
var rewards: Array = []
var flags: Dictionary = {}
var cat_access = 0
var xp = 0
var muted = false
var reduced_motion = false
var save_message = ""

func current_chapter() -> int:
    return Progress.current(flags)

func chapter_progress(chapter: int) -> Dictionary:
    return Progress.measure(flags,chapter)

func can_depart() -> bool:
    return Progress.can_depart(flags)

func award_xp(amount: int):
    xp += amount
    while xp >= 100:
        xp -= 100
        cat_access = mini(3, cat_access + 1)

func claim_memory() -> bool:
    if rewards.has("recuerdo_del_roble") or cat_access < 1:
        return false
    rewards.append("recuerdo_del_roble")
    cat_access -= 1
    flags["memory_completed"] = true
    return true

func restore(data: Variant) -> bool:
    if not data is Dictionary or data.get("version") != 1:
        return false
    chosen = "Khaterine" if data.get("chosen") == "Khaterine" else "Thomas"
    rewards = data.get("rewards", []) if data.get("rewards", []) is Array else []
    flags = data.get("flags", {}) if data.get("flags", {}) is Dictionary else {}
    cat_access = clampi(int(data.get("cat_access",0)),0,3)
    xp = clampi(int(data.get("xp",0)),0,99)
    muted = bool(data.get("muted",false))
    reduced_motion = bool(data.get("reduced_motion",false))
    return true

func snapshot() -> Dictionary:
    return {"version":1,"chosen":chosen,"rewards":rewards.duplicate(),"flags":flags.duplicate(true),"cat_access":cat_access,"xp":xp,"muted":muted,"reduced_motion":reduced_motion}
