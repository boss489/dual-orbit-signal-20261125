extends Node2D

const FONT = preload("res://NotoSansKR-Medium.ttf")
const MODEL = preload("res://OrbitModel.gd")
const INK := Color("071924")
const SEA := Color("123747")
const BRASS := Color("d6a760")
const PAPER := Color("f3e7cb")
const MINT := Color("75dec4")
const CORAL := Color("f1846d")

var model = MODEL.new()
var progress: Dictionary
var screen := "MENU"
var elapsed := 0.0
var pulse := 0.0
var message := ""
var audio_ready := false
var voice: AudioStreamPlayer


var last_event := ""

func _ready() -> void:
    progress = model.load_progress()

    voice = AudioStreamPlayer.new()
    voice.volume_db = -12.0
    add_child(voice)
    get_viewport().size_changed.connect(queue_redraw)

func _physics_process(delta: float) -> void:
    if screen == "PLAYING":
        model.step(delta)
        if model.last_event != "" and model.last_event != last_event:
            last_event = model.last_event
            match last_event:
                "collect": _tone(660, 0.11)
                "damage", "mistake": _tone(155, 0.22)
        if model.last_event == "":
            last_event = ""
        if model.state != "PLAYING":
            screen = model.state
            if screen == "LEVEL_CLEAR" or screen == "COMPLETE":
                progress["highest"] = maxi(int(progress["highest"]), model.level + 1)
                if screen == "COMPLETE":
                    var best := int(progress["best_mistakes"])
                    progress["best_mistakes"] = model.total_mistakes if best < 0 else mini(best, model.total_mistakes)
                if not model.save_progress(progress):
                    message = "기록 저장 불가 · 이번 플레이는 계속됩니다"
                _tone(880, 0.34)
            else:
                _tone(130, 0.3)
    elapsed += delta
    pulse = maxf(0.0, pulse - delta)
    queue_redraw()

func _tone(freq: float, duration: float) -> void:
    if audio_ready and not bool(progress["mute"]):
        var count := int(duration * 22050.0)
        var pcm := PackedByteArray()
        pcm.resize(count * 2)
        for i in range(count):
            var t := float(i) / 22050.0
            var env := minf(1.0, t * 70.0) * minf(1.0, (duration - t) * 22.0)
            var wave := sin(TAU * freq * t) + 0.18 * sin(TAU * freq * 2.0 * t)
            var sample := int(clampf(wave * env * 9000.0, -32768.0, 32767.0))
            pcm[i * 2] = sample & 255
            pcm[i * 2 + 1] = (sample >> 8) & 255
        var wav := AudioStreamWAV.new()
        wav.format = AudioStreamWAV.FORMAT_16_BITS
        wav.mix_rate = 22050
        wav.stereo = false
        wav.data = pcm
        voice.stop()
        voice.stream = wav
        voice.play()

func _wake_audio() -> void:
    audio_ready = true

func _layout() -> Dictionary:
    var size := get_viewport_rect().size
    var w := size.x
    var h := size.y
    var arena := minf(minf(w - 20.0, h - 300.0), 650.0)
    var center := Vector2(w / 2.0, maxf(280.0, h * 0.48))
    if center.y + arena * 0.48 > h - 192.0:
        center.y = h - 192.0 - arena * 0.48
    return {"w": w, "h": h, "center": center, "arena": arena,
        "button": Rect2(w * 0.08, h - 133, w * 0.84, 82),
        "top": Rect2(w - 88, 20, 70, 56),
        "mute": Rect2(24, h - 43, 120, 32),
        "contrast": Rect2(w - 145, h - 43, 120, 32)}

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        _wake_audio()
        match event.keycode:
            KEY_ESCAPE:
                if screen == "PLAYING": screen = "PAUSED"
                elif screen == "PAUSED": screen = "PLAYING"
                else: screen = "MENU"
            KEY_R:
                if screen != "MENU": _restart()
            KEY_SPACE, KEY_ENTER:
                _primary()
        queue_redraw()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _click(event.position)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and event.pressed:
        _click(event.position)
        get_viewport().set_input_as_handled()

