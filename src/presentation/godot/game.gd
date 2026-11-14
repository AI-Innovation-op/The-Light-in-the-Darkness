extends Node2D
## Composition root and Godot adventure controller. Domain rules live under src/domain.
const CatView = preload("res://src/presentation/godot/cat_view.gd")
const ActorView = preload("res://src/presentation/godot/actor_view.gd")
const EnemyView = preload("res://src/presentation/godot/enemy_view.gd")
const VillageView = preload("res://src/presentation/godot/village_view.gd")
const GameInterface = preload("res://src/presentation/godot/game_interface.gd")
const SaveRepository = preload("res://src/infrastructure/persistence/local_save_repository.gd")
const AdventureSession = preload("res://src/application/adventure_session.gd")
const SoundAdapter = preload("res://src/infrastructure/audio/sound_adapter.gd")
const NarrativeRepository = preload("res://src/infrastructure/content/narrative_repository.gd")
const StoryDirector = preload("res://src/application/story_director.gd")
const LondiniumView = preload("res://src/presentation/godot/londinium_view.gd")
const PreferencesService = preload("res://src/application/preferences_service.gd")

var session = AdventureSession.new(SaveRepository.new())
var narrative = NarrativeRepository.new()
var story = StoryDirector.new(session)
var replaying_story = false
var londinium
var boss_spawned = false
var hazards: Array = []
var obstacles: Array = []
var village
var interface
var audio
var camera: Camera2D
var heroes: Array = []
var elowen
var enemies: Array = []
var bolts: Array = []
var drops: Array = []
var bursts: Array = []
var dialogue_lines: Array = []
var dialogue_index = 0
var dialogue_done = ""
var cat_view
var cat_position = Vector2(100,425)
var wave = 0
var wave_wait = -1.0
var helper_cooldown = 0.0
var toast_time = 0.0
var clock = 0.0
var started = false
var has_save = false
var preferences
var preferences_storage_path = "user://preferences_v1.json"
var front_return = "title"
var pending_identity = "Thomas"
var opening_starts_game = false
var audit: Dictionary = {"moves":0,"switches":0,"attacks":0,"dodges":0,"parries":0,"throws":0,"recoveries":0,"kills":0,"dialogues":0,"memory_wins":0}

func _ready():
    configure_input()
    village = VillageView.new()
    village.show_behind_parent = true
    add_child(village)
    londinium = LondiniumView.new()
    londinium.show_behind_parent = true
    add_child(londinium)
    londinium.hide()
    camera = Camera2D.new()
    camera.position = Vector2(480,270)
    add_child(camera)
    camera.make_current()
    for who in ["Thomas","Khaterine"]:
        var hero = ActorView.new()
        hero.kind = who
        hero.position = Vector2(220 if who=="Thomas" else 165,410 if who=="Thomas" else 425)
        heroes.append(hero)
        add_child(hero)
    cat_view = CatView.new()
    cat_view.hide()
    add_child(cat_view)
    elowen = ActorView.new()
    elowen.kind = "Elowen"
    elowen.position = Vector2(435,363)
    add_child(elowen)
    for obstacle in [Rect2(570,444,28,25),Rect2(1435,350,32,24)]:
        var body = StaticBody2D.new()
        var shape = CollisionShape2D.new()
        var rectangle = RectangleShape2D.new()
        rectangle.size = obstacle.size
        shape.shape = rectangle
        body.position = obstacle.get_center()
        body.add_child(shape)
        body.collision_layer = 1
        add_child(body)
        obstacles.append(body)
    audio = SoundAdapter.new()
    add_child(audio)
    interface = GameInterface.new()
    add_child(interface)
    interface.action.connect(on_ui_action)
    has_save = session.load_checkpoint()
    var settings_storage = SaveRepository.new()
    settings_storage.path = preferences_storage_path
    preferences = PreferencesService.new(settings_storage)
    preferences.load_settings(session.state.snapshot())
    apply_preferences()
    session.mode = "cover"
    interface.front_page("cover")
    if OS.has_feature("web") and OS.has_feature("playtest"):
        var diagnostics = Timer.new()
        diagnostics.wait_time = 1.0
        diagnostics.timeout.connect(publish_diagnostic)
        add_child(diagnostics)
        diagnostics.start()
    queue_redraw()

