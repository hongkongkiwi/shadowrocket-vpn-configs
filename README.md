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
│   ├── apple-account.module
│   ├── apple-app-store-cdn.module
│   ├── apple-certificate-validation.module
│   ├── apple-intelligence.module
│   ├── apple-push.module
│   ├── apple-services.module
│   ├── apple-updates.module
│   ├── back-to-cn.module
│   ├── china-app-tun-compat.module
│   ├── dns-mainland-china.module
│   ├── httpdns-block.module
│   ├── ipv6.module
│   ├── privacy-dns.module
│   ├── private-ip-block.module
│   └── real-ip-compat.module
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
Emby, Spotify, and unmatched traffic. Apple account, certificate validation,
push, update, Intelligence, CDN, and catch-all routing live in separate modules.

Its rule order is intended to work like this:

1. Optional module rules run before the main profile rules.
2. The first matching main-profile rule wins.
3. Chinese domains use ChinaMax and then `GEOIP,CN` for direct access.
4. `FINAL` sends unmatched traffic to the fallback group.

`skip-proxy` moves matching connections from Shadowrocket's local proxy
interface to its TUN interface. It does not force `DIRECT`, and it has no effect
when TUN already handles everything. The base list has only RFC1918 addresses,
loopback, `.local`, and Apple's captive-portal check. The older mainland app
list now lives in `china-app-tun-compat`.

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
mode you use. The App Store host alias has its own module and is off unless you
import and enable it.

## Modules

Shadowrocket uses one active profile, so optional behavior lives in modules.
Import each module by URL, then order and toggle it under Config → Modules.

| Module | What it changes | When to use it | Import |
|---|---|---|---|
| [`adblock-core`](modules/adblock-core.module) | Advertising and tracker rules | Normal ad blocking | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-core.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-core.module) |
| [`adblock-lite`](modules/adblock-lite.module) | Smaller advertising list | Older devices or fewer false positives | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-lite.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-lite.module) |
| [`adblock-aggressive`](modules/adblock-aggressive.module) | Large mainland-focused anti-AD list | Add after Core works cleanly | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-aggressive.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/adblock-aggressive.module) |
| [`apple-account`](modules/apple-account.module) | Apple Account login hosts and a manual policy | Use for sign-in; keep one route selected until it finishes | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-account.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-account.module) |
| [`apple-app-store-cdn`](modules/apple-app-store-cdn.module) | Kingsoft host alias for one App Store download host | Mainland download workaround only | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-app-store-cdn.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-app-store-cdn.module) |
| [`apple-certificate-validation`](modules/apple-certificate-validation.module) | Direct Apple and DigiCert certificate checks | Enable for Apple sign-in and service use | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-certificate-validation.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-certificate-validation.module) |
| [`apple-intelligence`](modules/apple-intelligence.module) | Siri, Apple Intelligence, and Private Cloud Compute routing | Use a supported-region node when needed | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-intelligence.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-intelligence.module) |
| [`apple-push`](modules/apple-push.module) | APNs routing | Keep direct unless the local network blocks push | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-push.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-push.module) |
| [`apple-services`](modules/apple-services.module) | Catch-all Apple and iCloud policy | Normal Apple routing after narrower modules | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-services.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-services.module) |
| [`apple-updates`](modules/apple-updates.module) | Apple operating-system and component downloads | Keep large updates direct | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/apple-updates.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/apple-updates.module) |
| [`back-to-cn`](modules/back-to-cn.module) | Chinese domains and IPs through a mainland node | Outside mainland China only | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/back-to-cn.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/back-to-cn.module) |
| [`china-app-tun-compat`](modules/china-app-tun-compat.module) | Restores the old TUN list for selected mainland apps | Enable only when one of those apps fails | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/china-app-tun-compat.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/china-app-tun-compat.module) |
| [`dns-mainland-china`](modules/dns-mainland-china.module) | AliDNS with DNSPod fallback over HTTPS | Mainland networks | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/dns-mainland-china.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/dns-mainland-china.module) |
| [`httpdns-block`](modules/httpdns-block.module) | Known app-owned HTTPDNS endpoints | Apps that ignore system DNS | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/httpdns-block.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/httpdns-block.module) |
| [`ipv6`](modules/ipv6.module) | IPv6 plus preferred AAAA answers | Only with IPv6-capable networks and nodes | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/ipv6.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/ipv6.module) |
| [`privacy-dns`](modules/privacy-dns.module) | Cloudflare with Quad9 fallback over HTTPS | Hong Kong and travel outside mainland China | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/privacy-dns.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/privacy-dns.module) |
| [`private-ip-block`](modules/private-ip-block.module) | Proxies domains that unexpectedly resolve to private IPs | DNS-hijack defence; disable for split DNS | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/private-ip-block.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/private-ip-block.module) |
| [`real-ip-compat`](modules/real-ip-compat.module) | Real DNS answers for selected gaming and carrier hosts | Apps or consoles that fail with fake IP | [Raw](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/real-ip-compat.module) · [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/real-ip-compat.module) |

