# Module recipes

Shadowrocket applies module rules before the base profile. Narrow Apple modules
must come before `apple-services`, the broad catch-all. Keep ad blocking and
`httpdns-block` above `soul-ktv` and both return-to-China variants. Put Soul
above either `back-to-cn` or `back-to-cn-all` so the broad travel list cannot
bypass its reject-by-default policy.

Choose at most one of `adblock-lite` and `adblock-core`. The base has no ad or
tracker block. Add `adblock-aggressive` only after Core and only when Core is
working. Choose at most one DNS module. `privacy-dns` uses Cloudflare and Quad9;
`security-dns` uses Cloudflare malware filtering and Quad9 threat filtering;
`dns-mainland-china` uses AliDNS and DNSPod. Never combine these variants. DoH endpoints are selected
concurrently by clients that support parallel resolver selection, rather than
being a guaranteed primary-then-fallback chain. All three Shadowrocket DNS modules
intercept `*:53` and disable system and fallback-proxy DNS.

Safe Apple order:

```text
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-siri-search
apple-intelligence
apple-app-downloads (when App Store/content needs its own route)
apple-services
```

The App Store CDN alias maps one host to a Kingsoft name. It is separate from
the App Downloads and Apple Updates routes. Its `[Host]` setting has no
rule-order dependency on `apple-services`.

Check your intended order before importing, with names listed top to bottom:

```sh
ruby scripts/validate_configs.rb adblock-core privacy-dns apple-account apple-services
```

This checks the named stack, not the modules installed on your device.

## Module boundaries

Keep a module when its entire behavior needs an independent on/off switch.
Use a policy selector when only the exit needs to change.

| Area | Decision | Reason |
|---|---|---|
| AI and developer tools | Keep provider selectors in the base | Ordinary GitHub and Microsoft traffic stays separate from their Copilot APIs. |
| Streaming | Global services in the base; regional services optional | The HK/TW/JP overlay adds choices only for people using those services. |
| Downloads | One optional bulk selector, plus existing Apple modules | Separate large transfers from game communities and general APIs. Split game and package downloads only if their exit choices diverge. |
| Apple | Keep narrow routes separate from Services | Push, sign-in, large downloads, and Intelligence need different routes. The broad module alone covers users who want one Apple route. |
| DNS | Keep the three complete alternatives | Resolver selection and port-53 handling should switch together. A shared prerequisite module would complicate import and rollback. |
| IPv6 | Keep enable and prefer as alternatives | Enabling IPv6 and preferring it are different network decisions. |
| Ad blocking | Core or Lite, plus optional Aggressive | The mutable Aggressive source needs its own off switch. Core is required when it is enabled. |
| Return to China | Keep Targeted and All as alternatives | One changes selected apps; the other changes all mainland traffic. Each includes its own selector so it can be imported alone. |
| Compatibility | Keep QUIC, HTTPDNS, private answers, real IP, and the CDN alias separate | Each addresses a different failure and needs independent rollback. |
| Shared AI dependencies | Keep one temporary diagnostic module | Once a failing hostname is known, put that narrow exception in a private local override instead of permanently routing every vendor. |

Split the targeted China apps into account/payment and media modules only if
you need to enable those scopes independently. Different exits alone can be
handled with selectors. Split real-IP exceptions by game or carrier only after
a conflicting hostname is identified. Keep one-off corporate, bank, or personal
Emby hosts in private overrides until there is a tested rule worth sharing.

## Hong Kong and travel

Use [`hong-kong.conf`](../hong-kong.conf) while in Hong Kong. It includes privacy
DNS and defaults every service and unmatched traffic to `DIRECT` except AI and
international TikTok, which retain the US proxy default. Leave DNS modules off.
For this profile, start with the optional modules below. Ad blocking is optional,
and the Apple Intelligence module is only needed for Apple's AI cloud endpoints.

```text
adblock-core (or adblock-lite)
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-siri-search (only when needed)
apple-intelligence (only when needed)
apple-services
```

For the legacy `shadowrocket.conf`, add `privacy-dns` to that recipe.
Leave `private-ip-block` off for the AI/TikTok-only setup: it can force unrelated
domains through a proxy when DNS returns a private address. Also leave
`ai-shared-dependencies`, `bulk-downloads`, `regional-streaming`, Soul, and both
return-to-China modules off unless you deliberately want their extra routes.

