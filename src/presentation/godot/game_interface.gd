extends CanvasLayer

signal action(id: String)
var hud: Control
var overlay: ColorRect
var content: VBoxContainer
var bars: Dictionary = {}
var names: Dictionary = {}
var objective: Label
var hint: Label
var toast: Label
var xp_label: Label
var mode = "title"
var focus_button: Button
var card_buttons: Array = []
var card_symbols: Array = []
var opened: Array = []
var matched: Array = []
var busy = false
var generation = 0
var rng = RandomNumberGenerator.new()
const HealthGauge = preload("res://src/presentation/godot/health_gauge.gd")
const MemoryBoard = preload("res://src/domain/activities/memory_board.gd")
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")
var board
const NarrativeScreen = preload("res://src/presentation/godot/narrative_screen.gd")
var story_screen
var region: Label
var boss_label: Label
var boss_gauge

func text(value: String,size: int=16,color: String="e1dccb") -> Label:
    var label = Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color(color))
    return label

func style(fill: String,border: String) -> StyleBoxFlat:
    var box = StyleBoxFlat.new()
    box.bg_color = Color(fill)
    box.border_color = Color(border)
    box.set_border_width_all(1)
    box.content_margin_left = 20
    box.content_margin_right = 20
    box.content_margin_top = 11
    box.content_margin_bottom = 11
    return box

func button(label: String,id: String,parent: Node) -> Button:
    var b = Button.new()
    b.text = label
    b.custom_minimum_size.y = 45
    b.add_theme_font_size_override("font_size",16)
    b.add_theme_stylebox_override("normal",style("1c2a35","5a5a51"))
    b.add_theme_stylebox_override("hover",style("303c45","c4ab77"))
    b.add_theme_stylebox_override("focus",style("303c45","e6d5a6"))
    b.add_theme_stylebox_override("pressed",style("495054","d6bd85"))
    b.add_theme_color_override("font_color",Color("e9e0ca"))
    parent.add_child(b)
    b.pressed.connect(func(): action.emit(id))
    return b

func _ready():
    var root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hud)
    var top = ColorRect.new()
    top.color = Color(0.04,0.07,0.10,0.92)
    top.position = Vector2(0,0)
    top.size = Vector2(960,89)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top)
    for i in range(2):
        var who = "Thomas" if i==0 else "Khaterine"
        var portrait = TextureRect.new()
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.texture = Sprites.texture("portrait_"+who.to_lower())
        portrait.position = Vector2(18+i*232,9)
        portrait.size = Vector2(36,42)
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hud.add_child(portrait)
        var name_label = text(who.to_upper(),15)
        name_label.position = Vector2(62+i*232,13)
        hud.add_child(name_label)
        names[who] = name_label
        var bar = HealthGauge.new()
        bar.position = Vector2(62+i*232,38)
        bar.size = Vector2(160,9)
        bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.tint = Color("b8c3ac" if i==0 else "a397b7")
        hud.add_child(bar)
        bars[who] = bar
    xp_label = text("",12,"b7b6a9")
    xp_label.position = Vector2(24,59)
    hud.add_child(xp_label)
    region = text("OAKHAVEN",17,"d4bd8c")
    region.position = Vector2(687,14)
    hud.add_child(region)
    objective = text("",14)
    objective.position = Vector2(490,43)
    objective.size = Vector2(445,40)
    objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud.add_child(objective)
    var bottom = ColorRect.new()
    bottom.color = Color(0.04,0.07,0.10,0.94)
    bottom.position = Vector2(0,502)
    bottom.size = Vector2(960,38)
    bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bottom)
    var controls = text("WASD Mover   J Atacar   K Fuerte   L Guardia   Espacio Esquivar   Q Lanzar   E Interactuar   I Diario",13)
    controls.position = Vector2(22,512)
    hud.add_child(controls)
    hint = text("",15,"f0d39c")
    hint.position = Vector2(40,462)
    hint.size = Vector2(880,30)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_child(hint)
    toast = text("",15,"eee0be")
    toast.position = Vector2(160,104)
    toast.size = Vector2(640,50)
    toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud.add_child(toast)
    boss_label = text("MADRE MORWENNA, VIGÍA DE LA PIRA SAGRADA",14,"e7c58c")
    boss_label.position = Vector2(240,142)
    hud.add_child(boss_label)
    boss_gauge = HealthGauge.new()
    boss_gauge.position = Vector2(240,167)
    boss_gauge.size = Vector2(480,8)
    boss_gauge.tint = Color("bd8b78")
    hud.add_child(boss_gauge)
    boss_label.hide()
    boss_gauge.hide()
    overlay = ColorRect.new()
    overlay.color = Color(0.025,0.045,0.075,0.94)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(overlay)
    content = VBoxContainer.new()
    content.position = Vector2(110,65)
    content.size = Vector2(740,430)
    content.add_theme_constant_override("separation",14)
    overlay.add_child(content)
    story_screen = NarrativeScreen.new()
    root.add_child(story_screen)
    story_screen.action.connect(func(id): action.emit(id))
    story_screen.hide()

