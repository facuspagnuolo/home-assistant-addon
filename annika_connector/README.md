# Annika Connector

Minimal add-on that creates an outbound tunnel from Home Assistant to the
Annika Gateway using the `rathole` v0.5.0 client. The tunnel points to the
internal service `homeassistant:8123`; it does not publish any ports or
modify the Home Assistant configuration.

## Installation

1. Publish this repository at a Git URL reachable by Home Assistant.
2. In Home Assistant, open **Settings → Add-ons → Add-on Store**.
3. Open the menu in the top-right corner, choose **Repositories**, paste the
   repository URL and save.
4. Search for **Annika Connector** in the store and install it.

## Configuration and usage

In the add-on's **Configuration** tab, enter:

```yaml
unit_id: "unit-123"
log_level: "info"
```

`unit_id` is the id of the unit as registered in the Annika Backend, and may
only contain ASCII letters, digits, hyphens and underscores.

Save the configuration and select **Start**. On startup, the add-on calls the
Annika Gateway (`https://gateway.annikagroup.com/connectors/register`) with
its `unit_id` and, once the Gateway confirms the connector is registered and
active, generates its own `rathole-client.toml` from the response and starts
the tunnel. No server address or token needs to be configured by hand — the
Gateway assigns and hands them over automatically.

To check the connection, open the add-on's **Log** tab. The process reports
the unit, the registration attempts, the server and the target, but it never
prints the token.

This repository implements only the client. The registration, provisioning,
and `rathole` server side of the tunnel live in the `gateway` and `backend`
repositories.
