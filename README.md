# Sky Strike

B-2 Spirit stealth bomber air and naval combat game for Omarchy, designed for effortless mouse control and explosive arcade action.

![Sky Strike screenshot](screenshot.png)

## Features

- **B-2 Spirit Stealth Bomber**: Fly the iconic flying-wing stealth bomber with sawtooth trailing edge, flush cockpit windows, and internal bomb bay doors.
- **Big Cruise Missiles & Dramatic Impact**: Launch heavy cruise missiles with roaring afterburner plumes, supersonic shockwave rings, multi-stage fireballs, dark smoke clouds, and screen shake.
- **3 Boss Aeroplane Levels with Progressive Complexity**:
  - **Level 1 — Iron Vulture Bomber**: Gunmetal twin-wing airborne carrier launching red fighter escorts and firing targeted plasma shots.
  - **Level 2 — Storm Valkyrie Gunship**: Crimson forward-swept assault fortress with agile swooping maneuvers, twin fighter launches, and 3-way cannon spreads.
  - **Level 3 — Sky Titan Dreadnought**: Obsidian-and-gold tri-hull aerial dreadnought with a pulsing energy shield dome, 5-way plasma spreads, and full air/naval armada support.
- **Upgraded Player B-2 Spirit Capabilities Per Level**:
  - **Level 1 (Tier 1 Weapons)**: Heavy Cruise Missile + Gravity Bomb + 4-Bomb Carpet Salvo.
  - **Level 2 (Tier 2 Weapons)**: Twin Supersonic Homing Missiles + Dual Cluster Bombs + 6-Bomb Carpet Salvo.
  - **Level 3 (Tier 3 Weapons)**: Triple Homing Cruise Missiles + High-Energy Nose Plasma Laser Beam + 3 Heavy Bombs + 8-Bomb Mega Carpet Salvo.
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
