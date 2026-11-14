extends Control
signal action(id: String)
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")
var page = "cover"
var background: TextureRect
var shade: ColorRect
var panel: PanelContainer
var column: VBoxContainer
var continue_button: Button
var focus_button: Button
var mute_button: Button
var motion_button: Button
var volume_slider: HSlider
var volume_label: Label
var status_label: Label

func _ready():
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background = TextureRect.new()
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.texture = preload("res://assets/menu/cover.png")
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    shade = ColorRect.new()
    shade.color = Color(0.015,0.02,0.04,0.12)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

func box() -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.035,0.035,0.065,0.96)
    style.border_color = Color("b79b70")
    style.set_border_width_all(1)
    style.set_content_margin_all(18)
    return style

func words(value: String,font_size: int=16,color: String="e9dfcc") -> Label:
    var label = Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",Color(color))
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func button(value: String,id: String,parent: Node) -> Button:
    var control = Button.new()
    control.text = value
    control.custom_minimum_size.y = 44
    control.add_theme_font_size_override("font_size",16)
    for state in ["normal","hover","pressed","focus","disabled"]:
        var style = StyleBoxFlat.new()
        style.bg_color = Color("30243c" if state in ["hover","pressed","focus"] else "151824")
        style.border_color = Color("e3c48e" if state=="focus" else "6c5e51")
        style.set_border_width_all(2 if state=="focus" else 1)
        style.set_content_margin_all(7)
        control.add_theme_stylebox_override(state,style)
    control.add_theme_color_override("font_color",Color("eee0c2"))
    control.add_theme_color_override("font_disabled_color",Color("99929d"))
    parent.add_child(control)
    control.pressed.connect(func(): action.emit(id))
    return control

func begin(screen: String,area: Rect2):
    page = screen
    show()
    if is_instance_valid(panel):
        remove_child(panel)
        panel.queue_free()
    panel = PanelContainer.new()
    panel.position = area.position
    panel.size = area.size
    panel.add_theme_stylebox_override("panel",box())
    add_child(panel)
    column = VBoxContainer.new()
    column.add_theme_constant_override("separation",9)
    panel.add_child(column)
    shade.color.a = 0.0 if screen=="cover" else 0.20

func cover():
    begin("cover",Rect2(265,479,430,44))
    panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
    column.add_theme_constant_override("separation",0)
    focus_button = button("Pulsa Enter o haz clic para comenzar","open_menu",column)
    focus_button.grab_focus()

func main_menu(has_save: bool):
    begin("title",Rect2(628,106,294,403))
    column.add_child(words("ALBION TE ESPERA",17,"dfc18c"))
    continue_button = button("Continuar" if has_save else "Continuar · sin partida","continue",column)
    continue_button.disabled = not has_save
    var new_button = button("Nueva partida","new_game",column)
    button("Opciones","open_options",column)
    button("Instrucciones","open_instructions",column)
    button("Créditos","open_credits",column)
    if not OS.has_feature("web"):
        button("Salir del juego","exit_game",column)
    column.add_child(words("DEMO NARRATIVA  ·  0.4",12,"b9adba"))
    focus_button = continue_button if has_save else new_button
    focus_button.grab_focus()

func characters():
    begin("characters",Rect2(175,105,610,406))
    column.add_child(words("ELIGE A QUIÉN GUIAR",24,"dfc18c"))
    column.add_child(words("Ambos comparten la historia. Tu compañero seguirá a tu lado.",15))
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",20)
    column.add_child(row)
    for identity in ["Thomas","Khaterine"]:
        var card = VBoxContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_constant_override("separation",8)
        row.add_child(card)
        var portrait = TextureRect.new()
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.texture = Sprites.texture("portrait_"+identity.to_lower())
        portrait.custom_minimum_size = Vector2(100,112)
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        card.add_child(portrait)
        card.add_child(words("Ágil y veloz. Espada y combate cercano; menor resistencia." if identity=="Thomas" else "Magia a distancia y mayor resistencia; movimiento más lento.",15))
        var pick = button("Elegir "+identity,"start_"+identity.to_lower(),card)
        if identity=="Thomas": focus_button = pick
    button("Volver","front_back",column)
    focus_button.grab_focus()

