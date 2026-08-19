# AI-Company Delivery Templates

A reusable, stdlib-first template library for the 20 entry-level software/AI
offerings defined in `entry-level-project-catalog.md`. Each template is a
standalone repo you can clone, configure with the client's keys, and ship in
1–6 days.

> Built as part of the company delivery pipeline (kanban task t_e443102a).
> These templates cover the bulk of catalog items #1–#20 with 3 composable
> bases plus AI scaffolding shared across all of them.

## Templates (3, each its own repo)

| Template            | Use for (catalog #)                                  | Stack |
|---------------------|------------------------------------------------------|-------|
| `flask-ai-agent`    | #1 FAQ Chatbot, #10 Email Triage, #15 Ticket Classifier, #20 RAG Assistant | Flask + shared AI client |
| `streamlit-data-app`| #6 Dashboard, #12 Expense Tracker, #13 Content Calendar, #14 Weekly Report | Streamlit + pandas |
| `python-automation` | #4 Invoice Reminder, #5 Scheduler, #7 Scraper, #17 Price Monitor, #18 Workflow Glue, #19 Email Sequence | stdlib + requests |

All three share `shared/ai_client.py` (copied into each repo as `ai_client.py`):
a provider-agnostic, feature-flagged AI wrapper.

## Shared AI integration scaffolding

`shared/ai_client.py` talks to **any OpenAI-compatible `/chat/completions`
endpoint** (OpenAI, Anthropic via proxy, Nous, Mistral, local vLLM). It is:

- **Stdlib-only** — `urllib` + `json`, no hard SDK dependency.
- **Feature-flagged** — `AI_ENABLED=false` => offline/mock mode, no network, no key.
- **Fail-safe** — never raises to the host app; returns an `AIResult`.

Set these env vars (all optional, sensible defaults):
```
AI_ENABLED=true          # false = offline rule-based mode
AI_API_KEY=sk-...
AI_BASE_URL=https://api.openai.com/v1
AI_MODEL=gpt-4o-mini
AI_TEMPERATURE=0.2
AI_MAX_TOKENS=1024
AI_TIMEOUT_SECS=30
```

## CI/CD

`shared/ci_configs/python-ci.yml` is the reusable GitHub Actions workflow
(lint + test + build on push/PR). It's copied into each template at
`.github/workflows/ci.yml`. CI runs with `AI_ENABLED=false` so tests pass
without secrets.

## Local verification

```bash
# each template
cd templates/flask-ai-agent
pip install -r requirements.txt
pytest -q
AI_ENABLED=false python app.py &   # health check on :5000
```

## Publishing to a GitHub org (one command)

`scripts/publish_to_github.sh <org-name>` creates one repo per template under
`<org-name>/*` and pushes them. **Requires `gh` authenticated**
(`gh auth login`). Until then, the templates live locally under `templates/`
and are ready to push:

```bash
./scripts/publish_to_github.sh acme-ai-delivery
```

## How to deliver a client project

1. Pick the template matching the catalog item.
2. `git clone` the template (or `publish_to_github.sh` then clone the new repo).
3. Replace sample logic with the client's data source / API keys.
4. Push → CI runs → deploy (Render/Fly/Docker per template README).
