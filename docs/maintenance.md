# Maintenance

`shadowrocket.conf` is the source policy. Port its intent to each export using
that client's syntax. Preserve provider AI, narrow Apple, China, and final rule
order. Keep shared dependencies outside provider AI selectors and GitHub in
Developer Services, apart from the dedicated Copilot endpoints. The provenance
and scope of inline rules are recorded in [rule-sources.md](rule-sources.md).

Run:

```sh
ruby scripts/validate_configs.rb
ruby scripts/test_config_validation.rb
ruby scripts/validate_soul_module.rb
ruby scripts/audit_remote_sources.rb --self-test
```

To check a stack, pass module names in top-to-bottom order, for example
`ruby scripts/validate_configs.rb adblock-core privacy-dns apple-account apple-services`.
This rejects conflicting variants, Aggressive without Core, broad Apple rules
above narrow ones, and travel rules above rejection/Soul rules. The CDN alias
has no rule-order constraint. This checks your proposed stack, not the installed
device state. Regression checks exercise valid stacks, rejected combinations,
and isolated config mutations without editing the working configs.

The checker also rejects combining Security DNS with either other DNS variant,
requires blocking modules before the optional download/streaming/diagnostics
overlays, and puts those overlays above broad travel rules. Hostname cases
check provider routes across all four formats, source-rule parity, shared-host
exclusions, download/API boundaries, and Fast.com's diagnostics exclusion.
These offline cases check explicit domain rules and their placement, not the
contents of every remote list or native DNS/IP matching.

For a proposed source update, save old and new decoded payloads locally and run:

```sh
ruby scripts/audit_remote_sources.rb --compare old.list new.list
```

The comparison prints additions/removals and flags new keywords, regexes,
wildcards, whole TLDs, ASNs, shared service/CDN scopes, client-specific rules,
and changes to the relative order of retained rules. A flagged comparison
exits unsuccessfully for manual review. It never changes a pin or approves a
source. Unflagged lines still require ownership and scope review. Binary
providers require decoded text comparison plus native loading.

Then run `ruby scripts/audit_remote_sources.rb` and each target client long
enough to parse providers. The weekly `audit-sources` workflow catches upstream
removals and unexpected content changes between edits. Repository sources are
pinned; review and update the commit IDs deliberately. The Aggressive anti-AD
feed remains mutable. Static checks alone do not date a client as verified.

Blackmatrix's split lists need both `RULE-SET` and `DOMAIN-SET` entries at the
same pinned revision and policy. See the upstream
[Advertising instructions](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Shadowrocket/Advertising/README.md)
and [Surge Apple instructions](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Surge/Apple/README.md).
Advertising already includes Privacy. Don't add it again to Core.

The remote audit excludes comments and the profile's self-update URL. It
rejects redirects, empty/HTML responses, malformed rule/domain lines, invalid
YAML payloads, and missing domain companions. These are format checks, not full
client parsers. Binary sources get signature checks where available,
not a full decode; their output says `binary-unparsed`. Native loading is a
separate check. Domain ownership also needs review: `ai.com` is no longer an
OpenAI route in these profiles; see its [current site](https://ai.com/).
The domain-file check follows [Surge's domain-list format](https://manual.nssurge.com/rules/domain.html).

Record native tests with client/version, OS/device, network/date, source URL
and full commit ID, enabled modules, selected groups, and sanitized observations
for direct, proxy, reject, final, DNS, Apple, streaming, and client-specific
exceptions. Remove tokens, private node names, and account identifiers.

When adding a group or module, update the root module index, export policy maps,
and behavior matrix. Keep a pinned rollback URL and local copy of the last
tested profile.

## Recorded check: 2026-09-10

Local config/Soul checks and remote-audit self-tests passed. The live audit
fetched 114 sources through the workstation's configured HTTP proxy. The
unchanged-profile syntax check passed with mihomo 1.19.30 on macOS arm64.
A scratch startup downloaded all 25 providers without logged parse errors;
only listener bindings changed (mixed port disabled, DNS on an ephemeral
loopback port). No proxy subscription or TUN was enabled for that check.
Shadowrocket, Surge, Quantumult X, and Soul still need device/session tests.

A follow-up pass aligned all exported AI defaults with the US-first base,
added stack-order/dependency checks and 19 validator regression cases, and
checked rule/domain text shapes. Those checks, the 114-source audit, and a
mihomo syntax check passed on the revised files. This follow-up did not repeat
the provider startup test; provider URLs are unchanged.


## Research implementation check: 2026-09-10

Added eight AI/coding selectors and their reviewed domain rules to the base
and all three exports. Added optional bulk downloads, HK/TW/JP streaming,
security DNS, and diagnostics modules, with conflict and precedence checks.
The four optional modules are Shadowrocket-only; native export substitutions
for security DNS are documented separately.

All config checks, 34 validator regression cases, Soul checks and remote-audit
self-tests passed. The live audit fetched the same 114 remote sources; new
routing domains are inline and added no subscriptions. mihomo 1.19.30 passed
its native syntax check on the updated export. No new provider startup,
installed-profile import, account login, or playback proof is claimed here.

An independent review found a gap in the source-comparison scope gate for
shared subdomains such as S3 and Azure storage. The gate now checks nested
shared suffixes and has a CLI regression case for them. Cloudflare Security
DNS and Quad9 both returned valid DNS-wireformat answers for `example.org`
from the workstation. That confirms endpoint reachability, not native module
activation or a threat-blocking test.
