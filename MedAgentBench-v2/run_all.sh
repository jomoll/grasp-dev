#!/usr/bin/env bash
# Usage: ./run_all.sh <model>
#   model: gpt41 | gpt54mini | gpt54nano
set -euo pipefail

MODEL="${1:-}"
if [[ -z "$MODEL" ]]; then
    echo "Usage: $0 <model>  (gpt41 | gpt54mini | gpt54nano)" >&2
    exit 1
fi

cd "$(dirname "$0")"

for config in configs/*_cycle_${MODEL}.yaml; do
    [[ -e "$config" ]] || { echo "No configs matched for model '$MODEL'"; exit 1; }
    base="$(basename "$config" .yaml)"
    module="${base%_*}"
    echo ""
    echo "--- $config ---"
    python -m "src.$module" --config "$config" --resume
done
