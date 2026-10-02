#!/usr/bin/env bash
# Führt einen Task mit aider aus (gedacht für den agent-Container).
# Nutzung: tools/agent_task.sh TASK-0001 [weitere aider-Optionen]
# Modell/Endpoint kommen aus den Umgebungsvariablen AIDER_MODEL und OLLAMA_API_BASE.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ID="${1:?Task-ID fehlt, z. B. TASK-0001}"
shift || true

TASK_FILE="$(ls tasks/active/"${ID}"-*.md tasks/active/"${ID}".md 2>/dev/null | head -n1 || true)"
[[ -n "$TASK_FILE" && -f "$TASK_FILE" ]] || { echo "Task $ID nicht in tasks/active/ gefunden." >&2; exit 2; }

BASE="$(basename "$TASK_FILE" .md)"
BRANCH="task/${BASE#TASK-}"

# Pfade aus Abschnitten des Task-Files lesen
section() { awk -v s="$1" '$0 ~ "^## " s {f=1; next} /^## /{f=0} f' "$TASK_FILE"; }
paths()   { grep -oE '[A-Za-z0-9_./-]+\.(gd|tscn|tres|md|json|cfg)' | sort -u; }

READ_ARGS=(--read AGENTS.md --read docs/CONVENTIONS.md --read docs/ARCHITECTURE.md)
while read -r p; do
  case "$p" in AGENTS.md|docs/CONVENTIONS.md|docs/ARCHITECTURE.md) continue ;; esac
  [[ -n "$p" && -f "$p" ]] && READ_ARGS+=(--read "$p")
done < <(section "Kontext-Dateien" | paths)

FILE_ARGS=()
while read -r p; do
  [[ -n "$p" ]] && { mkdir -p "$(dirname "$p")"; FILE_ARGS+=(--file "$p"); }
done < <(section "Änderungen" | paths)

[[ ${#FILE_ARGS[@]} -gt 0 ]] || { echo "Keine Dateien im Abschnitt 'Änderungen' erkannt." >&2; exit 2; }

git switch "$BRANCH" 2>/dev/null || git switch -c "$BRANCH"
echo "== $BASE auf Branch $BRANCH | Modell: ${AIDER_MODEL:-<nicht gesetzt>} =="

aider \
  --yes-always \
  --no-show-model-warnings \
  --map-tokens 0 \
  --auto-test \
  --test-cmd "tools/run_checks.sh --changed --fast" \
  "${READ_ARGS[@]}" "${FILE_ARGS[@]}" \
  --message-file "$TASK_FILE" \
  "$@" && AIDER_RC=0 || AIDER_RC=$?

echo "== Abschlusslauf: vollständige Checks =="
mkdir -p .checks
set +e
tools/run_checks.sh 2>&1 | tee .checks/last_result.txt
CHECK_RC=${PIPESTATUS[0]}
exit $(( AIDER_RC != 0 ? AIDER_RC : CHECK_RC ))
