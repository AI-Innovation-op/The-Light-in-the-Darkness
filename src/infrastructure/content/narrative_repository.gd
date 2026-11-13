extends RefCounted
var data: Dictionary = {}
var story: Dictionary = {}

func _init():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/narrative/oakhaven.json"))
    if parsed is Dictionary:
        data = parsed
    var extra = JSON.parse_string(FileAccess.get_file_as_string("res://assets/narrative/story.json"))
    if extra is Dictionary:
        story = extra

func dialogue(id: String) -> Array:
    var lines = data.get("dialogues",{}).get(id,[])
    return lines.duplicate(true) if lines is Array else []

func sequence(id: String) -> Array:
    return story.get("sequences",{}).get(id,[]).duplicate(true)

func chapters() -> Array:
    return story.get("chapters",[]).duplicate(true)
