#!/usr/bin/env bash
# tools/run_checks.sh
# Automatische Checks für das Godot-4-Projekt. Läuft lokal (godot im PATH)
# oder per Docker (Fallback, wenn kein godot gefunden wird).
#
# Nutzung:
#   tools/run_checks.sh [--fast] [--changed] [--no-boot] [-h]
#
#   --fast      Tests überspringen
#   --changed   nur geänderte/neue .gd-Dateien prüfen (gegen $BASE_REF + Working Tree)
#   --no-boot   Headless-Start des Projekts überspringen
#
# Umgebungsvariablen (optional):
#   GODOT_BIN       Pfad/Name der Godot-Binary (sonst: godot, godot4, godot-4)
#   GODOT_IMAGE     Docker-Image, falls kein lokales Godot (Default s.u.; Version an Projekt anpassen)
#   GAME_DIR        Ordner mit project.godot (Default: game)
#   BASE_REF        Vergleichs-Branch für --changed (Default: main)
#   BOOT_FRAMES     Frames für den Headless-Start (Default: 120)
#   STEP_TIMEOUT    Timeout pro Godot-Aufruf in Sekunden (Default: 180)
#   ERR_REGEX       Regex für Fehlerzeilen im Godot-Log
#   IGNORE_REGEX    Regex für harmlose Zeilen (z. B. Audio im Container)
#   SKIP_SYNTAX=1   Einzeldatei-Syntaxcheck überspringen
#   STRICT=1        Warnungen (Lint/Format/fehlende Tests) werden zu Fehlern
#
# Exit-Code: 0 = PASS, 1 = FAIL, 2 = Setup-Problem.
# Letzte Ausgabezeile: "RESULT: PASS" oder "RESULT: FAIL".

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

GAME_DIR="${GAME_DIR:-game}"
LOG_DIR="${LOG_DIR:-.checks}"
GODOT_IMAGE="${GODOT_IMAGE:-barichello/godot-ci:4.3}"
BASE_REF="${BASE_REF:-main}"
BOOT_FRAMES="${BOOT_FRAMES:-120}"
STEP_TIMEOUT="${STEP_TIMEOUT:-180}"
ERR_REGEX="${ERR_REGEX:-SCRIPT ERROR|Parse Error|Compile Error|^ERROR:|Failed to load|Identifier .* not declared}"
IGNORE_REGEX="${IGNORE_REGEX:-ALSA|PulseAudio|audio driver|XDG_RUNTIME_DIR}"
STRICT="${STRICT:-0}"
SKIP_SYNTAX="${SKIP_SYNTAX:-0}"

FAST=0
CHANGED=0
NO_BOOT=0

for arg in "$@"; do
  case "$arg" in
    --fast) FAST=1 ;;
    --changed) CHANGED=1 ;;
    --no-boot) NO_BOOT=1 ;;
    -h|--help) sed -n '2,28p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 2 ;;
  esac
done

# ---------- Setup -------------------------------------------------------------

if [[ ! -f "$GAME_DIR/project.godot" ]]; then
  echo "SETUP-FEHLER: $GAME_DIR/project.godot nicht gefunden (GAME_DIR=$GAME_DIR)." >&2
  exit 2
fi

mkdir -p "$LOG_DIR"
: > "$LOG_DIR/summary.txt"

GODOT_CMD="${GODOT_BIN:-}"
if [[ -z "$GODOT_CMD" ]]; then
  for c in godot godot4 godot-4; do
    if command -v "$c" >/dev/null 2>&1; then GODOT_CMD="$c"; break; fi
  done
fi

USE_DOCKER=0
if [[ -z "$GODOT_CMD" ]]; then
  if command -v docker >/dev/null 2>&1; then
    USE_DOCKER=1
  else
    echo "SETUP-FEHLER: Weder godot im PATH noch docker gefunden. GODOT_BIN setzen oder Docker installieren." >&2
    exit 2
  fi
fi

TIMEOUT_CMD=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT_CMD="timeout $STEP_TIMEOUT"; fi

run_godot() {
  if [[ $USE_DOCKER -eq 1 ]]; then
    $TIMEOUT_CMD docker run --rm --network none -v "$ROOT":/work -w /work "$GODOT_IMAGE" godot "$@"
  else
    $TIMEOUT_CMD "$GODOT_CMD" "$@"
  fi
}

