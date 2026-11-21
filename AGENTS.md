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
- **Airborne Mothership, Small Planes & Paratroopers**:
  - A giant airborne carrier/mothership patrols the upper sky, opening its hangar bay doors to launch agile red fighter planes.
  - Paratrooper soldiers jump out with colorful parachutes and drift toward the sea; flying the B-2 Spirit near them rescues them for `+500` star bonus points.
- **Kid-Friendly Flow**: Colliding with enemy planes triggers a brief energy shield and knocks the enemy plane out without a punishing Game Over screen.

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
