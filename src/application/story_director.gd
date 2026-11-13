extends RefCounted
const Sequence = preload("res://src/domain/story/narrative_sequence.gd")
const Progress = preload("res://src/domain/story/chapter_progress.gd")
var sequence = Sequence.new()
var session

func _init(adventure):
    session = adventure

func begin(id: String,pages: Array) -> bool:
    if id=="act1_to_act2" and not Progress.can_depart(session.state.flags):
        return false
    return sequence.begin(id,pages)

func commit() -> bool:
    if not sequence.finished():
        return false
    if sequence.id=="opening":
        return true
    if sequence.id!="act1_to_act2" or not Progress.can_depart(session.state.flags):
        return false
    var before = session.state.snapshot()
    session.state.flags["arrived_londinium"] = true
    if not session.save():
        session.state.restore(before)
        return false
    return true
