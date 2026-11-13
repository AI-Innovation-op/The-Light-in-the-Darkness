extends SceneTree
const Hero = preload("res://src/domain/combat/hero_state.gd")
const Campaign = preload("res://src/domain/progression/campaign.gd")
const Memory = preload("res://src/domain/activities/memory_board.gd")
const Repository = preload("res://src/infrastructure/persistence/local_save_repository.gd")
const Session = preload("res://src/application/adventure_session.gd")
const Progress = preload("res://src/domain/story/chapter_progress.gd")
const Sequence = preload("res://src/domain/story/narrative_sequence.gd")
const Story = preload("res://src/application/story_director.gd")
var failures: Array = []
var count = 0

func check(condition: bool,label: String):
    count += 1
    if not condition:
        failures.append(label)

class FakeRepository:
    extends RefCounted
    var data = null
    func write(snapshot):
        data = snapshot.duplicate(true)
        return true
    func read():
        return data

class FailingRepository:
    extends RefCounted
    func write(_snapshot):
        return false
    func read():
        return null

func _initialize():
    var hero = Hero.new()
    hero.configure("Thomas")
    check(hero.receive_hit(23,true,false,0,true)=="evaded" and hero.health==80,"dodge prevents damage and disarm")
    check(hero.receive_hit(23,true,true,0.1,false)=="parried" and hero.armed,"precise guard parries")
    check(hero.receive_hit(23,true,true,0.5,false)=="blocked" and hero.guard==35,"heavy strike consumes guard")
    check(hero.receive_hit(23,true,true,0.5,false)=="guard_broken" and not hero.armed and hero.health<80,"second heavy breaks guard and disarms")
    hero.configure("Thomas")
    hero.receive_hit(1000,true,false,0,false)
    check(hero.health==0,"health cannot become negative")
    var witch = Hero.new()
    witch.configure("Khaterine")
    check(witch.max_health>80 and witch.speed<170,"character tradeoffs")
    var board = Memory.new(["ash","moon","ash","moon"])
    check(board.select_card(0)=="revealed" and board.select_card(0)=="ignored","same card cannot pair itself")
    check(board.select_card(1)=="mismatch" and board.select_card(2)=="ignored","third input locked during mismatch")
    board.hide_mismatch()
    board.select_card(0)
    check(board.select_card(2)=="match" and board.select_card(0)=="ignored","matched card cannot repeat")
    board.select_card(1)
    check(board.select_card(3)=="complete","all pairs finish")
    check(board.select_card(-1)=="ignored" and board.select_card(20)=="ignored","invalid indexes safe")
    var campaign = Campaign.new()
    check(not campaign.claim_memory(),"activity needs access")
    campaign.award_xp(100)
    check(campaign.cat_access==1 and campaign.xp==0,"XP creates access")
    check(campaign.claim_memory() and not campaign.claim_memory() and campaign.rewards.size()==1 and campaign.cat_access==0,"reward is idempotent")
    campaign.award_xp(900)
    check(campaign.cat_access==3,"access cap")
    check(not campaign.restore(null) and not campaign.restore({"version":99}),"unknown save rejected")
    var fake = FakeRepository.new()
    var session = Session.new(fake)
    session.start("Khaterine")
    session.finish_encounter()
    session.finish_encounter()
    check(session.state.cat_access==1,"checkpoint cannot farm encounter reward")
    var restored = Session.new(fake)
    check(restored.load_checkpoint() and restored.state.chosen=="Khaterine" and restored.state.cat_access==1,"application restores checkpoint via injected port")
    var failing = Session.new(FailingRepository.new())
    failing.state.award_xp(100)
    check(not failing.claim_activity() and failing.state.cat_access==1 and failing.state.rewards.is_empty(),"failed save rolls back reward and preserves access")
    var flow = Story.new(session)
    var pages = [{"body":"one"},{"body":"two"}]
    check(not flow.begin("act1_to_act2",pages),"cannot depart before main story prerequisites")
    check(flow.begin("opening",pages) and not flow.commit(),"intro cannot commit until finished")
    check(not flow.sequence.advance() and flow.sequence.current_page().body=="two","sequence advances in order")
    flow.sequence.skip()
    check(flow.commit() and session.state.current_chapter()==1,"skipping intro does not unlock a chapter")
    session.state.flags["met_elowen"] = true
    session.state.flags["morwenna_defeated"] = true
    check(session.state.can_depart() and session.state.cat_access==1,"optional Shalem activity is not a departure gate")
    check(session.state.chapter_progress(1).completed==3 and not session.state.chapter_progress(1).finished,"story stays incomplete until departure resolves")
    flow.begin("act1_to_act2",pages)
    flow.sequence.skip()
    check(flow.commit() and session.state.current_chapter()==2 and session.state.chapter_progress(1).finished,"skip commits the same chapter arrival")
    check(session.state.chapter_progress(2).completed==1,"Act II starts with arrival milestone")
    var failure_story = Story.new(failing)
    failing.state.flags = {"met_elowen":true,"encounter_cleared":true,"morwenna_defeated":true}
    failure_story.begin("act1_to_act2",pages)
    failure_story.sequence.skip()
    check(not failure_story.commit() and failing.state.current_chapter()==1,"failed arrival save rolls back chapter")
    var false_victory = {"arrived_londinium":true,"elowen_found":true,"prophecy_rebuilt":true,"malphas_phase2_won":true}
    check(not Progress.measure(false_victory,2).finished,"Malphas false victory does not finish Act II")
    false_victory["malphas_escape"] = true
    check(Progress.measure(false_victory,2).finished,"escape resolves Act II milestone")
    var empty_sequence = Sequence.new()
    check(not empty_sequence.begin("missing",[]) and empty_sequence.current_page().is_empty(),"empty sequence is rejected")
    var repo = Repository.new()
    repo.path = "user://automated_test_save.json"
    check(repo.write(campaign.snapshot()),"filesystem save")
    var second = Campaign.new()
    check(second.restore(repo.read()) and second.rewards==campaign.rewards,"filesystem round trip")
    check(repo.write(campaign.snapshot()),"replace existing checkpoint")
    FileAccess.open(repo.path,FileAccess.WRITE).store_string("broken")
    check(second.restore(repo.read()),"backup recovers corrupt checkpoint")
    for suffix in ["",".tmp",".bak"]:
        if FileAccess.file_exists(repo.path+suffix):
            DirAccess.remove_absolute(repo.path+suffix)
    print("DOMAIN_TEST_RESULT "+JSON.stringify({"checks":count,"failures":failures}))
    quit(0 if failures.is_empty() else 1)
