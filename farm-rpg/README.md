# Farm RPG (Godot 4) – lokale KI-Dev-Umgebung

## Überblick
```
Open WebUI (Planung, Mentoring)  ──┐
Continue (IDE)                     ├──> Repo (docs/, tasks/, game/)  <── agent-Container (aider + Godot, ohne Internet)
Dev-Server-Ollama (große Modelle) ─┘                                     └─ tools/run_checks.sh als Prüfinstanz
Lokale Ollama (3070, kleine Tasks)
```
Das Repo ist der gemeinsame Projektspace. Regeln für Agenten: `AGENTS.md`.

## Voraussetzungen
- Docker mit Compose v2.17 oder neuer. Unter Windows: Docker Desktop (WSL2-Backend) + NVIDIA-Treiber, Befehle in WSL ausführen, Repo im WSL-Dateisystem ablegen.
- Godot 4 zum Öffnen des Projekts im Editor (`game/project.godot`).
- Git.

## Einrichtung
```bash
git init && git add -A && git commit -m "Projekt-Setup"
cp .env.example .env            # DEV_OLLAMA_HOST, WEBUI_SECRET_KEY, HOST_UID/GID setzen

docker compose up -d ollama open-webui
docker compose exec ollama ollama pull <lokales-3070-modell>   # 7-9B, Q4_K_M
# optional: Projektordner als Tool-Server für Open WebUI
docker compose --profile mcp up -d mcpo
# Agent-Image bauen
docker compose build agent
```
Open WebUI: http://localhost:3000 (Dev-Server und lokale Ollama erscheinen als zwei Verbindungen).

## GUT installieren (einmalig, braucht Internet auf dem Host)
Im Godot-Editor: AssetLib > "GUT" > installieren (Version 9.x, passend zur Godot-Version), Plugin aktivieren. Danach liegt es in `game/addons/gut`, und `run_checks.sh` führt `game/tests/` aus.

## Täglicher Ablauf
```bash
tools/new_task.sh "Player-Bewegung" M          # Task anlegen, Inhalt vom Planer ausfüllen lassen
docker compose run --rm agent tools/agent_task.sh TASK-0001
tools/run_checks.sh                             # optional auch lokal/in Container
git diff main...HEAD                            # Review, danach mergen
```
Modellwechsel: `AGENT_OLLAMA_URL` und `AGENT_MODEL` in `.env` (siehe `.env.example`). Für lokale Modelle muss der Name auch in `.aider.model.settings.yml` stehen.

## Hinweise
- Godot-Version: `GODOT_VERSION` in `.env` und `config/features` in `game/project.godot` anpassen (voreingestellt 4.3).
- Die Dateien in diesem Setup wurden ohne laufendes Docker/Godot erstellt. Erster Lauf: `docker compose build agent` und `tools/run_checks.sh` prüfen.
