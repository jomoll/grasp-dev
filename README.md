# skill-agent-dev-min

Self-improving LLM agent experiments on FHIR medical benchmarks. Two benchmarks are included:

| Benchmark | Task | Dev | Val | Test |
|---|---|---|---|---|
| `MedAgentBench/` | FHIR reads/writes against a live FHIR server (10 clinical task types, v1 data) | 126 | 84 | 90 |
| `MedAgentBench-v2/` | Harder FHIR tasks — multi-step decision trees, time-window reasoning, coordinated writes (10 redesigned task types) | 126 | 84 | 90 |

Six learning methods are provided per benchmark:

| Method | Config prefix | Description |
|---|---|---|
| `skill_cycle` | `skill_cycle_*` | Skill writing from failure traces, probe-scored acceptance gate |
| `memory_cycle` | `memory_cycle_*` | Sequential flat correction notes after each failure |
| `batch_memory_cycle` | `batch_memory_cycle_*` | Batch-cadence flat correction notes |
| `evo_memory_cycle` | `evo_memory_cycle_*` | Retrieved episodic + semantic memory with utility tracking |
| `expel_cycle` | `expel_cycle_*` | ExpeL-style rule extraction from successful trajectories |
| `skillx_cycle` | `skillx_cycle_*` | SkillX functional skill extraction with plan rewriting |

Each method has three config variants:

| Suffix | Model | API |
|---|---|---|
| `_gpt41` | `gpt-4.1` | Azure Chat Completions via LiteLLM |
| `_gpt54mini` | `gpt-5.4-mini` | Azure Responses API (reasoning, low effort + low verbosity) |
| `_gpt54nano` | `gpt-5.4-nano` | Azure Responses API (reasoning, low effort + low verbosity) |

---

## Prerequisites

- Python 3.9
- Docker (for the FHIR server)
- Azure OpenAI access

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

See each benchmark's README for Docker setup and run commands:

- [MedAgentBench/README.md](MedAgentBench/README.md)
- [MedAgentBench-v2/README.md](MedAgentBench-v2/README.md)
