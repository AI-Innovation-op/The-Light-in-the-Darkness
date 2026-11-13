extends Control
signal action(id: String)
const Portrait = preload("res://src/presentation/godot/shalem_portrait.gd")
var background: TextureRect
var body: Label
var speaker: Label
var heading: Label
var counter: Label
var portrait
var next_button: Button
var skip_button: Button
var shade: ColorRect
var elapsed = 0.0
var letters = 0.0
var reduced = false
var texture_cache: Dictionary = {}

func label_at(value: String,at: Vector2,area: Vector2,font_size: int,color: String) -> Label:
    var label = Label.new()
    label.text = value
    label.position = at
    label.size = area
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",Color(color))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    return label

func make_button(value: String,at: Vector2,area: Vector2,id: String) -> Button:
    var button = Button.new()
    button.text = value
    button.position = at
    button.size = area
    button.add_theme_font_size_override("font_size",14)
    for state in ["normal","hover","focus","pressed"]:
        var box = StyleBoxFlat.new()
        box.bg_color = Color("30243f" if state!="normal" else "181626")
        box.border_color = Color("dfc28b" if state!="normal" else "79694e")
        box.set_border_width_all(2 if state=="focus" else 1)
        button.add_theme_stylebox_override(state,box)
    button.add_theme_color_override("font_color",Color("e8d9b8"))
    add_child(button)
    button.pressed.connect(func():
        if id=="story_next":
            advance_or_reveal()
        else:
            action.emit(id))
    return button

func _ready():
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background = TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    shade = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.02,0.025,0.05,0.06)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    var panel = Panel.new()
    panel.position = Vector2(32,310)
    panel.size = Vector2(896,214)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var box = StyleBoxFlat.new()
    box.bg_color = Color(0.045,0.035,0.075,0.97)
    box.border_color = Color("bda376")
    box.set_border_width_all(2)
    panel.add_theme_stylebox_override("panel",box)
    add_child(panel)
    portrait = Portrait.new()
    portrait.position = Vector2(48,337)
    portrait.size = Vector2(78,78)
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(portrait)
    speaker = label_at("",Vector2(145,326),Vector2(750,25),15,"e2c28b")
    body = label_at("",Vector2(145,356),Vector2(750,106),17,"ece5d4")
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_constant_override("line_spacing",3)
    heading = label_at("",Vector2(34,24),Vector2(675,30),17,"ece4ce")
    heading.add_theme_color_override("font_shadow_color",Color.BLACK)
    heading.add_theme_constant_override("shadow_offset_y",2)
    counter = label_at("",Vector2(48,479),Vector2(580,30),13,"afa5bd")
    next_button = make_button("Continuar [Espacio]",Vector2(678,471),Vector2(228,40),"story_next")
    skip_button = make_button("Saltar intro [Esc]",Vector2(755,20),Vector2(173,43),"story_skip")

func present(page: Dictionary,index: int,total: int,is_opening: bool,reduce_motion: bool):
    show()
    reduced = reduce_motion
    elapsed = 0
    letters = 0
    portrait.reduced_motion = reduced
    portrait.visible = is_opening
    speaker.text = page.get("speaker","")
    heading.text = page.get("heading","")
    body.text = page.get("body","")
    body.position.x = 145 if is_opening else 55
    body.size.x = 750 if is_opening else 850
    speaker.position.x = body.position.x
    body.visible_characters = -1 if reduced else 0
    counter.text = "%s / %s  ·  Enter o Espacio para continuar" % [index+1,total]
    skip_button.text = "Saltar intro [Esc]" if is_opening else "Saltar relato [Esc]"
    next_button.text = "Continuar [Espacio]" if index+1<total else ("Entrar en Albion" if is_opening else "Entrar en Londinium")
    var path = "res://assets/cinematics/%s.png" % page.get("image","")
    if not texture_cache.has(path) and ResourceLoader.exists(path):
        texture_cache[path] = load(path)
    background.texture = texture_cache.get(path)
    next_button.grab_focus()

func advance_or_reveal():
    if body.visible_characters>=0 and body.visible_characters<body.get_total_character_count():
        body.visible_characters = -1
        return
    action.emit("story_next")

func _process(delta):
    if not visible:
        return
    elapsed += delta
    if body.visible_characters>=0:
        letters += delta*62
        body.visible_characters = int(letters)
        if body.visible_characters>=body.get_total_character_count():
            body.visible_characters = -1
    if not reduced:
        shade.color.a = 0.06+sin(elapsed*0.6)*0.012

func _unhandled_key_input(event):
    if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_ENTER]:
        advance_or_reveal()
        get_viewport().set_input_as_handled()
