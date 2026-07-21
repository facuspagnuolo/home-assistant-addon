#!/bin/sh
set -eu

OPTIONS_FILE="/data/options.json"
RATHOLE_CONFIG="/data/rathole-client.toml"
TARGET="homeassistant:8123"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

[ -f "$OPTIONS_FILE" ] || fail "Options file not found: $OPTIONS_FILE"
jq -e 'type == "object"' "$OPTIONS_FILE" >/dev/null 2>&1 \
    || fail "Options file must contain a valid JSON object"

for option in server_address unit_id token log_level; do
    jq -e --arg option "$option" 'has($option)' "$OPTIONS_FILE" >/dev/null \
        || fail "Missing required option: $option"
done

jq -e '.server_address | type == "string" and length > 0' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid server_address: expected a non-empty host:port string"
jq -e '
    .server_address
    | capture("^([^[:space:]:]+|\\[[0-9A-Fa-f:.]+\\]):(?<port>[0-9]{1,5})$")
    | (.port | tonumber) as $port
    | $port >= 1 and $port <= 65535
' "$OPTIONS_FILE" >/dev/null 2>&1 \
    || fail "Invalid server_address: expected host:port with a port from 1 to 65535"

jq -e '.unit_id | type == "string" and test("^[a-zA-Z0-9_-]+$")' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid unit_id: only a-z, A-Z, 0-9, - and _ are allowed"
jq -e '.token | type == "string" and length > 0' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid token: it must be a non-empty string"
jq -e '.log_level | type == "string" and IN("error", "warn", "info", "debug", "trace")' "$OPTIONS_FILE" >/dev/null \
    || fail "Invalid log_level: expected error, warn, info, debug or trace"

SERVER_ADDRESS=$(jq -r '.server_address' "$OPTIONS_FILE")
UNIT_ID=$(jq -r '.unit_id' "$OPTIONS_FILE")
TOKEN=$(jq -r '.token' "$OPTIONS_FILE")
LOG_LEVEL=$(jq -r '.log_level' "$OPTIONS_FILE")

SERVER_TOML=$(jq -nr --arg value "$SERVER_ADDRESS" '$value | tojson')
TOKEN_TOML=$(jq -nr --arg value "$TOKEN" '$value | tojson')

umask 077
{
    printf '[client]\n'
    printf 'remote_addr = %s\n\n' "$SERVER_TOML"
    printf '[client.services.%s]\n' "$UNIT_ID"
    printf 'token = %s\n' "$TOKEN_TOML"
    printf 'local_addr = "%s"\n' "$TARGET"
} > "$RATHOLE_CONFIG"

printf 'Starting Annika Connector\n'
printf 'Unit: %s\n' "$UNIT_ID"
printf 'Server: %s\n' "$SERVER_ADDRESS"
printf 'Target: %s\n' "$TARGET"

export RUST_LOG="$LOG_LEVEL"
exec /usr/local/bin/rathole --client "$RATHOLE_CONFIG"
