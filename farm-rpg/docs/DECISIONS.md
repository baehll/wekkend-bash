# DECISIONS
Format: Datum, Entscheidung, Grund. Neueste zuunterst.

- **2026-10-03 | Godot 4 + GDScript:** Beste Unterstützung für 2D, Textformate (.tscn/.tres) sind git- und LLM-freundlich.
- **2026-10-03 | Renderer GL Compatibility:** Pixel-Art-2D braucht keinen Forward+; läuft auch headless/in Containern stabiler.
- **2026-10-03 | Auflösung 640x360, Integer-Skalierung, Nearest-Filter:** Scharfe Pixel bei 16:9-Skalierung.
- **2026-10-03 | Daten als Custom Resources:** Items und Pflanzen datengetrieben, leicht testbar und von Modellen editierbar.
- **2026-10-03 | Autoloads `EventBus`, `GameClock`:** Minimaler globaler Zustand; `GameClock` ohne Abhängigkeiten, damit ohne Szene testbar.
- **2026-10-03 | GUT als Test-Framework (Vorschlag):** Einfache CLI-Anbindung für `run_checks.sh`. Alternative gdUnit4 ist unterstützt.
