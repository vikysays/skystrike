# Sky Strike

B-2 Spirit stealth bomber air and naval combat game for Omarchy, designed for effortless mouse control and explosive arcade action.

![Sky Strike screenshot](screenshot.png)

## Features

- **B-2 Spirit Stealth Bomber**: Fly the iconic flying-wing stealth bomber with sawtooth trailing edge, flush cockpit windows, and internal bomb bay doors.
- **Big Cruise Missiles & Dramatic Impact**: Launch heavy cruise missiles with roaring afterburner plumes, supersonic shockwave rings, multi-stage fireballs, dark smoke clouds, and screen shake.
- **3 Distinct Combat Theaters & Multi-Phase Boss Aeroplanes**:
  - **Level 1 — Coral Sea Sunset Archipelago (`380 HP` Iron Vulture Bomber)**: Golden-crimson sunset sky over tropical volcanic islands and turquoise swells. The gunmetal twin-wing carrier enters **Phase 2 Enraged Overdrive** at 50% HP with faster maneuvers and double fighter launches.
  - **Level 2 — Arctic Aurora Glacier Strait (`720 HP` Storm Valkyrie Gunship)**: Polar midnight sky with shimmering emerald and cyan Aurora Borealis ribbons and towering jagged glaciers. The crimson forward-swept assault fortress unleashes 3-way cannon spreads and activates a Phase 2 tactical energy shield below 50% HP.
  - **Level 3 — Volcanic Lightning Red Sea (`1150 HP` Sky Titan Dreadnought)**: Obsidian ash clouds, erupting twin volcanoes with glowing magma streams, crimson sea swells, and storm lightning bolts. The tri-hull dreadnought commands a pulsing energy shield dome, 5-way plasma spreads, and Phase 2 overdrive.
- **Incremental B-2 Spirit Offensive Capabilities Per Level**:
  - **Level 1 (Tier 1 Weapons)**: `1` Heavy Cruise Missile + Continuous **Nose Rotary Gatling Cannon** (`+150` gun kills) + `1` Gravity Bomb + `4`-Bomb Carpet Salvo.
  - **Level 2 (Tier 2 Weapons)**: **Twin Supersonic Homing Missiles** + **Twin Wing-Mounted Cyan Rotary Autocannons** + **Dual Cluster Bombs** + `6`-Bomb Carpet Salvo.
  - **Level 3 (Tier 3 Weapons)**: **Triple Homing Cruise Missiles** + **High-Energy Nose Plasma Laser Beam** + **Twin Autonomous Stealth Wingman Drones** firing violet plasma bolts + `3` Heavy Mega Bombs + `8`-Bomb Mega Carpet Salvo.
- **Wartime Seascape & Paratrooper Rescues**: Dynamic rolling ocean swells, whitecap waves, searchlight beams, water splash geysers, enemy destroyers/cruisers/carriers that catch fire and sink, and paratroopers to rescue mid-air.

## Keyboard and Mouse Controls

| Input | Action |
| --- | --- |
| **Mouse Move** | Fly the B-2 Spirit stealth bomber across the sky |
| **Mouse Left Click** / **Space** | Fire current Weapon Tier (Missiles + Bombs + Level 3 Plasma Laser) |
| **Mouse Right Click** / **B** | Unleash a Carpet Bombing Salvo (4 / 6 / 8 bombs by level) |
| **1** / **2** / **3** | Jump directly to Level 1, Level 2, or Level 3 |
| **P** | Pause / Resume |
| **?** | Toggle help and shortcuts overlay |
| **Q** | Quit |

## Command-Line Usage

```sh
# Open the game window
skystrike open

# Check high score and game statistics in JSON
skystrike status --json

# Install agent skill
skystrike skill install
```

## Building and Testing

```sh
bin/build    # Compiles with qmake6 and make
bin/test     # Runs offscreen Qt tests
bin/install  # Installs desktop launcher entry and binary
```
