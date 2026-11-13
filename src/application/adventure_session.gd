extends RefCounted
## Application use cases depend on an injected persistence adapter.
const Campaign = preload("res://src/domain/progression/campaign.gd")
var state = Campaign.new()
var repository
var mode = "title"

func _init(storage):
    repository = storage

func save() -> bool:
    return repository.write(state.snapshot())

func load_checkpoint() -> bool:
    return state.restore(repository.read())

func start(identity: String):
    state = Campaign.new()
    state.chosen = identity
    mode = "adventure"

func finish_encounter():
    if not state.flags.get("encounter_cleared",false):
        state.award_xp(100)
        state.flags["encounter_cleared"] = true
    return save()

func claim_activity() -> bool:
    var before = state.snapshot()
    if not state.claim_memory():
        return false
    if not save():
        state.restore(before)
        return false
    return true

func defeat_morwenna() -> bool:
    state.flags["morwenna_defeated"] = true
    return save()
