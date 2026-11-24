extends SceneTree

var failures := 0

func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error(why)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene: Variant = load("res://Main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    check(scene.screen == "MENU", "title")
    scene._primary()
    check(scene.screen == "TUTORIAL", "tutorial")
    scene._primary()
    check(scene.screen == "PLAYING" and scene.model.state == "PLAYING", "start")
    var original: int = scene.model.lane
    scene._switch_lane()
    check(scene.model.lane != original, "lane switch")
    scene.screen = "PAUSED"
    var old_angle: float = scene.model.angle
    scene._physics_process(0.5)
    check(scene.model.angle == old_angle, "paused simulation")
    scene._primary()
    check(scene.screen == "PLAYING", "resume")
    scene.model.start_level(0)
    scene.model.angle = 719.5
    scene.model.next_signal = 1
    scene._physics_process(0.01)
    check(scene.screen == "GAME_OVER", "game over screen")
    scene._primary()
    check(scene.screen == "PLAYING" and scene.model.level == 0, "retry")
    for lev in range(3):
        scene.model.start_level(lev)
        scene.screen = "PLAYING"
        scene.model.next_signal = 6
        scene.model.lane = int(scene.model.events[lev][10]["lane"])
        scene.model.angle = float(scene.model.events[lev][10]["angle"]) - 0.5
        scene._physics_process(0.01)
        check(scene.screen == ("COMPLETE" if lev == 2 else "LEVEL_CLEAR"), "level complete %d" % lev)
        if lev < 2:
            scene._primary()
            check(scene.model.level == lev + 1 and scene.screen == "PLAYING", "advance %d" % lev)
    check(int(scene.progress["highest"]) == 3, "progress save")
    check(int(scene.progress["best_mistakes"]) >= 0, "best save")
    print("UI state tests: %d failures" % failures)
    scene.queue_free()
    quit(1 if failures else 0)
