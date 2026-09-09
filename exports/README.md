# Exports — same rules, other apps

The Shadowrocket config is the source of truth. These exports mirror it for
other clients. Rule lists are platform-native from the same upstream sources
(blackmatrix7 / Repcz / VPSDance / MetaCubeX), so coverage stays in sync across
apps — only the wrapper differs.

**All exports contain zero nodes.** Add your subscription in each app natively.

| App | File | Format | Rule source used |
|---|---|---|---|
| Clash Verge Rev / Clash Meta (mihomo) / Stash / ClashMi | [`clash/config.yaml`](clash/config.yaml) | YAML + rule-providers | blackmatrix7 Clash yaml + MetaCubeX .mrs |
| Surge iOS 5+ / Surge Mac 5+ | [`surge/Surge.conf`](surge/Surge.conf) | Surge conf | Repcz Surge lists + blackmatrix7 Surge lists |
| Quantumult X | [`quantumultx/QuantumultX.conf`](quantumultx/QuantumultX.conf) | QX conf + remote filters | blackmatrix7 QuantumultX lists |

## Import notes

- **Clash/mihomo**: import as a profile, then add your subscription URL to the
  proxy list (Verge Rev: Profiles → +; group `PROXY` in this file is a stub —
  replace with your subscription's proxy names or use `include-all` groups).
  Ads block via `RULE-SET,ads,REJECT` — delete that line to "toggle off".
- **Surge**: edit the `PROXY = select, policy-path=...` line to your real
  subscription URL after import. Modules like `Ads_SukkaW` from Repcz's Surge
  setup can be added for pre-matching adblock.
- **Quantumult X**: add subscription in the Server tab; groups reference
  `proxy`. blackmatrix7 QX lists embed policy names in every line — group names
  in `[policy]` match them exactly. AI lists use `force-policy=` to remap
  OpenAI/Claude lists into our single 🤖 AI group.

## Caveats

- QX/Surge param spellings drift between app versions; if a key errors, check
  the app's in-app docs. All rule-list URLs were verified live (2026-09-10).
- mihomo runs its own DNS (fake-ip + DoH here). Apple push / carrier domains
  are in `fake-ip-filter`, mirroring the Shadowrocket `always-real-ip` list.
- Loon: not exported yet — its remote-rule syntax differs again. Same rule
  sources apply (Surge-format lists work); ask if needed.

## Keeping exports in sync

Groups and rule order are duplicated intentionally (different engines, can't
share). When changing the Shadowrocket config's *groups or rule order*, apply
the same change to each export. Rule *content* needs no maintenance — it all
updates upstream daily.