Leave mainland DNS, `back-to-cn-all`, and the App Store CDN alias off. Add
`httpdns-block` or `real-ip-compat` only for a specific app failure. Choose
`ipv6` to enable IPv6 without preferring it. Use `ipv6-preferred` instead
only if the network and every chosen node pass IPv6 tests. `quic-compat` is
optional when a proxied app fails with QUIC.

Every service selector has a manual `DIRECT` option. The legacy profile keeps
its proxy defaults; the Hong Kong profile already selects `DIRECT` for GitHub,
streaming, gaming, and other ordinary services. Disable optional proxy routing
modules to keep only AI and international TikTok proxied. `DIRECT` uses the current network and
does not provide a mainland IP when you're in Hong Kong.

## Mainland China

Use [`mainland-china.conf`](../mainland-china.conf) while in mainland China.
It includes mainland DNS, so leave DNS modules off.

```text
adblock-core (or adblock-lite)
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-services
```

For the legacy `shadowrocket.conf`, add `dns-mainland-china` to that recipe.

Start Apple Account and Apple Services on `DIRECT`. If that fails, hold one
Hong Kong node fixed and use `PROXY` for both throughout sign-in. Add
`apple-intelligence` above Services only when needed and select a working US
node. Keep `privacy-dns`, `security-dns`, and `back-to-cn` off. Use `china-app-tun-compat` only
for a listed mainland app that fails through the ordinary capture path.

## Apple Intelligence and PCC

Add `apple-siri-search` and `apple-intelligence` above `apple-services`.
The first covers Siri, dictation, and search and defaults to Direct. The second
covers Apple Intelligence Extensions plus Private Cloud Compute and starts with
the US selector. Keep one route fixed during account or device setup.
Certificate validation stays direct.

