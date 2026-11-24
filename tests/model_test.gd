extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func _initialize() -> void:
    var M = load("res://OrbitModel.gd")
    var m = M.new()
    check(m.state == "MENU", "menu initial state")
    m.begin()
    check(m.state == "PLAYING" and m.level == 0 and m.health == 3, "start first stage")
    check(m.toggle(), "toggle accepted")
    check(not m.toggle(), "toggle cooldown")
    m.step(0.19)
    check(m.toggle(), "toggle after cooldown")
    # A single large physics tick must not skip an event angle.
    m.begin()
    m.step(0.36)
    check(m.next_signal == 2, "boundary crossing collects first signal")
    # Incorrect signal order is a mistake, not a collection.
    m.begin()
    m.step(0.16)
    m.toggle()
    m.step(0.70)
    check(m.next_signal == 1 and m.mistakes == 1, "wrong signal costs a mistake")
    # Every authored level must admit a collision-free path, including hazard avoidance.
    for lev in range(3):
        m.start_level(lev)
        var previous := 0.0
        for e in m.events[lev]:
            if m.state != "PLAYING":
                break
            var angle: float = e["angle"]
            var wanted: int = e["lane"] if e["kind"] == "signal" else 1 - int(e["lane"])
            var midpoint := (previous + angle) / 2.0
            var delta := maxf(0.0, midpoint - m.angle)
            m.step(delta / 100.0)
            if m.lane != wanted:
                check(m.toggle(), "solution toggle available level %s angle %s" % [lev, angle])
            m.step(maxf(0.0, angle + 0.1 - m.angle) / 100.0)
            previous = angle
        check(m.health == 3 and m.mistakes == 0 and m.next_signal == 7, "clean solution level %s" % lev)
    check(m.state == "COMPLETE", "three stage completion")
    m.begin()
    m.health = 1
    m.step(0.60)
    check(m.state == "GAME_OVER", "health depletion")
    m.begin()
    m.mistakes = 2
    m.angle = 80.0
    m.lane = 1
    m.step(0.1)
    check(m.state == "GAME_OVER", "third mistake")
    m.begin()
    m.step(7.21)
    check(m.state == "GAME_OVER", "two lap timeout")
    var p := {"highest": 2, "best_mistakes": 1, "mute": true, "contrast": true}
    check(m.save_progress(p), "progress write")
    var loaded: Dictionary = m.load_progress()
    check(int(loaded.get("highest", -1)) == 2 and int(loaded.get("best_mistakes", -1)) == 1 and loaded.get("mute") == true and loaded.get("contrast") == true, "progress roundtrip")
    print("OrbitModel tests: %s failures" % failures)
    quit(1 if failures else 0)