# ---------- Ergebnisverwaltung ------------------------------------------------

FAILS=0
WARNS=0

record() { # STATUS NAME [DETAIL]
  local status="$1" name="$2" detail="${3:-}"
  printf '%-5s %-22s %s\n' "$status" "$name" "$detail" | tee -a "$LOG_DIR/summary.txt"
}

pass() { record "PASS" "$1" "${2:-}"; }
skip() { record "SKIP" "$1" "${2:-}"; }
fail() { record "FAIL" "$1" "${2:-}"; FAILS=$((FAILS + 1)); }
soft() { # warn oder (STRICT) fail
  if [[ "$STRICT" == "1" ]]; then fail "$1" "${2:-}"; else record "WARN" "$1" "${2:-}"; WARNS=$((WARNS + 1)); fi
}

filter_errors() { # liest stdin, gibt Fehlerzeilen ohne harmlose aus
  if [[ -n "$IGNORE_REGEX" ]]; then
    grep -E "$ERR_REGEX" | grep -Ev "$IGNORE_REGEX"
  else
    grep -E "$ERR_REGEX"
  fi
}

# Godot-Schritt: Exit-Code UND Fehlerzeilen im Log auswerten
# (Godot meldet Skriptfehler im Headless-Modus teils mit Exit-Code 0).
godot_step() { # NAME ARGS...
  local name="$1"; shift
  local log="$LOG_DIR/${name}.log"
  run_godot "$@" >"$log" 2>&1
  local rc=$?
  local errs
  errs="$(filter_errors <"$log" | head -n 30 || true)"
  if [[ $rc -eq 124 ]]; then
    fail "$name" "Timeout nach ${STEP_TIMEOUT}s (Log: $log)"
    return 1
  elif [[ $rc -ne 0 || -n "$errs" ]]; then
    fail "$name" "exit=$rc (Log: $log)"
    [[ -n "$errs" ]] && printf '%s\n' "$errs" | sed 's/^/      /'
    return 1
  fi
  pass "$name"
  return 0
}

