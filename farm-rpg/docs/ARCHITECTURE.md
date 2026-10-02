# ARCHITECTURE

## Ordner (`game/`)
| Ordner | Inhalt |
|---|---|
| `autoload/` | Globale Singletons (nur laut Liste unten) |
| `scenes/` | `.tscn`-Szenen, gruppiert nach Feature (`scenes/player/`, `scenes/farm/`, `scenes/ui/`) |
| `scripts/` | Reine Logik ohne Szenenbezug (`RefCounted`/`Resource`), Hilfsklassen |
| `resources/` | `.tres`-Daten (`items/`, `crops/`) |
| `assets/` | Sprites, Tilesets, Audio, UI-Grafik |
| `tests/` | GUT-Tests, Datei `test_<thema>.gd` |

Szenen-Scripts liegen **neben ihrer Szene** (`player.tscn` + `player.gd`).

## Autoloads (abschließende Liste)
| Name | Zweck | Abhängigkeiten |
|---|---|---|
| `EventBus` | Systemübergreifende Signale, keine Logik | keine |
| `GameClock` | Spielzeit, Tageswechsel, Signale `time_changed`, `day_started` | keine |
| `SaveManager` (geplant) | Speichern/Laden | liest Zustand über definierte Schnittstellen |

Neue Autoloads brauchen einen Eintrag in `DECISIONS.md`.

## Prinzipien
- **Daten als Resources:** `ItemData`, `CropData` (`class_name ... extends Resource`). Neue Pflanze = neue `.tres`, kein neuer Code.
- **Call down, signal up.** Eltern rufen Kinder direkt, Kinder melden per Signal.
- **Logik testbar halten:** Regeln in `RefCounted`/`Resource`-Klassen oder Autoloads ohne Szenenabhängigkeit.
- **Zustand zentral:** Farm-Zustand (Tiles, Pflanzen) in einem Datenobjekt, die Szene stellt es nur dar. Das vereinfacht Speichern.

## Geplante Systeme (Reihenfolge)
1. Player & Bewegung
2. Farm-Grid / TileMapLayer
3. Werkzeuge & Interaktion
4. Pflanzen (`CropData`, Wachstum bei `day_started`)
5. Inventar & Items
6. Ernte, Verkauf, Geld
7. Save/Load
8. Energie, NPCs, Dialoge
