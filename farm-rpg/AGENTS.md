# AGENTS.md
Regeln für **alle** Agenten und Modelle in diesem Repo (Continue, Open WebUI, Skripte, Container).
Projekt: 2D-Farming-RPG in **Godot 4 / GDScript**. Gilt vor allen anderen Anweisungen, außer ein Mensch widerspricht ausdrücklich.

## 1. Lesereihenfolge (jede Session)
1. `AGENTS.md` (diese Datei)
2. `docs/CONVENTIONS.md` und `docs/ARCHITECTURE.md`
3. Dein aktueller Task: `tasks/active/TASK-XXXX.md`
4. Nur die dort genannten Kontext-Dateien. Nicht das ganze Projekt lesen.

## 2. Arbeitsweise
- **Ein Task = ein Ziel = ein Branch (`task/XXXX-slug`) = ein Commit.** Nie direkt auf `main`.
- Ändere **nur** Dateien aus dem Abschnitt "Änderungen" des Tasks. Alles andere ist tabu.
- Kein Scope Creep: kein Refactoring, keine Umbenennungen, keine "Verbesserungen" nebenbei. Gute Idee? Eintrag in `tasks/BACKLOG.md`.
- Unklar oder widersprüchlich? **Nicht raten.** Frage in `docs/OPEN_QUESTIONS.md` eintragen, Task als `BLOCKED` melden.
- Entscheidung mit Wirkung auf mehrere Dateien → `docs/DECISIONS.md` (Datum, Entscheidung, Grund).

## 3. Definition of Done
Ein Task ist erst fertig, wenn:
1. `tools/run_checks.sh` mit `RESULT: PASS` endet (Ausgabe im Review mitliefern),
2. alle Akzeptanzkriterien des Tasks erfüllt sind,
3. ein Test existiert, wenn der Task Logik enthält (nicht bei reiner Szenen-/Doku-Arbeit),
4. der Commit nur Task-Dateien enthält (`git status` sauber, keine `.checks/`, kein `.godot/`).

**Max. 3 Versuche pro Task.** Danach stoppen und berichten: was versucht, welcher Fehler (Datei:Zeile, Log-Auszug), Vermutung zur Ursache.

## 4. Godot 4 (häufige Fehler, bitte aktiv vermeiden)
- `@onready`, `@export`, `await`, `signal.connect(callable)`, `instantiate()`, `CharacterBody2D`. **Keine Godot-3-Syntax** (`onready var`, `yield`, `connect("sig", self, "fn")`, `KinematicBody2D`, `instance()`). `run_checks.sh` meldet das.
- **Statische Typen** überall: `var speed: float = 80.0`, `func grow(days: int) -> void:`.
- Spieldaten als **Custom Resources** (`class_name ItemData extends Resource`), keine losen Dictionaries.
- "Call down, signal up": Kommunikation nach oben per Signal, keine Pfade wie `get_node("../../X")`.
- `.tscn`/`.tres` nur minimal ändern, **keine UIDs oder IDs erfinden**. Im Zweifel Nodes per Script aufbauen oder den Menschen die Szene im Editor anlegen lassen.
- API unsicher? Nicht erfinden. Im Code/Doku nachsehen oder in `OPEN_QUESTIONS.md` fragen.
- Autoloads nur laut `ARCHITECTURE.md` (z. B. `GameClock`, `EventBus`, `SaveManager`). Keine neuen ohne Freigabe.

## 5. Befehle
```bash
tools/run_checks.sh             # alle Checks
tools/run_checks.sh --fast      # ohne Tests
tools/run_checks.sh --changed   # nur geänderte .gd-Dateien prüfen
tools/new_task.sh "Titel" S|M   # neuen Task aus tasks/TEMPLATE.md anlegen
tools/agent_task.sh TASK-0001   # Task mit aider ausführen (im agent-Container)
gdformat game/scripts           # Formatierung korrigieren
```
Logs liegen in `.checks/`. Bei FAIL zuerst das passende Log lesen, dann gezielt fixen.

## 6. Sandbox und Sicherheit (Docker)
- Agenten laufen im Container `agent` (`docker-compose.yml`): Repo unter `/work`, Nicht-Root, alle Capabilities entfernt.
- **Kein Internet:** Das Netz `agent_net` ist intern. Erreichbar sind nur `ollama` (lokal, 3070) und `dev-ollama` (Brücke zum Dev-Server).
- Erlaubte Shell-Befehle: `git` (add, commit, switch, diff, status, log), `godot`, `tools/*`, `gdformat`, `gdlint`, Lesebefehle (`cat`, `ls`, `grep`, `find`).
- **Verboten ohne ausdrückliche Freigabe:** Dateien/Ordner löschen, `git push`, `git reset --hard`, History umschreiben, Pakete/Addons installieren, Docker-/Ollama-Konfiguration ändern.
- Keine Geheimnisse (Keys, Tokens, interne Hostnamen) in Dateien, Commits oder Logs.
- Die Planer-Seite (Open WebUI über `mcpo`) darf nur `docs/` und `tasks/` schreiben.

## 7. Modell-Routing und Eskalation
| Stufe | Wer | Wann |
|---|---|---|
| S | lokales 3070-Modell | Einzelfunktion, Resource, Test, Doku |
| M | Coder auf Dev-Server (Devstral) | Szene + Script, Integration |
| L | Planer (Qwen 27B) | **Nie direkt ausführen.** Zuerst in S/M-Tasks zerlegen |

Zweimal gescheitert → eskalieren (größeres Modell oder Re-Planung). Nie dasselbe Modell mit identischem Prompt zum dritten Mal.

## 8. Antwortformat
**Executor am Ende eines Tasks:**
```
TASK-XXXX: DONE | FAILED | BLOCKED
Geänderte Dateien: ...
Checks: RESULT: PASS|FAIL (Kurzfassung)
Offene Punkte: ...
```
**Planer-Review:**
```
Review TASK-XXXX: PASS | FAIL | BLOCKED
Probleme: (nummeriert, Datei:Zeile)
Nächster Schritt: ...
```
Denkblöcke (`<think>`) gehören nie in Dateien, Commits oder Task-Berichte.

## 9. Mentoring
Der Mensch lernt Godot mit. Erkläre nicht-triviale Entscheidungen in 2–4 Sätzen (Was, Warum, Alternative). Neue Konzepte kurz in `docs/MENTORING_LOG.md` festhalten. Ehrlich bleiben: Wenn ein Wunsch den Scope sprengt, benenne es und biete eine kleinere Variante an.
