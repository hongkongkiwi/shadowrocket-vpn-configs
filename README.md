# shadowrocket-vpn-configs

Personal Shadowrocket setup: **one main config + toggleable modules + exports
for other proxy apps**.

Shadowrocket only ever runs one active config — so everything optional lives in
[modules/](modules/), switched on/off independently at any time (Config →
Modules). Module rules always outrank the main config's rules.

```
shadowrocket-vpn-configs/
├── shadowrocket.conf        # the one active config (source of truth)
├── modules/                 # 6 independently toggleable modules
└── exports/                 # same rules for Clash/mihomo, Surge, Quantumult X
```

## Main config — `shadowrocket.conf`

Base routing: AI / media / Microsoft / Google / Telegram / Twitter / Spotify /
Emby / Gaming / Apple proxy groups, DoH encrypted DNS (`doh.pub` + `dns.alidns.com`
with plaintext fallback), QUIC blocking for proxied traffic, `tun-excluded-routes`,
blackmatrix7 **ChinaMax** domain-based CN direct (before `GEOIP,CN`), carrier
`always-real-ip` entries, bank/carrier `skip-proxy`.

Import (Config → `+` → paste URL):
```
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/shadowrocket.conf
```
jsDelivr mirror (works better from mainland networks):
```
https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/shadowrocket.conf
```
The config's `update-url` points at this repo, so pushes to `main` propagate to
your devices via Shadowrocket's config auto-update. **No nodes/subscription
included — add your own airport subscription in Shadowrocket's Home tab.**

## Modules — one URL each

Shadowrocket imports modules one at a time (Modules → `+` → URL → Download).
URL-added modules can re-download updates from the repo; pasted content is a
frozen local copy. All six verified serving (2026-09-10):

| Module | Purpose | Default |
|---|---|---|
| [`httpdns-block`](modules/httpdns-block.module) | Block HTTPDNS endpoints (WeChat/Weibo/Baidu/NetEase) that bypass system DNS + port-53 hijack. Makes adblock reliable. | On |
| [`adblock-core`](modules/adblock-core.module) | blackmatrix7 Advertising (~280k domains) + Privacy | On |
| [`private-ip-block`](modules/private-ip-block.module) | DNS-rebinding protection (public domains → private IPs) | On (off if LAN apps break) |
| [`adblock-aggressive`](modules/adblock-aggressive.module) | anti-AD + Johnshall ad-only rules (~2MB) — extra China-app coverage | Off |
| [`adblock-lite`](modules/adblock-lite.module) | blackmatrix7 AdvertisingLite (~38k) — light alternative to core, don't stack both | Off |
| [`back-to-cn`](modules/back-to-cn.module) | Travel mode: CN domains + IPs via 🇨🇳 proxy group (needs a 回国 node) | Off (on when abroad) |

```
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/httpdns-block.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-core.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/private-ip-block.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-aggressive.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/adblock-lite.module
https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/back-to-cn.module
```

### Ordering rules

1. Module rules beat main-config rules.
2. Among modules, higher in the list wins — keep privacy modules above unlock modules.
3. Don't run adblock-core + adblock-lite together (lite is a subset).
   Core + aggressive is fine (aggressive adds China coverage).

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

## Exports — other apps, same rules

Rule lists are platform-native from the same upstream sources, so coverage
stays identical across apps — only the wrapper differs. See
[exports/README.md](exports/README.md) for full import notes and caveats.

| App | File | Notes |
|---|---|---|
| Clash Verge Rev / mihomo / Stash / ClashMi | [`exports/clash/config.yaml`](exports/clash/config.yaml) | Validated YAML; MetaCubeX `.mrs` rule providers; `PROXY` group is `include-all` so a subscription import self-wires |
| Surge iOS 5+ / Surge Mac | [`exports/surge/Surge.conf`](exports/surge/Surge.conf) | Edit `PROXY = select, policy-path=...` to your subscription URL after import |
| Quantumult X | [`exports/quantumultx/QuantumultX.conf`](exports/quantumultx/QuantumultX.conf) | blackmatrix7 QX lists embed policy names — group names in `[policy]` must match (they do); AI lists remapped via `force-policy=` |

Maintenance rule: when changing **groups or rule order** in the Shadowrocket
config, mirror the change in each export. Rule **content** needs no upkeep —
upstream lists update daily. All exports contain zero nodes.

## Per-app unlock/ad-removal modules

知乎/微博/B站/YouTube 去广告, VIP unlocks etc. are intentionally **not** vendored
here — import individually from
[deezertidal/shadowrocket-rules](https://github.com/deezertidal/shadowrocket-rules)
(`https://yfamilys.com/module/<name>.module`) for just the apps you use. They
are MITM rewrites: enable HTTPS decryption, and re-check them when apps update.

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
- Exports: [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) (mihomo `.mrs`),
  Repcz Surge lists, blackmatrix7 Surge/QuantumultX lists

## Security

Config and modules contain no credentials — nodes and subscriptions live in
Shadowrocket itself. Never add a `[Proxy]` section with node URIs or MITM
private keys to this repo.
