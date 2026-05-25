# GRASP — reproduction code

Code and instructions to reproduce the experiments in the paper. GRASP is a
self-improvement method that learns a small, regression-gated **skill library**
from an agent's own failure traces. This repository contains the four benchmark
families used in the paper, each as a self-contained directory:

| Directory | Benchmark | Role in paper | Setup |
|---|---|---|---|
| `MedAgentBench/` | FHIR reads/writes against a live FHIR server | primary (clinical) | Docker |
| `MedAgentBench-v2/` | Harder FHIR tasks: multi-step decisions, coordinated writes | primary (clinical) | Docker |
| `FHIR-AgentBench/` | Structured clinical QA / tool use on an independent FHIR store | supporting (clinical) | GCP Healthcare API |
| `AgentBench/` | Four non-clinical environments: OS, DBBench, WebShop, ALFWorld | supporting (generality) | Docker |

## Methods

The paper compares GRASP against a no-skills baseline and five self-improvement
methods. All six learning methods are implemented in each benchmark directory.

| Code name | Paper name |
|---|---|
| `grasp` | **GRASP** (ours) |
| `memory_cycle` | Sequential memory |
| `batch_memory_cycle` | Batch memory |
| `expel_cycle` | ExpeL |
| `evo_memory_cycle` | Evo-MedAgent |
| `skillx_cycle` | SkillX |

The no-skills baseline is produced automatically by every run (`run_baseline: true`).
The four AgentBench environments are reported for GRASP vs. no-skills only.

## Model backends

The executing agent and skill-writer use the same model. Five backends from the
paper are selectable at run time — no model identity is baked into a config:

| Preset | Model (paper) | Provider |
|---|---|---|
| `gptoss` | gpt-oss-120b | self-hosted, OpenAI-compatible |
| `deepseek` | DeepSeek V4 Flash | self-hosted, OpenAI-compatible |
| `gemini` | Gemini 3.1 Flash Lite | Google Vertex AI |
| `gpt5` | GPT-5.4 (low) | Azure OpenAI (Responses API) |
| `gpt4` | GPT-4.1 | Azure OpenAI |
| `local` | any | generic OpenAI-compatible endpoint |

Select a backend per run with `--agent <preset>`, the `GRASP_BACKEND`
environment variable, or a config's `agent_preset:` field (precedence in that
order). Presets read endpoints, keys, and projects from environment variables;
**no secrets are stored in the repository**. Each benchmark has a
`configs/agents/README.md` listing the required variables.

```bash
# example: self-hosted gpt-oss-120b
export OSS_API_BASE="http://localhost:8000/v1"

# example: Gemini via Vertex
export GOOGLE_CLOUD_PROJECT="my-project"
gcloud auth application-default login

# example: GPT-4.1 / GPT-5.4 via Azure
export AZURE_API_KEY="..." AZURE_API_BASE="https://YOUR-RESOURCE.openai.azure.com" AZURE_API_VERSION="2024-12-01-preview"
export AZURE_OPENAI_API_KEY="..." AZURE_OPENAI_BASE_URL="https://YOUR-RESOURCE.openai.azure.com/openai/v1/"
```

## Running

Each directory has its own README with environment setup (conda, Docker, data)
and a `run_all.sh <backend> [run_name]` helper that runs all six methods for one
backend and seed:

```bash
# clinical benchmarks
cd MedAgentBench    && ./run_all.sh gptoss run_001
cd MedAgentBench-v2 && ./run_all.sh gptoss run_001
cd FHIR-AgentBench  && ./run_all.sh gptoss run_001   # requires GCP

# non-clinical environments (GRASP only, per paper)
cd AgentBench       && ./run_all.sh gptoss run_001
```

The trailing integer of `run_name` is the seed (`run_001` → seed 1); the paper
uses three seeds for proprietary models and five for open-source models. See
each benchmark's README for prerequisites and per-method commands.

- [MedAgentBench/README.md](MedAgentBench/README.md)
- [MedAgentBench-v2/README.md](MedAgentBench-v2/README.md)
- [FHIR-AgentBench/README.md](FHIR-AgentBench/README.md)
- [AgentBench/README.md](AgentBench/README.md)

## Released results

All numbers behind the paper are released under **[`results/`](results/)** — the
per-seed validation, test, and OOD accuracies for every cell of Tables 1–5, the
learned skill libraries, the frozen transfer libraries, and the run
configurations (prompts are in each benchmark's `src/`). Full agent traces are
omitted to keep the mirror small (~40 MB vs ~15 GB) and are available on request;
API keys, endpoints, and account identifiers in configs are redacted.

| Table | Where |
|---|---|
| 1 — Main results (5 models × 3 benchmarks × 6 methods) | `results/main/<model>/<benchmark>/<method>/run_00N/` |
| 2 — Cross-model transfer | `results/transfer/cross_model/`, `cross_benchmark/MedAgentBench/` |
| 3 — Cross-benchmark transfer | `results/transfer/cross_benchmark/` |
| 4 — Ablations | `results/ablations/<variant>/` |
| 5 — Non-medical AgentBench | `results/nonmedical/<env>/` |
| Learned & frozen skill libraries | `…/run_00N/skills/` and `results/transfer/libraries/` |
| App. — sensitivity, cross-writer | `results/sensitivity/`, `results/transfer/cross_writer/` |

Reproduce the headline tables straight from the released score files:

```bash
python results/reproduce_tables.py                 # Table 1 (all models) + Table 5
python results/reproduce_tables.py gpt-oss-120b     # one model
```

See [`results/README.md`](results/README.md) for the full directory↔cell map,
file formats, and notes on two cells built from a superseded seed set.