func configure_input():
    var bindings = {"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"walk_up":[KEY_W,KEY_UP],"walk_down":[KEY_S,KEY_DOWN],"light":[KEY_J],"heavy":[KEY_K],"guard":[KEY_L],"dodge":[KEY_SPACE],"interact":[KEY_E],"swap":[KEY_TAB],"throw_weapon":[KEY_Q],"pause_game":[KEY_ESCAPE],"journal":[KEY_I]}
    for id in bindings:
        if not InputMap.has_action(id):
            InputMap.add_action(id)
        for key in bindings[id]:
            var event = InputEventKey.new()
            event.physical_keycode = key
            if not InputMap.action_has_event(id,event):
                InputMap.action_add_event(id,event)

func active():
    return heroes[1] if session.state.chosen=="Khaterine" else heroes[0]

func partner():
    return heroes[0] if session.state.chosen=="Khaterine" else heroes[1]

func start_scene(identity: String,continuing: bool=false):
    if not continuing:
        session.start(identity)
    apply_preferences()
    started = true
    for hero in heroes:
        hero.model.configure(hero.kind)
        hero.position = Vector2(220 if hero.kind=="Thomas" else 165,410 if hero.kind=="Thomas" else 425)
        hero.cooldown = 0
        hero.dodge_time = 0
        hero.guarding = false
    clear_combat()
    wave = 0
    wave_wait = -1
    boss_spawned = false
    hazards.clear()
    village.visible = session.state.current_chapter()==1
    londinium.visible = session.state.current_chapter()==2
    elowen.visible = session.state.current_chapter()==1
    for obstacle in obstacles:
        obstacle.collision_layer = 1 if session.state.current_chapter()==1 else 0
    session.mode = "adventure"
    interface.resume()
    audio.set_muted(session.state.muted)
    audio.ambience(true)
    notify("E para hablar · Tab para cambiar entre Thomas y Khaterine",6)
    if continuing and session.state.flags.get("encounter_cleared",false):
        heroes[0].position.x = 1330
        heroes[1].position.x = 1280
        notify("Punto seguro recuperado. Shalem te espera junto al sendero.",5)
    if session.state.current_chapter()==2:
        enter_londinium()
    has_save = session.save() or has_save

func clear_combat():
    for enemy in enemies:
        enemy.queue_free()
    enemies.clear()
    bolts.clear()
    drops.clear()
    bursts.clear()

func _unhandled_input(event):
    if event is InputEventKey and event.echo:
        return
    if session.mode in ["cover","title","characters","options","instructions","credits","confirm_new"]:
        if event.is_action_pressed("pause_game"):
            front_back()
            get_viewport().set_input_as_handled()
        return
    if session.mode in ["opening","interlude"]:
        if event.is_action_pressed("pause_game"):
            story.sequence.skip()
            finish_narration()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("journal") and session.mode in ["adventure","journal"]:
        if session.mode=="journal":
            resume_world()
        else:
            open_journal()
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("pause_game"):
        if session.mode == "adventure":
            session.mode = "pause"
            interface.pause_menu(session.state.muted,session.state.reduced_motion)
        elif session.mode in ["pause","memory","journal","departure"]:
            resume_world()
        get_viewport().set_input_as_handled()
        return
    if session.mode != "adventure":
        return
    if event.is_action_pressed("swap"):
        session.state.chosen = "Khaterine" if session.state.chosen=="Thomas" else "Thomas"
        for hero in heroes:
            hero.guarding = false
        audit.switches += 1
        notify("%s · %s" % [active().kind,"Magia a distancia" if active().kind=="Khaterine" else "Espada Corta del Monaguillo"])
    elif event.is_action_pressed("light"):
        attack(active(),false)
    elif event.is_action_pressed("heavy"):
        attack(active(),true)
    elif event.is_action_pressed("dodge"):
        if active().evade(Input.get_vector("walk_left","walk_right","walk_up","walk_down")):
            audit.dodges += 1
            audio.cue("evade")
    elif event.is_action_pressed("throw_weapon"):
        throw_weapon()
    elif event.is_action_pressed("interact"):
        interact()
    get_viewport().set_input_as_handled()

func _physics_process(delta: float):
    if not started:
        return
    update_interface()
    village.set_process(not session.state.reduced_motion and session.mode=="adventure")
    if session.mode != "adventure":
        return
    clock += delta
    toast_time = maxf(0,toast_time-delta)
    if toast_time<=0:
        interface.toast.text = ""
    var hero = active()
    var companion = partner()
    hero.selected = true
    companion.selected = false
    var move = Input.get_vector("walk_left","walk_right","walk_up","walk_down")
    if move.length()>0.1:
        audit.moves += 1
    hero.guarding = Input.is_action_pressed("guard") and hero.dodge_time<=0
    hero.tick(delta,move)
    var offset = hero.position-Vector2(hero.facing*65,-12)-companion.position
    companion.guarding = false
    companion.tick(delta,offset.normalized() if offset.length()>12 else Vector2.ZERO)
    cat_position = cat_position.move_toward(hero.position+Vector2(-hero.facing*38,16),delta*150)
    cat_view.position = cat_position
    cat_view.z_index = int(cat_position.y)
    cat_view.facing = hero.facing
    cat_view.visible = started
    cat_view.queue_redraw()
    camera.position.x = lerpf(camera.position.x,clampf(hero.position.x,480,1660),minf(1,delta*6))
    camera.position.y = 270
    for enemy in enemies.duplicate():
        if enemy.hp<=0:
            continue
        if enemy.tick(delta,hero.position):
            if enemy.is_boss and enemy.hp<enemy.max_hp*0.5:
                hazards.append({"position":enemy.target_position,"age":0.0,"fired":false})
            if enemy.position.distance_to(hero.position)<86 and absf(enemy.position.y-hero.position.y)<40:
                var was_armed = hero.armed
                var result = hero.take_hit(23 if hero.kind=="Thomas" else 17,enemy.heavy)
                if result == "parried":
                    enemy.state = "stunned"
                    enemy.timer = 1.25
                    audit.parries += 1
                    notify("Bloqueo perfecto · postura rota")
                    audio.cue("parry")
                elif result == "blocked":
                    audio.cue("block")
                elif result in ["hit","guard_broken"]:
                    audio.cue("hit")
                    burst(hero.position,"d89172")
                    if was_armed and not hero.armed:
                        drop_weapon(hero,hero.position+Vector2(-hero.facing*70,10))
                        notify("¡Desarme! Recoge tu arma con E. Puedes atacar a puños.",4)
    helper_cooldown = maxf(0,helper_cooldown-delta)
    if not enemies.is_empty() and helper_cooldown<=0:
        var nearest = nearest_enemy(companion.position)
        if nearest != null and nearest.position.distance_to(companion.position)<145:
            companion.facing = signf(nearest.position.x-companion.position.x)
            attack(companion,false,true)
            helper_cooldown = 1.6
    tick_bolts(delta)
    for hazard in hazards:
        hazard.age += delta
        if hazard.age>=0.85 and not hazard.fired:
            hazard.fired = true
            if hero.position.distance_to(hazard.position)<47:
                var was_armed = hero.armed
                var result = hero.take_hit(20,true)
                if was_armed and not hero.armed:
                    drop_weapon(hero,hero.position+Vector2(-60,0))
                if result in ["hit","guard_broken"]:
                    audio.cue("hit")
    hazards = hazards.filter(func(h): return h.age<1.2)
    for effect in bursts:
        effect.life -= delta
    bursts = bursts.filter(func(e): return e.life>0)
    if session.state.current_chapter()==1 and session.state.flags.get("met_elowen",false) and not session.state.flags.get("encounter_cleared",false) and hero.position.x>760 and wave==0:
        wave = 1
        spawn_enemy(Vector2(1080,400),true)
        notify("Acechador de Ceniza · espera su señal y esquiva o bloquea.",5)
    if wave>0 and enemies.is_empty() and not session.state.flags.get("encounter_cleared",false):
        if wave_wait<0:
            wave_wait = 1.6
        else:
            wave_wait -= delta
            if wave_wait<=0:
                wave_wait = -1
                if wave==1:
                    wave = 2
                    spawn_enemy(Vector2(hero.position.x+190,365),false)
                    spawn_enemy(Vector2(hero.position.x+235,440),false)
                    spawn_enemy(Vector2(hero.position.x-210,405),false)
                    notify("Llegan más cenizas. Mantén el movimiento.",4)
                else:
                    var saved = session.finish_encounter()
                    notify("Sendero despejado · acceso a Shalem obtenido. Pulsa E junto a él." if saved else "Acceso obtenido. No se pudo guardar el checkpoint; conserva esta sesión abierta.",7)
                    audio.cue("reward")
    if hero.hp<=0:
        session.mode = "defeat"
        interface.end_panel(false)
    if session.state.current_chapter()==1 and session.state.flags.get("encounter_cleared",false) and not session.state.flags.get("morwenna_defeated",false) and hero.position.x>1570 and not boss_spawned:
        boss_spawned = true
        var boss = EnemyView.new()
        boss.is_boss = true
        boss.hp = 196
        boss.max_hp = 196
        boss.position = Vector2(1900,405)
        enemies.append(boss)
        add_child(boss)
        begin_dialogue(narrative.dialogue("morwenna_intro"),"morwenna")
    queue_redraw()

func nearest_enemy(origin: Vector2):
    var found = null
    var distance = INF
    for enemy in enemies:
        if enemy.hp>0 and enemy.position.distance_to(origin)<distance:
            found = enemy
            distance = enemy.position.distance_to(origin)
    return found

func attack(hero,heavy: bool,assisting: bool=false):
    if not hero.strike(heavy):
        return
    if not assisting:
        audit.attacks += 1
    audio.cue("magic" if hero.kind=="Khaterine" else "swing")
    if hero.kind=="Khaterine" and hero.armed:
        var direction = Vector2(hero.facing,0)
        var enemy = nearest_enemy(hero.position)
        if enemy != null and enemy.position.distance_to(hero.position)<370 and signf(enemy.position.x-hero.position.x)==hero.facing:
            direction = (enemy.position-hero.position).normalized()
        bolts.append({"position":hero.position+Vector2(18*hero.facing,-18),"velocity":direction*390,"life":1.0,"damage":32 if heavy else 22,"color":"b5a0dd","weapon":false,"owner":hero.kind})
    else:
        var power = (35 if heavy else 21) if hero.armed else 9
        for enemy in enemies.duplicate():
            var offset = enemy.position-hero.position
            if absf(offset.y)<39 and offset.length()<(112 if heavy else 84) and offset.x*hero.facing>=-12:
                harm_enemy(enemy,power*0.65 if assisting else power,Vector2(hero.facing,0))

func harm_enemy(enemy,amount: float,direction: Vector2):
    enemy.damage(amount,direction)
    audio.cue("hit")
    burst(enemy.position+Vector2(0,-18),"c7be9f")
    if enemy.hp<=0:
        if enemy.is_boss:
            session.defeat_morwenna()
            hazards.clear()
            notify("Morwenna se retira entre las raíces. El camino a Londinium está abierto.",6)
        audit.kills += 1
        enemies.erase(enemy)
        enemy.queue_free()

func spawn_enemy(at: Vector2,heavy: bool):
    var enemy = EnemyView.new()
    enemy.position = Vector2(clampf(at.x,820,1930),at.y)
    enemy.heavy = heavy
    enemies.append(enemy)
    add_child(enemy)

func throw_weapon():
    var hero = active()
    if not hero.armed or hero.cooldown>0:
        return
    hero.armed = false
    hero.cooldown = 0.35
    bolts.append({"position":hero.position+Vector2(20*hero.facing,-12),"velocity":Vector2(hero.facing*430,0),"life":0.55,"damage":40,"color":"d4cfb9","weapon":true,"owner":hero.kind})
    audit.throws += 1
    audio.cue("swing")

func drop_weapon(hero,at: Vector2):
    drops.append({"owner":hero.kind,"position":Vector2(clampf(at.x,90,2040),clampf(at.y,355,470))})

func tick_bolts(delta: float):
    for bolt in bolts.duplicate():
        bolt.position += bolt.velocity*delta
        bolt.life -= delta
        var hit = false
        for enemy in enemies.duplicate():
            if bolt.position.distance_to(enemy.position+Vector2(0,-18))<26:
                harm_enemy(enemy,bolt.damage,bolt.velocity.normalized())
                hit = true
                break
        if hit or bolt.life<=0 or bolt.position.x<70 or bolt.position.x>2080:
            if bolt.weapon:
                drops.append({"owner":bolt.owner,"position":Vector2(clampf(bolt.position.x,90,2040),clampf(bolt.position.y+12,355,470))})
            bolts.erase(bolt)

func interact():
    var hero = active()
    for drop in drops:
        if drop.owner==hero.kind and drop.position.distance_to(hero.position)<65:
            hero.armed = true
            drops.erase(drop)
            audit.recoveries += 1
            audio.cue("pickup")
            notify("Arma recuperada")
            return
    if session.state.current_chapter()==2:
        if session.state.cat_access>0 and not session.state.flags.get("memory_completed",false) and hero.position.distance_to(cat_position)<80:
            session.mode = "memory"
            interface.memory()
            return
        begin_dialogue(narrative.dialogue("londinium_arrival"),"londinium")
        return
    if hero.position.x>1920 and session.state.can_depart() and enemies.is_empty():
        session.mode = "departure"
        interface.departure()
        return
    if elowen.visible and hero.position.distance_to(elowen.position)<115 and enemies.is_empty():
        begin_dialogue(narrative.dialogue("elowen_huerto"),"elowen")
    elif hero.position.distance_to(cat_position)<80 and enemies.is_empty():
        if session.state.flags.get("memory_completed",false):
            interface.end_panel(true)
            session.mode = "complete"
        elif session.state.cat_access>0:
            session.mode = "memory"
            interface.memory()
        else:
            begin_dialogue(narrative.dialogue("shalem_viaje"),"shalem")

func begin_dialogue(lines: Array,after: String):
    session.mode = "dialogue"
    dialogue_lines = lines
    dialogue_index = 0
    dialogue_done = after
    audit.dialogues += 1
    interface.dialogue(lines[0][0],lines[0][1],lines.size()==1)

func on_ui_action(id: String):
    if id.begins_with("volume:") and session.mode=="options":
        save_preference("volume",float(id.trim_prefix("volume:"))/100.0)
        return
    if id.begins_with("card_"):
        interface.flip(int(id.trim_prefix("card_")))
        audio.cue("pickup")
        return
    match id:
        "open_menu": show_main_menu()
        "new_game":
            session.mode = "characters"
            interface.front_page("characters")
        "open_options","open_instructions","open_credits":
            front_return = "pause" if session.mode=="pause" else "title"
            session.mode = {"open_options":"options","open_instructions":"instructions","open_credits":"credits"}[id]
            interface.front_page(session.mode,preferences.values)
        "front_back": front_back()
        "confirm_new": begin_new_game()
        "cancel_new":
            session.mode = "characters"
            interface.front_page("characters")
        "exit_game":
            if not OS.has_feature("web"):
                get_tree().quit()
        "story_next":
            if session.mode not in ["opening","interlude"]:
                return
            if story.sequence.advance():
                finish_narration()
            else:
                show_narration_page()
        "story_skip":
            if session.mode in ["opening","interlude"]:
                story.sequence.skip()
                finish_narration()
        "story_retry": finish_narration()
        "journal": open_journal()
        "replay_opening": start_narration("opening",true)
        "replay_journey":
            if session.state.flags.get("arrived_londinium",false):
                start_narration("act1_to_act2",true)
        "depart": start_narration("act1_to_act2")
        "start_thomas","start_khaterine":
            if session.mode!="characters":
                return
            pending_identity = "Thomas" if id=="start_thomas" else "Khaterine"
            if has_save:
                session.mode = "confirm_new"
                interface.front_page("confirm_new",{"identity":pending_identity})
            else:
                begin_new_game()
        "continue":
            if session.load_checkpoint():
                start_scene(session.state.chosen,true)
            else:
                has_save = false
                show_main_menu()
        "dialogue_next":
            dialogue_index += 1
            if dialogue_index>=dialogue_lines.size():
                if dialogue_done=="elowen":
                    session.state.flags["met_elowen"] = true
                    session.save()
                resume_world()
            else:
                interface.dialogue(dialogue_lines[dialogue_index][0],dialogue_lines[dialogue_index][1],dialogue_index==dialogue_lines.size()-1)
        "resume","memory_exit": resume_world()
        "mute":
            save_preference("muted",not preferences.values.muted)
        "motion":
            save_preference("reduced_motion",not preferences.values.reduced_motion)
        "restart":
            # Checkpoint progression is retained; health, weapons and encounter reset.
            var identity = session.state.chosen
            start_scene(identity,true)
        "title":
            has_save = session.save() or has_save
            show_main_menu()
        "memory_help": interface.memory_help()
        "memory_win","memory_retry":
            if session.claim_activity():
                audit.memory_wins += 1
                audio.cue("reward")
                session.mode = "complete"
                interface.end_panel(true)
            elif session.state.flags.get("memory_completed",false):
                session.mode = "complete"
                interface.end_panel(true)
            else:
                session.mode = "save_error"
                interface.save_error()

func apply_preferences():
    session.state.muted = preferences.values.muted
    session.state.reduced_motion = preferences.values.reduced_motion
    audio.set_muted(preferences.values.muted)
    AudioServer.set_bus_mute(0,preferences.values.muted or preferences.values.volume<=0)
    AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,preferences.values.volume)))

