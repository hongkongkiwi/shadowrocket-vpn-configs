# Shadowrocket VPN Configs

Hand-maintained routing policy for Shadowrocket, with ports for mihomo/Clash
Meta, Surge, and Quantumult X. This repository contains rules and remote list
references only. It contains no proxy nodes, subscription tokens, passwords,
certificates, or MITM private keys.

## Start here

1. Add your proxy subscription in Shadowrocket.
2. Import the profile for your current location:
   - [Hong Kong](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/hong-kong.conf): [`hong-kong.conf`](hong-kong.conf). Only AI and international TikTok default to a proxy. Everything else, including GitHub, streaming, gaming, and unmatched traffic, defaults to `DIRECT`. Includes Cloudflare/Quad9 DNS.
   - [Mainland China](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/mainland-china.conf): [`mainland-china.conf`](mainland-china.conf). Mainland and local destinations route directly; international services and unmatched traffic default to a proxy. Includes AliDNS/DNSPod DNS.
3. Import and order modules using [`docs/recipes.md`](docs/recipes.md).
4. Run `ruby scripts/validate_configs.rb` before sharing a profile.

Import both location profiles and select the one matching your current network.
Disable DNS modules when using them: each profile includes its own DNS settings.
Modules and saved selector choices can override these defaults. For the Hong Kong
AI/TikTok-only setup, leave `private-ip-block`, shared AI dependencies, bulk
downloads, return-to-China, Soul, and regional streaming overrides off.
Check selector choices after switching, particularly on an existing installation.
The old `shadowrocket.conf` URL remains available with its existing behavior;
it is the shared source used to generate both location profiles. Other client
exports retain their existing defaults and have not been split by location.
Hong Kong uses reviewed inline Claude, Google AI, and international TikTok rules
to avoid proxying unrelated services in their upstream lists. Shared CDN and
login hosts stay direct; add a narrow local override only for an observed failure.

For a module named `NAME`, import
`https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/NAME.module`.
The jsDelivr form is
`https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/<path>`.
For rollback, use a commit-pinned URL described in
[`docs/troubleshooting.md`](docs/troubleshooting.md).

## Documentation

- [`docs/recipes.md`](docs/recipes.md): ordered module recipes for Hong Kong,
  travel, mainland China, Apple Intelligence, back-to-China use, and recovery.
- [`docs/policy-matrix.md`](docs/policy-matrix.md): client behavior, exceptions,
  export gaps, and native-runtime proof status.
- [`docs/troubleshooting.md`](docs/troubleshooting.md): DNS, captive portal,
  Apple sign-in, rollback, and mutable-source checks.
- [`docs/maintenance.md`](docs/maintenance.md): source edits, parity work,
  validation, and native test records.
- [`exports/README.md`](exports/README.md): importing each client export.
- [`docs/rule-sources.md`](docs/rule-sources.md): source lineage and reviewed inline-rule boundaries.

## Module index

Modules run before the base profile. Import only what you need, then order
narrower rules above broader rules. This is the complete index for modules
currently in `modules/`; update it when a new module is added.

