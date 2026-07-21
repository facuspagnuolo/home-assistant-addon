# Annika Connector

Minimal add-on that creates an outbound tunnel from Home Assistant to a
remote server using the `rathole` v0.5.0 client. The tunnel points to the
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
server_address: "example.com:2333"
unit_id: "unit-123"
token: "replace-with-the-server-token"
log_level: "info"
```

`unit_id` must match the service name configured on the `rathole` server and
may only contain ASCII letters, digits, hyphens and underscores. The token is
required and must match the one configured for the remote service.

Save the configuration and select **Start**. To check the connection, open
the add-on's **Log** tab. The process reports the unit, the server and the
target, but it never prints the token.

This repository implements only the client. The `rathole` server and its
corresponding service must already exist.

## Server configuration

The `rathole` service must listen on all interfaces **inside the
container**, so Docker can publish the port:

```toml
[server.services.casa-facu]
token = "SECRET"
bind_addr = "0.0.0.0:18123"
```

The tunnel port must be published only on the EC2's loopback interface. In
Docker Compose:

```yaml
ports:
  - "2333:2333"
  - "127.0.0.1:18123:18123"
```

This way, `2333` receives connections from clients over the internet, and
the Home Assistant service becomes reachable at `127.0.0.1:18123` on the EC2
instance, without exposing that port publicly. A gateway running in another
container must share the Docker network with `rathole` and connect to the
service name on port `18123`; it must not use the EC2's loopback address.
