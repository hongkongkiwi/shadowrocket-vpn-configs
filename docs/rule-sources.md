# Rule sources and review record

Reviewed on 2026-09-10. `shadowrocket.conf` owns the policy; the three exports
port that intent. Inline rules below are maintained locally, so an upstream
edit does not silently change them. Comments that link to an upstream are
evidence references, not active subscriptions.

| Source family | Current revision | Use and lineage |
|---|---|---|
| Repcz/Tool | `b3c22feb3add856128c4a7f5353c06bb6ee8e31f` | Shadowrocket service rules and LAN ranges |
| blackmatrix7/ios_rule_script | `4112f8e7b3a9f23c9ccf381beaa5931a36df3781` | Service, Apple, China and blocking categories; native export formats |
| MetaCubeX/meta-rules-dat | `a1985d26a15f217dfd539e789c19a6d49f78b624` | mihomo binary domain/IP providers |
| carrnot/china-domain-list | `d13f21bc3c047664c9f5fda5d2a3c7d608df3d46` | Optional all-China travel domains |
| anti-AD | Mutable `https://anti-ad.net/surge.txt` | Aggressive ad-blocking module only |

Blackmatrix's [Proxy inputs](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Shadowrocket/Proxy/README.md)
already include ACL4SSR, Loyalsoldier and Hackl0us. Its
[Advertising inputs](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Shadowrocket/Advertising/README.md)
also aggregate other blocklists. Treat shared inputs as one lineage when
assessing coverage. Adding every source again creates overlap.

## Inline provider routes

The new AI domains were checked against
[v2fly's provider files](https://github.com/v2fly/domain-list-community/tree/5d939545c84e2a534f8e85ba6ffb2b51fa18fb76/data)
(`github-copilot`, `cursor`, `perplexity`, `xai`, `huggingface`, `windsurf`,
`jetbrains-ai`, and `category-ai-!cn`), the official
[GitHub Copilot allowlist](https://docs.github.com/en/copilot/reference/copilot-allowlist-reference),
and [Cursor's network requirements](https://prod.cursor.com/docs/enterprise/network-configuration).
The v2fly `include:` format is not imported as a Shadowrocket RULE-SET.

Provider-owned suffixes and exact dedicated tenant hosts are permitted.
Whole shared cloud suffixes, all of `api.github.com`, general Microsoft login
hosts, telemetry-only dependencies, and whole ASNs are excluded. Shared API
paths on one hostname cannot receive different routes through a domain rule.
Keep those hosts in their existing service policy rather than enabling MITM.

## Optional routing modules

The bulk-download and regional-streaming modules use small reviewed subsets
of the factual host inventories published at [Sukka's rule index](https://ruleset.skk.moe/).
Their domains are written inline; these modules do not subscribe to or claim
compatibility with Sukka's Surge modules. Original upstream lists declare
AGPL-3.0; retain the source attribution when redistributing derived material.

| Examined payload | SHA-256 of reviewed snapshot |
|---|---|
| `List/domainset/download.conf` | `9c85f095e6e6cf2bf7111fc428d289236b9c5a433a1078b94fc33e96e9609f35` |
| `List/domainset/game-download.conf` | `3a31ec975e1d0a1d0ee588c249f3cd84c77943576f8081c682a7170fcc4ccfcd` |
| `List/non_ip/stream_hk.conf` | `7893cb28a7e5f5cea8a122445e3331c98227c18cd2e7ca8282ddbde2705176e4` |
| `List/non_ip/stream_tw.conf` | `c3abeaed7b3783c55de5f7e8a718112f8fa477e919b3d7beaef6174433306025` |
| `List/non_ip/stream_jp.conf` | `ad79821bb7d7c381e28f8b6972d487218a6176b87f60671901d9e2473f5c3645` |

Bulk downloads exclude general Steam APIs/community, Apple hosts and package
websites. Registries can carry both metadata and assets on the same hostname.
Regional streaming excludes shared Brightcove/CDN hosts. The diagnostics
module includes only the reviewed Ookla suffixes; arbitrary ISP-owned test
servers are outside that scope. See [recipes](recipes.md) for the operating
limits and precedence of each module.

Security DNS follows [Cloudflare's encrypted Families endpoints](https://developers.cloudflare.com/1.1.1.1/setup/#1111-for-families)
and [Quad9's secured resolver](https://docs.quad9.net/services/).
This is an alternative resolver policy, independent of advertising lists.

## Updating a source

Fetch the current pinned and proposed payloads to separate local files. Use
`ruby scripts/audit_remote_sources.rb --compare OLD_FILE NEW_FILE` before
changing a pin. This prints added and removed rules and exits unsuccessfully
when additions contain known broad or client-specific scopes. Review the
flagged lines; there is no automatic approval or pin-writing step.

Suffixes nested beneath known shared hosts are also flagged, including S3
and Azure storage service subdomains. An exact dedicated tenant hostname
does not trigger this suffix check. Review its ownership separately.

A clean comparison is not an ownership or safety guarantee. Inspect all
deletions, order changes, provider-specific tenant names and false-positive
reports. Compare decoded text equivalents for binary providers, then load the
binary with the native client. Update this record, the inline rules where
applicable, and all affected exports together. Run the checks in
[maintenance](maintenance.md), including the hostname-policy regressions.
