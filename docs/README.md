# GunBlade Architecture Overview

## Project Summary

GunBlade is a Godot 4 action roguelike prototype with a menu-driven entry point, a start room, and a combat room linked into a minimal run loop. The current repository state implements a vertical slice focused on movement, melee and ranged combat, room progression, and simple run persistence.

## Runtime Entry Points

| Area | Path | Purpose |
| --- | --- | --- |
| Project config | `project.godot` | Defines engine settings, input actions, window configuration, and the main scene. |
| Main menu | `scenes/menus/MainMenu.tscn` | First screen shown on startup. |
| Main menu logic | `scripts/ui/MainMenu.gd` | Starts a new run or exits the game. |
| Start room | `scenes/game/levels/TestRoom.tscn` | Opening chamber where the player clears a guard and unlocks the descent gate. |
| Combat room | `scenes/game/levels/Dungeon.tscn` | Main combat arena cleared before claiming the next floor. |

## Core Gameplay Modules

| Module | Paths | Responsibility |
| --- | --- | --- |
| Player | `scenes/game/characters/Player.tscn`, `scripts/core/Player.gd` | Handles movement, jump physics, sprite flipping, frame-based animation, melee attacks, ranged arrows, health, and death. |
| Enemy | `scenes/game/characters/Enemy.tscn`, `scripts/core/Enemy.gd` | Handles player detection, pursuit, attack cadence, damage reaction, optional dummy mode, and death. |
| Room flow | `scripts/core/Dungeon.gd` | Applies selected character stats, updates room HUD, tracks living enemies, and handles room-to-room gate transitions. |
| Run state | `scripts/core/Game.gd` | Stores selected character, current floor, gold, and minimal run progress in `user://savegame.dat`. |

## Supporting Assets And Resources

| Area | Paths | Notes |
| --- | --- | --- |
| Tile resources | `resources/dungeon_tileset.tres` | Dungeon tileset resource used by the prototype level. |
| Shared UI | `scenes/shared/HealthBar.tscn` | Shared scene for health display. |
| Asset pipeline helper | `cut_ui_sprites.ps1` | Utility script for slicing UI sprite sheets outside the game runtime. |

## Current Scope Boundaries

- Implemented: startup menu, character select, start room, combat room, gate-based progression, player movement, melee and ranged attacks, enemy chase and attack, player/enemy health and death, and simple persisted run state.
- Not implemented in current codebase: procedural dungeon generation, inventory and equipment, alchemy, shops, boss flow, localization pipeline, audio pipeline, and production-ready save/load systems.

## Architectural Notes

- The project uses Godot scenes for composition and GDScript for gameplay logic.
- Input actions currently cover directional movement and mouse attack.
- The prototype mixes scene-authored geometry with script-driven room state and remains at an early vertical-slice stage.
