# Tech Context

## Stack

- Engine: Godot 4.x
- Language: GDScript
- Platform target in docs: desktop and mobile, но фактически проверяемая реализация в репозитории ориентирована на desktop prototype.
- VCS: Git, remote on GitHub

## Repository Landmarks

| Path | Purpose |
| --- | --- |
| `project.godot` | Конфигурация проекта и input map. |
| `scenes/` | Сцены меню, персонажей, уровней и shared-узлов. |
| `scripts/core/` | Основная игровая логика прототипа. |
| `scripts/ui/` | Логика интерфейсных сцен. |
| `resources/` | Godot resources, включая тайлсет подземелья. |
| `cut_ui_sprites.ps1` | Локальная утилита подготовки ассетов. |

## Tooling Notes

- По правилам AGENTS.md для JavaScript/TypeScript-проектов должен использоваться `bun` и проверка Biome, но в текущем репозитории отсутствуют `package.json`, `bun.lockb` и конфигурация Biome.
- В этой задаче изменялись только Markdown-файлы, которые по правилам не проверяются через Biome.