func _click(pos: Vector2) -> void:
    _wake_audio()
    var l := _layout()
    if l["mute"].has_point(pos):
        progress["mute"] = not progress["mute"]
        _save_options()
    elif l["contrast"].has_point(pos):
        progress["contrast"] = not progress["contrast"]
        _save_options()
    elif l["top"].has_point(pos):
        if screen == "PLAYING": screen = "PAUSED"
        elif screen == "PAUSED": screen = "PLAYING"
        else: screen = "MENU"
    elif l["button"].has_point(pos):
        _primary()
    elif screen == "PLAYING":
        _switch_lane()
    queue_redraw()

func _save_options() -> void:
    if not model.save_progress(progress):
        message = "설정 저장 불가 · 이번 세션에는 적용됩니다"

func _primary() -> void:
    match screen:
        "MENU": screen = "TUTORIAL"
        "TUTORIAL": _restart()
        "PLAYING": _switch_lane()
        "PAUSED": screen = "PLAYING"
        "LEVEL_CLEAR":
            model.advance()
            screen = model.state
            last_event = ""
        "GAME_OVER", "COMPLETE": _restart()

func _restart() -> void:
    model.begin()
    screen = "PLAYING"
    message = ""
    last_event = ""
    _tone(540, 0.1)

func _switch_lane() -> void:
    if model.toggle():
        pulse = 0.32
        _tone(360, 0.09)

func _col(base: Color) -> Color:
    if not bool(progress["contrast"]):
        return base
    if base == INK: return Color.BLACK
    if base == SEA: return Color("15222b")
    if base == PAPER: return Color.WHITE
    if base == BRASS: return Color("ffe588")
    if base == MINT: return Color("94fff2")
    if base == CORAL: return Color("ff8869")
    return base

func _text(pos: Vector2, text: String, size: int = 16, color: Color = PAPER, centered: bool = false) -> void:
    if centered:
        pos.x -= FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
    draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT,
        -1, size, _col(color), TextServer.JUSTIFICATION_NONE, TextServer.DIRECTION_AUTO,
        TextServer.ORIENTATION_HORIZONTAL, 0)

func _pill(rect: Rect2, color: Color, border: Color) -> void:
    var radius := minf(rect.size.y * 0.5, 24.0)
    var vertices := PackedVector2Array()
    var corners := [Vector2(rect.end.x - radius, rect.position.y + radius),
        Vector2(rect.end.x - radius, rect.end.y - radius),
        Vector2(rect.position.x + radius, rect.end.y - radius),
        Vector2(rect.position.x + radius, rect.position.y + radius)]
    for k in range(4):
        for j in range(9):
            var angle := -PI / 2.0 + k * PI / 2.0 + float(j) * PI / 16.0
            vertices.append(corners[k] + Vector2(cos(angle), sin(angle)) * radius)
    draw_colored_polygon(vertices, color)
    vertices.append(vertices[0])
    draw_polyline(vertices, border, 1.5, true)

func _draw() -> void:
    var l := _layout()
    var w: float = l["w"]
    var h: float = l["h"]
    var center: Vector2 = l["center"]
    var a: float = l["arena"]
    draw_rect(Rect2(0, 0, w, h), _col(INK))
    _background(w, h)
    _text(Vector2(22, 36), "NORTH PIER  /  SIGNAL ATLAS", 11, BRASS)
    _text(Vector2(22, 67), "이중 궤도 신호원", 23, PAPER)
    draw_line(Vector2(22, 83), Vector2(w - 22, 83), _col(BRASS).darkened(0.48), 1)
    _arena(center, a)
    _hud(l)
    if screen != "PLAYING":
        _overlay(l)
    _controls(l)
    if message != "": _text(Vector2(w * 0.5, h - 154), message, 11, CORAL, true)

