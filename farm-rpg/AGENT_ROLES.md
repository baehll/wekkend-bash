# AGENT_ROLES: Modelle, Modi und Rollen

## 1. Modellrollen (Dev-Server)

| Modell | Hauptrolle | Tools | Nicht verwenden für |
|---|---|---|---|
| Devstral Small 2 24B (Q3_K_L) | Coder (Chat, Edit, Apply, Agent) | ja | schwierige Architekturfragen |
| Qwen3.8 27B (Q4_K_M) | Planer, Reviewer | ja | Kleinkram (zu langsam) |
| DeepSeek R1 Distill 14B | Zweitmeinung, Debugging-Analyse | nein (bewusst) | Agent-/Tool-Loops |
| LFM2.5 2.6B Turbo-Brilliance (Q8_0) | **Agent-Basis**: Orchestrierung, Tool-Use, Extraktion, Zusammenfassungen, Task-Specs | ja | Programmieren, Faktenwissen |

Zum LFM-Modell sagt die Modellkarte: empfohlen für agentische Workloads, Tool-Use, Datenextraktion, RAG und lange Kontexte; **nicht empfohlen für agentisches Coden und wissensintensive Aufgaben**. Code schreibt deshalb Devstral (oder ein 7-9B-Coder auf der 3070), nicht das LFM-Modell. Mit Q8_0 (rund 3 GB) passt es auch auf die 3070 und kann dort parallel zu kleinen Aufgaben dienen.

## 2. Die 12 Modi (Turbo-Brilliance)

Schaltung: Tag **am Anfang der Nachricht** (`{REASON:spoon} ...`). Instruct-Variante mit Präfix `i` (`{REASON:ispoon}`), aus mit `{REASON:off}`, Hilfe mit `{REASON:help}`. Standard ohne Tag: Reasoning `high`, Instruct `medium`.

| # | Tag | Rolle im Projekt | Einsatz | Prompt in Continue |
|---|---|---|---|---|
| 1 | `omni` | Architekt | Systemübergreifende Planung, Reihenfolge, Wechselwirkungen | `/Architekt (omni)` |
| 2 | `deeptree` | Task-Zerleger | Großes Ziel bis zu S/M-Tasks herunterbrechen | `/Task-Zerleger (deeptree)` |
| 3 | `hyper` | Vollständigkeits-Check | MECE-Prüfung von Backlog, Akzeptanzkriterien, Testfällen | `/Vollständigkeits-Check (hyper)` |
| 4 | `socrates` | Mentor | Annahmen hinterfragen, Lernfragen, Vorbereitung von DECISIONS | `/Mentor (socrates)` |
| 5 | `logic` | Debugger | Ursachenanalyse aus Check-Logs und Stacktraces | `/Debugger (logic)` |
| 6 | `einstein` | Ideengeber | Mechaniken/Features brainstormen (nichts ohne Freigabe übernehmen) | `/Ideengeber (einstein)` |
| 7 | `spoon` | Expertenpanel | Optionenvergleich, Design-Entscheidungen, Recherche | `/Expertenpanel (spoon)` |
| 8 | `ultra` | Final-Reviewer | Gründliche Prüfung vor dem Merge (langsam) | `/Final-Review (ultra)` |
| 9 | `high` | Planer Standard | Task-Specs schreiben | `/Planer Standard (high)` |
| 10 | `medium` | Doku/Texte | Doku, Commit-Messages, Mentoring-Notizen | `/Doku und Texte (medium)` |
| 11 | `medium-low` | Schnellantwort | Log-Triage, kurze Fragen | `/Schnellantwort (medium-low)` |
| 12 | `low` | Extraktion | Formatieren/Extrahieren mit minimalem Tokenverbrauch | `/Extraktion minimal (low)` |

Die Zuordnung zu Projektaufgaben ist mein Vorschlag auf Basis der Modus-Beschreibungen der Modellkarte. Ob jeder Modus bei einem 2,6B-Modell wirklich so wirkt, zeigt erst der Test (Abschnitt 4).

## 3. Regeln für die Nutzung

- **Neuer Chat beim Moduswechsel.** Die Modellkarte empfiehlt das ausdrücklich. In Skripten: pro Modus eine eigene Anfrage ohne gemeinsamen Verlauf.
- Bei `spoon` und `einstein` den Zusatz "show the work of all panelists" bzw. "of all agents" anhängen (steckt in den Prompts).
- Für Agent-Schleifen (viele kurze Aufrufe) die Instruct-Modi nehmen: `{REASON:imedium-low}` oder `{REASON:ilow}`. Das Modell denkt sonst bei jedem Schritt (es ist ein reines Reasoning-Modell).
- Denkblöcke (`<think>`) nie in Dateien, Commits oder Task-Berichte übernehmen (siehe AGENTS.md §8).
- Min. Kontext laut Modellkarte 24.000 Token. Vorgabe in `continue/config.yaml`: 32.768.
- Laut Modellkarte: Q6 oder Q8 verwenden. Niedrigere Quants verschlechtern die Modi spürbar.
- Parameter laut Modellkarte (Test-Einstellungen): temperature 0.1 bis 1, top_k 64, min_p 0.05, top_p 0.95, repeat_penalty 1 bis 1.1. Fest einbauen mit `ollama/lfm-agent.Modelfile`.

## 4. Einmaliger Funktionstest (vor produktivem Einsatz)

1. Modell holen: `ollama pull hf.co/DavidAU/LFM2.5-2.6B-Qwen3.8-Turbo-Brilliance-Power-X12-NEO-MAX-GGUF:Q8_0` (Tag Q8_0 prüfen, falls der Pull fehlschlägt).
2. `ollama show <modell>` ansehen: steht bei den Capabilities `tools`? Wenn nicht, funktioniert Continues Agent-Modus mit diesem Modell nicht, und es bleibt Chat/Extraktion. Das Modell erzeugt standardmäßig Pythonic-Tool-Calls; ob Ollama sie über das mitgelieferte Template erkennt, ist nicht garantiert.
3. In einem neuen Chat `{REASON:help} Menu` senden. Antwortet das Modell mit der Modusübersicht, ist die Schaltung aktiv.
4. Pro Modus, den du nutzen willst, eine echte Projektaufgabe laufen lassen (z. B. `/Task-Zerleger (deeptree)` mit "Farm-Grid mit gießbarem Boden") und das Ergebnis mit Qwen 27B vergleichen.
5. Kommt das Modell bei einer Rolle nicht an Qwen/Devstral heran, die Rolle dorthin verlegen. Das ist bei 2,6B zu erwarten, sobald Fachwissen gefragt ist.

## 5. Wo die Modi greifen

- **Continue:** Prompts aus `.continue/prompts` (in der Chat-Eingabe `/` tippen). Modell "LFM2.5 2.6B Turbo-Brilliance" wählen.
- **Open WebUI:** Tag manuell an den Anfang der Nachricht setzen oder pro Modus ein "Prompt" speichern (Workspace > Prompts) mit dem Text aus der jeweiligen Datei.
- **Skripte/Agenten:** Tag als erste Zeile der Anfrage. Ob der Tag auch im System-Prompt wirkt, nennt die Modellkarte nicht. Beispiele dort setzen ihn in die Nutzernachricht, daher ist das der sichere Weg.
