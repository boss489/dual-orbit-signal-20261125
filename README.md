# 이중 궤도 신호원 (A1)

독립적인 Godot 4 Web 게임. 신호 △1→6을 순서대로 수집하고 × 장애를 피하며 세 구역을 통과하세요. 각 구역은 최대 두 바퀴, 체력 3, 실수는 2회까지 허용합니다.

## 실행

- Godot 4.7.2에서 `project.godot`을 열어 F6/F5 실행.
- Web 산출물: `build/index.html` + 같은 폴더의 `index.pck`, `index.wasm` 및 생성된 리소스. 파일을 직접 열지 말고 HTTP 서버로 제공: 이 디렉터리에서 `python3 -m http.server 8877 --directory build` 실행 후 `http://127.0.0.1:8877/` 방문. 브라우저 WebGL 2 지원 필요.
- 재빌드: `godot --headless --editor --path . --quit && godot --headless --path . --export-release Web build/index.html`

## 조작

- Space/Enter: 시작·계속·궤도 전환. 경기장 클릭/탭 또는 아래 큰 버튼도 동일. 전환 후 0.18초 간격.
- Esc: 일시정지/계속. R: 구역 처음부터 다시. 우측 상단 메뉴로 타이틀 복귀.
- 아래 '소리'/'고대비' 설정은 클릭/탭으로 변경. 브라우저 저장소(`user://`)에 최고 통과 구역, 최소 실수 및 설정을 저장합니다. 저장이 차단되어도 현재 게임은 계속됩니다.

## 구현 및 자산

`Main.tscn`/`Main.gd`는 Godot CanvasItem 자체 벡터 화면·상태별 UI·PCM 생성 효과음을, `OrbitModel.gd`는 고정 물리 틱 규칙과 3개 정적 구역 데이터를 담당합니다. `build/index.html`은 Godot Web exporter가 생성한 부트스트랩일 뿐 게임 본체가 아닙니다. 별도 HTML/JS 게임 엔진은 없습니다. 자세한 시각 원칙은 `ART_DIRECTION.md`에 기록했습니다.

글꼴은 Google Fonts **Noto Sans KR**, SIL Open Font License 1.1 (`OFL.txt`). `NotoSansKR.ttf`의 `wght=600` 인스턴스를 fontTools로 `NotoSansKR-Medium.ttf`에 구워 Web에서도 읽기 쉬운 무게를 고정했습니다. 폰트 내부 family 이름은 원본의 `Thin`으로 남지만 실제 윤곽은 600입니다. 화면·음원·코드는 이 프로젝트에서 제작했으며 제3자 그림/사운드는 사용하지 않았습니다.

## 검증

`godot --headless --path . --script res://tests/model_test.gd`, `godot --headless --path . --script res://tests/ui_test.gd`, `python3 check_glyphs.py`. 로컬 Chrome/Playwright 검사 스크립트 `browser-check.js`는 고정된 8877 포트의 Web 빌드를 열고 1280×800/320×700 캡처를 `../../artifacts/a1-screenshots/`에 저장합니다. Playwright 경로는 이 기계의 기존 로컬 패키지를 가리켜 외부 환경에서 조정이 필요할 수 있습니다. 테스트 내역과 범위는 `../../artifacts/a1-development.md` 참조.
