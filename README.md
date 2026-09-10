# Shadowrocket VPN Configs

Personal routing rules for Shadowrocket, with hand-maintained translations for
mihomo/Clash, Surge, and Quantumult X. The repository contains policies and
remote rule references only. It contains no proxy nodes, subscription URLs,
passwords, certificates, or MITM private keys.

`shadowrocket.conf` is the base policy, and `modules/` holds behavior that can be
toggled independently. The files under `exports/` translate the same routing
intent, but the clients have different DNS, policy, and remote resource models.
Treat the exports as ports, not identical copies.

> [!NOTE]
> The 2026-09-10 repair pass cleared the known static, source, and mihomo
> runtime failures. Shadowrocket, Surge, and Quantumult X still need native
> import and traffic tests before this revision can be called verified on those
> clients. See [Validation status](#validation-status).

## Repository map

```text
shadowrocket-vpn-configs/
├── shadowrocket.conf
├── modules/
│   ├── adblock-core.module
│   ├── adblock-lite.module
│   ├── adblock-aggressive.module
│   ├── apple-services.module
│   ├── httpdns-block.module
│   ├── private-ip-block.module
│   └── back-to-cn.module
├── scripts/validate_configs.rb
├── .github/workflows/validate.yml
└── exports/
    ├── clash/config.yaml
    ├── surge/Surge.conf
    ├── quantumultx/QuantumultX.conf
    └── README.md
```

## What the main config does

The main Shadowrocket profile separates traffic into selectable groups for AI,
international media, Microsoft, Google, Telegram, Twitter/X, TikTok, gaming,
Emby, Spotify, and unmatched traffic. Apple routing lives in an optional module
so it has one on/off switch.

Its rule order is intended to work like this:

1. Optional module rules run before the main profile rules.
2. The first matching main-profile rule wins.
3. Chinese domains use ChinaMax and then `GEOIP,CN` for direct access.
4. `FINAL` sends unmatched traffic to the fallback group.

Traffic listed in `skip-proxy` bypasses the proxy engine. This includes local
addresses, captive-portal checks, selected carrier endpoints, and selected bank
sites. Review that list before using the profile on an untrusted network.

## Shadowrocket setup

Add your proxy subscription in Shadowrocket first. On the Home tab, tap `+`,
choose `Subscribe`, paste the provider URL, and refresh it. This repository does
not provide nodes.

Import the main profile from either URL:

```text
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/shadowrocket.conf
```

```text
https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/shadowrocket.conf
```

The profile's `update-url` points back to the raw GitHub file. Updates to
`main` can therefore reach installed profiles during Shadowrocket's config
refresh.

After import, check all of the following in the app:

- Every rule target resolves to an existing policy group.
- Every region group contains at least one expected node.
- `FINAL` resolves to the fallback group.
- Remote rule resources download without warnings.
- A direct site, a proxied site, a rejected domain, and a LAN host behave as
  intended.

Shadowrocket 2.2.92 is installed on the development Mac, but the repair pass did
not replace or activate its current profile. Native import and sustained runtime
testing remain outstanding.

### Apple Silicon Mac

The iOS build runs on Apple Silicon Macs and uses the same profile, modules,
and update URLs. If `curl`, `git`, or another CLI tool ignores the system proxy,
enable Shadowrocket's TUN or Force Routing mode.

Local access differs by capture mode. Both TUN exclusions and `skip-proxy` now
cover `192.168.0.0/16`, including Apple Virtualization's usual
`192.168.64.0/24` network. Test Docker, printers, and NAS hosts on the capture
mode you use. The App Store host alias is active only with the Apple module;
disable that module if downloads fail or resolve to an unexpected CDN.

## Modules

Shadowrocket uses one active profile, so optional behavior lives in modules.
Import each module by URL, then order and toggle it under Config → Modules.

| Module | Purpose | Suggested use | Audit state |
|---|---|---|---|
| [`httpdns-block`](modules/httpdns-block.module) | Reject known app-owned HTTPDNS endpoints that bypass port 53 hijacking | Enable when apps ignore system DNS | Source URL returned 200 |
| [`adblock-core`](modules/adblock-core.module) | Advertising plus privacy/tracker lists | Normal ad-blocking choice | Both native list URLs returned 200 |
| [`adblock-lite`](modules/adblock-lite.module) | Smaller advertising list | Use instead of Core on slower devices | Source URL returned 200 |
| [`adblock-aggressive`](modules/adblock-aggressive.module) | Larger China-focused anti-AD list | Add only after Core works without false positives | Native list URL returned 200 |
| [`apple-services`](modules/apple-services.module) | Keep Apple services and software updates direct; apply the App Store CDN alias | Enable for the repository's preferred Apple routing; disable to use normal profile routing | Native Apple lists returned 200; exact direct rules run first |
| [`private-ip-block`](modules/private-ip-block.module) | Force domains with private DNS answers through the proxy | Useful with other profiles; the main profile already sets the same option | No remote dependency |
| [`back-to-cn`](modules/back-to-cn.module) | Route Chinese domains and IPs through a return-to-China node | Use only while outside mainland China | Domain and native IP-CIDR list URLs returned 200 |

Raw module URLs:

```text
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/httpdns-block.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-core.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-lite.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-aggressive.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-services.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/private-ip-block.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/back-to-cn.module
```

Do not enable Core and Lite together. Lite is a subset of Core. Core plus
Aggressive is intentional, though the overlap costs memory and initial parse
time. Keep privacy/reject modules above `back-to-cn` so a broad China rule does
not override a rejection.

## DNS and network behavior

The Shadowrocket profile uses Cloudflare and AliDNS over HTTPS for both primary
and fallback resolution. It has no system or plaintext fallback. DNS will fail
on a network that blocks both resolvers, so keep a known-good local profile if
you travel through networks with strict resolver filtering.

Other current choices:

- IPv6 is disabled.
- Port 53 DNS is hijacked into Shadowrocket.
- QUIC is blocked for proxied traffic so affected clients can retry over TCP.
- `private-ip-answer = false` treats unexpected private answers as DNS
  hijacking and forces those domains through the proxy. Set it to `true` if a
  trusted split-DNS or private service stops resolving.
- The Apple module maps `iosapps.itunes.apple.com` to a Kingsoft CDN alias.
- TUN exclusions cover RFC1918, loopback, link-local, documentation, multicast,
  and selected discovery ranges.

## Exports

See [`exports/README.md`](exports/README.md) for client-specific import steps.

| Client | File | Current proof | Remaining gap |
|---|---|---|---|
| Shadowrocket | [`shadowrocket.conf`](shadowrocket.conf) | Local policy/source checks against the installed 2.2.92 default profile | Native import and live routing |
| mihomo / Clash Meta | [`exports/clash/config.yaml`](exports/clash/config.yaml) | YAML load; mihomo 1.19.30 startup; all 27 providers downloaded and parsed | Behavior after merging a real node subscription |
| Surge 5+ | [`exports/surge/Surge.conf`](exports/surge/Surge.conf) | Exact policy-reference and source checks; compared with current Surge docs | Native profile check and live routing |
| Quantumult X | [`exports/quantumultx/QuantumultX.conf`](exports/quantumultx/QuantumultX.conf) | Policy/source checks; syntax compared with the vendor sample | Native import, regional population, and live routing |

The exports still differ where the clients use different controls. Surge has no
built-in ad rules in this repository, while the mihomo and Quantumult X exports
do. Apple routing stays built into each export because Shadowrocket's module
toggle has no direct cross-client equivalent. HTTPDNS blocking, private-answer
handling, and QUIC behavior also vary by client.

## Validation status

The 2026-09-10 repair pass produced these results:

- `ruby scripts/validate_configs.rb` passes. It parses the mihomo YAML, checks
  local policy/provider references, and rejects the retired URLs and old
  Quantumult X policy syntax.
- All 116 active remote rule and provider URLs returned HTTP 200.
- mihomo 1.19.30 accepted the file, started, and downloaded 27 providers without
  provider parse errors. This includes the VPSDance YAML source.
- Shadowrocket and Surge rule targets now match their declared group names.
- Reject rules run before the broad AI lists, so the known `segment.io` overlap
  stays rejected.
- Apple direct exceptions precede the broad Apple sources. Shadowrocket keeps
  the full Apple block in `apple-services.module` so it can be disabled.
- Quantumult X now uses `url-latency-benchmark`, forces ad and LAN/China policy
  outcomes, enables DoH, and includes OneDrive plus Prime Video.
- Taiwan selectors use the Taiwan flag and no longer match `🇨🇳`.

No native Shadowrocket, Surge, or Quantumult X import was performed. Static
syntax checks cannot prove that a mobile client accepts a profile or that a
subscription supplies the expected nodes.

## Maintenance checklist

When changing groups, sources, or rule order:

1. Edit `shadowrocket.conf` as the source policy.
2. Port the intent to each export using that client's native syntax.
3. Run `ruby scripts/validate_configs.rb`; CI runs the same command.
4. Fetch every remote URL and reject non-200 responses.
5. Load mihomo long enough to fetch and parse every provider.
6. Import each mobile profile, activate it, and test real direct/proxy/reject
   traffic before updating the validation date.

Do not update a “verified” date after a YAML parse or URL check alone. Those
checks say nothing about policy resolution or runtime routing.

## Security and trust

Remote rule lists are mutable third-party inputs. A `RULE-SET` cannot add a
proxy password or MITM certificate, but an upstream change can still overblock
traffic or move a domain between direct and proxy paths. Review unexpected
source-size changes and keep a known-good profile available locally.

Never commit any of these:

- A `[Proxy]` section containing node credentials.
- Subscription URLs with account tokens.
- MITM certificate private keys or PKCS#12 bundles.
- Provider dashboards, API tokens, or exported app backups.

Per-app “VIP unlock” and response-rewrite modules sit outside this repository.
They require HTTPS decryption and can read or alter decrypted app traffic. Do
not install one merely because it appears in a public list. Read its script,
pin a reviewed revision where possible, and retest after app updates.

## Sources

- [Repcz/Tool](https://github.com/Repcz/Tool) for the original Shadowrocket and
  Surge structure
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
  for service, China, advertising, and privacy lists
- [VPSDance/ai-proxy-rules](https://github.com/VPSDance/ai-proxy-rules) for the
  broad AI list
- [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) for
  mihomo MRS providers
- [anti-AD](https://anti-ad.net) for optional aggressive ad blocking
- [carrnot/china-domain-list](https://github.com/carrnot/china-domain-list) for
  the travel module's domain source

Client references used during maintenance:

- [mihomo rule-provider format](https://wiki.metacubex.one/en/config/rule-providers/)
- [Surge rule-set format](https://manual.nssurge.com/rules/ruleset.html)
- [Quantumult X sample configuration](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)
