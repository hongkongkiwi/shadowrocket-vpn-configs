# Client exports

These files port the routing intent in `../shadowrocket.conf` to other proxy
clients. They are hand-maintained because mihomo, Surge, and Quantumult X do
not share one policy or remote-resource format.

None of the exports contains a node or a real subscription URL.

> [!NOTE]
> The 2026-09-10 repair pass cleared the known static and provider failures.
> Surge and Quantumult X still need native import tests. mihomo still needs a
> real merged subscription before its routing behavior can be proven.

| Client | Proven | Not yet proven |
|---|---|---|
| mihomo 1.19.30 | YAML load, process startup, 27 provider downloads and parses | Behavior with a real merged node subscription |
| Surge 5+ | Static comparison with current vendor docs | Native import, policy resolution, runtime routing |
| Quantumult X | Static comparison, local policy checks, remote source checks | Native import, regional population, runtime routing |

## mihomo / Clash Meta

File: [`clash/config.yaml`](clash/config.yaml)

Use this as a merge fragment with the profile that supplies your nodes. Adding
it as a separate profile does not combine its rules with another profile's
proxies. The `PROXY` and regional groups use `include-all`, so they populate
only after the final merged profile contains proxies or proxy providers.

Use your client's merge or mixin feature, or merge the YAML top-level sections
yourself. The final rendered profile must contain `proxies:` or
`proxy-providers:` alongside this file's `proxy-groups:`, `rule-providers:`,
and `rules:` sections. Inspect the rendered profile; do not assume two profile
cards are combined.

Current check result:

- Ruby's YAML parser accepts the file.
- mihomo 1.19.30 accepts the structure, starts, downloads all 27 providers, and
  reports no provider parse errors. The VPSDance source now declares
  `format: yaml`.
- DNS listens on `127.0.0.1:1053`. Plain IP resolvers sit under
  `default-nameserver` only to bootstrap the DoH hostname; ordinary queries use
  the configured DoH resolvers.
- The profile has no nodes by itself, so empty groups fall back to mihomo's
  `COMPATIBLE` behavior.
- The Taiwan selector no longer matches the mainland China flag.

After merging, test with the same mihomo build your GUI ships. A standalone
`mihomo -t` check does not fetch providers, so run the profile long enough to
catch remote parse warnings.

## Surge 5+

File: [`surge/Surge.conf`](surge/Surge.conf)

The `PROXY = select, DIRECT` line is a safe placeholder. Replace `DIRECT` with
named proxies or a `policy-path=...` subscription before expecting traffic to
use a tunnel.

Current check result:

- Rule targets match declared policy-group names exactly.
- The dead Apple Push source is gone. The remaining Apple lists already cover
  APNs domains and Apple's `17.0.0.0/8` range.
- Apple Account has its own manual policy. Certificate checks that Apple marks
  as unsuitable for proxies go direct.
- Apple service exceptions use the selectable Apple policy instead of mixing
  hard-coded direct and proxy paths.
- The Kingsoft App Store host alias is absent because exports cannot toggle it
  independently.
- With the untouched `DIRECT` placeholder, every group that selects `PROXY`
  connects directly.
- The Taiwan selector no longer matches the mainland China flag.

Use Surge's profile checker after replacing the subscription. Then inspect the
rule log for one request in each policy group; a profile that imports can still
route through the wrong group.

## Quantumult X

File: [`quantumultx/QuantumultX.conf`](quantumultx/QuantumultX.conf)

Nodes added in Quantumult X's Server tab appear through the built-in `proxy`
candidate. Remote blackmatrix7 filters carry a policy name on every rule; use
`force-policy=` when the file's policy is not defined locally.

Current check result:

- Regional groups use `url-latency-benchmark=` with the vendor sample's
  hyphenated parameter names.
- Advertising and Privacy force `reject`. Lan and ChinaMax force `direct`.
- OneDrive and Prime Video now have policies and remote filters.
- Apple Account has a separate policy and explicit authentication rules.
- Apple certificate checks go direct; the other explicit Apple rules use the
  Apple policy.
- DoH is enabled. Quantumult X ignores the ordinary `server` entries for normal
  queries while an unscoped `doh-server` is active.
- Excluded routes have explicit CIDR masks.
- The Taiwan selector no longer matches the mainland China flag.

Do not call this export validated until Quantumult X imports it without errors,
all regional groups populate, and the request log proves direct, proxy, reject,
and final behavior.

## Parity rules

“Same rules” means matching user intent, not copying line order blindly.

When `shadowrocket.conf` changes:

1. Add or rename equivalent policy groups in every export.
2. Preserve first-match behavior around reject, Apple, China, and final rules.
3. Use a native rule source for each client and inspect its embedded policy.
4. Reproduce DNS and QUIC behavior only where the target client supports it.
5. Record what the export omits instead of claiming identical coverage.
6. Run the target client, fetch every remote resource, and inspect its logs.

Useful vendor references:

- [mihomo rule providers](https://wiki.metacubex.one/en/config/rule-providers/)
- [mihomo proxy groups](https://wiki.metacubex.one/en/config/proxy-groups/)
- [Surge rule sets](https://manual.nssurge.com/rules/ruleset.html)
- [Quantumult X sample configuration](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)
