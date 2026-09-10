# Client exports

These files port the routing intent in [`../shadowrocket.conf`](../shadowrocket.conf)
to clients with different rule, DNS, and remote-resource models. None contains
nodes or a real subscription URL.

| Client | File | Recorded checks | Open proof gap |
|---|---|---|---|
| mihomo 1.19.30 | [`clash/config.yaml`](clash/config.yaml) | YAML load, startup, 25 provider downloads and parses | Behavior after merging a real subscription |
| Surge 5+ | [`surge/Surge.conf`](surge/Surge.conf) | Static policy and source checks | Native import and live routing |
| Quantumult X | [`quantumultx/QuantumultX.conf`](quantumultx/QuantumultX.conf) | Static policy/source checks | Native import, population, and live routing |

## Import

The mihomo file is a merge fragment. Merge its `proxy-groups`,
`rule-providers`, and `rules` into the profile that supplies `proxies:` or
`proxy-providers:`. Empty groups are expected before a subscription is merged.

In Surge, replace the `PROXY = select, REJECT` placeholder with named proxies
or a subscription policy before testing proxy behavior. Quantumult X nodes
must be present in its Server tab so the built-in `proxy` candidate can select
one.

Surge regional groups include proxies declared in `[Proxy]` and nodes imported
through `PROXY` (for example with `policy-path`), then filter by node name.
See [Surge's policy inclusion rules](https://manual.nssurge.com/policy-groups/policy-including.html).
The placeholder itself rejects traffic, and a region without matching
nodes remains unusable. A country label does not verify an exit IP.

Every service selector offers `DIRECT` for local access, including Hong Kong.
Siri starts on `DIRECT`; PCC, international TikTok, and all AI provider selectors
start on `PROXY` (`proxy` in Quantumult X), matching the base profile. Configure
that proxy for the service you need; no US node is required. This does not
automatically switch settings when you travel.

## Parity and exceptions

The exports use the canonical policy groups `🤖 OpenAI`, `🧠 Claude`,
`💎 Google AI`, `🧑‍💻 GitHub Copilot`, `🪟 Microsoft Copilot`, `🖱️ Cursor`,
`🔍 Perplexity`, `𝕏 xAI / Grok`, `🤗 Hugging Face`, `🏄 Windsurf`,
`🧠 JetBrains AI`, `💻 Developer Services`, and separate streaming groups for
`▶️ YouTube`, `🎬 Netflix`, `🏰 Disney+`, `📦 Prime Video`, `📺 HBO`, and
`🐉 Bahamut`. Shared dependencies stay outside provider AI selectors.

Apple selectors are separate: `📲 Apple App Downloads`, `🍏 Apple Updates`,
`🗣️ Siri & Search`, `🧠 Apple PCC`, `🔔 Apple Push`, `🔐 Apple Account`, and
the broad `🍎 Apple Services`. The App Downloads policy is distinct from the
optional Shadowrocket Kingsoft CDN host alias; exports omit that independent
alias.

The exports do not enable ad or tracker rejection. China rules force direct
access in the exports; Shadowrocket's `back-to-cn` behavior is a separate
travel module. QUIC, IPv6, private-answer handling, HTTPDNS blocking, and
real-IP exceptions vary by client.

Quantumult X DoH endpoints are configured for concurrent resolver selection,
not as a guaranteed primary/fallback chain. The exports use the privacy DNS
default. On mainland networks, use the documented AliDNS/DNSPod substitutions
in [`../docs/troubleshooting.md`](../docs/troubleshooting.md) where the client
supports them.

For mihomo and Surge, replace the two profile DoH endpoints with
`https://dns.alidns.com/dns-query` and `https://doh.pub/dns-query`, keeping each
client's existing syntax. In Quantumult X, replace the single `doh-server`
line with both URLs separated by a comma. Test on the destination network.

See [`../docs/policy-matrix.md`](../docs/policy-matrix.md) for explicit outcomes
and the still-missing native runtime evidence, and
[`../docs/maintenance.md`](../docs/maintenance.md) for parity and test records.

Vendor references: [mihomo rule providers](https://wiki.metacubex.one/en/config/rule-providers/),
[mihomo proxy groups](https://wiki.metacubex.one/en/config/proxy-groups/),
[Surge rule sets](https://manual.nssurge.com/rules/ruleset.html), and
[Quantumult X sample configuration](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf).

## Optional modules and security DNS

The new bulk-download, HK/TW/JP streaming, and diagnostics overlays are
Shadowrocket modules. They are not enabled in these exports. The AI provider
routes are included in every export. Port an optional overlay only when using
it, with the target client's syntax and policies; do not import `.module`
files into other clients as if they were native resources.

For the security-DNS equivalent, replace the standard Cloudflare DoH URL in
Surge's `encrypted-dns-server`, Quantumult X's `doh-server`, or mihomo's
`dns.nameserver` with `https://security.cloudflare-dns.com/dns-query`, retaining
`https://dns.quad9.net/dns-query` as the other encrypted resolver. Remove any
other unfiltered resolver from the active answer pool. Preserve native
bootstrap settings needed to resolve the DoH hostname; bootstrap is distinct
from the resolver answering application queries. These are manual DNS
substitutions, not an automatically enabled security profile. Check the
client's effective resolver configuration after import.
