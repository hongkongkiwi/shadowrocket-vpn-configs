# Policy and client parity

Shadowrocket has two location profiles: `hong-kong.conf` defaults only AI and
international TikTok to a proxy, with everything else direct; `mainland-china.conf`
keeps the legacy routing defaults. Both include location-specific DNS. Optional
modules and saved selections can override their defaults. The table below
describes the shared legacy policy and unsplit exports. Neither new location
profile has native import or live traffic proof yet.

Hong Kong replaces the upstream Claude, Gemini, and TikTok lists with reviewed
domain rules in `rules/hong-kong-proxy.list`. Shared analytics, generic Google
APIs, CapCut, broad ByteDance domains, keywords, and ASN rules are excluded.
Shared dependencies may need observed-host overrides after native testing.

| Area | Shadowrocket | mihomo / Clash Meta | Surge | Quantumult X |
|---|---|---|---|---|
| Unmatched | `FINAL` to Fallback | final fallback group | final fallback group (default `PROXY`, initially a DIRECT placeholder) | final fallback policy |
| China | ChinaMax and `GEOIP,CN` direct; travel module optional | native China providers direct | native China rules direct | China rules force `direct` |
| Ads | None in base; Core or Lite, Aggressive only on Core | none in export | none in export | none in export |
| AI | Eleven provider selectors including both Copilots, Cursor, Perplexity, xAI, Hugging Face, Windsurf and JetBrains; US first; shared dependencies excluded | same US defaults | same US defaults | same US defaults |
| GitHub | General API/auth in Developer Services; Copilot API separate | same | same | same |
| Streaming | YouTube, Netflix, Disney+, Prime Video, HBO, Bahamut separate | separate | separate | separate |
| Apple | App Downloads, Updates, Siri, PCC, Push, Account, then Services | built into export | policy plus direct certificate exceptions | policy plus direct certificate exceptions |
| App Store alias | optional Kingsoft host alias | omitted | omitted | omitted |
| DNS | Privacy, Security, or Mainland DoH module; choose one | privacy DoH; documented security substitution | privacy DoH; documented security substitution | concurrent privacy DoH; documented security substitution |
| Bulk downloads | optional selected game/package asset hosts | omitted | omitted | omitted |
| Regional streaming | optional HK/TW/JP services | omitted | omitted | omitted |
| Diagnostics | optional selected Ookla hosts; Fast.com remains Netflix | omitted | omitted | omitted |
| QUIC | unchanged in base; optional compatibility module blocks proxied QUIC | unchanged | unchanged | unchanged |
| IPv6 | disabled by base; optional enable/prefer modules | disabled in profile and DNS | disabled in profile | client default |

The App Store alias is absent from all exports. mihomo is a merge
fragment with no nodes. Surge's `PROXY = select, DIRECT` is a placeholder,
not a working proxy: replace it before relying on tunnelling. Its regional
groups include `[Proxy]` entries and resolved members of `PROXY`, then filter
by name. Empty regional groups remain possible until matching nodes exist.
HTTPDNS, private-answer, and real-IP controls also vary by client.

Static checks cover policy references, domain-file pairing, source pinning,
and selected routing invariants; they are not full native parsers. A mihomo
1.19.30 startup test downloaded and parsed all 25 providers. Native import and
live traffic proof remain outstanding for
Shadowrocket, Surge, and Quantumult X. mihomo still needs a real merged
subscription before routing behavior is proven.
