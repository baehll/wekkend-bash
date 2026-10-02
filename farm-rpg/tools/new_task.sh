#!/usr/bin/env bash
# Legt einen neuen Task aus tasks/TEMPLATE.md an.
# Nutzung: tools/new_task.sh "Titel" [S|M]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

TITLE="${1:?Titel fehlt. Nutzung: tools/new_task.sh \"Titel\" [S|M]}"
LEVEL="${2:-S}"
[[ "$LEVEL" == "S" || "$LEVEL" == "M" ]] || { echo "Stufe muss S oder M sein (L erst zerlegen)." >&2; exit 2; }

LAST="$( { ls tasks/active tasks/done 2>/dev/null | grep -oE 'TASK-[0-9]{4}' | sort -u | tail -n1 | grep -oE '[0-9]{4}'; } || true )"
NEXT="$(printf '%04d' $((10#${LAST:-0} + 1)))"

SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g; s/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40)"
FILE="tasks/active/TASK-${NEXT}-${SLUG}.md"

content="$(cat tasks/TEMPLATE.md)"
content="${content//TASK-XXXX/TASK-${NEXT}}"
content="${content//<Titel>/${TITLE}}"
content="${content//Stufe: S|M/Stufe: ${LEVEL}}"
content="${content//task\/XXXX-<slug>/task/${NEXT}-${SLUG}}"
printf '%s\n' "$content" > "$FILE"

echo "$FILE"