func save_preference(id: String,value: Variant):
    var saved = preferences.update(id,value)
    apply_preferences()
    if session.mode=="options":
        interface.front_menu.refresh_options(preferences.values,saved)

func show_main_menu():
    session.mode = "title"
    interface.title(has_save)
    audio.ambience(true)

func begin_new_game():
    opening_starts_game = true
    start_narration("opening")

func front_back():
    match session.mode:
        "cover": show_main_menu()
        "title":
            session.mode = "cover"
            interface.front_page("cover")
        "confirm_new":
            session.mode = "characters"
            interface.front_page("characters")
        "characters": show_main_menu()
        "options","instructions","credits":
            if front_return=="pause":
                session.mode = "pause"
                interface.pause_menu(session.state.muted,session.state.reduced_motion)
            else:
                show_main_menu()

func resume_world():
    session.mode = "adventure"
    interface.resume()

func notify(value: String,duration: float=3.0):
    interface.toast.text = value
    toast_time = duration

func update_interface():
    var boss = null
    for enemy in enemies:
        if enemy.is_boss:
            boss = enemy
    interface.boss_label.visible = boss!=null
    interface.boss_gauge.visible = boss!=null
    if boss!=null:
        interface.boss_gauge.max_value = boss.max_hp
        interface.boss_gauge.value = boss.hp
    for hero in heroes:
        interface.bars[hero.kind].max_value = hero.max_hp
        interface.bars[hero.kind].value = hero.hp
        interface.names[hero.kind].text = ("> " if hero==active() else "")+hero.kind.to_upper()+(" · A PUÑOS" if not hero.armed else "")
    interface.xp_label.text = "SHALEM  %s / 100     ACCESOS  %s     GUARDIA  %s%%" % [session.state.xp,session.state.cat_access,int(active().guard)]
    interface.region.text = "OAKHAVEN" if session.state.current_chapter()==1 else "LONDINIUM"
    if session.state.current_chapter()==2:
        interface.objective.text = "Acto II · Explora la entrada de la ciudadela"
    elif not session.state.flags.get("met_elowen",false):
        interface.objective.text = "Habla con Elowen junto al huerto"
    elif not session.state.flags.get("encounter_cleared",false):
        interface.objective.text = "Sigue el sendero hacia el bosque >" if wave==0 else "Despeja el sendero · %s amenazas" % enemies.size()
    elif not session.state.flags.get("morwenna_defeated",false):
        interface.objective.text = "Avanza hacia las hogueras de Morwenna >"
    else:
        interface.objective.text = "Partir hacia Londinium > · I para revisar pendientes"
    var message = ""
    if enemies.is_empty():
        message = "E · Shalem"
        if elowen.visible and active().position.distance_to(elowen.position)<115:
            message = "E · Elowen de Oakhaven"
        if session.state.current_chapter()==2:
            message = "E · Shalem · acceso pendiente   |   I · Diario" if session.state.cat_access>0 and not session.state.flags.get("memory_completed",false) else "E · Hablar sobre Londinium   |   I · Diario"
        elif active().position.x>1920 and session.state.can_depart():
            message = "E · Partir hacia Londinium"
    for drop in drops:
        if drop.owner==active().kind and drop.position.distance_to(active().position)<65:
            message = "E · Recuperar tu arma"
    interface.hint.text = message

