#!/bin/bash
# tests/shellcheck.sh — Roda ShellCheck em todos os scripts do projeto
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

echo "=== QXDC ShellCheck ==="
echo ""

for f in $(find "$SCRIPT_DIR" -name "*.sh" -not -path "*/tests/*" -not -path "*/.git/*" | sort); do
    relative="${f#$SCRIPT_DIR/}"
    if shellcheck -S warning "$f" 2>/dev/null; then
        echo "  OK  $relative"
    else
        echo "  ERR $relative"
        ((ERRORS++))
    fi
done

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "Todos os scripts passaram."
    exit 0
else
    echo "$ERRORS script(s) com problemas."
    exit 1
fi
