extends RefCounted
## Story milestones are separate from XP, optional activities, and boss health.
const MILESTONES = {
    1:["met_elowen","encounter_cleared","morwenna_defeated","arrived_londinium"],
    2:["arrived_londinium","elowen_found","prophecy_rebuilt","malphas_escape"],
    3:["arrived_cathedral","crucible_defeated","astaroth_defeated","epilogue_complete"]
}

static func measure(flags: Dictionary,chapter: int) -> Dictionary:
    var keys = MILESTONES.get(chapter,[])
    var completed = 0
    var done: Array = []
    for key in keys:
        done.append(bool(flags.get(key,false)))
        if flags.get(key,false):
            completed += 1
    return {"completed":completed,"total":keys.size(),"done":done,"finished":not keys.is_empty() and completed==keys.size()}

static func can_depart(flags: Dictionary) -> bool:
    return flags.get("met_elowen",false) and flags.get("encounter_cleared",false) and flags.get("morwenna_defeated",false)

static func current(flags: Dictionary) -> int:
    if flags.get("arrived_cathedral",false):
        return 3
    return 2 if flags.get("arrived_londinium",false) else 1