func _background(w: float, h: float) -> void:
    for i in range(37):
        var x := fposmod(float(i * 173 + 17), w)
        var y := fposmod(float(i * 97 + 121), h - 120.0)
        var alpha := 0.18 + 0.13 * sin(elapsed + i)
        draw_circle(Vector2(x, y), 1.0 + float(i % 3) * 0.4, Color(BRASS, alpha))
    for i in range(7):
        var yy := h * 0.22 + float(i) * (h * 0.08)
        draw_line(Vector2(0, yy), Vector2(w, yy), Color(0.29, 0.48, 0.53, 0.07), 1)
    draw_line(Vector2(w * 0.5, 112), Vector2(w * 0.5, h - 160), Color(BRASS, 0.12), 1)
    for j in range(3):
        var yy := h - 184.0 + j * 18.0
        draw_arc(Vector2(w * 0.5, yy), w * (0.65 + j * 0.16), PI * 1.13, PI * 1.87, 30, Color(MINT, 0.08), 2)

func _arena(c: Vector2, a: float) -> void:
    var inner := a * 0.275
    var outer := a * 0.395
    draw_circle(c, outer + 28.0, Color(SEA, 0.72))
    draw_arc(c, outer + 23.0, 0, TAU, 120, _col(BRASS).darkened(0.55), 1)
    for k in range(72):
        var theta := deg_to_rad(float(k) * 5.0 - 90.0)
        var length := 10.0 if k % 6 == 0 else 4.0
        var dir := Vector2(cos(theta), sin(theta))
        draw_line(c + dir * (outer + 13.0 - length), c + dir * (outer + 13.0), Color(BRASS, 0.65 if k % 6 == 0 else 0.28), 1.2)
    for radius in [inner, outer]:
        draw_arc(c, radius + 5.0, 0, TAU, 120, Color(BRASS, 0.21), 9)
        draw_arc(c, radius, 0, TAU, 120, _col(BRASS), 2.2)
        draw_arc(c, radius - 5.0, 0, TAU, 120, Color(BRASS, 0.17), 1)
    draw_circle(c, 28.0, _col(INK))
    draw_arc(c, 26, 0, TAU, 60, _col(BRASS), 1)
    var compass := Vector2(cos(elapsed * 0.12), sin(elapsed * 0.12))
    draw_colored_polygon(PackedVector2Array([c + compass * 20, c + compass.rotated(2.3) * 7, c + compass.rotated(-2.3) * 7]), _col(BRASS))
    draw_colored_polygon(PackedVector2Array([c - compass * 18, c - compass.rotated(2.3) * 6, c - compass.rotated(-2.3) * 6]), _col(MINT))
    draw_circle(c, 3, _col(PAPER))
    var lev: int = model.level if screen not in ["MENU", "TUTORIAL"] else 0
    for e in model.events[lev]:
        var radius: float = inner if e["lane"] == 0 else outer
        var rad := deg_to_rad(float(e["angle"]) - 90.0)
        var p := c + Vector2(cos(rad), sin(rad)) * radius
        if e["kind"] == "signal": _signal(p, int(e["number"]), a)
        else: _hazard(p, a)
    var rad := deg_to_rad(model.angle - 90.0 if screen not in ["MENU", "TUTORIAL"] else elapsed * 15.0 - 90.0)
    var rr := inner if model.lane == 0 else outer
    var dir := Vector2(cos(rad), sin(rad))
    var p := c + dir * rr
    for i in range(4, 0, -1):
        draw_circle(p - dir.rotated(PI / 2.0) * float(i) * 6.0, 3.0 + i, Color(MINT, 0.09 * (5 - i)))
    draw_circle(p, 11 + 2 * sin(elapsed * 7), Color(MINT, 0.13))
    draw_colored_polygon(PackedVector2Array([p + dir.rotated(PI / 2.0) * 13, p - dir * 8 + dir.rotated(PI / 2.0) * -7, p + dir * 8 + dir.rotated(PI / 2.0) * -7]), _col(PAPER))
    draw_circle(p, 2.5, _col(MINT))
    if pulse > 0 and not bool(progress["contrast"]):
        draw_arc(p, 13 + (0.32 - pulse) * 70.0, 0, TAU, 40, Color(MINT, pulse), 2)

