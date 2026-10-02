# CONVENTIONS

## GDScript
- Godot-4-Syntax, **statische Typisierung** für Variablen, Parameter und Rückgabewerte.
- Namen: Dateien/Ordner `snake_case`, Klassen `PascalCase`, Funktionen/Variablen `snake_case`, Konstanten `UPPER_SNAKE`, Signale `snake_case` in Vergangenheit (`day_started`), private Member mit `_`.
- Reihenfolge in Dateien: `extends`, `class_name`, Doc-Kommentar, Signale, Enums, Konstanten, `@export`, öffentliche Variablen, private Variablen, `@onready`, Methoden (Lifecycle zuerst).
- Einrückung mit Tabs (gdformat-Standard). Zeilenlänge max. 100.
- Kein `get_node("../..")`. Referenzen per `@export var x: Node` oder `@onready var x: Node = $Child`.
- Kommentare erklären das *Warum*. Doc-Kommentare mit `##`.
- `class_name` **nicht** bei Autoload-Scripts (kollidiert mit dem Singleton-Namen).

## Szenen und Ressourcen
- Eine Szene = eine Verantwortung. Node-Namen in `PascalCase`.
- `.tscn`/`.tres` nur minimal von Agenten ändern (siehe AGENTS.md §4).
- Pixel-Art: Textur-Filter Nearest (in `project.godot` gesetzt), Integer-Skalierung.

## Input-Aktionen (im Editor unter Projekteinstellungen > Eingabe-Zuordnung anlegen)
`move_left`, `move_right`, `move_up`, `move_down`, `interact`, `use_tool`, `tool_next`, `tool_prev`, `open_inventory`.
Im Code nur diese Namen verwenden, keine Tasten hartkodieren.

## Collision-Layer (Vorschlag, im Editor benennen)
1 `world`, 2 `player`, 3 `interactables`, 4 `npc`.

## Tests
- GUT 9.x, Dateien `game/tests/test_<thema>.gd`, `extends GutTest`.
- Logik wird getestet, Szenen-/Optikarbeit nicht.
- Ein Test prüft ein Verhalten, Name beschreibt es (`test_day_rolls_over_at_midnight`).

## Git
- Branch pro Task: `task/<nr>-<slug>`, ein Commit pro Task.
- Commit-Message: `TASK-0007: Kurzbeschreibung im Imperativ`.
