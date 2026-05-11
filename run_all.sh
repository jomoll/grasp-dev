#!/usr/bin/env bash
# Usage: ./run_all.sh <model>
#   model: gpt41 | gpt54mini | gpt54nano
set -euo pipefail

MODEL="${1:-}"
if [[ -z "$MODEL" ]]; then
    echo "Usage: $0 <model>  (gpt41 | gpt54mini | gpt54nano)" >&2
    exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"

run_med_bench() {
    local repo="$1"
    echo ""
    echo "========================================"
    echo "  Repo: $repo  |  model: $MODEL"
    echo "========================================"
    cd "$ROOT/$repo"
    for config in configs/*_cycle_${MODEL}.yaml; do
        [[ -e "$config" ]] || { echo "No configs matched for model '$MODEL' in $repo"; break; }
        local base
        base="$(basename "$config" .yaml)"
        local module="${base%_*}"
        echo ""
        echo "--- $config ---"
        python -m "src.$module" --config "$config" --resume
    done
}

run_fhir_bench() {
    echo ""
    echo "========================================"
    echo "  Repo: FHIR-AgentBench  |  model: $MODEL"
    echo "========================================"
    cd "$ROOT/FHIR-AgentBench"
    for config in configs/*_cycle_${MODEL}.yaml; do
        [[ -e "$config" ]] || { echo "No configs matched for model '$MODEL' in FHIR-AgentBench"; break; }
        local base
        base="$(basename "$config" .yaml)"
        local module="${base%_*}"
        echo ""
        echo "--- $config ---"
        python "${module}.py" --config "$config" --resume
    done
}

run_med_bench "MedAgentBench"
run_med_bench "MedAgentBench-v2"
run_fhir_bench
