# skill-agent-dev-min

Self-improving LLM agent experiments on FHIR medical benchmarks. Two benchmarks are required; a third is optional.

| Benchmark | Task | Dev | Val | Test | Setup |
|---|---|---|---|---|---|
| `MedAgentBench/` | FHIR reads/writes against a live FHIR server (10 clinical task types, v1 data) | 126 | 84 | 90 | Docker |
| `MedAgentBench-v2/` | Harder FHIR tasks — multi-step decision trees, time-window reasoning, coordinated writes (10 redesigned task types) | 126 | 84 | 90 | Docker |
| `FHIR-AgentBench/` *(optional)* | QA over real MIMIC-IV patient data via Google Cloud Healthcare FHIR API | — | — | — | GCP account required |

FHIR-AgentBench is optional — if you have a GCP account it is straightforward to set up (see [FHIR-AgentBench/README.md](FHIR-AgentBench/README.md)); if not, running MedAgentBench and MedAgentBench-v2 is all that is needed.

Six learning methods are provided per benchmark:

| Method | Config prefix | Description |
|---|---|---|
| `skill_cycle` | `skill_cycle_*` | Skill writing from failure traces, probe-scored acceptance gate |
| `memory_cycle` | `memory_cycle_*` | Sequential flat correction notes after each failure |
| `batch_memory_cycle` | `batch_memory_cycle_*` | Batch-cadence flat correction notes |
| `evo_memory_cycle` | `evo_memory_cycle_*` | Retrieved episodic + semantic memory with utility tracking |
| `expel_cycle` | `expel_cycle_*` | ExpeL-style rule extraction from successful trajectories |
| `skillx_cycle` | `skillx_cycle_*` | SkillX functional skill extraction with plan rewriting |

For MedAgentBench and MedAgentBench-v2, each method has three config variants:

| Suffix | Model | API |
|---|---|---|
| `_gpt41` | `gpt-4.1` | Azure Chat Completions via LiteLLM |
| `_gpt54mini` | `gpt-5.4-mini` | Azure Responses API (reasoning, low effort + low verbosity) |
| `_gpt54nano` | `gpt-5.4-nano` | Azure Responses API (reasoning, low effort + low verbosity) |

FHIR-AgentBench follows the same three-variant pattern using the same Azure credentials.

---

## Prerequisites

- Python 3.9
- Docker (for the MedAgentBench FHIR server)
- Azure OpenAI access
- *(FHIR-AgentBench only)* GCP account with Cloud Healthcare API enabled and `gcloud` CLI authenticated — see [FHIR-AgentBench/README.md](FHIR-AgentBench/README.md) for step-by-step instructions

## Environment variables

```bash
# GPT-4.1 (Chat Completions via LiteLLM)
export AZURE_OPENAI_API_KEY="..."
export AZURE_API_BASE="https://YOUR-RESOURCE-NAME.openai.azure.com"
export AZURE_API_VERSION="2024-12-01-preview"

# GPT-5.4-mini / GPT-5.4-nano (Responses API — base_url set per config)
export AZURE_OPENAI_API_KEY="..."   # same key, picked up automatically
```

Then edit the `base_url` in each `_gpt54mini` / `_gpt54nano` config to your Azure resource name:
```yaml
base_url: "https://YOUR-RESOURCE-NAME.openai.azure.com/openai/v1/"
```

## Quick start

See each benchmark's README for setup and run commands:

- [MedAgentBench/README.md](MedAgentBench/README.md)
- [MedAgentBench-v2/README.md](MedAgentBench-v2/README.md)
- [FHIR-AgentBench/README.md](FHIR-AgentBench/README.md) *(optional — requires GCP)*

---

## Collaboration

We can share results by committing `outputs/` back via pull request.

### One-time setup

1. Fork this repository.
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/skill-agent-dev-min.git
   cd skill-agent-dev-min
   ```
3. Follow the setup instructions in the benchmark READMEs (conda environment, Docker).
4. Set your Azure credentials:
   ```bash
   export AZURE_OPENAI_API_KEY="..."
   export AZURE_API_BASE="https://YOUR-RESOURCE-NAME.openai.azure.com"   # for GPT-4.1
   export AZURE_API_VERSION="2024-12-01-preview"
   ```
   Edit the `base_url` field in each `_gpt54mini` / `_gpt54nano` config to your resource name.

### Running experiments

In each benchmark directory, start the task worker in one terminal and the learning cycle in another — see the respective README for exact commands. Test set evaluation runs automatically when each cycle finishes; results land in `<run-dir>/test_eval_best/`, `<run-dir>/test_eval_final/`, and `<run-dir>/test_eval_baseline/` (no-skill baseline).

For FHIR-AgentBench, run `python skill_cycle.py --config configs/skill_cycle_gpt41.yaml` (no separate task worker needed). If you don't have a GCP account, skip this benchmark entirely — it is optional.

### Sharing results

Commit your `outputs/` directories and open a pull request against `main`:

```bash
git checkout -b results/<your-name>
git add MedAgentBench/outputs/ MedAgentBench-v2/outputs/
# If you ran FHIR-AgentBench, include it too:
# git add FHIR-AgentBench/outputs/
git commit -m "Add experiment results: <model(s)>, <benchmark(s)>"
git push -u origin results/<your-name>
# Then open a PR on GitHub
```

What to include:

| Path | Required | Notes |
|---|---|---|
| `outputs/<method>/<run>/val_scores.json` | yes | val learning curve |
| `outputs/<method>/<run>/test_eval_best/` | yes | held-out test score, best checkpoint |
| `outputs/<method>/<run>/test_eval_final/` | yes | held-out test score, final epoch |
| `outputs/<method>/<run>/test_eval_baseline/` | yes | held-out test score, no-skill baseline |
| `outputs/<method>/<run>/skills/` | yes | learned skills — needed for transferability experiments |
| `outputs/<method>/<run>/run.log` | optional | full training log |
| `outputs/<method>/<run>/epoch_*/` | optional | per-epoch dev/val traces |
