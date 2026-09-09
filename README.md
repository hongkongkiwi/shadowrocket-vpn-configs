# shadowrocket-vpn-configs

Personal Shadowrocket setup: **one main config + toggleable modules**.

Shadowrocket only ever runs one active config — so everything optional lives in
[modules/](modules/), which can be switched on/off independently at any time
(Config → Modules). Module rules always outrank the main config's rules.

## Main config

**`shadowrocket.conf`** — base routing: AI / media / Microsoft / Google /
Telegram / Twitter / Spotify / Emby / Gaming / Apple proxy groups, DoH
encrypted DNS, QUIC blocking, region url-test groups, GEOIP,CN direct,
DoH-app-source rules from Repcz/Tool.

Import: Shadowrocket → Config → `+` → paste this URL after pushing:
```
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/shadowrocket.conf
```
The config's `update-url` points here, so later improvements propagate to your
phone via Shadowrocket's config auto-update. **No nodes/subscription included —
add your own airport subscription in Shadowrocket's Home tab.**

## Modules (toggle on/off in Config → Modules)

| Module | Purpose | Suggested default |
|---|---|---|
| [`httpdns-block`](modules/httpdns-block.module) | Block HTTPDNS endpoints (WeChat/Weibo/Baidu/NetEase) that bypass system DNS + port-53 hijack. Makes adblock reliable. | On |
| [`adblock-core`](modules/adblock-core.module) | blackmatrix7 Advertising (~280k domains) + Privacy | On |
| [`private-ip-block`](modules/private-ip-block.module) | DNS-rebinding protection (public domains → private IPs) | On (off if LAN apps break) |
| [`adblock-aggressive`](modules/adblock-aggressive.module) | anti-AD + Johnshall ad-only rules (~2MB) — extra China-app coverage | Off |
| [`adblock-lite`](modules/adblock-lite.module) | blackmatrix7 AdvertisingLite (~38k) — light alternative to core, don't stack both | Off |
| [`back-to-cn`](modules/back-to-cn.module) | Travel mode: CN domains + IPs via 🇨🇳 proxy group (needs a 回国 node) | Off (on when abroad) |

Module URLs (after push), e.g.:
```
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/httpdns-block.module
```

## Apple Silicon Mac

Shadowrocket runs natively on Apple Silicon Macs (iOS app on macOS) — **same
config, same modules, same import URLs**. No separate desktop config needed;
forking the wrapper but sharing the rule-sets would just double maintenance.

Mac notes:
- `skip-proxy` already covers localhost, `*.local` and all RFC1918 ranges, so
  local dev servers, Docker NAT (10.x) and Apple Virtualization guest networks
  (192.168.64.0/24 ⊂ 192.168.0.0/16) stay direct.
- The `[Host]` entry `iosapps.itunes.apple.com = ...ks-cdn.com` is iOS-only;
  harmless on Mac (App Store on macOS doesn't use that host).
- If a CLI tool (curl, git, Claude Code) doesn't go through the tunnel, enable
  **TUN / Force Routing** in Shadowrocket settings — the proxy is HTTP-only for
  apps that don't honor system proxy by default.
- Optional Mac tweak: append your machine's dev domains to `skip-proxy` rather
  than forking the config.

Per-app unlock/ad-removal modules (知乎/微博/B站/YouTube 去广告, VIP unlocks etc.)
are intentionally **not** vendored here — import individually from
[deezertidal/shadowrocket-rules](https://github.com/deezertidal/shadowrocket-rules)
(`https://yfamilys.com/module/<name>.module`) for just the apps you use. They
are MITM rewrites: enable HTTPS decryption, and re-check them when apps update.

## Ordering rules

1. Module rules beat main-config rules.
2. Among modules, higher in the list wins — keep privacy modules above unlock modules.
3. Don't run adblock-core + adblock-lite together (lite is a subset).
   Core + aggressive is fine (aggressive adds China coverage).

## Credits & sources

- Base config: [Repcz/Tool](https://github.com/Repcz/Tool) (X branch)
- Rules: [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script),
  [Repcz/Tool](https://github.com/Repcz/Tool),
  [VPSDance/ai-proxy-rules](https://github.com/VPSDance/ai-proxy-rules)
- Adblock lists: blackmatrix7, [anti-AD](https://anti-ad.net),
  [Johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/Johnshall/Shadowrocket-ADBlock-Rules-Forever)
- DNS/TUN hardening: [Johnshall lazy_group.conf](https://github.com/Johnshall/Shadowrocket-ADBlock-Rules-Forever/blob/release/lazy_group.conf)
- CN lists: [blackmatrix7 ChinaMax](https://github.com/blackmatrix7/ios_rule_script) (CN direct),
  [carrnot/china-domain-list](https://github.com/carrnot/china-domain-list),
  [carrnot/china-ip-list](https://github.com/carrnot/china-ip-list)

## Security

Config contains no credentials — nodes and subscriptions live in Shadowrocket
itself. Never add a `[Proxy]` section with node URIs or MITM private keys to
this repo.
