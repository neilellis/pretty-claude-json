#!/usr/bin/env bash
# pretty_claude.sh – colour/indent-aware formatter for Claude raw JSON.
# deps: bash 3.2+, jq 1.5+

set -euo pipefail
IFS=$'\n\t'
trap 'exit 0' PIPE   # ignore EPIPE

### ── colour setup ──────────────────────────────────────────────
if tput colors &>/dev/null; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  CYAN=$(tput setaf 6); YEL=$(tput setaf 3); MAG=$(tput setaf 5)
  GRN=$(tput setaf 2); RED=$(tput setaf 1); BLU=$(tput setaf 4)
else
  BOLD=""; DIM=""; RESET=""; CYAN=""; YEL=""; MAG=""; GRN=""; RED=""; BLU=""
fi
HR="$(printf '%*s' "${COLUMNS:-80}" '' | tr ' ' '─')"

### ── helpers ───────────────────────────────────────────────────
wrap() {
  fold -s -w "${COLUMNS:-80}" |
  sed 's/$/\r/'
}

### ── main loop ─────────────────────────────────────────────────
while IFS= read -r line; do
  [[ -z $line ]] && continue

  # Skip non-JSON lines
  if ! jq -e . <<<"$line" &>/dev/null; then
    echo "$line" | wrap
    continue
  fi

  # Only handle JSON objects (not strings, arrays, etc.)
  if ! jq -e 'type=="object"' <<<"$line" &>/dev/null; then
    echo "$line" | jq --color-output . | wrap
    continue
  fi

  # Parse object types
  # Claude message envelope
  if jq -e 'has("message") and (.message|type=="object")' <<<"$line" &>/dev/null; then
    jq -r --arg HR "$HR" --arg B "$BOLD" --arg D "$DIM" --arg R "$RESET" \
          --arg CY "$CYAN" --arg YE "$YEL" --arg GR "$GRN" --arg RE "$RED" \
    '
      .message as $m |
      ($CY + $HR + $R),
      ($B + "Role    ▸ " + ($m.role // "unknown") + $R),
      ($B + "Model   ▸ " + ($m.model // "unknown") + $R),

      # Handle different message types based on the envelope type, not message type
      (if .type == "system" then
        "🔧 SYSTEM session=" + ((.session // .session_id // "unknown") | tostring)
      elif .type == "result" then
        "✅ RESULT: " + (.result // "no result")
      else
        # Handle message content
        ($m.content[]? |
          if .type == "thinking" then
            "💭" + ((.thinking // "") | tostring | split("\n")[] | "   " + .)
          elif .type == "tool_use" then
            "🛠  Tool Call: " + (.name // "<unknown>") +
            (if .input then
              "\n   ↳ Input: " + (.input | tostring)
            else
              ""
            end)
          elif .type == "tool_result" then
            "🔧 " +
            (if .content then
              ((.content | tostring) | split("\n")[] | "   " + .)
            else
              " (no content)"
            end)
          elif .type == "text" then
            "💬 " + ((.text // "") | tostring | split("\n")[] | "   " + .)
          else
            "🔹 " + .type + ":\n" + ((. | tostring) | split("\n")[] | "   " + .)
          end
        )
      end),

      # Usage stats if available
      (if $m.usage then
        "\n📊 Usage: " +
        "in=" + ($m.usage.input_tokens // 0 | tostring) +
        ", out=" + ($m.usage.output_tokens // 0 | tostring) +
        (if $m.usage.cache_creation_input_tokens and ($m.usage.cache_creation_input_tokens > 0) then
          ", cache.new=" + ($m.usage.cache_creation_input_tokens | tostring)
        else
          ""
        end) +
        (if $m.usage.cache_read_input_tokens and ($m.usage.cache_read_input_tokens > 0) then
          ", cache.read=" + ($m.usage.cache_read_input_tokens | tostring)
        else
          ""
        end)
      else
        ""
      end),
      ""
    ' <<<"$line" | wrap

  # Top-level system record OR result record
  elif jq -e 'has("type") and (.type=="system" or .type=="result")' <<<"$line" &>/dev/null; then
    jq -r --arg HR "$HR" --arg B "$BOLD" --arg R "$RESET" \
          --arg CY "$CYAN" --arg YE "$YEL" --arg GR "$GRN" --arg MA "$MAG" \
    '
      ($CY + $HR + $R),
      (if .type == "system" then
        ($B + "🔧 SYSTEM" + $R)
      else
        ($B + "🏁 RESULT" + $R)
      end),
      (if .session_id then ($YE + "Session ▸ " + (.session_id | tostring) + $R) else "" end),
      (if .cwd then ($GR + "CWD     ▸ " + .cwd + $R) else "" end),
      (if .tools then ($GR + "Tools   ▸ " + (.tools | join(", ")) + $R) else "" end),
      (if .subtype then ($YE + "Subtype ▸ " + .subtype + $R) else "" end),
      (if .result then ($MA + "Output  ▸ " + (.result | tostring) + $R) else "" end),
      (if .duration_ms then ($GR + "Time    ▸ " + (.duration_ms | tostring) + "ms" + $R) else "" end),
      (if .total_cost_usd then ($MA + "Cost    ▸ $" + (.total_cost_usd | tostring) + $R) else "" end),
      ""
    ' <<<"$line" | wrap

  else
    # Generic pretty-print for other objects
    echo "$line" | jq --color-output . | wrap
  fi

done
