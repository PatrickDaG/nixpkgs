# Firezone Server {#module-services-firezone-server}

[Firezone](https://www.firezone.dev/) is a self-hosted WireGuard-based VPN and firewall platform.

## Token generation {#module-services-firezone-server-token-generation}

The Firezone NixOS module provides a `firezone-generate-token` script for
generating authentication tokens for relays, gateways, and headless clients.
The script is installed system-wide via `environment.systemPackages` when the
module is enabled.

Relay token generation has been removed from the Firezone web interface, making
this script the only way to create relay tokens. Gateway and client tokens can
still be created through the admin panel, but the script is provided as a
convenience for automation and headless deployments.

### Usage {#module-services-firezone-server-token-generation-usage}

The script has three subcommands:

```shell
# Generate a relay token (global, not account-specific)
firezone-generate-token relay

# Generate a gateway token for a specific account and site
firezone-generate-token gateway <account-slug> <site-name>

# Generate a client token for a specific account and actor
firezone-generate-token client <account-slug> <actor-name>
```

The token is printed to stdout. To save it to a file:

```shell
firezone-generate-token relay > /var/lib/firezone-relay/token
firezone-generate-token gateway main my-site > /var/lib/firezone-gateway/token
firezone-generate-token client main my-service-account > /var/lib/firezone-client/token
```

### How it works {#module-services-firezone-server-token-generation-how-it-works}

The script calls into the running Firezone portal via its internal API to
generate a token and persist it to the database. It must be run on the host
where the Firezone server (portal) service is running.

### Typical deployment pattern {#module-services-firezone-server-token-generation-deployment}

1. Run `firezone-generate-token` on the portal host to create a token.
2. Store the output in a file accessible to the target component.
3. Point the component's `tokenFile` option at that file.

For example, to provision a relay:

```shell
firezone-generate-token relay > /var/lib/firezone-relay/token
```

Then in the relay's NixOS configuration:

```nix
{
  services.firezone.relay.tokenFile = "/var/lib/firezone-relay/token";
}
```