func _signal(p: Vector2, n: int, a: float) -> void:
    var active: bool = n == model.next_signal
    var r := maxf(14.0, a * 0.048)
    var col := _col(MINT) if active else Color(0.40, 0.60, 0.59, 0.7)
    if active:
        draw_circle(p, r + 5.0 + sin(elapsed * 5.0) * 2.0, Color(MINT, 0.13))
    draw_circle(p, r, _col(INK))
    draw_arc(p, r, 0, TAU, 32, col, 2.4)
    for i in range(3):
        var theta := TAU * i / 3.0 - PI / 2.0
        draw_line(p + Vector2(cos(theta), sin(theta)) * (r + 3), p + Vector2(cos(theta), sin(theta)) * (r + 7), col, 1.5)
    _text(p + Vector2(0, 5.3), str(n), 14, col, true)

func _hazard(p: Vector2, a: float) -> void:
    var r := maxf(12.0, a * 0.038)
    var red := _col(CORAL)
    draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), _col(INK))
    for i in range(-1, 2):
        draw_line(p + Vector2(i * 5 - 4, -6), p + Vector2(i * 5 + 4, 6), Color(CORAL, 0.65), 1)
    draw_line(p + Vector2(-r, 0), p + Vector2(0, -r), red, 2)
    draw_line(p + Vector2(0, -r), p + Vector2(r, 0), red, 2)
    draw_line(p + Vector2(r, 0), p + Vector2(0, r), red, 2)
    draw_line(p + Vector2(0, r), p + Vector2(-r, 0), red, 2)

func _hud(l: Dictionary) -> void:
    var w: float = l["w"]
    var c: Vector2 = l["center"]
    var a: float = l["arena"]
    var top_y := 97.0
    if w < 420:
        _text(Vector2(22, top_y + 16), "구역 %d / 3" % (model.level + 1), 14, BRASS)
        _text(Vector2(w - 88, top_y + 16), "♥ %d   실수 %d/3" % [model.health, model.mistakes], 13, PAPER, true)
        _text(Vector2(w / 2, top_y + 45), "다음 △ %d  ·  %s 궤도" % [model.next_signal, "안쪽" if _target_lane() == 0 else "바깥쪽"], 17, MINT, true)
    else:
        _text(Vector2(w / 2, top_y + 18), "구역 %d / 3    ·    다음 △ %d — %s 궤도" % [model.level + 1, model.next_signal, "안쪽" if _target_lane() == 0 else "바깥쪽"], 17, MINT, true)
        _text(Vector2(w / 2, top_y + 48), "체력 ♥ %d / 3     실수 %d / 3" % [model.health, model.mistakes], 13, PAPER, true)
    var fy := c.y + a * 0.48 + 17
    _text(Vector2(w / 2, fy), "현재 %s  •  남은 궤도 %.1f 바퀴" % ["안쪽" if model.lane == 0 else "바깥쪽", maxf(0, (720.0 - model.angle) / 360.0)], 13, PAPER, true)
    draw_line(Vector2(w * 0.13, fy + 14), Vector2(w * 0.87, fy + 14), Color(BRASS, 0.35), 3)
    draw_line(Vector2(w * 0.13, fy + 14), Vector2(w * (0.13 + 0.74 * minf(model.angle / 720.0, 1.0)), fy + 14), _col(MINT), 3)

