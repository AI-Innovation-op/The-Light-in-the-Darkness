extends Node
## Original placeholder WAVs. Cue IDs can later point at produced assets.
var muted = false
var ambience_player: AudioStreamPlayer
var sounds: Dictionary = {}

func _ready():
    ambience_player = AudioStreamPlayer.new()
    ambience_player.stream = synthesize("wind",8.0)
    ambience_player.volume_db = -22
    add_child(ambience_player)
    for id in ["evade","parry","block","hit","magic","swing","reward","pickup"]:
        sounds[id] = synthesize(id,0.65 if id=="reward" else 0.22)

func synthesize(id: String,duration: float) -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 16000
    var size = int(duration*stream.mix_rate)
    var bytes = PackedByteArray()
    bytes.resize(size*2)
    var noise = RandomNumberGenerator.new()
    noise.seed = id.hash()
    var low_noise = 0.0
    var frequency = {"parry":880.0,"pickup":620.0,"reward":523.25,"magic":310.0,"hit":95.0,"block":170.0,"swing":200.0,"evade":140.0}.get(id,80.0)
    for i in range(size):
        var t = float(i)/stream.mix_rate
        var envelope = pow(1.0-float(i)/size,2)
        low_noise = lerpf(low_noise,noise.randf_range(-1,1),0.025)
        var value = 0.0
        if id == "wind":
            value = low_noise*(0.4+0.2*sin(t*1.3))
        elif id in ["swing","evade"]:
            value = noise.randf_range(-0.3,0.3)*envelope
        elif id == "reward":
            value = (sin(TAU*frequency*t)+sin(TAU*frequency*1.25*t)+sin(TAU*frequency*1.5*t))*0.13*envelope
        else:
            value = (sin(TAU*(frequency*t-45*t*t))*0.42+low_noise)*envelope
        bytes.encode_s16(i*2,int(clampf(value,-0.95,0.95)*32767))
    stream.data = bytes
    if id == "wind":
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_end = size
    return stream

func set_muted(value: bool):
    muted = value
    ambience_player.volume_db = -80 if muted else -22

func ambience(enabled: bool):
    if DisplayServer.get_name()=="headless":
        return
    if enabled:
        ambience_player.play()
    else:
        ambience_player.stop()

func cue(id: String):
    if muted or DisplayServer.get_name()=="headless" or get_child_count()>=9:
        return
    if not sounds.has(id):
        return
    var player = AudioStreamPlayer.new()
    player.stream = sounds[id]
    player.volume_db = -16
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func _exit_tree():
    for child in get_children():
        if child is AudioStreamPlayer:
            child.stop()
            child.stream = null
    sounds.clear()