func burst(at: Vector2,color: String):
    bursts.append({"position":at,"life":0.35,"color":color})

func _draw():
    if session.state.current_chapter()==1:
        for box in [Rect2(570,421,28,47),Rect2(1435,327,32,47)]:
            draw_rect(box,Color("615344"))
            draw_rect(box.grow(-3),Color("7a6650"),false,2)
            draw_line(box.position,box.end,Color("453f38"),3)
    for hazard in hazards:
        draw_arc(hazard.position,43,0,TAU,28,Color("d9ab65") if hazard.age<0.85 else Color("a4c17e"),3)
        if hazard.age>=0.85:
            draw_circle(hazard.position,40,Color(0.45,0.65,0.35,0.4))
    if not started:
        return
    for drop in drops:
        draw_arc(drop.position,21,0,TAU,20,Color("c4ab73"),1)
        draw_line(drop.position+Vector2(-12,-4),drop.position+Vector2(14,-12),Color("d0cfbd"),4)
        draw_line(drop.position+Vector2(-6,-13),drop.position+Vector2(-1,2),Color("b29461"),3)
    for bolt in bolts:
        draw_line(bolt.position-bolt.velocity.normalized()*22,bolt.position,Color(bolt.color),bolt.damage/10)
        draw_circle(bolt.position,4,Color("e5d5e9"))
    for effect in bursts:
        for i in range(7):
            var direction = Vector2(cos(i*TAU/7),sin(i*TAU/7))
            var at = effect.position+direction*(0.35-effect.life)*95
            draw_rect(Rect2(at,Vector2(3,3)),Color(effect.color))

