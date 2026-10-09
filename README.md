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

## 🚀 Phase 1 Status: Engine Setup & Simulation Logic Port ✅

Phase 1 is complete! The complete simulation core, data-driven scenario pipelines, dynamic formula parsing, and business logic have been ported to GDScript and validated against automated unit tests.

### What Was Built:
1. **Engine & Configuration:**
   - Godot 4 project configured with the **Compatibility renderer (WebGL 2 / OpenGL 3)** for lightweight, friction-free browser deployment.
   - Canvas items stretch mode at 1280×720 viewport resolution.
2. **Data Pipelines:**
   - Native integration with [`data/scenarios.json`](res://data/scenarios.json) and [`data/events.json`](res://data/events.json).
3. **GDScript Simulation Models:**
   - `FormulaEvaluator.gd`: Safely parses math formulas (e.g., `"0.25 * students"`, `"(3.50 * students * 2) - 15"`) using Godot's built-in `Expression` engine.
   - `ClubState.gd`: Complete simulation state, ledger transactions, happiness clamping, formatting templates, and victory/defeat rules.
   - `ScenarioManager.gd`: Season deck generation with randomized non-repeating scenario draws, Week 1 starter scenario lock, and 4-option math challenge distractor generation.
   - `MathChallenge.gd`, `Choice.gd`, `Scenario.gd`, `GameEvent.gd`: Strongly typed data representations.
4. **Automated Test Suite:**
   - Headless test runner in [`tests/test_runner.gd`](res://tests/test_runner.gd) running all 12 core test specifications.

---

## 🧪 Running the Test Suite

You can execute the automated test suite headlessly via the Godot CLI:

```powershell
# Windows
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless -s res://tests/test_runner.gd
```

All 12 test suites will run and report status with zero GUI overhead:
* Initial state validation
* Formula evaluation & context variable injection
* Choice deduction & ledger tracking
* Math challenge bonus & penalty calculations
* Immediate loss triggers (Mutiny, Resignation, Boycott, Bankruptcy)
* Victory and missed-target season endings
* ScenarioManager JSON loading & deck shuffling
* Dynamic template string formatting

---

## 📁 Repository Structure

```
club-budget-the-game-godot/
├── data/
│   ├── scenarios.json            # Dynamic scenario cards & math challenges
│   └── events.json               # Unexpected mid-season events
├── scripts/
│   └── model/
│       ├── formula_evaluator.gd  # Expression-based dynamic formula parser
│       ├── math_challenge.gd     # Math challenge data model
│       ├── choice.gd             # Scenario choice model
│       ├── scenario.gd           # Scenario model
│       ├── game_event.gd         # Random event model
│       ├── club_state.gd         # Core simulation engine & win/loss checks
│       └── scenario_manager.gd   # Season deck manager & JSON loader
├── tests/
│   └── test_runner.gd            # Headless automated unit test runner
├── .gitignore
├── project.godot                 # Godot 4.7 project settings
└── README.md
```

---

## ⏭️ Next Step: Phase 2 (UI Layout & State Flow)
- Build the Godot `Control` node tree for screens:
  - Setup screen (parameters & custom naming)
  - HUD dashboard (Budget, Week, 3 Stakeholder meters)
  - Scenario dialogue & choice buttons
  - Math challenge modal overlay
  - Week summary & Game Over / Victory screens
