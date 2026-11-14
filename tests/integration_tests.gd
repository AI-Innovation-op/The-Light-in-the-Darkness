extends SceneTree
var failures: Array = []
var count = 0
var game
const Sprites = preload("res://src/presentation/godot/sprite_catalog.gd")

func _initialize():
    call_deferred("run")

func check(condition: bool,label: String):
    count += 1
    if not condition:
        failures.append(label)

func frames(number: int):
    for i in range(number):
        await physics_frame

func run():
    game = load("res://main.tscn").instantiate()
    game.session.repository.path = "user://automated_integration_checkpoint.json"
    game.preferences_storage_path = "user://automated_integration_preferences.json"
    for path in [game.session.repository.path,game.preferences_storage_path]:
        for suffix in ["",".bak",".tmp"]:
            if FileAccess.file_exists(path+suffix):
                DirAccess.remove_absolute(path+suffix)
    root.add_child(game)
    await frames(3)
    check(game.interface.mode=="cover" and game.interface.front_menu.background.texture!=null,"boot opens the illustrated cover before any narration")
    var opening_clock = game.clock
    var opening_flags = game.session.state.flags.duplicate(true)
    await frames(8)
    check(game.clock==opening_clock,"cover suspends world simulation")
    game.interface.front_menu.focus_button.pressed.emit()
    check(game.session.mode=="title" and game.interface.front_menu.continue_button.disabled,"main menu disables Continue when no checkpoint exists")
    game.on_ui_action("open_options")
    game.on_ui_action("mute")
    game.on_ui_action("motion")
    game.on_ui_action("volume:39")
    check(game.session.state.muted and game.session.state.reduced_motion and is_equal_approx(game.preferences.values.volume,0.39),"main-menu settings apply without starting play")
    check(not FileAccess.file_exists(game.session.repository.path) and FileAccess.file_exists(game.preferences_storage_path),"changing options creates only a preferences file")
    game.on_ui_action("front_back")
    game.on_ui_action("open_instructions")
    await frames(2)
    check(game.session.mode=="instructions" and game.interface.front_menu.panel.get_rect().end.y<=540,"instructions fit inside the viewport")
    game._unhandled_input(key_event(KEY_ESCAPE))
    check(game.session.mode=="title","Escape returns from instructions to main menu")
    game.on_ui_action("open_credits")
    await frames(2)
    check(game.session.mode=="credits" and game.interface.front_menu.panel.get_rect().end.y<=540,"credits use a bounded scrollable page")
    game.on_ui_action("front_back")
    game.on_ui_action("new_game")
    await frames(2)
    check(game.session.mode=="characters" and game.interface.front_menu.panel.get_rect().end.y<=540,"character selection fits inside the viewport")
    game.on_ui_action("start_thomas")
    check(game.session.mode=="opening" and game.story.sequence.pages.size()==4 and not game.started,"new-game selection opens Shalem before the world")
    check(game.interface.story_screen.background.texture!=null,"opening illustration loads as a Godot resource")
    check(not FileAccess.file_exists(game.session.repository.path),"watching the prologue does not replace a checkpoint")
    game.on_ui_action("story_skip")
    check(game.session.mode=="adventure" and game.session.state.flags==opening_flags and game.active().kind=="Thomas","skipping prologue starts the selected character without story rewards")
    check(game.session.state.muted and game.session.state.reduced_motion,"new-game reset preserves user preferences")
    game._unhandled_input(key_event(KEY_ESCAPE))
    game.on_ui_action("open_options")
    await frames(8)
    check(game.clock==opening_clock and game.interface.front_menu.panel.get_rect().end.y<=540,"pause options freeze the world and stay inside the screen")
    game.on_ui_action("front_back")
    check(game.session.mode=="pause","pause options return to pause rather than the title")
    game.on_ui_action("title")
    check(not game.interface.front_menu.continue_button.disabled,"a saved campaign enables Continue")
    var before_cancel = game.session.repository.read()
    game.on_ui_action("new_game")
    game.on_ui_action("start_khaterine")
    check(game.session.mode=="confirm_new","new game asks before replacing an existing checkpoint")
    game.on_ui_action("cancel_new")
    check(game.session.repository.read()==before_cancel and game.active().kind=="Thomas","cancelled replacement preserves the checkpoint and protagonist")
    game.on_ui_action("front_back")
    game.on_ui_action("continue")
    check(game.session.mode=="adventure" and game.active().kind=="Thomas","Continue restores the checkpoint without replaying the prologue")
    var hero = game.active()
    var portraits_fit = true
    for control in game.interface.hud.get_children():
        if control is TextureRect:
            portraits_fit = portraits_fit and control.size.x<=60 and control.size.y<=60
    check(portraits_fit,"HUD portraits stay inside the compact health header")
    var art_errors: Array = []
    for id in Sprites.POSES:
        var texture: Texture2D = load("res://assets/sprites/%s.png" % id)
        var image = texture.get_image()
        if image.detect_alpha()==Image.ALPHA_NONE or image.get_pixel(0,0).a>0 or not image.get_used_rect().has_area():
            art_errors.append(id)
    check(art_errors.is_empty(),"all thirteen sprite files have real transparency and visible artwork: "+str(art_errors))
    check(hero.current_sprite()=="thomas_idle","equipped Thomas starts in the sword idle pose")
    hero.attack_time = 0.15
    check(hero.current_sprite()=="thomas_attack","Thomas attack selects the sword action pose")
    hero.armed = false
    check(hero.current_sprite()=="thomas_disarmed","disarm takes precedence over an active sword pose")
    hero.armed = true
    hero.attack_time = 0
    check(Sprites.hero_pose("Khaterine",false,true)=="khaterine_idle","disarmed Khaterine never displays the magic attack pose")
    check(Sprites.foot_rect("thomas_idle").end.y==0 and Sprites.foot_rect("thomas_attack").end.y==0,"different pose heights stay anchored on the same ground plane")
    var start_x = hero.position.x
    Input.action_press("walk_right")
    await frames(18)
    Input.action_release("walk_right")
    check(hero.position.x>start_x+30,"mapped movement advances physics body")
    game._unhandled_input(key_event(KEY_TAB))
    check(game.active().kind=="Khaterine" and game.partner().kind=="Thomas","switch selects distinct actor")
    await frames(80)
    check(game.active().position.distance_to(game.partner().position)>40,"companion leaves a readable gap after switching")
    game._unhandled_input(key_event(KEY_TAB))
    hero = game.active()
    hero.position = game.elowen.position+Vector2(-40,10)
    game.interact()
    var clock = game.clock
    await frames(15)
    check(game.session.mode=="dialogue" and game.clock==clock,"dialogue suspends world across physics frames")
    game.on_ui_action("dialogue_next")
    game.on_ui_action("dialogue_next")
    check(game.session.state.flags.get("met_elowen",false) and game.session.mode=="adventure","canonical conversation advances quest")
    game.throw_weapon()
    await frames(50)
    check(not hero.armed and game.drops.size()==1,"thrown weapon lands as recoverable item")
    hero.position = game.drops[0].position
    game.interact()
    check(hero.armed and game.drops.is_empty(),"interaction recovers own weapon")
    hero.position = Vector2(805,410)
    await frames(3)
    check(game.wave==1 and game.enemies.size()==1,"crossing forest threshold begins duel")
    # Deterministic bot uses the same attack cooldown and dodge window as the player.
    var attempts = 0
    while not game.session.state.flags.get("encounter_cleared",false) and attempts<60 and hero.hp>0:
        attempts += 1
        if game.enemies.is_empty():
            await frames(110)
            continue
        var enemy = game.enemies[0]
        hero.position = enemy.position-Vector2(75,0)
        hero.facing = 1
        if not hero.armed:
            for drop in game.drops:
                if drop.owner==hero.kind:
                    hero.position = drop.position
                    game.interact()
                    break
        game.attack(hero,true)
        await frames(40)
    check(game.session.state.flags.get("encounter_cleared",false) and game.audit.kills==4,"duel and three-enemy wave can be cleared")
    check(game.session.state.cat_access==1,"encounter grants one Shalem access")
    game.cat_position = hero.position+Vector2(-20,0)
    game.interact()
    check(game.interface.mode=="memory","Shalem opens real eight-card interface")
    clock = game.clock
    await frames(12)
    check(game.clock==clock,"memory pauses world")
    var groups = {}
    for i in range(8):
        var symbol = game.interface.card_symbols[i]
        if not groups.has(symbol): groups[symbol] = []
        groups[symbol].append(i)
    for pair in groups.values():
        game.on_ui_action("card_%s" % pair[0])
        game.on_ui_action("card_%s" % pair[1])
    check(game.session.mode=="complete" and game.session.state.rewards==["recuerdo_del_roble"],"eight-card activity grants its unique demo reward")
    check(game.session.state.cat_access==0,"success consumes one access")
    var checkpoint = game.session.repository.read()
    check(checkpoint.flags.get("memory_completed",false) and checkpoint.rewards.size()==1,"completion checkpoint is readable")
    game.on_ui_action("resume")
    await frames(5)
    check(game.clock>clock and game.session.mode=="adventure","world resumes after activity")
    game.open_journal()
    check(game.session.mode=="journal" and game.session.state.chapter_progress(1).completed==2,"journal measures story separately from Shalem reward")
    game.on_ui_action("replay_opening")
    game.on_ui_action("story_skip")
    check(game.session.mode=="journal" and game.session.state.cat_access==0,"replay returns to journal without spending access")
    game.on_ui_action("resume")
    hero.position = Vector2(1650,410)
    await frames(3)
    check(game.session.mode=="dialogue" and game.enemies.size()==1 and game.enemies[0].is_boss,"Morwenna encounter begins with dialogue")
    game.on_ui_action("dialogue_next")
    game.on_ui_action("dialogue_next")
    attempts = 0
    while not game.enemies.is_empty() and hero.hp>0 and attempts<20:
        attempts += 1
        var boss = game.enemies[0]
        if not hero.armed:
            for drop in game.drops:
                if drop.owner==hero.kind:
                    hero.position = drop.position
                    game.interact()
                    break
        hero.position = boss.position-Vector2(75,0)
        hero.facing = 1
        game.attack(hero,true)
        await frames(41)
    check(game.session.state.flags.get("morwenna_defeated",false) and hero.hp>0,"Morwenna prototype can be defeated through combat")
    check(game.session.state.chapter_progress(1).completed==3 and game.session.state.current_chapter()==1,"boss defeat does not finish chapter alone")
    hero.position.x = 1960
    game.interact()
    check(game.session.mode=="departure","exit offers review before departure")
    game.on_ui_action("depart")
    check(game.session.mode=="interlude" and game.story.sequence.pages.size()==3,"departure opens three illustrated pages")
    var illustrated_pages = true
    for i in range(3):
        illustrated_pages = illustrated_pages and game.interface.story_screen.background.texture!=null
        game.on_ui_action("story_next")
    check(illustrated_pages,"all three interlude illustrations load")
    check(game.session.mode=="adventure" and game.session.state.current_chapter()==2 and game.londinium.visible and not game.village.visible,"interlude enters playable Londinium")
    check(game.session.state.chapter_progress(1).finished and game.session.state.chapter_progress(2).completed==1,"arrival finishes Act I and starts Act II")
    check(game.obstacles.all(func(o): return o.collision_layer==0),"Oakhaven obstacles do not block Londinium invisibly")
    var before_replay = game.session.state.snapshot()
    game.on_ui_action("replay_journey")
    game.on_ui_action("story_skip")
    check(game.session.mode=="journal" and game.session.state.snapshot()==before_replay,"interlude replay leaves progression unchanged")
    check(game.session.repository.read().flags.get("arrived_londinium",false),"arrival persisted to checkpoint")
    game.on_ui_action("resume")
    game.session.state.flags.erase("memory_completed")
    game.session.state.rewards.clear()
    game.session.state.cat_access = 1
    game.interact()
    check(game.session.mode=="memory" and game.session.state.cat_access==1,"unused Shalem access remains playable after arriving in Act II")
    game.on_ui_action("memory_exit")
    game.session.state.restore(before_replay)
    print("INTEGRATION_TEST_RESULT "+JSON.stringify({"checks":count,"failures":failures,"snapshot":game.diagnostic_snapshot()}))
    game.queue_free()
    await frames(5)
    quit(0 if failures.is_empty() else 1)

func key_event(code: int) -> InputEventKey:
    var event = InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    return event