func clear_panel(new_mode: String):
    story_screen.hide()
    generation += 1
    mode = new_mode
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()
    content.position = Vector2(110,65)
    content.size = Vector2(740,430)
    overlay.show()
    hud.visible = new_mode != "title"

func paragraph(value: String,size: int=17):
    var label = text(value,size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(label)

func title(has_save: bool):
    clear_panel("title")
    overlay.color = Color(0.025,0.045,0.075,0.83)
    content.add_child(text("UNA HISTORIA DE CENIZA Y ELECCIONES",13,"c3ab79"))
    content.add_child(text("THE LIGHT\nIN THE DARKNESS",41,"eee4cc"))
    paragraph("Oakhaven · El sendero de las hogueras",20)
    paragraph("Dos compañeros. Un poder prestado. Algo se mueve al otro lado del huerto.",16)
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",16)
    content.add_child(row)
    focus_button = button("Nueva partida: Thomas","start_thomas",row)
    button("Nueva partida: Khaterine","start_khaterine",row)
    if has_save:
        button("Continuar partida","continue",content)
    content.add_child(text("DEMO NARRATIVA  /  0.3     ·     Teclado y ratón",12,"a2aba8"))
    focus_button.grab_focus()

func resume():
    story_screen.hide()
    mode = "adventure"
    overlay.hide()
    hud.show()
    get_viewport().gui_release_focus()

func dialogue(speaker: String,body: String,last: bool):
    clear_panel("dialogue")
    overlay.color = Color(0.025,0.045,0.075,0.88)
    content.position.y = 110
    content.add_child(text(speaker.to_upper(),16,"d9bd83"))
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",20)
    content.add_child(row)
    var portrait_id = Sprites.portrait_for(speaker)
    if not portrait_id.is_empty():
        var portrait = TextureRect.new()
        portrait.texture = Sprites.texture(portrait_id)
        portrait.custom_minimum_size = Vector2(108,120)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(portrait)
    var words = text(body,20)
    words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(words)
    focus_button = button("Seguir" if not last else "Volver al sendero","dialogue_next",content)
    focus_button.grab_focus()

func pause_menu(muted: bool,reduced: bool):
    clear_panel("pause")
    content.position.y = 30
    content.add_theme_constant_override("separation",10)
    content.add_child(text("Un respiro entre las cenizas",28,"e6d7b8"))
    paragraph("Tab: cambiar personaje · Q: lanzar arma · E: hablar o recuperar arma\nJ: ataque ligero · K: ataque fuerte · L: bloquear · Espacio: esquivar",16)
    focus_button = button("Continuar","resume",content)
    button("Diario · Historia de Albion","journal",content)
    button("Sonido: " + ("silenciado" if muted else "activado"),"mute",content)
    button("Movimiento ambiental: " + ("reducido" if reduced else "activado"),"motion",content)
    button("Reiniciar encuentro","restart",content)
    button("Volver al inicio","title",content)
    focus_button.grab_focus()

func memory():
    clear_panel("memory")
    content.position.y = 30
    content.add_child(text("SHALEM · ECOS DEL ROBLE",25,"d9bd83"))
    paragraph("Encuentra cuatro parejas. El tiempo del sendero está detenido. Puedes salir y conservar tu acceso.",16)
    card_symbols = ["CENIZA","LUNA","ROBLE","SAUCE","CENIZA","LUNA","ROBLE","SAUCE"]
    # Local RNG: no dependency on global random state.
    rng.randomize()
    for i in range(7,0,-1):
        var j = rng.randi_range(0,i)
        var swap = card_symbols[i]
        card_symbols[i] = card_symbols[j]
        card_symbols[j] = swap
    opened.clear()
    matched.clear()
    board = MemoryBoard.new(card_symbols)
    card_buttons.clear()
    busy = false
    var grid = GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",10)
    content.add_child(grid)
    for i in range(8):
        var b = button("Sello %s" % (i+1),"card_%s" % i,grid)
        b.custom_minimum_size = Vector2(174,65)
        card_buttons.append(b)
    button("Ver los símbolos como ayuda","memory_help",content)
    button("Volver sin gastar el acceso","memory_exit",content)
    card_buttons[0].grab_focus()

func flip(index: int):
    if mode != "memory" or busy:
        return
    var pair = board.opened.duplicate()
    var result = board.select_card(index)
    if result == "ignored":
        return
    card_buttons[index].text = card_symbols[index]
    if result == "revealed":
        return
    pair.append(index)
    if result in ["match","complete"]:
        for i in pair:
            card_buttons[i].text = "OK · " + card_symbols[i]
        if result == "complete":
            action.emit("memory_win")
    else:
        busy = true
        var token = generation
        await get_tree().create_timer(1.3).timeout
        if mode != "memory" or token != generation:
            return
        for i in board.opened:
            card_buttons[i].text = "Sello %s" % (i+1)
        board.hide_mismatch()
        busy = false

func memory_help():
    for i in range(8):
        card_buttons[i].text = card_symbols[i]

func save_error():
    clear_panel("save_error")
    content.add_child(text("No se pudo guardar el recuerdo",27,"dfc68f"))
    paragraph("Conservas tu acceso a Shalem. Puedes reintentar el guardado o volver al sendero sin gastar el acceso.",19)
    focus_button = button("Reintentar guardado","memory_retry",content)
    button("Volver al sendero","memory_exit",content)
    focus_button.grab_focus()

func end_panel(won: bool):
    clear_panel("complete" if won else "defeat")
    content.add_child(text("El sendero vuelve a estar en calma" if won else "Las cenizas no son el final",29,"dfc68f"))
    paragraph("Recuerdo del Roble añadido al diario. Shalem ha reconstruido un eco del pasado. Puedes revisar el diario o continuar el viaje." if won else "Brillante estrategia: cansar la espada del enemigo golpeándola repetidamente con tus costillas. ¿Probamos otra vez?",19)
    focus_button = button("Continuar el viaje" if won else "Reintentar encuentro","resume" if won else "restart",content)
    button("Volver al inicio","title",content)
    focus_button.grab_focus()

func story_page(page: Dictionary,index: int,total: int,opening: bool,reduced: bool):
    mode = "opening" if opening else "interlude"
    overlay.hide()
    hud.hide()
    story_screen.present(page,index,total,opening,reduced)

func journal(state,chapters: Array):
    clear_panel("journal")
    content.position.y = 27
    content.add_theme_constant_override("separation",10)
    content.add_child(text("EL DIARIO DE ALBION",25,"dfc68f"))
    var scroll = ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(740,318)
    content.add_child(scroll)
    var entries = VBoxContainer.new()
    entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entries.add_theme_constant_override("separation",9)
    scroll.add_child(entries)
    var current = state.current_chapter()
    for chapter in chapters:
        var number = int(chapter.id)
        var progress = state.chapter_progress(number)
        var unlocked = number<=current
        entries.add_child(text("ACTO %s · %s" % [number,chapter.title],16,"dfc68f" if unlocked else "8c8992"))
        if unlocked:
            var gauge = HealthGauge.new()
            gauge.custom_minimum_size = Vector2(710,6)
            gauge.max_value = progress.total
            gauge.value = progress.completed
            entries.add_child(gauge)
            entries.add_child(text("Historia: %s de %s hitos" % [progress.completed,progress.total],14))
            if number==current:
                for i in range(chapter.milestones.size()):
                    var done = progress.done[i]
                    var revealed = done or i==0 or progress.done[i-1]
                    var caption = chapter.milestones[i] if revealed else "Por descubrir"
                    entries.add_child(text(("[x] " if done else "[ ] ")+caption,14))
        else:
            entries.add_child(text("Capítulo por descubrir",13,"8c8992"))
    content.add_child(text("Recuerdos de Shalem: %s · Accesos: %s" % [state.rewards.size(),state.cat_access],14))
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",12)
    content.add_child(row)
    focus_button = button("Volver","resume",row)
    button("Rever la introducción","replay_opening",row)
    if state.flags.get("arrived_londinium",false):
        button("Rever el viaje","replay_journey",row)
    focus_button.grab_focus()

func departure():
    clear_panel("departure")
    content.add_child(text("El camino conduce a Londinium",28,"dfc68f"))
    paragraph("Morwenna ha escapado. Una orden sellada señala la capital. Puedes revisar el diario y explorar Oakhaven antes de partir. La partida conservará el progreso y los recuerdos obtenidos.",19)
    focus_button = button("Partir hacia Londinium","depart",content)
    button("Revisar el diario","journal",content)
    button("Seguir en Oakhaven","resume",content)
    focus_button.grab_focus()

func story_save_error():
    clear_panel("story_save_error")
    content.add_child(text("No se pudo guardar la llegada",26,"dfc68f"))
    paragraph("El cierre de Oakhaven está conservado en esta sesión. Reintenta el guardado para entrar en Londinium o vuelve al sendero.",18)
    focus_button = button("Reintentar guardado","story_retry",content)
    button("Volver a Oakhaven","resume",content)
    focus_button.grab_focus()
