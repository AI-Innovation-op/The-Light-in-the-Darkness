extends RefCounted
## Pure activity rules. Presentation decides how long mismatches remain visible.
var cards: Array = []
var opened: Array = []
var matched: Array = []

func _init(deck: Array=[]):
    cards = deck.duplicate()

func select_card(index: int) -> String:
    if index<0 or index>=cards.size() or opened.size()>=2 or opened.has(index) or matched.has(index):
        return "ignored"
    opened.append(index)
    if opened.size()<2:
        return "revealed"
    if cards[opened[0]] != cards[opened[1]]:
        return "mismatch"
    matched.append_array(opened)
    opened.clear()
    return "complete" if matched.size()==cards.size() else "match"

func hide_mismatch():
    opened.clear()
