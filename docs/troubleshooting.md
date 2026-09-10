# Troubleshooting and rollback

## Commit-pinned rollback

Choose a reviewed full commit ID, then use either URL:

```text
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/<COMMIT_SHA>/shadowrocket.conf
https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@<COMMIT_SHA>/shadowrocket.conf
```

Replace `<COMMIT_SHA>` with the 40-character ID. No current revision is
claimed here as verified. Keep a local copy before changing the installed
profile.

Use one DNS module. Privacy DNS is the general Hong Kong/travel option; Security DNS is its
threat-filtering alternative. AliDNS/DNSPod is the mainland substitution. Endpoints are selected
concurrently where supported, not as a guaranteed primary/fallback chain. If
the selected resolvers are blocked, disable the module for captive-portal login.

For client exports, use the [client-specific DNS substitutions](../exports/README.md#parity-and-exceptions).

For Apple failures, keep certificate checks direct, place narrow modules above
Services, hold one route fixed, and disable the Kingsoft alias first when App
Store downloads or sign-in fail. TLS decryption stays off.

Run `ruby scripts/audit_remote_sources.rb` to fetch every configured remote
rule/provider and report its size. Repository sources use full commit IDs.
Inspect the mutable anti-AD result and any deliberate pin update. HTTP 200
proves availability only.

macOS command-line Ruby does not automatically adopt System Settings' proxy.
If the browser works but the audit times out, pass your own local HTTP proxy
through `http_proxy` for that command. Use the actual port shown by your
client; don't publish a credential-bearing proxy URL.

Empty groups usually mean a merged subscription has no matching node names. A
mihomo syntax check does not fetch providers. A profile checker cannot prove
TUN, DNS, QUIC, or live routing.
