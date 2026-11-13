extends RefCounted
## Navigation has no clocks, textures, input, or scene tree dependencies.
var id = ""
var pages: Array = []
var index = 0

func begin(identity: String,items: Array) -> bool:
    if items.is_empty():
        return false
    id = identity
    pages = items.duplicate(true)
    index = 0
    return true

func current_page() -> Dictionary:
    return pages[index] if index<pages.size() else {}

func advance() -> bool:
    index = mini(index+1,pages.size())
    return index==pages.size()

func skip():
    index = pages.size()

func finished() -> bool:
    return not pages.is_empty() and index==pages.size()