Do not enable `adblock-core` and `adblock-lite` together. Do not enable both DNS
modules together. Put `apple-account`, `apple-certificate-validation`,
`apple-push`, `apple-updates`, and `apple-intelligence` above
`apple-services`; their narrower rules must run first. Keep rejection modules
above `back-to-cn`.

## Suggested module stacks

| Situation | Enable | Leave off or change |
|---|---|---|
| Hong Kong, normal use | `privacy-dns`, `private-ip-block`, `adblock-core`, Apple Account, Certificate Validation, Push, Updates, Services | Keep the App Store CDN alias off. Enable IPv6 only after testing every node. |
| Mainland China, normal use | `dns-mainland-china`, `adblock-core`, Apple Account, Certificate Validation, Push, Updates, Services | Select `DIRECT` for the Apple groups first. Keep `privacy-dns`, `back-to-cn`, and IPv6 off. |
| Mainland China, Apple Intelligence | Mainland stack plus `apple-intelligence` | Select one working US node. Do not change it during a request. |
| Outside China, mainland apps | Hong Kong stack plus `back-to-cn` | The travel module needs a working mainland node. |
| One mainland bank or carrier app fails | Current stack plus `china-app-tun-compat` | Remove it again if it does not fix that app. |

### Apple sign-in recovery

Apple lists four account hosts: `account.apple.com`,
`appleid.cdn-apple.com`, `idmsa.apple.com`, and `gsa.apple.com`. The account
module routes those hosts together and also includes `setup.icloud.com` for
managed-device sign-in. Apple says these account hosts support proxies, but its
TLS traffic must not be inspected.

For a failed sign-in:

1. Enable `apple-certificate-validation`. Disable `apple-app-store-cdn`,
   `apple-intelligence`, `privacy-dns`, and `private-ip-block` temporarily.
2. Set both Apple Account and Apple Services to `DIRECT`. Retry once.
3. If direct access fails, select one fixed Hong Kong node as Shadowrocket's
   Home server, then set both groups to `PROXY`. Do not change the Home server
   during the login attempt.
4. On iPhone, iPad, or Mac, turn off Limit IP Address Tracking for that network
   while testing. Apple documents conflicts between Private Relay and VPN or
   filtering software.
5. Re-enable modules one at a time after login works.

## DNS and network behavior

The base profile leaves DNS transport, port 53 interception, private-answer
handling, and real-IP exceptions to Shadowrocket. `privacy-dns` uses Cloudflare
with Quad9 fallback. `dns-mainland-china` uses AliDNS with DNSPod fallback and
disables HTTP/3 for its resolver connections. Both encrypt DNS over HTTPS and
intercept port 53. Pick one; never enable both.

These modules have no plaintext or system fallback. Disable the active DNS
module during captive-portal sign-in or if both configured resolvers are
blocked.

Other current choices:

- IPv6 is disabled.
- QUIC is blocked for proxied traffic so affected clients can retry over TCP.
- `private-ip-block` treats unexpected private answers as DNS hijacking and
  forces those domains through the proxy.
- `real-ip-compat` bypasses fake-IP DNS for a short list of hosts that inspect
  addresses directly. Its list contains no Apple entries.
- The optional App Store CDN module maps `iosapps.itunes.apple.com` to a
  Kingsoft alias. No other module changes Apple DNS answers.
- TUN exclusions cover RFC1918, loopback, link-local, documentation, multicast,
  and selected discovery ranges.

## Choosing proxy nodes

