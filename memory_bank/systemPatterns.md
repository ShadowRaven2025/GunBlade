# System Patterns

## High-Level Structure

- Godot scene tree используется как основной механизм композиции.
- GDScript-файлы в `scripts/core` и `scripts/ui` реализуют поведение игровых объектов и экранов.
- Текущий проект представляет собой ранний вертикальный срез без развитой модульной декомпозиции.

## Observed Runtime Flow

1. Godot запускает `scenes/menus/MainMenu.tscn` как главную сцену.
2. `scripts/ui/MainMenu.gd` переводит пользователя в `scenes/game/levels/Dungeon.tscn`.
3. В игровой сцене активны игрок, враги и вспомогательные сцены вроде камеры и health bar.
4. `scripts/core/Player.gd` и `scripts/core/Enemy.gd` управляют базовой боевой петлей.
5. `scripts/core/Game.gd` хранит минимальное состояние текущего run через локальный файл сохранения.

## Architectural Constraints

- Часть логики и структуры расходится с исходным планом из `DEVELOPMENT_PLAN.md`; в коде фактически реализован только базовый prototype scope.
- В проекте заметны следы промежуточных экспериментов, например `scripts/systems/GameManager.gd`, который не соответствует текущей реализации `Player.gd` по API и выглядит как устаревший путь настройки сцены.