func _target_lane() -> int:
    if model.next_signal > 6: return model.lane
    for e in model.events[model.level]:
        if e["kind"] == "signal" and e["number"] == model.next_signal:
            return e["lane"]
    return 0

func _overlay(l: Dictionary) -> void:
    var w: float = l["w"]
    var h: float = l["h"]
    var box := Rect2(maxf(12, w / 2 - 170), maxf(178, h * 0.38 - 42), minf(w - 24, 340), 214)
    _pill(box, Color(INK, 0.96), _col(BRASS))
    var title := ""
    var lines := ["", "", ""]
    match screen:
        "MENU":
            title = "항구의 별을 잇다"
            lines = ["안팎 두 궤도를 달리며", "△ 1부터 6까지 순서대로 수집", "3개 구역 · 각 2바퀴의 항해"]
        "TUTORIAL":
            title = "항해 안내"
            lines = ["Space / Enter / 탭: 궤도 전환", "△ 숫자 순서대로 · × 위험은 피하기", "체력 3 · 실수 3회면 실패"]
        "PAUSED":
            title = "잠시 정박"
            lines = ["시간과 신호가 멈췄습니다", "Esc: 계속   R: 처음부터", "아래에서 소리·대비 설정 가능"]
        "LEVEL_CLEAR":
            title = "구역 %d 신호 연결" % (model.level + 1)
            lines = ["다음 항로가 열렸습니다", "체력과 실수는 구역마다 재설정", "누적 실수 %d" % model.total_mistakes]
        "GAME_OVER":
            title = "신호가 끊겼습니다"
            lines = ["체력 %d · 실수 %d" % [model.health, model.mistakes], "같은 항로를 다시 항해하세요", "R: 즉시 다시 시작"]
        "COMPLETE":
            title = "항구의 밤이 밝혀졌다"
            lines = ["세 구역의 신호를 모두 연결", "누적 실수 %d · 최고 기록 %d" % [model.total_mistakes, int(progress["best_mistakes"])], "모든 항로를 다시 달릴 수 있습니다"]
    _text(Vector2(w / 2, box.position.y + 44), title, 21, BRASS, true)
    draw_line(Vector2(box.position.x + 34, box.position.y + 60), Vector2(box.end.x - 34, box.position.y + 60), Color(BRASS, 0.5), 1)
    for i in range(3):
        _text(Vector2(w / 2, box.position.y + 93 + i * 32), lines[i], 13, PAPER if i != 1 else MINT, true)

func _controls(l: Dictionary) -> void:
    var w: float = l["w"]
    var h: float = l["h"]
    var button: Rect2 = l["button"]
    var button_text := ""
    match screen:
        "MENU": button_text = "항해 시작  ›"
        "TUTORIAL": button_text = "출항하기  ›"
        "PLAYING": button_text = "◎  링 바꾸기  ◎"
        "PAUSED": button_text = "계속 항해  ›"
        "LEVEL_CLEAR": button_text = "다음 구역  ›"
        "GAME_OVER", "COMPLETE": button_text = "처음부터 다시"
    _pill(button, _col(BRASS) if screen != "PLAYING" else _col(SEA), _col(PAPER))
    _text(Vector2(w / 2, button.position.y + 51), button_text, 22, INK if screen != "PLAYING" else PAPER, true)
    _text(Vector2(w / 2, button.position.y - 15), "화면 탭도 전환 · 0.18초 간격" if screen == "PLAYING" else "SPACE / ENTER 또는 터치", 11, BRASS, true)
    _pill(l["top"], _col(SEA), _col(BRASS))
    _text(Vector2(w - 53, 56), "Ⅱ" if screen == "PLAYING" else "메뉴", 15, PAPER, true)
    _text(Vector2(24, h - 22), "소리: %s" % ("끔" if progress["mute"] else "켬"), 12, BRASS)
    _text(Vector2(w - 137, h - 22), "고대비: %s" % ("켬" if progress["contrast"] else "끔"), 12, BRASS)