This repository cannot safely bundle proxy nodes or subscriptions. Free proxy
lists are a bad fit for Apple accounts, banking, or private traffic: ownership
is unclear, exits rotate, and public endpoints disappear quickly.

When comparing paid subscriptions or self-hosted servers, require all of the
following:

- VLESS + REALITY over TCP 443 and a separate Hysteria 2 or TUIC path.
- Hong Kong, Japan, Singapore, and US exits, plus a mainland exit only if you
  need `back-to-cn`.
- Stable node names that match this profile's region filters.
- A subscription URL that can refresh on the networks you use, plus an offline
  copy for travel.
- No installed root certificate, HTTPS decryption, or rotating residential
  proxy requirement.
- A short trial or refund window tested on both Wi-Fi and mobile data.

No provider ranking is stored here. Resellers change servers, owners, and
protocols too quickly for a committed list to stay trustworthy.

For mainland China, start with VLESS + REALITY + XTLS Vision over TCP 443. It
resembles ordinary TLS traffic and gives you a TCP path when UDP is filtered.
Keep Hysteria 2 or TUIC as a second path for lossy networks where UDP works.
Shadowsocks 2022 is useful in Hong Kong and as another fallback, but studies of
the Great Firewall show that fully encrypted Shadowsocks-style traffic can be
identified and blocked.

The server route matters as much as the protocol:

- Keep at least two independently operated subscriptions or servers.
- Test Hong Kong first from mainland China, then Tokyo or Osaka, Singapore, and
  a US node. The nearest city does not guarantee the best carrier path.
- Test on the mainland Wi-Fi and mobile carriers you actually use. A node that
  works from China Mobile can fail from China Telecom.
- Use manual selection for Apple Account, banking, payments, and long-lived
  sessions. Automatic latency groups can change the exit IP mid-session.
- Never enable TLS decryption for Apple account, iCloud, push, or update hosts.

Shadowrocket 2.2.92 has current support and fixes for VLESS, XTLS, Hysteria 2,
TUIC, AnyTLS, WireGuard variants, and MASQUE. Support in the app does not prove
that a provider configured the server side correctly. Test TCP and UDP paths
separately before travel.

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
- Apple Account, certificate validation, push, updates, Intelligence, App Store
  CDN, and catch-all routing are separate. The validator checks the official
  account and certificate hosts and prevents narrower rules from returning to
  `apple-services`.
- Strict DNS, private-answer blocking, and real-IP exceptions stay outside the
  base profile and can be enabled separately.
- The base `skip-proxy` contains local access and captive-portal detection. The
  older mainland app list is optional.
- Every module has checked raw GitHub and jsDelivr import URLs in this README.
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

- [Apple network hosts and ports](https://support.apple.com/en-ie/101555) for
  account, iCloud, push, update, and Intelligence endpoints
- [Apple Private Relay network troubleshooting](https://support.apple.com/en-asia/102022)
  for the per-network Limit IP Address Tracking advice
- [Shadowrocket on the App Store](https://apps.apple.com/us/app/shadowrocket/id932747118)
  for current protocol and client-fix history
- [LOWERTOP Shadowrocket wiki](https://github.com/LOWERTOP/Shadowrocket/wiki)
  for module, DNS, TUN, and policy syntax
- [Xray REALITY](https://xtls.github.io/en/config/transports/reality.html),
  [Hysteria 2 protocol](https://v2.hysteria.network/docs/developers/Protocol/),
  and [Shadowsocks 2022](https://shadowsocks.org/doc/sip022.html) for proxy
  protocol behavior
- [GFW Report: fully encrypted traffic blocking](https://gfw.report/publications/usenixsecurity23/data/paper/paper.pdf)
  for mainland protocol-detection evidence
- [Free Proxies Unmasked](https://arxiv.org/abs/2403.02445) for measured
  availability and security problems in public proxy services
- [Cloudflare](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/),
  [Quad9](https://docs.quad9.net/services/),
  [AliDNS](https://www.alidns.com/solution), and
  [DNSPod](https://cloud.tencent.com.cn/document/product/302/110786) for the
  DNS module endpoints
- [mihomo rule-provider format](https://wiki.metacubex.one/en/config/rule-providers/)
- [Surge rule-set format](https://manual.nssurge.com/rules/ruleset.html)
- [Quantumult X sample configuration](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)
