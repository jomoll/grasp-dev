# MedAgentBench

FHIR medical records benchmark (v1, 10 clinical task types). Agents read and write FHIR resources against a live FHIR server hosted in Docker.

## Setup

```bash
conda create -n medagentbench python=3.9
conda activate medagentbench
pip install -r requirements.txt
```

Pull and start the FHIR server:
**Terminal 1 — fhir server (keep running for all experiments, only need one for both datasets):**

```bash
docker pull jyxsu6/medagentbench:latest
docker tag jyxsu6/medagentbench:latest medagentbench
docker run -p 8080:8080 medagentbench
```

Wait until the console shows "Started Application in XXX seconds", then verify at `http://localhost:8080/`.

Generate data splits (one-time, splits are already included but can be regenerated):

```bash
python data/medagentbench/split_dataset.py
```

## Environment variables

```bash
# GPT-4.1
export AZURE_OPENAI_API_KEY="..."
export AZURE_API_BASE="https://YOUR-RESOURCE-NAME.openai.azure.com"
export AZURE_API_VERSION="2024-12-01-preview"

# GPT-5.4-mini / GPT-5.4-nano — same key; also edit base_url in each config:
#   base_url: "https://YOUR-RESOURCE-NAME.openai.azure.com/openai/v1/"
```

## Running experiments

Start the task worker in one terminal, then run the learning cycle in another.

**Terminal 2 — task worker (keep running for all experiments):**

```bash
conda activate medagentbench
python -m src.start_task -a --config configs/start_task.yaml
```

**Terminal 3 — learning cycle:**

Run all six cycle types for one model with the helper script at the repo root:

```bash
conda activate medagentbench
./run_all.sh gpt41         # or gpt54mini / gpt54nano
```

Alternatively, run individual cycles by hand:

```bash
conda activate medagentbench

# skill_cycle
python -m src.skill_cycle --config configs/skill_cycle_gpt41.yaml      --run-name run_001
python -m src.skill_cycle --config configs/skill_cycle_gpt54mini.yaml   --run-name run_001
python -m src.skill_cycle --config configs/skill_cycle_gpt54nano.yaml   --run-name run_001

# memory_cycle
python -m src.memory_cycle --config configs/memory_cycle_gpt41.yaml     --run-name run_001
python -m src.memory_cycle --config configs/memory_cycle_gpt54mini.yaml --run-name run_001
python -m src.memory_cycle --config configs/memory_cycle_gpt54nano.yaml --run-name run_001

# batch_memory_cycle
python -m src.batch_memory_cycle --config configs/batch_memory_cycle_gpt41.yaml      --run-name run_001
python -m src.batch_memory_cycle --config configs/batch_memory_cycle_gpt54mini.yaml  --run-name run_001
python -m src.batch_memory_cycle --config configs/batch_memory_cycle_gpt54nano.yaml  --run-name run_001

# evo_memory_cycle
python -m src.evo_memory_cycle --config configs/evo_memory_cycle_gpt41.yaml      --run-name run_001
python -m src.evo_memory_cycle --config configs/evo_memory_cycle_gpt54mini.yaml  --run-name run_001
python -m src.evo_memory_cycle --config configs/evo_memory_cycle_gpt54nano.yaml  --run-name run_001

# expel_cycle
python -m src.expel_cycle --config configs/expel_cycle_gpt41.yaml      --run-name run_001
python -m src.expel_cycle --config configs/expel_cycle_gpt54mini.yaml  --run-name run_001
python -m src.expel_cycle --config configs/expel_cycle_gpt54nano.yaml  --run-name run_001

# skillx_cycle
python -m src.skillx_cycle --config configs/skillx_cycle_gpt41.yaml      --run-name run_001
python -m src.skillx_cycle --config configs/skillx_cycle_gpt54mini.yaml  --run-name run_001
python -m src.skillx_cycle --config configs/skillx_cycle_gpt54nano.yaml  --run-name run_001
```

**Resuming an interrupted run:**

If a run is interrupted (API timeout, machine restart, etc.), resume it with the same `--run-name` and add `--resume`. Completed epochs and dev batches are skipped automatically.

```bash
python -m src.skill_cycle --config configs/skill_cycle_gpt41.yaml --run-name run_001 --resume
```

The `--resume` flag works identically for all six cycle types.

## Test set evaluation

Test set evaluation runs **automatically** at the end of every cycle using the best-val checkpoint. Both test splits are evaluated. Results are written directly into the run directory:

```
outputs/<method>/<run-name>/
├── test_eval_best/          # OOD test (tasks 6, 7), best-val checkpoint
│   ├── test_runs.jsonl      # per-sample correctness
│   └── test_score.json      # {split, score, n_correct, n_total}
├── test_eval_baseline/      # OOD test, no-skill/no-memory baseline
│   ├── test_runs.jsonl
│   └── test_score.json
├── id_test_eval_best/       # in-dist test, best-val checkpoint
│   ├── test_runs.jsonl
│   └── test_score.json
├── id_test_eval_baseline/   # in-dist test, no-skill/no-memory baseline
│   ├── test_runs.jsonl
│   └── test_score.json
└── test_scores.json         # summary of all four evaluations
```

To run a standalone evaluation manually (e.g. for the base agent or a custom skill directory):

```bash
# Base agent (no learned skills)
python -m src.run_eval --config configs/skill_cycle_gpt41.yaml --split test --run-name base_test

# Best skills from a completed run
python -m src.run_eval --config configs/skill_cycle_gpt41.yaml --split test \
    --skills-dir outputs/skill_cycle_gpt41/run_001/skills/best --run-name run_001_best_test
```

The task worker must be running for both automatic and manual evaluation.

## Data splits

| Split | Samples | Description |
|---|---|---|
| dev | 96 | Skill learning (12 per in-dist task type — tasks 1–5, 8, 9, 10) |
| val | 80 | Monitoring during training (10 per in-dist task type) |
| id_test | 64 | In-distribution held-out evaluation (8 per in-dist task type) |
| test | 60 | OOD held-out evaluation (tasks 6, 7 — 30 per type) |

## Output structure

```
outputs/
└── skill_cycle_gpt41/
    └── run_001/
        ├── run.log
        ├── val_scores.json
        ├── test_eval_best/       # OOD test, best-val checkpoint
        │   ├── test_runs.jsonl
        │   └── test_score.json
        ├── test_eval_baseline/   # OOD test, no-skill baseline
        │   ├── test_runs.jsonl
        │   └── test_score.json
        ├── id_test_eval_best/    # in-dist test, best-val checkpoint
        │   ├── test_runs.jsonl
        │   └── test_score.json
        ├── id_test_eval_baseline/ # in-dist test, no-skill baseline
        │   ├── test_runs.jsonl
        │   └── test_score.json
        ├── test_scores.json      # summary of all four evaluations
        └── skills/
            ├── learned/        # current skill library
            └── best/           # best checkpoint by val score
```