func confirm_new(identity: String):
    begin("confirm_new",Rect2(220,177,520,254))
    column.add_child(words("¿COMENZAR DE NUEVO?",23,"dfc18c"))
    column.add_child(words("La nueva partida con %s sustituirá tu checkpoint cuando termine el prólogo. Tus opciones se conservarán." % identity,17))
    button("Comenzar nueva partida","confirm_new",column)
    focus_button = button("Conservar mi partida","cancel_new",column)
    focus_button.grab_focus()

func options(settings: Dictionary):
    begin("options",Rect2(255,113,450,395))
    column.add_child(words("OPCIONES",25,"dfc18c"))
    column.add_child(words("Tus preferencias se aplican también a nuevas partidas.",15))
    volume_label = words("",16)
    column.add_child(volume_label)
    volume_slider = HSlider.new()
    volume_slider.min_value = 0
    volume_slider.max_value = 100
    volume_slider.step = 1
    volume_slider.custom_minimum_size.y = 36
    volume_slider.focus_mode = Control.FOCUS_ALL
    volume_slider.add_theme_stylebox_override("focus",box())
    column.add_child(volume_slider)
    volume_slider.value_changed.connect(func(value): action.emit("volume:"+str(int(value))))
    mute_button = button("","mute",column)
    motion_button = button("","motion",column)
    status_label = words("",13,"c5b3c8")
    column.add_child(status_label)
    focus_button = button("Volver","front_back",column)
    refresh_options(settings,true)
    status_label.text = "Los cambios se guardan en este dispositivo."
    volume_slider.grab_focus()

func refresh_options(settings: Dictionary,saved: bool):
    volume_label.text = "Volumen general   %s%%" % int(round(settings.volume*100))
    volume_slider.set_value_no_signal(settings.volume*100)
    mute_button.text = "Sonido: "+("silenciado" if settings.muted else "activado")
    motion_button.text = "Movimiento ambiental: "+("reducido" if settings.reduced_motion else "activado")
    status_label.text = "Guardado en este dispositivo" if saved else "No se pudo guardar. Se conserva la opción anterior."

func information(screen: String):
    begin(screen,Rect2(190,108,580,403))
    column.add_child(words("INSTRUCCIONES" if screen=="instructions" else "CRÉDITOS",24,"dfc18c"))
    var scroll = ScrollContainer.new()
    scroll.custom_minimum_size.y = 267
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(scroll)
    var content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",12)
    scroll.add_child(content)
    if screen=="instructions":
        content.add_child(words("TECLADO Y RATÓN",16,"dfc18c"))
        content.add_child(words("WASD / Flechas   Moverse por el sendero\nJ / K   Ataque ligero / fuerte\nL   Mantener guardia; bloqueo preciso al inicio\nEspacio   Esquivar\nQ   Lanzar el arma\nE   Hablar, interactuar o recuperar tu arma\nTab   Cambiar entre Thomas y Khaterine\nI   Abrir o cerrar el diario\nEsc   Pausa / volver",16))
        content.add_child(words("Sigue los objetivos del diario. Al ganar un acceso, Shalem propone un juego de memoria opcional. Puedes saltar el prólogo y los relatos con Esc. En los menús usa flechas o Tab, y Enter para elegir. El mando y el cooperativo local siguen pendientes.",15))
    else:
        content.add_child(words("CREACIÓN, HISTORIA Y DIRECCIÓN VISUAL\nKevin",17,"dfc18c"))
        content.add_child(words("DESARROLLO\nKevin con asistencia de Codex",17))
        content.add_child(words("ARTE\nCarátula basada en la imagen de Kevin. Ilustraciones, sprites y adaptación de portada asistidos por image_gen.",16))
        content.add_child(words("MOTOR\nGodot Engine · licencia MIT. Los paquetes incluyen los avisos de licencia del motor y de sus componentes.",16))
        content.add_child(words("SONIDO\nEfectos y ambiente sintetizados provisionales. No contiene voces grabadas ni música final.",16))
        content.add_child(words("THE LIGHT IN THE DARKNESS\nDemo narrativa 0.4 · Proyecto en desarrollo",16,"dfc18c"))
    focus_button = button("Volver","front_back",column)
    focus_button.grab_focus()

func _gui_input(event):
    if page=="cover" and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
        action.emit("open_menu")
        accept_event()
