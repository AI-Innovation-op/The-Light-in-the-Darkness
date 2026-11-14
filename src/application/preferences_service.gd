extends RefCounted
## Preferences use their own injected store and never create a campaign checkpoint.
var repository
var values: Dictionary = {"muted":false,"reduced_motion":false,"volume":0.8}

func _init(storage):
    repository = storage

func load_settings(legacy: Dictionary = {}):
    var saved = repository.read()
    var source: Dictionary = saved if saved is Dictionary else legacy
    var volume = source.get("volume",0.8)
    values = {"muted":source.get("muted",false) if source.get("muted") is bool else false,"reduced_motion":source.get("reduced_motion",false) if source.get("reduced_motion") is bool else false,"volume":clampf(float(volume),0,1) if volume is float or volume is int else 0.8}

func update(id: String,value: Variant) -> bool:
    if not values.has(id):
        return false
    if (id=="volume" and not (value is float or value is int)) or (id!="volume" and not value is bool):
        return false
    var next = values.duplicate()
    next[id] = clampf(float(value),0,1) if id=="volume" else bool(value)
    var document = next.duplicate()
    document["version"] = 1
    if not repository.write(document):
        return false
    values = next
    return true
