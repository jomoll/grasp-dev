# MedAgentBench

FHIR medical records benchmark (v1, 10 clinical task types). Agents read and write FHIR resources against a live FHIR server hosted in Docker.

## Setup

```bash
conda create -n medagentbench python=3.9
conda activate medagentbench
pip install -r requirements.txt
```

Pull and start the FHIR server:

```bash
docker pull jyxsu6/medagentbench:latest
docker tag jyxsu6/medagentbench:latest medagentbench
docker run -p 8080:8080 medagentbench
```

Wait until the console shows "Started Application in XXX seconds", then verify at `http://localhost:8080/`.

Download `refsol.py` into `src/server/tasks/medagentbench/refsol.py` from the [Stanford Box link](https://stanfordmedicine.box.com/s/fizv0unyjgkb1r3a83rfn5p3dc673uho).

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

**Terminal 1 — task worker (keep running for all experiments):**

```bash
conda activate medagentbench
python -m src.start_task -a --config configs/start_task.yaml
```

**Terminal 2 — learning cycle:**

Replace `<config>` with any config file from `configs/` and `<run-name>` with a unique name.

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

## Evaluating on the test set

After a skill_cycle run, evaluate the best learned skills on the held-out test set:

```bash
# Base agent (no learned skills)
python -m src.run_eval --config configs/skill_cycle_gpt41.yaml --split test --run-name base_test

# Best skills from a completed run
python -m src.run_eval --config configs/skill_cycle_gpt41.yaml --split test \
    --skills-dir outputs/skill_cycle_gpt41/run_001/skills/best --run-name run_001_best_test
```

The task worker must be running. Results are written to `outputs/eval/<run-name>/`:
- `test_runs.jsonl` — per-sample correctness
- `test_score.json` — summary `{split, score, n_correct, n_total}`

## Data splits

| Split | Samples | Description |
|---|---|---|
| dev | 126 | Skill learning (60% of tasks 1–5, 8, 9) |
| val | 84 | Monitoring during training (40% of tasks 1–5, 8, 9) |
| test | 90 | Held-out evaluation (tasks 6, 7, 10 — OOD) |

## Output structure

```
outputs/
└── skill_cycle_gpt41/
    └── run_001/
        ├── run.log
        ├── val_scores.json
        └── skills/
            ├── learned/    # current skill library
            └── best/       # best checkpoint by val score
```