| Module | Purpose | Import |
|---|---|---|
| [`adblock-core`](modules/adblock-core.module) | Advertising and tracker rejection | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-core.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-core.module) |
| [`adblock-lite`](modules/adblock-lite.module) | Smaller advertising list | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-lite.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-lite.module) |
| [`adblock-aggressive`](modules/adblock-aggressive.module) | Extra mainland-focused ad list; add after Core | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-aggressive.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-aggressive.module) |
| [`ai-shared-dependencies`](modules/ai-shared-dependencies.module) | Optional shared login, payment, and telemetry routing for AI compatibility | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/ai-shared-dependencies.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/ai-shared-dependencies.module) |
| [`apple-account`](modules/apple-account.module) | Apple account authentication route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-account.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-account.module) |
| [`apple-app-downloads`](modules/apple-app-downloads.module) | App Store and Apple-hosted content route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-app-downloads.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-app-downloads.module) |
| [`apple-app-store-cdn`](modules/apple-app-store-cdn.module) | Optional Kingsoft alias for one App Store host | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-app-store-cdn.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-app-store-cdn.module) |
| [`apple-certificate-validation`](modules/apple-certificate-validation.module) | Direct certificate status checks | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-certificate-validation.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-certificate-validation.module) |
| [`apple-intelligence`](modules/apple-intelligence.module) | Apple Intelligence Extensions and Private Cloud Compute route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-intelligence.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-intelligence.module) |
| [`apple-push`](modules/apple-push.module) | APNs route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-push.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-push.module) |
| [`apple-services`](modules/apple-services.module) | Broad Apple and iCloud route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-services.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-services.module) |
| [`apple-siri-search`](modules/apple-siri-search.module) | Siri, dictation, and search route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-siri-search.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-siri-search.module) |
| [`apple-updates`](modules/apple-updates.module) | Apple update downloads | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-updates.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-updates.module) |
| [`back-to-cn`](modules/back-to-cn.module) | Selected mainland apps through a mainland exit | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/back-to-cn.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/back-to-cn.module) |
| [`back-to-cn-all`](modules/back-to-cn-all.module) | All China domains and IPs through a mainland exit | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/back-to-cn-all.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/back-to-cn-all.module) |
| [`bulk-downloads`](modules/bulk-downloads.module) | Selected game, package, and software downloads | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/bulk-downloads.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/bulk-downloads.module) |
| [`regional-streaming`](modules/regional-streaming.module) | Optional HK, TW, and JP streaming routes | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/regional-streaming.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/regional-streaming.module) |
| [`security-dns`](modules/security-dns.module) | Threat-filtering Cloudflare and Quad9 DoH; alternative to Privacy DNS | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/security-dns.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/security-dns.module) |
| [`network-diagnostics`](modules/network-diagnostics.module) | Selected Ookla hosts; Fast.com keeps its Netflix route | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/network-diagnostics.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/network-diagnostics.module) |
| [`china-app-tun-compat`](modules/china-app-tun-compat.module) | Optional mainland app TUN exclusions | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/china-app-tun-compat.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/china-app-tun-compat.module) |
| [`dns-mainland-china`](modules/dns-mainland-china.module) | AliDNS and DNSPod DoH for mainland networks | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/dns-mainland-china.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/dns-mainland-china.module) |
| [`httpdns-block`](modules/httpdns-block.module) | Reject known app HTTPDNS endpoints | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/httpdns-block.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/httpdns-block.module) |
| [`ipv6`](modules/ipv6.module) | Enable IPv6 without preferring it | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/ipv6.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/ipv6.module) |
| [`ipv6-preferred`](modules/ipv6-preferred.module) | Enable and prefer IPv6 | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/ipv6-preferred.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/ipv6-preferred.module) |
| [`privacy-dns`](modules/privacy-dns.module) | Cloudflare and Quad9 DoH | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/privacy-dns.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/privacy-dns.module) |
| [`private-ip-block`](modules/private-ip-block.module) | Proxy domains with unexpected private answers | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/private-ip-block.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/private-ip-block.module) |
| [`real-ip-compat`](modules/real-ip-compat.module) | Real DNS answers for selected clients and games | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/real-ip-compat.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/real-ip-compat.module) |
| [`quic-compat`](modules/quic-compat.module) | Disable proxied QUIC so clients retry over TCP | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/quic-compat.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/quic-compat.module) |
| [`soul-ktv`](modules/soul-ktv.module) | Optional Soul routing; leave disabled until a mainland node is configured. Defaults to REJECT. | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/soul-ktv.module) · [CDN](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/soul-ktv.module) |

Soul KTV has no mainland proxy configured yet. See
[`docs/soul-ktv.md`](docs/soul-ktv.md) for setup, scope, and remaining tests.
CDN copies can lag behind GitHub after publication; use Raw for the newest version.

The base profile has no ad or tracker block, no blanket Direct rule list, and
no port 22 bypass. It keeps local and captive-portal access in `skip-proxy`,
uses `FINAL` for unmatched traffic, and leaves strict DNS, private-answer
handling, and real-IP exceptions optional.

## Validation status

On 2026-09-10, the local checks passed for policy references, module boundaries,
domain-file pairing, source pins, and selected client-parity rules. The remote
audit fetched 114 unique sources and checked text payloads and binary signatures.
Binary decoding is a separate native check. mihomo 1.19.30 loaded the export,
started, and downloaded all 25 providers. The research implementation then added eight provider selectors and four
optional modules. All 34 validator regression cases, the 114-source audit, and
the updated mihomo syntax check passed. Run the checks with:

```sh
ruby scripts/validate_configs.rb
ruby scripts/test_config_validation.rb
ruby scripts/validate_soul_module.rb
ruby scripts/audit_remote_sources.rb --self-test
ruby scripts/audit_remote_sources.rb
```

Native import and live traffic proof remains outstanding for Shadowrocket,
Surge, and Quantumult X. mihomo still needs a real merged subscription for
routing behavior to be proven. See [`docs/policy-matrix.md`](docs/policy-matrix.md).

## Updating an existing installation

This revision adds explicit Copilot, Cursor, Perplexity, xAI/Grok, Hugging Face,
Windsurf, and JetBrains AI choices across all four clients. Downloads, regional
streaming, security DNS, and diagnostics are optional Shadowrocket modules.
The earlier split separated AI, developer, streaming, and Apple selectors and removed
base ad blocking. Refresh the profile and enabled modules together, reselect
your routes, and enable Core or Lite if you still want blocking. Check new
group defaults before browsing. Disable both return-to-China modules unless
you have a verified mainland node; Soul has its own reject-by-default setup.

Country groups measure connectivity and match names. They don't verify exit
location or service access, and can switch nodes. Use one fixed node during
Apple sign-in. The [recipes](docs/recipes.md) explain that setup.

## Sources and trust

Repository-backed rule URLs are pinned to full upstream commit IDs. The
generated anti-AD feed in the opt-in Aggressive module is the one mutable rule
source. Review it before enabling that module and keep a known-good local copy.
Current references include
[blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script),
[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat),
[anti-AD](https://anti-ad.net), and
[carrnot/china-domain-list](https://github.com/carrnot/china-domain-list).
