---
name: Farm RPG Projektregeln
alwaysApply: true
---
Projekt: 2D-Farming-RPG in Godot 4 (GDScript). Vollständige Regeln stehen in AGENTS.md, docs/CONVENTIONS.md und docs/ARCHITECTURE.md im Repo. Lies sie bei Bedarf, bevor du Code schreibst.

- Nur Godot-4-Syntax (`@onready`, `@export`, `await`, `signal.connect(callable)`, `CharacterBody2D`, `instantiate()`), statische Typen überall.
- Kleine, atomare Änderungen. Nur Dateien ändern, die zur Aufgabe gehören. Kein Refactoring nebenbei.
- `.tscn`/`.tres` nur minimal ändern, keine UIDs oder IDs erfinden.
- Spieldaten als Custom Resources, Kommunikation per Signals, keine `get_node("../..")`-Pfade.
- Prüfen mit `tools/run_checks.sh`. Unklarheiten in docs/OPEN_QUESTIONS.md eintragen statt zu raten.
- Keine Löschaktionen, kein `git push`, keine neuen Pakete ohne Freigabe.
