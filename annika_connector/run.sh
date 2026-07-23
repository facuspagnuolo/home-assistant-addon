#!/bin/sh
set -eu

OPTIONS_FILE="/data/options.json"
STATE_FILE="/data/connector-state.json"
RATHOLE_CONFIG="/data/rathole-client.toml"
TARGET="homeassistant:8123"
GATEWAY_REGISTER_URL="https://gateway.annikagroup.com/connectors/register"
REGISTER_MAX_ATTEMPTS=10
REGISTER_RETRY_DELAY_SECONDS=5

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

[ -f "$OPTIONS_FILE" ] || fail "Options file not found: $OPTIONS_FILE"
jq -e 'type == "object"' "$OPTIONS_FILE" >/dev/null 2>&1 \
    || fail "Options file must contain a valid JSON object"

for option in unit_id log_level; do
    jq -e --arg option "$option" 'has($option)' "$OPTIONS_FILE" >/dev/null \
        || fail "Missing required option: $option"
done

jq -e '.unit_id | type == "string" and test("^[a-zA-Z0-9_-]+$")' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid unit_id: only a-z, A-Z, 0-9, - and _ are allowed"
jq -e '.log_level | type == "string" and IN("error", "warn", "info", "debug", "trace")' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid log_level: expected error, warn, info, debug or trace"

UNIT_ID=$(jq -r '.unit_id' "$OPTIONS_FILE")
LOG_LEVEL=$(jq -r '.log_level' "$OPTIONS_FILE")

printf 'Starting Annika Connector\n'
printf 'Unit: %s\n' "$UNIT_ID"

REGISTER_RESPONSE=""

if [ -f "$STATE_FILE" ] && printf '%s' "$(cat "$STATE_FILE")" | jq -e --arg unitId "$UNIT_ID" '
    type == "object"
    and .unit_id == $unitId
    and (.service | type == "string" and length > 0)
    and (.token | type == "string" and length > 0)
    and (.server | type == "string" and length > 0)
' >/dev/null 2>&1
then
    printf 'Reusing the connector assignment saved from a previous registration\n'
    REGISTER_RESPONSE=$(cat "$STATE_FILE")
else
    printf 'Registering with: %s\n' "$GATEWAY_REGISTER_URL"

    REGISTER_BODY=$(jq -nr --arg unitId "$UNIT_ID" '{unitId: $unitId} | tojson')

    attempt=1
    while [ "$attempt" -le "$REGISTER_MAX_ATTEMPTS" ]; do
        if REGISTER_RESPONSE=$(curl --fail --silent --show-error \
                --header 'Content-Type: application/json' \
                --data "$REGISTER_BODY" \
                "$GATEWAY_REGISTER_URL" 2>/dev/null) \
            && printf '%s' "$REGISTER_RESPONSE" | jq -e '
        type == "object"
        and (.service | type == "string" and length > 0)
        and (.token | type == "string" and length > 0)
        and (.server | type == "string" and length > 0)
    ' >/dev/null 2>&1
        then
            break
        fi

        printf 'Registration attempt %s/%s failed, retrying in %ss...\n' \
            "$attempt" "$REGISTER_MAX_ATTEMPTS" "$REGISTER_RETRY_DELAY_SECONDS"
        attempt=$((attempt + 1))
        sleep "$REGISTER_RETRY_DELAY_SECONDS"
    done

    printf '%s' "$REGISTER_RESPONSE" | jq -e '
        type == "object"
        and (.service | type == "string" and length > 0)
        and (.token | type == "string" and length > 0)
        and (.server | type == "string" and length > 0)
    ' >/dev/null 2>&1 \
        || fail "Could not register with the Annika Gateway after $REGISTER_MAX_ATTEMPTS attempts"

    umask 077
    printf '%s' "$REGISTER_RESPONSE" | jq --arg unitId "$UNIT_ID" '. + {unit_id: $unitId}' > "$STATE_FILE"
fi

SERVICE=$(printf '%s' "$REGISTER_RESPONSE" | jq -r '.service')
TOKEN=$(printf '%s' "$REGISTER_RESPONSE" | jq -r '.token')
SERVER_ADDRESS=$(printf '%s' "$REGISTER_RESPONSE" | jq -r '.server')

SERVER_TOML=$(jq -nr --arg value "$SERVER_ADDRESS" '$value | tojson')
TOKEN_TOML=$(jq -nr --arg value "$TOKEN" '$value | tojson')

umask 077
{
    printf '[client]\n'
    printf 'remote_addr = %s\n\n' "$SERVER_TOML"
    printf '[client.services.%s]\n' "$SERVICE"
    printf 'token = %s\n' "$TOKEN_TOML"
    printf 'local_addr = "%s"\n' "$TARGET"
} > "$RATHOLE_CONFIG"

printf 'Registered as service: %s\n' "$SERVICE"
printf 'Server: %s\n' "$SERVER_ADDRESS"
printf 'Target: %s\n' "$TARGET"

CONNECTOR_IP=$(
    ip -4 addr show scope global \
    | awk '/inet / {print $2}' \
    | cut -d/ -f1 \
    | head -n1
)

printf 'Connector IPv4: %s\n' "${CONNECTOR_IP:-unknown}"

HA_IP=$(getent hosts homeassistant 2>/dev/null | awk 'NR==1 {print $1}')

printf 'Home Assistant IP: %s\n' "${HA_IP:-unknown}"

if command -v ip >/dev/null 2>&1 && [ -n "${HA_IP:-}" ]; then
    printf 'Route to Home Assistant: %s\n' "$(ip route get "$HA_IP" 2>/dev/null || true)"
fi

export RUST_LOG="$LOG_LEVEL"
exec /usr/local/bin/rathole --client "$RATHOLE_CONFIG"
