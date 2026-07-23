# Changelog

## 1.1.1

- Guard against an invalid connector assignment (missing `service`, `token`
  or `server`) coming from either a fresh registration or a saved state
  file. Instead of writing a broken `rathole-client.toml` and crashing on
  parse, the add-on now clears the saved state and fails with a clear error
  so the next restart registers from scratch.

## 1.1.0

- Persist the connector assignment (`service`, `token`, `server`) returned by
  the Gateway on first registration. On subsequent starts (add-on restart, HA
  reboot, etc.) the saved assignment is reused instead of registering again,
  which previously failed with a `409 Unit connector already active` and
  produced an invalid `rathole-client.toml`.

## 1.0.0

- Initial release.
