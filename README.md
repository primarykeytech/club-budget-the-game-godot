# Club Budget: The Game (Godot Edition) 🧮🎮

A modernized port of the resource management simulation game built with **Godot 4.7+**, targeting high-resolution 2D presentation and seamless in-browser play on **itch.io**.

---

## 🎯 Project Overview

Players act as treasurer and advisor for an afterschool math club, navigating financial decisions and Common Core 5th-grade math challenges across a multi-week club season while balancing stakeholder morale:
* **Students** (loss trigger if < 40%)
* **Coaches** (loss trigger if < 40%)
* **Parents** (loss trigger if < 40%)
* **Budget** (loss trigger if < $0.00)
* **Goal:** Keep all stakeholders $\ge 80\%$ by the end of the season for a Gold Ribbon finish!

---

## 🚀 Development Status

### Phase 1: Engine Setup & Simulation Logic Port ✅
- Godot 4 project configured with the **Compatibility renderer (WebGL 2 / OpenGL 3)** for friction-free in-browser deployment.
- Responsive 1280×720 widescreen viewport with `canvas_items` stretch mode.
- Complete data pipeline loading [`data/scenarios.json`](res://data/scenarios.json) and [`data/events.json`](res://data/events.json).
- High-precision formula parser (`FormulaEvaluator.gd`) supporting context variables (`students`, `students_x2`, `half_students`) and Python-style division normalization.
- Full simulation model (`ClubState.gd`, `ScenarioManager.gd`, `Choice.gd`, `MathChallenge.gd`, `GameEvent.gd`, `Scenario.gd`).

### Phase 2: UI Layout & State Architecture ✅
- Complete modular Godot UI node hierarchy with rounded modern cards, high contrast typography, and responsive layouts:
  - **Main Game Coordinator** ([`scenes/main.tscn`](res://scenes/main.tscn) & [`game_controller.gd`](res://scripts/ui/game_controller.gd)): Coordinates state transitions, keyboard shortcuts (`1`, `2`, `3`, `Space`, `Enter`), and modal management.
  - **HUD Dashboard** ([`scenes/ui/hud.tscn`](res://scenes/ui/hud.tscn)): Live budget counter, week indicator, dynamic burn-rate allowance, and 3 color-thresholded stakeholder morale progress bars with smooth animated tweens.
  - **Stage View** ([`scenes/ui/stage_view.tscn`](res://scenes/ui/stage_view.tscn)): Classroom chalkboard environment with reactive character cards (Piper the student rep, Coach John, and Parent Ms. Chaidee) with speaking highlights and emotional mood states (Thrilled, Satisfied, Stressed, Crisis).
  - **Scenario Panel** ([`scenes/ui/scenario_panel.tscn`](res://scenes/ui/scenario_panel.tscn)): Narrative description cards and 3 styled action buttons displaying cost, revenue, morale tags, and math badges.
  - **Modals:**
    - [`MathModal`](res://scenes/ui/modals/math_modal.tscn): Interactive multiple-choice challenge modal with instant feedback.
    - [`EventModal`](res://scenes/ui/modals/event_modal.tscn): Mid-season unexpected crisis / grant announcements.
    - [`SummaryModal`](res://scenes/ui/modals/summary_modal.tscn): End-of-week ledger and reaction quote recap.
    - [`EndGameModal`](res://scenes/ui/modals/end_game_modal.tscn): Victory celebration / season failure summary with restart capabilities.
  - **Title & Setup Screens:**
    - [`TitleScreen`](res://scenes/ui/title_screen.tscn): Objective overview and prompt to start.
    - [`SetupScreen`](res://scenes/ui/setup_screen.tscn): Name selection presets, starting budget slider ($100–$1000), student roster slider (4–36), and season length slider (4–30).

### Phase 3: Modern Art & Audio Assets ✅
- **High-Resolution Character Portraits (`assets/images/characters/`):**
  - **Piper (Student Rep):** Illustrated portrait bust with red pi baseball cap, curls, and yellow math club hoodie.
  - **Coach John (Head Coach):** Illustrated portrait bust with dark wavy hair, warm smile, and royal blue coaching polo with math compass emblem.
  - **Ms. Chaidee (Parent):** Illustrated portrait bust with sleek bob, purple cardigan, and warm coffee mug.
- **Classroom Environment Background (`assets/images/backgrounds/`):**
  - Warm sunlit classroom interior with chalk formulas, math diagrams, and banners.
- **Complete Audio System (`scripts/audio/audio_manager.gd`):**
  - Global autoload `AudioManager` with polyphonic sound effect playback and volume control.
  - Dedicated sound effects: `select.wav` (UI tick), `confirm.wav` (button confirm), `cash.wav` (metallic coin clink), `alarm.wav` (danger buzzer), `correct.wav` (rising victory arpeggio), `game_over.wav` (melancholic cadence), `victory.wav` (brass fanfare).
  - Looping background theme music: `theme_music.wav` (playful, cozy 16-bar math club theme).
  - In-game HUD mute button toggle ("🔊" / "🔇") and global keyboard shortcut (`M`).

### Phase 4: Game Polish & Juicing ✅
- **Animated Budget Rolling Counter:** Smooth numerical count-up/count-down interpolations (`Tween.tween_method`) with scale-punch feedback on balance shifts.
- **Floating Transaction Popups:** Dynamic rising badges (`+$45.00` green / `-$28.00` red) spawned in the HUD upon every financial change.
- **Floating Morale Indicators:** Rising morale delta badges (`+5% 😃` / `-8% 😟`) directly over character portrait cards in the classroom stage with card scale bounces.
- **Confetti Particle Cannon (`CPUParticles2D`):** Colorful multi-cannon celebratory confetti burst on correct math challenge solutions and Gold Ribbon season victory.
- **Modal Transitions:** Snappy pop-and-bounce card entrance animations (`TRANS_BACK`, `EASE_OUT`) across all modals.
- **Critical Danger Alerts:** Screen trauma shake on bankruptcy or mutiny/boycott loss events, and pulsing alert warning text on low morale or deficit risks.

---

## 🧪 Automated Testing

Both the model logic and UI state transitions are backed by headless automated test suites runnable via the Godot CLI:

### 1. Simulation Logic Test Suite (12 Tests)
```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless -s res://tests/test_runner.gd
```
* Initial state validation
* Formula evaluation & context variable injection
* Choice deduction & ledger tracking
* Math challenge bonus & penalty calculations
* Immediate loss triggers (Mutiny, Resignation, Boycott, Bankruptcy)
* Victory and missed-target season endings
* ScenarioManager JSON loading & deck shuffling
* Dynamic template string formatting

### 2. UI Flow Integration Test Suite (7 Tests)
```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless res://tests/test_ui.tscn
```
* Main scene instantiation & initial visibility
* Title to Setup screen transition
* Setup to Gameplay transition & parameter injection
* Weekly choice selection, math resolution, and summary modal flow
* Math modal answer evaluation & feedback display
* Game Over modal triggering on immediate loss
* Play Again / Restart flow returning to setup

---

## 📁 Repository Structure

```
club-budget-the-game-godot/
├── assets/
│   ├── audio/
│   │   ├── music/
│   │   │   └── theme_music.wav   # Cozy looping math club theme
│   │   └── sfx/                  # Modern sound effects (select, confirm, cash, etc.)
│   └── images/
│       ├── backgrounds/
│       │   └── classroom_bg.jpg  # Sunlit math club classroom backdrop
│       └── characters/           # Illustrated portraits (Student, Coach, Parent)
├── data/
│   ├── scenarios.json            # Dynamic scenario cards & math challenges
│   └── events.json               # Unexpected mid-season events
├── scenes/
│   ├── main.tscn                 # Primary game viewport & state coordinator
│   └── ui/
│       ├── hud.tscn              # Top bar, budget, mute toggle & morale gauges
│       ├── stage_view.tscn       # Classroom vignette & illustrated character cards
│       ├── scenario_panel.tscn   # Weekly scenario narrative & choice cards
│       ├── title_screen.tscn     # Title screen & rules overview
│       ├── setup_screen.tscn     # Club configuration sliders & presets
│       └── modals/
│           ├── math_modal.tscn   # Multiple-choice math challenge dialog
│           ├── event_modal.tscn  # Random event popup
│           ├── summary_modal.tscn# Weekly ledger recap
│           └── end_game_modal.tscn# Victory / Game Over summary
├── scripts/
│   ├── audio/
│   │   ├── audio_manager.gd      # Global audio autoload singleton
│   │   └── generate_audio.py     # Procedural audio generator script
│   ├── model/                    # Simulation logic & data models
│   └── ui/                       # UI controllers & modal logic
├── tests/
│   ├── test_runner.gd            # Headless model test runner
│   ├── test_ui.tscn              # Headless UI integration test scene
│   └── test_ui_flow.gd           # Headless UI flow integration tests
├── .gitignore
├── project.godot                 # Godot 4.7 project settings
└── README.md
```

---

## ⏭️ Next Step: Phase 4 & Phase 5
- **Phase 4 (Juice & Polish):** Particle effects (confetti / chalk dust), animated budget counters, floating stat deltas (`+$15.00`, `+5% Morale`).
- **Phase 5 (Web Export & itch.io):** Single-threaded WebAssembly export preset configuration, HTML5 shell template, and deployment package for itch.io.
