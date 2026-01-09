# Guzzoline - Token Efficiency Plugin

> "Who controls the guzzoline, controls the waste!"

Guzzoline is a Gas Town plugin for token conservation. It introduces headless polecat mode, token accounting, and model tiering to reduce costs without sacrificing quality.

## Features

### 1. Headless Polecat Mode

Polecats in headless mode output ONLY:
- Git diffs (unified format)
- Bead state updates
- Exit signals

No explanations. No summaries. No reasoning. Pure execution.

**Token savings**: 70-80% reduction vs interactive mode

### 2. Token Accounting

Every agent session records token usage in `.events.jsonl`:

```json
{
  "type": "done",
  "actor": "citadel/furiosa",
  "payload": {
    "tokens": {
      "input": 12400,
      "output": 2100,
      "cache_read": 8200,
      "total": 14500
    }
  }
}
```

### 3. Model Tiering

| Agent Type | Model | Rationale |
|------------|-------|-----------|
| polecat | Sonnet | Design, debug, complex reasoning |
| polecat-headless | Haiku | Mechanical code gen |
| witness | Haiku | Patrol loops, git ops |
| refinery | Haiku | Merge queue processing |

## Usage

### Triggering Headless Mode

Option 1: Use the headless formula directly
```bash
gt sling <issue> <rig> --formula mol-polecat-headless
```

Option 2: Label your issue
```bash
bd update <issue> --labels headless
```

Option 3: Issue title patterns (auto-detected)
- `refactor*`
- `rename*`
- `update*imports*`
- `fix*typo*`

### Token Budget Enforcement

Configure in `plugin.yaml`:

```yaml
config:
  token_budget:
    polecat: 50000
    polecat-headless: 10000
```

Agents exceeding budget are automatically killed.

### Viewing Token Stats

```bash
# Recent sessions
gt costs summary

# Per-agent breakdown
gt costs breakdown --rig citadel

# Token trends
gt costs trend --days 7
```

## Installation

Already installed at `~/gt/plugins/guzzoline/`.

To activate headless formulas:
```bash
cp plugins/guzzoline/formulas/*.toml .beads/formulas/
```

## The Guzzoline Philosophy

In the wasteland, fuel is life. Every drop wasted is a drop that could have powered the war rig further.

Same with tokens:
- **Stop when done** - No polishing, no summaries after `gt done`
- **Right-size the model** - Haiku for mechanical work
- **Minimize context** - Only load what's needed
- **Account for everything** - What gets measured gets managed

Witness me, shiny and chrome... and token-efficient.
