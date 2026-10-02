# BACKLOG
Priorisiert, oberste zuerst. Planer zerlegt Einträge in Tasks (`tools/new_task.sh`).

## Meilenstein 0: Setup
- [ ] GUT installieren (`game/addons/gut`), Plugin aktivieren, `tools/run_checks.sh` einmal grün laufen lassen
- [ ] Input-Aktionen laut CONVENTIONS.md im Editor anlegen
- [ ] OPEN_QUESTIONS 1-5 beantworten

## Meilenstein 1: Player
- [ ] Player-Szene (`CharacterBody2D`) mit 4-Richtungs-Bewegung
- [ ] Kamera folgt dem Player

## Meilenstein 2: Farm-Grid
- [ ] TileMapLayer mit Platzhalter-Tiles
- [ ] Grid-Hilfsklasse (Weltposition <-> Zelle), mit Tests
- [ ] Zeile "Zelle vor dem Spieler" anzeigen (Cursor)

## Meilenstein 3: Werkzeuge und Pflanzen
- [ ] Boden pflügen / gießen (Zustand pro Zelle in Datenobjekt)
- [ ] `CropData`-Resource + Wachstum bei `day_started`
- [ ] Säen und Ernten

## Später
Inventar, Verkauf, Save/Load, Energie, NPCs.