A regional `url-test` group can switch its chosen node. For a fixed session,
select one exact node through Shadowrocket's global `PROXY` selection and
choose `PROXY` in the relevant Apple groups, or use a private local module
with that node named directly. Neither an exit IP nor these rules establish
Apple Intelligence eligibility. Device, account region, OS, and language
requirements still apply; check [Apple's requirements](https://support.apple.com/en-us/121115).

The base and all exports separate OpenAI, Claude, Google AI, GitHub Copilot,
Microsoft Copilot, Cursor, Perplexity, xAI/Grok, Hugging Face, Windsurf, and
JetBrains AI. New provider selectors start with the US group and allow manual
PROXY, regional, and DIRECT choices. GitHub authentication and general API
traffic remain Developer Services; Microsoft account hosts remain Microsoft
Services. Shared dependencies remain outside the provider routes.

Enable `ai-shared-dependencies` only if an AI sign-in or billing flow fails
because its shared services use a different exit. It also captures unrelated
apps that use Auth0, Stripe, Sentry, Intercom, and similar providers, so remove
it after diagnosis when possible. The Arkose and LiveKit suffixes also cover
the narrower OpenAI verification and ChatGPT voice hosts in the base. Changing
the shared selector changes their route too.

## Back to China outside China

Start with the Hong Kong recipe, then add `back-to-cn`. It routes WeChat,
Alipay, Bilibili, NetEase Music, and mainland media rules to `🇨🇳 Return to
China`. Its selector exposes the automatic group plus matching individual
nodes; choose one individual node for account or payment sessions.

Leave both return modules disabled until you have a verified mainland node.
`CN` in a node name is only a filter match, not a location check. These general
travel selectors also expose `PROXY` and `DIRECT` as manual escape routes;
they do not enforce a mainland-only exit. For Soul, follow the separate
[reject-by-default setup](soul-ktv.md) instead. Its RTC and room-access tests
still require the mainland proxy you haven't configured yet.

Use `back-to-cn-all` instead when every mainland domain and IP should use the
mainland exit. Never enable both modules. Keep either one off while physically
in mainland China.

## Captive portal and DNS recovery

1. Disable the active DNS modules, `private-ip-block`, and `httpdns-block`. If using a location
   profile, temporarily switch to the legacy `shadowrocket.conf` with those
   modules disabled; disabling modules alone does not remove embedded DNS.
2. Keep `captive.apple.com` in the base `skip-proxy` setting.
3. Complete the network sign-in, then restore the correct location profile with
   DNS modules off, or restore one DNS module if staying on the legacy profile.
4. For Apple sign-in, disable the CDN alias and use `DIRECT` for Account and
   Services; if needed, use one fixed Hong Kong node for both.

Never enable TLS decryption for Apple account, iCloud, push, certificate, or
update traffic.

## Local override example

Copy `examples/local-overrides.module.example` outside the repository, remove
the comment markers you need, and place it above shared modules. The ignored
name `local-overrides.module` is safe for a private working copy.

```ini
[Rule]
DOMAIN-SUFFIX,lan.example,DIRECT
DOMAIN,work.example,🌏 Foreign Websites
IP-CIDR,192.168.64.0/24,DIRECT,no-resolve
```

## Downloads, regional streaming, and diagnostics

These modules are independent options. Order rejection modules before them,
and place them before either return-to-China module:

```text
adblock-core (or adblock-lite)
adblock-aggressive (only with Core, optional)
httpdns-block (optional)
security-dns (or privacy-dns; choose one)
bulk-downloads (optional)
regional-streaming (optional)
network-diagnostics (optional)
soul-ktv (only after its separate setup)
back-to-cn (or back-to-cn-all; optional)
```

Existing narrow Apple modules still precede `apple-services`. The three new
routing modules have no ordering dependency on each other or on Apple modules.
Check the selected stack with the validator before importing.

`bulk-downloads` starts on PROXY. Pick DIRECT or a cheaper node only after
checking the actual asset transfer. Steam community and APIs keep Gaming
Platforms; selected Steam content hosts use Bulk Downloads. Package assets
include Python wheels and Rust crates. npm and container registries carry
metadata as well as package bytes, so host-based routing moves both. Apple
content and updates retain their existing modules. This is a reviewed subset,
not every CDN a downloader can use.

`regional-streaming` starts HK/TW/JP groups on matching regions, with PROXY and
DIRECT available. It covers selected ViuTV, myTVSUPER, Now E, KKTV, friDay,
ABEMA, and TVer domains. Viu can serve several markets; select the route you
need. Shared video CDNs stay on their existing routes. Inspect playback logs
before adding a service-specific CDN exception. A matching country name does
not prove playback access, account eligibility, or a functioning subscription.

`network-diagnostics` moves `speedtest.net` and `ooklaserver.net` to a separate
selector. Ookla can choose an ISP-owned server outside those suffixes: check
the selected server hostname and matched policy before treating a result as a
measurement of that selector. Fast.com remains a Netflix-path test. A 204
health check measures availability/latency, not download throughput.

## Security DNS

Use `security-dns` instead of `privacy-dns` outside mainland China when you want
threat filtering. Both configured encrypted resolvers apply filtering, even
when a client queries them concurrently. They are different providers and can
return different blocking verdicts. This is DNS filtering, not a firewall for
all malicious traffic: hardcoded IPs and apps using their own encrypted DNS
can bypass the chosen resolver. Port-53 interception does not intercept DoH.

Keep ad blocking separate. For a suspected false positive, record the hostname
and resolver response, then compare with the privacy variant after disabling
security DNS. Restore exactly one variant after the test. Do not enable both
and rely on module order to choose the effective resolver. Use mainland DNS
when foreign resolvers cannot be reached on that network.

## Private services and experimental features

Corporate DNS requires the actual internal zones, resolver addresses and VPN
routes. Keep those in the existing private override; omit `private-ip-block`
when legitimate internal names resolve to private addresses. Do not publish
corporate resolver details in this repository.

For a bank or payment session, select one fixed trusted node through PROXY or
use DIRECT where the service works locally. Keep that choice stable through
sign-in and payment. No shared bank-domain list can establish the right exit
for every account. P2P tracker domains also do not cover arbitrary peer IPs or
DHT traffic, so there is no blanket DIRECT torrent rule.

When diagnosing iCloud Private Relay coexistence, record its enabled state,
compare the same request with it temporarily disabled, and restore the user's
chosen setting afterward. Do not add interception or broad Apple overrides
just to alter Private Relay. App rewrites and MITM-dependent enhancements need
a separate experimental profile and native tests; these routing modules do
not install scripts or certificates.