func diagnostic_snapshot() -> Dictionary:
    return {"mode":session.mode,"chosen":session.state.chosen,"health":active().hp,"position":[active().position.x,active().position.y],"flags":session.state.flags,"rewards":session.state.rewards,"cat_access":session.state.cat_access,"enemies":enemies.size(),"chapter":session.state.current_chapter(),"story_page":story.sequence.index,"audit":audit}

func start_narration(id: String,replay: bool=false):
    if not story.begin(id,narrative.sequence(id)):
        return
    replaying_story = replay
    audio.set_muted(session.state.muted)
    audio.ambience(true)
    session.mode = "opening" if id=="opening" else "interlude"
    show_narration_page()

func show_narration_page():
    interface.story_page(story.sequence.current_page(),story.sequence.index,story.sequence.pages.size(),story.sequence.id=="opening",session.state.reduced_motion)

func finish_narration():
    if replaying_story:
        open_journal()
        return
    if not story.commit():
        session.mode = "story_save_error"
        interface.story_save_error()
        return
    if story.sequence.id=="opening":
        if opening_starts_game:
            opening_starts_game = false
            start_scene(pending_identity)
        else:
            show_main_menu()
    else:
        enter_londinium()
        resume_world()
        notify("Acto II · La Ciudadela Dorada de Londinium",6)

func open_journal():
    session.mode = "journal"
    interface.journal(session.state,narrative.chapters())

func enter_londinium():
    clear_combat()
    hazards.clear()
    village.hide()
    londinium.show()
    elowen.hide()
    for obstacle in obstacles:
        obstacle.collision_layer = 0
    for hero in heroes:
        hero.position = Vector2(480 if hero==active() else 420,410)
        hero.hp = hero.max_hp
        hero.armed = true
        hero.guarding = false
    cat_position = Vector2(440,440)
    camera.position = Vector2(480,270)

func publish_diagnostic():
    var payload = JSON.stringify(diagnostic_snapshot())
    JavaScriptBridge.eval("if(location.hostname==='127.0.0.1'||location.hostname==='localhost'){fetch('/playtest',{method:'POST',body:"+JSON.stringify(payload)+"}).catch(()=>{});}")
