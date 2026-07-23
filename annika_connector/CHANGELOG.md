# Changelog

## 1.1.0

- Persist the connector assignment (`service`, `token`, `server`) returned by
  the Gateway on first registration. On subsequent starts (add-on restart, HA
  reboot, etc.) the saved assignment is reused instead of registering again,
  which previously failed with a `409 Unit connector already active` and
  produced an invalid `rathole-client.toml`.

## 1.0.0

- Initial release.
