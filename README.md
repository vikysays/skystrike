# Sky Strike

City defense aeroplane combat game for Omarchy, designed especially for quick arcade fun with the mouse.

![Sky Strike screenshot](screenshot.png)

## Features

- **Mouse-First Flight**: Aeroplane glides smoothly wherever the mouse moves.
- **Missiles in the Plane**: Launch dual high-speed missiles with left click or Space bar.
- **Giant Mothership**: Massive aircraft cruises across the sky with opening hangar bay doors.
- **Small Fighter Planes**: Waves of agile mini jets launched from the mothership.
- **Paratroopers Rescue**: Soldiers jump from planes with colorful parachutes; fly close to rescue them for bonus star points.
- **Cityscape Ground**: Multi-layer parallax skyline with glowing windows and blinking antenna beacons.
- **Live Omarchy Theme**: Live accent colors and Hyprland window rounding.

## Keyboard and Mouse Controls

| Input | Action |
| --- | --- |
| **Mouse Move** | Fly the aeroplane smoothly across the sky |
| **Mouse Left Click** | Launch missiles |
| **Space** | Launch missiles |
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
