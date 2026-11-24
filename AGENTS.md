# Sky Strike (`skystrike`) — Project Context & Agent Guide

This document preserves the full design context, requirements, and technical architecture of **Sky Strike** so future sessions can resume seamlessly.

## 1. Core Concept & Player Requirements

- **Target Player**: Designed for a 6-year-old to play effortlessly with the mouse (plus keyboard shortcuts).
- **Hero Aircraft**: Realistic **B-2 Spirit Stealth Bomber** flying-wing silhouette with sawtooth "W" trailing edge, straight swept leading edges, radar-absorbent slate/gunmetal paneling, 4-pane wrap-around metallic cockpit windscreens, serrated dorsal S-duct engine intakes, twin concealed exhaust vents, and glowing internal bomb bay doors.
- **Ordnance & Combat**:
  - **Left Click / `Space`**: Fires a **Big Heavy Cruise Missile** forward (with swept mid-wings, yellow warhead stripe, and roaring afterburner smoke trail) AND drops a **Heavy Gravity Bomb** downward from the internal bomb bay.
  - **Right Click / `B`**: Drops a 4-bomb **Carpet Bombing Salvo** (`BOMBS AWAY!`).
  - **Dramatic Impact FX**: Multi-stage explosions with white-hot core flash, expanding supersonic shockwave rings, rolling fireballs transitioning into dark war smoke, towering water splash geysers, and camera screen shake.
- **Wartime Seascape & Enemy Fleet**:
  - Stormy wartime ocean below with multi-layered rolling waves, whitecaps, distant horizon artillery glow, and sweeping naval searchlights.
  - **Enemy Warships**: Destroyers, guided-missile cruisers, and aircraft carriers steaming across the sea. Bomb hits ignite deck fires and black smoke until magazine detonation sinks the ship.
- **3-Level Campaign, Distinct Visual Theaters & Multi-Phase Boss Aeroplanes**:
  - **Level 1 — Coral Sea Sunset Archipelago / Iron Vulture Bomber (`380 HP`)**: Golden-crimson sunset sky, setting sun, tropical volcanic island silhouettes, and turquoise sea swells. Enters **Phase 2 Enraged Overdrive** at 50% HP.
    - *Player Capability (Tier 1)*: `1` Heavy Cruise Missile + Nose Rotary Gatling Cannon (auto-fires + fires on trigger) + `1` Gravity Bomb + `4`-Bomb Carpet Salvo.
  - **Level 2 — Arctic Aurora Glacier Strait / Storm Valkyrie Gunship (`720 HP`)**: Polar midnight sky with animated emerald/cyan Aurora Borealis ribbons and jagged icebergs/glaciers. Fires 3-way cannon spreads and activates a Phase 2 tactical shield below 50% HP.
    - *Player Capability (Tier 2)*: **Twin Supersonic Homing Cruise Missiles** + **Twin Wing-Mounted Cyan Rotary Autocannons** + **Dual Cluster Bombs** + `6`-Bomb Carpet Salvo + Wingtip Hardpoint Pods.
  - **Level 3 — Volcanic Lightning Red Sea / Sky Titan Dreadnought (`1150 HP`)**: Obsidian storm sky, twin erupting volcanoes with glowing lava streams, periodic lightning bolts, and crimson sea swells. Commands a pulsing energy shield dome, 5-way plasma spreads, and Phase 2 Enraged Overdrive.
    - *Player Capability (Tier 3)*: **Triple Homing Cruise Missiles** + **Nose Plasma Laser Beam** + **Twin Autonomous Stealth Wingman Drones** (flying in formation and firing violet plasma bolts) + `3` Heavy Mega Bombs + `8`-Bomb Mega Carpet Salvo.
  - Defeating each Boss Aeroplane advances the player to the next level and unlocks the next weapon tier; defeating Level 3's Sky Titan Dreadnought triggers the Campaign Victory screen (while preserving future extensibility to 10 levels).
  - Keys `1`, `2`, `3` allow jumping directly to any of the 3 levels.
- **Kid-Friendly Flow**: Colliding with enemy planes or boss plasma shots triggers a brief energy shield (`SHIELD DEFLECT!`) and knocks enemy planes out without a punishing Game Over screen.

## 2. Architecture (`omarchy-app` conventions)

- `skystrike.pro`: Qt 6 (`qmake6`) project (`core gui qml quick quickcontrols2 dbus`).
- `src/main.cpp`:
  - Sets `QCoreApplication::setApplicationName("skystrike")` and `QGuiApplication::setDesktopFileName("skystrike")` **before** constructing `QGuiApplication` and suppresses `qt.qpa.services.warning` to avoid duplicate xdg-desktop-portal registration errors.
  - Supports headless CLI commands (`skystrike status --json`, `skystrike skill install`) and GUI launch (`skystrike` or `skystrike open`).
- `src/backend.{h,cpp}`: Tracks `score`, `highScore` (persisted atomically to `~/.config/omarchy/skystrike.json`), `rescues`, `planesDestroyed`, `shipsDestroyed`, `mothershipsDefeated`, `wave`, `paused`, and `statusMessage`.
- `src/theme.{h,cpp}`: Live watcher for Omarchy's active theme accent (`~/.local/state/omarchy/current/theme/colors.toml`) and Hyprland corner rounding (`hyprctl -j getoption decoration:rounding`).
- `src/translator.{h,cpp}` & `src/i18n/{en,da}.json`: Live watcher for `~/.config/omarchy/language` with CLDR plural rules.
- `src/Main.qml`: Single-window Qt Quick UI with a 60 FPS `Timer` loop and hardware-accelerated 2D `Canvas` renderer.
- `tests/skystrike_tests.{pro,cpp}`: Offscreen Qt Test suite verifying backend scoring, naval/air counters, wave progression, theme watching, and live translations.
- `pkgbuild/`: Arch Linux `PKGBUILD`, `skystrike.desktop`, and `skystrike.svg` icon.

## 3. Development Workflow

```sh
bin/build    # Compile binary into build/skystrike
bin/test     # Build and run offscreen unit tests in build/tests/skystrike_tests
bin/install  # Install binary to ~/.local/bin, desktop entry & icon to ~/.local/share, and build Arch package
```
