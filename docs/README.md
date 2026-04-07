# GunBlade Architecture Overview

## Project Summary

GunBlade is a Godot 4 action roguelike prototype with a menu-driven entry point and a single playable dungeon scene. The current repository state implements a vertical slice focused on core movement, melee combat, basic enemy pursuit, and simple run persistence.

## Runtime Entry Points

| Area | Path | Purpose |
| --- | --- | --- |
| Project config | `project.godot` | Defines engine settings, input actions, window configuration, and the main scene. |
| Main menu | `scenes/menus/MainMenu.tscn` | First screen shown on startup. |
| Main menu logic | `scripts/ui/MainMenu.gd` | Starts a new run or exits the game. |
| Game scene | `scenes/game/levels/Dungeon.tscn` | Current playable level used for the prototype. |

## Core Gameplay Modules

| Module | Paths | Responsibility |
| --- | --- | --- |
| Player | `scenes/game/characters/Player.tscn`, `scripts/core/Player.gd` | Handles movement, sprite flipping, frame-based animation, melee attack timing, health, and death. |
| Enemy | `scenes/game/characters/Enemy.tscn`, `scripts/core/Enemy.gd` | Handles player detection, pursuit, attack cadence, damage reaction, and death. |
| Camera | `scenes/shared/Camera.tscn`, `scripts/core/Camera.gd` | Shared camera scene for following gameplay action. |
| Run state | `scripts/core/Game.gd` | Stores current floor, gold, and minimal run progress in `user://savegame.dat`. |

## Supporting Assets And Resources

| Area | Paths | Notes |
| --- | --- | --- |
| Tile resources | `resources/dungeon_tileset.tres` | Dungeon tileset resource used by the prototype level. |
| Shared UI | `scenes/shared/HealthBar.tscn` | Shared scene for health display. |
| Asset pipeline helper | `cut_ui_sprites.ps1` | Utility script for slicing UI sprite sheets outside the game runtime. |

## Current Scope Boundaries

- Implemented: startup menu, dungeon scene loading, player movement, player attack, enemy chase and attack, player/enemy health and death, simple persisted run state.
- Not implemented in current codebase: class selection, procedural dungeon generation, inventory and equipment, alchemy, shops, boss flow, localization pipeline, full HUD, and production-ready save/load systems.

## Architectural Notes

- The project uses Godot scenes for composition and GDScript for gameplay logic.
- Input actions currently cover directional movement and mouse attack.
- The prototype mixes scene-authored nodes with script-driven behavior and remains at an early vertical-slice stage.