collect_gd_files() {
  if [[ $CHANGED -eq 1 ]]; then
    {
      git diff --name-only "${BASE_REF}...HEAD" 2>/dev/null
      git diff --name-only 2>/dev/null
      git diff --name-only --cached 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u | grep -E "^${GAME_DIR}/.*\.gd$" | grep -v '/addons/' | while read -r f; do
      [[ -f "$f" ]] && echo "$f"
    done
  else
    find "$GAME_DIR" -name '*.gd' -not -path '*/addons/*' -not -path '*/.godot/*' | sort
  fi
}

mapfile -t GD_FILES < <(collect_gd_files)

echo "== run_checks: $(date '+%Y-%m-%d %H:%M:%S') | Godot: $([[ $USE_DOCKER -eq 1 ]] && echo "docker:$GODOT_IMAGE" || echo "$GODOT_CMD") | .gd-Dateien: ${#GD_FILES[@]} =="

# ---------- 1) Import (erzeugt .godot-Cache, findet kaputte Ressourcen) -------

godot_step "import" --headless --path "$GAME_DIR" --import

# ---------- 2) Godot-3-Reste (statisch) ---------------------------------------

if [[ ${#GD_FILES[@]} -gt 0 ]]; then
  G3_PATTERN='^\s*onready\s|^\s*export\s*(\(|var)|\byield\s*\(|KinematicBody2D|KinematicBody\b|\.instance\(\)|\.connect\(\s*"|\bOS\.get_ticks_msec\b'
  G3_HITS="$(grep -nE "$G3_PATTERN" "${GD_FILES[@]}" 2>/dev/null | head -n 30 || true)"
  if [[ -n "$G3_HITS" ]]; then
    fail "godot3-syntax" "Godot-3-Konstrukte gefunden (Godot 4 verwenden, siehe AGENTS.md §4)"
    printf '%s\n' "$G3_HITS" | sed 's/^/      /'
  else
    pass "godot3-syntax"
  fi
else
  skip "godot3-syntax" "keine .gd-Dateien"
fi

# ---------- 3) Syntaxcheck je Script ------------------------------------------
# Hinweis: --check-only kennt Autoload-Namen teils nicht und kann dann
# "not declared"-Fehler melden. In dem Fall ist der Boot-Test (4) maßgeblich;
# Fehler bewusst prüfen und ggf. mit SKIP_SYNTAX=1 überbrücken.

if [[ "$SKIP_SYNTAX" == "1" ]]; then
  skip "gdscript-syntax" "SKIP_SYNTAX=1"
elif [[ ${#GD_FILES[@]} -eq 0 ]]; then
  skip "gdscript-syntax" "keine .gd-Dateien"
else
  syntax_fail=0
  : > "$LOG_DIR/syntax.log"
  for f in "${GD_FILES[@]}"; do
    res_path="res://${f#"$GAME_DIR"/}"
    out="$(run_godot --headless --path "$GAME_DIR" --check-only --script "$res_path" 2>&1)"
    rc=$?
    echo "--- $f (exit=$rc)" >> "$LOG_DIR/syntax.log"
    echo "$out" >> "$LOG_DIR/syntax.log"
    errs="$(printf '%s\n' "$out" | filter_errors | head -n 10 || true)"
    if [[ $rc -ne 0 || -n "$errs" ]]; then
      syntax_fail=1
      echo "      $f"
      [[ -n "$errs" ]] && printf '%s\n' "$errs" | sed 's/^/        /'
    fi
  done
  if [[ $syntax_fail -eq 1 ]]; then
    fail "gdscript-syntax" "Fehler in .gd-Dateien (Log: $LOG_DIR/syntax.log)"
  else
    pass "gdscript-syntax" "${#GD_FILES[@]} Dateien"
  fi
fi

# ---------- 4) Headless-Start -------------------------------------------------

if [[ $NO_BOOT -eq 1 ]]; then
  skip "headless-boot" "--no-boot"
else
  godot_step "headless-boot" --headless --path "$GAME_DIR" --quit-after "$BOOT_FRAMES"
fi

# ---------- 5) Tests ----------------------------------------------------------

if [[ $FAST -eq 1 ]]; then
  skip "tests" "--fast"
elif [[ -f "$GAME_DIR/addons/gut/gut_cmdln.gd" ]]; then
  godot_step "tests-gut" --headless --path "$GAME_DIR" -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
elif [[ -f "$GAME_DIR/addons/gdUnit4/bin/GdUnitCmdTool.gd" ]]; then
  godot_step "tests-gdunit4" --headless --path "$GAME_DIR" -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
else
  soft "tests" "kein Test-Framework (GUT/gdUnit4) in $GAME_DIR/addons gefunden"
fi

# ---------- 6) Format und Lint (gdtoolkit, optional) --------------------------

if [[ ${#GD_FILES[@]} -eq 0 ]]; then
  skip "gdformat" "keine .gd-Dateien"
  skip "gdlint" "keine .gd-Dateien"
else
  if command -v gdformat >/dev/null 2>&1; then
    if gdformat --check "${GD_FILES[@]}" >"$LOG_DIR/gdformat.log" 2>&1; then
      pass "gdformat"
    else
      soft "gdformat" "Formatierung abweichend: 'gdformat <datei>' ausführen (Log: $LOG_DIR/gdformat.log)"
    fi
  else
    skip "gdformat" "gdtoolkit nicht installiert"
  fi

  if command -v gdlint >/dev/null 2>&1; then
    if gdlint "${GD_FILES[@]}" >"$LOG_DIR/gdlint.log" 2>&1; then
      pass "gdlint"
    else
      soft "gdlint" "Lint-Hinweise (Log: $LOG_DIR/gdlint.log)"
      head -n 15 "$LOG_DIR/gdlint.log" | sed 's/^/      /'
    fi
  else
    skip "gdlint" "gdtoolkit nicht installiert"
  fi
fi

# ---------- Ergebnis ----------------------------------------------------------

echo "== Zusammenfassung: $FAILS Fehler, $WARNS Warnungen (Logs: $LOG_DIR/) =="
if [[ $FAILS -eq 0 ]]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL"
  exit 1
fi
