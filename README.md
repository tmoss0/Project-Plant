# Project Plant

A 2D platformer game built in Godot 4.4 featuring a character with unique movement mechanics including grappling hooks and burrowing abilities.

## Features

- **Multi-state Player Movement**: State machine-driven character with idle, moving, jumping, falling, grappling, grappled, and burrowing states
- **Grappling Hook System**: Click to shoot, right-click to pull, with visual aim line and rope physics
- **Burrowing Mechanic**: Underground movement ability (C key to burrow, V to cancel)
- **4 Levels**: Progressive level design with increasing complexity
- **Audio Integration**: Sound effects for player interactions

## Controls

- **Movement**: A/D or Arrow Keys
- **Jump**: Spacebar
- **Grapple**: Left Click (shoot), Right Click (pull)
- **Burrow**: C (enter), V (exit)

## Technical Details

- **Engine**: Godot 4.4 with Forward Plus rendering
- **Resolution**: 1280x720 viewport
- **Physics**: Custom gravity (1000.0) with collision layers for Player, World, GrappleSurface, and Enemies
- **Architecture**: State machine pattern for player behavior management

## Project Structure

```
project-plant/
├── assets/          # Textures and audio
├── scenes/          # Game levels and character scenes
├── scripts/         # Player logic and state management
└── project.godot    # Godot project configuration
```

## Development Status

Early development (v0.1) with core mechanics implemented and 4 levels created.

