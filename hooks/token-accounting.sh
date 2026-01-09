#!/bin/bash
# Guzzoline Token Accounting Hook
# Runs on Stop to record token usage in events.jsonl
#
# This hook extracts token usage from the Claude session and
# appends it to the town's events log for analysis.

set -euo pipefail

TOWN_ROOT="${GT_TOWN_ROOT:-$HOME/gt}"
EVENTS_FILE="$TOWN_ROOT/.events.jsonl"

# Get actor from environment or derive from cwd
ACTOR="${GT_ACTOR:-unknown}"
RIG="${GT_RIG:-}"
SESSION_ID="${GT_SESSION_ID:-}"

# Try to get token info from Claude's cost recording
# This piggybacks on `gt costs record` which should have run
COSTS_FILE="$TOWN_ROOT/.gt/costs/sessions.jsonl"

if [[ -f "$COSTS_FILE" ]]; then
    # Get the most recent entry for this session
    LATEST=$(tail -1 "$COSTS_FILE" 2>/dev/null || echo "{}")

    # Extract token counts if available
    INPUT_TOKENS=$(echo "$LATEST" | jq -r '.input_tokens // 0' 2>/dev/null || echo "0")
    OUTPUT_TOKENS=$(echo "$LATEST" | jq -r '.output_tokens // 0' 2>/dev/null || echo "0")
    CACHE_READ=$(echo "$LATEST" | jq -r '.cache_read_tokens // 0' 2>/dev/null || echo "0")
    TOTAL=$((INPUT_TOKENS + OUTPUT_TOKENS))
else
    INPUT_TOKENS=0
    OUTPUT_TOKENS=0
    CACHE_READ=0
    TOTAL=0
fi

# Only record if we have actual token data
if [[ "$TOTAL" -gt 0 ]]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create the event entry
    EVENT=$(jq -n \
        --arg ts "$TIMESTAMP" \
        --arg actor "$ACTOR" \
        --arg rig "$RIG" \
        --arg session "$SESSION_ID" \
        --argjson input "$INPUT_TOKENS" \
        --argjson output "$OUTPUT_TOKENS" \
        --argjson cache "$CACHE_READ" \
        --argjson total "$TOTAL" \
        '{
            ts: $ts,
            source: "guzzoline",
            type: "token_usage",
            actor: $actor,
            payload: {
                rig: $rig,
                session_id: $session,
                tokens: {
                    input: $input,
                    output: $output,
                    cache_read: $cache,
                    total: $total
                }
            },
            visibility: "internal"
        }')

    echo "$EVENT" >> "$EVENTS_FILE"
fi

# Check budget enforcement
BUDGET_FILE="$TOWN_ROOT/plugins/guzzoline/config/budgets.json"
if [[ -f "$BUDGET_FILE" && "$TOTAL" -gt 0 ]]; then
    # Determine agent type from actor
    AGENT_TYPE="polecat"
    if [[ "$ACTOR" == *"witness"* ]]; then
        AGENT_TYPE="witness"
    elif [[ "$ACTOR" == *"refinery"* ]]; then
        AGENT_TYPE="refinery"
    elif [[ "$ACTOR" == *"headless"* ]]; then
        AGENT_TYPE="polecat-headless"
    fi

    BUDGET=$(jq -r ".$AGENT_TYPE // 0" "$BUDGET_FILE" 2>/dev/null || echo "0")

    if [[ "$BUDGET" -gt 0 && "$TOTAL" -gt "$BUDGET" ]]; then
        echo "GUZZOLINE WARNING: Token budget exceeded ($TOTAL > $BUDGET)" >&2
        # Log the overage
        OVERAGE_EVENT=$(jq -n \
            --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            --arg actor "$ACTOR" \
            --argjson total "$TOTAL" \
            --argjson budget "$BUDGET" \
            '{
                ts: $ts,
                source: "guzzoline",
                type: "budget_exceeded",
                actor: $actor,
                payload: {
                    total: $total,
                    budget: $budget,
                    overage: ($total - $budget)
                },
                visibility: "feed"
            }')
        echo "$OVERAGE_EVENT" >> "$EVENTS_FILE"
    fi
fi

exit 0
