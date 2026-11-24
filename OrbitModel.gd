extends RefCounted

const SPEED := 100.0
const COOL := 0.18
const SAVE_PATH := "user://dual_orbit_progress.json"

var events: Array = []
var state := "MENU"
var level := 0
var lane := 0
var angle := 0.0
var health := 3
var mistakes := 0
var next_signal := 1
var cooldown := 0.0
var invulnerable := 0.0
var total_mistakes := 0
var last_event := ""

func _init() -> void:
    var signals := [[0, 1, 0, 1, 0, 1], [1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 1, 0]]
    var positions := [[30, 85, 140, 195, 250, 305], [28, 82, 136, 190, 244, 298], [32, 80, 128, 176, 224, 272]]
    var hazards := [[56, 112, 167, 222, 278, 335], [54, 108, 162, 216, 270, 324], [55, 104, 152, 200, 248, 296]]
    for lev in range(3):
        var row := []
        for i in range(6):
            row.append({"kind": "signal", "angle": float(positions[lev][i]), "lane": signals[lev][i], "number": i + 1})
            row.append({"kind": "hazard", "angle": float(hazards[lev][i]), "lane": signals[lev][i], "number": 0})
        events.append(row)

func begin() -> void:
    total_mistakes = 0
    start_level(0)

func start_level(index: int) -> void:
    level = index
    lane = 0
    angle = 0.0
    health = 3
    mistakes = 0
    next_signal = 1
    cooldown = 0.0
    invulnerable = 0.0
    last_event = ""
    state = "PLAYING"

func toggle() -> bool:
    if state != "PLAYING" or cooldown > 0.0:
        return false
    lane = 1 - lane
    cooldown = COOL
    last_event = "switch"
    return true

func step(dt: float) -> void:
    if state != "PLAYING" or dt <= 0.0:
        return
    cooldown = maxf(0.0, cooldown - dt)
    invulnerable = maxf(0.0, invulnerable - dt)
    var previous := angle
    angle += dt * SPEED
    for lap in range(2):
        for event in events[level]:
            var crossing: float = event["angle"] + 360.0 * lap
            if crossing > previous and crossing <= angle:
                if event["kind"] == "signal" and int(event["lane"]) == lane:
                    if int(event["number"]) == next_signal:
                        next_signal += 1
                        last_event = "collect"
                        if next_signal == 7:
                            state = "LEVEL_CLEAR" if level < 2 else "COMPLETE"
                            return
                    else:
                        mistakes += 1
                        total_mistakes += 1
                        last_event = "mistake"
                elif event["kind"] == "hazard" and int(event["lane"]) == lane and invulnerable <= 0.0:
                    health -= 1
                    invulnerable = 0.7
                    last_event = "damage"
                if health <= 0 or mistakes >= 3:
                    state = "GAME_OVER"
                    return
    if angle >= 720.0:
        state = "GAME_OVER"
        last_event = "timeout"

func advance() -> void:
    if state == "LEVEL_CLEAR" and level < 2:
        start_level(level + 1)

func save_progress(data: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    return file.get_error() == OK

func load_progress() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {"highest": 0, "best_mistakes": -1, "mute": false, "contrast": false}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {"highest": 0, "best_mistakes": -1, "mute": false, "contrast": false}
    var value: Variant = JSON.parse_string(file.get_as_text())
    if value is Dictionary and value.has("highest") and value.has("best_mistakes") and value.has("mute") and value.has("contrast"):
        return value
    return {"highest": 0, "best_mistakes": -1, "mute": false, "contrast": false}
